# overlays（modules/overlays/）

本目录存放 overlay：**一个文件一个 overlay，文件名即 overlay 名**。

- 文件形如标准 overlay：`final: prev: { ... }`；
- 自动导出为 flake 的 `overlays.<文件名>`；`overlays.default` 按字母序组合全部；
- 与某模块强相关的 overlay 建议与模块同名，表达关联；
- overlay 只改写包属性，不写模块逻辑。

详细规范见 `docs/structure.md` §7。当前暂无 overlay，例如要改写 `hello` 包：

```nix
# modules/overlays/hello.nix
final: prev: {
  hello = prev.hello.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./hello.patch ];
  });
}
```
