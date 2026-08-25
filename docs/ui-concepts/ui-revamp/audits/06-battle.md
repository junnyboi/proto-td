# Battle UI Family Audit — Battle HUD, Tutorials, Placement, Pause, and Feedback

**Audit group:** 06 — Battle  
**Repository revision:** `6f382b621c812c29dacfa79a41fe59e19909709c`  
**Target engine and reference canvas:** Godot `4.7.2`, `1280×720`  
**Required responsive portrait gate:** `720×1280`  
**Audit scope:** Battle HUD; operator, trap, skill, and spell controls; pause and resign; terminal and results presentation; First Stand tutorial; placement, target, and facing feedback; map-navigation overlay; tooltips; transient battlefield dialogs and effects.

## Executive assessment

The battle family is **functionally broad and architecturally disciplined but visually fragmented**. Its most important strength is that interaction adapters do not invent battle truth: deployment, traps, spells, skills, healing, retreat, and resign all pass through `BattleModel.apply_action`, while button enablement and target validity use the model's own validators. Camera navigation and effects are likewise presentation-owned. These contracts must survive any redesign.

The principal problem is that the live battle reads as an engineering/debug HUD attached to an increasingly polished isometric game. A clipped text line reports `Base HP`, `DP`, kills, raw tick, and result; default Godot buttons hold unit names, speed, pause, resign, retreat, and spells; tutorial and map-pan panels use the older rounded Aetheria treatment; and the terminal flow combines a pixel-art stamp, a plain `Continue` button, and then a generic centered results plate. These elements do not yet express the approved **premium, clearly adult 21+ anime-gacha Lunaris Reliquary** promise established by `docs/ART_DIRECTION.md` and the accepted Mission, Training, title, and staging concepts.

The revamp should not add decorative noise to the map. It should build a coherent, compact **Lunaris field-command layer**: clipped black-blue glass, thin reliquary-gold construction, moon-cyan state energy, high-contrast ivory type, mature operator portrait crops, and stable information zones. Essential battle information should remain continuously legible, while transient guidance should be contextual and should not occupy the same coordinates as persistent controls.

A second major finding is that portrait support exists at the map layer but remains risky at the control layer. The rotated stage, two-axis pan, overscroll, inertia, recenter action, and click suppression are deliberate and tested. By contrast, the deploy rail can become a tall one-column stack; its advertised `BAR_HEIGHT` remains `88` even when that stack is much taller; the facing chooser only reserves that fixed height; the pan hint occupies the lower field; and top-right spell, pause, status, tutorial, and recenter elements are all positioned independently. The implementation therefore needs a shared safe-area/layout coordinator rather than further local offsets.

## Sources reviewed

The audit reviewed the repository overview and display configuration; canonical visual direction; existing UI concept documents; battle scenes and presentation scripts; battle definitions and localization; shared UI styles; placement feedback documentation; and all currently available battle-adjacent smoke tests. The following files are the primary evidence set.

| Area | Source files |
|---|---|
| Project and direction | `project.godot`; `README.md`; `docs/ART_DIRECTION.md`; `docs/TOWER_PLACEMENT_FEEDBACK.md` |
| Accepted UI language | `docs/ui-concepts/LUNARIS_ENTRY_REDESIGN.md`; `docs/ui-concepts/MISSION_TRAINING_GACHA_UI.md`; `docs/ui-concepts/STAGING_CONCEPT_FIDELITY_PLAN.md`; `docs/ui-concepts/ui-revamp/reference-findings.md` |
| Scene roots | `scenes/battle.tscn`; `scenes/results.tscn`; `scenes/ui/components/aetheria_screen_shell.tscn` |
| Battle orchestration | `scripts/view/battle_view.gd`; `scripts/view/battle_hud_presenter.gd`; `scripts/view/map_navigator.gd`; `scripts/view/battle_palette.gd` |
| Interactive controls | `scripts/ui/battle_controls.gd`; `scripts/ui/deploy_bar.gd`; `scripts/ui/spell_bar.gd`; `scripts/ui/first_stand_tutorial.gd`; `scripts/ui/map_navigation_overlay.gd`; `scripts/ui/results.gd` |
| Battlefield feedback | `scripts/view/juice_layer.gd`; `scripts/view/skill_ready_feedback.gd`; `scripts/view/enemy_damage_feedback.gd`; `scripts/view/selection_ring.gd`; `data/juice_config.tres`; `assets/sfx/catalog.tres` |
| Shared UI system | `scripts/ui/components/aetheria_theme.gd`; `scripts/ui/components/aetheria_screen_shell.gd`; `scripts/ui/components/lunaris_ops_style.gd`; `scripts/ui/components/ui_copy.gd`; `scripts/ui/game_typography.gd`; `data/presentation/ui/threshold_theme.tres`; `data/presentation/ui_material_tier.gd` |
| Content and localization | `data/operator_def.gd`; `data/spell_def.gd`; `data/trap_def.gd`; `data/skill_def.gd`; `data/target_policy_def.gd`; `data/operators/*.tres`; `data/spells/*.tres`; `data/traps/*.tres`; `localization/en-US.json`; `localization/zh-CN.json` |
| Existing focused tests | `test/map_navigation_overlay_smoke.gd`; `test/map_navigator_orientation_smoke.gd`; `test/placement_feedback_smoke.gd`; `test/placement_feedback_visual_harness.gd`; `test/placement_feedback_visual_harness.tscn`; `test/stage_orientation_smoke.gd`; `test/stage_redesign_smoke.gd` |

## Screen and state inventory

The battle scene is intentionally code-built: `scenes/battle.tscn` contains only a `Node2D` with `battle_view.gd`, and every HUD surface is created at runtime. The following inventory therefore treats meaningful runtime states as screens or overlays even when they are not separate `.tscn` resources.

