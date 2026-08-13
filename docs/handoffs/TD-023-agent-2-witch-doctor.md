# TD-023 — Witch Doctor deterministic healing

**Owner:** AGENT 2

**Branch:** `agent-2/td-023-witch-doctor`

**Base:** `f84810578303d6599b4e5de89c407f9747d3812d`

**Superseded candidate:** `c0506a4d1da93dd45e78987ebf7306b7970a870f` — independent audit FAIL; never eligible for merge

**Corrected implementation:** `91b427cce0321ce2554b9d2ec145f72a0ffe942a`

**Pre-closure latest-master union:** `5d18de44eab4d0334e376640f7b2c69646d3a461`

**Coordination rekey:** The lane was originally claimed as TD-021. While it was in release assurance, master landed an independent completed TD-021 music lane and TD-022 roster lane. The Witch Doctor closure was therefore rekeyed to the next unused stable ID, TD-023; no gameplay or evidence meaning changed.

## Outcome

TD-023 adds `witch_doctor_1` as an eleventh, separate advanced Mage template. It does not rename, alias, or retune `caster_2` Sorcerer. Witch Doctor is an elevated, rarity-3, 18-DP support unit with 110 HP, zero attack, and the data-owned `mend` skill.

Mend accepts `mend(healer_unit_id, target_unit_id)` only for a different, living, injured allied unit within Chebyshev range 2 while the healer is alive and fully charged. Acceptance restores `min(60, missing_hp)`, spends all SP, records the exact trigger tick and target ID, and increments `skills_fired`. Self, full-HP, dead/retreated, missing, out-of-range, wrong-skill, uncharged, terminal, malformed, and untargeted-trigger commands are hash-equal rejects. Mend never revives or touches strategic death records.

Witch Doctor is the sole S7 first-clear reward. The catalog therefore remains five starters, reaches ten after S6, and reaches all eleven only after S7. The new generated battle frames and portrait have separate logical IDs, canonical provenance, and truthful `placeholder: true` flags.

## Determinism and replay

`OperatorDef.OpClass.HEALER = 5` and `SkillDef.Effect.HEAL_TARGET = 6` are append-only. `UnitState.skill_target_unit_id` joins `BattleHash` and the hash-paranoia table in the same change.

The exact three-Mend differential on `test_skill`, seed 42, produces CLEAR at tick 1762 with 2 kills/0 leaks/10 HP; filtering only those Mend rows produces DEFEAT at tick 1402 with 0 kills/2 leaks. The canonical `witch_doctor.json` replay contains an accepted Mend followed by an SP-empty rejected Mend. The runner asserts semantic post-action state and the pinned final battle hash, while `scripts/replay_check.sh` proves separate-process equality.

## Player input and presentation

One full-SP Witch Doctor click enters target mode without changing the model. Invalid target clicks keep the mode active and hash-equal. Right-click and `ui_cancel` cancel hash-equal. A live non-vacuous middle drag is blocked through `DeployBar.is_mend_targeting()`. Clicking the one highlighted Defender dispatches exactly one Mend and exits. A ready Defender still fires its legacy instant skill with one click.

The view edge-detects `skill_triggered_tick + skill_target_unit_id` and emits a target-side mint burst. The lifetime is 16 render frames from `JuiceConfig`. The dual-lane scenario proves presence then absence with reserved-color probes and a mandatory completion sentinel.

## Assurance history

The red acceptance suite initially failed because the enum, resource, and verb did not exist. During implementation, exact gates found and corrected: malformed ReplayCodec indentation; an independent provenance classifier missing the new operator ID; the pinned P16 replay suite count changing from 5/5 to 7/7 (feature-specific assertions were moved intact into `test_witch_doctor.gd`, never removed); and the synthetic `ui_cancel` path not reaching `_input` (DeployBar now also observes the action state). No threshold, watchdog, expected result, or verification script was weakened.

One standard run saw R3.7 filesystem-web exit 139 during clean import. The unchanged rung passed immediately in isolation, then the full standard ladder was restarted from R2 and completed ALL GREEN. A later plan-checklist review found invalid-click, cancellation, pan-block, legacy-skill, screenshot-name, and watchdog evidence gaps; the game/scenario were corrected and the complete standard ladder was restarted and passed again.

The first frozen release candidate then completed a fresh 183.310-second full gate with 78 passing rungs, 25 passing windowed reports, zero pixel skips, and identical 11-replay cross-process output. The mandatory independent audit still rejected it: `BattleModel.apply_action` converted a String `"mend"` to `StringName` before checking the pinned exact verb type. The dispatcher now rejects every non-`TYPE_STRING_NAME` verb before conversion, and hash-equal tests reproduce String, integer, bool, and null verb variants. The release audit restarts from a new frozen commit; no evidence from `c0506a4` will be reused.

## Plan deviations and boundaries

