{
  config,
  lib,
  options,
  pkgs,
  ...
}:
let
  cfg = config.programs.kuakeCli;

  # 包装 kuake / kuake-mcp：运行前按序加载 environmentFiles 中的 .env。
  # 安全要点：
  #   - 逐行 read 解析，不 source / 不 eval（cookie 值含分号也不会有注入风险）；
  #   - 已存在的环境变量优先（用户 shell 优先），文件间先到先得；
  #   - 路径支持 $HOME 与开头的 ~，缺失/不可读文件静默跳过；
  #   - 不 cd 到 .env 所在目录（会破坏 kuake upload 的本地相对路径）。
  # 语法约束（nix 缩进字符串内）：
  #   - 禁止裸 `''`（字符串终止符）与反斜杠转义，bash 空串写 `""`；
  #   - 每个 `${` 必须写 `''${`，因此解析器刻意不用嵌套参数展开
  #     （如 ${key#"${key%%...}"}），改用单层 `?` 通配与严格键名校验。
  wrapKuake =
    binaryName: pkg:
    pkgs.writeShellScriptBin binaryName ''
      for f in ${lib.concatStringsSep " " (map (p: ''"${p}"'') cfg.environmentFiles)}; do
        # 展开开头的 ~ 与路径中的 $HOME（$HOME 未定义时保持原样）
        case "$f" in
          "~"*) f="$HOME''${f#?}" ;;
        esac
        f=''${f//'$HOME'/$HOME}
        [ -r "$f" ] || continue
        while IFS= read -r line || [ -n "$line" ]; do
          case "$line" in
            "" | '#'*) continue ;;
          esac
          key=''${line%%=*}
          val=''${line#*=}
          # 键名必须严格是合法标识符（不要在 = 两边留空格）
          case "$key" in
            [A-Za-z_][A-Za-z0-9_]*) ;;
            *) continue ;;
          esac
          # 去掉值的外围引号（支持 "..." 与 '...'）
          case "$val" in
            '"'*) val=''${val#?} ;;
          esac
          case "$val" in
            *'"') val=''${val%?} ;;
          esac
          case "$val" in
            "'"*) val=''${val#?} ;;
          esac
          case "$val" in
            *"'") val=''${val%?} ;;
          esac
          # 不覆盖已存在的环境变量
          if [ -z "''${!key+x}" ]; then
            export "$key=$val"
          fi
        done < "$f"
      done
      exec ${pkg}/bin/${pkg.meta.mainProgram or pkg.pname} "$@"
    '';
in
# 实现逻辑：所有副作用包在 mkIf 里。
# 双上下文（见 docs/structure.md §3.5）：home-manager → home.packages；
# NixOS → environment.systemPackages（判定用 options ? home，勿用 config ? home）。
{
  config = lib.mkIf cfg.enable (
    if options ? home then
      {
        home.packages = [
          (wrapKuake "kuake" cfg.package)
          (wrapKuake "kuake-mcp" cfg.mcpPackage)
        ];
      }
    else
      {
        environment.systemPackages = [
          (wrapKuake "kuake" cfg.package)
          (wrapKuake "kuake-mcp" cfg.mcpPackage)
        ];
      }
  );
}