| Screen or overlay | Current composition | Functional interactions | Current persistence/lifecycle |
|---|---|---|---|
| **Live battle field and HUD** | Isometric stage over a flat dark backdrop; one top-left `Label` for Base HP/HP, DP, kills/K, raw tick/T, result, and stars after clear | Observation only; leak feedback shakes/tints this label | Created by `BattleHudPresenter`; text is projected from the live model snapshot |
| **Operator and trap deployment bar** | Default Godot buttons with sprite icon, display name or ticket identity suffix, DP cost; responsive `GridContainer` at bottom-left | Press-and-drag an enabled operator or trap; operators require facing after release; traps commit on valid release; right-click or `ui_cancel` cancels | Rebuilds when deployment IDs change; enablement derives from `is_deployable` / `is_trap_placeable` |
| **Placement targeting field** | All valid tiles receive translucent green operator, amber trap, or pale green heal diamonds; hovered tile is valid-color or red | Release commits trap or opens facing chooser; invalid release rejects and cancels; map navigation is blocked while targeting | Screen-space overlays are recalculated after map scale/layout changes |
| **Facing chooser** | Four illustrated gold diagonal arrows in a fixed 2×2 screen-space cluster; hover/focus or tutorial emphasis switches one arrow cyan; arrows bounce/pulse | Choosing any arrow calls `deploy`; cancellation restores normal time and clears overlays | Appears only after a valid operator placement release; cluster clamps to simple top/bottom margins |
| **Deployed-unit selection, active skill, Mend, and retreat** | Rotating dashed gold selection ring; ready skill activates immediately on unit click, or enters heal-target mode; unready unit exposes a plain floating `Retreat` chip | Click unit; click valid heal recipient; click Retreat; click empty map to deselect; `ui_cancel` cancels Mend | Readiness comes from unit state; Mend validity comes from `HealingRules`; selection clears on death/retreat |
| **Spell bar and spell targeting** | Default top-right spell buttons with icon/name and `1/wave` suffix; 8 px amber cooldown sweep; square/diamond valid or red target cursor | Press spell; next left press casts at cell or lowest-ID valid enemy on clicked cell; right-click/`ui_cancel` exits | Empty loadout intentionally creates no buttons; enablement and cursor validity are model-owned |
| **Pause/speed/resign strip** | Top-right row below spells: `II` / `>`, `1x`/`2x`/`4x`, `Resign`, and a fixed `PAUSED` label slot | Click pause; Space toggles pause; speed cycles and unpauses if needed; Resign opens confirmation | Pause/speed writes only `ticks_per_frame_scale`; interaction is disabled during tutorial hold |
| **Resign confirmation dialog** | Unthemed centered `PanelContainer` with `Resign this battle?`, `Counts as a defeat.`, and Resign/Cancel default buttons | Opening forces pause; Cancel restores prior scale; confirm applies `resign`; both restore the prior scale after closing | Modal visibility is local; no dimmer, focus trap, localization, or `ui_cancel` behavior is implemented |
| **First Stand tutorial** | Four-step Aetheria modal card with illustration, copy, buttons, route diamonds, recommended-cell marker, and focused control ring; followed by a six-second field reminder | Route → deployment → facing → block → live; invalid and cancelled placement return to deployment guidance; skip/dismiss; tutorial gates deploy controls and holds battle time | Shows only for campaign stage `s1` before any `s1` star exists; tutorial completion itself is not separately persisted |
| **Map-navigation overlay** | Portrait-only first-use `DRAG TO PAN` hint plus a `CENTER` button with tooltip | Portrait primary drag/touch with threshold, rubber-band, inertia, snapback; middle drag and wheel panning; `R` or button recenters | Hint is persisted through `ViewPreferences`; camera input is blocked while deployment, spell, or Mend targeting is active |
| **Transient battlefield feedback** | Wave banner, result stamp and stars, leak vignette/HUD knock/shake, kill sparks, damage flash/stagger, charm swirl, trap snap/shimmer, skill burst, Mend burst, SP blink, portrait-color flash, deployment crouch and terrain-specific emitters | Presentation only; cues follow observed model edges | All effects age in render time and do not mutate authoritative battle state |
| **Terminal battle overlay** | Full-width CLEAR/DEFEAT stamp band with sequential stars and a plain centered `Continue` button | Button or focused Space proceeds to Results | `Game.record_result` must succeed before stamp appears; no automatic scene swap |
| **Results screen** | Centered scrollable Aetheria reading plate with result, stars, kills/leaks, rewards, class unlocks, premium-life losses, narrative consequence, optional training notice, and action grid | Train Recruits when eligible; Retry; Return to Staging; Back to Title; `ui_cancel` always returns to title | Projects `Game.last_result`; action grid stacks in portrait; focus wraps through available actions |
| **Tooltips and transient copy** | Only map recenter and results actions expose explicit tooltips; unit/spell buttons rely on visible text; tutorial gives contextual feedback | Hover tooltip where available | Several battle strings are hard-coded and bypass `UiCopy`/I18n |

## Feature contracts that must survive

### Authoritative state and action routing

> **Battle UI is a projection and input adapter, never a second battle model.**

The architectural contract in `README.md` is correctly reflected in the battle family. A redesign must preserve each of the following seams:

