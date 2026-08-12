# my-module

（一句话描述这个模块做什么。示例见 `modules/nixos/forge-example/README.md`。）

## 选项

| 选项 | 类型 | 默认值 | 说明 |
| ---- | ---- | ------ | ---- |
| `services.myModule.enable` | bool | `false` | 启用本模块 |

## 使用

```nix
# flake.nix —— 消费方
{
  inputs.nix-forge.url = "github:sxhsxy/nix-forge";
  outputs = { nixpkgs, nix-forge, ... }: {
    nixosConfigurations.myHost = nixpkgs.lib.nixosSystem {
      modules = [ nix-forge.nixosModules.my-module ];
    };
  };
}
```

```nix
# configuration.nix
{ ... }:
{
  services.myModule.enable = true;
}
```

## 验证

```bash
nix flake check
```
