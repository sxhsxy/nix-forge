# tests/

本目录存放 NixOS VM 集成测试，目录结构与模块一一对应：

- `tests/nixos/<name>.nix` 对应 `modules/nixos/<name>/`
- `tests/home/<name>.nix` 对应 `modules/home/<name>/`

测试文件是一个 NixOS 模块 + `testScript`：

```nix
# tests/nixos/forge-example.nix
{
  services.forgeExample.enable = true;

  testScript = ''
    machine.wait_for_unit("multi-user.target")
    machine.succeed("grep -q 'Hello from nix-forge!' /etc/forge-example.conf")
  '';
}
```

接入 flake 的 checks（按需，会显著增加求值/构建时间）：

```nix
# flake.nix —— checks 中
checks.${system}.forge-example =
  pkgs.testers.runNixOSTest (import ./tests/nixos/forge-example.nix);
```

## 最低门槛（仓库自带）

除集成测试外，flake 自带 `checks.${system}.module-eval` 冒烟检查：对所有模块
入口文件执行 `nix-instantiate --eval`，任何语法/导入错误都会让
`nix flake check` 失败。这是新增模块必须通过的最低门槛。
