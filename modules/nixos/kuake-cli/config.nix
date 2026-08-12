{
  config,
  lib,
  options,
  ...
}:
let
  cfg = config.programs.kuakeCli;
in
# 实现逻辑：所有副作用包在 mkIf 里。
#
# 双上下文（本模块同时注册为 nixosModules.kuake-cli 与 homeModules.kuake-cli，
# 见 docs/structure.md §3.5）：
#   - home-manager 模块系统声明了 `home` 选项 → 装入 home.packages；
#   - NixOS 未声明 `home` 选项 → 装入 environment.systemPackages。
# ⚠️ 用 `options ? home` 而不是 `config ? home`：后者在 config 求值期查询
# config 自身的属性集合，会触发无限递归。
# 注意：NixOS + home-manager NixOS 模块的组合下，`home` 选项不存在于 NixOS
# 选项中（home-manager 的 home.* 在其自己的模块系统里求值），检测为系统
# 上下文，属预期行为。
{
  config = lib.mkIf cfg.enable (
    if options ? home then
      {
        home.packages = [
          cfg.package
          cfg.mcpPackage
        ];
      }
    else
      {
        environment.systemPackages = [
          cfg.package
          cfg.mcpPackage
        ];
      }
  );
}
