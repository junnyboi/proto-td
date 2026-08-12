# Prototype TD Collaboration Area

This directory is the Git-backed cold-resume surface for concurrent work. It records incomplete work, completed outcomes, implementation contracts, durable decisions, handoffs, and small evidence references. Runtime behavior and verification remain authoritative; a document never substitutes for a green build.

## Directory contract

| Path | Responsibility |
|---|---|
| [`todo.md`](todo.md) | Incomplete work, active agent/branch ownership, exclusive files, dependencies, acceptance, and evidence. |
| [`completed.md`](completed.md) | Compact history for items closed out of `todo.md`; not a duplicate product-feature ledger. |
| [`plans/`](plans/) | File-level implementation contracts and links to canonical MGS plans. |
| [`decisions/`](decisions/) | Durable architectural/product decisions and numbered deviations. |
| [`handoffs/`](handoffs/) | Agent transfers after a lane is verified: branch, base, commits, files, gates, risks, next action. |
| [`media/`](media/) | Small collaboration evidence or references; never bulk generated output. |
| [`art/`](art/) | Pre-existing TORCHLIGHT & STEEL references and provenance; not a collaboration-ledger surface. |

## Authority map

- `FEATURES.json` owns product acceptance, evidence references, and feature status; explicit evidence classes are a queued migration.
- `PLAYTEST.md` owns human verdict capture.
- `FINAL_REPORT.md` is the audit record, not the active queue.
- `CLAUDE.md` owns repository-local standing agent rules.

## Operating rules

1. Pull the current default branch before development; start clean and establish a green baseline with `scripts/verify.sh`.
2. Claim exactly one stable item in `todo.md` before implementation. Record one owner, one branch, an exclusive file set, dependencies, non-owned files, acceptance, and required evidence. Existing domain IDs remain valid; new general coordination IDs use `TD-###`.
3. Branches use `agent-N/<lane>` and commits use the exact prefix `AGENT N - `. Completed feature owners merge current `origin/master` into their feature branch, resolve and reverify there, push the branch, then fast-forward and reverify `master` before pushing it.
4. Parallelize only across disjoint files. The simulation core, `scripts/verify.sh`, tick semantics, thresholds, and shared ledgers remain serial unless explicitly sequenced.
5. Never write into a checkout another agent is actively verifying. Auto-discovered tests, scenarios, and bots can invalidate an in-flight run.
6. Verify each lane locally. The integrating agent independently reruns the merged union; lane green does not prove union green.
7. On closure, remove the item from `todo.md`, append one auditable line to `completed.md`, and write a handoff with exact commits, evidence, risks, and next action.
8. Force-push is forbidden in every form, including `--force-with-lease`. The accepted integration sequence is recorded in [D-001](decisions/D-001-autonomous-feature-integration.md).

## Integrity contract

> Never weaken/remove/reinterpret a failing check — fix the game. Screenshots only from the run just executed (verify report.json + mtimes); never reuse or hand-craft evidence. Impossible checks stay failing and get logged as numbered deviations. Never conclude "works" from a hung or skipped run. Tests and thresholds are human-owned: never edit a test or a threshold to pass — retune `data/*.tres`.

## Repository anchors

- Default branch: `master`
- Verification entrypoint: [`../scripts/verify.sh`](../scripts/verify.sh)
- Product feature ledger: [`../FEATURES.json`](../FEATURES.json)
- Repository rules: [`../CLAUDE.md`](../CLAUDE.md)
