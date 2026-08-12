# D-002 — Retire the unsupported Movie Maker bot lane

- **Status:** accepted
- **Date:** 2026-08-12
- **Owner:** AGENT 8
- **Work item:** `VERIFY-MOVIE`
- **Plan:** [`../plans/VERIFY-MOVIE-agent-8.md`](../plans/VERIFY-MOVIE-agent-8.md)

## Context

`scripts/playtest.sh` advertised `--render` as a windowed Godot Movie Maker path that wrote a complete PNG frame sequence and WAV file for a bot run. The branch had existed since the repository scaffold, was not invoked by `scripts/verify.sh`, had no committed consumer or retained proof artifact, and had not been requalified against the current build. Its comment claimed Phase 9 exercise even though repository history did not contain a later change or durable qualification record.

The current verification contract already runs each seeded scenario in a direct windowed lane under Xvfb, captures bounded in-engine viewport PNGs from model conditions, and evaluates exact pixel probes. The MGS visual-assessment order reserves Movie Maker for a specific motion defect that cannot be settled through scene-state introspection, telemetry, GUT, or direct frame sampling. No active work item names such a defect. Retaining an untested capture flag as a supported interface would therefore overstate the project’s evidence surface and produce unbounded artifacts without an owner.

## Decision

Direct Xvfb scenario screenshots and pixel probes **supersede the generic Movie Maker bot lane** for normal verification.

The supported `scripts/playtest.sh` contract is now:

```text
scripts/playtest.sh <bot> [--seed N] [--ticks N]
```

The runner remains headless, fixed at 60 FPS, bounded by the existing shell watchdog and the bot’s `--max-ticks` guard, and writes telemetry through the existing game path. `--render`, `--out`, and every other unknown argument reject before engine launch with exit code 2. `scripts/verify.sh --full` remains the single supported render-evidence entrypoint and is not modified by this decision.

This decision does **not** declare Godot Movie Maker broken. It retires only the repository’s unqualified generic CLI lane. A future motion-specific work item may restore a Movie Maker command after meeting the reopen criteria below.

## Consequences

The repository has one fewer dormant verification interface and no longer implies that complete frame-sequence capture is continuously qualified. Normal bot telemetry remains available through the same command, seed, tick budget, and watchdogs. Fresh visual evidence continues to come from current-run Xvfb scenario captures with explicit checks and zero pixel skips.

Operators who still pass `--render` or `--out` receive an immediate, visible failure rather than a silent no-op. Historical reports that say the Movie Maker lane was once proven remain historical facts; D-002 supersedes their implication that the lane is an open release requirement.

The rollback path is a normal revert of the Agent 8 implementation commit. No force-push, threshold change, gameplay migration, or artifact conversion is required.

## Reopen criteria

A successor decision may restore Movie Maker only when all of the following are pinned:

1. A named motion defect such as jitter or tunneling that cheaper evidence channels cannot falsify.
2. A bounded capture window and double-watchdog behavior.
3. A machine-checkable consumer and pass/fail predicate for the captured sequence.
4. An artifact retention policy that prevents uncontrolled frame and audio output.
5. Integration into the verification contract, including a reproducible command and fresh evidence manifest.

## Verification

Closure requires shell syntax validation, one successful `bot_idle` headless smoke at seed 42 and 100 ticks, fail-closed checks for both retired flags, a clean cross-process `bot_campaign` replay diff, a fresh `scripts/verify.sh` pass, and a fresh `xvfb-run -a scripts/verify.sh --full` pass with zero pixel skips. Candidate-bound hashes and rung inventory are retained in [`../media/VERIFY-MOVIE-verification.json`](../media/VERIFY-MOVIE-verification.json).

## Supersession

This is the current decision of record. Do not silently restore `--render` or reinterpret D-002. A replacement must use a new `D-###` record, link back here, satisfy the reopen criteria, and name its verification owner.
