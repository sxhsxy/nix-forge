# kuake-cli

安装夸克网盘（Quark Cloud Drive）相关工具：

- `kuake` —— 夸克网盘文件管理 CLI（目录/文件/分享管理、JSON 输出与管道模式）；
- `kuake-mcp` —— kuake 的 MCP server（stdio），为 Claude Code 等 MCP 客户端
  提供 14 个夸克网盘操作工具。

**双上下文模块**（规范 §3.5）：同一份代码同时注册为
`nixosModules.kuake-cli` 与 `homeModules.kuake-cli`，config 按运行上下文分流：
home-manager → `home.packages`；NixOS → `environment.systemPackages`。

包定义迁移自 `mynixpkgs/kuake-cli`，**单一来源在 `modules/overlays/kuake-cli.nix`**
（overlays/ 是仓库的包层；lib/ 禁 pkgs，modules/ 是配置层）。本模块以
`(import ../../overlays/kuake-cli.nix) pkgs pkgs` 方式复用同一份包，改包只改
overlay 一处。

## 选项

| 选项 | 类型 | 默认值 | 说明 |
| ---- | ---- | ------ | ---- |
| `programs.kuakeCli.enable` | bool | `false` | 安装 kuake 与 kuake-mcp |
| `programs.kuakeCli.package` | package | overlay 的 `kuake` | kuake 包，可覆盖 |
| `programs.kuakeCli.mcpPackage` | package | overlay 的 `kuake-mcp` | kuake-mcp 包，可覆盖 |
| `programs.kuakeCli.environmentFiles` | list of str | `["$HOME/.config/kuake/.env"]` | 启动前按序加载的 .env 文件列表 |

## 凭证（.env）

kuake / kuake-mcp 是**包装过的二进制**：每次运行前先按序加载
`environmentFiles` 里的 .env 文件（默认 `$HOME/.config/kuake/.env`），
把变量导入环境后再执行真正的程序。因此**无需 export、无需复制文件**，
只需把凭证放进 .env：

```bash
mkdir -p ~/.config/kuake
cat > ~/.config/kuake/.env <<'EOF'
# 浏览器登录 pan.quark.cn → F12 → Network → 复制请求头里的 Cookie
KUAKE_COOKIE="__pus=xxx; __puus=yyy"
EOF
chmod 600 ~/.config/kuake/.env
kuake user    # 验证
```

语义与注意事项：

- **不覆盖已存在的环境变量**：shell 里 export 过的变量优先（与 kuake 自身
  dotenv 语义一致）；多个文件间先到先得；
- 加载是**安全解析**（逐行 read，不 source / 不 eval），cookie 里的分号、
  引号不会被执行，无注入风险；
- 路径支持 `$HOME` 与开头的 `~`（运行时展开）；文件缺失/不可读静默跳过；
- 选项类型是 **str**，且**必须加引号**（如 `"~/secrets/kuake.env"`）：裸写
  `~/...` 会被 nix 当作路径字面量，纯模式下报 "can not be resolved in pure
  mode"；也不要写无引号的绝对路径字面量——path 会被拷贝进 /nix/store，
  cookie 就泄露了；
- 文件权限建议 600；密钥文件由你自己管理（不要提交进 git 或 nix 配置，
  需要声明式密钥管理时用 sops-nix / agenix 与这里共存）。

自定义路径（多个文件按序加载，后加载的不会覆盖先加载的）：

```nix
programs.kuakeCli.environmentFiles = [
  "/etc/kuake/base.env"
  "$HOME/.config/kuake/secret.env"
];
```

## 使用

方式一：NixOS 系统配置（装入 systemPackages）：

```nix
# flake.nix —— 消费方
{
  inputs.nix-forge.url = "github:sxhsxy/nix-forge";
  outputs = { nixpkgs, nix-forge, ... }: {
    nixosConfigurations.myHost = nixpkgs.lib.nixosSystem {
      modules = [ nix-forge.nixosModules.kuake-cli ];
    };
  };
}
```

```nix
# configuration.nix
{ ... }:
{
  programs.kuakeCli.enable = true;
}
```

方式二：home-manager 用户配置（装入 home.packages，同一份模块）：

```nix
# home.nix —— home-manager 配置
{ ... }:
{
  imports = [ inputs.nix-forge.homeModules.kuake-cli ];
  programs.kuakeCli.enable = true;
}
```

方式三：overlay（任意上下文：home-manager、nix shell 等）：

```nix
nixpkgs.overlays = [ nix-forge.overlays.kuake-cli ];
# 之后 pkgs.kuake / pkgs.kuake-mcp 可用
```

## 验证

```bash
nix flake check                     # 冒烟检查：模块可求值

# NixOS 上下文：systemPackages 含 kuake
nix eval --impure --expr 'let f = builtins.getFlake (toString ./.); s = f.inputs.nixpkgs.lib.nixosSystem { modules = [ { nixpkgs.hostPlatform = "x86_64-linux"; } f.nixosModules.kuake-cli { programs.kuakeCli.enable = true; } ]; }; in builtins.map (p: p.name) s.config.environment.systemPackages'

# home-manager 上下文：home.packages 含 kuake（用 flake 的 home-manager 输入）
nix eval --impure --expr 'let f = builtins.getFlake (toString ./.); pkgs = f.inputs.nixpkgs.legacyPackages.x86_64-linux; hm = f.inputs.home-manager.lib.homeManagerConfiguration { inherit pkgs; modules = [ f.homeModules.kuake-cli { programs.kuakeCli.enable = true; } { home = { username = "sxh"; homeDirectory = "/home/sxh"; stateVersion = "26.05"; }; } ]; }; in builtins.map (p: p.name) hm.config.home.packages'
```

## 文件

```
default.nix   入口：imports options/config
options.nix   选项声明（programs.kuakeCli.*）
config.nix    双上下文实现（home.packages / environment.systemPackages 分流）
dual.nix      双上下文标记（存在即同时注册 homeModules，见规范 §3.5）
README.md     本文档
```

包定义见 `../../overlays/kuake-cli.nix`（overlay 单一来源）。
