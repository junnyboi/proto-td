# Protos UI Implementation Gap Audit

**Status:** strict synthesis of six family audits  
**Scope:** approved eight-concept Protos UI implementation  
**Repository:** `/home/ubuntu/workspace/proto-td`  
**Decision basis:** material concept fidelity, authoritative behavior preservation, responsive/accessibility compliance, and available verification evidence

## Executive verdict

The implementation is **behaviorally strong, materially coherent, and suitable for a corrective fidelity pass rather than a redesign**. The six family scores average **70.3/100** (range: 64–81). No family audit failed. The shared Lunaris system, Mission Command, campaign routing, Premium Resonance transaction boundary, Vahalla semantics, Results payload authority, battle simulation boundary, tutorials, and 720×1280 adaptation are already credible.

The remaining gap is concentrated in a small number of high-value areas: **false or inert affordances, incomplete reduced-motion propagation, unsafe narrow dialogs and modal focus containment, inaccessible battle controls, a real landscape battle-deck collision, untranslated player-facing copy, and hierarchy weaknesses on Training, Resonance, Vahalla, and Results**. These can be corrected with existing native controls and canonical assets. **No new generated asset is required.**

> **Strict authority rule:** presentation may expose, reorganize, localize, or restyle authoritative projection data; it must not infer gameplay legality, stage order, rewards, economy, pity, promotion choices, casualties, persistence, or navigation state.

## Classification standard

| Classification | Meaning |
|---|---|
| **Implement now** | A bounded correction that materially improves concept fidelity, removes an authority/accessibility defect, and can preserve current model and route contracts. |
| **Already satisfied** | The approved native deviation or requirement has adequate source/test/capture evidence and should be protected rather than redesigned. |
| **Defer** | Requires new content authority, broad geometry replacement, speculative systems, generated identities, or lower-value framework migration. |

## Priority findings

