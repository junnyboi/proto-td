# Protos Unified UI Audit

> **Historical technical evidence — not narrative canon.** This document preserves superseded production, localization, visual, screenshot, and regression evidence. Any historical story text, labels, prompts, or approval language shown here is rejected as current lore and must not be used as narrative authority. The sole current narrative authority is [The Anima War canon](../../NARRATIVE_CANON.md).


**Scope:** Six UI families spanning entry, Company Command, campaign navigation, Mission, Training, Premium Resonance, Vahalla, live battle, and Results  
**Audited revision:** `6f382b621c812c29dacfa79a41fe59e19909709c`  
**Engine / reference canvas:** Godot 4.7.2; `1280×720` landscape and `720×1280` portrait gates  
**Change boundary:** Presentation architecture, scenes, UI scripts, presentation resources, localization, assets, and tests only. **Gameplay, simulation, campaign authority, economy authority, durable transaction order, and battle rules are not redesign targets.**

## Executive assessment

Protos has a strong product thesis and a strong behavioral foundation, but not yet a single production UI system. The recorded visual direction for this audited revision was: **premium, unmistakably adult 21+ anime realism; fashion-editorial combat couture; sacred science-fantasy monumentality; near-black and black-blue glass; ivory type; brushed or antique gold structure; restrained moon-cyan state energy; mature portrait crops; and native, scalable controls**.[1] Title, Company Command, and Mission Command already demonstrate meaningful parts of that promise. Campaign state, roster identity, promotion, premium pulls, memorial membership, battle actions, and results are also separated from presentation with unusually disciplined authoritative boundaries.

The principal weakness is continuity. Players repeatedly cross visible quality cliffs: cinematic title and Company Command become a generic centered Stage Select; Mission Command becomes a utility battle HUD; the terminal ceremony becomes a generic Results plate; Premium Resonance—the highest-aspiration collection surface—uses flat equal cards; Training and Vahalla present character-rich systems as administrative forms or lists. Across the six audits, the same structural problems recur:

1. **Three competing UI dialects** coexist: bespoke Staging assets, flat Lunaris operations styling, and rounded Aetheria reading plates/native Godot controls.
2. **Full-safe-area composition is not systematized.** Screens solve layout with local offsets, oversized centered plates, or one outer scroll instead of fixed header/action regions and bounded content owners.
3. **Character art is inconsistently used as product structure.** Approved adult portraits are dominant in concepts but often reduced to small utility crops, absent entirely, or treated as wallpaper.
4. **State semantics depend too heavily on tint, prose, and hover.** Locked, available, selected, ready, planned, premium, fallen, invalid, retry, pity, and destructive states need shared shape, icon, label, and motion rules.
5. **Localization, focus, and reduced motion are incomplete seams rather than global guarantees.** Hard-coded English, missing CJK validation, inert image controls, focusless dialogs, and motion preferences that do not survive scene transitions recur across families.
6. **Portrait support exists but lacks cross-system geometry ownership.** At `720×1280`, map pan, deployment, tutorial, facing, top controls, action docks, soft keyboard, and local scroll regions can compete for the same pixels or gestures.

The recommended program is not a reskin and must not become a gameplay refactor. It is a **feature-preserving presentation consolidation** around five reusable foundations:

- a `LunarisScreenShell` with safe-area header/body/action slots and explicit local scrolling;
- a `LunarisDialogSheet` / `LunarisConfirmSheet` with veil, focus trap/restoration, and Back/Escape parity;
- shared semantic tokens for materials, typography, control roles, state badges, focus, and reduced motion;
- reusable character, roster, route, result, and battle instrumentation components fed only by projections or immutable receipts;
- deterministic responsive, localization, accessibility, navigation, and visual harnesses at both required viewports.

> **Program rule:** UI may format, stage, animate, filter, and navigate authoritative projections. It must never calculate or mutate campaign progression, pull results, promotion legality, death/lives, rewards, placement legality, targeting legality, or battle outcome.

## Historical design principles

The unified direction follows [`docs/ART_DIRECTION.md`][1] and the six family audits.[2][3][4][5][6][7]

| Principle | Unified requirement |
|---|---|
| **Clearly adult character identity** | Every hero depiction is visibly 21+, mature in face, anatomy, posture, styling, and context. No juvenile proportions, school coding, ambiguous-age crops, or infantilizing expressions. |
| **Premium character hierarchy** | Use face, hair, upper couture, signature accessory/weapon, and faction color as the primary portrait information. Character presence must be contextual—selected operator, duty officer, affected casualty, featured premium hero—not decorative wallpaper alone. |
| **Ceremonial science fantasy** | Use lunar rings, sacred geometry, ruined causeways, reliquary mechanisms, memory/gravity motifs, and monumental environments. Technology should read as ritual instrumentation, not generic sci-fi panels. |
| **Material discipline** | Near-black/navy glass supplies mass; ivory supplies readable text; antique/brushed gold supplies structure and commitment; moon-cyan supplies focus, selection, readiness, and live energy; violet supplies depth/memory; crimson is restricted to breach, terminal loss, invalid, and destructive actions. |
| **Angular native controls** | Use protected nine-patch/StyleBoxTexture frames around native Controls and native text. Prefer clipped or `0–6 px` corners; avoid broad rounded utility cards, baked labels, and image-only actions. |
| **Editorial asymmetry** | Prefer a character or mission stage plus an operational rail/inspector. Do not force every family into an identical template, but preserve a recognizable shell, material, type, control, and motion grammar. |
| **Accessible redundancy** | State must be conveyed by label, shape/icon/pattern, and contrast—not color or animation alone. Active targets are at least `44×44`; full logical labels survive abbreviated presentation labels. |
| **Responsive authorship** | Landscape and portrait are distinct compositions. Reflow, local scroll, collapsible regions, and persistent docks replace uniform scale-down and undiscoverable two-axis scrolling. |
| **Motion as enhancement** | Reduced motion produces an equally complete static state. Backdrops, focus pulses, reveal choreography, tutorial pulses, shake, stars, and inertia share one preference seam and stop processing when invisible. |

## Complete screen and state matrix

The matrix contains **79 family-level screen/state entries** from the six audits. Shared surfaces appear more than once when a family imposes a distinct contract on that surface; this preserves traceability rather than hiding cross-family dependencies.

### 01 — Company Command and global staging shell (16)

