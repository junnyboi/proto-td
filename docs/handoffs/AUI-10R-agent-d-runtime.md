# AUI-10R — Agent D S1 Runtime Integration Handoff

**Owner:** AGENT D
**Branch:** `agent-d/s1-world-runtime`
**Base:** `3936eeda3e25c5f45def229b168fd11c41a048d9`
**Assurance lane:** RELEASE
**Current state:** implemented and machine-green; human visual verdict and final RELEASE freeze remain pending

## What changed

The eight validated S1 civic-weatherworks PNGs are promoted byte-for-byte into `assets/world/s1/` and registered under `world.s1.*` manifest IDs. Runtime provenance lives in `assets/provenance/world/s1/`. The typed `StageArtTheme` resource binds only stage `s1`; other stages continue through the generic terrain lane.

`BattleView` loads and validates the theme through `data/presentation/<stage_id>_world_theme.tres`. `IsoGridBuilder` projects the themed ground, route, elevation, backdrop ring, exactly three route notches, and the typed Spawn/Core landmarks. The rain measure remains manifest-backed but unplaced. Every decoration ignores input; picking still uses the existing projection seam.

No simulation, StageDef geometry, save/hash/replay state, gameplay data, threshold, localization catalog, or verification entrypoint changed.

## Approval and provenance

The exact approved concept record is `docs/media/AUI-DESIGN-D-approved-manifest.json`. The accepted manifest SHA-256 is `91cfda9a1c5b199b5c69d42c82d58fbe4a186b270b828180b16ad7c1cb811e51`; the approval-receipt SHA-256 is `d7bdbb4b3401932a20fd1cfdf66b7ba3b05e3bab4b7b2133b9958162271781e1`. All six canonical image hashes were reverified before implementation. The approved focused S1 keyframe hash is `991f2c3d03da7160aa53c760645f69a0a9dea3bdf554f17275f74d120ac1335d`.

Runtime art remains `placeholder = true` and `human_acceptance.final_art = false` until Poseidon accepts the live result. Agent E content remains wholly excluded.

## Required evidence and review

Before merge, freeze one commit and run the existing staging art gate on that clean commit, GUT including `test_stage_art_theme.gd`, `s1_world_art` headless/windowed, `assets_floor`, `iso_projection_floor`, a fresh uninterrupted `scripts/verify.sh --full`, then one cache-bypassed clean-artifact RELEASE rerun. The exact frozen diff must receive an independent diff-vs-pins audit. Localization review must confirm the lane adds no visible copy or catalog delta. Poseidon must review the unobscured `s1_world_integrated.png`; only that verdict may clear final-art placeholder/provenance flags in a later verified commit.

If human review requests a visual adjustment, change presentation data/assets only, preserve all tests and thresholds, rerun the complete RELEASE protocol, and present a fresh screenshot. The verification fleet has no mercy, which is why it remains useful.
