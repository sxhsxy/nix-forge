{
  config,
  lib,
  pkgs,
  ...
}:
let
  # 复用 overlays/ 里的包定义（单一来源）：以 final=prev=pkgs 应用 overlay 取出
  kuakePkgs = (import ../../overlays/kuake-cli.nix) pkgs pkgs;
in
# 选项声明：纯声明（本地 import 求值无副作用）。
{
  options.programs.kuakeCli = {
    enable = lib.mkEnableOption "夸克网盘 CLI（kuake）及其 MCP server（kuake-mcp）";

    package = lib.mkOption {
      type = lib.types.package;
      default = kuakePkgs.kuake;
      defaultText = lib.literalExpression "overlays.kuake-cli 的 kuake";
      description = "kuake CLI 包，可覆盖为自定义构建。";
    };

    mcpPackage = lib.mkOption {
      type = lib.types.package;
      default = kuakePkgs.kuake-mcp;
      defaultText = lib.literalExpression "overlays.kuake-cli 的 kuake-mcp";
      description = "kuake-mcp（MCP server）包，可覆盖为自定义构建。";
    };
  };
}
