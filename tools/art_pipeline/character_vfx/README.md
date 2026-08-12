# AUI-34 Character/VFX Pipeline

This directory owns the offline deterministic normalization contract for staged character and VFX frame sets. The Python 3.12.3 + Pillow 12.3.0 backend is the canonical PNG encoder. It accepts strict JSON plus a trusted input root, performs exact keying, binary-alpha thresholding, integer nearest-neighbor sampling, palette remapping, deterministic component filtering, foot-pivot anchoring, fixed 4×2 atlas composition, and a deterministic light/dark/grayscale contact sheet.

The package is runtime-unbound. It never edits `assets/**`, the canonical manifest, Agent F presentation contracts, gameplay, tests, thresholds, or human acceptance state.

```bash
export PYTHONDONTWRITEBYTECODE=1
python3 -B tools/art_pipeline/character_vfx/normalize.py build \
  --spec staging/qa/character-vfx/fixtures/spec.json \
  --input-root staging/qa/character-vfx/fixtures/source \
  --output /tmp/aui34-python --clean
```

Every failure exits non-zero with a compact measured JSON diagnostic. Publication is atomic: the candidate packet is fully re-opened and validated before its directory is renamed into place.
