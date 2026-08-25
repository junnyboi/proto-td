# UI Revamp Audit 02 — Campaign Map, Mission Squad Selection, Deploy Flow, and Results

**Audit family:** Campaign map, mission squad selection, and results  
**Repository revision:** `6f382b621c812c29dacfa79a41fe59e19909709c`  
**Target viewports:** `1280×720` landscape and `720×1280` portrait  
**Visual benchmark:** premium, clearly adult (21+), non-explicit anime-gacha presentation led by the Lunaris Reliquary art direction

## Executive assessment

This family contains a sound, data-driven campaign flow with unusually strong deterministic and persistence boundaries. Stage availability, squad legality, battle tickets, outcomes, rewards, deaths, premium lives, and training eligibility are projections of authoritative state rather than UI-owned facts. Those contracts must remain untouched.

Presentation quality is uneven. **Mission Command is already the reference-quality member of the family**: it uses character-forward portrait cards, a full-viewport Lunaris backdrop, operational hierarchy, mission narrative, a tactical inspector, roster filters, and a persistent three-action deploy dock. Company Command is similarly bespoke and premium. By comparison, **Stage Select and Results still resolve to generic centered Aetheria reading plates**, with little visual storytelling, no meaningful campaign geography, weak reward ceremony, and minimal character presence. The terminal battle stamp, Continue control, deployment slot bar, retreat chip, and resign confirmation also remain utilitarian native controls. Moving through the flow therefore produces a visible quality cliff: bespoke ceremonial Company Command → plain stage list → premium Mission Command → workmanlike battle overlays → plain results dialog.

The recommended revamp should treat the family as one continuous **Lunaris expedition ritual**. Company Command establishes the operation, a full-bleed celestial campaign route selects it, Mission Command assembles adult operators, battle overlays use the same engraved material language, and Results resolves into either a celebratory reliquary debrief or a sober recovery report. The redesign must remain a view layer over `Game`, campaign projections, `BattleModel`, and the existing action validators.

## Sources reviewed

| Area | Source files |
|---|---|
| Project and visual authority | `project.godot`; `README.md`; `docs/ART_DIRECTION.md` |
| Approved UI concepts | `docs/ui-concepts/MISSION_TRAINING_GACHA_UI.md`; `docs/ui-concepts/LUNARIS_ENTRY_REDESIGN.md`; `docs/ui-concepts/STAGING_CONCEPT_FIDELITY_PLAN.md`; `docs/ui-concepts/ui-revamp/reference-findings.md`; `docs/ui-concepts/assets/GPT Image 2 - Mission Command.webp` |
| Campaign navigation | `scenes/staging.tscn`; `scripts/ui/staging.gd`; `scenes/stage_select.tscn`; `scripts/ui/stage_select.gd`; `autoloads/game.gd` |
| Mission briefing and squad selection | `scenes/squad_select.tscn`; `scripts/ui/squad_select.gd`; `scripts/ui/components/roster_filter.gd`; `scripts/ui/components/roster_filter_bar.gd`; `scripts/ui/components/training_support.gd` |
| Battle deploy and related dialogs | `scenes/battle.tscn`; `scripts/view/battle_view.gd`; `scripts/ui/deploy_bar.gd`; `scripts/ui/battle_controls.gd`; `scripts/ui/map_navigation_overlay.gd`; `scripts/view/map_navigator.gd` |
| Results | `scenes/results.tscn`; `scripts/ui/results.gd`; `autoloads/game.gd` |
| Shared UI system | `scenes/ui/components/aetheria_screen_shell.tscn`; `scripts/ui/components/aetheria_screen_shell.gd`; `scripts/ui/components/aetheria_theme.gd`; `scripts/ui/components/aetheria_button.gd`; `scripts/ui/components/aetheria_label.gd`; `scripts/ui/components/lunaris_ops_style.gd`; `scripts/ui/components/faction_heraldry.gd`; `scripts/ui/components/ui_copy.gd`; `data/presentation/ui/threshold_theme.tres` |
| Content shown by this family | `data/stages/s1.tres` through `data/stages/s8.tres`; `data/presentation/narrative/stage_narrative_catalog.tres`; `data/presentation/narrative/stages/s1.tres` through `s8.tres`; operator, trap, spell, and class resources loaded by the screens |
| Existing tests | `test/map_navigation_overlay_smoke.gd`; `test/map_navigator_orientation_smoke.gd`; `test/stage_orientation_smoke.gd`; `test/stage_redesign_smoke.gd`; `test/placement_feedback_smoke.gd`; `test/agent4_isometric_renderer_smoke.gd`; `tests/custom_naming_roster_test.gd`; `tests/faction_roster_filter_test.gd`; `tests/premium_hero_system_test.gd` |

## Screen and interaction inventory

### 1. Company Command campaign entry

`scenes/staging.tscn` is a code-built campaign home. It presents the animated Lunaris background, command navbar, campaign status and milestones, next-operation preview, faction standards, operation tiles, and Exit. The **Mission Control** action is disabled when the next stage narrative record is missing and otherwise calls `Game.open_stage_select()`. `ui_cancel` and Exit call `Game.open_title()`.