| Priority | Classification | Strict recommendation | Material reason | Authority and regression gate |
|---|---|---|---|---|
| P0 | **Implement now** | Remove the production mock wallet and all purchase-like plus affordances. Retain a resource display only if its values come from an existing authoritative projection. | Company Command currently advertises fixed non-authoritative values as economy. | Do not add purchase, spending, persistence, or progression. Preserve Exit layout/focus and migrate node-dependent tests deliberately. |
| P0 | **Implement now** | Apply `accessibility/reduced_motion` to the Company Command backdrop **before playback can begin**. | Staging reads the preference but its video backdrop defaults to motion. | Preserve title settings, static-first fallback, looping behavior when enabled, and preference persistence. |
| P0 | **Implement now** | Make `LunarisDialogSheet` viewport-aware: landscape-centered, portrait/narrow bottom-attached, width-clamped, locally scrollable, and action-stacking when required. Add a true modal focus scope and reduced-motion-aware entry/exit. | The 520 px minimum plus margins overflows 540 px; centered portrait dialogs miss the approved command-sheet geometry; pointer blocking is not full keyboard/controller containment. | Preserve Cancel default, Confirm-only mutation, pending submit-once lock, `ui_cancel`, exact return focus, and battle-speed restoration. |
| P0 | **Implement now** | Separate the landscape spell and battle-command deck hit regions. | Both currently occupy the same top-right origin and visibly interpenetrate. | Reposition presentation only; preserve targeting, tutorial guides, map-pan suppression, terminal disablement, and spell input routing. |
| P0 | **Implement now** | Restore keyboard/controller access to Pause, Speed, Resign, and Recenter, with explicit focus neighbors and modal return focus. | These controls are intentionally `FOCUS_NONE`, contradicting the approved accessibility contract. | Prevent Space double-toggle; retain Space pause, R recenter, safe Cancel, exact speed restoration, and Confirm-only resign. |
| P0 | **Implement now** | Localize hard-coded gacha, battle, withdrawal, terminal, and remaining Results copy through typed `UiCopy`/I18n entries and live locale refresh where supported. | Catalog parity currently does not mean these surfaces are translated. | Localization formats model values only; it must not translate identifiers or recompute pity, Marks, rewards, battle state, or routes. |
| P1 | **Implement now** | Move Training's mode actions into a persistent shell-level dock outside `TrainingDialogScroll`. | The first-view captures omit part or all of the required action set. | Preserve existing button names, callbacks, enablement, retry exit lock, local scrolling, and portrait stacking. |
| P1 | **Implement now** | Recompose Training as selected-operator first: enlarge identity/portrait, demote naming to an edit disclosure, and show compact read-only legal-path previews. Replace oversized path-card lists with a compact selector plus one authoritative detail panel. | Training remains utility/form-first and five-choice promotion is an unverified, extremely long nested flow. | Preserve all legal path IDs and facts, 1/2/5 choice cardinality, draft restoration/replacement, stable hero identity, atomic submit, stale reconciliation, durable retry, and one-time acknowledgement. |
| P1 | **Implement now** | Recompose Premium Resonance's three canonical identities into one asymmetric banner stage while preserving the sole authoritative pull action and every per-identity state label. | The browsing state reads as an equal-card catalog rather than the approved featured trio. | Keep the three runtime identities, one 40-Mark pull, 5% rate, ten-pull hard pity, life/revival state, test handles, and first-view action. |
| P1 | **Implement now** | Promote Results `CLEAR`/`DEFEAT` to the dominant ceremony, tighten typed reward/consequence ledgers, and correct frame padding. | Correct payloads are visually subordinate to empty panels and edge collisions. | Preserve `Game.last_result` authority, separate local scroll regions, every route, conditional Training, and active-campaign `ui_cancel` behavior. |
| P1 | **Implement now** | Enlarge and structure Vahalla's selected memorial into portrait stage plus ruled service ledger using only current fields. | The low-scale selected portrait and compressed text stack fall short of the premium memorial hierarchy. | Preserve stable `hero_id` selection, filtering, visit-local Honor, permanent loss, and no invented dates, decorations, deployments, lives, or resurrection. |
| P1 | **Implement now** | Enrich the Stage Select dossier with existing localized objective/threat and resolved typed reward identity; show Marks only from an authoritative stage-relevant projection. | The dossier has unused space and reports only reward-record count. | Narrative cannot become a new gate; reward copy must distinguish first-clear/replay eligibility; locked rows remain nonfocusable/nonactivatable. |
| P1 | **Implement now** | Remove inert Messages chrome. Make Settings a real focusable route to the existing settings surface only if reuse preserves state; otherwise remove it too. | Decorative utility icons advertise unavailable actions. | A reused settings sheet must be modal, restore focus, update locale/motion immediately, and not alter music/session/campaign state. |
| P2 | **Implement now** | Replace player-facing battle `TICK` with authoritative wave progress when available, otherwise omit it; strengthen deployment-card portrait/state hierarchy and tighten the terminal stamp. | Debug information and weak card/terminal hierarchy reduce field-command readability. | Keep tick only in debug tooling; preserve deployment IDs, model-derived readiness, duplicate slots, terminal one-shot result recording, and Results separation. |
| P2 | **Implement now** | Normalize Company Command focus energy to moon-cyan, use existing primary/operation frames selectively, and simplify dense/quiet rows to restrained glass. | Gold focus conflicts with the semantic palette; repeated ornate frames flatten hierarchy. | Preserve visible non-color focus, disabled skipping, hit targets, content margins, CJK wrapping, and compact sizes. |
| P2 | **Implement now** | Close verification gaps before acceptance: Company Command states, Training transactional states, gacha reveals, narrow/CJK dialogs, battle overlap/controller paths, and portrait Slow Field. | Existing source tests are stronger than the retained visual/interaction evidence. | Fixtures must be presentation-only unless a test explicitly verifies one authoritative transaction, and teardown must restore `Game`, locale, audio, and campaign state. |

## Already-satisfied requirements to freeze

