# AUI-10 — S1 Civic-Weatherworks World Assets

**Status:** staged in Agent D's independent ART lane; runtime-unbound
**Branch base:** `975261e8e00a20a0b25fe17e7976d743d509c14b`
**Owner:** AGENT D
**Concept authority:** owner-approved `AUI-DESIGN-D`, including the focused S1 mannequin revision

## Parallel boundary

Agent D owns source-generation records, native asset generation, provenance, presentation data, QA boards, and this handoff. Agent F does **not** block those artifacts. Agent F's later integration seam owns the shared runtime manifest and view binding; this lane deliberately does not edit `assets/manifest.tres`, `assets/asset_manifest.gd`, `scripts/view/**`, scenes, stage data, harness/core APIs, tests, thresholds, `FEATURES.json`, or `scripts/verify.sh`.

The staged presentation payload is `STAGED_UNBOUND` and `non_authoritative`. A runtime consumer must validate its logical IDs, stage-resource hash, offsets, input pass-through, and asset dimensions before binding anything.

`staging/.gdignore` is load-bearing: it prevents Godot from auto-importing unbound candidates and generating `.import` sidecars during unrelated verification. Agent F must copy the accepted eight PNGs into the runtime manifest-owned asset path; removing the staging guard or resolving `res://staging/**` directly is forbidden.

## Asset set

| Logical ID | Native geometry | Purpose | Current state |
|---|---:|---|---|
| `world.s1.ground` | 32×16 | quiet shell-lime passive floor | machine-conformant, human-final unset |
| `world.s1.route` | 32×16 | warm west→east service route | machine-conformant, human-final unset |
| `world.s1.elevated` | 32×24 | 32×16 top plus exactly eight wall rows | machine-conformant, human-final unset |
| `world.s1.backdrop` | 32×16 | broken non-playable court-edge fragments | machine-conformant, human-final unset |
| `world.s1.spawn_landmark` | 32×32, pivot 16×30 | canvas/intake Spawn identity | machine-conformant, human-final unset |
| `world.s1.core_landmark` | 32×32, pivot 16×30 | squat regulator Core identity | machine-conformant, human-final unset |
| `world.s1.rain_measure` | 16×16, pivot 8×14 | low decor candidate | conformant but intentionally unplaced |
| `world.s1.route_notch` | 32×16 | exactly three neutral cadence notches | machine-conformant, human-final unset |

## Reproduction and provenance

`python3 tools/art_pipeline/world/normalize_s1_world.py` deterministically rebuilds every native PNG, provenance sidecar, contact sheet, staged composition, playable-surface mask, and normalization report from checked-in contract/palette/source-ledger facts. `python3 tools/art_pipeline/world/validate_s1_world.py` rejects geometry drift, soft alpha, reserved probe colors, missing/duplicate provenance, source-model drift, accidental human-final claims, stage-hash drift, guessed anchors, internal absolute paths, and common secret markers.

The 16 large GPT Image 2 source rasters remain in the external owner-approval archive and are represented in Git by exact SHA-256, dimensions, mode, prompt hash, and approved-reference hashes. This avoids approximately 59 MB of duplicate binary churn while preserving auditable identity and regeneration inputs.

## Measured staged feasibility

The current deterministic mock preserves the authoritative 8×5 S1 geometry, path `(0,2)`→`(7,2)`, and elevated cells `(3,1)`/`(3,3)`. Median playable-surface CIE L* is `52.124` within `[48,58]`; warm/direct share is `0.6670` within `[0.55,0.70]`. These are staged-raster measurements, not runtime proof.

Runtime viewport fit, picking, endpoint attachment clearance, asset import, Web budget, unit/trap/overlay recognition, and human final-art acceptance remain explicitly unclaimed until the integration lane produces fresh runtime evidence.