This screen is adjacent to rather than wholly inside the requested family, but it is the source and destination of campaign navigation and therefore defines the visual continuity contract. Its desktop/portrait split, top-aligned character art, cut-metal frames, Cinzel display hierarchy, gold/cyan accents, and staged command deck are the quality bar that Stage Select and Results currently fail to sustain.

### 2. Stage selection / campaign map

`scenes/stage_select.tscn` contains only a root `Control`; `scripts/ui/stage_select.gd` builds the screen. The resulting `CampaignShell` is a centered `900×620` Aetheria reading plate with:

- a faction symbol and localized Campaign heading;
- a centered next-stage hint;
- one stage button per `Game.campaign_stage_ids()` entry;
- a two-column stage list in landscape and one column in portrait;
- a locked disabled state for unavailable stages;
- ASCII star repetition for cleared stages;
- Back to Staging in the header;
- wraparound focus among unlocked stages and Back;
- `ui_cancel` parity with Back.

Pressing an unlocked stage writes `Game.selected_stage_id` and calls `Game.open_squad_select()`. Unlocking is sequential: the first stage is available and later stages unlock when the immediately preceding stage has a star record. The eight current stages are First Stand, Tempo, The Choke, Air Raid, High Ground, Turncoat, Full Kit, and The Gatecrasher, with squad limits increasing from three to six.

Despite its route role, this is **not presently a campaign map**. It is a functional list of rectangular buttons with index, title, lock suffix, and asterisks. There is no act identity, route line, mission thumbnail, environmental geography, threat preview, objective, reward preview, replay state, or visual distinction between latest operation and cleared replay.

### 3. Mission briefing and squad selection

`scenes/squad_select.tscn` is also a root-only scene populated by `scripts/ui/squad_select.gd`. This is the strongest implementation in scope. Its `MissionCommandShell` uses the canonical loading artwork as a subdued full-screen backdrop and a near-full-viewport reading surface (`1210×660` regular landscape, `920×680` compact landscape, `680×1180` portrait).

The screen contains:

- mission index/title and squad limit;
- mission intelligence for objective, threat, human reason, clue, tactical hint, and unlocked loadout;
- a campaign roster built from both ready and fallen heroes;
- Active/Fallen and faction filtering through `RosterFilterBar`;
- name/title search and recruitment/name sort;
- empty and shown/total states;
- custom callsign, custom title, recruitment index, class, DP, portrait, premium status, and premium lives;
- disabled fallen cards labeled `FALLEN • VAHALLA`;
- toggle selection up to `StageDef.squad_size`;
- prefill from `Game.selected_squad` when returning from Training or retrying;
- selected count and selected callsign line;
- Back, Train Operators, and Deploy Squad actions;
- local roster and intelligence scrolling;
- keyboard focus cycling and `ui_cancel` back navigation.

Deploy is disabled when no hero is selected or the stage narrative is unavailable. Back preserves campaign state and returns to Stage Select. Training opens through `Game.training_call(&"open", &"mission")`; leaving Training returns to Mission and the prefill restores selected squad continuity. Deploy calls `Game.start_stage(_stage.id, _picked)`.

### 4. Campaign launch / deploy transition

`Game.start_stage()` is a critical transactional boundary. In campaign mode it does not merely swap scenes: it issues `campaign.begin_attempt`, durably commits through `CampaignRuntimeAuthority`, and publishes `selected_stage_id`, `selected_squad`, the battle ticket, and active-attempt state **only after acceptance**. The battle scene is queued only after commit. Pending attempts are restored on campaign load and resumed directly.

The current Mission button offers no pending/commit feedback and ignores the returned result. A commit rejection can therefore leave the player on Mission Command without an explicit reason or recovery action. The revamp should add a view-only launch state and error sheet while preserving the exact transactional ordering.

### 5. In-battle deployment bar

`DeployBar` is the tactical continuation of squad selection. It projects ticket squad rows into operator slots and unlocked traps into trap slots. Slot labels expose operator identity index, DP cost, and icon. Enabled state reads `model.is_deployable()` / `model.is_trap_placeable()` every frame; cell highlights read `model.can_deploy_at()` / `model.can_place_trap_at()` rather than duplicating legality.

Interactions are:

- press/drag an operator slot to start placement;
- green valid and red invalid cell feedback;
- release on invalid cell to reject and cancel;
- release an operator on a valid cell to open a four-direction facing chooser;
- confirm a facing to issue `apply_action([&"deploy", ...])`;
- press/drag a trap; valid trap cells use amber and a valid release places immediately without facing;
- right-click or `ui_cancel` cancels placement;
- click a deployed unit to select it and show a selection ring;
- trigger a ready skill, enter targeted healing, or expose a Retreat chip when the skill is not ready;
- click Retreat to issue the authoritative retreat action;
- relayout highlights, slot grid, facing cluster, and selection ring with viewport/grid scale changes.

At widths below 1200, slots use two columns; portrait uses one column and pins the resulting potentially tall stack to the lower-left. Facing controls clamp inside top and bottom safety bounds. These behaviors are semantically careful but visually disconnected from Mission Command: plain buttons, generic labels, solid highlight colors, and a plain Retreat chip do not communicate premium operator identity.

