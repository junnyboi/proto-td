# Archive Caster Animation Production Record

## Scope

The **Archive Caster** now has unique, non-placeholder stationary-tower presentation for `idle` and `attack`. Generated `NE` and `SE` sequences are paired with deterministic pixel-mirrored `NW` and `SW` derivatives. Gameplay simulation, balance, targeting, and the existing `caster_1` operator kit remain unchanged; portrait-based presentation routing alone selects these visuals.

## Canonical sources and generation

The canonical sources are `archive_caster_design_sheet.png` and `archive_caster_chibi_sheet.png` in this folder. Automatic contrast scoring selected **neon green** for chroma production. GPT Image 2 generated separate NE and SE neutral keyframes. Veo 3.1 generated quiet looping idles; Gemini Omni Flash generated one compact Astrolabe cast per direction. Each carrier is four seconds, 1280×720, H.264, and 24 FPS.

The carriers preserve the adult premium chibi identity, silver-lilac curled bob, black-plum fitted ritual dress, sheer sleeves, translucent gold-edged panels, heels, suspended reliquary ornaments, and complete concentric Archive Astrolabe with moon-cyan core.

## Deterministic processing contract

The production processor sampled **48 frames** per carrier, scaled to the 480p ceiling, measured encoded chroma from border pixels, recovered alpha using color distance plus channel dominance, normalized each sequence to one union crop, and emitted lossless WebP masters. Runtime conversion used the neutral frame as its scale anchor, a 192×192 cell, `(0.5, 0.94)` pivot, and 174-pixel target subject height.

Idle strips contain **24 frames at 12 FPS** and loop. Attack strips contain **13 frames at 12 FPS** and do not loop. Archive Caster attacks use endpoint-preserving sampling over source window `[0, 32)` because the NE carrier's pulse peaks near frame 23 and completes recovery by frame 31. This preserves a full anticipation→pulse→recovery cycle without changing the engine's 13-frame contract. West frames are exact pixel mirrors of east frames.

| Runtime strip | SHA-256 | Bytes |
|---|---|---:|
| `attack_ne.webp` | `db2c9d6e8fd50a85287d86634d83a7ff59a51711292a54d93838e44357ba229d` | 412,220 |
| `attack_nw.webp` | `04244aca1cfe69f9aa4ac198eb19f4a0f4052c8663d8871387d150d547f0715a` | 412,018 |
| `attack_se.webp` | `3f6eac2f181321c655ade6141ec2bcb020abf6695f5ec920c59fef3e142ccf83` | 374,472 |
| `attack_sw.webp` | `6d5da45262563b1f185cfa3e9b1994eecd5d189bb7b009b47eb47e58c56cad11` | 376,456 |
| `idle_ne.webp` | `46eae333f99b190ccc0cf87540595f18cd1f7a70f66866e7ec43d5db360c0370` | 836,898 |
| `idle_nw.webp` | `86e4493b1195c82b16cff6ad5ff0989b3c0d06d74de927010b6225888fe05f60` | 838,086 |
| `idle_se.webp` | `40e9f9d3b582ec7d8b6ab6aa78ee7d01be52db4fc34a29175d4fdf401f925f5e` | 730,686 |
| `idle_sw.webp` | `f43e8e2865aed998a2e788ac51239c4c603ad9b9a5a16a9a2ff02e9fab088eb3` | 730,070 |

## Runtime integration

`portrait_archive_caster` resolves to the `archive_caster` presentation template through `OperatorVisualCatalog`. The template references eight non-placeholder manifest IDs under `assets/sprites/operators/animated/archive_caster/`. Ordinary `caster_1` units continue to use their existing visual template.

## Verification

The production validator confirmed frame counts, FPS, loop flags, fixed-cell dimensions, pivot metadata, neutral-anchor scale, source indices, alpha bounds, and exact mirror equality. Godot 4.7.2 imported the WebP strips and passed `tests/archive_caster_animation_test.gd`. A real BattleView Xvfb harness rendered all four facings at 1280×720 and 720×1280, exercised an F9 idle-to-attack transition, and produced no script, texture, or scene errors.

**Synchronized base revision:** `ca3e8a51c805aeeda85cda425b79d58dbb43acb3`.
