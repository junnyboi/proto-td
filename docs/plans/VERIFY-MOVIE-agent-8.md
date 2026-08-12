# VERIFY-MOVIE — Agent 8 Movie Maker Lane Decision and Retirement Plan

## Summary

This companion session closes the dormant Movie Maker verification question without changing gameplay. The selected decision is to **retire `scripts/playtest.sh --render` and its unused `--out` argument from the supported CLI**, because current MGS verification uses seeded scenario state checks plus direct in-engine Xvfb viewport captures and pixel probes. Movie Maker remains an escalation technique only when motion must be seen and cannot be settled by state, telemetry, GUT, or direct frame sampling.

| Anchor | Pin |
|---|---|
| Owner | AGENT 8 |
| Branch | `agent-8/retire-movie-maker` |
| Base | `master` at `f65498a15a2375f3d71450441a372c0705cbf7ce` |
| Baseline | `scripts/verify.sh` ALL GREEN on the base |
| Stable item | `VERIFY-MOVIE` |
| Mode | Companion/process lane; no player-facing behavior change |

The current `--render` branch was introduced in the scaffold, is excluded from `scripts/verify.sh`, has no committed consumer or evidence artifact, and captures a full bot frame stream plus WAV output. The current MGS environment and harness rules explicitly classify Movie Maker as unnecessary for ordinary juice verification and reserve it for rare motion-only escalation. The supported verification surface is therefore narrower and more honest if the unqualified CLI path is removed rather than advertised as exercised.

## Goal and non-goals

The goal is to record a durable supersession decision, remove the unsupported Movie Maker flags from `scripts/playtest.sh`, prove the normal headless bot path still works, and re-run the current merged verification ladder.

This lane does **not** change `scripts/verify.sh`, the harness, scenarios, gameplay code, simulation state, tick order, visual assets, audio policy, bots, thresholds, human verdicts, Web export, or Agent 7's active `POLISH-BOLT` surface. It does not claim that Movie Maker is technically broken; it classifies it as unnecessary and unsupported unless a future falsifiable motion requirement reopens it.

## Pinned parameters and file ownership

| Parameter | Value | Reason |
|---|---|---|
| Seed | 42 | Repository verification convention |
| Headless smoke bot | `bot_idle` | Cheapest real consumer of `playtest.sh` |
| Headless smoke ticks | 100 | Human-owned tier-1 minimum and bounded execution |
| Shell watchdog | Existing `playtest.sh` formula | No new timing contract |
| Full gate | `xvfb-run -a scripts/verify.sh --full` | Linux render lane with fresh screenshots and zero pixel skips |
| Replay oracle | Two fresh `bot_campaign` OS processes, wall/engine metadata normalized | Confirms the CLI change did not alter deterministic outcomes |

Exclusive files are `scripts/playtest.sh`, `docs/plans/VERIFY-MOVIE-agent-8.md`, `docs/decisions/D-002-retire-movie-maker.md`, `docs/handoffs/VERIFY-MOVIE-agent-8.md`, `docs/media/VERIFY-MOVIE-verification.json`, and the `VERIFY-MOVIE` claim/closure rows in `docs/todo.md` and `docs/completed.md`. Shared ledgers are edited atomically after pull/reconciliation. Agent 7's `POLISH-BOLT` files and all hot verification surfaces remain forbidden.

## Dependency contract

- **A1 — current verification contract:** `scripts/verify.sh --full` directly captures fresh windowed scenario PNGs, runs pixel probes, bots, and gates. Verify against the live tree before integration.
- **A2 — Movie Maker escalation policy:** MGS routes visual assessment through state, telemetry, GUT, and direct viewport capture before Movie Maker. Reopen only when a named motion defect cannot be falsified through cheaper channels.
- **A3 — no active consumer:** no repository script, test, doc command, or CI entry invokes `playtest.sh --render`. Re-run repository search before removal and before merge.
- **A4 — headless compatibility:** `scripts/playtest.sh bot_idle --ticks 100` remains exit 0 and writes fresh telemetry through the existing runner.
- **A5 — rejection honesty:** after retirement, `--render` and `--out` must fail closed as unknown arguments with exit 2 rather than silently no-op.

## Phase 1 — Retire the unsupported CLI lane

### File-level deliverables