| Classification | Requirement already satisfied | Evidence and preservation instruction |
|---|---|---|
| **Already satisfied** | The Lunaris material system is coherent: near-black glass, antique-gold structure, ivory copy, cyan active/focus roles, Cinzel display type, CJK fallback, and native textured controls. | Protect [`aetheria_theme.gd`](../scripts/ui/components/aetheria_theme.gd), [`lunaris_ops_style.gd`](../scripts/ui/components/lunaris_ops_style.gd), and existing imported frame assets. Do not propagate the title-only 1.15 scale globally. |
| **Already satisfied** | Stage Select's native route+dossier is an approved substitute for a literal map. Sequential unlock, stars, recommendation, replay, order, and activation remain projection-owned. | Protect [`stage_select.gd`](../scripts/ui/stage_select.gd), locked-row disabled/focus exclusion, enabled-only `selected_stage_id` mutation, local route scrolling, and Company Command return behavior. |
| **Already satisfied** | Company Command's character-forward shell, authoritative next-operation logic, missing-narrative hard guard, campaign-complete replay access, disabled Barracks/Armory, eligible-count Training, and Resonance/Vahalla routes are correct. | Protect [`staging.gd`](../scripts/ui/staging.gd) route handlers and campaign projection boundaries. |
| **Already satisfied** | Mission Command has an operator-forward authoritative roster/intelligence composition and a genuine persistent Back/Training/Deploy dock. | Protect [`squad_select.gd`](../scripts/ui/squad_select.gd), selection cap, fallen exclusion, filters/search/sort, squad context, stage selection, and `Game.start_stage`. Mission's scaled shell remains an approved deviation. |
| **Already satisfied** | Training's transaction model is mature: validation, legal-path authority, draft/review, canonical ordering, atomic/idempotent dispatch, stale reconciliation, durable retry lock, and one-time acknowledgement. | Presentation refactors in [`training.gd`](../scripts/ui/training.gd) must reuse these controls/callbacks rather than reimplementing transaction logic. Success continues to Company Command by approved design. |
| **Already satisfied** | Premium Resonance's economy and transaction boundary are authoritative: one 40-Mark pull, 5% base five-star rate, ten-pull hard pity, three identities, Confirm-only mutation, Cancel invariance, input lock, Skip, and reduced-motion final settlement. | Protect [`gacha.gd`](../scripts/ui/gacha.gd), [`gacha_cinematic_player.gd`](../scripts/ui/components/gacha_cinematic_player.gd), and current economy tests. |
| **Already satisfied** | Vahalla is a stable-hero-id memorial with filtering, permanent loss semantics, and visit-local Honor—not resurrection or progression. | Protect [`vahalla.gd`](../scripts/ui/vahalla.gd) and its current non-mutating Honor behavior. |
| **Already satisfied** | Results projects outcome, stars, tally, typed rewards, narrative consequence, casualties, premium-life losses, XP, and destinations from `Game.last_result`. | Protect [`results.gd`](../scripts/ui/results.gd), its persistent action dock, and the asymmetric active-campaign `ui_cancel` route. |
| **Already satisfied** | Battle deployment, placement, spell legality, Slow Field behavior, pause/resign transaction, tutorials, terminal gating, and result recording remain model-owned and well tested. | Protect [`deploy_bar.gd`](../scripts/ui/deploy_bar.gd), [`spell_bar.gd`](../scripts/ui/spell_bar.gd), [`battle_controls.gd`](../scripts/ui/battle_controls.gd), and the battle model boundary. |
| **Already satisfied** | Battle and Results are correctly separate authoritative states; current BattleView geometry is an approved implementation-plan deviation. | Do not duplicate rewards/routes in the terminal stamp or replace the complete field layout with concept-only rails. |
| **Already satisfied** | Existing 1280×720 and 720×1280 evidence demonstrates broad containment and shared material consistency. | Treat the current captures as baselines, not sufficient final acceptance for 540×960, CJK, modal focus, or high-risk transactional states. |

