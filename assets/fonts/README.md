# Protos bundled font subset

`ProtosSansSC-Subset.otf` is a glyph subset of **Noto Sans CJK SC Regular**, used only as the CJK fallback beneath Godot's built-in primary UI font. It contains the codepoints present in the canonical `localization/zh-CN.json` values at generation time; English and existing typography metrics remain owned by `ThemeDB.fallback_font`. `AetheriaTheme` constructs its `FontFile` directly from these tracked OTF bytes so a pulled worktree never depends on a generated `.godot/imported/*.fontdata` cache artifact. The Web export preset preserves the raw bytes; pack-only verification must prove that invariant.

The source font was `/usr/share/fonts/opentype/noto/NotoSansCJKsc-Regular.otf` from Ubuntu package `fonts-noto-cjk`, with SHA-256 `2c76254f6fc379fddfce0a7e84fb5385bb135d3e399294f6eeb6680d0365b74b`. The generated subset SHA-256 is `b7303b6a0226a30d069485752d2f5badc95ec20d4bcb745dfbea2ac3e8dfb947`.

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
