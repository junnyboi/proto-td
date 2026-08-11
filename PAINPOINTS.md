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

## Phase 9 (juice pass)

- **Correct-but-invisible effects are a real defect class** (art/VFX
  generation). The spike's sprung frame was implemented exactly to spec and
  fully covered by the triggering enemy's larger rect — only the pixel
  probe caught it (headless and node-level checks were green). Placeholder
  VFX that must be *seen* need a draw-order plan, not just a spawn call;
  the fix (overlay flash in the juice layer, above entities) is the
  reusable pattern.
- **Two frame clocks, one convention** (scene debuggability). Transients
  aged in _physics_process while scenarios awaited process frames: at 120Hz
  every lifetime silently halved and one decay probe flaked. All juice now
  ages in _process; SceneTree.process_frame fires BEFORE node _process, so
  "await 1 frame then read a detection" is off by one — await 2.
- **A scenario abort can masquerade as a pass** (harness integrity). A null
  node access killed run() mid-way; every recorded check had passed and
  the remaining pixel checks skipped headless → vacuous green. Harness now
  has an opt-in expect_done()/done() completion sentinel; juice scenarios
  use it. Related trap: view rects for model entities don't exist until a
  projection frame has run — never fetch them at verb time.
- **Raw-input helpers are wall-clock hogs at high refresh** (level
  authoring / testing). click_view's press/release physics holds consume
  ~most of a 10-frame transient window on ProMotion — pixel probes anchor
  to seam-triggered events; raw input keeps proving the adapter only
  (rule 3's once-per-verb discipline pays again).

## Phase 10 (campaign assembly, lanes B+C folded in)

- **Stage/timeline tuning converged in 4 data-edit rounds** (balance
  tuning — acceptance #10's richest sample). The loop that made it cheap:
  clearability as GUT (milliseconds per full battle) + rejected timeline
  actions failing loudly WITH the live DP value in the message. Every
  verdict resolved as a stage-data or timeline edit; zero code changes.
  Paper DP estimates ran consistently ~2-4 DP hot — trust the printed
  number, not the derivation, from round 2 on.
- **Freshly swapped-in Controls have unsettled rects for a frame or two**
  (scene debuggability): clicking a grid button straight after the screen
  appears can land on overlapping at-origin rects — one batch-lane flake,
  fixed by settling frames inside the screen-await helper. Same family as
  P9's "rects don't exist until a projection frame".
- **--check-only passed a real parse error in an autoload script** (the
  HFlowContainer return-type mismatch) — the boot lane and the P9
  completion sentinel caught it. Re-confirms the CLAUDE.md rule: the
  compile gate for autoload-referencing scripts is boot + GUT, never
  --check-only alone.

## Lane A (art pipeline v1)

- **Exact-color juice probes and art palettes share one namespace** (art
  generation). The grunt's white eyes/teeth were exact f4f4f4 — the same
  color the sprung-flash absence probe asserts < 5 px of in the trap cell,
  and the 4th grunt walks that cell during the trap_gone shot. Enemy
  sprites now use PALE (c7d6e8) for whites; rule of thumb: probe-asserted
  colors (SPRUNG/DUST/CHARMED) are reserved words for sprite palettes —
  build the charmed ramp ON the probed color, keep everything else off it.
- **Button.expand_icon on a min-sized button collapses the icon to zero**
  (scene debuggability). Squad-select portraits silently vanished while
  every behavioral check stayed green — only the shot review caught it.
  icon_max_width alone is the right tool; expand_icon needs a button that
  is larger than its minimum size.

---

## Category index (acceptance #11 — final audit, 2026-08-09)

Entries stay verbatim above; this index maps them to the five acceptance categories.

- **Art / VFX generation**: P9 "correct-but-invisible effects" (draw-order); Lane A entries
  (palette reservation — WHITE probes vs sprite whites; ASCII-map authoring throughput).
- **Audio generation**: *no entries.* The P9 synth-SFX pipeline (11 WAVs, fixed-seed,
  byte-idempotent) landed without logged pain — reported honestly as empty, not padded.
- **Scene debuggability**: P7 grid-coordinate conventions; P8 CanvasLayer born-visible toggle
  inversion; P9 two-frame-clocks + view-rects-need-a-projection-frame + scenario-abort
  vacuous green; P10 unsettled Control rects.
- **Level authoring**: P8 StringName sort order; P9 raw-input helpers vs transient windows;
  P10 filename⇔id invariant (audit fix).
- **Balance tuning**: P10 "4 data-edit rounds; print the budget in the rejection; paper DP
  estimates run 2–4 hot".

Harness-integrity entries (P3/P4-5 loops, watchdog budgets) sit outside the five categories
but carried the most method value — they are the learnings doc's spine.

## Phase 13 (battle QoL: pause/speed/resign + terminal flow)

- **The plan's "top-center is free" HUD fact was wrong as-built.** The HUD
  status line (`Base HP … tick N RESULT`) reaches past center-x at 1280 wide,
  so the controls row planned for top-center rendered on top of it — every
  check green, shot obviously wrong (the looks-wrong channel worked). Row
  moved right-aligned under the spell bar (D5). Lesson: free-real-estate
  claims need a pixel look at the LONGEST live text, not the _ready() text.
- **A human on the machine breaks the windowed lane two new ways once
  gameplay hotkeys exist.** (a) Real zero-mask mouse motion mid-synthetic-
  press makes the Viewport drop GUI mouse focus — the press's release never
  fires (3 batch runs, a different lost click each). (b) The scenario window
  takes keyboard focus, so live typing lands in the game — Space (the new
  pause hotkey) toggled pause mid-measurement. Both fixed for good by
  `selftest/input_shield.gd`: a harness-only root `_input` node that eats
  every untagged (device != 4242) mouse/key event. (c) Unfixable remainder:
  hiding/fully covering the window stops macOS draws — `shot_grab`'s
  `frame_post_draw` await stalls until the frame watchdog; a pre-existing
  scenario (blocking) hit it too. R4b needs ~3 undisturbed minutes; that is
  an environment contract, not code.
- **`physics_frames(n)` measures n-1..n stepped frames, not n.** The 4x
  speed exactness band derived as 20s±1 (residue only) missed the await-
  boundary frame: at 4x the observable is [78, 80]. Derive dtick bands as
  [floor(19.5s), 20s], never 20s±1.
