# nix-forge 代码组织结构规范

- **版本**：1.0（2026-08）
- **状态**：生效中
- **适用范围**：本仓库内所有新增、修改的模块与代码

---

## 0. 本规范的地位

nix-forge 是一个以「可扩展的多模块集合」为第一目标的仓库：随着时间推移，
NixOS 模块、home-manager 模块、overlay 会持续增多。本规范回答三个问题：

1. **新模块放哪里**（目录约定）；
2. **模块内部怎么写**（文件约定、命名约定）；
3. **怎么让新模块自动生效**（自动发现与聚合机制）。

规范是强制性的：不满足规范的模块不应合入主分支。逐条都有对应的检查
（`nix flake check` 至少保证模块可求值，详见 §8）。

## 1. 顶层布局

```
nix-forge/
├── flake.nix               # 入口：聚合所有模块，导出对外 API
├── flake.lock
├── README.md               # 项目门面：快速使用 + 目录总览
├── CHANGELOG.md            # 变更记录（倒序）
├── LICENSE                 # MIT
├── docs/                   # 文档
│   ├── structure.md        # ★ 本规范
│   └── authoring.md        # 新增模块速成指南
├── lib/                    # 跨模块共享的纯函数库
│   ├── default.nix         # 库入口：导出全部 lib 函数
│   ├── discovery.nix       # 模块自动发现（readDir 扫描）
│   └── mkModule.nix        # 模块 meta 注入助手
├── modules/                # ★ 模块集合根
│   ├── nixos/              #   NixOS 系统模块：一个目录一个模块
│   │   └── forge-example/  #   示例模块（四件套）
│   ├── home/               #   home-manager 模块（暂无，见目录内 README）
│   └── overlays/           #   overlay：一个文件一个
├── templates/              # nix flake 脚手架模板
│   └── module/             #   新模块四件套模板
└── tests/                  # 集成测试（NixOS VM），目录与模块一一对应
    └── README.md
```

### 职责边界

| 目录 | 放什么 | 不放什么 |
| ---- | ------ | -------- |
| `modules/nixos/` | NixOS 系统模块 | 包定义、overlay、home-manager 模块 |
| `modules/home/` | home-manager 模块 | 系统模块（home 模块里也**不要**写 `systemd`、`environment.etc` 等 NixOS 专属选项） |
| `modules/overlays/` | 包覆盖 overlay | 模块、测试 |
| `lib/` | 纯函数、共享逻辑 | 任何有副作用、依赖 pkgs 的实现 |
| `docs/` | 规范、指南、设计文档 | 模块 README（放各模块目录内） |
| `tests/` | NixOS VM 集成测试 | 单元测试（暂无框架，冒烟检查见 §8） |

## 2. 核心约定：一个目录 = 一个模块

模块按**类别 + 名称**两级组织：

```
modules/<category>/<name>/
```

- `category` ∈ { `nixos`, `home` }，与 flake 输出命名空间一一对应；
- `name` 为 kebab-case，全仓库唯一，同时是：
  - 目录名；
  - flake 导出名（`nixosModules.<name>` / `homeModules.<name>`）；
  - 模块 `meta.name`。
- 目录内**必须**存在 `default.nix` —— 它是自动发现机制（§5）的识别标志，
  也是模块的入口。

### 为什么按目录拆，而不是一个文件放多个模块？

- 目录天然携带文档与附属文件（README、测试、资源）；
- git 历史更清晰：`git log -- modules/nixos/<name>/` 即该模块的全部历史；
- 自动发现（§5）可以零配置把新目录挂载成新导出。

## 3. 模块文件规范（四件套）

```
modules/<category>/<name>/
├── default.nix   入口：imports 其余文件，声明 meta          【必须】
├── options.nix   选项声明（纯声明，无副作用）                【可选】
├── config.nix    实现逻辑（读取 options，mkIf 守卫副作用）   【可选】
└── README.md     模块文档                                    【推荐】
```

