{
  config,
  lib,
  ...
}:
let
  cfg = config.programs.kuakeCli;
in
# 实现逻辑：所有副作用包在 mkIf 里。
{
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
      cfg.mcpPackage
    ];
  };
}
