# D-001 — Autonomous Feature Integration

## Status and authority

- Status: accepted
- Date: 2026-08-12
- Authority: human owner
- Owner: AGENT 2 for initial codification; applies to every future feature owner

## Context

Feature branches previously ended at push and handoff, leaving integration as a separate receiving-agent action. The owner now requires the feature owner to carry completed, quality-gated work through integration into `master` autonomously. Conflicts must be reconciled on the feature branch before master changes, and Git history must never be rewritten by force-push.

## Decision

Every completed feature follows this sequence:

1. Fetch current remote state while on the feature branch.
2. Merge `origin/master` into the feature branch before integrating. If conflicts exist, resolve them semantically on the feature branch, preserve both valid behaviors, commit with the assigned agent prefix, and rerun the scope required by `docs/validation.md`.
3. Push the verified feature branch normally.
4. Switch to local `master` and pull `origin/master` with `--ff-only`.
5. Fast-forward `master` to the verified feature branch. If fast-forward is impossible because master moved again, do not resolve on master; return to the feature branch, merge the new master, resolve, reverify, and repeat.
6. Run the same required validation scope again on the merged master, then push master normally.
7. Confirm local and remote master resolve to the same SHA and the working tree is clean.

`git push --force`, `git push -f`, and `git push --force-with-lease` are forbidden.

## Consequences

The feature owner remains accountable through merged-tree verification rather than stopping at branch-local green. Conflicts are isolated where the feature context and tests exist, master receives only a branch that already contains current master, and a failed master fast-forward becomes an explicit signal to repeat reconciliation. Feature branches may remain on the remote after integration unless a separate cleanup policy removes them.

## Historical verification evidence

The initial application is TD-002 on `agent-2/collaboration-docs`. Policy commit `369d3f82da3b356a265b718f52c6d82ceb557284` first merged current master into the feature branch (already contained; zero conflicts), then passed the now-retired `xvfb-run -a scripts/verify.sh --full` workflow in 155 seconds: 61 green rungs, 18 headless and 18 windowed scenarios, 11 bots, 11 quality gates, 61 fresh PNGs, and zero pixel skips. All screenshots passed checklist review. Candidate-bound evidence is retained in `docs/media/TD-002-branch-verification.json`. This paragraph records historical evidence only; current gates come from `docs/validation.md`. Integration still stops on any conflict or red gate; force-push is never a recovery mechanism.
