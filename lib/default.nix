{
  lib,
}:
# nix-forge 共享纯函数库：仅供本仓库 flake 与各模块复用。
# 规范见 docs/structure.md §6（lib 规范）：
#   - 必须是纯函数：不 import pkgs、不触网、无副作用；
#   - 新增文件后必须在下面导出，并注明用途。
{
  inherit (import ./discovery.nix { inherit lib; })
    discoverModules
    discoverDualModules
    discoverOverlays
    ;
}
