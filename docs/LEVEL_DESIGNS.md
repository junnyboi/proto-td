# Campaign Level Designs

All campaign stages are authored once in **landscape orientation** under `data/stages/`. `BattleView` snapshots the viewport orientation at battle startup. Landscape battles use the authored `StageDef`; portrait battles use a lossless 90-degree clockwise copy that rotates `grid_rows`, paths, early-stage landmark cells, elevated cells, blocked cells, and environment-prop cells while preserving stage ID, wave schedule, music, roster, rewards, requirements, and hints.

The orientation is intentionally fixed for the lifetime of a battle. Resizing the viewport refits and pans the active map but does not remap deployed units or rotate an in-progress simulation.

| Stage | Tactical identity | Landscape structure | Wave structure |
|---|---|---|---|
| S1 — First Stand | Blocking, ranged placement, and reinforcement | One turned route with an early line, fallback line, and two deployable elevated platforms | Singles teach setup, then paired pushes test block capacity and ranged support |
| S2 — Tempo | Rapid opening and asymmetric coverage | Two-turn route with distinct approach and exit high ground | Runner opener, short recovery, then alternating grunt-runner pairs |
| S3 — The Choke | Finite trap charges at true convergence | Two entries merge into one shared exit and premium trap cell | Three alternating runners consume Spike Plate charges, then synchronized mixed pairs |
| S4 — Air Raid | Anti-air position and facing | Straight aerial lane crosses coverage with a bent ground convoy route | Ground preview, isolated drone, then mixed air-ground pairs |
| S5 — High Ground | Exposed power versus safe coverage | Inner elevated site inside ranged pressure and safer late elevated site | Two spellcaster clusters separated by Bolt’s full cooldown with active bridge pressure |
| S6 — Turncoat | Charm reversal timing; unlocks Slow Field on first clear | Two escort routes converge into one corridor | One heavy leader and same-path escort column per Charm window |
| S7 — Full Kit | First Slow Field lesson and tool sequencing across three fronts | Two ground entries and one aerial entry converge on a contested corridor | Opening mobility, ranged-and-air pressure, then ground columns compressed into the shared field lane |
| S8 — The Gatecrasher | Boss escort disruption, Slow Field control, and defense in depth | Three fortress approaches merge into a gate corridor with two fallback regions | Rehearsal, combined mastery, then boss, eligible escort, support casters, and aerial cover |
| S9 — Return Path | Restoration Lattice tutorial | Two routes converge through one clearly readable restoration seal | Ground-only demonstration, mixed proof, then a durable lattice column |
| S10 — Living Triage | Alternating dual-lattice suppression | Two repair lanes share an exit but retain independent suppression timing | Runner checks, armored probes, then alternating Shieldbearer and caster pushes |
| S11 — Mirror Basin | Split air-ground domains | Three approaches separate Interceptor pressure from two restoring ground lanes | Offset air windows force permanent anti-air while ground suppression rotates |
| S12 — Archive Orchard | Charm into shared suppression | Three orchard routes converge through a provenance-vault lattice | Eligible leaders precede archive columns so Charm and Slow Field must be sequenced |
| S13 — Borrowed Mercy | Trap economy around restoration | Two long trap-compatible lanes join at a relay corridor | Burst packs reward Spike Plate finishers, Tar Pit displacement, and lattice veto timing |
| S14 — White Weather | Persistent air pressure over restoring armor | Three climate channels converge under exposed anti-air platforms | Interceptor and drone cadence persists while heavy ground columns cycle through lattices |
| S15 — Consent Protocol | Four-front covenant rehearsal | Four faction routes compress into one public audit corridor | Every enemy role appears across four waves; one leak ends the protocol attempt |
| S16 — The Unfinished Proof | Dual-boss covenant audit | Four fortress approaches provide upper, center, lower, and final fallback lines | Two Charm-immune Gatecrashers arrive in separate audit windows with eligible escorts and support |

The complete authored balance ledger is machine-readable in [`act2-stage-balance.json`](act2-stage-balance.json). Act II grows from 18 to 32 enemies, two to four paths, one to four lattices, and a three-to-one leak-limit curve without introducing hidden difficulty modifiers.

## Orientation contract

`StageDef.copy_for_viewport()` is the authoritative orientation selector. `StageDef.clockwise_rotated_copy()` applies `(x, y) → (height - 1 - y, x)` and swaps grid dimensions. It also rotates every authored Restoration Lattice cell while preserving heal amount and interval. `StageArtTheme.clockwise_rotated_copy()` applies the same transform to early-stage cell-indexed presentation metadata after validating the authored landscape theme. `BattleModel`, `IsoGridBuilder`, deployment validation, pathing, picking, and map navigation all consume the same selected `StageDef` instance.

## Validation

`test/stage_redesign_smoke.gd` verifies all sixteen exact layouts, unique topologies, rectangular rows, adjacent walkable paths, valid endpoints, chronological waves, valid enemy resources, restoration contracts, early-stage themes, S3 convergence, S5 cooldown spacing, S6 escort columns and Slow Field reward, S7 first-use convergence, and the S8 boss column. `test/stage_orientation_smoke.gd` verifies all sixteen clockwise transforms, Restoration Lattice rotation, metadata preservation, path adjacency, endpoint domains, early-stage landmark rotation, and four-rotation round trips. `tests/act2_campaign_test.gd` additionally enforces sixteen-stage order, one-to-one rewards, monotonic balance envelopes, deterministic terminal schedules, the S8→S9 unlock boundary, and additive restoration of historical eight-stage V3 saves.
