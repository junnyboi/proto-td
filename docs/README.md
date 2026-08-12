# Repository Coordination Documents

This directory is the Git-backed cold-resume surface for multi-agent collaboration.

| Path | Responsibility |
|---|---|
| `todo.md` | Incomplete work, agent/branch ownership, exclusive files, dependencies, acceptance, and required evidence. |
| `completed.md` | Compact history for items closed out of `todo.md`; not a duplicate feature ledger. |
| `plans/` | Actionable repository-local implementation contracts and links to canonical MGS plans. |
| `decisions/` | Durable architectural/product decisions and numbered deviations. |
| `handoffs/` | Agent-to-agent transfer notes: branch, base, commits, files, gates, risks, next action. |
| `media/` | Small collaboration references/evidence only; use manifest or managed storage for large generated assets. |
| `art/` | Existing art references and pipeline material. |

Other authorities remain distinct:

- `FEATURES.json` owns product acceptance, evidence references, and feature status; explicit evidence classes are a queued schema migration.
- `PLAYTEST.md` owns human verdict capture.
- `FINAL_REPORT.md` is the audit record.
- `CLAUDE.md` owns repository-local standing agent rules.

Pull the default branch before changing shared coordination files. Keep edits atomic, preserve concurrent valid entries, never force-push, and never let two active items own the same file.
