# kuake-cli

安装夸克网盘（Quark Cloud Drive）相关工具：

- `kuake` —— 夸克网盘文件管理 CLI（目录/文件/分享管理、JSON 输出与管道模式）；
- `kuake-mcp` —— kuake 的 MCP server（stdio），为 Claude Code 等 MCP 客户端
  提供 14 个夸克网盘操作工具。

**双上下文模块**（规范 §3.5）：同一份代码同时注册为
`nixosModules.kuake-cli` 与 `homeModules.kuake-cli`，config 按运行上下文分流：
home-manager → `home.packages`；NixOS → `environment.systemPackages`。

包定义迁移自 `mynixpkgs/kuake-cli`，**单一来源在 `modules/overlays/kuake-cli.nix`**
（overlays/ 是仓库的包层；lib/ 禁 pkgs，modules/ 是配置层）。本模块以
`(import ../../overlays/kuake-cli.nix) pkgs pkgs` 方式复用同一份包，改包只改
overlay 一处。

## 选项

| 选项 | 类型 | 默认值 | 说明 |
| ---- | ---- | ------ | ---- |
| `programs.kuakeCli.enable` | bool | `false` | 安装 kuake 与 kuake-mcp |
| `programs.kuakeCli.package` | package | overlay 的 `kuake` | kuake 包，可覆盖 |
| `programs.kuakeCli.mcpPackage` | package | overlay 的 `kuake-mcp` | kuake-mcp 包，可覆盖 |

## 使用

方式一：NixOS 系统配置（装入 systemPackages）：

```nix
# flake.nix —— 消费方
{
  inputs.nix-forge.url = "github:sxhsxy/nix-forge";
  outputs = { nixpkgs, nix-forge, ... }: {
    nixosConfigurations.myHost = nixpkgs.lib.nixosSystem {
      modules = [ nix-forge.nixosModules.kuake-cli ];
    };
  };
}
```

```nix
# configuration.nix
{ ... }:
{
  programs.kuakeCli.enable = true;
}
```

方式二：home-manager 用户配置（装入 home.packages，同一份模块）：

```nix
# home.nix —— home-manager 配置
{ ... }:
{
  imports = [ inputs.nix-forge.homeModules.kuake-cli ];
  programs.kuakeCli.enable = true;
}
```

方式三：overlay（任意上下文：home-manager、nix shell 等）：

```nix
nixpkgs.overlays = [ nix-forge.overlays.kuake-cli ];
# 之后 pkgs.kuake / pkgs.kuake-mcp 可用
```

## 验证

```bash
nix flake check                     # 冒烟检查：模块可求值

# NixOS 上下文：systemPackages 含 kuake
nix eval --impure --expr 'let f = builtins.getFlake (toString ./.); s = f.inputs.nixpkgs.lib.nixosSystem { modules = [ { nixpkgs.hostPlatform = "x86_64-linux"; } f.nixosModules.kuake-cli { programs.kuakeCli.enable = true; } ]; }; in builtins.map (p: p.name) s.config.environment.systemPackages'

# home-manager 上下文：home.packages 含 kuake（用 flake 的 home-manager 输入）
nix eval --impure --expr 'let f = builtins.getFlake (toString ./.); pkgs = f.inputs.nixpkgs.legacyPackages.x86_64-linux; hm = f.inputs.home-manager.lib.homeManagerConfiguration { inherit pkgs; modules = [ f.homeModules.kuake-cli { programs.kuakeCli.enable = true; } { home = { username = "sxh"; homeDirectory = "/home/sxh"; stateVersion = "26.05"; }; } ]; }; in builtins.map (p: p.name) hm.config.home.packages'
```

## 文件

```
default.nix   入口：imports options/config
options.nix   选项声明（programs.kuakeCli.*）
config.nix    双上下文实现（home.packages / environment.systemPackages 分流）
dual.nix      双上下文标记（存在即同时注册 homeModules，见规范 §3.5）
README.md     本文档
```

包定义见 `../../overlays/kuake-cli.nix`（overlay 单一来源）。
