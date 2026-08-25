# Reliquary Duelist Animation Production Record

## Scope

The **Reliquary Duelist** now has unique, non-placeholder stationary-tower presentation for `idle` and `attack`. The generated east-facing `NE` and `SE` sequences are paired with deterministic pixel-mirrored `NW` and `SW` derivatives. Gameplay simulation, balance values, targeting, and the existing `guard_2` operator kit remain unchanged; only portrait-based presentation routing changes.

## Canonical sources and generation

The canonical design sources are `reliquary_duelist_design_sheet.png` and `reliquary_duelist_chibi_sheet.png` in this folder. Automatic contrast scoring selected **hot pink** for chroma production. GPT Image 2 generated separate rear-biased NE and front-biased SE neutral keyframes. Veo 3.1 generated the seamless idle carriers; Gemini Omni Flash generated the compact spellblade attacks. Each source carrier is four seconds, 1280×720, H.264, and 24 FPS.

The first NE attack carrier was rejected because it replaced the uniform hot-pink stage with an opaque mottled coral field. That single carrier was regenerated with stricter stage preservation. No successful carrier was rerolled.

## Deterministic processing contract

The production processor sampled **48 frames** per carrier, scaled source media to the 480p ceiling, measured encoded chroma from border pixels, recovered alpha using color distance plus channel dominance, normalized each sequence to one union crop, and emitted lossless WebP masters. Runtime conversion used the neutral frame as its scale anchor, a 192×192 cell, a `(0.5, 0.94)` pivot, and a 174-pixel target subject height.

Idle strips contain **24 frames at 12 FPS** and loop. Attack strips contain **13 frames at 12 FPS**, preserve both ends of source window `[0, 24)`, and do not loop. West-facing frames are exact pixel mirrors of their east-facing counterparts.

| Runtime strip | SHA-256 | Bytes |
|---|---|---:|
| `attack_ne.webp` | `588542201a1693c1536d06b5aad0bd1f8e9cc4331638a98669ef916b8bdcc5e8` | 339,288 |
| `attack_nw.webp` | `d7fbd376f2af813f3bd9278ff07ae706d7c03a2b2f8222c59802e28c7a9c2c9a` | 340,402 |
| `attack_se.webp` | `8969a7868259af875101d92020d280b60807f25b24abc1c02c1defcda17b5ccb` | 322,894 |
| `attack_sw.webp` | `6e9b538b9eb16ad3f0897e0e35b81ffeaaadcb2031e1ed2a185e434c90c83542` | 321,590 |
| `idle_ne.webp` | `faaf85e1154c015903541fd016f0775c85c939051c6714d8c1a2d16e34f78ecb` | 616,982 |
| `idle_nw.webp` | `20b181e9ff4958607709bbf892f0343b5fe3dc19b615837ef10eb25fbb1ca65c` | 617,162 |
| `idle_se.webp` | `db7e193a1c60effcde83aefb498f8d803d914934a728252e15e86d9aa1915cf6` | 536,850 |
| `idle_sw.webp` | `5a98377d12f8a9221360e08b3cf25bbde806f20f57620a162cfeffa90081b12d` | 537,040 |

## Runtime integration

`portrait_reliquary_duelist` resolves to the `reliquary_duelist` presentation template through `OperatorVisualCatalog`. The template references eight non-placeholder manifest IDs under `assets/sprites/operators/animated/reliquary_duelist/`. Ordinary `guard_2` units continue to resolve to the existing `guard_2` visual template.

## Verification

The production validator confirmed frame counts, FPS, loop flags, fixed-cell dimensions, pivot metadata, neutral-anchor scale, source indices, alpha bounds, and exact mirror equality. Godot 4.7.2 imported the eight WebP strips and passed `tests/reliquary_duelist_animation_test.gd`. A real BattleView Xvfb harness rendered all four facings at 1280×720 and 720×1280, exercised an F9 idle-to-attack transition, and produced no script, texture, or scene errors.

**Synchronized base revision:** `2b4503e19a1ed2bdc3f9dceb756ca0a0b92549b3`.
