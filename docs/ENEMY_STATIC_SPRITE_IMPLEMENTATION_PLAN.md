# Enemy Static-Sprite Implementation Plan

## Objective

Replace every non-grunt enemy animation/fallback path with a core-resident static sprite and Godot-owned procedural presentation, while preserving all deterministic gameplay, lore, accessibility, responsive layout, Charm behavior, damage feedback, and Web deployment contracts. The Grunt remains the only frame-animated enemy.

## Constraints

The implementation uses Godot 4.7.2 and the repository Web preset. Generated 1920×1920 sources remain under `docs/enemy-redesign/source/concepts/`; runtime derivatives use transparent 640×640 canvases with the subject’s longest visible edge near 600 px. In-game footprint is controlled exclusively by `EnemyAnimator`. No existing enemy statistics, stages, waves, target policies, attack cadence, balance hashes, campaign data, or save formats may change.

## Phase 1 — Reproduce and close the fallback path

1. Add an all-enemy visual harness that spawns the nine canonical IDs and records texture versus fallback state.
2. Assert that every non-grunt is core-resident and that the Grunt alone uses a multi-frame animation.
3. Add a bounded missing-texture diagnostic and a regression that fails when any production enemy resolves to a solid square.
4. Preserve the existing fail-safe `ColorRect` only for corrupt development builds; it must never appear in release verification.

**Gate:** direct import, harness capture, strict log scan, and a machine-readable nine-enemy texture report.

## Phase 2 — Process GPT Image 2 sources

1. Preserve all 1920×1920 concept masters unchanged.
2. Deterministically remove the temporary green chroma field and edge spill.
3. Trim transparent borders, preserve aspect ratio, scale the visible subject to at most 600 px, and place it on a 640×640 transparent canvas.
4. Anchor walkers near the bottom center and center aerial units vertically.
5. Generate SHA-256 provenance and visual contact sheets.

**Gate:** alpha/canvas/dimension assertions, source immutability hashes, and visual inspection at 100%, 10%, and expected in-game scale.

## Phase 3 — Integrate core static resources

1. Add an `enemy_static_manifest.tres` layer with one frame per non-grunt.
2. Merge the layer into `Art` with duplicate-ID fail-closed behavior.
3. Map each non-grunt to `enemy_static_<id>`; retain the current Grunt directional animation IDs.
4. Use aspect-preserving texture layout and per-archetype display footprints.
5. Keep all eight runtime textures out of Web exclusion and deferred content-pack patterns.

**Gate:** manifest/schema tests, source/import resolution, Web export boundary checks, and zero dependency on `enemy-variants` for non-grunt rendering.

## Phase 4 — Procedural locomotion and attack presentation

1. Add typed motion profiles for ground, aerial, heavy, caster, siege, and boss silhouettes.
2. Drive bob, hover, roll, lean, scale, brace, and recoil from render time, stable enemy ID phase, path tangent, blocked state, and existing attack counters.
3. Apply transforms only to the sprite child. Keep body position, shadow anchor, HP bar, model state, and collision semantics fixed.
4. Mirror the static image horizontally for westward travel without creating extra assets.
5. Suppress continuous rotation/lateral drift/squash under Reduced Motion and retain discrete attack-state changes.

**Gate:** transform bounds, deterministic replay snapshots, reduced-motion assertions, Charm tint, damage flash, and representative Xvfb sequences.

## Phase 5 — Documentation and deprecation

1. Update this plan with final paths, motion amplitudes, tests, and any deviations.
2. Update README visual direction and Web export notes.
3. Mark legacy `experimental_salvage` and `enemy-variants` atlases as deprecated for enemy runtime use; retain historical source/provenance unless a separate cleanup is approved.
4. Update content-pack tests so enemy rendering no longer requires the `enemy-variants` pack.

**Gate:** documentation references match code and export behavior exactly.

## Phase 6 — Regression, export, and deployment

1. Re-fetch and reconcile `master`; preserve concurrent features.
2. Run direct import, bounded headless boot, every repository regression, and all smoke harnesses.
3. Run Xvfb visual checks for the full roster at landscape and portrait sizes, including normal and Reduced Motion states.
4. Export through `Web`; require HTML, JavaScript, WASM, and PCK artifacts and stage all remaining optional packs/streams.
5. Serve over HTTP and verify exact MIME/bytes, runtime console/network health, Title Start, battle rendering, no eager cinematics, responsive zero-chrome geometry, and no square fallbacks.
6. Retarget the newest `proto-td-web` forward-only host, run `pnpm check` and `pnpm build`, restart, save a checkpoint, and publish when an explicit publish tool is available.

