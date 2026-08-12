# POLISH-BOLT — Agent 10 Bolt Impact Plan

## Summary

- Mode: small phase plan on `agent-10/bolt-impact`.
- Base: `master` at `f65498a15a2375f3d71450441a372c0705cbf7ce`.
- Last green: fresh import plus `scripts/verify.sh` at the base; R2, R2.5, R3, and 18 headless scenarios passed.
- Goal: make every accepted Bolt cast produce a deterministic, manifest-backed, readable impact at its authored target cell without changing Bolt damage, cooldown, targeting, audio policy, or any battle outcome.
- Non-goals: no general VFX replacement, no boss-hit work, no SFX, no threshold edits, no spell rebalance, no harness/verify contract change, and no new input path.

## Pinned Parameters

| Parameter | Pin | Reason |
|---|---:|---|
| Test seed | `42` | Repository scenario convention. |
| Model trigger | `last_bolt_cast_tick = -1`, `last_bolt_cast_cell = Vector2i(-1, -1)` before any accepted cast | Fail-closed sentinel with no valid in-grid target collision. |
| Accepted-cast observation | A cast accepted at model tick `T` records tick `T` and the exact target cell before `_apply_cast` returns; the view consumes the new record on the next render `_process` | One deterministic source for seam, bot, replay, and input paths. |
| Rejected cast | Returns `false`; event fields and `state_hash()` remain byte-identical | Architecture rule 7. |
| Asset logical ID | `effect_bolt_impact` | View resolves no physical asset path. |
| Shipping asset | One `48×48` RGBA PNG; binary alpha; TD32 palette; transparent canvas; no text/logo/shadow | Pixel-safe manifest contract. |
| Generated master | GPT Image 2/latest built-in image model, one transparent electric impact glyph, using `icon_bolt.png` as style/palette reference | User-preferred generation lane plus a durable identity source. |
| Runtime display scale | `2.0 × live grid_scale` from `JuiceConfig` | Matches the existing 2× sprite presentation while preserving resize correctness. |
| Lifetime | `12` render frames from `JuiceConfig` | Same clock as `_process` and harness `frames(n)`. |
| Probe color | TD32 `PALE_GOLD #ffe9b0`, at least 20 exact pixels in the centered ROI while live | Falsifiable present/absent proof without using reserved WHITE/SKY channels. |
| Draw order | `JUICE_Z = 60`, above grid/entities and below HUD | Existing battle-view z-band contract. |
| Scenario watchdog | `max_frames = 600`; shell watchdog remains repository-owned | More than 10× the bounded render-frame path, no inherited default. |

## Exactness Tests on Paper

1. **Accepted cast:** with `model.tick == T`, `apply_action([&"cast", &"bolt", C]) == true` implies `last_bolt_cast_tick == T` and `last_bolt_cast_cell == C` before any subsequent `step()`. No off-by-one applies because casting is a verb between model steps, not a sub-step event.
2. **Second accepted cast after debug re-arm:** if debug reset makes Bolt ready at `T2`, a cast at `C2` replaces the record with `(T2, C2)` exactly once; the view compares the tick record against its seen tick.
3. **Rejected cast:** invalid target or cooldown rejection returns before record mutation. Hash before equals hash after.
4. **Hash coverage:** changing only the tick or either cell coordinate changes `BattleHash.of(model)`; the append-only hash order receives the new pair at the end.

## Deliverables and Sequence

### 1. Deterministic model record

- `sim/battle_model.gd`: add the two Bolt event fields; assign only after Bolt target validation/effect resolution succeeds.
- `sim/battle_hash.gd`: append tick, cell x, and cell y to the canonical hash.
- `test/test_spells.gd`: cover exact accepted record and rejected zero-state-change behavior.
- `test/test_hash_paranoia.gd`: add independent rows for tick and cell hash coverage.

### 2. Generated and normalized manifest asset

