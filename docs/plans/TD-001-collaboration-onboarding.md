# TD-001 — Collaboration Docs and Onboarding Contract

## Status and anchors

| Field | Pin |
|---|---|
| Status | Completed |
| Owner | AGENT 2 |
| Branch | `agent-2/collaboration-docs` |
| Base | `master` at `7babf28646fbc16c531a03ecdb44dd81f642677e` |
| Mode | Operational onboarding; no gameplay behavior change |
| Exclusive ownership | New coordination records: `docs/README.md`, ledgers, plans, decisions, handoffs, and media policy |
| Forbidden surface | Existing `docs/art/**`, gameplay code, `scripts/**`, `test/**`, `selftest/**`, thresholds, feature ledger, repository rules |

## Goal

Create the missing repository-native collaboration area required for conflict-safe multi-agent work. A cold-start agent must be able to identify active ownership, understand how work moves from todo to completed, write a compatible plan or decision, and hand off a verified branch without relying on chat history.

## Non-goals

This lane does not modify gameplay, balance, harness behavior, verification scripts, tests, `FEATURES.json`, `CLAUDE.md`, web export settings, or historical phase reports. It does not retroactively invent owners or evidence for work completed before this ledger existed.

## Deliverables

| File | Contract |
|---|---|
| `docs/README.md` | Index and binding collaboration workflow. |
| `docs/todo.md` | Incomplete-work ledger with one active bootstrap claim and a complete entry template. |
| `docs/completed.md` | Compact completion archive and one-line schema. |
| `docs/plans/README.md` | Plan requirements for future lanes. |
| `docs/decisions/README.md` | Decision/deviation naming and required fields. |
| `docs/handoffs/README.md` | Handoff schema covering agent, base, commits, scope, ownership, verification, docs, risks, and next action. |
| `docs/media/README.md` | Evidence freshness, size, provenance, and secret-safety policy. |
| `docs/handoffs/TD-001-agent-2-collaboration-onboarding.md` | Final verified transfer record. |

## Acceptance and evidence

| Check | Pass predicate | Evidence |
|---|---|---|
| Required structure | Every required directory contains tracked documentation. | Filesystem/schema check. |
| Ledger schema | Todo template includes status, owner, branch, base, dependencies, owned files, forbidden files, acceptance, evidence, and date. | Text contract check. |
| Handoff schema | Template includes every required transfer field. | Text contract check. |
| Link integrity | Every relative Markdown link resolves from its source file. | Link checker exit 0. |
| Scope isolation | Every branch change is under `docs/**`. | Git path check. |
| Build preservation | Existing import, lint, GUT, and headless scenarios remain green. | `scripts/verify.sh` ALL GREEN and `artifacts/verify.json`. |
| Recoverability | Final handoff names base, commits, commands, evidence, risks, and next action. | Handoff review. |

## Implementation sequence

1. Claim `TD-001` and the `docs/**` file set on the Agent 2 branch.
2. Add the index, ledgers, plan/decision/handoff/media contracts, and this plan.
3. Run structure, schema, relative-link, and scope-isolation checks.
4. Run `scripts/verify.sh`; commit the standalone onboarding implementation.
5. Move `TD-001` from active to completed, write the final handoff with the implementation SHA, rerun pre-push checks, and push the branch.

## Trim order and never-cut list

If scope pressure appears, omit optional examples before removing any required field. Never cut exclusive ownership, acceptance/evidence, integrity rules, completion movement, handoff verification, or scope-isolation checks.

## Preflight lint

- Contradictions: concrete file table and prose agree.
- Parameters: base SHA, branch, owner, paths, date, and verification entrypoint are pinned.
- Falsifiability: each acceptance row has a binary predicate and named evidence.
- Scope hygiene: explicit non-goals and forbidden surface are present.
- Dependencies: none; no external install or unlanded gameplay prerequisite.
- Integrity: the repository integrity contract remains verbatim in the docs index.

## Assumptions and deviation candidates

- A1: `master` remains the default branch through handoff; verify immediately before push.
- A2: no other agent owns the new coordination records; verify remote branches and active processes before mutation.
- A3: historical work remains represented by Git, `FEATURES.json`, and phase reports; this lane does not manufacture retrospective collaboration entries.
- A4: `docs/art/**` predates this lane and remains unchanged under its own provenance contract.
- D1: if `master` moves, merge it into the Agent 2 branch, revalidate links and scope, and rerun the full headless gate before push.

## As-built evidence

Implementation commit `c83c4d80b9aff8076235fdb74954c8cc57378af7` adds the eight planned coordination files without changing `docs/art/**` or any runtime surface; closure commit `8f90a376d865fc37bcac1c1c37bf3d28e280229a` moves TD-001 from active to completed. The deterministic docs validator passed all required-file, schema, verbatim-integrity, relative-link, and exact-path checks. At the clean frozen closure commit, `xvfb-run -a scripts/verify.sh --full` completed ALL GREEN in 139 seconds: 18 headless and 18 windowed scenarios, 11 bots plus quality gates, 61 fresh PNGs, and zero pixel skips. Agent visual review found no regression against the named scenario checklists. Two separate `bot_campaign` processes produced identical normalized telemetry with SHA-256 `81e68ba071f794e4b02db2243c97d5c961fe73b2b384d06695d7ed2269c71d26`. The rung inventory, report and screenshot hashes, replay result, and source scope are retained in `docs/media/TD-001-verification.json`.