| ID | Screen / state | Principal gap | Target composition | Non-negotiable preservation |
|---:|---|---|---|---|
| S01 | Boot/loading bridge | Documentation and runtime entry disagree; continuity is not governed as a shell contract | Recorded full-cover Lunaris static art with clean title handoff | Never expose an empty root; retain minimum display/fade and `Game.open_title()` |
| S02 | Lunaris title entry | Strong benchmark but bespoke | Retain cinematic entry; consume shared type, button, backdrop, and dialog primitives | Start campaign route, music behavior, keyboard/controller focus |
| S03 | Title Settings sheet | Behavior is strong but title-local | Reusable `LunarisSettingsSheet` over input-blocking veil | Locale, music, reduced motion, Back/Escape, focus restoration |
| S04 | Company Command — active campaign | Passive standards precede current intent | Next Operation → Mission Control → operations; tertiary affiliations/milestones | View-only campaign projection and all existing child routes |
| S05 | Company Command — no active campaign | Normal-looking empty composition can imply valid campaign | Explicit offline/no-record state with safe actions | Never mutate or fabricate campaign state |
| S06 | Company Command — campaign complete | Normal mission preview falsely implies a next operation | Completion seal, replay callout, distinct copy/art | Replay via Mission Control remains available |
| S07 | Company Command — missing narrative | Error is text-led and weakly discoverable | Corrupted/sealed-record variant with explicit disabled reason | Mission Control disabled, nonfocusable, and unroutable |
| S08 | Company Command — training acknowledgement | Inserted card disrupts hierarchy | Compact one-time acknowledgement banner near Training state | Render committed assignment once, then consume |
| S09 | Company Command — `1280×720` | Standards and repeated progress push actions below an unmarked fold | 72–80 px rail; character stage; fixed first-view command stack | Mission Control, Resonance, Vahalla, Training state, Exit reachable |
| S10 | Company Command — `720×1280` | Top bar is width-tight; bottom sheet hides operations | Compact rail, 35–40% art stage, bottom sheet with visible action grid and scroll cue | Same actions and authority as landscape |
| S11 | Top command/resource bar | Mock economy looks purchasable; Settings/Messages are inert textures | Real Buttons; honest resource source state; overflow/details for hidden stamina | Exit clears active runtime and returns to title; mock wallet stays isolated |
| S12 | Faction standards gallery | Four equal passive cards imply selection and consume priority space | Featured Lunaris affiliation plus three compact archive/allied seals | All four factions intact; Lunaris remains Company Manus active affiliation |
| S13 | Next-operation preview and CTA | Generic tiny pixel panorama for every stage | Stage-specific painterly 16:9 art, location/threat metadata, state variants | First unlocked stage absent from `stage_stars`; narrative guard |
| S14 | Operation tile — Barracks | Lock is mostly tint | Explicit locked badge/reason on shared operation anatomy | Disabled and nonfocusable until implemented |
| S15 | Operation tiles — Resonance, Armory, Vahalla, Training | Inconsistent weight and unclear badge semantics | Icon, operation name, one live metric/status, explicit state badge | Exact routes; Armory locked; Training iff `eligible_count > 0` |
| S16 | Mission Control downstream shell | Generic centered Aetheria plate breaks continuity | Premium expedition shell around unchanged stage projection | Unlocked/locked stage behavior, stars, Back/Escape to Staging |

### 02 — Campaign map, Mission, deploy flow, and Results (9)

| ID | Screen / state | Principal gap | Target composition | Non-negotiable preservation |
|---:|---|---|---|---|
| C01 | Company Command campaign entry/navigation | Flow starts premium but immediately drops quality | Shared Expedition Command handoff | Campaign-preserving routes and safe return |
| C02 | Stage selection / campaign map | Functional two-column text list, not a route | Eight-node celestial/ruined-causeway route plus selected dossier; vertical route in portrait | Sequential unlocks, star projection, selected stage write, Back/ui_cancel |
| C03 | Mission briefing and squad selection | Strong reference, but hard-coded identity and text-heavy selection | Refine existing architecture; stage-derived identity; ordered portrait squad chips | Narrative gate, squad size, ready/fallen rules, filters/search/sort/prefill |
| C04 | Durable campaign launch / deploy transition | No visible commit-pending or rejection feedback | Pending state, duplicate-activation guard, authoritative error sheet | `begin_attempt` durably accepted before publishing squad/opening Battle |
| C05 | In-battle deploy/placement/facing flow | Native rows and color-only overlays break continuity | Responsive Deployment Dock, patterned validity, lunar facing compass | Model validators, operator facing, direct trap release, cancel cleanup |
| C06 | Portrait pan hint and recenter | Competes with deployment/facing and uses legacy styling | Reserved prompt band and shared field-control frame | Exact pan threshold, click suppression, persistence, R recenter |
| C07 | Pause/speed/resign | Utility controls and weak modal behavior | Localized field strip and dimmed confirm sheet | Space, `1×/2×/4×`, pause semantics, prior-speed restoration, one resign action |
| C08 | CLEAR/DEFEAT stamp and Continue | Outcome and Results feel duplicated | First beat of one debrief ceremony; static reduced-motion seal | Only after accepted `record_result`; explicit Continue remains |
| C09 | Victory/defeat Results and routes | Emotionally flat plate, ASCII stars, buried actions, unsafe cancel | Outcome-specific After-Action Reliquary with typed rewards and persistent dock | Full result payload; Retry/Replay, Staging, Training, explicit Title semantics |

### 03 — Roster, Training, promotion, and naming (12)

