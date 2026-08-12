# home-manager 模块（modules/home/）

本目录存放**纯 home-manager** 模块，规范与 `modules/nixos/` 完全一致：

- 每个模块一个子目录：`modules/home/<name>/`；
- 四件套：`default.nix` / `options.nix` / `config.nix` / `README.md`
  （小模块可全部写进 `default.nix`，但 `default.nix` 必须存在）；
- 自动导出为 flake 的 `homeModules.<name>`，`homeModules.default` 为全部合并；
- ⚠️ home 模块里**不要**写 `systemd`、`environment.etc` 等 NixOS 专属选项。

**NixOS 与 home-manager 通用的双上下文模块不放这里**，而是放
`modules/nixos/<name>/` 并加 `dual.nix` 标记（规范 §3.5），flake 会自动把它
同时注册为 `homeModules.<name>`（实例：`modules/nixos/kuake-cli/`）。

详细规范见 `docs/structure.md`。当前 `modules/home/` 下暂无模块，用脚手架添加第一个：

```bash
nix flake init -t github:sxhsxy/nix-forge#module
```