| Interaction | Contract to preserve |
|---|---|
| Operator availability | Disabled state remains derived from `model.is_deployable(deployment_id)`; the UI must not replicate DP, death, redeploy, or placement rules |
| Operator placement | Valid tiles remain derived from `model.can_deploy_at`; commit remains `apply_action([&"deploy", deployment_id, cell, facing])` |
| Trap availability and placement | Availability remains `is_trap_placeable`; valid cells remain `can_place_trap_at`; valid release commits `place_trap` directly because traps have no facing |
| Spell availability and target validity | Button state remains `is_castable`; target indication remains `cast_target_valid`; CELL spells pass a cell, ENEMY spells resolve the lowest-ID valid alive enemy on the clicked cell |
| Active skills | Unit readiness remains `UnitState.is_skill_ready`; non-heal skills call `trigger_skill`; Mend uses `HealingRules.is_valid` and `mend` |
| Retreat | Clicking an unready selected unit can expose Retreat; confirm continues to call `retreat` with the authoritative unit ID |
| Resign | Confirm continues to call `apply_action([&"resign"])`, producing the same defeat path as any other model result |
| Simulation projection | HUD, unit bars, result stamp, damage, wave, leak, and placement effects continue to observe model/snapshot changes rather than write simulation values |

The campaign loadout contract is also essential: `SpellBar.setup` receives the caller's validated spell IDs, and **an empty loadout must remain an empty bar** rather than a show-everything sentinel. Trap slots likewise come only from unlocked launch IDs. Ticket display data may override operator cost/sprite identity, but the model remains the source for eligibility.

### Time, pause, and tutorial behavior

Pause is currently a view-time seam, not a model command. The revamp must retain the `ticks_per_frame_scale` behavior: Space and the pause button toggle zero/nonzero; speed cycles `1× → 2× → 4× → 1×`; choosing speed while paused both chooses the speed and resumes; resign confirmation pauses and Cancel restores the exact prior scale. Tutorial hold and deploy-drag slowdown use `juice_time_push`/`juice_time_pop`; the strongest active slowdown wins, and leaving the battle resets `Engine.time_scale` to `1.0`.

First Stand remains a conditional onboarding flow, not a universal interrupt. It appears only for campaign stage `s1` before the first recorded `s1` clear, holds battle simulation during route/deploy/facing/block instruction, enables operator interaction only at the intended steps, and releases the hold for the six-second live reminder. Placement rejection or facing cancellation must return the tutorial to its deploy step. Skipping must restore interaction and remove every guide.

### Spatial interaction and camera contracts

Portrait stages are copied/rotated for the viewport before model and themed presentation are constructed. The camera uses exact height-fill scaling, derives overflow bounds from the sprite-aware content envelope, boots at the base side, allows portrait primary/touch drag with a 10 px threshold, suppresses the subsequent map click, permits bounded rubber-band overscroll, then applies inertia or snapback. Recenter returns to the established default pan. Landscape primary touch remains available for deployment; middle-button and wheel panning remain separate affordances.

Camera navigation must remain blocked while a deployment cursor, spell cursor, or Mend target cursor is active. Deployment and transient effects must continue to track map transform changes. A newly deployed unit may expand bounds just enough to become visible. The first-use portrait pan hint appears only when portrait overflow exists, is allowed, and has not been completed or expired; a real pan permanently dismisses it through `ViewPreferences`.

### Placement, facing, target, and feedback semantics

The three placement families need visually distinct but rule-equivalent semantics: operator-valid tiles are green today, traps are amber, and healing is pale green; invalid hover is red. Facing remains a separate explicit choice after valid operator release, and the four screen-diagonal arrows continue to map to the model's cardinal facings. The selected/tutorial-recommended facing can be emphasized, but **any arrow remains legal and commits**.

Terrain-specific placement confirmation is already an approved contract. Normal ground plays `deploy_ground` and emits eight warm dust/grit particles; elevated placement plays `deploy_elevated` and emits cyan-white shards, one expanding isometric ring, and one contracting beam. The legacy `deploy` sound alias must continue resolving to `deploy_ground`. Both profiles occur before the existing crouch recovery and remain presentation-only.

Other edge-triggered cues must remain one-shot and outcome-safe: ability-ready audio only on false-to-true readiness; wave banner on wave-index advancement; leak cue, vignette, HUD knock, approved shake, and hit stop on leak growth; kill spark and sound once per death; charm swirl/beat on faction flip; terminal result only after `Game.record_result` accepts the outcome; sequential stars equal to model stars; and no automatic results transition before player confirmation.

### Results and campaign continuity

Results must continue to project `Game.last_result`, including clear/defeat, stars, kills, leaks, reward grants, class entitlements, premium-life spend and lockout, and the stage-specific clear or defeat consequence. Campaign results expose Retry and Return to Staging; eligible recruits add Train Recruits and route to training with a `results` origin; Back to Title remains available; portrait actions stack and focus traversal wraps. A visual redesign may reorganize this information but must not alter reward, attempt, training, premium-life, save, or navigation authority.

## Visual-system gap analysis

### Conflict with the approved Lunaris aesthetic

The accepted direction is a sophisticated adult gacha command interface: near-black lunar ink, translucent black-blue glass, ivory type, restrained moon-cyan and reliquary gold, tight clipped geometry, ceremonial mechanisms, and character-forward hierarchy. The battle family currently has four competing visual dialects:

1. **Bare Godot controls** dominate the HUD, deployment, spells, pause, retreat, Continue, and resign confirmation.
2. **Legacy Aetheria panels** style tutorial, map hint, and Results with uniform rounded rectangles and medium-grey boundaries.
3. **Pixel/arcade transients** provide wave and result banners, stars, and saturated combat colors.
4. **New Lunaris operations styling** exists elsewhere in `lunaris_ops_style.gd` and staging frame assets but is not applied to battle.

This makes battle feel older and cheaper than Mission, Training, staging, and title even though its underlying behavior is richer. The inconsistency is most visible in the route from Mission's adult portrait cards to battle's small sprite-button rows, and from the CLEAR stamp to Results' centered utility plate.