| ID | Screen / state | Principal gap | Target composition | Non-negotiable preservation |
|---:|---|---|---|---|
| T01 | Mission recruit roster integration | Good data, but dense cards and controls | Shared compact roster states and ordered squad portrait chips | Filters, selection limit, Fallen disabled, selected squad continuity |
| T02 | Training / Operator Advancement landing | Monolithic administrative plate | Full-safe-area Reliquary Atelier: roster rail, hero dossier, inspector, dock | Projection-only eligibility and all origin routes |
| T03 | Selected operator dossier / Field Record | `126×160` portrait is subordinate to forms | Large mature operator stage with continuity, class, XP/lives, status seals | Stable `hero_id`, custom identity, premium/fallen distinctions |
| T04 | Callsign and optional title editor | Naming dominates main inspector | `EDIT FIELD IDENTITY` inspector state/sheet with counters and preview | Authoritative Unicode, trim, uniqueness, control-char, eligibility rules |
| T05 | Rename confirmation modal | Native desktop-tool dialog | Framed responsive review sheet with current/proposed identity | Review before durable commit, one dispatch, errors, focus restoration |
| T06 | Promotion path selection and class comparison | Large vertical cards fail 1/2/5 choices | Compact ceremonial seals plus selected detail compare | Options only from `promotion_options()`; all authored combat facts retained |
| T07 | Multi-operator plan review/confirm | Generic list and competing primaries | Portrait-led old-duty → new-duty rows; one commitment action | Stable hero-ID order, atomic batch, permanence disclosure |
| T08 | Pending promotion-save retry/integrity | Exit lock can look broken | Dominant integrity state with `RETRY SAVE` and disabled rationale | Back/Not Now/ui_cancel blocked; retry pending mutation, no new command |
| T09 | Post-promotion acknowledgement in Command | Destination and consumption are under-explained | Explicit success-destination policy and idempotent banner | Fresh success publishes once; duplicate receipt does not republish |
| T10 | Results training-available prompt | Entry exists but visual continuity is weak | Shared training-ready status and origin-aware action | Only when eligible; Results state survives return |
| T11 | Company Command Training tile | Availability largely tint/prose | `Training · N Ready` badge in standard operation anatomy | Enabled only for positive eligible count |
| T12 | Contextual return to Mission/Results/Command | Only Mission is explicit; success always routes Command | Origin-aware labels and documented completion destination | Review→paths→roster→origin cancel chain; invalid origin safe fallback |

### 04 — Premium Resonance gacha and reveal lifecycle (18)

| ID | Screen / state | Principal gap | Target composition | Non-negotiable preservation |
|---:|---|---|---|---|
| G01 | Company Command Premium Resonance entry | Real Marks are invisible beside mock wallet | Operation metric with authoritative Marks distinction | `RecruitButton`/route and campaign continuity |
| G02 | Idle banner and three-hero pool | Three equal flat cards lack featured thesis | 58–62% mature Lunaris Vessel feature; two 4-star cards/economy rail | Random pool disclosure; no targeting/rate-up implication |
| G03 | Campaign-offline locked | Utility status only | Explicit locked banner state with safe return | No pull command without campaign |
| G04 | Insufficient-Marks locked | Shortfall is functional but weakly integrated | Marks chip, exact shortfall, disabled reason | 40-Mark cost remains authoritative |
| G05 | Attempt-pending locked | Competes with normal idle hierarchy | Clear operation-pending lock state | Pull remains unavailable until attempt resolves |
| G06 | Unacquired/owned/zero-life hero cards | State mostly prose/tint | Featured/compact card variants with seals, lives, copies, locked state | Same persistent hero identity and fixed-kit projection |
| G07 | Pull activation / commit pending | Direct commit has no intentionality check | Confirmation then submit-once alignment state | Command invoked only on Confirm; no reveal before accepted commit |
| G08 | Pre-commit pull confirmation | Missing entirely | Cost, before/after Marks, pity distance, random-pool statement, Cancel/Confirm | Cancel byte-equivalent; stale state yields authoritative rejection |
| G09 | Signal-lock and rarity-charge beats | Stars ignite under transparent parent | Visible phased reticle/filaments and star rail; Skip from frame one | Immutable committed receipt drives presentation |
| G10 | Four-star reveal | Insufficient distinction | Four visible cyan/silver ignitions and unlit fifth cell | Exactly four stars; same result semantics |
| G11 | Natural five-star reveal | Weak must-pull ceremony | Gold-white fifth-star turn, mature hero rise, restrained light sweep | Natural receipt; pity reset from authority |
| G12 | Forced-pity five-star reveal | Text-only guarantee | Guarantee seal and lock-release treatment | `pity_forced` receipt value; gameplay reward unchanged |
| G13 | New-hero outcome | Rich information disappears into status line | Persistent outcome card: NEW HERO, one life, updated guarantee | One persistent fixed-kit hero row |
| G14 | Duplicate LIFE +1 outcome | Gain can be missed off-scroll | Persistent life delta and total on stable identity | Same row gains one life/copy; no duplicate hero row |
| G15 | Zero-life revival outcome | Revival can be confused with duplicate | REVIVED state with restored same identity and memorial consequence | Authority clears death/memorial; UI does not perform revival |
| G16 | Reduced-motion reveal | Immediate state exists but not globally governed | Short opacity transition to identical stable final state | Same receipt, result information, and focus outcome |
| G17 | Post-reveal settled idle | One-line result is too subtle | Outcome sheet closes to updated banner/gallery with deterministic focus | Pull or Back focus fallback; state remains committed |
| G18 | Return to Company Command | Idle keyboard cancel under-specified | Explicit Return and idle `ui_cancel` parity | Preserve UID, revision, Marks, pity, ownership, and progression |

### 05 — Vahalla memorial and loss dialogs (10)

| ID | Screen / state | Principal gap | Target composition | Non-negotiable preservation |
|---:|---|---|---|---|
| V01 | Company Command Vahalla entry | Tile is visually generic | Memorial operation anatomy and fallen metric | Stable `VahallaButton` and `Game.open_vahalla()` |
| V02 | Vahalla populated archive | Flat red card grid feels administrative | Full-viewport fallen rail plus selected memorial dossier | Read-only fallen/memorial projection, Back/ui_cancel |
| V03 | Faction-filtered archive | Icon/count only; rebuild risks focus/scroll | Visible selected-faction summary and stable in-place selection | All + four factions, counts, presentation-only filtering |
| V04 | Empty archive | Functional but visually anonymous | Memorial glyph, concise state, active filter and return | No fake records; filter/Back remain usable |
| V05 | Memorial unhonored/honored variants | Per-card action disappears in scroll; rebuild destroys focus | Sticky selected `HONOR MEMORY`; terminal seal; local honored state | Visit-local idempotence; no campaign write |
| V06 | Squad Selection Fallen dependency | Fallen state shares normal card chassis | Shared memorial veil/seal in roster | Fallen remains inspectable, disabled, nondeployable |
| V07 | Battle terminal defeat + Continue | Detached from loss narrative | Consequence ceremony opening beat | Accepted result gate and explicit Continue |
| V08 | Results casualty/life-loss summary | Ordinary deaths absent; premium IDs/raw English used | Casualty Ledger with callsigns, ordinary loss, reserve spend, lockout | Exact authoritative IDs/lives/memorial membership |
| V09 | In-battle Resign confirmation | No scrim/focus trap/cancel parity | `LunarisConfirmSheet`, Cancel default | Pause, exact speed restore, one resign, ui_cancel-to-Cancel |
| V10 | Premium duplicate-pull revival dependency | Cross-family consequence is not clearly explained | Memorial tolerates removal; premium dossier explains same-identity restoration | Same hero restored; ordinary death never presented as purchasably revivable |

