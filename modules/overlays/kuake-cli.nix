final: prev:
# kuake-cli overlay：新增 kuake 与 kuake-mcp 两个包（迁移自 mynixpkgs/kuake-cli）。
# 包定义单一来源在此文件；NixOS 模块 modules/nixos/kuake-cli/ 以
# `(import ../../overlays/kuake-cli.nix) pkgs pkgs` 方式复用同一份包。
let
  lib = prev.lib;
  version = "1.5.0";
  # 上游 tag v1.5.0 对应的 commit（改版本时同步更新 rev / 源码 hash / vendorHash）
  rev = "17b062b268c20873ed8347c87c9c23389856b68c";

  mkKuake =
    {
      pname,
      mainPath,
      binaryName,
      description,
    }:
    prev.buildGoModule {
      inherit pname version;

      # 构建时实时从 GitHub 拉取源码（archive 端点 302 到 codeload 官方 CDN）；
      # 国内网络间歇性断联时，重跑 nix build 即可（nix 会缓存已成功的下载）。
      src = prev.fetchFromGitHub {
        owner = "zhangjingwei";
        repo = "kuake_cli";
        rev = rev;
        hash = "sha256-89XMY1UggK5X9rGdLRmC5brF/xrfmBI+vhJNy+oiRk0=";
      };

      # Go 依赖的 vendor 哈希：构建时 nixpkgs 在固定输出沙箱中自动下载模块。
      vendorHash = "sha256-v/yHclHWgPWKNFEINmXc49aqYu1KBlKswdK61n3U2P8=";

      # GOPROXY 策略（模块下载）：用户环境变量优先，缺省回落 goproxy.cn。
      # 多用户 daemon 模式下 nixpkgs 的 impureEnvVars 读取 nix-daemon 进程环境；
      # 本机 systemd 单元已配 GOPROXY=https://goproxy.cn,direct。
      env.GOPROXY = "https://goproxy.cn,direct";

      # 与上游 build.sh 一致：CGO 关闭、纯静态二进制
      # （buildGoModule 将 CGO_ENABLED 归入 env，须经 env 传入）
      env.CGO_ENABLED = 0;

      # 默认 ldflags 已含 -buildid=（可复现构建），GOFLAGS 已含 -trimpath
      ldflags = [
        "-s"
        "-w"
      ];

      buildPhase = ''
        runHook preBuild
        go build -o $out/bin/${binaryName} ${mainPath}
        runHook postBuild
      '';

      # 二进制已在 buildPhase 直接写入 $out/bin，无需默认的 GOPATH/bin 拷贝
      installPhase = ":";

      # 默认 checkPhase 依赖默认 buildPhase 中定义的 getGoDirs 函数，
      # 覆盖 buildPhase 后必须显式给出 checkPhase，否则单测会被静默跳过
      checkPhase = ''
        runHook preCheck
        export GOFLAGS=''${GOFLAGS//-trimpath/}
        go test ./...
        runHook postCheck
      '';

      meta = {
        inherit description;
        homepage = "https://github.com/zhangjingwei/kuake_cli";
        license = lib.licenses.agpl3Only;
        mainProgram = binaryName;
        platforms = lib.platforms.unix;
      };
    };
in
{
  kuake = mkKuake {
    pname = "kuake";
    mainPath = "./cmd";
    binaryName = "kuake";
    description = "夸克网盘文件管理 CLI 工具（Quark Cloud Drive CLI），支持目录/文件/分享管理、JSON 输出与管道模式";
  };

  kuake-mcp = mkKuake {
    pname = "kuake-mcp";
    mainPath = "./mcp";
    binaryName = "kuake-mcp";
    description = "kuake 的 MCP server（stdio），为 Claude Code 等 MCP 客户端提供 14 个夸克网盘操作工具";
  };
}