### Information hierarchy and legibility gaps

| Current gap | Consequence |
|---|---|
| The HUD is one clipped text label with raw `tick` and debug-like abbreviations | Mission-critical base health and DP do not read as distinct resources; raw tick consumes premium space without meaningful player framing |
| HUD, spells, and controls are all independently positioned at the top | The screen has no stable command rail; overlap and occlusion are resolved by comments and offsets rather than composition |
| Operator slots show sprite, text, and DP only | No portrait-forward continuity, role/class, ground/elevated placement, redeploy state, or reason for disabled status is visible |
| Spells expose an 8 px shrinking strip and sometimes `1/wave` | Cooldown magnitude, target mode, once-per-wave consumption, and invalid target reason are not clear enough at battle speed |
| SP readiness is a tiny blinking bar and a sound | The player can miss which operator is ready; clicking a ready unit immediately activates the skill with no skill-name affordance |
| Retreat appears as a floating plain button only when a skill is not ready | The same unit click has state-dependent destructive behavior, and the chip lacks portrait/name/health/refund or cancellation context |
| Green/amber/red translucent tiles carry most targeting meaning | Color-only differentiation is weak for accessibility, can flatten detailed terrain, and does not explain why a tile is invalid |
| Facing arrows are attractive assets but float without a central anchor or range preview | The action lacks an explicit selected operator, attack-area preview, cancel affordance, or `CHOOSE FACING` label |
| Resign confirmation lacks dimming, destructive styling, focus ownership, localization, and cancel shortcut | A consequential action reads as a generic utility panel and is less accessible by keyboard/controller |
| Result stamp and Results screen duplicate the outcome without a designed transition | The emotional peak is split between an arcade band and a static reading dialog; rewards and adult operator consequences lack visual emphasis |

### Character and 21+ presentation gaps

The art direction requires visibly adult, 21+ heroes with must-pull charisma and mature identity markers. The battlefield chibis may remain tactical abstractions, but the deploy rail and unit inspector are the correct places to reassert adult identity through canonical portrait crops. Current operator slots use small tactical sprites as icons, which preserve class readability but do not deliver premium gacha attachment. The redesign should use existing portrait IDs and ticket visual specs where available, crop face/hair/upper costume safely, and retain adult expressions and faction details. It must not generate juvenile, school-coded, or ambiguous-age imagery, nor should crops create accidental sexualization.

### Localization and accessibility gaps

Tutorial and Results copy is localized in English and Simplified Chinese with key parity, but map-navigation fallbacks (`ui.map_navigation.*`) are absent from both locale JSON files even though `UiCopy` defines English fallbacks. Most of the battle surface bypasses localization entirely: Pause/Paused, Resign, confirmation body, Cancel, Retreat, Continue, wave labels, HUD labels and abbreviations, spell `1/wave`, and deployment slot formatting are hard-coded. Data names shown by DeployBar and SpellBar use `display_name` directly rather than the existing localized operator/spell naming helpers.

Keyboard/controller support is uneven. Results provides wrapped focus and a default focus. Battle control buttons intentionally use `FOCUS_NONE` to prevent Space from double-activating controls, but this also removes normal keyboard/controller navigation. Recenter is also `FOCUS_NONE`. Facing buttons can focus, while deployment/spell buttons retain default focus behavior; there is no declared focus topology. Tooltips exist only for recenter and Results actions and are not useful on touch. Controls need accessible names and visible state copy, not hover-only explanations.

Motion is also inconsistent with the title's reduced-motion setting. Facing arrows, tutorial pulse, pan-hint pulse, SP blink, banner slide, result stars, flashes, screen shake, and inertia have no shared reduced-motion seam. Critical validity/readiness information must remain visible when pulses or shake are reduced.

## Recommended battle component system

### 1. Lunaris field-command frame

Create one presentation root that owns safe areas and major zones. It should not be a large opaque plate over the battlefield. At `1280×720`, use a **compact top command rail** and a **bottom deployment dock** with clipped corners. At `720×1280`, use a top status cluster and a bottom portrait tray that can scroll horizontally or collapse, preserving the central map viewport.

The frame should derive its materials from `LunarisOpsStyle` and, where appropriate, the staging nine-patch vocabulary: `#07111C` ink, `#0B1827E8` glass, `#F5EFE1` ivory, `#91EAF1` selected/ready state, `#D9B96E` command and cost accents, muted violet depth, and danger red only for breach/destructive state. Corners should remain 0–6 px with clipped/engraved shapes rather than the existing 8–12 px rounded Aetheria cards.

The layout root should publish reserved rectangles for status, pause, spells, deploy tray, tutorial card, map navigation, target prompts, and terminal overlays. Every child should consume these zones rather than using unrelated fixed coordinates.

### 2. Battle status cluster

Replace the raw label with native, localizable resource components:

| Component | Recommended presentation |
|---|---|
| **Core Integrity** | Shield/reliquary glyph, large current Base HP, breach threshold or lives remaining when available, danger transition on leak |
| **Deployment Points** | Gold DP crystal/gauge with current value and subtle refill motion; never hide the number |
| **Wave pressure** | Current wave and remaining/defeated count if authoritative observation exposes it; otherwise retain kills without fabricating totals |
| **Battle state** | Compact RUNNING/PAUSED/CLEAR/DEFEAT badge; remove raw tick from player HUD or place it only in an optional diagnostics build |
| **Stars** | Show only at terminal outcome, preserving the model star count |

Leak feedback should knock the Core Integrity component rather than the entire text line. Red must be paired with icon/shape and brief `BREACH` text so the event is not color-only.