### 06 — Battle HUD, tutorials, pause, placement, and feedback (14)

| ID | Screen / state | Principal gap | Target composition | Non-negotiable preservation |
|---:|---|---|---|---|
| B01 | Live battlefield and status HUD | One clipped debug-like label with raw tick | Core Integrity, DP, wave/kills, battle-state cluster in compact command rail | Snapshot-only projection; no fabricated totals |
| B02 | Operator/trap deployment tray | Default buttons; portrait mode becomes tall stack | Fixed-height portrait-forward operator tray; tools group; measured bounds | `is_deployable`/`is_trap_placeable`, unlocked loadout only |
| B03 | Placement validity/hover | Color floods flatten terrain and exclude color-vision redundancy | Sparse outline + glyph/pattern for operator, trap, Mend, invalid | `can_deploy_at`/`can_place_trap_at` and authoritative target validity |
| B04 | Four-direction facing chooser | Attractive arrows float without context or real safe geometry | Lunar compass, Choose Facing, range preview, touch Cancel | Every arrow legal; cardinal mapping and action verb unchanged |
| B05 | Selected unit, skill, Mend, retreat | Tiny SP blink and isolated destructive Retreat | Selected-operator chip with portrait, HP/SP, skill state, explicit target/retreat | Unit readiness, HealingRules, trigger/mend/retreat actions |
| B06 | Spell bar and targeting | Weak cooldown/once-wave status; resolved enemy invisible | Engraved spell seals, READY/USED/NEXT WAVE, target prompt/reticle | Empty loadout empty; CELL/ENEMY and lowest-ID resolution unchanged |
| B07 | Pause/speed/resign controls | Bare controls and `FOCUS_NONE` weaken accessibility | Localized focusable field controls or pause sheet | Space parity, speed cycle/unpause, exact prior-scale behavior |
| B08 | Resign confirmation | Utility panel over active HUD | Dimmed destructive sheet with focus trap and Cancel default | One `resign` action, ui_cancel, focus/speed restoration |
| B09 | First Stand tutorial | Rounded card collides with controls | Astral Field Manual in reserved zone; collapsed live reminder | Conditional s1 flow, simulation hold, step gates, rejection/cancel recovery |
| B10 | Portrait map-navigation hint/recenter | Fixed offsets and unsupported glyph risk | Reserved map-safe prompt band, shipped icons, touch/controller parity | Pan, inertia, suppression, persisted hint, R recenter |
| B11 | Transient wave/leak/damage/skill/trap/charm/placement feedback | Mixed arcade and Lunaris dialect; no global motion seam | Shared banner/toast/target-prompt hierarchy and restrained effects | One-shot observed edges; approved placement SFX/emitter profiles |
| B12 | Terminal CLEAR/DEFEAT + Continue | Pixel band and plain button split ceremony | In-field result crest, stars, styled Continue, reduced-motion static state | `record_result` acceptance and manual continuation |
| B13 | After-action Results | Centered plate, buried actions, weak consequences | Full-viewport asymmetric debrief with local body scroll and fixed dock | Complete `Game.last_result` projection and routes |
| B14 | Tooltips, prompts, rejection feedback, transient dialogs | Hover-centric, inconsistent, often hard-coded | Shared accessible tooltip, target prompt, toast, modal roles | Never infer rejection reasons outside authoritative APIs |

## Cross-cutting design-system gaps

### 1. Shell and spatial architecture

The project lacks a premium shell that can carry full-viewport art, safe gutters, responsive body regions, and persistent actions. `AetheriaScreenShell` has useful mechanical behavior but its centered reading plate, broad padding, and rounded material are not the final Lunaris language. Bespoke screens repeatedly recreate headers, modal layers, scrolling, and focus.

**Requirement:** introduce a premium shell without deleting useful mechanical layout behavior. Every major screen declares one header region, one action region, explicit content owners, and safe-area insets. No critical exit or commitment action may live at the bottom of an unbounded outer document.

### 2. Material and geometry tokens

Generated staging frames exist, including primary and operation frames, but live controls often use `StyleBoxFlat`. Flat Lunaris Ops, rounded Aetheria, native Godot defaults, and staging nine-patches each define different corners, padding, focus, and disabled behavior.

**Requirement:** establish semantic roles—shell, rail, inspector, dossier, primary, secondary, destructive, operation available/locked, status seal, resource chip, dialog, selected row, terminal state, focus ring—then map them to scalable texture or flat fallbacks. Ornament must not intercept input or contain runtime text.

### 3. Typography and localization

Cinzel-led display type is present in Staging but absent or inconsistent in Training, Gacha, Vahalla, Battle, and Results. Numerous labels, faction identities, statuses, death reasons, battle controls, and gacha outcomes are hard-coded English. Cinzel has no CJK glyph coverage.

**Requirement:** centralize display/body/detail/action roles in `game_typography.gd`; use Cinzel only where the composite fallback is valid; use the CJK-capable body face for Simplified Chinese and long operational copy; move all player-facing strings through `UiCopy` and authoritative runtime `en-US`/`zh-CN` catalogs with placeholder parity.

### 4. State grammar

Available/locked/new, selected/ready/planned, premium/fallen, valid/invalid, commit pending/retry, ordinary death/premium reserve loss, four-star/five-star/forced pity, and clear/defeat are family-local treatments. Tint and prose do too much work.

**Requirement:** each semantic state receives a stable combination of **label + icon/shape/pattern + contrast**, with motion as optional reinforcement. Gold is structure/commitment, cyan is live state/focus/selection, crimson is limited to terminal/invalid/destructive, and disabled content remains readable with a visible reason.

### 5. Character-art integration

The audited adult 21+ art direction is a retained production constraint, but several high-value screens lack character presence or use small undifferentiated portraits. Gacha's featured Vessel crop needs a maturity review; portrait reflow can crop faces, weapons, and couture unsafely.

**Requirement:** add focal metadata or approved dedicated crops; prioritize mature face, hair, upper costume, signature equipment, and faction material; use character art to communicate current operator, squad, casualty, or premium identity. Preserve tactical chibis on the field while reasserting adult identity in trays and inspectors.

### 6. Navigation, modal, and focus behavior

