{
  lib,
}:
let
  inherit (lib)
    filterAttrs
    hasSuffix
    mapAttrs'
    pathExists
    readDir
    removeSuffix
    ;
in
{
  # 扫描 <root>/modules/<category> 下所有「含 default.nix 的子目录」，
  # 导出 { <目录名> = import <目录>/default.nix; }。
  # 目录名即模块名（kebab-case），导出名与目录名严格一致 ——
  # 这是「一个目录 = 一个模块」约定的实现基础。
  #
  # ⚠️ flake 求值只看到 git 已跟踪的文件：新增模块后必须先 git add，
  #    否则 readDir 在 store 副本里看不到该目录。
  discoverModules =
    root: category:
    let
      dir = root + "/modules/${category}";
      isModuleDir = name: type: type == "directory" && pathExists (dir + "/${name}/default.nix");
    in
    mapAttrs' (name: _: {
      inherit name;
      value = import (dir + "/${name}/default.nix");
    }) (filterAttrs isModuleDir (readDir dir));

  # 扫描 <root>/modules/overlays 下所有 *.nix 文件，
  # 导出 { <文件名去后缀> = import <文件>; }。
  # 每个文件形如 final: prev: { ... }（标准 overlay）。
  discoverOverlays =
    root:
    let
      dir = root + "/modules/overlays";
      isOverlayFile = name: type: type == "regular" && hasSuffix ".nix" name;
    in
    mapAttrs' (name: _: {
      name = removeSuffix ".nix" name;
      value = import (dir + "/${name}.nix");
    }) (filterAttrs isOverlayFile (readDir dir));
}