- D-WD-1 exercised: Mend validation/mutation was extracted to pure `sim/healing_rules.gd` because `BattleModel` was at its public-method cap. The dispatcher remains the sole mutation entry and the UI calls the same pure validator.
- `BattleView` color constants moved to immutable `scripts/view/battle_palette.gd` to remain under the 1,000-line lint cap; no presentation value changed except the additive healer color.
- Replay runner expectation objects are additive; every legacy boolean array and existing replay fixture byte remains unchanged.
- D-WD-4 exercised and explicit: adding a canonical generated operator changes shared checked-in generator inputs (`tools/gen_assets.gd`, palette/operator/portrait recipes, and the provenance router). Every legacy generated provenance sidecar authenticates those shared source bytes, so truthful canonical regeneration necessarily refreshes its source digests and the manifest's provenance hashes even though every unrelated PNG remains byte-identical. Preserving the old sidecar bytes would make their authenticated source digests false and fail the exact provenance contract. This is a provenance-only migration: acceptance state, generation facts, source closure, logical IDs, and all unrelated asset bytes remain unchanged.
- Agent F's localization/UI-shell lane, Sorcerer payload, promotion/XP UI, permanent-death logic, thresholds, `scripts/verify.sh`, and final-art acceptance remain untouched.

## Release audit and human verdict

Corrected commit `91b427c` completed one fresh cache-bypassed clean-artifact `scripts/verify.sh --full` in 181.203 seconds: 78/78 rungs passed, 25/25 windowed scenario reports passed, 672 checks passed, zero shot/pixel/render skips occurred, and the 11-replay two-process output was byte-identical at SHA-256 `6930a9fe9ed861a1b783546c84ceaced2e0f934c48e3af5065406ae56c7b75d1`. A fresh non-implementer audit returned PASS with no critical findings, warnings, or pin breaks; it independently verified the verb fix and the D-WD-4 provenance-only migration.

Poseidon reviewed the exact corrected-candidate `mend_targeting.png` and `mend_effect.png` frames in-conversation on 2026-08-13 and replied: **“Approve mechanics and legibility; keep art placeholder, then merge.”** This closes the gameplay feel/legibility boundary while explicitly leaving both Witch Doctor visual assets `placeholder: true` for a later final-art lane.

The first latest-master union gate correctly went red at `test_campaign_state_p16`: P16.1 had landed an exact authored-environment fingerprint while TD-023 was in release review, and the eleventh operator plus S7 reward changed that manifest. The canonical manifest was recomputed from union bytes as SHA-256 `b0188079cc71f817bdc05383258a14238c5f65e3327b7bc7830ec548deaf5835`; `CampaignDef`, `p16_v1.tres`, and the two-process roster oracle were migrated together. A new exact test proves removing either the Witch Doctor catalog row or S7 reward rejects. No strategic save/hash/outcome golden was retuned unless the focused P16 suite independently required it.

After that focused seam passed, the restarted full GUT suite found one remaining P16 projection pin: debug-unlock expected the pre-healer catalog size 10. The test and live `model_roster_probe` now require exactly 11; the probe's authored-environment assertion migrated to the same canonical hash, while the new-campaign starter projection remains exactly 5 and the legacy campaign state remains byte-identical. No threshold or gameplay code changed.

The next restart passed all 230 tests but the separate integrity gate rejected 12/12 in `test_campaign_state_p16.gd` because P16 pins that suite to exactly 11/11. The new union assertion was moved intact into `test_witch_doctor.gd`; `scripts/verify.sh` and its exact P16 count remain unchanged. This preserves both the P16 evidence contract and the new catalog/reward differential.

The first clean-artifact full union run then reached the stale-class upgrade gate and went red: a cache derived from pre-class baseline `7babf28` could not resolve the new global `HealingRules` identifier. Both runtime consumers now preload `res://sim/healing_rules.gd` under a local alias before calling its static methods, exactly following the repository's cold-cache rule. The failed full run is red history; release assurance restarts from a new commit and clean artifact directory.

## Current evidence state

- Logic: green — 230-test latest-master union GUT suite, including exact Mend/clamp/reject/ordinal/hash/differential and P16 environment tests.
- Integration: green — stage lint, 11-template campaign/debug reachability, canonical semantic replay, cross-process replay equality.
- Visual: green machine evidence — `witch_doctor_heal` passes headless and windowed with 33 checks, 3 fresh shots, zero windowed pixel skips, and present/absent mint probes.
- Feel: green — Poseidon approved mechanics and legibility on the exact corrected-candidate frames on 2026-08-13.
- Final art: pending by design; both Witch Doctor asset entries remain placeholders.

All feature-level release requirements are satisfied. The only remaining integration requirement is a fresh exact-union full gate after this closure transaction, followed by fast-forward master integration and local/remote SHA confirmation.