### 拆分规则

- **小模块**（< ~60 行、选项 ≤ 5 个）：全部写在 `default.nix` 单文件即可；
- **四件套**：选项变多、或 config 有独立逻辑需要单独评审/测试时拆分；
- 拆分后 `default.nix` 固定为：

```nix
{ config, lib, pkgs, ... }:
{
  imports = [
    ./options.nix
    ./config.nix
  ];

  meta = {
    name = "my-module";        # kebab-case，与目录名一致
    category = "nixos";        # nixos | home
    description = "一句话说明这个模块做什么";
    doc = "docs/structure.md"; # 指向模块文档（README 或规范章节）
  };
}
```

### 硬性规则

1. **options 纯声明**：`options.nix` 只声明选项类型与默认值，禁止任何副作用
   （写文件、fetch、exec、import 非纯内容）。副作用全部发生在 `config` 阶段。
2. **config 用 mkIf 守卫**：所有对系统的改动（写文件、启服务、装包）必须包在
   `lib.mkIf cfg.enable { ... }` 里，`cfg = config.<namespace>` 在 let 中取出。
3. **meta 必填且字段一致**：`name` / `category` / `description` / `doc` 四项，
   手写或 `lib.mkModule` 自动注入二选一（见 `lib/mkModule.nix`）。
4. **不 import 兄弟模块**：模块间要共享逻辑，下沉到 `lib/`（§6），禁止
   `import ../other-module/` 互相引用 —— 那会让模块失去独立可用的特性。

## 4. 命名规范

| 对象 | 规范 | 示例 |
| ---- | ---- | ---- |
| 目录名 / 文件名 / 导出名 / `meta.name` | kebab-case | `forge-example` |
| Nix 标识符 / 选项属性名 | lowerCamelCase | `services.forgeExample` |
| 选项命名空间 | `services.<name>` / `programs.<name>` / `home.<name>` | `services.forgeExample` |

- 选项命名空间**必须包含模块名**（转 lowerCamelCase），防止不同模块选项冲突；
- 布尔开关统一用 `lib.mkEnableOption`；
- 导出名与目录名必须一致 —— 这是自动发现机制成立的前提（§5）。

## 5. 自动发现与聚合

flake.nix 不手写模块清单，而是通过 `lib/discovery.nix` 扫描目录：

```nix
# flake.nix（核心三行）
nixosModules = forge-lib.discoverModules ./. "nixos";   # 扫描 modules/nixos/
homeModules  = forge-lib.discoverModules ./. "home";    # 扫描 modules/home/
overlays     = forge-lib.discoverOverlays ./.;          # 扫描 modules/overlays/*.nix
```

由此自动得到：

| 你在仓库里做的 | 自动获得的导出 |
| -------------- | -------------- |
| 新建 `modules/nixos/foo/default.nix` | `nixosModules.foo` |
| 新建 `modules/home/bar/default.nix` | `homeModules.bar` |
| 新建 `modules/overlays/baz.nix` | `overlays.baz` |
| — | `nixosModules.default`（全部合并） |
| — | `homeModules.default`（全部合并） |
| — | `overlays.default`（全部按序组合） |

`default` 的实现要点：**模块列表本身就是一个合法模块**，
所以 `nixosModules.default = builtins.attrValues nixosModules` 即为全量合并。

### ⚠️ 最重要的一个坑

flake 求值**只打包 git 已跟踪的文件**。新建/重命名/移动模块后，`readDir`
在 store 副本里看不到新目录，聚合结果不会更新。因此：

> **新增模块后的第一件事是 `git add`，然后才 `nix flake check`。**

### 使用建议

- 消费方优先**只引用单个模块**（`nixosModules.foo`），避免 `default` 意外带入
  不想要的配置；`default` 适合自用主机或确认模块间无冲突的场景。

## 6. lib 共享库规范