## Deferred work and explicit non-goals

| Classification | Deferred item | Reason |
|---|---|---|
| **Defer** | A true authored connected campaign map, stage-specific key-art catalog, or semantic geography. | This requires separately approved content and map authority; a wide/two-axis map would also regress portrait one-axis flow. |
| **Defer** | New generated commander, operator, memorial, reward, or gacha identities. | Canonical portraits, final plates, videos, heraldry, frames, stars, icons, and native effects are sufficient for the corrective pass. Generated identities would conflict with runtime authority. |
| **Defer** | Literal reconstruction of the concept's battle rails or wholesale BattleView relayout. | Current pan, placement, targeting, tutorial, and safe-region behavior is frozen authority. Correct collisions and compact hierarchy only. |
| **Defer** | Recruit 10, 100/900-Mark prices, 3% rate, essence conversion, resource purchase, or any new economy. | These are illustrative concept values and directly conflict with the approved one-pull economy. |
| **Defer** | New faction selection, Barracks/Armory gameplay, Messages system, persisted Vahalla Honor, resurrection, or invented memorial ledger fields. | No authoritative gameplay or persistence exists for them. Remove false affordances instead. |
| **Defer** | Broad StateSigil migration across all screens. | A small native sigil can be introduced opportunistically for repeated lock/completion/warning/memory roles, but a system-wide migration has lower value and higher regression risk than the P0/P1 corrections. |
| **Defer** | Global automatic UI-audio binding. | Existing semantic cues work; naive centralization risks double playback or pre-acceptance sounds. Consider an opt-in helper only after a call-site audit. |
| **Defer** | Decorative atmosphere, additional animation, or ornamental polish not required to fix hierarchy/contrast. | First complete authority, accessibility, responsive, localization, and evidence gates. A subdued non-semantic Stage Select atmosphere may be considered afterward. |

## Phased correction plan

### Phase 0 — Safety and authority corrections

**Exit criteria:** no fabricated economy; no motion-policy leak; no 540×960 dialog overflow; modal input is contained; battle decks do not intersect; battle commands are controller reachable; audited player-facing strings translate.

