# Changelog

本仓库所有值得记录的变更（新增/废弃模块、规范修订、破坏性变更）都写在这里，按时间倒序。

## [Unreleased]

### Added

- 仓库骨架：flake 自动发现聚合（nixosModules / homeModules / overlays）、模块冒烟检查（module-eval）、代码风格 formatter
- 代码组织结构规范 v1.0（docs/structure.md）
- 新增模块速成指南（docs/authoring.md）
- 示例模块 `forge-example`（NixOS 四件套）
- 模块脚手架模板 `#module`
- 决策：模块顶层禁止自定义 meta 字段（nixpkgs 对 config.meta 严格校验），模块身份由目录结构承载
- 新增 `kuake-cli`：overlay（kuake / kuake-mcp 包，自 mynixpkgs 迁移）+ NixOS 模块（`programs.kuakeCli`）
- `kuake-cli` 改为双上下文模块（规范 §3.5）：dual.nix 标记 + `options ? home` 分流（勿用 `config ? home`，会无限递归），同时注册 `nixosModules` / `homeModules`；flake 新增 home-manager 输入用于集成验证；`lib.discoverDualModules`
