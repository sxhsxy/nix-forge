{
  lib,
}:
{
  # 为模块注入统一的 meta（name / category / description / doc），
  # 供聚合器、文档工具与下游消费者查询模块元信息。
  # 与手写 meta 二选一，字段保持一致即可。
  #
  # 用法：
  #   lib.mkModule {
  #     name = "my-module";
  #     category = "nixos";
  #     description = "一句话说明";
  #     module = { config, lib, pkgs, ... }: { ... };
  #   }
  mkModule =
    {
      name,
      category,
      description,
      module,
    }:
    {
      config,
      lib,
      pkgs,
      ...
    }@args:
    let
      evaluated = module args;
    in
    evaluated // {
      meta = (evaluated.meta or { }) // {
        inherit name category description;
        doc = "docs/modules/${category}/${name}.md";
      };
    };
}