Inert TextureRects, `FOCUS_NONE` controls, destroyed focus after rebuild, unsafe `ui_cancel` routes, and inconsistent initial focus recur. Dialogs do not share focus trapping or restoration.

**Requirement:** use native Buttons for actions; define deterministic initial focus, cyclic focus graphs, disabled-control skipping, focused-item local scrolling, modal containment, and restoration. Back/Escape must match a visible action. Destructive Title exit from active Results requires explicit product confirmation rather than an invisible cancel shortcut.

### 7. Reduced motion and processing

Title owns a preference, but Staging can restart animation and battle/reveal effects do not share it. Some focus pulses redraw every frame even off-screen.

**Requirement:** one shared preference initializes every backdrop and motion director. Static state must preserve selection, validity, readiness, rarity, and outcome. Process only while visible and active; kill tweens on exit.

### 8. Economy and truthfulness

Company Command's mock wallet uses plus affordances while real Marks appear only inside Gacha. This risks misleading purchase semantics.

**Requirement:** mark presentation-only values honestly or remove them from production; remove plus/purchase cues; surface authoritative Marks distinctly near Resonance; never make UI scaffold spendable, persistent, or progression-bearing.

### 9. Input and touch parity

Hover tooltips, unsupported Unicode arrows, desktop shortcuts, portrait map pan, drag deployment, dock scrolling, and soft keyboard behavior are unresolved as one input system.

**Requirement:** native accessible names, visible selected captions, touch details affordances, shipped glyph assets, `44×44` targets, explicit gesture ownership, and post-drag click suppression. Shortcuts remain supplemental.

## Preserved-feature ledger

| Domain | Feature contract to preserve | Presentation-safe change | Prohibited change |
|---|---|---|---|
| Architecture | UI projects authoritative `Game`, campaign, model, and receipt state | View models, formatting, component decomposition | UI-owned progression, rewards, legality, pity, death, or economy |
| Staging | Next operation is first unlocked stage missing from `stage_stars` | New art, metadata, complete/offline/corrupt variants | Different stage-selection rule |
| Staging | Missing narrative disables and unfocuses Mission Control | Strong disabled state and reason sheet | Fallback narrative that authorizes deployment |
| Navigation | Mission Control, Resonance, Vahalla, Training, Exit retain exact routes | Shared shell and clearer origin labels | Bypassing `Game` route bridges |
| Exit | Company Command Exit returns to title and clears active runtime state | Confirmation/presentation | Quitting application or preserving an invalid active session |
| Locked operations | Barracks and Armory disabled/nonfocusable | Explicit lock badges/reasons | Making them appear or behave actionable |
| Mock wallet | Deterministic, nonpersistent, nonspendable, nonpurchasable | Honest source labeling or removal | Purchase/spend/progression behavior |
| Factions | Four stable factions; Lunaris is active Company Manus affiliation | Compact affiliation/archive rail | Implied selection without authority or save changes |
| Settings | Modal blocking, locale, music, reduced motion, Back/Escape, focus restoration | Shared sheet extraction | Loss of input containment or preference persistence |
| Campaign map | Sequential unlock; locked nodes visible/disabled | Spatial route and dossier | Unlock inference in view |
| Stage route | Enabled stage sets `selected_stage_id`, then opens Squad Select | New node component and focus graph | Mutation from locked activation |
| Mission | Narrative required; ≥1 ready hero; max `squad_size`; Fallen disabled | Portrait chips, compact filters, launch status | Local squad legality or fabricated readiness |
| Identity | `hero_id` stable; callsign/title/class/faction/portrait/premium lives survive | Shared dossier/card presentation | Keying by display name or list index |
| Launch | Durable `begin_attempt` accepted before squad publication/Battle | Commit-pending and rejection UI | Optimistic scene transition |
| Attempt recovery | Pending attempts resume with trusted ticket/squad | Resume presentation | Rebuilding ticket from UI |
| Training origins | Mission/Results/Staging return paths and state survive | Explicit labels and documented success policy | Silent origin loss |
| Filtering | Active/Fallen, factions, query, sort, counts, empty state | Collapsed filter UI | Save/hash mutation or clearing valid selected squad |
| Naming | Unicode/trim/length/control/uniqueness/eligibility validation, review, durable receipt | Responsive identity sheet | UI reimplementation of validation |
| Promotion | Options data-driven; local multi-hero draft; stable ordering; atomic/idempotent commit | Seal/compare view and review rows | UI-generated paths or partial batch mutation |
| Save retry | Pending mutation blocks every exit; Confirm retries same mutation | Integrity state and focused Retry | New command or bypassed exit lock |
| Premium heroes | Fixed kit, no XP/training/rename; stored lives | Clear seals and life pips | Ordinary progression or local life edits |
| Gacha | 40 Marks; three identities; 2/40 sole 5-star; 19/40 each 4-star; hard tenth pity | Confirmation and receipt-driven ceremony | Local roll, pity, selection, charge, grant, or revival |
| Gacha reveal | Reveal only after accepted commit; input lock; one visible Skip; same final receipt | Phased director and reduced-motion path | Pre-commit reward or presentation-dependent result |
| Premium lifecycle | First copy one row; duplicate +1 same row; zero-life duplicate restores same hero/removes memorial | Distinct NEW/LIFE +1/REVIVED outcome | New duplicate hero row or UI memorial edits |
| Memorial | Fallen derived from dead status/death record; ordinary death permanent | Dossier and authored stage/reason copy | Revive implication for ordinary dead |
| Honor | Visit-local, idempotent, nonpersistent | In-place update and focus preservation | Campaign write without separate feature approval |
| Premium loss | Life spent while remaining = Ready; final life = Dead/0/memorial; pull can restore | Casualty Ledger | Treating every premium fall as death |
| Battle actions | Deploy/trap/spell/skill/Mend/retreat/resign use validators and `apply_action` | New controls and feedback | Duplicated rules or direct state mutation |
| Loadout | Empty spell loadout remains empty; only validated IDs exposed | Better empty/tool group state | Show-all sentinel |
| Placement | Operator valid drop → facing; trap valid release → direct place; invalid/cancel cleanup | Patterned geometry and prompts | Changed verb ordering |
| Targeting | CELL/ENEMY semantics and lowest-ID valid enemy resolution | Resolved-target reticle | Alternate local target selection |
| Pause | `ticks_per_frame_scale`; Space; `1×/2×/4×`; speed unpauses; resign restores exact scale | Focusable controls/modal | Model pause command or scale drift |
| First Stand | Conditional uncleared s1 flow, holds time, gates steps, restores all interactions | Field Manual styling | Different campaign criterion without product decision |
| Camera | Portrait rotation/height-fill/base boot/pan/threshold/suppression/inertia/recenter; landscape touch | Reserved prompts and safe zones | Broken gesture arbitration or advertised unsupported zoom |
| Facing | Four arrows map cardinal to screen diagonals; every direction legal | Compass/range preview | Disabling tutorial-nonrecommended directions |
| Feedback | Ground/elevated deployment effects and one-shot event cues remain presentation-only | Visual polish/reduced motion | Simulation mutation or repeated event emission |
| Results gate | Terminal UI/Results only after accepted `record_result`; Continue explicit | Unified ceremony | Automatic or pre-acceptance transition |
| Results payload | Stars, kills, leaks, rewards, Marks, entitlements, XP, lives/lockout, consequence, routes | Typed cards and fixed dock | Dropped data or UI-computed rewards |
| Localization | English/Chinese key and placeholder parity; CJK fallback | Expanded catalogs and typography | Baked translated text in frames |
| Accessibility | Native text, logical labels, visible focus, `44×44`, cancellation parity | Better focus graphs/tooltips/touch info | Image-only controls or color-only state |
| Automation | Stable handles such as `MissionControlButton`, `RecruitButton`, `VahallaButton`, `TrainingButton`, `ExitButton`, `ContinueButton` | Internal visual children and adapters | Unnecessary handle churn without aliases/tests |