| Workstream | Production files | Tests to modify or add | Required captures |
|---|---|---|---|
| Company Command authority and motion | [`scripts/ui/staging.gd`](../scripts/ui/staging.gd), [`scripts/ui/staging_mock_wallet.gd`](../scripts/ui/staging_mock_wallet.gd), [`scripts/ui/components/staging_resource_chip.gd`](../scripts/ui/components/staging_resource_chip.gd), [`scripts/ui/components/lunaris_animated_backdrop.gd`](../scripts/ui/components/lunaris_animated_backdrop.gd) | Extend [`tests/campaign_ui_layout_test.gd`](../tests/campaign_ui_layout_test.gd); add `tests/company_command_ui_test.gd` for fresh/complete/missing-narrative, operation availability, wallet absence/authority, reduced motion, focus order, both locales | Add `verification/phase2/company-command-landscape.webp`, `company-command-portrait.webp`, `company-command-reduced-motion.webp`, plus zh-CN narrow evidence |
| Responsive modal/focus scope | [`scripts/ui/components/lunaris_dialog_sheet.gd`](../scripts/ui/components/lunaris_dialog_sheet.gd), call sites in [`gacha.gd`](../scripts/ui/gacha.gd) and [`battle_controls.gd`](../scripts/ui/battle_controls.gd) | Extend [`tests/lunaris_ui_foundation_test.gd`](../tests/lunaris_ui_foundation_test.gd), [`tests/premium_gacha_ui_test.gd`](../tests/premium_gacha_ui_test.gd), and [`tests/battle_ui_layout_test.gd`](../tests/battle_ui_layout_test.gd) for 720×1280/540×960 bounds, all-direction focus containment, invalid return node, pending lock, reduced motion | Replace `phase2/gacha-confirm-portrait.webp` and `phase3/resign-portrait.webp`; add 540×960 en-US and zh-CN confirmation/resign captures |
| Battle deck/input correction | [`scripts/ui/spell_bar.gd`](../scripts/ui/spell_bar.gd), [`scripts/ui/battle_controls.gd`](../scripts/ui/battle_controls.gd), [`scripts/ui/map_navigation_overlay.gd`](../scripts/ui/map_navigation_overlay.gd) | Update [`tests/battle_ui_layout_test.gd`](../tests/battle_ui_layout_test.gd) to assert non-intersecting hit rects, click routing, focus neighbors, disabled skipping, mouse/keyboard/joypad parity, no Space double-toggle, modal return to Resign | Replace `phase3/live-landscape.webp`, `resign-landscape.webp`, `live-portrait.webp`, and `resign-portrait.webp` |
| Localization completion | [`scripts/ui/components/ui_copy.gd`](../scripts/ui/components/ui_copy.gd), [`localization/en-US.json`](../localization/en-US.json), [`localization/zh-CN.json`](../localization/zh-CN.json), [`scripts/ui/gacha.gd`](../scripts/ui/gacha.gd), [`scripts/view/battle_hud_presenter.gd`](../scripts/view/battle_hud_presenter.gd), [`scripts/ui/battle_controls.gd`](../scripts/ui/battle_controls.gd), [`scripts/ui/deploy_bar.gd`](../scripts/ui/deploy_bar.gd), [`scripts/ui/results.gd`](../scripts/ui/results.gd), [`scripts/view/battle_view.gd`](../scripts/view/battle_view.gd) | Extend [`tests/localization_ui_parity_test.gd`](../tests/localization_ui_parity_test.gd); add instantiated zh-CN confirmation, reveal, battle, and clear/defeat assertions to family tests | Add zh-CN 720×1280 and 540×960 captures for highest-risk dialog, battle, and Results states |

### Phase 1 — High-value concept hierarchy

**Exit criteria:** Training actions remain visible; all authoritative path cardinalities are usable; Resonance reads as one featured trio; Results reads as a ceremony; Vahalla reads as a memorial; Stage Select provides meaningful native briefing data.

| Workstream | Production files | Tests to modify or add | Required captures |
|---|---|---|---|
| Training dock, hero dossier, and path selector | [`scripts/ui/training.gd`](../scripts/ui/training.gd), [`scripts/ui/components/promotion_path_card.gd`](../scripts/ui/components/promotion_path_card.gd), optionally a new focused selector component under `scripts/ui/components/` | Extend [`tests/campaign_ui_layout_test.gd`](../tests/campaign_ui_layout_test.gd); add `tests/training_interaction_ui_test.gd` covering rename Cancel/Confirm/error, 1/2/5 paths, draft replacement, review single dispatch, stale reconciliation, retry-locked exits, all origins, Mission stage/squad continuity | Replace `phase2/training-landscape.webp` and `training-portrait.webp`; add rename modal, five-path selection, review, and retry captures in both orientations |
| Resonance banner | [`scripts/ui/gacha.gd`](../scripts/ui/gacha.gd) and existing canonical portrait/final-plate resources only | Extend [`tests/premium_gacha_ui_test.gd`](../tests/premium_gacha_ui_test.gd) to preserve all three identity states, stable handles or documented replacements, sole pull action, first-view containment | Replace gacha browsing/confirmation baselines; add four-star reveal, five-star/forced-pity reveal, and reduced-motion final plate in both orientations |
| Results ceremony | [`scripts/ui/results.gd`](../scripts/ui/results.gd), existing style helpers | Extend [`tests/results_ui_test.gd`](../tests/results_ui_test.gd) for clear/defeat hierarchy, zero/three stars, long typed ledgers, action dock and 540×960/CJK containment | Replace `phase2/results-landscape.webp` and `results-portrait.webp`; add clear and defeat narrow/CJK evidence |
| Vahalla memorial | [`scripts/ui/vahalla.gd`](../scripts/ui/vahalla.gd), existing canonical portrait resources | Extend [`tests/vahalla_ui_test.gd`](../tests/vahalla_ui_test.gd), [`tests/custom_naming_roster_test.gd`](../tests/custom_naming_roster_test.gd), and [`tests/faction_roster_filter_test.gd`](../tests/faction_roster_filter_test.gd) for stable selection, only-authoritative ledger fields, and portrait reachability | Replace `phase2/vahalla-landscape.webp` and `vahalla-portrait.webp` |
| Campaign dossier and utility cleanup | [`scripts/ui/stage_select.gd`](../scripts/ui/stage_select.gd), [`scripts/ui/staging.gd`](../scripts/ui/staging.gd), existing narrative/reward presenters, existing settings helper if safely reusable | Extend `tests/company_command_ui_test.gd` and [`tests/campaign_ui_layout_test.gd`](../tests/campaign_ui_layout_test.gd) for reward eligibility copy, locked-row invariance, Settings modal return, and removal of inert Messages | Replace `phase2/stage-select-landscape.webp` and `stage-select-portrait.webp`; refresh Company Command captures |

