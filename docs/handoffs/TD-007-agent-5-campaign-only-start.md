# TD-007 — Campaign-Only Start Flow Handoff

- Agent / branch: AGENT 5 / `agent-5/campaign-only-start`
- Base: `master` at `690f7617acdc710855c3c8e169ad673b1fa8fec0`
- Frozen implementation candidate: `924f3607c7e72af67b9249729af4a02aae77d4da`
- Implementation commits: `ae6ee34508dd67bc91cedbe6a7d65fdaa358b385`, `8a2f31e8e451062fa3de48b64aaee58994cb197b`, `f08ee081705ce6d0aa2840bab9cccdf66ebfdd21`, `924f3607c7e72af67b9249729af4a02aae77d4da`
- Date: 2026-08-12

## Outcome

The prototype now has one player game flow. The title contains exactly one `StartButton` labeled **Start**; the former visible `CampaignButton` and title direct-battle action are gone. A real Start click initializes a fresh `CampaignState`, clears stale battle/route/result state, and opens Staging.

Campaign CLEAR and DEFEAT Results expose Retry, Return to Staging, and Back to Title. Direct `Game.start_battle()` remains only for harness, bot, debug, and tool seams. If such an internal battle opens Results without a CampaignState, the screen exposes only the safe Back to Title action; it cannot enter invalid campaign screens.

Back to Title clears campaign, campaign-active flag, pending stage, current battle, selected stage, selected squad, and last result. The boot scenario dirties route state before the raw Start click, preventing freshness assertions from passing on constructor defaults.

## Changed contracts

- `scripts/ui/title.gd`: sole Start action calls `Game.start_campaign()`.
- `autoloads/game.gd`: campaign initialization and title reset clear all transient route/battle state.
- `scripts/ui/results.gd`: campaign actions require both an active flag and non-null CampaignState; internal no-campaign Results retain only Back to Title.
- `boot`, `campaign_flow`, `staging_flow`, `resign_flow`, and `battle_controls`: route, reset, mode-safety, and negative-button assertions.
- `PLAYTEST.md`: current route is Title → Start → Staging and minimum build is `master` ≥ `f08ee08`.
- `FEATURES.json`: P13/P15 wording supersedes quick/two-button semantics; `FLOW-1` records the single-flow acceptance contract.

No simulation, balance data, bot timelines, thresholds, harness internals, tests, `scripts/verify.sh`, or audio policy changed.

## Verification evidence

At frozen hash `924f3607c7e72af67b9249729af4a02aae77d4da`, artifacts were deleted and one uninterrupted `xvfb-run -a scripts/verify.sh --full` ran from `2026-08-12T10:31:01Z` to `2026-08-12T10:33:23Z`:

| Measure | Result |
|---|---:|
| Wall time | 142 seconds |
| Verification rungs | 63/63 pass |
| Scenario reports | 19/19 pass |
| Pixel skips | 0 |
| `boot` checks / shots | 21 / 3 |
| `campaign_flow` checks / shots | 46 / 4 |
| `staging_flow` checks / shots | 95 / 3 |
| `resign_flow` checks / shots | 36 / 3 |
| `battle_controls` checks / shots | 34 / 5 |

Reviewed fresh screenshots from that run:

| Screenshot | Verdict |
|---|---|
| `artifacts/boot/boot.png` | Exactly one centered Start action; no Campaign text/button, ghost row, clipping, overlap, or edge void. |
| `artifacts/resign_flow/back_at_title.png` | Reset route returns the same single-action title with no stale battle/results projection. |
| `artifacts/resign_flow/results_defeat.png` | Campaign DEFEAT visibly offers Retry, Return to Staging, and Back to Title with complete labels. |
| `artifacts/staging_flow/staging_initial.png` | P15 Staging remains intact: 0/8, First Stand, enabled Mission Control/Back, and five disabled unavailable operations. |

All reviewed PNG mtimes fell inside the uninterrupted run and preceded their matching passing report mtimes.

Two separate `bot_campaign` OS processes at the frozen hash produced identical normalized telemetry:

`e725749e45e62690ae970ce1066865387562b6bc1bf119ce652bbf239997f084`

## Independent adversarial audit

Three independent read-only diff-vs-plan passes found and drove fixes for:

1. Internal no-campaign Results originally exposed invalid campaign destinations; fixed with campaign-state gating and a clicked safe-exit scenario.
2. P15 and playtest documentation still admitted old Campaign/two-flow wording; fixed to the sole Start contract and `f08ee08` minimum build.
3. Start freshness initially asserted an already-empty selected stage; fixed by clearing all transient state in `start_campaign()` and dirtying route fields before input.

The final independent audit of `924f360` versus base `690f761` returned **clean**, with no findings or pin breaks at confidence ≥80.

## Integration protocol

Autonomous integration follows repository policy: fetch and merge current `origin/master` into the feature branch if it moved, resolve without force-push, re-run the required merged-tree gates, fast-forward `master`, push normally, and confirm local/remote SHA equality. No deviations are recorded.
