# TD-005 — P15 Staging Area vertical-slice contract

## Goal

One top-level owner, **AGENT A**, implements and verifies the entire plain Staging Area vertical slice. Wide Research parallelizes read-only discovery and adversarial review; repository mutation remains single-owner.

Final player flow:

```text
Title → Campaign → Staging → Mission Control → Stage Select
Battle → Results → Staging
```

## Base and ownership

- Original base: `master` at `f65498a15a2375f3d71450441a372c0705cbf7ce`
- Reconciled contract tip: `af28022c71d7f7786f08a62393cfc53627caeff4`
- Owner/Integrator: AGENT A / `agent-a/p15-integration`
- Engine: Godot 4.7.1 stable regular
- Seed: 42

Agents B and C were unassigned by the human owner on 2026-08-12. Their incomplete lanes are absorbed here; no external handoff is required.

## Scope

### Production

- `autoloads/game.gd`
- `scenes/staging.tscn`
- `scripts/ui/staging.gd`
- `scripts/ui/stage_select.gd`
- `scripts/ui/results.gd`

### Verification

- `selftest/scenarios/staging_flow.gd`
- `selftest/scenarios/campaign_flow.gd`
- `selftest/scenarios/resign_flow.gd`

### Coordination and closure

- `FEATURES.json`
- `docs/todo.md`
- `docs/completed.md`
- `PLAYTEST.md`
- `docs/handoffs/TD-005-agent-a-p15-staging.md`
- this plan

## Observable contract

```text
Game.open_staging()
Game.open_stage_select()
Game.open_title()
Game.start_campaign() → Staging when interactive
STAGING_SCENE_PATH = res://scenes/staging.tscn
```

Final implementation hard-routes `open_staging()` to the scene. The temporary missing-scene fallback in the dependency commit must be removed before acceptance.

Required node names:

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

## UI contract

- Plain original tactical hub using current project colors and UI conventions; no new art and no copied XCOM layout.
- Fixed 1280×720 presentation with a centered 1080×620 shell.
- Heading ≥48px; operation labels ≥32px; detail/status text ≥24px.
- Mission Control and Back to Title are enabled.
- Barracks, Recruit, Training, Armory, and Memorial are visible, disabled, and explicitly labeled as future personnel operations.
- Campaign summary is nonblank and initially reports `0/8` cleared.
- Next-mission summary identifies the first unlocked campaign stage.
- Stage select includes `BackToStaging`.
- Campaign CLEAR and DEFEAT results expose `ReturnToStaging`; quick results remain mode-correct.

## Ordered implementation

1. Run Wide Research over repository UI conventions, staging information architecture, scenario proof, and routing regressions.
2. Synthesize accepted/rejected findings; update this plan only if repository facts require it.
3. Consolidate ledgers under Agent A.
4. Implement `staging.gd` and `staging.tscn`; import before cross-file references settle.
5. Remove the temporary route fallback; add Back/Return controls without changing campaign model semantics.
6. Add `staging_flow`; update campaign/resign scenarios minimally.
7. Run per-write lint, import, GUT, targeted headless/windowed scenario, then the full gate.
8. Read fresh P15 PNGs against the checklist.
9. Run independent adversarial diff review; fix any finding without weakening tests.
10. Close ledgers, reconcile current master, verify the branch and merged master, push normally.
11. Export the verified Web build, host through Manus WebDev, browser-smoke title → staging → mission control, inspect console, and deliver the playable URL.

## Acceptance and evidence

- Title Campaign opens `StagingRoot`.
- All operation controls exist.
- Five future operations are disabled and visibly unavailable.
- Mission Control opens stage select.
- Stage-select Back returns to the same campaign Staging state.
- Campaign CLEAR and DEFEAT results return to Staging.
- Quick battle never enters an active campaign Staging state.
- Completion sentinel is called.
- Fresh shots: `staging_initial.png`, `staging_to_missions.png`, `results_return_to_staging.png`.
- L5 checklist: labels fit 1280×720; measured text floor passes; enabled/disabled states are distinguishable; `0/8` summary is legible; no battle HUD/stage-row bleed; no void strips.
- `scripts/verify.sh --full` green on final branch and merged master.
- Final Web candidate is hosted and browser-smoke-tested.

## Non-goals

Hero instances, recruiting mechanics, points, five-unit retuning, permadeath, XP, equipment, specialization, save/load, new art, and new audio behavior remain P16+.

No changes to `sim/**`, `data/**`, battle/replay semantics, `BattleHash`, bots, `scripts/verify.sh`, tick semantics, or human-owned thresholds.

## Assumptions and deviations

- A1: `start_campaign(false)` remains the bot/non-UI path and does not swap scenes.
- A2: Existing campaign unlock, reward, star, squad, debug, quick battle, and result semantics remain unchanged.
- D-P15-01: If current scene structure makes a required node name impossible, record a numbered deviation before changing the observable contract.

## Integrity

> Never weaken/remove/reinterpret a failing check — fix the game. Screenshots only from the run just executed (verify report.json + mtimes); never reuse or hand-craft evidence. Impossible checks stay failing and get logged as numbered deviations. Never conclude "works" from a hung or skipped run. Tests and thresholds are human-owned: never edit a test or a threshold to pass — retune `data/*.tres`.

## Integration responsibility

Agent A owns implementation through merged-tree verification and hosted playtest delivery. It must merge current `origin/master` into the feature branch, resolve semantically, rerun required gates, fast-forward local master only after green, rerun full on master, push normally, and confirm local/remote SHA equality. Force-push is forbidden.

## Completion evidence — 2026-08-12

- Implementation commit: `7714b194c1fd83148e30c6e39f13c46e3703d8bc`.
- Fresh uninterrupted `scripts/verify.sh --full`: 63/63 rungs passed in 151 seconds; 19 scenario reports, 64 PNGs, zero pixel skips.
- Focused `staging_flow`: 94/94 checks and three fresh 1280×720 shots.
- Cross-process campaign replay: identical normalized telemetry, SHA-256 `3eef210dcea1635d1ef85cabe777c37abe6b103804986e4ca7c7ee5359e468d1`.
- Independent adversarial diff review: clean, no findings or pin breaks.
- Web export: official Godot 4.7.1 no-thread template; browser smoke passed Title → Campaign → Staging → Mission Control with no runtime console errors.
- WebDev checkpoint: `085c9c75`; public host: `https://prototype-td.manus.space`.
- Deviations: none.
