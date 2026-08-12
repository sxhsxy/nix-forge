{
  config,
  lib,
  ...
}:
let
  cfg = config.services.myModule;
in
# 实现逻辑：读取 options 产出系统配置，所有副作用包在 mkIf 里。
{
  config = lib.mkIf cfg.enable {
    # 示例：向 /etc 写一个配置文件（删掉并换成你的实现）
    # environment.etc."my-module.conf".text = ''
    #   greeting = ${cfg.greeting}
    # '';
  };
}
