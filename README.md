# nix-forge

个人自定义 Nix 模块集合仓库：**结构规范 + 自动发现 + 脚手架**三位一体。

- `modules/nixos/`、`modules/home/` 下**一个目录一个模块**，drop-in 即用，
  flake 自动导出 `nixosModules.<name>` / `homeModules.<name>`；
- `modules/overlays/` 一个文件一个 overlay，自动组合为 `overlays.default`；
- 代码组织结构规范见 [docs/structure.md](docs/structure.md) —— 新模块先读它；
- 新增模块有脚手架：`nix flake init -t github:sxhsxy/nix-forge#module`；
- `nix flake check` 自带模块冒烟检查，保证所有模块可求值。

## 快速使用

```nix
# flake.nix —— 消费方
{
  inputs.nix-forge.url = "github:sxhsxy/nix-forge";

  outputs = { nixpkgs, nix-forge, ... }: {
    nixosConfigurations.myHost = nixpkgs.lib.nixosSystem {
      modules = [
        nix-forge.nixosModules.forge-example   # 只引需要的模块
        # 或 nix-forge.nixosModules.default   # 全部模块（注意潜在的选项冲突）
      ];
    };
  };
}
```

## 目录结构

```
nix-forge/
├── flake.nix            # 入口：自动发现并聚合全部模块
├── docs/
│   ├── structure.md     # ★ 代码组织结构规范（仓库的"宪法"）
│   └── authoring.md     # 新增模块速成指南
├── lib/                 # 共享纯函数库（自动发现逻辑就在这里）
├── modules/
│   ├── nixos/           # NixOS 模块（forge-example 为示例）
│   ├── home/            # home-manager 模块
│   └── overlays/        # overlay（一个文件一个）
├── templates/module/    # 新模块脚手架（四件套）
└── tests/               # NixOS VM 集成测试约定
```

## 开发

```bash
nix flake check   # 冒烟检查：所有模块可求值
nix fmt           # nixfmt-rfc-style 统一格式
nix flake show    # 查看自动聚合出的全部导出
```

## 文档

- [代码组织结构规范](docs/structure.md) —— 目录/文件/命名/测试/提交约定
- [新增模块速成指南](docs/authoring.md) —— 5 分钟上手
- [forge-example 示例模块](modules/nixos/forge-example/README.md) —— 活标本

## License

[MIT](LICENSE)