- `docs/art/reference/bolt_impact_master.png` + `.json`: retain the accepted generated master and exact prompt/model/reference metadata.
- `tools/artgen/normalize_bolt_impact.py`: deterministic alpha threshold, square pad, nearest-neighbor sample to 48×48, TD32 palette remap, and exact contract assertions.
- `assets/sprites/effect_bolt_impact.png` + provenance sidecar/import metadata: shipping bytes and source/recipe hash.
- `assets/manifest.tres`: add `effect_bolt_impact`, `frames = 1`, `size = Vector2i(48, 48)`, `placeholder = false` only because the generated/normalized asset is accepted by the runtime and visual gates in this lane.

### 3. Data-driven view effect

- `data/juice_config.gd` and `.tres`: add lifetime and display-scale values only.
- `scripts/view/juice_layer.gd`: spawn one centered manifest texture, animate a deterministic overshoot/fade envelope, age exclusively in `_process`, and expose no model writes.
- `scripts/view/battle_view.gd`: edge-detect the model record once and call the juice layer with `cell_center(recorded_cell)` and the live grid scale.

### 4. Seeded scenario and evidence

- `selftest/scenarios/bolt_impact.gd`: direct the real cast verb, verify the record, take pre-cast/live/expired captures, and require completion.
- Present proof: at least 20 `#ffe9b0` pixels in a node/cell-derived ROI after the cast.
- Absent proof: fewer than 5 such pixels before the cast and after `bolt_impact_frames + 4` render frames.
- Falsifiable PNG checklist:
  1. Impact is centered over the cast cell, not over the HUD or spell button.
  2. Silhouette reads as a jagged electrical detonation at native gameplay scale, not a uniform circle or square.
  3. The impact draws above terrain and any target body; its transparent canvas has no opaque rectangular halo.
  4. No text, logo, watermark, smooth antialias fringe, or off-palette color is visible.
  5. The expired capture contains no residual impact pixels.

## Verification Ladder

1. L1: `--check-only` and `gdlint` for every touched GDScript; Python syntax check for the normalizer.
2. L2/L3: import, boot, full GUT; narrow spell/hash tests first.
3. L4: `scripts/verify.sh --scenario=bolt_impact`, then `--windowed` under Xvfb.
4. L5: read all fresh Bolt PNGs against the checklist and verify report/mtime freshness plus zero render skips.
5. L6: one standalone-green Agent 10 commit with feature ledger, coordination closure, provenance, and durable evidence manifest.
6. L7: feature remains reachable in the normal battle UI; overall human playtest rounds remain owned by the existing blocked L7 queue.
7. Final lane audit: wipe `artifacts/`, run one uninterrupted `scripts/verify.sh --full`, run two independent campaign bots and diff normalized telemetry, then perform an independent adversarial diff-versus-this-plan review.

> Never weaken/remove/reinterpret a failing check — fix the game. Screenshots only from the run just executed (verify report.json + mtimes); never reuse or hand-craft evidence. Impossible checks stay failing and get logged as numbered deviations. Never conclude "works" from a hung or skipped run. Tests and thresholds are human-owned: never edit a test or a threshold to pass — retune `data/*.tres`.

## Explicitly Not in This Phase

| Excluded work | Deferred to |
|---|---|
| Dust, sparks, vignette, swirl, banner, stamp replacement | `POLISH-VFX` |
| Boss-hit event wiring | `POLISH-BOSS-HIT` |
| Audio restoration | Human owner; `D-SFX` remains authoritative |
| Frame-duration schema migration | `L7-DURATION` after human verdict |
| Tier-2 balance bands or threshold edits | `L7-T2` after `L7-R1` |

## Trim Order and Never-Cut List

After three distinct failed implementation attempts, trim in this order: (1) scale/fade envelope complexity, retaining the static timed sprite; (2) generated-master retention size, retaining prompt/provenance and shipping bytes; (3) extra unit-test duplication already covered by the scenario. Never cut the model record, hash/paranoia coverage, manifest indirection, data-owned lifetime/scale, present/absent pixel pair, completion sentinel, fresh full gate, or adversarial audit.

