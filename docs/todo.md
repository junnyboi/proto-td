# Active Collaboration Work

This file contains incomplete work only. Allowed statuses are `pending`, `blocked`, and `in_progress`. Preserve every valid concurrent entry during merges; completed work moves to [`completed.md`](completed.md) rather than being duplicated here.

## TD-002 — Encode autonomous feature integration

- Status: in_progress
- Owner: AGENT 2
- Branch: `agent-2/collaboration-docs`
- Base: `master` at `7babf28646fbc16c531a03ecdb44dd81f642677e`
- Dependencies: TD-001
- Owned files: `CLAUDE.md`, `docs/README.md`, `docs/todo.md`, `docs/completed.md`, `docs/decisions/D-001-autonomous-feature-integration.md`
- Do not touch: gameplay code, `scripts/**`, `test/**`, `selftest/**`, `playtests/thresholds.json`, `FEATURES.json`, `docs/art/**`
- Acceptance: repository rules require completed feature branches to merge current master into the branch first, resolve and verify any conflicts there, then merge the branch into master, verify the merged tree, and push master normally; force-push is explicitly forbidden
- Required evidence: docs validator PASS; `scripts/verify.sh` ALL GREEN on the feature branch and again on merged master; normal remote pushes with matching local/remote master SHA
- Last update: 2026-08-12

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
