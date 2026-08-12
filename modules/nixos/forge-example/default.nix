{
  config,
  lib,
  pkgs,
  ...
}:
# 示例模块：演示 nix-forge 的「四件套」结构
# （default.nix + options.nix + config.nix + README.md）。
# 本模块实现一个纯配置型「服务」：启用后向 /etc/forge-example.conf 写入问候语，
# 不安装任何软件包，便于离线演示与测试。
{
  imports = [
    ./options.nix
    ./config.nix
  ];

  # 模块元信息：手写 meta 与 lib.mkModule 自动注入二选一（见 lib/mkModule.nix），
  # 字段必须与规范一致：name / category / description / doc。
  meta = {
    name = "forge-example";
    category = "nixos";
    description = "示例模块：演示 nix-forge 模块结构规范（四件套）";
    doc = "docs/structure.md#3-模块文件规范四件套";
  };
}
