# Protos bundled font subset

`ProtosSansSC-Subset.otf` is a glyph subset of **Noto Sans CJK SC Regular**, used only as the CJK fallback beneath Godot's built-in primary UI font. It contains the codepoints present in the canonical `localization/zh-CN.json` values at generation time; English and existing typography metrics remain owned by `ThemeDB.fallback_font`.

At runtime, `AetheriaTheme` loads the tracked OTF source through `FontFile.load_dynamic_font()` before consulting Godot's imported-resource loader. Tests require the resulting in-memory font data to be byte-identical to the tracked source. This keeps pulled worktrees compilable when `.godot/imported/*.fontdata` is missing or stale, while exported packs retain a `ResourceLoader` fallback if the source path is not directly file-accessible. The Web export preset preserves the raw bytes, and pack-only verification proves that invariant. Generated `.fontdata` remains a disposable cache, never a source artifact.

The source font was `/usr/share/fonts/opentype/noto/NotoSansCJKsc-Regular.otf` from Ubuntu package `fonts-noto-cjk`, with SHA-256 `2c76254f6fc379fddfce0a7e84fb5385bb135d3e399294f6eeb6680d0365b74b`. The generated subset SHA-256 is `804a197fdc6fc517d502f03127acc6982682f279c22361eeba7cd486552f571e`.

The font is distributed under the SIL Open Font License 1.1. The complete package copyright and license notice is preserved in `NotoSansCJK-COPYRIGHT.txt`.

Regenerate from the repository root with:

```bash
jq -r '.entries[]' localization/zh-CN.json | tr -d '\n' > /tmp/protos-zh-corpus.txt
pyftsubset /usr/share/fonts/opentype/noto/NotoSansCJKsc-Regular.otf \
  --text-file=/tmp/protos-zh-corpus.txt \
  --output-file=assets/fonts/ProtosSansSC-Subset.otf \
  --layout-features='*' --glyph-names --symbol-cmap --legacy-cmap \
  --notdef-glyph --notdef-outline --recommended-glyphs \
  --name-IDs='*' --name-legacy --name-languages='*'
rm /tmp/protos-zh-corpus.txt
```
