# Active Collaboration Work

This file contains incomplete work only. Allowed statuses are `pending`, `blocked`, and `in_progress`. Preserve every valid concurrent entry during merges; completed work moves to [`completed.md`](completed.md) rather than being duplicated here.

## TD-001 — Establish collaboration docs and onboarding contract

- Status: in_progress
- Owner: AGENT 2
- Branch: `agent-2/collaboration-docs`
- Base: `master` at `7babf28646fbc16c531a03ecdb44dd81f642677e`
- Dependencies: none
- Owned files: `docs/README.md`, `docs/todo.md`, `docs/completed.md`, `docs/plans/**`, `docs/decisions/**`, `docs/handoffs/**`, `docs/media/**`
- Do not touch: `docs/art/**`, gameplay code, `scripts/**`, `test/**`, `selftest/**`, `playtests/thresholds.json`, `FEATURES.json`, `CLAUDE.md`
- Acceptance: required `docs/` structure is tracked; todo/completed/plan/decision/handoff/media contracts are explicit; all relative links resolve; source diff is confined to `docs/**`; repository baseline remains green
- Required evidence: docs structure/link/schema checks; `scripts/verify.sh` ALL GREEN; clean branch status; pushed Agent 2 branch and handoff
- Last update: 2026-08-12

---

## Entry template

```markdown
## TD-### — Imperative work title

- Status: pending | blocked | in_progress
- Owner: AGENT N
- Branch: `agent-N/lane-name`
- Base: `<default branch>` at `<full SHA>`
- Dependencies: none | TD-###
- Owned files: exact paths or non-overlapping globs
- Do not touch: shared or externally owned paths
- Acceptance: falsifiable behavior and measurable exit conditions
- Required evidence: named tests, scenarios, screenshots, replay diffs, or documents
- Last update: YYYY-MM-DD
```
