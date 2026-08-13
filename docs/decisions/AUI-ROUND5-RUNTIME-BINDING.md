# AUI Round-5 Character Runtime Binding

- **Decision owner:** Poseidon
- **Effective:** 2026-08-13
- **State:** human-final accepted
- **Accepted candidate:** `441cb80b079ee89195ef751dbc26e67b426600d0`
- **Accepted at:** 2026-08-13T10:13:37Z
- **Scope:** approved Round-5 allied roster, allied portraits, and enemy character sheet

## Decision

Replace the procedurally generated operator thumbnails, operator battle art, and enemy battle art with deterministic runtime derivatives of the approved Round-5 character sheets.

The binding preserves every existing logical asset ID, path pattern, native canvas, pivot, and animation-frame count:

- ten `portrait_<operator>` assets at 128×128;
- ten operator assets at 32×32 with five legacy animation frames;
- six enemy assets at their existing 24×24, 32×32, or 48×48 canvases with two walk frames;
- charmable enemy variants remain deterministic derivatives and retain the exact charm probe color.

No gameplay, simulation, save, replay, localization, UI-layout, or balance contract changes. Agent F's active AUI-12 paths remain untouched.

## Acceptance state

Poseidon approved the exact candidate after reviewing fresh windowed captures of squad select, portrait inventory, operator animation regions, and base/charmed enemy variants. Round-5 character provenance is therefore `human_final_accepted` and all corresponding manifest entries are `placeholder: false`.

This decision applies only to the exact reviewed character bytes at candidate `441cb80b079ee89195ef751dbc26e67b426600d0`. The subsequent acceptance-state commit changes metadata and generated manifest/provenance only; it does not alter the reviewed PNGs. Any later character-byte change returns the affected asset to review-pending.

## Reproduction

```bash
godot --headless --path . -s tools/gen_assets.gd
```

The canonical generator creates deterministic fallbacks first, then `tools/art_pipeline/characters/import_round5_sheets.py` replaces the character paths from the retained source sheets and regenerates canonical provenance.
