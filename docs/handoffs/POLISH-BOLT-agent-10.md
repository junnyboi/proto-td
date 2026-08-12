# POLISH-BOLT Agent 10 Release Handoff

## Ownership

Agent 10 released `POLISH-BOLT` immediately on the user's 2026-08-12 instruction. The queue item is pending and unassigned. No files remain leased by Agent 10, no Godot/verification process remains active, and the work is not merged to `master`.

## Checkpoint

The pushed implementation branch is `agent-10/bolt-impact`; the standalone implementation checkpoint is commit `cf16ca2` (`[AGENT 10] Add deterministic Bolt impact presentation`). The branch was based on `master` at `f65498a15a2375f3d71450441a372c0705cbf7ce`. A future owner may adopt the branch only after claiming the queue row and performing a conflict-first comparison against the then-current `master`; otherwise cherry-pick or reimplement the checkpoint deliberately.

The checkpoint adds a hash-covered accepted-Bolt target-cell record, rejection equality coverage, a GPT Image 2 master with deterministic 48×48 TD32 normalization/provenance, manifest indirection, data-owned render-frame lifetime/scale, a centered `_process`-aged view transient, and the `bolt_impact` scenario with pre/live/expired pixel checks and a completion sentinel. It does not change Bolt damage, cooldown, targeting, audio, thresholds, `scripts/verify.sh`, or unrelated VFX.

## Green Evidence Before Release

The implementation checkpoint passed full GUT with 123/123 tests and 22,432 assertions. It passed `scripts/verify.sh` through R2, R2.5, R3, and all 19 headless scenarios. The targeted Xvfb run `scripts/verify.sh --scenario=bolt_impact --windowed` passed with seed 42, 13 checks, three fresh screenshots, zero pixel skips, and 44 frames. Manual review found the live glyph centered, jagged and readable at gameplay scale, above terrain, free of an opaque rectangle/text/watermark/trails, and fully absent in the expired capture.

## Mandatory Warning: Full Audit Is Not Complete

A clean frozen-hash `scripts/verify.sh --full` run was started from `cf16ca2` after deleting `artifacts/`, then terminated immediately when the user ordered Agent 10 to unassign the work. The terminated run reached R2, R2.5, R3, all 19 R4a headless scenarios, and windowed `assets_floor` plus `battle_controls`; it exited 143 during windowed `blocking`. This is intentionally not recorded as green evidence. Partial artifacts were deleted and must never be reused.

The planned cross-process campaign replay diff and independent adversarial diff-versus-plan review were not executed. `FEATURES.json`, `docs/completed.md`, and a final verification manifest were therefore not changed. Any future owner must rerun the entire final audit fresh and complete the product/evidence ledgers only after it is green.

## Known Implementation Notes

Candidates A–C were rejected for long horizontal-trail artifacts; candidate D became the retained generated master. The normalizer's shipping output is 48×48 RGBA with binary alpha, 260 opaque pixels, and 72 exact `#ffe9b0` probe pixels. The first expiry attempt exposed and then fixed an indentation regression in the common transient retention loop; the unchanged scenario assertion identified the defect. Standalone `--check-only` cannot resolve the `Game` autoload in `battle_view.gd`, so the repository-approved real project boot plus GUT is the compile gate.

## Takeover Procedure

1. Pull current `master`, inspect open PRs/branches/processes, and claim `POLISH-BOLT` with a new owner, branch, base SHA, exact files, non-goals, and evidence contract.
2. Read `docs/plans/POLISH-BOLT-agent-10.md` and compare `cf16ca2` against current `master` before selecting adopt, cherry-pick, or replace.
3. Run import, project boot, full GUT, targeted headless/windowed `bolt_impact`, and visually read fresh PNGs.
4. At a frozen clean hash, delete all artifacts and run one uninterrupted `scripts/verify.sh --full`; require zero windowed pixel skips.
5. Run the two-process normalized replay diff and an independent adversarial diff-versus-plan audit.
6. Only then update `FEATURES.json`, move the queue item to `docs/completed.md`, commit evidence/handoff closure, integrate conflict-first into current `master`, rerun merged-tree verification, and push.
