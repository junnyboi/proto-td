# Lightweight Validation Policy

## Purpose

The repository uses **bounded, scope-aware validation** rather than one aggregate all-project ladder. The current entrypoint is `scripts/validate.sh`. It runs the fastest checks that prove the game imports, boots, executes GUT, and completes one deterministic gameplay scenario, while optional flags add render and Web-export coverage only when the changed surface requires them.

## Current environment contract

Godot **4.7.2 stable** is the supported engine. Resolution order is an explicit `GODOT` environment variable, `godot` or `godot4` on `PATH`, and finally `~/.local/bin/godot`, which is the Manus Game Studio bootstrap location. The validator rejects a different version instead of silently mixing engine and export-template revisions.

## Required validation by change type

| Change scope | Required command | Additional focused evidence |
|---|---|---|
| Documentation or repository metadata only | `scripts/validate.sh` | `git diff --check` and any document-specific linter |
| Simulation, campaign, save, replay, or data | `scripts/validate.sh --test=res://test/<focused_test>.gd --scenario=<affected_scenario>` | Run the relevant bounded helper such as `replay_check.sh`, `model_roster_check.sh`, `strategic_verbs_check.sh`, or a domain-specific check |
| UI, input, layout, animation, or visual assets | `scripts/validate.sh --test=res://test/<focused_test>.gd --scenario=<affected_scenario> --render` | Review the fresh scenario PNGs against falsifiable acceptance criteria |
| Web export, browser runtime, or preview host | `scripts/validate.sh --scenario=<affected_scenario> --render --web` | Load the exported or hosted build in Chromium, exercise the affected input path, and inspect console/network failures |
| Audio | `scripts/validate.sh --test=res://test/test_music_player.gd --scenario=music_routing` or the matching SFX test/scenario | Run the appropriate audio catalog/derivation verifier |

The default command uses `test_smoke.gd` and the `boot` scenario. It is deliberately small enough for the normal edit loop. Focused test and scenario arguments replace those defaults; they do not trigger unrelated suites.

## Branch and integration rule

Run the required scope row on the feature branch. Merge current `origin/master` into that branch, resolve conflicts there, and rerun the same scope before pushing the branch. After fast-forwarding local `master`, rerun the same scope on the merged tree before pushing `master`. Never weaken a focused check, reuse stale screenshots, or force-push to bypass a failure.

## Failure contract

The validator stops on a nonzero process exit, timeout, parser/autoload/resource/runtime error text, zero-test GUT run, failing scenario report, missing render evidence, absent Web template, or missing/empty HTML, JavaScript, WASM, or PCK export. Logs and a machine-readable summary are written beneath `artifacts/validation/`.

## Historical-reference policy

`FEATURES.json`, `FINAL_REPORT.md`, files under `docs/plans/`, `docs/handoffs/`, and `docs/media/`, and frozen records under `assets/provenance/` or `staging/provenance/` preserve evidence from earlier releases. Exact references there to Godot 4.7.1 or the retired `scripts/verify.sh` command are **historical facts**, not current instructions, and remain unchanged. A schema or generator may retain 4.7.1 only when it is explicitly labeled as the immutable recipe identity for those v1 bytes. Current execution authority is `CLAUDE.md`, this document, `docs/README.md`, active `docs/todo.md` entries, and executable scripts.