## Responsive requirements

### Global layout contract

1. Treat `1280×720` and `720×1280` as authored compositions, not scale endpoints.
2. Add a safe-inset abstraction for native, Web, 18:9/20:9, and browser-canvas offsets; do not rely on undeclared project stretch behavior.
3. Keep header and primary action dock inside the safe viewport. Scroll only the route, roster, inspector, dossier body, gallery, or debrief body that owns overflow.
4. Avoid nested uncontrolled vertical scroll regions. Every screen documents its scroll owner and focus-to-scroll behavior.
5. Preserve at least `44×44` active targets and full logical labels; shorten only presentation labels.
6. Use aspect plus width/height layout classes rather than width-only portrait switches.
7. Verify native text expansion in `en-US` and `zh-CN`, including long callsigns/titles, class descriptions, loss copy, premium outcomes, and errors.
8. Use focal metadata/dedicated crops so portrait mode retains mature faces, hair, upper costume, and signature equipment without accidental sexualization.

### `1280×720` landscape gates

| Requirement | Acceptance gate |
|---|---|
| First-view priority | Company Command shows Next Operation, Mission Control, Resonance, Vahalla, Training state, and Exit without discovering a hidden fold. |
| Fixed actions | Mission, Training, Gacha, Vahalla, and Results commitment/return actions remain visible while variable body content scrolls. |
| Full-safe-area shells | Stage route+dossier, Atelier, archive, Gacha, and Results use the viewport rather than increasing centered plate minimums. |
| Battle zone ownership | Status, spells, pause, tutorial, deploy tray, navigation, targeting, facing, and terminal overlays consume measured reserved rectangles. |
| Dense payloads | Six heroes plus tools; five training paths; maximal Results rewards/losses; long bilingual copy do not overlap or push actions away. |
| Texture density | Nine-patch protected margins and optical-size 38–52 px icon derivatives are validated at actual scale. |

### `720×1280` portrait gates

| Requirement | Acceptance gate |
|---|---|
| One-axis navigation | Campaign route is vertical; no undiscoverable two-axis campaign-map pan. Battlefield pan remains its distinct tested system. |
| Compact top rails | Identity, one critical metric/economy chip, and Back/Exit fit without a three-row utility header. |
| Persistent docks | Primary/return actions remain bottom-safe while body, roster, route, or ledger scrolls. |
| Bounded selection | Training uses compact roster carousel/rail and tabbed inspector; Vahalla uses one selected dossier plus one scroll owner; Gacha features the five-star before its secondary pool. |
| Battle visibility | Deploy tray is horizontal/two-row/collapsible, never an unbounded one-column stack; facing and pan hints reserve actual tray bounds. |
| Gesture arbitration | Dock scroll cannot pan map; active deployment/targeting blocks map navigation; slow drags around the 10 px threshold and release outside controls are tested. |
| Soft keyboard | Search and naming fields scroll into view, permit keyboard dismissal, and restore actions/selection after close. |
| Touch parity | Back, Skip, faction filters, recenter, Cancel, and modal actions meet `44×44`; hover-only information has a touch route. |

## Component strategy

### Foundation components

| Proposed component | Responsibility | Consumers |
|---|---|---|
| `LunarisScreenShell` | Safe insets; background/scrim; header/body/action slots; landscape/portrait modes; explicit scroll hosts | Staging, Stage Select, Mission, Training, Gacha, Vahalla, Results |
| `LunarisActionDock` | Persistent safe-bottom actions; one-primary policy; compact portrait stacking | Mission, Training, Gacha, Vahalla, Results |
| `LunarisDialogSheet` | Veil, angular sheet, title/icon, focus trap/restoration, Back/Escape, resize clamp | Settings, identity review, launch errors, gacha confirmation, integrity errors |
| `LunarisConfirmSheet` | Safe-default Cancel, destructive hierarchy, submit-once state | Resign, campaign exit, pull confirmation, promotion confirmation |
| `LunarisMotionPolicy` | Shared reduced-motion read, static alternatives, visibility processing, tween cleanup | Backdrops, focus, route, Gacha, Battle, terminal/results |
| Semantic skin/token layer | Material, spacing, corner, typography, focus, disabled, badge, danger, rarity, terminal roles | All families |
| `UiCopy` typed catalog | Stable bilingual keys, placeholder schemas, fallbacks, accessible names | All families |

### Navigation and campaign components

| Proposed component | Responsibility | Authority input |
|---|---|---|
| `CampaignRouteNode` | Locked/available/next/cleared/replay, real star icons, logical label | Stage projection and `stage_stars` |
| `MissionDossier` | Objective, threat, squad limit, hint, reward preview, briefing action | Stage and narrative resources |
| `StagePreviewCard` | Stage-specific 16:9 art, location/threat, offline/complete/corrupt variants | Presentation-only preview catalog |
| `OperationCard` | Optical icon, operation, one metric/status, state badge | Existing campaign projections only |
| `AffiliationRail` | Active Lunaris standard plus passive allied/archive seals | Stable faction presentation metadata |