`lib/` 是本仓库自带的纯函数库（flake 的 `lib` 输出），供 flake 与各模块复用。

- **纯函数**：不 import `pkgs`、不触网、无副作用（输出不依赖构建环境）；
- **有依赖才下沉**：两处以上使用同一逻辑，才提取到 `lib/`；一处使用的就留在模块内；
- **新文件要在 `lib/default.nix` 导出**，并加一行注释说明用途；
- 模块间共享逻辑**禁止**互相 import，一律走 `lib/`（见 §3 硬性规则 4）。

## 7. overlays 规范

- `modules/overlays/<name>.nix`，一个文件一个 overlay，文件名即 overlay 名；
- 文件形如 `final: prev: { ... }`（标准 overlay）；
- 每个 overlay 保持独立可用；`overlays.default` 按字母序组合全部；
- 与某模块强相关的 overlay 建议同名（模块 `foo` → overlay `foo`），表达关联；
- overlay 里只改写包属性，不写模块逻辑。

## 8. 测试规范

### 最低门槛：冒烟检查（仓库自带，零成本）

flake 的 `checks.<system>.module-eval` 会对**所有模块入口文件**执行
`nix-instantiate --eval`：任何语法错误、顶层导入错误都会让 `nix flake check`
失败。这是新增模块的最低门槛，合入前必须通过。

```bash
nix flake check
```

### 集成测试：NixOS VM（按需）

行为可测的模块应提供 VM 测试，放 `tests/<category>/<name>.nix`，目录与模块
一一对应。测试文件形如：

```nix
# tests/nixos/forge-example.nix
{
  services.forgeExample.enable = true;

  testScript = ''
    machine.wait_for_unit("multi-user.target")
    machine.succeed("grep -q 'Hello from nix-forge!' /etc/forge-example.conf")
  '';
}
```

接入 flake 的 checks（按需，会显著增加求值/构建时间）：

```nix
checks.${system}.forge-example =
  pkgs.testers.runNixOSTest (import ./tests/nixos/forge-example.nix);
```

详见 `tests/README.md`。

## 9. 脚手架：新增模块的正确姿势

```bash
# 在任意空目录生成四件套骨架（含占位命名 my-module / myModule）
nix flake init -t github:sxhsxy/nix-forge#module

# 复制进本仓库（或直接在 modules/<category>/ 下建目录）
mv <生成的文件> modules/<category>/<name>/
# 全局替换 my-module → <name>，myModule → <name 转 lowerCamelCase>
```

完整步骤见 `docs/authoring.md`。骨架文件与示例模块 `forge-example` 就是
规范的活标本 —— 不确定时照抄它们。

## 10. 文档与提交约定

- 每个模块的 README 至少包含三节：**选项表**（表格）、**使用**（flake + 配置示例）、
  **验证**（命令）。照抄 `modules/nixos/forge-example/README.md` 的骨架；
- 提交信息格式：`<category>/<module>: <描述>`，例如：
  - `nixos/forge-example: add message option`
  - `lib: fix discoverModules empty-dir guard`
  - `docs: clarify flake check workflow`
- 破坏性变更（选项改名、默认值变更、删除模块）必须记入 `CHANGELOG.md`；
- 一个提交只做一件事，模块新增/修改与文档/规范修订分开提交。

## 11. 代码风格

- 所有 `.nix` 文件用 `nixfmt-rfc-style` 格式化，仓库提供 formatter：

```bash
nix fmt          # 一键格式化整个仓库
nix fmt --check  # 只检查
```

- 注释用中文（本仓库是中文优先的个人仓库），标识符、字符串内容用英文；
- 行宽、缩进交给 nixfmt，不手调。

## 12. 规范演进

- 本规范受版本管理（见文件头版本号）；修订必须记入 `CHANGELOG.md`；
- 重大修订（影响存量模块的目录/命名约定）需同时提供迁移说明；
- 规范与代码冲突时，以本文件为准，并开 issue 修正代码。
