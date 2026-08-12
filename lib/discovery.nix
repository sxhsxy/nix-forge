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

  # 扫描 <root>/modules/<category> 下含 dual.nix 标记的双上下文模块
  # （规范见 docs/structure.md §3.5）：目录结构同 discoverModules，
  # 额外要求目录内存在 dual.nix 标记文件；返回的模块会被 flake 同时
  # 注册为 nixosModules.<name> 与 homeModules.<name>。
  discoverDualModules =
    root: category:
    let
      dir = root + "/modules/${category}";
      isDualModule = name: type: type == "directory" && pathExists (dir + "/${name}/dual.nix");
    in
    mapAttrs' (name: _: {
      inherit name;
      value = import (dir + "/${name}/default.nix");
    }) (filterAttrs isDualModule (readDir dir));

  # 扫描 <root>/modules/overlays 下所有 *.nix 文件，
  # 导出 { <文件名去后缀> = import <文件>; }。
  # 每个文件形如 final: prev: { ... }（标准 overlay）。
  discoverOverlays =
    root:
    let
      dir = root + "/modules/overlays";
      isOverlayFile = name: type: type == "regular" && hasSuffix ".nix" name;
    in
    mapAttrs' (
      name: _:
      let
        # 注意：不能直接 `{ name = removeSuffix ...; value = import ...${name}.nix }` ——
        # 属性集内后一个绑定看到的 name 仍是 lambda 参数（未去后缀），
        # 会拼出 <name>.nix.nix 的错误路径。
        overlayName = removeSuffix ".nix" name;
      in
      {
        name = overlayName;
        value = import (dir + "/${overlayName}.nix");
      }
    ) (filterAttrs isOverlayFile (readDir dir));
}