1. `scripts/playtest.sh`: remove `--render`, `--out`, render-only state, frame-directory creation, and `--write-movie`; preserve the headless bot command and watchdog exactly.
2. `docs/decisions/D-002-retire-movie-maker.md`: accepted decision with context, testable behavior, consequences, rollback/reopen criteria, verification, and supersession rules.
3. Repository/project plans: this file and the canonical external plan.
4. Closure records: `docs/handoffs/VERIFY-MOVIE-agent-8.md`, `docs/media/VERIFY-MOVIE-verification.json`, `docs/completed.md`, and removal from `docs/todo.md` after all gates pass.

### Acceptance and evidence

| Check | Pass predicate | Evidence |
|---|---|---|
| Shell syntax | `bash -n scripts/playtest.sh` exits 0 | Command result |
| Supported bot path | `scripts/playtest.sh bot_idle --ticks 100` exits 0 | Fresh telemetry and command log |
| Retired flags fail closed | `--render` and `--out` each exit 2 with `unknown arg` | Captured stderr/exit codes |
| Scope isolation | Diff touches only the pinned files | `git diff --name-only` |
| Headless regression | `scripts/verify.sh` is ALL GREEN | `artifacts/verify.json` |
| Render/union regression | `xvfb-run -a scripts/verify.sh --full` is ALL GREEN with zero windowed pixel skips | Fresh rung/report/screenshot manifest |
| Determinism | Two separate `bot_campaign` runs normalize to an empty diff | Hashes and diff result in durable evidence JSON |
| Documentation | Decision, todo/completed movement, and handoff agree on status, SHA, and evidence | Adversarial mapping review |

No gameplay exactness arithmetic changes. The exact CLI contract is: accepted arguments are `<bot>`, `--seed N`, and `--ticks N`; every other argument rejects before engine launch with exit 2.

## Verification ladder and integrity

L1 is `bash -n` plus `git diff --check`; L2/L3 are covered by the full GUT/import/boot path in `scripts/verify.sh`; L4/L5 use the unchanged seeded headless and Xvfb windowed scenarios, current-run PNGs, and pixel probes; L6 is the standalone-green prefixed commit plus evidence manifest; L7 remains the existing blocked human playtest and is unaffected because this change has no player-facing behavior.

> Never weaken/remove/reinterpret a failing check — fix the game. Screenshots only from the run just executed (verify report.json + mtimes); never reuse or hand-craft evidence. Impossible checks stay failing and get logged as numbered deviations. Never conclude "works" from a hung or skipped run. Tests and thresholds are human-owned: never edit a test or a threshold to pass — retune `data/*.tres`.

## Trim order and never-cut list

After three distinct implementation failures, trim only optional prose duplication. Never cut the fail-closed negative checks, the durable decision, scope isolation, headless bot smoke, full Xvfb gate, replay diff, ledger closure, or semantic reconciliation with current `master`.

## Preflight lint

| Reviewer check | Verdict |
|---|---|
| Contradiction scan | PASS: retirement removes the advertised CLI flags and the decision names future escalation criteria; it does not claim the engine feature is broken. |
| Content obtainability | N/A: no game content changes. |
| Unpinned parameters | PASS: seed, bot, ticks, watchdog owner, full command, and replay oracle are pinned. |
| Exactness and observation convention | PASS: no tick arithmetic changes; CLI acceptance/rejection behavior is exact. |
| Integrity and ladder | PASS: integrity text is verbatim; all applicable rungs and the L7 non-impact are explicit. |
| Watchdogs | PASS: the existing shell and bot tick watchdogs are preserved; all direct engine runs remain bounded. |
| Scope hygiene | PASS: explicit non-goals, exclusive files, trim order, never-cut list, and resume anchors are present. |
| Dependencies | PASS: Godot, Xvfb, GUT, bots, and verification scripts are already present; no network dependency. |
| Phase order | PASS: one process/CLI phase; no model or content work. |
| Falsifiability | PASS: positive headless smoke, two negative flag checks, full gate, and replay diff can all fail honestly. |

## Deviations and rollback

- **D1 candidate:** if a live repository consumer of `--render` appears before merge, stop retirement, retain the lane, and re-scope to a bounded qualification proof rather than deleting that consumer.
- **D2 candidate:** any full-gate red is routed by the repository failure table and blocks closure; no test, threshold, or screenshot rule may be weakened.

Rollback is a normal revert of the Agent 8 implementation commit. A future decision may restore Movie Maker only with a named motion defect, a bounded capture window, a machine-checkable consumer, watchdogs, artifact retention policy, and integration into the verification contract.