### 6. Map navigation overlay

`MapNavigationOverlay` appears only when a battlefield can pan. It provides a first-use portrait hint, a Center button, persisted hint completion, a seven-second hint lifetime, R shortcut, and interaction gating. Portrait battlefield navigation uses exact height-fill scale, starts at the base side, permits horizontal panning and bounded rubber-band overscroll, suppresses the deployment click after drag, and can recenter. Landscape leaves primary touch available for deployment.

This belongs to campaign navigation only in the broad continuity sense: it is a battlefield navigation overlay, not the Stage Select map. It nevertheless competes spatially with deployment controls at `720×1280` and must be included in responsive validation.

### 7. Battle pause, resign, and terminal transition

`BattleControls` provides Pause, speed cycling, and Resign. Resign opens a centered code-built confirmation stating that resignation counts as defeat, pauses battle while open, restores the prior speed on cancel, and sends only `model.apply_action([&"resign"])` on confirmation.

When `BattleModel.result` becomes terminal, `BattleView` first calls `Game.record_result()`. Only after acceptance does it show a CLEAR/DEFEAT stamp, play victory/defeat SFX, and create a centered Continue button. There is intentionally no automatic scene change. Continue, and terminal keyboard activation through focus, calls `Game.open_results()`.

### 8. Victory / defeat / results

`scenes/results.tscn` is root-only and `scripts/ui/results.gd` creates a `900×600` landscape or `640×900` portrait centered Aetheria plate. It projects `Game.last_result` into:

- localized CLEAR or DEFEAT headline;
- star row on clear only;
- kills and leaks;
- unlocked operators, traps, and spells;
- Marks currency reward treatment;
- newly granted class entitlements;
- premium life losses and lockout messaging;
- clear- or defeat-specific narrative consequence;
- training eligibility notice and Train Recruits action;
- Retry, Return to Staging, and Back to Title routes.

Retry calls `Game.open_squad_select()` and therefore retains selected stage and selected squad. Training opens with return path `results`; leaving Training reconstructs Results from unchanged `Game.last_result`. Return to Staging preserves campaign state. Back to Title clears active campaign, current battle, selection, result, pending mutations, and training state. `ui_cancel` always takes the destructive Back-to-Title route, even during an active campaign.

## Feature contracts that must survive

| Contract | Preservation requirement |
|---|---|
| Campaign authority | UI remains a projection of `CampaignStateV3`/runtime projection. Do not move stage unlock, star, roster, life, reward, XP, or entitlement truth into controls. |
| Sequential stage unlocking | Locked missions remain visible but disabled; stage `n` unlocks only when stage `n-1` has a star entry. |
| Stable stage routing | Selecting an enabled stage sets `Game.selected_stage_id`; Back returns to Staging; `ui_cancel` matches visible Back behavior. |
| Durable begin-attempt transaction | `Game.start_stage()` must commit the campaign begin command before publishing battle selection or opening Battle. Rejected commits must never fake launch success. |
| Pending-attempt recovery | A valid durable pending attempt resumes Battle and uses its trusted ticket hash and squad rows. |
| Mission narrative gate | Missing narrative keeps deployment disabled and presents a recoverable mission-record error; no fabricated fallback objective may authorize deployment. |
| Squad selection legality | At least one ready hero is required; selection may not exceed `StageDef.squad_size`; fallen heroes remain non-selectable. |
| Squad continuity | Previously selected hero IDs prefill on retry and on returning from Training, subject to current readiness and limit. |
| Hero identity | Custom callsign/title, recruitment index, class, DP, portrait, premium identity/lives, faction, and fallen state remain visible and tied to stable `hero_id`. |
| Roster discovery | Active/Fallen and faction filters, name/title search, recruitment/name sort, shown/total count, and empty state survive the visual rewrite. |
| Training continuity | Mission → Training → Mission and Results → Training → Results retain their existing return paths and source-screen state. |
| Loadout disclosure | Unlocked traps and spells shown in Mission remain derived from campaign projection; direct battle catalogs remain separate. |
| Deploy legality | Slot enabled states continue to read model deployability; valid-cell visuals continue to read model validators; no UI duplicate of placement rules. |
| Placement verbs | Operators require facing after a valid drop; traps place on valid release without facing; invalid releases reject; cancel clears drag, chooser, and highlights. |
| Map gesture arbitration | Portrait map drag must suppress the following deployment click; landscape touch must remain available for deployment; recenter and persisted first-use hint remain functional. |
| Unit interaction | Selection ring, ready-skill activation, targeted healing, retreat visibility, and authoritative retreat/mend actions survive component restyling. |
| Resign semantics | Confirmed resign is an authoritative defeat action; opening confirm pauses; cancel restores prior speed; confirmation does not bypass model resolution. |
| Result acceptance boundary | Terminal UI and Results become available only after `Game.record_result()` accepts the canonical model outcome. |
| Result completeness | Result, stars, kills, leaks, all reward kinds, Marks, class entitlements, premium life loss/lockout, and narrative consequence remain represented. |
| Results routing | Retry returns to the same mission selection; Return to Staging keeps campaign; Training returns to Results; Back to Title deliberately clears campaign runtime state. |
| Input/accessibility | Existing keyboard/controller focus cycles, minimum 44px targets, tooltips/logical button text, `ui_cancel`, R recenter, Space pause, and localization remain operable. |