### Phase 2 — Field-command and material polish

**Exit criteria:** no debug HUD copy; operator state is explicit; terminal ceremony is compact and legible; cyan focus semantics and frame hierarchy are consistent; portrait Slow Field evidence exists.

| Workstream | Production files | Tests to modify or add | Required captures |
|---|---|---|---|
| HUD/operator/terminal hierarchy | [`scripts/view/battle_hud_presenter.gd`](../scripts/view/battle_hud_presenter.gd), [`scripts/ui/deploy_bar.gd`](../scripts/ui/deploy_bar.gd), [`scripts/view/battle_view.gd`](../scripts/view/battle_view.gd), existing canonical portrait mappings | Extend [`tests/battle_ui_layout_test.gd`](../tests/battle_ui_layout_test.gd) for authoritative wave display/absence, slot identity/readiness labels, terminal-only focus path and one-shot result handoff | Replace `phase3/live-*` and `terminal-*`; add Slow Field portrait capture at `verification/slow-field/slow-field-portrait.webp` |
| Shared focus/frame hierarchy | [`scripts/ui/components/staging_command_tile.gd`](../scripts/ui/components/staging_command_tile.gd), [`scripts/ui/components/staging_skin.gd`](../scripts/ui/components/staging_skin.gd), [`scripts/ui/components/lunaris_ops_style.gd`](../scripts/ui/components/lunaris_ops_style.gd), [`scripts/ui/components/aetheria_theme.gd`](../scripts/ui/components/aetheria_theme.gd) | Extend [`tests/lunaris_ui_foundation_test.gd`](../tests/lunaris_ui_foundation_test.gd) for cyan focus plus non-color cue; family layout tests retain targets/margins/wrapping | Refresh one dense landscape, one dense portrait, Company Command focused state, and one battle state |
| Responsive verification matrix | Test fixtures only unless a failure is found | Add `tests/ui_responsive_locale_matrix_test.gd`: 1280×720, compact landscape, 720×1280, 540×960 × en-US/zh-CN; assert global bounds, no horizontal scroll, visible primary actions, ≥44 px targets, focus reachability, disabled skipping | Retain the smallest/highest-risk matrix captures and update inspection notes |

## Acceptance gates

Every phase must satisfy all applicable gates below before visual sign-off.

