{
  # nix-forge 新模块脚手架。把本目录复制为 modules/<category>/<name>/ 后：
  #   1. 全局替换 my-module → 你的模块名（kebab-case）
  #   2. 全局替换 myModule   → 选项命名空间（lowerCamelCase）
  #   3. 修改 options.nix / config.nix 实现你的选项与逻辑
  #   4. git add 后运行 nix flake check 验证
  # 完整流程见 docs/authoring.md。
  description = "nix-forge 模块脚手架";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    {
      nixosModules.my-module = import ./default.nix;
    };
}
