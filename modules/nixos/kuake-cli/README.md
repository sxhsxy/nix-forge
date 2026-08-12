# kuake-cli

安装夸克网盘（Quark Cloud Drive）相关工具：

- `kuake` —— 夸克网盘文件管理 CLI（目录/文件/分享管理、JSON 输出与管道模式）；
- `kuake-mcp` —— kuake 的 MCP server（stdio），为 Claude Code 等 MCP 客户端
  提供 14 个夸克网盘操作工具。

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

方式一：NixOS 模块（推荐，随系统升级/回滚）：

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

方式二：overlay（任意上下文：home-manager、nix shell 等）：

```nix
# flake.nix
{
  inputs.nix-forge.url = "github:sxhsxy/nix-forge";
  outputs = { nixpkgs, nix-forge, ... }: {
    nixpkgs.overlays = [ nix-forge.overlays.kuake-cli ];
    # 之后 pkgs.kuake / pkgs.kuake-mcp 可用：
    # home.packages = [ pkgs.kuake ];
  };
}
```

## 验证

```bash
nix flake check                     # 冒烟检查：模块可求值
nix build --impure --expr 'let f = builtins.getFlake (toString ./.);
  pkgs = f.inputs.nixpkgs.legacyPackages.x86_64-linux;
  in ((import ./modules/overlays/kuake-cli.nix) pkgs pkgs).kuake'
./result/bin/kuake version          # 冒烟运行
```

## 文件

```
default.nix   入口：imports options/config
options.nix   选项声明（programs.kuakeCli.*）
config.nix    实现逻辑（lib.mkIf 守卫）
README.md     本文档
```

包定义见 `../../overlays/kuake-cli.nix`（overlay 单一来源）。