## Visual and experience gaps

### Family-wide inconsistency

The family mixes three visual systems: bespoke staging frames and Cinzel typography, Mission Command’s flat-but-coherent `LunarisOpsStyle`, and the older rounded Aetheria reading dialog. Colors overlap, but geometry, density, backdrop behavior, typography, state treatment, and ornament do not. The player repeatedly leaves the premium title identity for a generic utility panel and then returns to it.

Aetheria’s `12px` reading-panel corners, broad `40px` padding, flat slate background, centered geometry, and bright flat button fills read as an accessible prototype shell rather than the approved fashion-editorial, ceremonial science-fantasy system. Mission’s tighter four-pixel corners and character cards are directionally correct but still use mostly `StyleBoxFlat` surfaces rather than the staging frame assets.

### Stage Select

Stage Select is the largest gap. A campaign described through sacred mechanisms, ruined causeways, evacuation routes, and a Deep Gate is represented by eight text rows. ASCII asterisks, textual `LOCKED`, uniform card size, and a generic Campaign heading supply state but no progression fantasy. Cleared, recommended, replayable, locked, and campaign-complete states are not visually differentiated beyond enablement and text suffixes. The “next” hint is centered in the header yet carries no explicit label or route connection.

The list also wastes the opportunity to preview the exact data already available: stage title/index, narrative objective/threat, squad limit, hints, rewards, completion stars, and next-stage status. The faction symbol is decorative but not integrated into a route legend or act identity. The full screen lacks adult hero art entirely, weakening the 21+ premium character promise between Company Command and Mission Command.

### Mission Command

Mission Command meets the approved composition more closely than any other scoped screen, but several inconsistencies remain. The header’s index text is hard-coded as `MISSION 01 / OLD CUT`, so every selected stage can display the wrong mission index and landmark. `RELIQUARY THREAT` is also a fixed generic label rather than stage-derived threat classification. Much of the screen copy—section labels, action labels, readiness copy, premium-life strings, `NOTHING UNLOCKED`, and card status—is not routed through localization.

The roster exposes fallen soldiers through a filter while also disabling them, which is truthful, but a dead card uses the same portrait-card chassis and only text to communicate memorial status. Selection states are cyan borders but do not clearly present ordered field-team slots. The right panel shows selected names as one text line rather than portrait chips or role balance. No explicit launch progress/error response exists for durable begin-attempt failure.

### Deployment and battle overlays

The slot bar is a set of default Godot buttons with mixed icon assets and long labels. It has no operator rarity, faction, current DP availability emphasis, redeploy state, or selected-drag treatment beyond disabled state. Valid overlays use generic translucent green, trap amber, heal green, and invalid red; these are legible but not integrated with Lunaris sacred geometry. Green and red alone are insufficient for color-vision robustness.

The four facing arrows are attractive bespoke assets and preserve excellent interaction geometry, but they float without a concise “Choose facing” context or preview of attack direction. Retreat is a plain button and can appear near the map with little visual hierarchy. Map Center and the pan hint use older Aetheria styling. The resign dialog is a bare panel with plain native controls and no focus ownership; every battle-control button intentionally uses `FOCUS_NONE`, which avoids Space conflicts but weakens controller accessibility for the confirmation itself.

The CLEAR/DEFEAT stamp and Continue button are mechanically clear yet visually detached from Results. The transition repeats outcome presentation rather than forming one authored sequence.

### Results

Results is information-complete but emotionally flat. CLEAR and DEFEAT share the same centered plate, alignment, and structure. Stars are ASCII asterisks. Rewards are appended as undifferentiated text lines, with only Marks receiving a stronger heading. No reward icon, operator portrait, class seal, item art, stage identity, squad survivors, fallen roster, XP distribution, “new best,” or next-operation preview is shown. Premium life loss uses raw premium ID capitalization rather than canonical hero identity and lacks a portrait or gravity appropriate to a paid high-rarity resource.

The action hierarchy is inconsistent. Training availability changes the number of landscape columns and can make Return to Staging secondary. Retry is offered for both victory and defeat, but there is no semantic label difference such as Replay versus Retry. `ui_cancel` routes directly to Back to Title, the most destructive navigation option in the group; this conflicts with the usual visible-return convention used elsewhere and creates an accidental campaign-abandon risk.

### Adult-premium character promise

The art-direction requirement is not merely a content restriction; it is the product’s visual thesis. Mission Command supports it by centering visibly adult operator portraits. Stage Select and Results do not. The family should include adult hero presence without turning every screen into a pin-up: a cropped 21+ command lead or selected squad silhouette on Stage Select, and surviving/affected operator portraits in Results. Crops must prioritize face, hair, upper costume, weapon/accessory, mature expression, and faction identity, avoiding incidental cleavage crops or ambiguous-age chibi treatment.

## Design recommendations

### Unify the family under an Expedition Command shell

Create a reusable **Expedition Command** visual layer rather than reusing the generic centered reading plate unchanged. It should combine the staging asset kit and Mission’s responsive structure:

