# Pain points (logged as they happen — CLAUDE.md session protocol step 5)

## Phase 3 (blocking + combat)

- **Tick-observation off-by-one cost a full test-file rewrite.** The plan's
  §4.3 numbers (block at 121, kill at 301, leak at 361) are *entry-tick*
  events; the first draft of `test_combat.gd` asserted them at
  `model.tick == T` instead of `T+1` and 8/10 tests failed against a correct
  model. Phase 1 had already pinned the convention
  (`test_arrival_tick_exactness` steps to T, asserts the before-state, then
  steps once more) — re-deriving it mid-session instead of copying the
  Phase 1 pattern was the mistake. Rule added to CLAUDE.md.
- **Mid-cell catch invalidated the paper scenario for the conservation gate.**
  An enemy spends ~30 advances inside a cell, so one that passes a full
  blocker is still caught if capacity frees before it walks off the cell
  (D12's check runs after *every* advance, not on cell entry). The first
  conservation battle assumed walk-past-is-forever and its expected counts
  were wrong; the battle had to be re-derived (defender at (4,2) at tick 180).
  The signature case survives only because #2 leaves cell 3 at 271, before
  the 301 kill frees a slot — that margin is now stated in the test comment.
- **`gdformat` mangles multiline lambdas in dictionary literals** (it
  duplicated the file's `##` doc comments into the lambda body — valid but
  garbage). Keep dict-checkpoint lambdas single-line; hoist compound
  conditions into named helpers/vars. Long `h.check(...)` args with ternaries
  trigger the ugly `(h . check(...))` wrap — precompute into locals.
- **Windowed batch run lost a raw-input drag to the real mouse** (deploy_flow
  batch-fail, isolated-pass — the known G6 environment race, confirmed by
  re-running `--scenario=deploy_flow --full` green and then the full ladder
  green).
- **The harness frame watchdog is refresh-rate-dependent.** Windowed R4b runs
  at wall clock; on a high-refresh display (M4 Pro ProMotion) process frames
  accrue ~2-4x faster than the 60fps the default 3600-frame budget assumes, so
  a full D22-length battle (~17s) flakes right at the edge (3601 frames, every
  check already PASS). Scenarios that play a battle to terminal must set
  `h.max_frames` themselves; the default budget really means "~15-30s", not
  "60s".

## Phases 4-5 (classes/counters + skills)

- **An enemy-free battle terminates CLEAR on its very first step** (timeline
  exhausted + nothing alive), and `step()` no-ops after terminal, so a
  `while model.tick < N: model.step()` loop over such a model never advances —
  the first `test_skills.gd` draft hung GUT forever. Pure-economy tests pin
  the battle open with one never-reached wave entry (`tick: 100_000`) and
  tick-bounded while-loops also guard on `result == RUNNING`. Rule added to
  CLAUDE.md.

## Phase 7 (spells + charm)

- **Two grid-coordinate conventions between harness and view cost a debug
  cycle** (scene debuggability). `SelfTestHarness.click_cell` maps cells
  from a zero origin, but `battle_view` centers `GridRoot` in the viewport
  — the scenario's bolt click landed ~5 cells off and the cast rejected
  silently (adapter exits targeting on an invalid press, by design, so
  nothing errored). trap_flow had implicitly avoided this by always going
  through `view.cell_center`; the convention is now a CLAUDE.md rule
  instead of tribal knowledge.
- **`gdlint max-file-lines` (1000) tripped mid-phase on battle_model.gd**
  (code organization). The fix that preserved the check was extracting the
  full-state hash enumeration to `sim/battle_hash.gd` (a pure serialization
  concern, append-only field order). Expect the same pressure again around
  Phase 10; the next natural seam is the combat pass.

## Phase 8 (debug mode)

- **A default-visible CanvasLayer inverted every toggle observation** (scene
  debuggability). `toggle()` lazily builds the overlay then flips
  `visible` — CanvasLayer is born visible, so the first toggle built it
  and immediately hid it, and all six scenario checks read inverted. The
  symptom looked exactly like "injected key events don't reach _input
  headless", and a 20-line probe was what separated the two hypotheses
  (instrument, don't speculate — again). Lazily-built UI that a toggle
  flips must be born hidden.
- **StringName's `sort()` is interning-order, not lexicographic** (level
  authoring / API trap). `Array[StringName].sort()` rendered the stage
  buttons as test_drone, test_skill, test_lane — stable within a process,
  arbitrary across binaries. Catalog scans now sort String copies. Note:
  `SpellBook.ids.sort()` (Phase 7) shares the trap; harmless there because
  hash order only needs same-process stability, but worth knowing at
  Phase 10 when replays cross sessions.
- **The deploy bar overflows 1280px with a 10-operator debug squad**
  (cosmetic, debug-only): slots are an unwrapped HBox sized for
  squad_size-bounded rosters. Phase 10's loadout gating bounds it again;
  revisit only if debug play needs the full strip.
