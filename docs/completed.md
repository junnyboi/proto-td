# Completed Work

Compact cold-resume history for work closed out of `docs/todo.md`. One line per item:

```text
ID | agent | outcome | commit | evidence
```

`FEATURES.json` remains the canonical product-feature/evidence ledger; this file must not duplicate it one-for-one. Periodically merge redundant prose into efficient one-liners, but never remove stable IDs, commit SHAs, deviations, or evidence needed to reproduce or understand a result. Historical work predating agent identities is labeled `LEGACY`, never retroactively attributed.

## Historical coordination backfill

- PROC-MULTIAGENT-BOOTSTRAP | AGENT 1 | Established active/completed ledgers, coordination docs, branch ownership, prefixed commits, safe merge/push rules, and merged-tree verification | commit `e6bbda1` | `docs/handoffs/PROC-MULTIAGENT-BOOTSTRAP.md`
- TD-001 | AGENT 2 | Established collaboration ledgers/contracts and preserved onboarding verification evidence | implementation commit `c83c4d8` | `docs/handoffs/TD-001-agent-2-collaboration-onboarding.md`, `docs/media/TD-001-verification.json`
- TD-002 | AGENT 2 | Required conflict-first autonomous feature integration into master and prohibited every force-push form | policy commit `369d3f8` | `docs/decisions/D-001-autonomous-feature-integration.md`, `docs/media/TD-002-branch-verification.json`
- TD-003 | AGENT 4 | Generated and provenance-locked six loopable orchestral candidates—one BGM/boss pair per act—with retained source/transcription evidence and exact integrity gates; human acceptance remains TD-004 | implementation commits `be1c50b`, `97f5b3b` | `docs/handoffs/TD-003-agent-4-luminous-descent-music.md`, `docs/media/TD-003-verification.json`
- TD-005 | AGENT A | Added the plain P15 Staging hub, mode-correct campaign returns, state-preserving Mission Control route, and focused route proof; full gate and hosted browser smoke green | implementation commit `7714b19` | `docs/handoffs/TD-005-agent-a-p15-staging.md`, WebDev checkpoint `085c9c75`
- TD-006 | AGENT 4 | Regenerated Act I BGM and both Act III cues from human prompt-change feedback; exact source/transcription lineage, low-band gains, untouched-cue hashes, full verification, and independent audit green; human acceptance remains TD-004 | implementation commit `a58e2d5` | `docs/handoffs/TD-006-agent-4-three-cue-regeneration.md`, `docs/media/TD-006-verification.json`
- TD-007 | AGENT 5 | Replaced the title's direct battle/Campaign split with one Start→campaign route, made Results campaign-only for players with a safe harness exit, and added non-vacuous fresh-session/reset proof | verified implementation `924f360` | `docs/handoffs/TD-007-agent-5-campaign-only-start.md`
- TD-008 | AGENT 2 | Height-filled the live battle viewport and added bounded middle-drag/wheel X/Y panning with resize-safe picking, VFX, shake, overlays, and minimal deploy auto-framing | frozen candidate `3989689` | `docs/handoffs/TD-008-agent-2-map-height-fill-pan.md`, external `td008-release-evidence/manifest.json`
- TD-009 | AGENT 2 | Replaced scattered cardinal facing buttons with a compact viewport-safe isometric diagonal cluster and preserved real-input `Facing.RIGHT` deployment semantics | implementation `2d9f351` | `docs/handoffs/TD-009-agent-2-isometric-facing-arrows.md`, external `facing-arrows-agent-2/ORIENTATION.json`
- LEGACY-P10-LANES | LEGACY | Integrated campaign data, stage authoring, bot timelines, unlock flow, results, and campaign proof | commits `0eaf9ad`, `13f5251`, `83b7368` | `FEATURES.json` P10/LB/LC; `FINAL_REPORT.md` §5
- LEGACY-P12 | LEGACY | Integrated isometric projection, terrain/elevation presentation, responsive canvas fit, and deploy UX | merge `9c660c8`; feature commits `27c95c7`, `84026cc` | `FEATURES.json` P12; `PLAYTEST.md` Phase 12 note
- LEGACY-P13 | LEGACY | Integrated pause/speed/resign controls and universal terminal-results flow | commits `bbf4759`, `8dfbfa3` | `FEATURES.json` P13
- LEGACY-P14-LANES | LEGACY | Integrated determinism, resize correctness, harness integrity, content/docs, and merged-tree verification | merge `7babf28`; lane commits `401a489`…`84a5cd2` | `FEATURES.json` P14; `FINAL_REPORT.md` §9
