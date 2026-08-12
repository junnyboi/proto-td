# AUI-10/AUI-10R — S1 Civic-Weatherworks World Assets

**Status:** runtime-integrated revision 2; Poseidon approved final art on exact candidate `60b69a6004a9c843851d9f6c9aee84c88389cb1f`
**Runtime base:** `3936eeda3e25c5f45def229b168fd11c41a048d9`
**Owner:** AGENT D
**Concept authority:** `AUI-DESIGN-D` plus Poseidon's `AUI-DESIGN-D-REVISION-2` selection of Core C + Backdrop B

## Runtime boundary

Poseidon authorized Agent D to integrate and revise its own S1 world assets. Agent F's remote checkpoint is contained in master, its lease expired, and it holds no active worktree, PR, process, or queue claim. Agent E remains unrelated and blocked.

Runtime code never resolves `res://staging/**`. The logical manifest owns import paths, and `data/presentation/s1_world_theme.tres` owns S1-only roles and placement. `StageArtTheme` validates every required manifest ID before `IsoGridBuilder` constructs the presentation. No model, stage geometry, save/hash/replay state, threshold, or localization catalog changes are part of this lane.

## Asset set

| Logical ID | Native geometry | Runtime role | Acceptance state |
|---|---:|---|---|
| `world.s1.ground` | 32×16 | quiet shell-lime passive floor | integrated, human-final accepted |
| `world.s1.route` | 32×16 | warm west→east service route | integrated, human-final accepted |
| `world.s1.elevated` | 32×24 | 32×16 top plus eight wall rows | integrated, human-final accepted |
| `world.s1.backdrop` | 32×16 | low alpine foothill source component | manifested, human-final accepted |
| `world.s1.backdrop_ridge` | 32×24 | mid-ridge source component | manifested, human-final accepted |
| `world.s1.backdrop_peak` | 32×32 | high-peak source component | manifested, human-final accepted |
| `world.s1.backdrop_mist` | 32×16 | mist-ravine source component | manifested, human-final accepted |
| `world.s1.backdrop_panorama` | 208×104 | one continuous, noninteractive Alpine Escarpment behind S1 | integrated, human-final accepted |
| `world.s1.spawn_landmark` | 32×32, pivot `(16,30)` | canvas/intake Spawn identity | integrated, human-final accepted |
| `world.s1.core_landmark` | 32×32, pivot `(16,30)` | Cloud-Seal Orrery Core identity | integrated, human-final accepted |
| `world.s1.rain_measure` | 16×16, pivot `(8,14)` | reserved low-decor candidate | manifested, deliberately unplaced, human-final accepted |
| `world.s1.route_notch` | 32×16 | exactly three neutral cadence notches | integrated, human-final accepted |

All twelve manifest entries have `placeholder = false`. Runtime and staged provenance retain exact final bytes, original/revision approvals, GPT Image 2 source hashes, deterministic tool/contract/palette hashes, and Poseidon's exact-candidate verdict from `docs/media/AUI-10R-REVISION-2-HUMAN-APPROVAL.json`.

## Revision-2 production chain

Poseidon rejected the pressure-tank Core and repeated outside-map fragments, then approved **Cloud-Seal Orrery + Alpine Escarpment**. The exact decision and concept hashes live in `docs/media/AUI-DESIGN-D-REVISION-CORE-C-BACKDROP-B.json`.

The Orrery is synthesized deterministically at 32×32 from the approved open-arc design. The mountain panorama uses a dedicated GPT Image 2 environment-only matte; `prepare_s1_revision_source.py` records the one-time bounded 832×416 source, and `generate_s1_revision_v2.py` performs exact four-to-one BOX reduction plus fixed 12-color, no-dither quantization into 208×104. The runtime panorama is one TextureRect at z=-10, above BattleView's flat canvas at -20 and below all terrain bands; it ignores input and creates no outside-map grid affordances.

## Reproduction and proof

Canonical regeneration order:

```sh
python3 tools/art_pipeline/world/normalize_s1_world.py
python3 tools/art_pipeline/world/generate_s1_revision_v2.py
python3 tools/art_pipeline/world/validate_s1_world.py
```

The second command intentionally reapplies the owner-approved revision after the base AUI-10 generator. The validator rejects asset-set drift, staged/runtime byte divergence, geometry mismatch, soft alpha, reserved probe colors, missing provenance, source/approval/tool hash drift, stage-resource drift, guessed anchors, protected/internal paths, secrets, or inferred human acceptance.

GUT pins all twelve sizes and SHA-256 values. `s1_world_art` proves one continuous panorama, exact themed tiles, three notches, Spawn/Orrery placements, ignored input, unplaced rain measure, and cell-picking round trips. Existing `assets_floor`, `iso_projection_floor`, full verification, fresh clean-artifact RELEASE, independent diff-vs-pins review, and Poseidon's in-game visual verdict remain mandatory.

The playable-surface value board remains median CIE L* `52.124` within `[48,58]` and warm/direct share `0.6670` within `[0.55,0.70]`. The mountain field is cooler and darker than the playable platform. Poseidon reviewed the fresh frozen-candidate overview and focused Orrery/mountain crops, then approved AUI-10R revision 2 on 2026-08-13.
