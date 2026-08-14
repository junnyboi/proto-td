# Protos — Agent Rules

Tactical tower defense POC (Arknights-benchmark + twist bundle), built agent-first on Godot
4.7.1. Canonical phase plans live in the Manus MGS project knowledge area; actionable
collaboration contracts are mirrored under `docs/plans/`. This file is the standing rule set —
it grows one rule per repeated mistake and never shrinks.

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
- Windowed runs on a human's machine are **quiet windows**: focus theft is creation-time, so
  `verify.sh` writes a transient `override.cfg` (`no_focus=true`) around windowed rungs and the
  harness parks the window bottom-right; `selftest/input_shield.gd` eats untagged
  (device != 4242) input. Never launch a bare windowed preview during dev — headless first,
  pixels via `verify.sh --full` or `verify.sh --scenario=X --windowed`. Never minimize/hide the
  preview window: macOS stops drawing it and `shot_grab` stalls on `frame_post_draw` until the
  watchdog.

## NOT-do list

- Never hand-write `uid://` values in `.tscn`/`.tres` — omit `uid=`; the engine mints `.uid`
  sidecars on import; commit the sidecars.
- Never hand-write `Object(InputEventKey…)` serialization — input actions via a scratch
  `ProjectSettings` script.
- Never reference a new `class_name` before running `--import` (registry lives in `.godot`).
- Runtime hot paths that reference a newly introduced `class_name` (especially autoloads and
  battle-view builders) must explicitly `preload()` that script under a local constant or type
  alias. A developer
  pulling new code can retain a valid-but-stale class cache; requiring a manual reimport is not a
  shipping fix. Fresh clones still run `--import` first. Gate the upgrade path with
  `scripts/probe_stale_class_registry.sh`; dedicated cache-regression gates must also scan output
  because Godot may report a fatal parse/autoload error and still exit 0.
- Never make a shipped script's parseability depend on a generated `.godot/imported/*` artifact.
  A pull can update the tracked source asset and `.import` remap before that machine regenerates
  the cache. For the bundled CJK font, build `FontFile` from the tracked OTF bytes at runtime;
  preserve those raw bytes in exports and gate the upgrade path by deleting the generated
  `.fontdata` before boot. A committed `.import` sidecar is metadata, not a cache delivery system.
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
- A pinned "event at tick T" lands during the step whose **entry** tick is T and is
  observable at `model.tick == T+1` — `step(T)` shows the before-state, one more `step()`
  shows the event. Asserting at `model.tick == T` is an off-by-one against a correct model.
- An enemy-free battle terminates CLEAR on its **first step** (timeline exhausted + nothing
  alive), and `step()` no-ops after terminal — so a `while model.tick < N` loop over a
  terminal model hangs forever. Pure-economy tests pin the battle open with one never-reached
  wave entry (`tick: 100_000`); tick-bounded loops also guard on `result == RUNNING`.
- Scenario grid clicks go through `view.cell_center(cell)` + `click_view`/
  `press_mouse_at` — never the harness's `click_cell` (it assumes an
  origin-anchored grid; `GridRoot` is centered in the viewport, so
  `click_cell` lands cells off-target and adapters cancel silently).
- `DirAccess` catalog scans must strip a `.remap` suffix before the `.tres` filter — exported
  builds convert text resources to binary and list `<name>.tres.remap`, so a bare
  `ends_with(".tres")` scan ships EMPTY catalogs (operators/traps/spells/stages) while running
  fine from source. Load by the original `.tres` path; it resolves through the remap.
- `editor/export/convert_text_resources_to_binary` stays **false** (pinned in project.godot):
  the 4.7.1 export-time converter silently drops `PackedStringArray` @export fields from
  `script_class` .tres (StageDef.grid_rows shipped empty — no terrain, no deployable tiles —
  while paths/waves survived; a runtime `ResourceSaver` round-trip keeps the field, so only
  the exporter is broken). Localize exported-data bugs natively, no browser needed:
  `godot --main-pack <exported.pck> -s res://tools/<probe>.gd`.

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

1. **Pull + orient**: fetch/pull the current default branch before development; `git log
   --oneline -10`; read `FEATURES.json`, `docs/todo.md`, `docs/completed.md`, and relevant
   `docs/plans/`/`docs/decisions/`;
   `godot --headless --path . --import`; `scripts/verify.sh` — green **before** new work; if
   red, fixing it *is* the session.
2. **Claim ONE item** in `docs/todo.md`: assigned agent/code, `agent-N/<lane>` branch, exclusive
   files, do-not-touch surfaces, dependencies, acceptance, and evidence. Never two agents on one
   file; never write into a worktree another agent is verifying.
3. Inner loop: write → hook checks per write → `verify.sh --scenario=X` → `verify.sh --full`.
4. Commit feature + ledgers (+ baselines) atomically on the feature branch. Every new commit starts
   `AGENT N - ` where N is the assigned number/code. Apply prospectively; never rewrite history
   merely to add prefixes.
5. On closure, move the item from `docs/todo.md` to one compact line in `docs/completed.md`:
   ID | agent | outcome | commit | evidence. Compact redundant prose without deleting stable
   IDs, SHAs, deviations, or evidence.
6. **The feature owner integrates completed work.** Fetch current remote state and merge
   `origin/master` into the feature branch first. Resolve conflicts semantically on that branch,
   preserving both valid behaviors; never accept all of `ours` or `theirs` blindly. If
   requirements conflict, stop for the owner rather than deleting another lane. Run
   `git diff --check` + `scripts/verify.sh` before every push and `scripts/verify.sh --full` after
   substantive conflict resolution, then push the feature branch normally.
7. Switch to local `master`, pull `origin/master` with `--ff-only`, then fast-forward to the
   verified feature branch. If fast-forward is impossible because master moved, return to the
   feature branch, merge the new master, resolve, and reverify; never resolve drift on master.
   Run `scripts/verify.sh --full` on merged master, push master normally, and confirm local and
   remote master share the same SHA. A lane green does not prove the union green.
8. **Never force-push in any form**: `--force`, `-f`, and `--force-with-lease` are forbidden.
   See `docs/decisions/D-001-autonomous-feature-integration.md`.
9. Report: what shipped, branch/master gate verdicts, deviations (numbered, never silent), any new rule earned
   for this file. Log pain points to `PAINPOINTS.md` as they happen.

## Audio: approved runtime music; SFX remains silent

The 2026-08-11 owner decision made the build silent. On 2026-08-12 the owner approved the
six-cue score and explicitly authorized runtime music. `Music` is the sole catalog-backed
owner and must retain exactly one `AudioStreamPlayer`: never layer cues, never restart the
current logical ID, and hard-replace only when the ID changes. Stage act/boss routing lives
in `StageDef` data. Do not restore synth SFX; the `sfx_played` telemetry seam stays wired.
See `docs/decisions/D-SFX.md`.
