# Prototype TD Collaboration Area

This directory is the repository-native coordination surface for concurrent work. It records incomplete work, completed outcomes, implementation contracts, durable decisions, handoffs, and small evidence references. Runtime behavior and verification remain authoritative; a document never substitutes for a green build.

## Directory contract

| Path | Purpose |
|---|---|
| [`todo.md`](todo.md) | Authoritative list of incomplete work and active file ownership. |
| [`completed.md`](completed.md) | Compact archive of accepted work with commit and evidence pointers. |
| [`plans/`](plans/) | File-level implementation contracts for collaborating agents. |
| [`decisions/`](decisions/) | Durable architectural choices and numbered deviations. |
| [`handoffs/`](handoffs/) | Agent-to-agent transfer records after a lane is verified and pushed. |
| [`media/`](media/) | Small collaboration evidence or references; never bulk generated assets. |
| [`art/`](art/) | Pre-existing TORCHLIGHT & STEEL reference set and provenance; not a collaboration-ledger surface. |

## Operating rules

1. Pull the current default branch before development. Start from a clean, understood tree and establish a green baseline with `scripts/verify.sh`.
2. Claim exactly one stable `TD-###` item in [`todo.md`](todo.md) before implementation. Record one owner, one branch, an exclusive file set, dependencies, non-owned files, acceptance criteria, and required evidence. Existing content under [`art/`](art/) retains its own provenance contract unless a lane names exact art paths.
3. Branches use `agent-N/<lane>` and commits use the exact prefix `AGENT N - `. Never force-push.
4. Parallelize only across disjoint file ownership. The simulation core, `scripts/verify.sh`, tick semantics, quality thresholds, and other shared hot files remain serial unless a coordinator explicitly sequences them.
5. Never write any file into a checkout another agent is actively verifying. Auto-discovered tests, scenarios, and bots can invalidate an in-flight run even when the new file appears unrelated.
6. Verify the lane locally. The integrating agent must independently rerun the merged union. A lane green is evidence for that lane, not for a future merge.
7. On completion, remove the full item from [`todo.md`](todo.md), append one auditable line to [`completed.md`](completed.md), and write a handoff containing exact commits, commands, evidence, risks, and next action.

## Integrity contract

> Never weaken/remove/reinterpret a failing check — fix the game. Screenshots only from the run just executed (verify report.json + mtimes); never reuse or hand-craft evidence. Impossible checks stay failing and get logged as numbered deviations. Never conclude "works" from a hung or skipped run. Tests and thresholds are human-owned: never edit a test or a threshold to pass — retune `data/*.tres`.

## Current repository anchors

- Default branch: `master`
- Verification entrypoint: [`../scripts/verify.sh`](../scripts/verify.sh)
- Feature/evidence ledger: [`../FEATURES.json`](../FEATURES.json)
- Repository rules: [`../CLAUDE.md`](../CLAUDE.md)
