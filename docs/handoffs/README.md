# Agent Handoffs

Write one handoff per completed or blocked lane. Prefer `TD-###-agent-N-short-topic.md`; domain-specific stable IDs may retain their established form. The receiving agent must inspect the diff and rerun required gates—worker green does not prove the merged union.

## Required template

```markdown
# <stable ID> — Handoff title

- Agent / branch: AGENT N / `agent-N/lane-name`
- Base: `<default branch>` at `<full SHA>`
- Commits: `<SHA>` — summary
- Scope: what changed
- Non-goals: what deliberately did not change
- File ownership: exact files touched; reservations released or retained
- Verification: command, verdict, wall time, and evidence path
- Docs: todo/completed movement, plan, decisions, and deviations
- Risks: known gaps, blockers, conflicts, and human verdicts
- Next action: one concrete integration or follow-up command
```

A blocked handoff keeps its item in [`../todo.md`](../todo.md) with `Status: blocked`. A completed handoff moves the item to [`../completed.md`](../completed.md). Every handoff must identify the exact branch, base, commits, files, gate evidence, risks, and one executable next action.