### 3. Operator deployment cards and tray

Each operator card should remain a native Button but use a clipped Lunaris card frame and a canonical adult portrait crop. Show **callsign/display name**, compact class/role glyph, DP cost, placement type, and a strong ready/insufficient/redeploy/dead state. Premium or named ticket identities must stay visually distinct without exposing internal IDs. Disabled cards need a reason badge or short state line rather than mere dimming.

Landscape can show a fixed-height horizontal tray or two compact rows without covering the field. Portrait must not use a tall one-column stack; use a horizontally scrollable tray of 112–136 px cards, an expandable drawer, or a tabbed Operators/Tools rail. Traps should be visually grouped as tactical tools and retain amber validity. Any scrolling gesture inside the tray must not begin map panning.

Dragging remains the primary direct-manipulation behavior, but provide a touch-accessible tap-select → tap-cell path if later usability testing confirms long drag conflicts with portrait map panning. Such a path must still call the same validators and verbs.

### 4. Selected-operator command chip

Replace the isolated Retreat button and ambiguous immediate skill activation with a compact contextual chip anchored to a safe screen edge, not directly over the unit. It should show portrait/callsign, HP/SP, skill name/readiness, and two explicit actions when applicable: **ACTIVATE** or **SELECT TARGET**, and **RETREAT**. If preserving one-click ready-skill activation is required for combat speed, the chip can appear after activation as confirmation/history, but the destructive Retreat action must remain visually separate and consistently available.

Do not invent refund or range values. Display them only when an authoritative API exposes them. Selection ring position and gold ceremonial motion may remain, but add a cyan state wedge or glyph to distinguish selected, skill-ready, and heal-target states without relying only on animation.

### 5. Spell command deck

Use compact engraved spell seals with icon, localized name, and an unambiguous availability layer. A cooldown should combine radial/linear fill with remaining seconds or ticks converted through authoritative configuration; once-per-wave spells should show `READY`, `USED`, or `NEXT WAVE`, not only `1/wave`. Entering targeting should visibly select the spell, add a concise `CHOOSE TARGET • RMB/ESC CANCEL` prompt, and show target footprint ornament without obscuring enemy silhouettes.

The current lowest-ID enemy resolution on a crowded cell is a deterministic contract, but the player should see which enemy will receive the cast. Add a target reticle on the resolved enemy while retaining the area footprint for cell spells.

### 6. Placement and facing layer

Keep valid-cell calculation unchanged, but replace flat color floods with layered isometric cues: a thin cyan/green perimeter plus a sparse center sigil for operators, amber trap brackets for tools, and a medical cross/ring for Mend. Invalid hover should use a red slash or broken-circuit glyph in addition to red. Do not draw heavy ornament on every valid tile at full opacity; the map and elevated geometry must remain readable.

At valid operator release, retain slowdown and the four existing arrow illustrations. Place them around a small lunar compass centered on the cell, show `CHOOSE FACING` at the cluster edge, draw a low-opacity live attack-range preview for the highlighted arrow, and expose a visible Cancel affordance for touch. The cluster must reserve the **actual deploy-tray rectangle**, not the constant `BAR_HEIGHT = 88`. Tutorial emphasis continues to change the recommended arrow to cyan, but no arrow should look disabled unless it truly is.

Ground and elevated deployment effects should be polished rather than replaced. Ground dust can gain a restrained gold lock-in circuit; elevated shards/ring/beam already match Lunaris cyan ceremony. Keep effect timing, event IDs, particle count/composition, crouch, and terrain routing stable.

### 7. Pause sheet and field controls

Use recognizable localized icons with text/tooltips: Pause/Resume, speed, and Menu. The Space contract remains. Keyboard/controller focus should be restored through an input design that prevents Space from activating both a focused button and the global pause action—prefer action consumption or a dedicated `battle_pause` handler over disabling focus globally.

A Menu button should open a full-screen dimmed **Field Operations** pause sheet. At minimum it includes Resume, speed state, Retry/Resign as allowed by product direction, settings/reduced motion if available, and Back/Cancel. If scope stays limited, the existing resign-only modal still needs a dimmer, `AuiDestructiveButton` or Lunaris danger styling, focus trap, default focus on Cancel, `ui_cancel` close, localized copy, and exact prior-speed restoration.

### 8. First Stand tutorial

The underlying four-step teaching sequence is strong and should remain. Restyle it as an **Astral Field Manual** rather than a large rounded modal: clipped black-blue sheet, gold step label, one focused illustration, ivory title, concise body, cyan primary action, and quiet skip. Keep native localized copy and the existing route/target/focus guides.

At landscape, anchor the card to a reserved right-side tutorial zone that does not cover spells or pause. At portrait, place it above a fixed-height deploy tray and allow body text to scroll locally if CJK or accessibility type expands. The guide should use a dimmer/spotlight only outside the target and map route rather than adding more pulsing shapes. The six-second live reminder should collapse into a small top-center field notice so it no longer blocks combat.

Tutorial completion needs an explicit product decision. Current behavior shows it again after any uncleared retry because visibility is inferred solely from missing `s1` stars. If that is intended, test it. If a player-scoped `seen_first_stand_tutorial` preference is desired, it must be introduced outside battle simulation and must not change campaign authority.

### 9. Map-navigation overlay

Retain the tested camera behavior. Replace Unicode `↔ ↕` with shipped glyph assets or ASCII-safe directional icons, because another concept review already exposed unsupported Unicode in web fonts. Add English and Chinese locale entries for `ui.map_navigation.*`; currently the overlay succeeds only through fallbacks.