- top-aligned Lunaris animated/fallback background where character-safe;
- near-black/navy glass with staging nine-patch engraved frames;
- `0–6px` clipped corners, fine antique-gold rules, and sparse cyan state energy;
- Cinzel for Latin display/operation labels with the existing CJK fallback policy;
- native text and icons over scalable frames, never baked labels;
- full or nearly full safe viewport composition;
- one persistent, safe-area-aware action dock;
- local scrolling for route, roster, and detail regions rather than one giant outer document;
- gold for structure and unlocked progression, cyan for focus/selection/primary state, violet for memory/lore, desaturated steel for locked content, and restrained crimson for defeat/destructive states.

Do not force every screen into an identical template. Stage Select should feel spatial, Mission should feel character-forward and tactical, and Results should feel ceremonial, but material, type, motion, iconography, and control states should be recognizable as one system.

### Replace the stage list with a celestial route map

Build a native **Act I Reliquary Route** with eight ordered mission nodes connected by a celestial/ruined-causeway line. A wide layout should reserve approximately two-thirds for the route and one-third for a selected mission dossier. Portrait should use a vertically scrolling route with a bottom-attached or inline selected dossier; it must not scale down a wide map.

Each node should expose:

- mission index and localized title;
- locked, available, recommended-next, cleared, and replay states;
- zero-to-three actual resonance-star icons rather than text asterisks;
- faction/mission glyph and optional environment thumbnail;
- a clear route connection to prerequisite and next mission;
- focus, hover, press, and disabled treatments that do not rely only on color.

Selecting/focusing a node should update a dossier with objective, threat, squad limit, tactical hint, first-clear reward preview, completion record, and a `BRIEF SQUAD` primary action. Locked nodes should remain inspectable enough to explain the prerequisite but must not call the stage route. The recommended next mission should be called out with restrained orbital motion that respects reduced motion. Campaign complete should replace “next” emphasis with a completion seal and allow replay.

Use existing `data/stages/*.tres` and narrative records; do not introduce UI-owned copies. A selected adult Lunaris commander crop can anchor the dossier edge, with composition chosen to keep faces clear of text.

### Refine Mission Command rather than replace it

Preserve the accepted two-column/stacked architecture. Correct mission identity by deriving the eyebrow from `_stage.campaign_index` and stage-specific narrative/location data instead of hard-coded `MISSION 01 / OLD CUT`. Localize all operational labels and status strings.

Upgrade operator cards into reusable **Deployment Operator Cards** with portrait, callsign/title, class/faction seal, DP badge, premium-life pips where applicable, and explicit selected slot numbering. The selected squad should also appear as compact ordered portrait chips in the inspector, making capacity and removal understandable without scanning the roster. Fallen cards should use a distinct memorial veil, Vahalla glyph, and disabled semantics while retaining identity.

Retain every filter and sort control but collapse them into a compact filter drawer or two-row toolbar in portrait. Add a small clear-all selection action when at least one hero is selected. Deploy should show a short committing state, ignore duplicate activation, and surface an authoritative rejection in a Lunaris error sheet with Retry/Back choices. It must never optimistically enter Battle.

### Restyle deploy flow as tactical reliquary instrumentation

Create a responsive **Deployment Dock** component that preserves every existing verb seam. Each squad slot should show a compact portrait/role silhouette, callsign or stable short identity, DP cost, and deployability/redeploy state. Use the staging frame assets at battle-HUD density rather than plain buttons. Traps should occupy a visually distinct tactical-assets group. Disabled styling should retain readable cost and explain the reason in tooltip/accessibility text when available.

Replace solid color-only placement overlays with patterned sacred-geometry diamonds: cyan/gold line + fill for operator-valid, amber chevron for trap-valid, moon-green cross motif for heal-valid, and crimson hatch/X for invalid. Keep current colors as redundant cues, not sole cues. Add a compact “DRAG TO POSITION / RELEASE TO AIM” hint on first use and “CHOOSE FACING” around the arrow cluster. Reduced motion should stop arrow bounce/pulse while keeping emphasis state.

Restyle Retreat, Center, pan hint, pause/speed/resign strip, and resign confirmation through a single battle-overlay skin. The resign sheet should claim modal focus, expose controller-accessible Confirm/Cancel, restore prior focus on cancel, and retain the existing Space/pause safety behavior.

### Join terminal stamp and Results into one debrief sequence

Keep the manual Continue contract, but visually treat the stamp as the opening beat of the debrief. CLEAR can use a restrained gold/cyan resonance sweep and stars; DEFEAT should use violet/crimson memory-fracture treatment without punitive gore or shame. Reduced motion should use a static seal.

Results should use distinct but structurally related states:

- **Victory / Mission Clear:** stage key art or environment, stage title, star result, operational tally, reward reveal cards, class/promotion readiness, and clear consequence.
- **Defeat / Withdrawal Report:** stage title, failure reason category where authoritative data permits, leaks/kills, premium lives spent, fallen impact, defeat consequence, and a primary Retry action.

