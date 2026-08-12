# Active Collaboration Work

This file contains incomplete work only. Allowed statuses are `pending`, `blocked`, and `in_progress`. Preserve every valid concurrent entry during merges; completed work moves to [`completed.md`](completed.md) rather than being duplicated here.

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
