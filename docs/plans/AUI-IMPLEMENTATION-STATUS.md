# Aetheria Art/UI Implementation Status

## AUI-00 — Presentation contracts and baselines

- Repository checkpoint: `a46fe9c` (`AGENT F - Claim AUI presentation contracts`), fully contained in current master.
- Ownership state: Agent F's external lease expired at `2026-08-12T20:42:17.172134Z`; no Agent F worktree, pull request, process, or active `docs/todo.md` claim exists.
- Owner decision: Poseidon explicitly ruled that Agent F is not a blocker for Agent D's approved S1 world assets.
- Residual boundary: AUI-00's additive contracts remain available; they do not retain exclusive ownership of the manifest/view seam.

## AUI-10 — Agent D S1 world source and staging packet

- Status: merged to master and machine-conformant.
- Commits: `817408a` implementation and `3b7ba22` final fail-closed handoff pin.
- Contents: eight deterministic native S1 assets, GPT Image 2 source ledger, portable normalizer, staged provenance, value-board/contact-sheet QA, and an unbound presentation payload.
- Human final art: unset.

## AUI-10R — Agent D S1 runtime integration

- Status: `in_progress`
- Owner: `AGENT D`
- Branch: `agent-d/s1-world-runtime`
- Base: `master` at `3936eeda3e25c5f45def229b168fd11c41a048d9`
- Effective lane: `RELEASE`
- Lease: active from `2026-08-12T13:58:39.473748Z` through `2026-08-12T23:58:39.473748Z`

### Dependency boundary

- D: exact `AUI-DESIGN-D` manifest is available at `docs/media/AUI-DESIGN-D-approved-manifest.json`; receipt, accepted manifest, focused S1 revision, and all six canonical image hashes are verified.
- F: owner-superseded for this S1 seam; the remote branch is fully contained in master and its lease is expired.
- E: still iterating; no E asset, approval, or E-dependent successor work is consumed.

### Runtime scope

AUI-10R may promote only Agent D's eight S1 PNGs into `assets/world/s1/`, add truthful runtime provenance, extend the logical manifest, add an S1 `StageArtTheme`, project it through `BattleView`/`IsoGridBuilder`, and add exact tests/scenarios/evidence. It may not change simulation, stage geometry, save/hash/replay state, thresholds, localization catalogs, unrelated UI, or Agent E content.

### Acceptance state

- S1 tile and backdrop roles resolve through manifest IDs.
- Three route cadence notches and typed Spawn/Core landmarks render with input ignored.
- Rain measure remains manifest-backed but deliberately unplaced.
- Non-S1 stages retain the generic art lane.
- All runtime assets retain `placeholder = true` and provenance `human_final_art = false` until Poseidon reviews the live screenshot/build.
- RELEASE requires a frozen candidate, fresh clean-artifact full gate, independent diff-vs-pins audit, localization-impact review, and human visual verdict before merge.

## Successor locks

Agent D S1 runtime integration is no longer blocked by F or E. Every Agent E asset and E-dependent successor package remains blocked until the separate `AUI-DESIGN-E` approval token and accepted hash exist.
