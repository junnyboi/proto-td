# Aetheria Art/UI Implementation Status

## AUI-00 — Presentation contracts and baselines

- Repository checkpoint: `a46fe9c` (`AGENT F - Claim AUI presentation contracts`), fully contained in current master.
- Ownership state: Agent F's external lease expired; no Agent F worktree, pull request, process, or active `docs/todo.md` claim exists.
- Owner decision: Poseidon explicitly ruled that Agent F is not a blocker for Agent D's approved S1 world assets.
- Residual boundary: AUI-00's additive contracts remain available; they do not retain exclusive ownership of the manifest/view seam.

## AUI-10 — Agent D S1 world source and staging packet

- Status: merged to master and machine-conformant.
- Commits: `817408a` implementation and `3b7ba22` final fail-closed handoff pin.
- Contents: eight base deterministic S1 assets, GPT Image 2 source ledger, portable normalizer, staged provenance, value-board/contact-sheet QA, and an unbound presentation payload.
- Human final art: unset.

## AUI-10R — Agent D S1 runtime integration and revision 2

- Status: `in_progress`; implementation and focused gates green; frozen full RELEASE and owner visual verdict pending.
- Owner: `AGENT D`
- Branch: `agent-d/s1-world-runtime`
- Base: `master` at `3936eeda3e25c5f45def229b168fd11c41a048d9`
- Effective lane: `RELEASE`
- Lease: renewed at the `AUI-DESIGN-D-REVISION-2` approval boundary.

### Dependency boundary

- D: parent approval plus exact `AUI-DESIGN-D-REVISION-2` selection (`Cloud-Seal Orrery + Alpine Escarpment`) are available and hash-pinned.
- F: owner-superseded for this S1 seam; its remote branch is contained in master and its lease is expired.
- E: still iterating; no E asset, approval, or E-dependent successor work is consumed.

### Runtime scope

AUI-10R may alter only Agent D S1 source/runtime assets and provenance, the logical manifest, typed S1 presentation resource, `IsoGridBuilder`, exact tests/scenarios, and corresponding AUI docs/evidence. It may not change simulation, stage geometry, save/hash/replay state, thresholds, localization catalogs, unrelated UI, or Agent E content.

### Acceptance state

- Twelve S1 manifest IDs resolve to exact runtime bytes with one-to-one runtime provenance.
- The selected 32×32 Core is the Cloud-Seal Orrery; the rejected pressure-tank silhouette is superseded.
- S1 renders one continuous 208×104 Alpine Escarpment behind the map; no repeated outside-map grid or tile ring renders.
- Three route cadence notches and typed Spawn/Core landmarks render with input ignored.
- Rain measure remains manifest-backed but deliberately unplaced.
- Non-S1 stages retain the generic art lane.
- Focused art gate, GDScript lint, GUT, and headless/windowed `s1_world_art` are green.
- All runtime assets retain `placeholder = true` and provenance `human_final_art = false` until Poseidon reviews the frozen candidate.
- RELEASE still requires an atomic frozen candidate, fresh clean-artifact full gate, independent diff-vs-pins audit, localization-impact review, and explicit human visual verdict before merge.

## Successor locks

Agent D S1 runtime integration is not blocked by F or E. Every Agent E asset and E-dependent successor package remains blocked until the separate `AUI-DESIGN-E` approval token and accepted hash exist.