Reward cards should use actual resource icons or portraits and differentiate operator, trap, spell, class entitlement, and Marks. Premium-life loss should resolve canonical hero identity and portrait, with lockout treated as a serious recovery state. When XP awards are present, show compact per-operator progress without changing the reward model. Keep long reward sets inside an internal scroll region while the action dock remains visible.

Use **Replay Mission** after a clear and **Retry Mission** after defeat while preserving the same route. Make Return to Company Command the safe default and make Back to Title a tertiary explicit Exit action. `ui_cancel` during an active campaign should return to Staging or open an exit confirmation; it should not silently clear campaign runtime state.

## Proposed component changes and implementation targets

| Target | Proposed responsibility |
|---|---|
| `scripts/ui/stage_select.gd` | Replace button list with route-node projection, selected mission dossier, reward preview, correct focus graph, and responsive wide/vertical compositions. Preserve `Game` routes and unlock checks. |
| `scenes/stage_select.tscn` | Remain a thin root or gain named native layout anchors; do not embed gameplay data. |
| New `scripts/ui/components/campaign_route_node.gd` | Render locked/available/next/cleared/replay states, real star icons, mission glyph, focus, tooltip, and accessible logical text. |
| New `scripts/ui/components/mission_dossier.gd` | Bind stage and narrative resources into objective, threat, squad limit, hint, reward preview, and Brief action. |
| New `scripts/ui/components/expedition_shell.gd` or extension of staging skin | Share backdrop, typography, engraved frames, safe area, reduced-motion response, and dock geometry across Stage Select and Results. Avoid broad behavioral changes to `AetheriaScreenShell`. |
| `scripts/ui/squad_select.gd` | Replace hard-coded mission identity, localize labels, add ordered selected chips and launch pending/error presentation while preserving roster and selection behavior. |
| New `scripts/ui/components/deployment_operator_card.gd` | Consolidate portrait, identity, class/faction, DP, premium life, fallen, selected-order, focus, and disabled states currently built inline. |
| `scripts/ui/deploy_bar.gd` | Swap visual construction for Deployment Dock/cards and patterned overlay renderer; do not change validator or `apply_action` calls. Add reduced-motion visual handling. |
| New `scripts/ui/components/deployment_dock.gd` / `placement_overlay_style.gd` | Own responsive dock grouping and non-color-only placement motifs without owning legality. |
| `scripts/ui/map_navigation_overlay.gd` | Adopt battle overlay skin, safe-area collision rules, and reduced-motion pulse behavior while preserving hint persistence and recenter API. |
| `scripts/ui/battle_controls.gd` | Restyle control strip and resign modal; add modal focus capture/restore and controller navigation without changing pause/speed/resign semantics. |
| `scripts/view/battle_view.gd` | Replace only terminal stamp/Continue presentation and relayout anchor. Preserve `record_result()` acceptance boundary and manual Continue. |
| `scripts/ui/results.gd` | Introduce outcome-specific composition, typed reward cards, hero identity resolution, XP/premium-loss presentation, safe default route, and fixed action dock. Keep `Game.last_result` as sole source. |
| New `scripts/ui/components/result_reward_card.gd` | Render operator/trap/spell/currency/class reward types with accessible text and icon/portrait. |
| New `scripts/ui/components/result_operator_row.gd` | Render XP, fallen state, or premium-life effects from existing resolution fields without inferring simulation truth. |
| `scripts/ui/components/ui_copy.gd`, `localization/en-US.json`, `localization/zh-CN.json` | Add all missing campaign-map, mission-status, deployment-hint, launch-error, and outcome-action copy with placeholder schemas. |
| `assets/ui/staging/frames/`, `assets/ui/staging/icons/`, `scripts/ui/components/staging_skin.gd` | Reuse existing approved frame/icon assets and material helpers before producing new campaign-only ornaments. |

## Responsive risk assessment

### `1280×720` landscape

| Risk | Severity | Required mitigation / gate |
|---|---:|---|
| Stage route plus selected dossier can exceed 720px when placed inside a centered shell. | High | Use full safe viewport; keep header and bottom action dock fixed; scroll/zoom only the route region. Validate all eight nodes and dossier at 100% UI scale. |
| Mission Command is already at `1210×660`, leaving only 35px vertical margin; shell padding and child minimums can clip the dock. | High | Preserve accepted local-scroll strategy and verify header, roster, intelligence, and all three actions simultaneously visible. Do not increase card height or panel padding. |
| Three `190×220` roster cards plus filter controls can force horizontal/vertical pressure with localized text. | High | Cap portrait image region, use badges instead of long status sentences, and test long Chinese and premium-life labels. |
| Result reward, entitlement, premium-loss, consequence, training notice, and actions are one vertical document. | High | Separate fixed header/action dock from an internally scrolling debrief body. Test maximal simultaneous result payload. |
| Battle HUD control strip, map recenter, status HUD, spells, and deployment slots can collide. | High | Introduce overlay regions and collision-aware anchors; validate widest slot labels and a six-hero plus traps loadout. |
| Deploy slot grid breakpoint treats exactly 1280 as three columns, potentially making a tall bottom-left block. | Medium | Use available-width calculation and horizontal paging/rail instead of fixed width breakpoints where possible. |
| Terminal Continue is positioned at `viewport.y * 0.5 + 120` and does not visibly relayout in the reviewed terminal path. | Medium | Anchor to safe-area bottom/center and test resize after terminal state. |
| Cinzel has no CJK glyphs. | Medium | Continue explicit Latin-display/CJK fallback policy; never force Cinzel onto translated labels. |

