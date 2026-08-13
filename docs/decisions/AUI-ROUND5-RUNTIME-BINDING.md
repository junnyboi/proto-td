# AUI Round-5 Character Runtime Binding

- **Decision owner:** Poseidon
- **Effective:** 2026-08-13
- **State:** runtime candidate authorized; final in-game review pending
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

The source concepts are already owner-approved. Normalized runtime bytes remain `human_concept_accepted_runtime_review_pending` and manifest `placeholder: true` until Poseidon reviews fresh exact-candidate in-game captures. Final acceptance, if granted, flips only the character placeholder/provenance acceptance state and then runs the release gate; a machine may not infer that verdict.

## Reproduction

```bash
godot --headless --path . -s tools/gen_assets.gd
```

The canonical generator creates deterministic fallbacks first, then `tools/art_pipeline/characters/import_round5_sheets.py` replaces the character paths from the retained source sheets and regenerates canonical provenance.
