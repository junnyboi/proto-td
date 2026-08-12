# TD-003 — P15 Staging Area routing and three-lane contract

## Goal

Insert a plain Staging Area as the campaign home without changing campaign progression, battle semantics, balance, hashes, quick battle, or persistence. Final player flow:

```text
Title → Campaign → Staging → Mission Control → Stage Select
Battle → Results → Staging
```

## Base and ownership

- Base: `master` at `f65498a15a2375f3d71450441a372c0705cbf7ce`
- Integration owner: AGENT A / `agent-a/p15-integration`
- UX dependency: AGENT B / `agent-b/p15-staging-ux`
- Verification dependency: AGENT C / `agent-c/p15-staging-verification`
- Engine: Godot 4.7.1 stable regular
- Seed: 42

## Research synthesis

### Accepted

- Current campaign routing is autoload-owned and session-only; P15 adds no model state.
- Existing campaign unlocks, rewards, stars, selected squad, quick battle, debug behavior, battle/replay IDs, and hashes remain unchanged.
- `Game.start_campaign()` must create the same fresh `CampaignState` and then enter Staging for interactive launches; bots still pass `false` and drive stages directly.
- The only Agent A production file is `autoloads/game.gd`.
- Agent B and C receive observable methods and exact node names, not line-number promises.

### Rejected as scope creep

- No `BattleHeroSpec`, hero IDs, profile/roster model, campaign hash, result transaction, persistence, reset redesign, duplicate-archetype behavior, stage-cap tuning, or debug-policy change in P15.
- No changes to `sim/`, battle creation, deploy/debug verbs, `BattleHash`, bots, thresholds, or data resources.

## Observable dependency contract

Agent A publishes:

```text
Game.open_staging()
Game.open_stage_select()
Game.open_title()
Game.start_campaign() → Staging when interactive
STAGING_SCENE_PATH = res://scenes/staging.tscn
```

During the dependency-only commit, `open_staging()` temporarily falls back to stage select if `staging.tscn` is absent so the pre-existing suite remains green. Agent A removes that fallback after merging Agent B and before Agent C’s acceptance run. The final build must hard-route to Staging.

Agent B exposes these exact node names:

```text
StagingRoot
StagingHeading
CampaignSummary
NextMissionSummary
MissionControlButton
BarracksButton
RecruitButton
TrainingButton
ArmoryButton
MemorialButton
BackToTitleButton
OperationStatus
BackToStaging
ReturnToStaging
```

## Exclusive files

| Lane | Owned files |
|---|---|
| Agent A | `autoloads/game.gd`, `FEATURES.json`, `docs/todo.md`, final `docs/completed.md`, final `PLAYTEST.md`, final handoff |
| Agent B | `scenes/staging.tscn`, `scripts/ui/staging.gd`, `scripts/ui/stage_select.gd`, `scripts/ui/results.gd` |
| Agent C | `selftest/scenarios/staging_flow.gd`, `selftest/scenarios/campaign_flow.gd`, `selftest/scenarios/resign_flow.gd` |

Never parallelize `scripts/verify.sh`, simulation/model files, tick semantics, thresholds, or shared ledgers. No two agents edit one file.

## Ordered implementation

1. Agent A publishes the route contract from the frozen green base.
2. Agent B branches from the exact contract SHA and implements the plain staging UX.
3. Agent C may research while Agent B works; it branches from the contract and tests only after Agent B’s commit is available.
4. Agent A merges Agent B, removes the temporary route fallback, and performs import/boot smoke checks.
5. Agent A merges Agent C and runs `staging_flow` headless/windowed.
6. Agent A runs one full union gate, reads fresh PNGs, updates ledgers, integrates master, reruns full, exports Web, browser-smokes, and delivers the URL.

## Acceptance and evidence

- `staging_flow` proves title → staging → mission control, stage-select Back, campaign result returns, and quick-mode separation.
- Five future operation controls exist and are disabled.
- Initial summary is nonblank and reports `0/8`.
- Required fresh shots: `staging_initial.png`, `staging_to_missions.png`, `results_return_to_staging.png`.
- Text measures at least 48px heading, 32px operation labels, and 24px detail text.
- No HUD/stage bleed or void strips.
- `scripts/verify.sh --full` is green on the union and again on merged master.
- Final candidate is exported to Web, hosted through Manus WebDev, browser-smoke-tested, and delivered for L7.

## Non-goals

Hero instances, recruiting, points, field-cap retuning, permadeath, XP, equipment, specialization, save/load, new art, and audio are deferred to P16+.

## Assumptions and deviations

- A1: `start_campaign(false)` remains the bot/non-UI path and does not swap scenes.
- A2: Existing campaign model behavior is unchanged.
- A3: The temporary missing-scene fallback exists only in the dependency commit and is removed before final acceptance.
- D-P15-01: If Agent B cannot satisfy the fixed node-name contract, stop and revise this contract rather than silently renaming test seams.

## Integrity

> Never weaken/remove/reinterpret a failing check — fix the game. Screenshots only from the run just executed (verify report.json + mtimes); never reuse or hand-craft evidence. Impossible checks stay failing and get logged as numbered deviations. Never conclude "works" from a hung or skipped run. Tests and thresholds are human-owned: never edit a test or a threshold to pass — retune `data/*.tres`.

## Integration responsibility

Agent A inspects and serially merges both lane diffs, independently reruns every required gate, reconciles current master on the feature branch, fast-forwards master only after green, pushes normally, and confirms local/remote SHA equality. Force-push is forbidden.