The pan hint should sit in a reserved map-safe band above the deploy tray and should never overlap tutorial or targeting prompts. The recenter button should use the same field-control frame, expose a touch-readable icon and label, and become keyboard/controller focusable. Because the tooltip says `(R)`, keep the shortcut visible in desktop mode but omit or adapt it on touch. Do not advertise zoom: the navigator currently supports fit scale and pan, not user zoom or pinch.

### 10. Terminal outcome and Results

Turn the terminal overlay into a concise in-battle ceremony: dim the active field, freeze or hold presentation, show a Lunaris result crest with CLEAR/DEFEAT and sequential stars, and present a styled Continue command. Preserve the explicit player acknowledgment and `Game.record_result` gate.

Results should then become a full-viewport **After-Action Reliquary** rather than a centered generic dialog. In landscape, use an asymmetric two-column composition: outcome and rewards on the left, mission consequence and operator/premium-life consequences on the right, with a persistent bottom action dock. In portrait, stack those regions inside a single scroll area but keep actions fixed in the safe bottom dock. Premium-life loss and lockout need mature operator portrait emphasis and solemn danger styling; reward grants and class entitlements need distinct seals rather than uniform centered text lines.

The result screen must continue to render native text and dynamic data. Decorative assets may provide frames and symbols but must never bake reward names, counts, consequences, or buttons into imagery.

### 11. Tooltips and transient dialogs

Adopt one reusable battle tooltip component with short delay, safe-edge positioning, controller focus parity, and touch long-press or info-button parity. Deployment cards should explain class/placement and disabled reason; spells should explain target type, cooldown, and once-per-wave state; pause/speed/recenter should include shortcuts; Retreat should clearly state consequence without claiming unexposed refunds.

Transient messages should share a common hierarchy: **field banner** for waves, **target prompt** for an active targeting mode, **toast** for rejection/cancellation/ready events, and **modal** only for destructive confirmation. Action rejection currently provides sound and red cursor but no persistent reason; a short localized toast should explain `Not enough DP`, `Wrong terrain`, `Occupied`, `No valid target`, or a generic rejection only if those reasons can be obtained authoritatively. Do not infer reasons by duplicating rules.

## Responsive risk assessment

### `1280×720` landscape

| Risk | Evidence and impact | Required mitigation |
|---|---|---|
| **Top-layer collision** | HUD occupies almost the full width at `y=8`; SpellBar independently anchors top-right at `y=8`; controls anchor top-right at `y=64`. The HUD has higher z-index and can cover spell content. | One top command rail with explicit left/center/right regions and measured widths; spell deck must reserve status width |
| **Tutorial collision** | Tutorial card is 500 px wide at the upper-right (`y=116`), independently of controls/spells and map objectives | Reserve a tutorial panel rectangle; compact or move field controls while tutorial holds |
| **Bottom field loss** | Deploy grid uses three columns at 1280 and grows by squad/tool count; its translucent/default controls float directly over map content | Fixed-height dock with internal horizontal scrolling or compact card sizing; publish actual dock bounds to camera and facing layer |
| **Facing/tray overlap** | Facing safe maximum subtracts only `BAR_HEIGHT = 88`, not the deploy grid's live height | Clamp to measured tray safe rectangle and terminal/tutorial overlays |
| **Result action reachability** | Results action row is inside the same scroll as rewards and losses | Move actions to a persistent dock; test maximum representative reward/loss payload |
| **Dense label clipping** | HUD `clip_text = true`; long/localized operator names and status values have no adaptive layout | Componentized metrics, CJK font, ellipsis/secondary lines, no hidden essential data |

### `720×1280` portrait

| Risk | Evidence and impact | Required mitigation |
|---|---|---|
| **Deploy rail height explosion** | Portrait forces one GridContainer column. Four operators plus traps can occupy hundreds of pixels above the bottom, while other systems assume an 88 px bar. | Horizontal scroll tray, tabs, or collapsible drawer with bounded height; never one unbounded vertical column |
| **Facing chooser obstruction** | The chooser reserves only 88 px at bottom and can be clamped over tall slots; edge cells already force cluster translation | Clamp against actual tray, status, tutorial, and device safe insets; preview a connector to the target cell when displaced |
| **Pan hint overlap** | Hint anchors near `size.y - 228`, the same lower region occupied by the expanded deployment stack | Reserve a prompt band above the fixed tray; suppress or relocate while tutorial/targeting is active |
| **Top control crowding** | Compact HUD is 46% width and 84 px tall; spells remain top-right; pause row begins at `y=64`; recenter begins at `y=104` | Portrait-specific top stack with two measured rows; hide low-priority labels before shrinking touch targets |
| **Map pan versus battle gestures** | Primary drag pans only in portrait; deployment is also drag-based; click suppression protects map selection only after a pan threshold | Clearly separate tray gesture capture, map pan state, and active targeting; test slow drags near the 10 px threshold and touch release outside controls |
| **Tutorial card displacement** | Card sits above the first deployment slot and can rise only to `y=112`; tall CJK copy can overlap top UI or target field | Fixed tutorial sheet region with local scrolling and measured height; reduce art before reducing text below body-size minimum |
| **Touch accessibility** | Hover tooltips and keyboard shortcut notation do not transfer to touch; 46–64 px controls are acceptable but tightly clustered | Maintain ≥44 px targets, add long-press/info affordances, spacing, and screen-reader/accessibility labels |
| **Results actions below content** | Results stacks actions to one column, but the row remains inside scroll after variable rewards/losses | Fixed safe-bottom action dock; verify all actions and scroll end at 720×1280 |

The project does not declare a stretch mode or explicit device safe-area policy in `project.godot`; the battle root sizes itself from the visible viewport. Mobile/notched devices therefore need an explicit safe-inset abstraction before shipping portrait UI. The existing 1280×720 and 720×1280 gates are necessary but not sufficient for 18:9, 20:9, and browser canvas offsets.

