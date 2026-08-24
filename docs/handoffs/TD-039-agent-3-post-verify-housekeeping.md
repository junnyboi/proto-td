# TD-039 — Agent 3 Post-Verify Housekeeping Handoff

## Purpose

After `TD-VERIFY-REMOVE` deleted the slow aggregate workflow, this lane establishes a bounded default check and reconciles the live repository rules and active queue. Historical feature evidence, decisions, plans, handoffs, and completion records are intentionally preserved verbatim.

## Base and ownership

| Field | Value |
|---|---|
| Owner | AGENT 3 |
| Branch | `agent-3/post-verify-housekeeping` |
| Base | `master` at `a9237ee67202817e412d57f6b44783a074804248` |
| Implementation | `7cf86591f3ebc024cc5aa989d76248f453c49616` |
| Dependency | `TD-VERIFY-REMOVE` complete |
| Excluded surfaces | Gameplay code, tests, thresholds, assets, `FEATURES.json`, Agent 1's handoff, removed `scripts/verify.sh`, and Web preview state |

## Audited repository state

At the claimed base, local and remote `master` were clean and synchronized. GitHub reported no open issues or pull requests. `FEATURES.json` parsed successfully with 30 `passing` rows and 1 `pending` row. The active queue contained 12 pre-existing work items after Agent 1 closed `TD-VERIFY-REMOVE`: 5 pending and 7 blocked. No active ID was duplicated in `docs/completed.md`.

The repository contained 2,249 tracked files and no untracked or obvious tracked OS/editor-junk files before import. Git object storage was one 332.83 MiB pack with no garbage. The largest tracked files were intentional art sources, music sources/runtime audio, and deterministic fixtures; this lane did not delete or rewrite project assets.

## Changes

| Path | Change |
|---|---|
| `scripts/quick_check.sh` | Adds the default bounded entrypoint: exact engine check, headless import, 120-frame boot, and deterministic `boot` scenario with seed 42. |
| `scripts/probe_filesystem.sh` | Discovers `GODOT`, `godot`, `godot4`, `~/.local/bin/godot`, then legacy `~/bin/godot`; accepts the project-pinned 4.7.2 engine. |
| `CLAUDE.md` | Replaces deleted aggregate-workflow requirements with a quick baseline plus lane-specific focused evidence and updates the active engine pin/path. |
| `docs/README.md` | Repoints collaboration guidance and repository anchors to `scripts/quick_check.sh`. |
| `docs/todo.md` | Claims TD-039 and replaces active requirements for the deleted workflow with bounded baseline plus focused evidence. |

## Validation evidence

| Check | Result |
|---|---|
| Shell syntax | PASS — `bash -n scripts/quick_check.sh scripts/probe_filesystem.sh` |
| Diff whitespace | PASS — `git diff --check` |
| Engine | PASS — `4.7.2.stable.official.ed1daf0bf` at `/home/ubuntu/.local/bin/godot` |
| Default engine discovery | PASS — `scripts/quick_check.sh` found `~/.local/bin/godot` with `GODOT` unset and no Godot command on `PATH` |
| Bounded baseline | PASS — import, 120-frame boot, and deterministic boot scenario; 24 checks, 0 shots, 882 frames |
| Filesystem contract | PASS — native probe, 162 checks across 18 cases, no mandatory failures |
| Feature ledger | PASS — valid JSON with 30 passing rows and 1 pending row |
| Queue integrity | PASS — 1 in-progress lane (TD-039), 5 other pending items, 7 blocked items, and no active/completed ID collision |
| Active policy audit | PASS — no standing-rule or required-evidence dependency on `scripts/verify.sh` in `CLAUDE.md`, `docs/README.md`, or `docs/todo.md` |


## Deliberate non-changes

`FEATURES.json` and historical records still contain references to earlier `verify.sh --full` runs. Those strings document acceptance or evidence produced in prior releases; rewriting them would falsify history. Focused helpers not owned by TD-039 may still default to legacy `~/bin/godot`, but callers can override them with `GODOT`; repository-wide normalization remains a separate bounded lane if desired.

## Known deviation

The deterministic boot harness publishes `[RESULT] pass (24 checks, 0 shots, 882 frames)` and then Godot 4.7.2 reports exit-time leaked-object/resource diagnostics. TD-039 treats the explicit scenario result as the acceptance signal while still failing on parser, resource-load, autoload, type-resolution, or `[FAIL]` text. The leak diagnostics predate this documentation-only/shell-policy lane and were not hidden or changed.
