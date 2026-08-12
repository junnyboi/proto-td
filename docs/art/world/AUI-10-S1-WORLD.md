# AUI-10/AUI-10R — S1 Civic-Weatherworks World Assets

**Status:** runtime-integrated RELEASE candidate on `agent-d/s1-world-runtime`; human final-art acceptance unset
**Runtime base:** `3936eeda3e25c5f45def229b168fd11c41a048d9`
**Owner:** AGENT D
**Concept authority:** `AUI-DESIGN-D`, accepted manifest `91cfda9a1c5b199b5c69d42c82d58fbe4a186b270b828180b16ad7c1cb811e51`

## Runtime boundary

Poseidon explicitly authorized Agent D to integrate its own approved S1 world assets. Agent F's remote checkpoint is contained in master, its lease expired, and it holds no active worktree, PR, process, or queue claim. Agent E remains unrelated and blocked.

The eight staged PNGs were copied byte-for-byte into `assets/world/s1/`; runtime code never resolves `res://staging/**`. The logical manifest owns the import paths, and `data/presentation/s1_world_theme.tres` owns S1-only role and placement data. `BattleView` validates the resource and manifest IDs, then passes it to `IsoGridBuilder` as a disposable presentation projection. No model, stage geometry, save/hash/replay state, or threshold changes are part of this lane.

## Asset set

| Logical ID | Native geometry | Runtime role | Acceptance state |
|---|---:|---|---|
| `world.s1.ground` | 32×16 | quiet shell-lime passive floor | integrated, human-final unset |
| `world.s1.route` | 32×16 | warm west→east service route | integrated, human-final unset |
| `world.s1.elevated` | 32×24 | 32×16 top plus exactly eight wall rows | integrated, human-final unset |
| `world.s1.backdrop` | 32×24 | broken non-playable court-edge fragments | integrated, human-final unset |
| `world.s1.spawn_landmark` | 32×48, pivot `(16,30)` | canvas/intake Spawn identity | integrated, human-final unset |
| `world.s1.core_landmark` | 32×48, pivot `(16,30)` | squat regulator Core identity | integrated, human-final unset |
| `world.s1.rain_measure` | 32×32 | reserved low-decor candidate | manifested and deliberately unplaced |
| `world.s1.route_notch` | 32×16 | exactly three neutral cadence notches | integrated, human-final unset |

All eight manifest entries retain `placeholder = true`. Their runtime provenance sidecars retain the exact GPT Image 2 model/prompt/reference chain, final byte hashes, the approval receipt and accepted-manifest hashes, and `human_acceptance.final_art = false`.

## Reproduction and proof

`python3 tools/art_pipeline/world/normalize_s1_world.py` deterministically rebuilds the staged native candidates and QA boards. `python3 tools/art_pipeline/world/validate_s1_world.py` rejects geometry drift, soft alpha, reserved probe colors, missing provenance, source-model drift, accidental human-final claims, stage-hash drift, guessed anchors, internal absolute paths, and common secret markers. The runtime unit test additionally pins every promoted PNG SHA-256 and verifies all eight manifest bindings.

The `s1_world_art` scenario proves the live S1 grid uses the new ground, route, elevation, and backdrop textures; exactly three notches; exact Spawn/Core placements; ignored input; unplaced rain measure; and cell-picking round trips. Its windowed lane produces `s1_world_integrated.png` after the startup banner clears. Existing `assets_floor` and `iso_projection_floor` remain required regression gates.

The staged value board remains median playable-surface CIE L* `52.124` within `[48,58]` and warm/direct share `0.6670` within `[0.55,0.70]`. Runtime visual acceptance, Web performance, and final-art promotion remain pending fresh RELEASE evidence, independent review, and Poseidon's verdict.
