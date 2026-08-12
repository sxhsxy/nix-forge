{
  config,
  lib,
  pkgs,
  ...
}:
# 模块入口。规范见 docs/structure.md §3（模块文件规范）。
{
  imports = [
    ./options.nix
    ./config.nix
  ];

  meta = {
    name = "my-module"; # ← 替换为你的模块名（kebab-case，与目录名一致）
    category = "nixos"; # ← nixos | home
    description = "一句话说明这个模块做什么";
    doc = "docs/structure.md"; # ← 指向模块文档（README 或规范章节）
  };
}
