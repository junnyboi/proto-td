# Agent Handoffs

Create one concise handoff per transferred lane. Include:

- Agent identity and exact branch
- Default-branch base SHA
- Commit SHAs and summaries
- Scope and explicit non-goals
- Files touched and any remaining reservations
- Verification commands, results, wall time, and evidence paths
- Todo/completed/decision updates and numbered deviations
- Known risks or required human verdicts
- One executable next action

The receiving or integrating agent must inspect the diff and rerun the merged gates. A lane green does not prove the union green.