## Implementation targets

The revamp should remain presentation-focused. No simulation files need to change merely to restyle or reorganize the battle family.

| Priority | Exact target | Recommended responsibility |
|---:|---|---|
| P0 | `scripts/view/battle_hud_presenter.gd` | Replace single text label with a componentized localized status cluster; keep snapshot-only projection |
| P0 | `scripts/view/battle_view.gd` | Instantiate one battle UI layout root, pass measured safe rectangles, preserve all model/action/time/result seams and feedback routing |
| P0 | `scripts/ui/deploy_bar.gd` | Convert slots to portrait-forward cards/tray; add state presentation; measure actual dock; preserve validators, signals, verbs, and target/facing behavior |
| P0 | `scripts/ui/spell_bar.gd` | Restyle spell seals, selected targeting state, cooldown/once-wave presentation, resolved-target reticle, and target prompt without duplicating cast rules |
| P0 | `scripts/ui/battle_controls.gd` | Localized focusable field controls and pause/resign sheet; preserve pause/speed/prior-scale behavior |
| P0 | `scripts/ui/first_stand_tutorial.gd` | Lunaris Field Manual layout, collision-free breakpoints, reduced motion, and current step/gating/signals |
| P0 | `scripts/ui/map_navigation_overlay.gd` | Shared safe band, asset-backed arrows, localization, focus/touch parity; preserve hint persistence and recenter event |
| P0 | `scripts/ui/results.gd` and `scenes/results.tscn` | Full-viewport after-action composition, persistent action dock, reward/loss hierarchy, current routes and result data |
| P1 | New `scripts/ui/components/battle_ui_layout.gd` | Central reserved-zone/safe-area coordinator for landscape and portrait |
| P1 | New `scripts/ui/components/battle_status_cluster.gd` | Core integrity, DP, wave/kills, pause/result status |
| P1 | New `scripts/ui/components/operator_deploy_card.gd` | Native button, adult portrait crop, cost/class/placement/state, accessible name/tooltip |
| P1 | New `scripts/ui/components/battle_target_prompt.gd` | Shared deployment/spell/Mend/facing prompt and cancel affordance |
| P1 | New `scripts/ui/components/battle_tooltip.gd` | Desktop hover, focus, and touch parity with safe-edge placement |
| P1 | `scripts/ui/components/lunaris_ops_style.gd` | Add battle-specific compact HUD, selected, cooldown, danger, and tooltip roles, or promote them into a shared Theme resource |
| P1 | `scripts/ui/components/ui_copy.gd`; `localization/en-US.json`; `localization/zh-CN.json` | Localize every battle-facing string, including map navigation, state reasons, pause, resign, target prompts, wave/result, cooldown, retreat, and Continue |
| P1 | `scripts/view/selection_ring.gd`; `scripts/view/skill_ready_feedback.gd` | Coherent selected/ready/target visual states and reduced-motion-safe readiness cue |
| P1 | `scripts/view/juice_layer.gd` | Lunaris wave/result treatment and reduced-motion branching while preserving event counts, lifetimes, and placement profiles |
| P2 | `assets/ui/battle/` | Standalone production icons/frames: core integrity, DP, wave, pause/resume, speed, retreat, target/facing compass, cooldown, field banners, result crest; no baked text |
| P2 | `data/presentation/ui/threshold_theme.tres` or a new battle material tier | Replace rounded legacy HUD/modal roles with approved clipped Lunaris surfaces while retaining CJK fallback |

If disabled reasons, wave totals, deployment refund, cooldown seconds, or safe insets are not currently exposed by presentation-safe APIs, the UI should show only truthful generic state until a separately reviewed read-only projection is added. The revamp must not reverse-engineer those values from private model fields in component code.

## Exact validation and test targets

Existing tests cover map orientation/gesture behavior and terrain placement effects, but **no current test directly instantiates BattleControls, DeployBar, SpellBar, FirstStandTutorial, BattleHudPresenter, terminal Continue, or Results**. The following exact targets should form the acceptance suite.

### Existing targets that must continue to pass

| Target | Command | Contract |
|---|---|---|
| `test/map_navigation_overlay_smoke.gd` | `godot --headless --path . --script res://test/map_navigation_overlay_smoke.gd` | First portrait overflow hint, persistence after real pan, landscape suppression, recenter enablement, button and `R` emission |
| `test/map_navigator_orientation_smoke.gd` | `godot --headless --path . --script res://test/map_navigator_orientation_smoke.gd` | Exact portrait height-fill, base-side boot, overflow, rubber-band limit/snapback, drag consumption, click suppression, recenter, landscape touch preservation |
| `test/placement_feedback_smoke.gd` | `godot --headless --path . --script res://test/placement_feedback_smoke.gd` | `deploy` alias, ground/elevated audio length and routing, emitter counts, elevated ring and beam |
| `test/placement_feedback_visual_harness.tscn` | Windowed captures with `PLACEMENT_PROFILE=ground` and `PLACEMENT_PROFILE=elevated` | Production-renderer confirmation of both terrain profiles and map anchoring |
| `test/stage_orientation_smoke.gd` | `godot --headless --path . --script res://test/stage_orientation_smoke.gd` | Stage copy/orientation behavior survives UI safe-area work |
| `test/stage_redesign_smoke.gd` | `godot --headless --path . --script res://test/stage_redesign_smoke.gd` | Redesigned stage data remains valid under battle UI projection |

### New focused contract targets

