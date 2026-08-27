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

This section will be updated after implementation with final source revision, generated asset hashes, exact display footprints, procedural amplitudes, test counts, export artifact hashes, managed URLs, and WebDev checkpoint identity.