## Preflight Lint — `godot-2d-reviewer` Plan-Lint Mode

- Contradictions: PASS; Bolt-only concrete file/parameter table wins, and any forced departure becomes a numbered deviation.
- Content obtainability: N/A; no unlock or stage content changes.
- Unpinned parameters: PASS; seed, sentinel, timing, scale, dimensions, palette, probe count, z band, and watchdog are pinned.
- Exactness/observation convention: PASS; cast verbs are observed immediately at tick `T`, view on the next render frame.
- Integrity/ladder: PASS; verbatim integrity contract and L1–L7 are present.
- Watchdog derivation: PASS; 600 frames exceeds the bounded 16-frame effect path by over 30×.
- Scope hygiene: PASS; non-goals, explicit deferrals, trim order, and never-cut list are present.
- Dependencies/offline fallback: PASS; Godot/GUT/Pillow/toolchain are local; generated master is retained, and regeneration failure cannot erase accepted bytes.
- Phase order: PASS; model trigger → asset contract → view → scenario/evidence.
- Falsifiability: PASS; every screenshot statement and pixel threshold can fail.

## Assumptions and Pre-numbered Deviations

- A1: no other active lane owns any listed file; verified against `docs/todo.md`, remote branches/PRs, local processes, and current master before claim.
- A2: a single-frame manifest asset plus deterministic view envelope is sufficient to read as an impact; if visual review rejects it, add manifest frames without changing the model seam.
- A3: `#ffe9b0` is absent from the target ROI before casting; the pre-cast pixel check proves this rather than assuming it.
- D1 candidate: generated output cannot satisfy binary-alpha/palette/silhouette gates after three bounded generations; switch to a different accepted GPT Image candidate, never hand-repair.
- D2 candidate: the repository's current `placeholder = false` convention conflicts with human-only final acceptance. Preserve the existing convention for this product lane but record the provenance and leave the overall L7 verdict open.

## Implementation Checkpoint — 2026-08-12

The planned model, hash, asset, manifest, data, view, and scenario work is implemented. GPT Image 2 candidates A–C were rejected for long horizontal trail artifacts; bounded candidate D removed those artifacts and became the retained master. The deterministic normalizer produced a 48×48 binary-alpha TD32 sprite with 260 opaque pixels, including 72 exact `#ffe9b0` probe pixels. The runtime effect resolves only through `effect_bolt_impact`, uses the live grid scale and the two authored `JuiceConfig` values, and expires synchronously after exactly 12 render frames.

The first expiry run exposed an indentation regression that had placed common transient retention inside the velocity-only branch. The scenario reported an empty transient ledger with a live node; comparison with `master` identified the defect, and the game loop was restored rather than weakening the assertion. The unchanged expiry gate then passed.

Current evidence is green: full GUT passes 123/123 tests; the single-scenario headless and Xvfb windowed lanes pass; the windowed report has 13 passing checks, three fresh screenshots, zero pixel skips, seed 42, and 44 frames used; manual review passes all five falsifiable screenshot pins; and the complete headless `scripts/verify.sh` gate passes R2, R2.5, R3, and all 19 discovered scenarios. The uninterrupted `--full`, cross-process replay diff, independent adversarial review, ledger closure, and master integration remain pending.

Recorded deviations are bounded and do not alter product semantics. D1 was exercised as written by switching to a fourth generated candidate rather than hand-repairing rejected generations. D2 preserves the repository's existing `placeholder = false` convention while retaining master, prompt, reference, hashes, and normalization recipe. L1 standalone `--check-only` could not resolve the `Game` autoload in `battle_view.gd`; per the verified engine rules, the valid project boot compile gate plus GUT replaced that unreliable oracle. No threshold, test expectation, spell balance value, input path, audio asset, or verification script changed.
