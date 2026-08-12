{
  config,
  lib,
  ...
}:
# 选项声明：纯声明，不做任何副作用。
# 规范要点：
#   - 选项命名空间 services.<模块名 lowerCamelCase>，必须包含模块名防冲突；
#   - 每个布尔开关用 lib.mkEnableOption 并提供 description；
#   - 禁止在这里写文件、fetch、exec 等一切副作用。
{
  options.services.forgeExample = {
    enable = lib.mkEnableOption "nix-forge 示例服务（写入 /etc/forge-example.conf）";

    message = lib.mkOption {
      type = lib.types.str;
      default = "Hello from nix-forge!";
      description = "写入配置文件正文的问候语。";
      example = "Hello, NixOS!";
    };
  };
}
