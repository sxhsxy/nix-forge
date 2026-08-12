# 新增模块速成指南

对照本指南走一遍，一个新模块从零到合入约 5 分钟。规范全文见
[docs/structure.md](structure.md) —— 本指南是它的可执行摘要。

## 0. 先想清楚两件事

- **类别**：NixOS 系统配置 → `nixos`；用户环境配置 → `home`。
- **名字**：kebab-case，全仓库唯一。示例：`forge-example` → 选项命名空间
  `services.forgeExample`。

## 1. 生成骨架（推荐）

```bash
# 任选一个空目录
mkdir -p /tmp/new-module && cd /tmp/new-module
nix flake init -t github:sxhsxy/nix-forge#module
```

或手写（照抄 `modules/nixos/forge-example/`）：

```
modules/<category>/<name>/
├── default.nix   入口：imports options/config
├── options.nix   选项声明（纯声明）
├── config.nix    实现逻辑（mkIf 守卫）
└── README.md     模块文档
```

## 2. 落地到仓库

```bash
cd <本仓库>
mv /tmp/new-module/* modules/<category>/<name>/
# 全局替换占位名（骨架里是 my-module / myModule）：
#   my-module → <name>，myModule → <name 转 lowerCamelCase>
```

## 3. 写代码

1. **options.nix**：定义选项。命名空间 `services.<模块名>`，布尔开关用
   `lib.mkEnableOption`，字符串/枚举给好 `default` 与 `example`。
2. **config.nix**：`let cfg = config.<命名空间>; in { config = lib.mkIf cfg.enable { ... }; }`。
3. **default.nix**：`imports` 挂上 options/config。模块顶层不要写自定义
   meta 字段（nixpkgs 严格校验，见规范 §3 硬性规则 3）。
4. **README.md**：选项表 + 使用示例 + 验证命令三节。

## 4. 验证（关键步骤！）

```bash
git add modules/<category>/<name>/   # ⚠️ 先 add：flake 只打包已跟踪文件
nix flake check                      # 冒烟检查：所有模块可求值
nix fmt                              # 统一格式
git add -u && git commit
```

`nix flake check` 不通过就不允许合入。

## 5. 可选进阶

- **集成测试**：行为可测时写 `tests/<category>/<name>.nix`（NixOS VM），
  接入方法见 `tests/README.md`；
- **共享逻辑**：多处复用的逻辑下沉到 `lib/`（纯函数），并在 `lib/default.nix` 导出；
- **overlay**：需要改 nixpkgs 包时，写 `modules/overlays/<name>.nix`。

## 6. 提交

```bash
git add -A
git commit -m "nixos/<name>: add <一句话>"
```

破坏性变更记得更新 `CHANGELOG.md`（§10 提交约定见规范）。

## 检查清单

- [ ] 目录名 kebab-case、唯一，与导出名一致
- [ ] `default.nix` 存在（自动发现的识别标志）
- [ ] options 纯声明无副作用；config 全在 `mkIf` 里
- [ ] 模块顶层无自定义 meta 字段（nixpkgs 严格校验）
- [ ] 模块间无互相 import（共享逻辑走 lib/）
- [ ] README 三节齐全（选项表 / 使用 / 验证）
- [ ] `git add` 后 `nix flake check` 通过
- [ ] `nix fmt` 已格式化
