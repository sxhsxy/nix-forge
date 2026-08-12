{
  config,
  lib,
  pkgs,
  ...
}:
# kuake-cli 模块：启用后把 kuake（夸克网盘 CLI）与 kuake-mcp（MCP server）
# 装入 environment.systemPackages。包定义单一来源：modules/overlays/kuake-cli.nix。
{
  imports = [
    ./options.nix
    ./config.nix
  ];
}
