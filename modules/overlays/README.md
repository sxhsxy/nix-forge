# overlays（modules/overlays/）

本目录存放 overlay：**一个文件一个 overlay，文件名即 overlay 名**。

- 文件形如标准 overlay：`final: prev: { ... }`；
- 自动导出为 flake 的 `overlays.<文件名>`；`overlays.default` 按字母序组合全部；
- 与某模块强相关的 overlay 建议与模块同名，表达关联；
- overlay 可改写现有包属性，也可新增自定义包（如 `kuake-cli`）；不写模块逻辑；
- 包定义单一来源：同一包同时被 overlay 与 NixOS 模块使用时，包定义放 overlay
  文件，模块以 `(import <overlay>) pkgs pkgs` 复用（见 `modules/nixos/kuake-cli/`）。

详细规范见 `docs/structure.md` §7。已有 `kuake-cli`（新增 kuake / kuake-mcp 包）。
例如要改写 `hello` 包：

```nix
# modules/overlays/hello.nix
final: prev: {
  hello = prev.hello.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./hello.patch ];
  });
}
```
