# VERIFY-MOVIE — Agent 8 released WIP handoff

- **Status:** released; pending and unassigned
- **Former owner:** AGENT 8
- **Branch:** `agent-8/retire-movie-maker`
- **Base:** `f65498a15a2375f3d71450441a372c0705cbf7ce`
- **Claim commit:** `0ece60c`
- **Implementation commit:** `51e08de72eb91992b63c0bd35047ebd6690f32fe`
- **Reason for release:** explicit user instruction on 2026-08-12 to unassign all existing Agent 8 tasks

## Preserved WIP

The branch contains a complete but **not integrated** retirement proposal for the generic Movie Maker bot lane. It narrows `scripts/playtest.sh` to `<bot> [--seed N] [--ticks N]`, makes `--render` and `--out` fail closed with exit 2, and adds `docs/decisions/D-002-retire-movie-maker.md`. No gameplay, simulation, view, data, asset, harness, scenario, threshold, bot, or `scripts/verify.sh` file changed.

A future owner must make an independent adoption decision. The unassigned todo item intentionally restores the original either/or acceptance: record that direct Xvfb screenshots supersede Movie Maker, or retain and execute a bounded Movie Maker proof. The next owner may adopt, revise, or discard Agent 8's proposal; this handoff grants no ownership and claims no merge authority.

## Fresh evidence at the frozen implementation commit

- `bash -n scripts/playtest.sh`: PASS.
- `scripts/playtest.sh bot_idle --seed 42 --ticks 100`: exit 0; fresh telemetry written.
- `scripts/playtest.sh bot_idle --render`: exit 2 with `unknown arg: --render`.
- `scripts/playtest.sh bot_idle --out /tmp/forbidden`: exit 2 with `unknown arg: --out`.
- `scripts/verify.sh`: ALL GREEN before the implementation checkpoint.
- `xvfb-run -a scripts/verify.sh --full`: ALL GREEN in 142 seconds at `51e08de72eb91992b63c0bd35047ebd6690f32fe`; 61 rungs, 18 headless scenarios, 18 windowed scenarios, 11 bots plus 11 gates, 61 fresh PNGs, and zero pixel skips.
- Two separate `bot_campaign` processes at seed 42 / 3600 ticks normalized by deleting only `.meta.wall_ms` and `.meta.engine`: empty diff and identical SHA-256 `81e68ba071f794e4b02db2243c97d5c961fe73b2b384d06695d7ed2269c71d26`.

The independent adversarial and visual review calls were interrupted before completion by the user's release instruction. Their absence is intentional and means this WIP is **not closure-ready** without a future owner's fresh review and merged-tree verification.

## Resume instructions

1. Fetch all remotes and confirm `VERIFY-MOVIE` remains unassigned on every active branch.
2. Read `docs/plans/VERIFY-MOVIE-agent-8.md` and `docs/decisions/D-002-retire-movie-maker.md`; do not assume D-002 is accepted merely because it exists on this WIP branch.
3. Claim the task under a new owner/branch and pin a fresh base SHA and exclusive files.
4. Reconcile current `master` semantically before adopting any commit; Agent 7's active `POLISH-BOLT` branch was disjoint at release time but may have merged since.
5. Re-run targeted checks, one clean `scripts/verify.sh --full`, cross-process replay, independent adversarial review, and merged-union verification before closure.
6. Never force-push or weaken a test, threshold, pixel check, or evidence rule.

## Repository state

At release time, no Agent 8 commit had been merged into `master`. The latest branch commit after this handoff should be the ownership-release commit. The default branch therefore remains authoritative, and this branch is only a recoverable WIP reference.
