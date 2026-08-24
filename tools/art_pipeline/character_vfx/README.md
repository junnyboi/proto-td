# AUI-34 Character/VFX Pipeline

This package owns an **offline, deterministic, runtime-unbound** normalization contract for staged character and VFX frame sets. Python 3.12.3 with Pillow 12.3.0 is the canonical PNG encoder. Godot 4.7.2 `Image` is the fallback. Both implement the same integer pixel algorithm, atlas geometry, contact-sheet raster, strict source containment, packet validation, and rollback-safe publication.

The package never edits `assets/**`, canonical manifests, Agent F presentation contracts, gameplay, tests, thresholds, localization, or human acceptance state.

## Python canonical backend

```bash
export PYTHONDONTWRITEBYTECODE=1
python3 -B tools/art_pipeline/character_vfx/normalize.py build \
  --spec staging/qa/character-vfx/fixtures/spec.json \
  --input-root staging/qa/character-vfx/fixtures/source \
  --output /tmp/aui34-python --clean
```

## Godot Image fallback

```bash
export GODOT="${GODOT:-$HOME/.local/bin/godot}"
timeout 60 "$GODOT" --headless --path . \
  -s res://tools/art_pipeline/character_vfx/godot/normalize.gd -- \
  build --backend godot \
  --spec staging/qa/character-vfx/fixtures/spec.json \
  --input-root staging/qa/character-vfx/fixtures/source \
  --output /tmp/aui34-godot --clean
```

## Differential verification

```bash
timeout 180 python3 -B staging/qa/character-vfx/verify_pipeline.py \
  --backend differential --clean --seed 42 \
  --input-root staging/qa/character-vfx/fixtures/source \
  --process-timeout-seconds 60 \
  --evidence-root /tmp/aui34-differential \
  --godot "$GODOT"
```

Every failure exits non-zero with a measured diagnostic. Each candidate packet is reopened and validated before atomic publication. Replacement writes and verifies the raw bytes of a complete canonical salvage of the old packet before any destructive rollback cleanup. A salvage failure leaves the complete rollback intact; a cleanup failure may leave a partial rollback but retains the complete independently decodable salvage. Both are red and require deliberate operator recovery. A timeout, missing report, stale output, zero checks, or dirty tested worktree is red.

See [`docs/art/character-vfx/AUI-34-pipeline-contract.md`](../../../docs/art/character-vfx/AUI-34-pipeline-contract.md) for the complete operator contract.
