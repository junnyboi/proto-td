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