### `720×1280` portrait

| Risk | Severity | Required mitigation / gate |
|---|---:|---|
| A literal horizontal campaign map would become illegible or require undiscoverable two-axis pan. | Critical | Author a vertical route mode with one-axis scroll and an inline/bottom dossier; do not uniformly scale landscape. |
| Mission portrait stacks header, filter bars, roster, intel, readiness, and three `62px` actions inside a `680×1180` shell. | High | Keep roster and intel independently scrollable, compact filter controls, and guarantee all actions in the initial safe view as the approved concept log requires. |
| One-column `190px`-high roster cards make large rosters expensive to scan. | High | Use a portrait-specific compact horizontal card rail or 2-column narrow card mode if readability permits; preserve at least 44px targets and full identity access. |
| Search (`240px`) and sort (`200px`) minimums stack with status/faction filters and consume the upper viewport. | High | Collapse advanced sorting/filtering into a drawer/sheet, retain active-filter summary and clear action. |
| Deployment slot box is forced to one column at the lower-left and can obscure a large fraction of the battlefield. | Critical | Replace with a bottom horizontal carousel or two-row dock with expand/collapse; keep map visible and touch targets ≥44px. |
| Portrait battlefield intentionally pans horizontally; deployment drag, map drag, and local dock scroll can conflict. | Critical | Maintain gesture arbitration and post-drag click suppression; define distinct drag handles/axes and test touch sequences on edge cells. |
| Facing cluster reserves 104px top and 88px bottom but can still overlap the pan hint, Center, or expanded deploy dock. | High | Add shared safe-region negotiation; test all four edge/corner placement cells with overlays visible. |
| Results portrait shell (`640×900`) leaves large dead space while maximal content scrolls inside a centered plate. | Medium | Use a full-height debrief sheet (`≈680×1180`) with persistent actions and portrait-safe key art crop. |
| Full-width 16:9 adult character art crops heavily in portrait. | High | Supply art-directed portrait focal metadata or dedicated crops; keep adult faces, weapons, and important costume cues visible and avoid accidental sexualized crops. |
| Pan hint uses a fixed bottom calculation and can sit over the deployment dock. | High | Position relative to registered dock height or move to a dismissible top safe-area toast. |
| Soft keyboard from name search can cover selected squad and actions. | Medium | Ensure focused field scrolls into view, allow keyboard dismissal, and keep Deploy state recoverable after keyboard closes. |

## Exact test targets

The revamp needs focused UI tests in addition to existing simulation tests. Test scripts may be new SceneTree tests or extensions, but their target behavior and nodes should remain explicit.

