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

    environmentFiles = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "$HOME/.config/kuake/.env" ];
      defaultText = lib.literalExpression ''[ "$HOME/.config/kuake/.env" ]'';
      example = lib.literalExpression ''[ "/etc/kuake.env" "$HOME/.config/kuake/custom.env" ]'';
      description = ''
        启动 kuake / kuake-mcp 前按序加载的 .env 文件列表（不覆盖已存在的环境变量）。
        路径中的 `$HOME` 与开头的 `~` 在运行时展开；文件缺失或不可读时静默跳过。
        注意：类型是 str——不要使用 nix 的 path 字面量，否则文件会被拷贝进
        /nix/store，cookie 会泄露给本机所有用户。建议文件权限 600。
      '';
    };
  };
}
