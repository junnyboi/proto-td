# TD-021 — Witch Doctor deterministic healing

**Owner:** AGENT 2

**Branch:** `agent-2/td-021-witch-doctor`

**Base:** `f84810578303d6599b4e5de89c407f9747d3812d`

**Implementation candidate:** pending commit freeze

## Outcome

TD-021 adds `witch_doctor_1` as an eleventh, separate advanced Mage template. It does not rename, alias, or retune `caster_2` Sorcerer. Witch Doctor is an elevated, rarity-3, 18-DP support unit with 110 HP, zero attack, and the data-owned `mend` skill.

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

## Plan deviations and boundaries

- D-WD-1 exercised: Mend validation/mutation was extracted to pure `sim/healing_rules.gd` because `BattleModel` was at its public-method cap. The dispatcher remains the sole mutation entry and the UI calls the same pure validator.
- `BattleView` color constants moved to immutable `scripts/view/battle_palette.gd` to remain under the 1,000-line lint cap; no presentation value changed except the additive healer color.
- Replay runner expectation objects are additive; every legacy boolean array and existing replay fixture byte remains unchanged.
- Agent F's localization/UI-shell lane, Sorcerer payload, promotion/XP UI, permanent-death logic, thresholds, `scripts/verify.sh`, and final-art acceptance remain untouched.

## Current evidence state

- Logic: green — 203-test full GUT suite, exact Mend/clamp/reject/ordinal/hash/differential tests.
- Integration: green — stage lint, 11-template campaign/debug reachability, canonical semantic replay, cross-process replay equality.
- Visual: green machine evidence — `witch_doctor_heal` passes headless and windowed with 33 checks, 3 fresh shots, zero windowed pixel skips, and present/absent mint probes.
- Feel: pending Poseidon review of exact-candidate targeting and effect frames.
- Final art: pending by design; both Witch Doctor asset entries remain placeholders.

The branch is not eligible for autonomous master merge until a frozen candidate passes one fresh clean-artifact `scripts/verify.sh --full`, an independent non-implementer diff-vs-pins audit, and Poseidon's required player-facing visual verdict.