| Test target | Exact assertions |
|---|---|
| New `tests/campaign_stage_select_ui_test.gd` | Instantiate `stage_select.tscn` with a campaign fixture; assert eight route nodes in campaign order; only sequentially unlocked nodes are enabled; cleared stars match projection; locked activation cannot mutate `selected_stage_id`; enabled activation sets it and requests Squad Select; Back and `ui_cancel` request Staging. |
| New `tests/campaign_stage_select_responsive_test.gd` | Render/probe `1280×720` and `720×1280`; assert landscape and portrait route modes, visible action dock, no viewport escape, reachable final stage, selected dossier reflow, and ≥44px enabled targets. |
| New `tests/mission_squad_select_ui_test.gd` | Assert mission index/title derive from selected stage; narrative fields bind correctly; missing narrative disables Deploy; zero selection disables Deploy; selection limit is enforced; deselection works; prefill retains only selectable heroes; selected order/identity is stable. |
| Extend/retain `tests/faction_roster_filter_test.gd` | Preserve default Active behavior, Fallen and faction counts, explicit faction precedence, and safe fallback. Add card-level filtering checks in Mission. |
| Extend/retain `tests/custom_naming_roster_test.gd` | Preserve custom callsign/title through annotation, filtering, card label, selected squad chip, and Results hero effect rows. |
| New `tests/mission_roster_identity_ui_test.gd` | Assert ready, fallen, premium, premium-life, custom title, DP, class, portrait, and recruitment index presentations; fallen cards are visible only under intended filter and never selectable. |
| New `tests/mission_training_return_test.gd` | Mission selection → Training → Mission restores selected stage, selected hero IDs, filters where deliberately persisted, and deploy eligibility; Results → Training → Results preserves `last_result`. |
| New `tests/campaign_launch_transaction_ui_test.gd` | Accepted begin attempt opens Battle only after commit; rejected/retryable commit remains on Mission, prevents duplicate launch, shows error/retry UI, and does not publish a fake active battle. |
| New `tests/deployment_dock_ui_test.gd` | Assert ticket-row identity and stable order, trap separation, deployability projection, DP/status updates, six-hero responsive layout, and no dock escape at both target viewports. |
| Existing deploy-flow contract harness referenced by `deploy_bar.gd` comments, or new `tests/deploy_flow_test.gd` | Validate operator drag → valid cell → facing → commit; invalid cell reject; cancel/right-click/Escape cleanup; trap valid release direct commit; action payloads unchanged. |
| Existing trap-flow contract harness referenced by `deploy_bar.gd` comments, or new `tests/trap_flow_test.gd` | Validate trap validator use, amber patterned state, no facing, rejection, and cancel behavior. |
| Retain `test/map_navigator_orientation_smoke.gd` | Preserve exact portrait height-fill, base-side default, horizontal overflow, rubber band/snap, click suppression, recenter, and landscape deployment-touch availability at `720×1280`/`1280×720`. |
| Retain and extend `test/map_navigation_overlay_smoke.gd` | Preserve first-use hint visibility/persistence, timeout, pan dismissal, R/button recenter, landscape suppression, interaction gating; add dock-safe layout and reduced-motion non-pulse assertion. |
| Retain `test/stage_orientation_smoke.gd` and `test/stage_redesign_smoke.gd` | Ensure responsive stage copies and terrain semantics remain compatible with deploy/map UI changes. |
| Retain `test/placement_feedback_smoke.gd` and `test/agent4_isometric_renderer_smoke.gd` | Preserve placement SFX/VFX distinctions, dynamic grid scale, elevated deployment semantics, and obstacle correctness. |
| New `tests/battle_resign_dialog_ui_test.gd` | Opening confirm pauses and captures modal focus; Cancel restores prior speed/focus; Confirm sends resign once; Space cannot accidentally confirm; buttons remain reachable by controller. |
| New `tests/battle_terminal_results_transition_test.gd` | No stamp/Continue before accepted `record_result`; clear/defeat stamp and correct SFX appear once; Continue opens Results once; resize keeps Continue inside safe area. |
| New `tests/results_ui_test.gd` | Cover clear and defeat; zero/three stars; kills/leaks; each reward kind; Marks; multiple entitlements; XP awards; premium life loss and lockout; missing narrative fallback; typed cards faithfully match `last_result`. |
| New `tests/results_route_test.gd` | Retry preserves stage/squad and opens Mission; Return opens Staging without clearing campaign; Train opens with `results` return path; Back-to-Title confirmation clears only after explicit acceptance; `ui_cancel` follows the approved safe route. |
| New `tests/results_responsive_test.gd` | At both target viewports, assert headline, consequence, maximal reward list, and every applicable action remain reachable; action dock stays visible; no overlap/escape; portrait key-art crop respects focal-safe bounds. |
| New `tests/campaign_localization_ui_test.gd` | Run English and Simplified Chinese at both target viewports; assert no missing glyphs, raw localization keys, placeholder leakage, or clipped critical actions; verify mission index, stars, life counts, and reward formats. |
| New visual harness `test/campaign_family_visual_harness.tscn/.gd` | Deterministically capture Company Command entry, map states, Mission empty/full/fallen/premium states, deploy/facing/invalid overlays, clear/defeat terminal states, and maximal Results at `1280×720` and `720×1280`, with reduced motion on/off. |

## Acceptance gates

1. **Behavioral:** all authoritative campaign, transaction, deploy-validator, resolution, and routing contracts above pass without changes to simulation ownership.
2. **Visual continuity:** Company Command, Stage Select, Mission Command, battle overlays, and Results visibly share the Lunaris material/type/state system; no generic centered utility dialog remains in the primary path.
3. **Character promise:** all new hero imagery is unmistakably adult 21+, glamorous and powerful but non-explicit, with mature facial/anatomical cues and UI-safe crops.
4. **Responsive:** all primary actions are present in the initial safe view at `1280×720` and `720×1280`; long content is reachable through intentional local scrolling; no control or label escapes the viewport.
5. **Input:** mouse, touch, keyboard, and controller paths retain visible focus, cancellation parity, modal focus safety, and minimum target size. Map pan and deployment gestures remain unambiguous.
6. **Localization/accessibility:** English and Simplified Chinese render with correct fallback fonts; critical state never relies on color alone; reduced motion removes decorative pulses/bounce while preserving meaning.
7. **Data fidelity:** every title, narrative line, unlock, star, reward, identity, life, XP, class, and result displayed by the UI comes from the existing resource/projection/result source or a clearly presentation-only label—not from duplicated gameplay rules.

## Priority order

**P0:** Preserve transactional/authoritative contracts; fix Results `ui_cancel` safety; add launch-error presentation; prevent portrait deploy-dock obstruction and gesture conflicts.  
**P1:** Replace Stage Select list with responsive route + dossier; redesign Results into typed, outcome-specific debrief; unify terminal transition.  
**P2:** Correct Mission hard-coded identity, localize remaining strings, componentize deployment cards, and add selected-slot visualization.  
**P3:** Apply premium battle-overlay skin, patterned placement cues, reduced-motion handling, and final animation/audio polish.

The correct implementation strategy is therefore **not a gameplay rewrite and not a static mockup transplant**. It is a componentized presentation upgrade around existing authoritative seams, with Stage Select and Results receiving the largest structural changes and Mission Command receiving targeted fidelity, localization, and launch-state refinements.
