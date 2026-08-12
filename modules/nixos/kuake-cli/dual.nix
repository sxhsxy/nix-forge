# 双上下文标记文件（约定见 docs/structure.md §3.5）。
#
# 存在本文件即声明：modules/nixos/<name>/ 是一个 NixOS / home-manager
# 通用模块，flake 会把它同时注册为 nixosModules.<name> 与 homeModules.<name>。
# 实现上 config.nix 以 `if options ? home then home.packages else environment.systemPackages`
# 区分运行上下文（用 options 而非 config，避免无限递归）。删除本文件则只注册为 NixOS 模块。
#
# 本文件仅作标记（discovery 只检查其存在），内容不求值；写成合法表达式
# 以便 nixfmt / nix-instantiate 可处理。
true