| Proposed exact target | Required assertions |
|---|---|
| `test/battle_hud_presenter_smoke.gd` | Snapshot values map to Core Integrity, DP, kills/wave, and result components; no raw-value drift; CLEAR star count; 1280×720 and 720×1280 geometry remains within assigned zone; essential labels do not clip in EN or zh-CN |
| `test/battle_controls_smoke.gd` | Pause/resume; Space parity; 1×/2×/4× cycle; speed unpauses; resign opens paused modal; Cancel restores exact prior scale; confirm emits `resign`; tutorial hold disables controls; `ui_cancel` closes modal and restores focus |
| `test/deploy_bar_interaction_smoke.gd` | Loadout/ticket slot identity; validator-derived disabled state; operator drag signal flow; invalid rejection; valid release opens facing; facing commits exact action; trap release commits without facing; right-click/`ui_cancel` cleanup; relayout uses measured dock bounds |
| `test/deploy_bar_unit_command_smoke.gd` | Empty click deselects; ready non-heal skill triggers; ready Mend enters targeting and only valid living allies commit; unready selection exposes Retreat; retreat commits exact unit; death/retreat clears selection and chip |
| `test/spell_bar_interaction_smoke.gd` | Empty allowed loadout stays empty; catalog spell not in loadout stays hidden; castability controls disabled state; CELL footprint span; ENEMY target resolves lowest valid ID on clicked cell; invalid/valid target visuals; right-click/`ui_cancel` cleanup; cooldown and once-wave presentation |
| `test/first_stand_tutorial_smoke.gd` | Visibility condition for campaign `s1`; ROUTE→DEPLOY→FACING→BLOCK→LIVE→DONE; hold emissions; operator gating; rejected/cancelled placement returns to DEPLOY; recommended facing emphasis; skip and delayed dismiss clean every overlay |
| `test/battle_terminal_overlay_smoke.gd` | Result stamp appears once only after accepted `Game.record_result`; CLEAR/DEFEAT copy and exact stars; Continue focus; player action opens Results; no automatic swap |
| `test/results_ui_smoke.gd` | Clear/defeat, tally, every reward kind, class entitlements, premium-life loss and lockout, narrative fallback and stage narrative, training eligibility, route callbacks, focus loop, `ui_cancel`, fixed action dock at both target viewports |
| `test/battle_ui_localization_test.gd` | EN/zh-CN key parity for all `ui.battle.*`, `ui.tutorial.*`, `ui.map_navigation.*`, and `ui.results.*`; placeholder type parity; no player-facing hard-coded battle strings; shipped glyph coverage |
| `test/battle_ui_visual_harness.tscn` plus `test/battle_ui_visual_harness.gd` | Deterministic states for default battle, maximum deploy loadout, disabled DP, operator placement valid/invalid, facing at each viewport edge, spell targeting, Mend targeting, selected/skill-ready unit, paused sheet, First Stand steps, map hint/recenter, CLEAR/DEFEAT, and Results payload |

### Required visual capture matrix

| Viewport | States |
|---|---|
| `1280×720` | Default live HUD; maximum operator/trap/spell loadout; pause sheet; tutorial route/deploy/facing; bottom-edge facing; spell target; terminal clear and defeat; Results with maximum representative rewards/losses |
| `720×1280` | Base-side boot; opposite pan edge; maximum deploy tray; pan hint; tutorial with English and zh-CN; top- and bottom-edge facing; map recenter; targeting cancellation; terminal; Results actions visible with scrolled content |
| Both | Keyboard focus, controller focus, mouse, touch emulation, reduced motion, 100% and enlarged text where supported, color-vision/desaturation review |

After implementation, run the focused tests above, then the repository baseline:

```bash
godot --headless --path . --import
godot --headless --fixed-fps 60 --path . --quit-after 120
```

## Acceptance criteria

The battle revamp is acceptable when the following are simultaneously true:

1. The complete live battle family reads as one **premium Lunaris field-command interface**, not default controls mixed with rounded utility dialogs.
2. Adult operator identity is visible in deployment/selection surfaces through approved portrait assets while tactical chibis remain readable on the map.
3. Core integrity, DP, actionable units/spells, pause state, active target mode, and outcome are legible at a glance without raw-debug presentation.
4. All deployment, trap, spell, skill, Mend, retreat, resign, time-scale, result, reward, and navigation authority remains unchanged.
5. `1280×720` and `720×1280` show no HUD overlap, clipped essential copy, unreachable action, or facing/target control under the deploy tray.
6. Portrait pan, inertia, overscroll, click suppression, hint persistence, and recenter behavior continue to pass their current smoke tests.
7. Ground and elevated placement cues retain their exact audio routing and emitter composition.
8. Every player-facing battle string is localizable in English and Simplified Chinese; font/glyph coverage is verified; essential meaning is not color-, hover-, or motion-only.
9. Results keeps variable content scrollable while actions remain visible in the safe area.
10. Deterministic visual harness captures pass for the complete interaction matrix, including reduced motion and maximum-content stress states.

## Final disposition

**Revamp priority: P0, high impact.** The battle family contains the game's densest and most important interactions, but it currently has the largest quality gap against the approved title aesthetic. The recommended work is a presentation-system consolidation, not a gameplay rewrite. Preserve the model validators, action verbs, time seams, tutorial signals, camera semantics, terrain feedback, and result authority exactly; replace the fragmented surfaces around them with a measured, portrait-safe Lunaris field-command framework.

The highest-risk implementation mistake would be treating portrait support as a skinning exercise. The map already supports portrait; the controls do not yet share its safe geometry. The highest-value first step is therefore the new `battle_ui_layout.gd` coordinator plus deterministic 1280×720 and 720×1280 harness states. Once those zones are stable, status, deploy, spells, tutorial, pause, and terminal presentation can be upgraded without reopening gameplay contracts.