### Character, roster, and consequence components

| Proposed component | Responsibility | Shared use |
|---|---|---|
| `OperatorPortraitFrame` | Approved crop/focal metadata, rarity/faction/status overlays, accessible identity | Mission, Training, Gacha, Vahalla, Battle, Results |
| `RosterFilterBar` modes | Active/Fallen, All+four factions, visible selected caption, compact drawer | Mission, Training, Vahalla |
| `DeploymentOperatorCard` | Callsign/title, class/faction, DP, premium lives, fallen, selected order | Mission and Battle variants |
| `OperatorDossier` | Stable personhood, field record, current duty, XP/lives, readiness | Training and Vahalla variants |
| `PromotionPathSeal` / compare | 1/2/5-choice summary and selected details | Training |
| `TrainingPlanRow` | Portrait, callsign/title, old→new duty, edit, reconciliation | Training review |
| `MemorialRosterRow` / `MemorialDossier` | Stable `hero_id` selection, terminal record, Honor | Vahalla |
| `CasualtyLedger` | Ordinary death, premium life spent, premium lockout using actual callsigns | Results and Vahalla flow |
| `ResultRewardCard` / `ResultOperatorRow` | Typed rewards, XP, life/fallen effects | Results |

### Premium Resonance components

| Proposed component | Responsibility | Constraint |
|---|---|---|
| `PremiumHeroCard` | Featured/compact variants; catalog and owned-state projection | No selection/transaction behavior |
| `PremiumGuaranteeTrack` | Ten cells, numeric distance, forced-next, accessible state | Projection values only |
| `PremiumPullConfirmation` | Cost, before/after, guarantee, random-pool disclosure | Emits cancel/confirm only |
| `PremiumRevealDirector` | Receipt-driven phases, Skip/finalize, reduced motion, tween cleanup | Never calls campaign mutation |
| `PremiumOutcomeSheet` | NEW HERO / LIFE +1 / REVIVED and updated guarantee | Immutable receipt plus refreshed projection |

### Battle instrumentation components

| Proposed component | Responsibility | Constraint |
|---|---|---|
| `BattleUiLayout` | Publishes measured safe rectangles and z-order for all battle UI | No battle rules |
| `BattleStatusCluster` | Core Integrity, DP, wave/kills, state | Snapshot projection only |
| `DeploymentDock` | Fixed-height operator/tool trays and actual measured bounds | Existing validators/signals |
| `PlacementOverlayStyle` | Sparse pattern/glyph geometry for operator/trap/Mend/invalid | Consumes validity, does not calculate it |
| `SelectedOperatorChip` | Identity, HP/SP, skill state, target/retreat actions | Existing unit/action APIs |
| `SpellSeal` / `BattleTargetPrompt` | Cooldown/usage/target state and resolved reticle | Existing cast validity/target resolution |
| `BattleTooltip` / toast / banner | Mouse, focus, touch parity and safe-edge placement | Authoritative reason only; generic fallback otherwise |
| `TerminalCeremony` | CLEAR/DEFEAT, stars, Continue, reduced-motion static state | Appears only after accepted result |

## Prioritized implementation phases

### Phase 0 — Contract freeze and regression harnesses

**Goal:** make visual iteration safe before replacing components.

- Record stable route/node handles and authoritative seams in tests.
- Add focused tests for staging states/navigation, stage unlocking, Mission selection, launch transaction, Training draft/retry/origins, gacha confirmation/reveal, memorial identity/loss, battle actions/pause/tutorial, and Results routing.
- Create deterministic capture harnesses at `1280×720` and `720×1280`, `en-US` and `zh-CN`, normal and reduced motion.
- Reconcile `README.md` with the actual `loading.tscn` project entry.
- Make an explicit product decision on player-facing **Vahalla/Valhalla** spelling while retaining stable identifiers unless separately migrated.
- Make explicit decisions for Training success destination and Results `ui_cancel`/Title-exit safety; tests must encode the approved behavior.

**Exit gate:** existing simulation and focused UI tests remain green; new harnesses can reproduce all critical state variants without modifying gameplay code.

### Phase 1 — Shared Lunaris foundations

**Goal:** remove systemic duplication before family redesign.

- Implement semantic skin/type tokens, `LunarisScreenShell`, `LunarisActionDock`, `LunarisDialogSheet`, and shared motion policy.
- Extract the title Settings sheet as the first dialog consumer; wire Company Command Settings to it.
- Centralize focus trap/restoration, initial focus, cancel parity, local focus scrolling, and `44×44` targets.
- Expand `UiCopy`, `en-US`, and `zh-CN`; establish placeholder and CJK fallback tests.
- Define safe-inset/layout classes and aspect-aware landscape/portrait switching.
- Apply approved nine-patch frames to native controls; add optical-size icon derivatives/import validation.

**Exit gate:** Settings works identically from title and staging; shell/dialog tests pass at both viewports/locales; reduced motion persists across title→staging.

### Phase 2 — Entry, Company Command, and campaign navigation

**Goal:** fix the first quality cliff and establish the expedition shell.

- Reorder Company Command around Next Operation, Mission Control, and operation grid.
- Replace standards gallery with affiliation rail; remove mock purchase cues; add honest overflow/details.
- Add stage-specific preview catalog and explicit no-campaign/complete/missing-record variants.
- Replace Stage Select list with responsive route+dossier while preserving unlock/routing logic.
- Correct Mission's stage-derived identity, localization, selected portrait chips, and launch pending/error presentation.

**Exit gate:** active/offline/complete/corrupt/training-ready states pass; all eight missions and route states are reachable; no first-view critical action is hidden.

### Phase 3 — Training, roster identity, Vahalla, and consequence ledger

**Goal:** consolidate shared character and lifecycle presentation.

- Build compact roster/filter modes, reusable portrait/status frames, Training dossier/inspector, identity sheet, path seals, and plan rows.
- Prove one, two, and five path choices; preserve atomic plans, stale reconciliation, and retry lock.
- Rebuild Vahalla as fallen rail + selected dossier with stable `hero_id`, focus, and scroll.
- Add localized terminal-reason/stage-title mappings and Results `CasualtyLedger` using actual callsigns.
- Restyle resign through the shared confirm sheet.

**Exit gate:** Mission↔Training and Results↔Training preserve state; naming/promotion authority tests pass; ordinary death, premium reserve spend, premium lockout, and revival remain distinct.

