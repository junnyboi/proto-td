# Prototype TD — Agent Rules

Tactical tower defense POC (Arknights-benchmark + twist bundle), built agent-first on Godot
4.7.1. Plan of record: `~/Documents/MGS docs/Prototype TD/prototype-td-implementation-plan.md`
(+ `td-phase-0-1.md` for Phases 0–1). This file is the standing rule set — it grows one rule per
repeated mistake and never shrinks.

## Environment (verified facts — do not re-derive)

- Godot **4.7.1 stable** at `~/bin/godot` (never assume PATH; scripts self-provision `$HOME/bin`).
- Typed GDScript is enforced: `untyped_declaration=2` (errors). Every declaration typed or
  inferred with `:=`.
- `--headless` runs the full loop; `--fixed-fps 60` decouples sim from wall clock.
- Headless **cannot** screenshot (dummy renderer) — `shot()` no-ops with `[SHOT-SKIPPED]`;
  pixels come from the windowed lane (`verify.sh --full`).
- Injected mouse motion never moves `get_mouse_position()` — game code tracks the pointer from
  motion events. Synthetic events carry `device == 4242`; game code may ignore untagged mouse
  events under the harness.
- Hold synthetic presses across **physics** frames, not render frames.
- A human on the machine races injected input: batch-fail + isolated-pass ⇒ environment, not code.
- Under `-s script.gd` headless, the dummy window boots **64×64** regardless of project display
  settings, and GUI events outside the window rect are silently dropped. The harness pins
  `root.size` to the design resolution after the first frame (`_run()`); earlier sets are
  clobbered during engine setup.

## NOT-do list

- Never hand-write `uid://` values in `.tscn`/`.tres` — omit `uid=`; the engine mints `.uid`
  sidecars on import; commit the sidecars.
- Never hand-write `Object(InputEventKey…)` serialization — input actions via a scratch
  `ProjectSettings` script.
- Never reference a new `class_name` before running `--import` (registry lives in `.godot`).
- `--check-only` cannot resolve autoloads — the compile gate for autoload-referencing scripts is
  the boot check + GUT, not `--check-only`.
- Never override `_process` on a `SceneTree` script — connect to `process_frame`.
- Godot 3 API ban: no `yield` (use `await`), no `onready var` without `@`, no `export` without
  `@`, no `KinematicBody2D` (`CharacterBody2D`), no `instance()` (`instantiate()`),
  no `OS.get_ticks_msec()` (`Time.get_ticks_msec()`).
- No gameplay numbers in logic code — balance lives in `res://data/*.tres` (rule 4 below).
- Adding a mutable field to `BattleModel` without extending `state_hash()` is a defect.
- A `Control` parented to a `Node2D` gets **no anchor-based layout** — size it explicitly
  (`get_viewport().get_visible_rect()`), and only after it is inside the tree.
- View-projection CanvasItems (`ColorRect` tiles/units/enemies) must set
  `MOUSE_FILTER_IGNORE` — default STOP eats GUI clicks meant for `_unhandled_input`.

## Architecture rules (numbered — violation = rework)

1. **The battle is a database; the engine is a view.** Authoritative state lives in plain-data
   classes under `res://sim/` (`RefCounted`, zero Node/rendering/autoload imports). Nodes and
   sprites are disposable projections.
2. **The simulation is engine-independent and tick-stepped.** `BattleModel.step()` advances one
   tick (30 ticks/s). No engine physics, no Timers, no wall clock, no RNG (v1) inside the model.
   Entire battles run inside GUT.
3. **Every verb is seam-drivable without hardware**: `deploy`, `retreat`, `trigger_skill`,
   `place_trap`, `cast`, `step(n)`. A battle is fully described by
   `(stage_id, squad, seed, [(tick, verb, args)])` — replay = bot = test format. Raw input is a
   thin adapter validated once per verb.
4. **All balance is data** in `res://data/*.tres`. Playtest verdicts must resolve as data edits.
5. **Debug mode is a UI over the verbs** — same seams as tests, no parallel code path.
6. **View reads, never writes.** Battle speed = model ticks consumed per frame; speed can never
   change outcomes.

## Verification = run `verify.sh`

```
scripts/verify.sh              # R2 import -> stage lint -> R3 GUT -> R4a scenarios headless
scripts/verify.sh --full       # + R4b windowed shots -> R5 bots -> R6 gate
scripts/verify.sh --scenario=X # inner loop on one scenario
scripts/playtest.sh <bot>      # one bot, headless lane
```

Run `verify.sh` before every commit; `verify.sh --full` before declaring a feature done.

### Failure routing

| Failing rung | Meaning | Action |
|---|---|---|
| R1 hook / R2 | code or resource malformed | fix before anything else runs |
| R2.5 | stage data invalid | fix `data/stages/*.tres` |
| R3 | a remembered fact regressed | fix code, **never** the test |
| R4 | feature acceptance broken | read `artifacts/<scenario>/report.json` details (they carry the measured number); fix or retune `data/*.tres` |
| R5/R6 | balance drifted | gate names the band; retune data, never thresholds |
| shots wrong despite green | looks-wrong defect | ledger defect with the shot attached |
| batch-fail, isolated-pass | environment (focus/real input) | not code — re-run isolated |

### Integrity rules (load-bearing)

- Never weaken a failing check to make it pass — fix the game.
- Screenshots must come from the run just executed (fresh evidence only).
- Impossible checks stay failing and get logged, never deleted.
- Thresholds (`playtests/thresholds.json`) are human-owned; tier-2 bands are written only after
  human playtest round 1.

## Session protocol

1. **Orient**: `git log --oneline -10`; read `FEATURES.json`;
   `godot --headless --path . --import`; `scripts/verify.sh` — green **before** new work; if
   red, fixing it *is* the session.
2. **Pick ONE** failing feature. Never two.
3. Inner loop: write → hook checks per write → `verify.sh --scenario=X` → `verify.sh --full`.
4. Flip ledger status; commit feature + ledger (+ baselines) in one commit.
5. Report: what shipped, gate verdicts, deviations (numbered, never silent), any new rule earned
   for this file. Log pain points to `PAINPOINTS.md` as they happen.