**Gate:** pushed canonical source, exact managed artifacts, final browser captures, clean logs, saved WebDev checkpoint, and complete verification records.

## Planned regression coverage

| Test or harness | Contract |
|---|---|
| `enemy_static_sprite_test.gd` | Eight non-grunt static IDs resolve from core; Grunt alone remains animated; no production fallback |
| `enemy_procedural_motion_test.gd` | Profile amplitudes, attack synchronization, west mirroring, fixed body anchor, Reduced Motion |
| `enemy_roster_visual_harness` | Nine-enemy landscape/portrait capture and texture/fallback report |
| Existing enemy/battle tests | Stats, targeting, balance, Charm, damage feedback, stage composition, controller accessibility |
| Web export test | Static sprite paths remain in core; obsolete enemy pack is not required for rendering |
| Browser acceptance | Real battle shows every archetype, zero missing-resource errors, responsive fullscreen host |

## Completion record

The implementation is complete on the pushed canonical lineage through `ed77425`. Investigation confirmed the square was the release fallback `ColorRect`: production S2–S4 atlas WebPs were excluded from the core PCK, while the accepted host supplied no matching `--content-pack` arguments. The remaining experimental families were vulnerable to the same deferred-resource failure. The redesign removes that dependency rather than decorating the fallback.

GPT Image 2 concept masters are preserved under `docs/enemy-redesign/source/concepts/`. `tools/enemy_sprites/process_static_enemy_sprites.py` performs reproducible chroma cleanup, detached-component rejection, ground/aerial anchoring, 600px subject normalization on transparent 640×640 canvases, SHA-256 provenance, and lossless mipmapped import pinning. The generated manifest is `assets/enemy_static_manifest.tres`; runtime textures are `assets/sprites/enemies/static/<enemy>.png`; exact source/runtime hashes are in `docs/enemy-redesign/SHA256SUMS.txt` and `docs/enemy-redesign/static-sprite-processing.json`.

| Enemy | Godot footprint | Frequency | Bob/hover | Roll | Attack lunge |
|---|---:|---:|---:|---:|---:|
| Runner | 58px | 2.80Hz | 1.2px | 0.030rad | 3.0px |
| Shieldbearer | 72px | 1.35Hz | 1.4px | 0.013rad | 3.0px |
| Breacher | 80px | 1.15Hz | 1.3px | 0.014rad | 4.0px |
| Heavy | 74px | 0.82Hz | 1.0px | 0.012rad | 2.5px |
| Hunter Drone | 56px | 1.70Hz | 2.2px hover | 0.035rad | 1.0px |
| Interceptor | 66px | 1.25Hz | 1.7px hover | 0.040rad | 2.0px |
| Channeler | 68px | 1.10Hz | 1.4px | 0.020rad | 2.0px |
| Gatecrasher | 88px | 0.72Hz | 1.0px | 0.011rad | 3.0px |

`EnemyAnimator` now selects `enemy_static_<id>` for all eight non-grunts, keeps Grunt directional frame animation, applies deterministic ID-phased transform motion to the sprite child only, mirrors westward travel, derives attack anticipation/impact from existing counters, preserves Charm tint and damage flash, and suppresses rotation/lateral drift/squash under Reduced Motion. Missing core textures emit a bounded diagnostic and mark the body for harness failure. The legacy `assets/enemy-variants` sources remain preserved but are no longer routed or staged; Web content packs now contain only the eleven advanced-operator classes.

The planned separate procedural-motion test was intentionally folded into `tests/enemy_static_sprite_test.gd`, because the same fixture can prove manifest resolution, one-frame identity, body-anchor immutability, transform motion, attack telegraph, Charm tint, and Reduced Motion without duplicating battle construction. `test/enemy_roster_visual_harness.tscn` emits a nine-enemy texture/fallback report and captures landscape/portrait views. The final native gate passed Godot 4.7.2 direct import, bounded boot, **68 regression scripts**, **6 Xvfb smoke harnesses**, and strict parse/runtime/resource log scans. Exact Web artifact hashes, managed URLs, browser evidence, and checkpoint identity are maintained in the forward-only `proto-td-web` release records.