### Phase 4 — Premium Resonance

**Goal:** make the premium collection surface equal to the product promise.

- Recompose Gacha as featured mature 5-star banner plus compact 4-star/economy rail.
- Add authoritative Marks presentation and ten-cell guarantee track.
- Add pre-transaction confirmation and submit-once pending state.
- Implement receipt-only reveal director with visible star charge, forced guarantee seal, frame-one Skip, reduced-motion equivalence, and persistent outcome sheet.
- Re-approve or replace the Lunaris Vessel crop through the approved adult 21+ art-production pipeline.

**Exit gate:** confirmation cancel does not mutate state; rejected commits never reveal; 4-star/natural 5-star/forced 5-star and NEW/LIFE +1/REVIVED are deterministic and localized.

### Phase 5 — Battle field-command layer and debrief

**Goal:** replace local offsets and default controls without changing action semantics.

- Introduce `BattleUiLayout` and measured reserved rectangles.
- Componentize HUD, deployment tray, spell deck, selected operator, target prompts, pause/resign, tutorial, and navigation controls.
- Replace color-only placement/target feedback with sparse patterned geometry.
- Clamp facing/tutorial/navigation against actual measured zones and safe insets.
- Preserve ground/elevated effects while adding one reduced-motion seam.
- Join terminal and full-viewport Results into one debrief sequence with fixed actions and typed rewards/consequences.

**Exit gate:** all validator/action tests pass; six-hero+tools portrait battle remains visible; tutorial, facing, pan, target modes, and controls never overlap at target gates.

### Phase 6 — Localization, accessibility, visual polish, and shipping hardening

**Goal:** prove the system rather than relying on isolated screenshots.

- Run bilingual visual matrices for every listed screen/state and maximum payload.
- Verify focus topology with keyboard/controller, touch targets, touch details routes, and focus restoration after rebuild/modal close.
- Validate native/Web glyphs, safe insets, compact landscape, and exported real-window behavior.
- Profile idle redraw, hidden animation, backdrop decode/stop, tween cleanup, and battle overlay density.
- Perform final art review for mature 21+ identity, safe crops, coherent weapons/hands, material separation, and no accidental sexualization.

**Exit gate:** headless import and 120-frame runtime baseline pass; focused tests pass; deterministic captures have no clipping/overlap/missing glyphs; feature ledger is signed off.

## Test and acceptance program

The family audits contain detailed file-level test targets. At program level, acceptance requires the following matrix:

| Gate | Required coverage |
|---|---|
| **Authority** | Byte-equivalent or explicit projection checks before/after presentation-only cancel, filter, Honor, Skip, reduced motion, and dialog operations |
| **Navigation** | Every entry, Back, `ui_cancel`, child return, retry/replay, Training origin, Results route, and destructive exit |
| **Transactions** | Begin-attempt, rename, promotion, pull, and result acceptance: pending, accepted, rejected, duplicate activation, idempotent replay, durable retry |
| **Responsive** | Exact `1280×720` and `720×1280`; compact landscape guard; safe containment; fixed docks; local scrolling; max payload |
| **Localization** | `en-US`/`zh-CN` key and placeholder parity; no hard-coded operational copy; no missing glyphs; CJK fallback and wrapping |
| **Accessibility** | Initial focus, cyclic order, disabled skipping, modal trap/restore, visible focus, non-color-only states, `44×44`, logical labels, touch alternatives |
| **Motion** | Normal/reduced-motion equivalence; preference survives scene transitions; critical information remains static; hidden/inactive processing stops |
| **Visual** | Adult 21+ art review; face/weapon/costume crop safety; material/type consistency; stage-specific art; rarity and consequence differentiation |
| **Runtime** | `tools/run_godot_isolated.sh --headless --import` and `tools/run_godot_isolated.sh --headless --fixed-fps 60 --quit-after 120`, then every focused SceneTree test through `tools/run_godot_test.sh` |

## Critical patterns requiring program-level ownership

1. **Authoritative projection boundary:** redesign views and input adapters, never the rules they display or invoke.
2. **Full-safe-area shell with persistent actions:** eliminate oversized centered plates and hidden critical actions.
3. **Measured battle layout zones:** replace local offsets with one safe-region coordinator, especially in portrait.
4. **Character-forward adult 21+ hierarchy:** make selected, featured, deployed, and affected heroes visually meaningful with approved mature crops.
5. **One semantic material/state system:** engraved angular native controls, explicit badges, non-color-only patterns, and restrained gold/cyan/crimson roles.
6. **Bilingual accessibility as architecture:** catalog-backed copy, CJK fallback, native logical labels, focus containment/restoration, touch parity, and `44×44` targets.
7. **Shared reduced-motion lifecycle:** preference persistence, static equivalence, visibility-aware processing, and tween cleanup.
8. **Truthful economy and consequence presentation:** distinguish mock resources from Marks; ordinary death from premium life spend/lockout; duplicate from revival.
9. **Transaction-aware presentation:** pending, rejection, retry, and submit-once states around durable launch, rename, promotion, pull, and result boundaries.
10. **Deterministic responsive visual QA:** both target viewports, both locales, maximum payload, exceptional states, and reduced motion before visual sign-off.

## Conclusion

Protos does not need new gameplay to achieve a substantially stronger UI. It needs a disciplined presentation program that treats its existing model boundaries as immutable assets. The highest-return work is to establish the shared shell, dialog, typography, state, focus, localization, and motion systems first; then migrate the most visible continuity breaks—Company Command→Stage Select, Mission→Battle, terminal→Results—before completing the character workspaces, premium reveal, and battlefield instrumentation.

Success means the player experiences one authored Lunaris product across all 79 audited screen/state entries while every existing unlock, route, transaction, lifecycle, camera, combat, and result contract remains intact.

## References

[1]: ../../ART_DIRECTION.md "Protos visual art direction"
[2]: audits/01-staging.md "Audit 01 — Company Command and global staging shell"
[3]: audits/02-campaign.md "Audit 02 — Campaign map, Mission, deploy flow, and Results"
[4]: audits/03-training.md "Audit 03 — Roster, Training, promotion, and naming"
[5]: audits/04-gacha.md "Audit 04 — Premium Gacha and reveal lifecycle"
[6]: audits/05-vahalla.md "Audit 05 — Vahalla memorial and loss dialogs"
[7]: audits/06-battle.md "Audit 06 — Battle HUD, tutorials, pause, placement, and feedback"