| Gate | Required assertion |
|---|---|
| **Authority** | UI values are projection/model inputs; no presentation-owned unlock, reward, economy, promotion, death, pity, deployability, wave, or result calculation is introduced. |
| **Mutation boundary** | Gacha, rename, training, resign, deploy, and route mutations remain on their existing explicit authoritative action only; Cancel and inspection remain non-mutating. |
| **Navigation/persistence** | Staging/Stage Select/Mission/Training/Results routes, selected stage/squad continuity, one-time acknowledgement, active-campaign `ui_cancel`, and durable retry locks remain exact. |
| **Accessibility** | Native/localizable labels, CJK fallback, ≥44 px targets, visible focus, cyclic controller traversal, disabled skipping, modal containment/restoration, local focus scrolling, and reduced motion pass. |
| **Responsive** | No horizontal outer overflow at 1280×720, compact landscape, 720×1280, or 540×960; primary actions remain visible; portrait uses one-axis/local scrolling. |
| **Battle safety** | Control hit regions do not overlap; shortcuts do not double-fire; targeting/panning/tutorial suppression and terminal lockout remain unchanged. |
| **Visual hierarchy** | Gold remains structural, cyan communicates focus/selection/readiness, major frames outrank dense rows, and concept hierarchy improves without baking illustrative data. |
| **Evidence** | Automated state assertions and deterministic captures exist for the highest-risk transaction, narrow/CJK, reduced-motion, and controller states. |

Run focused SceneTree tests using the repository convention:

```bash
godot --headless --path . --script res://tests/<test_name>.gd
```

Before final acceptance, also run import/startup gates and the affected existing suites: `lunaris_ui_foundation_test.gd`, `campaign_ui_layout_test.gd`, `custom_naming_roster_test.gd`, `faction_roster_filter_test.gd`, `premium_gacha_ui_test.gd`, `premium_gacha_pity_economy_test.gd`, `gacha_cinematic_resources_test.gd`, `vahalla_ui_test.gd`, `results_ui_test.gd`, `battle_ui_layout_test.gd`, `slow_field_spell_test.gd`, `slow_field_tutorial_ui_test.gd`, `localization_ui_parity_test.gd`, and `ui_audio_direction_test.gd`.

## Final decision

Proceed with **Phases 0–2 in order**. Phase 0 is release-blocking because it contains false economy presentation, motion-policy leakage, narrow-dialog overflow, incomplete modal containment, battle hit-region collision, controller exclusion, and untranslated player-facing surfaces. Phase 1 provides the largest concept-fidelity gain without changing authority. Phase 2 should be accepted only after the behavioral and responsive gates are stable.

Do **not** commission new art or reopen gameplay/economy/navigation design for this pass. The repository already contains sufficient canonical art, cinematic plates, video, frames, seals, stars, icons, portraits, and native controls to deliver the approved corrections.

**Failed family audits:** none.

## Implementation closure

The approved pass completed the release-blocking Phase 0 and the material hierarchy work from Phase 1 without introducing new gameplay authority. Shared dialogs now own responsive sheet geometry, local scrolling, focus lifecycle, veil dominance, and reduced-motion-aware entry. Company Command no longer presents fabricated economy or inert utility chrome. Campaign, Training, Premium Resonance, Vahalla, Results, and battle command surfaces now match the approved information hierarchy materially more closely while preserving every existing route, command, receipt, and model projection.

| Closure gate | Evidence |
|---|---|
| Authority and mutation boundaries | Expanded campaign, gacha, Vahalla, Results, battle, and modal regressions pass; Confirm-only mutations and Cancel invariance remain asserted. |
| Responsive/accessibility | Narrow 540×960 sheet bounds/action stacking, 720×1280 bottom sheets, persistent Training actions, battle deck separation, focusable commands, and safe focus restoration are covered and visually verified. |
| Localization | English and Simplified Chinese catalogs contain 470 parity-checked keys with typed placeholders for the added surfaces. |
| Native validation | Godot 4.7.2 import, bounded boot, and all 29 current repository tests pass. |
| Visual evidence | Twelve non-battle and eight battle captures pass at 1280×720 and 720×1280; logs scan clean. |

The implementation is accepted for Web export and deployment. Detailed evidence is recorded in [`ApprovedUnifiedUIImplementationCompletion.md`](ApprovedUnifiedUIImplementationCompletion.md) and [`verification/approved-phase0/inspection-notes.md`](ui-concepts/ui-revamp/verification/approved-phase0/inspection-notes.md).
