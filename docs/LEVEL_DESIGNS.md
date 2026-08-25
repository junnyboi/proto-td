# Campaign Level Designs

All campaign stages are authored once in **landscape orientation** under `data/stages/`. `BattleView` snapshots the viewport orientation at battle startup. Landscape battles use the authored `StageDef`; portrait battles use a lossless 90-degree clockwise copy that rotates `grid_rows`, paths, early-stage landmark cells, elevated cells, blocked cells, and environment-prop cells while preserving stage ID, wave schedule, music, roster, rewards, requirements, and hints.

The orientation is intentionally fixed for the lifetime of a battle. Resizing the viewport refits and pans the active map but does not remap deployed units or rotate an in-progress simulation.

| Stage | Tactical identity | Landscape structure | Wave structure |
|---|---|---|---|
| S1 — First Stand | Blocking and reinforcement | One turned route with an early line and fallback line; no elevated cells | Singles teach setup, then paired pushes test block capacity |
| S2 — Tempo | Rapid opening and asymmetric coverage | Two-turn route with distinct approach and exit high ground | Runner opener, short recovery, then alternating grunt-runner pairs |
| S3 — The Choke | Finite trap charges at true convergence | Two entries merge into one shared exit and premium trap cell | Three alternating runners consume Spike Plate charges, then synchronized mixed pairs |
| S4 — Air Raid | Anti-air position and facing | Straight aerial lane crosses coverage with a bent ground convoy route | Ground preview, isolated drone, then mixed air-ground pairs |
| S5 — High Ground | Exposed power versus safe coverage | Inner elevated site inside ranged pressure and safer late elevated site | Two spellcaster clusters separated by Bolt’s full cooldown with active bridge pressure |
| S6 — Turncoat | Charm reversal timing | Two escort routes converge into one corridor | One heavy leader and same-path escort column per Charm window |
| S7 — Full Kit | Tool sequencing across three fronts | Two ground entries and one aerial entry converge on a contested corridor | Opening mobility, ranged-and-air pressure, then Charm-ready heavy columns |
| S8 — The Gatecrasher | Boss escort disruption and defense in depth | Three fortress approaches merge into a gate corridor with two fallback regions | Rehearsal, combined mastery, then boss, eligible escort, support casters, and aerial cover |

## Orientation contract

`StageDef.copy_for_viewport()` is the authoritative orientation selector. `StageDef.clockwise_rotated_copy()` applies `(x, y) → (height - 1 - y, x)` and swaps grid dimensions. `StageArtTheme.clockwise_rotated_copy()` applies the same transform to early-stage cell-indexed presentation metadata after validating the authored landscape theme. `BattleModel`, `IsoGridBuilder`, deployment validation, pathing, picking, and map navigation all consume the same selected `StageDef` instance.

## Validation

`test/stage_redesign_smoke.gd` verifies exact layouts, unique topologies, rectangular rows, adjacent walkable paths, valid endpoints, chronological waves, valid enemy resources, early-stage themes, S3 convergence, S5 cooldown spacing, S6 escort columns, S7 breadth, and the S8 boss column. `test/stage_orientation_smoke.gd` verifies all eight clockwise transforms, metadata preservation, path adjacency, endpoint domains, early-stage landmark rotation, and four-rotation round trips.
