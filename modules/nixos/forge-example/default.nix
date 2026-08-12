{
  config,
  lib,
  pkgs,
  ...
}:
# 示例模块：演示 nix-forge 的「四件套」结构
# （default.nix + options.nix + config.nix + README.md）。
# 本模块实现一个纯配置型「服务」：启用后向 /etc/forge-example.conf 写入问候语，
# 不安装任何软件包，便于离线演示与测试。
#
# 注意：模块顶层不要写自定义 meta 字段（如 meta.name/meta.category）——
# nixpkgs 对 config.meta 是严格校验，只允许 maintainers/doc/priority 等
# 已声明字段，自定义字段会在系统求值时直接报错。模块的身份信息由
# 目录结构（<category>/<name>）与 README 承载。
{
  imports = [
    ./options.nix
    ./config.nix
  ];
}
