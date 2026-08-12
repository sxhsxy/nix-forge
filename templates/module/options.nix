{
  config,
  lib,
  ...
}:
# 选项声明：纯声明，不做任何副作用。
{
  options.services.myModule = {
    enable = lib.mkEnableOption "my-module";

    # 在这里添加更多选项，例如：
    # greeting = lib.mkOption {
    #   type = lib.types.str;
    #   default = "hi";
    #   description = "示例字符串选项";
    #   example = "你好";
    # };
  };
}
