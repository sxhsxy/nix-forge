{
  config,
  lib,
  pkgs,
  ...
}:
# 模块入口。规范见 docs/structure.md §3（模块文件规范）。
# 注意：不要写自定义 meta 字段（nixpkgs 严格校验 config.meta，只允许
# maintainers/doc/priority 等已声明字段）；模块身份由目录名与 README 承载。
{
  imports = [
    ./options.nix
    ./config.nix
  ];
}
