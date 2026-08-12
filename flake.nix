{
  description = "nix-forge：个人自定义 Nix 模块集合仓库（NixOS / home-manager / overlays），内置代码组织结构规范与模块脚手架";

  inputs = {
    # 与 mynixpkgs 系列保持一致：直接跟随 nixos-unstable
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      lib = nixpkgs.lib;

      # nix-forge 自带的共享纯函数库（lib/ 目录），含模块自动发现逻辑
      forge-lib = import ./lib { inherit lib; };

      # ── 模块自动发现（约定优于配置）────────────────────────────
      # 规范见 docs/structure.md：
      #   modules/nixos/<name>/default.nix  → nixosModules.<name>
      #   modules/home/<name>/default.nix   → homeModules.<name>
      #   modules/overlays/<name>.nix       → overlays.<name>
      # ⚠️ flake 求值只打包 git 已跟踪的文件：新增模块后必须先 `git add`。
      nixosModules = forge-lib.discoverModules ./. "nixos";
      homeModules = forge-lib.discoverModules ./. "home";
      overlays = forge-lib.discoverOverlays ./.;

      # 全部模块入口文件（供冒烟检查使用）
      allModuleFiles =
        let
          entries =
            category:
            map (n: ./. + "/modules/${category}/${n}/default.nix") (
              builtins.attrNames (forge-lib.discoverModules ./. category)
            );
        in
        entries "nixos"
        ++ entries "home"
        ++ map (n: ./. + "/modules/overlays/${n}.nix") (builtins.attrNames overlays);
    in
    {
      # ── 对外 API ───────────────────────────────────────────────
      inherit lib;

      # 每个模块独立导出；default 为全部模块的合并（模块列表本身即合法模块）
      nixosModules = nixosModules // {
        default = builtins.attrValues nixosModules;
      };
      homeModules = homeModules // {
        default = builtins.attrValues homeModules;
      };
      overlays = overlays // {
        default = lib.composeManyExtensions (builtins.attrValues overlays);
      };

      # 脚手架：nix flake init -t github:sxhsxy/nix-forge#module
      templates.module = {
        path = ./templates/module;
        description = "nix-forge 模块脚手架：modules/<category>/<name>/ 四件套（default/options/config/README）";
      };

      # 代码风格：nix fmt
      # nix 2.34+ 的 `nix fmt` 不再自动收集文件，参数原样转发给 formatter，
      # 因此这里用一个包装脚本：无参数时格式化 git 已跟踪的全部 .nix 文件
      # （flake 只打包这些文件，语义一致）；显式传参（如 --check）则直接转发。
      formatter = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        pkgs.writeShellScriptBin "nix-forge-fmt" ''
          cd "''${PRJ_ROOT:-.}"
          check=""
          if [ "$1" = "--check" ] || [ "$1" = "-c" ]; then
            check="$1"
            shift
          fi
          if [ "$#" -eq 0 ]; then
            candidates=$(git ls-files '*.nix')
          else
            candidates="$@"
          fi
          # 只处理磁盘上真实存在的文件（git ls-files 会包含已删除未提交的条目）
          files=""
          for f in $candidates; do
            [ -f "$f" ] && files="$files $f"
          done
          [ -z "$files" ] && exit 0
          exec ${pkgs.nixfmt}/bin/nixfmt $check $files
        ''
      );

      # 冒烟检查：对所有模块入口文件执行 nix-instantiate --eval，
      # 任何语法/顶层导入错误都会让 `nix flake check` 失败。新增模块的最低门槛。
      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          module-eval =
            pkgs.runCommand "nix-forge-module-eval"
              {
                nativeBuildInputs = [ pkgs.nix ];
                # 沙箱内 HOME 不可用会导致 nix-instantiate 尝试创建
                # /nix/var/nix/profiles 而失败，显式给一个可写 HOME
                HOME = "/tmp";
              }
              (
                lib.concatMapStringsSep "\n" (f: "nix-instantiate --eval '${f}' >/dev/null") allModuleFiles
                + "\ntouch $out\n"
              );
        }
      );
    };
}
