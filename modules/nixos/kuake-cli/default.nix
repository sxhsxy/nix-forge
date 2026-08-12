{
  config,
  lib,
  pkgs,
  ...
}:
# kuake-cli 双上下文模块：启用后把 kuake（夸克网盘 CLI）与 kuake-mcp（MCP server）
# 装入用户/系统环境（home-manager → home.packages；NixOS → environment.systemPackages）。
# 包定义单一来源：modules/overlays/kuake-cli.nix。
# 双上下文约定见 docs/structure.md §3.5；本目录的 dual.nix 是注册标记。
{
  imports = [
    ./options.nix
    ./config.nix
  ];
}
