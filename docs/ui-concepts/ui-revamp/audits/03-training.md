# UI Revamp Audit 03 — Roster, Training, Promotion, and Naming

**Audit family:** Recruit roster, roster filters, operator dossier, training and promotion paths, promotion confirmation, custom naming, and contextual return flows  
**Repository revision:** `6f382b621c812c29dacfa79a41fe59e19909709c`  
**Target viewports:** `1280×720` landscape and `720×1280` portrait  
**Authority boundary:** This audit proposes presentation and interaction-system changes only. Campaign state, promotion legality, renaming validation, deterministic command receipts, save integrity, and battle rules remain model-owned.

## 1. Executive assessment

This family is **functionally mature but visually split between two generations of Protos UI**. It already preserves unusually strong progression contracts: authoritative path eligibility, atomic multi-operator promotion plans, stale-draft reconciliation, durable-save retry, ordinary-versus-premium rules, active/fallen and faction filters, callsign/title customization, keyboard focus cycling, and three contextual origins. The current controller is therefore a valuable feature baseline, not a disposable prototype.[1][2]

The approved Recruit Training concept and current art direction call for a **character-forward, adult 21+ luxury anime-gacha atelier**: a compact recruit rail, a large selected operator, a distinct advancement inspector, ceremonial lunar machinery, Cinzel-led hierarchy, restrained gold, and cyan reserved for state.[3][4] The runtime instead places almost every function inside one generic, centered, scrollable reading plate. Its flat `StyleBoxFlat` surfaces, small selected portrait, utility-first filters, native confirmation dialog, and two-column roster/inspector composition make the screen read as a competent administrative tool rather than a premium operator advancement experience. The visual system also stops short of the textured frames and Cinzel-with-CJK-fallback skin already implemented for Company Command.[5]

The most important redesign decision is to **keep the controller contracts while decomposing the view**. At landscape, the roster should become a compact rail, the selected operator should own the visual center, and progression/naming should move into a focused right inspector. At portrait, these regions should become a shallow roster selector, hero dossier, and tabbed or segmented inspector above a genuinely persistent action dock. Promotion path selection and plan review should use the same shell and identity anchor instead of turning into generic long-form pages.

There is also a contextual-flow inconsistency that requires an explicit product decision. `Not Now`, `ui_cancel`, and `RETURN TO MISSION` return to the recorded origin, but a successful promotion always opens Company Command so that its acknowledgement card can be consumed.[1][2] A revamp must either preserve this as a deliberate **completion destination contract** and say so before confirmation, or carry the acknowledgement back to Mission/Results. Silently changing it would be a behavior regression; leaving it unexplained remains a UX defect.

## 2. Sources reviewed

The audit reviewed the project configuration and product documentation; the approved Recruit Training concept image; the live training and mission scenes; shared shell, style, typography, button, label, faction, roster, dossier, path-card, and projection code; contextual entry points in Mission, Results, and Company Command; promotion and naming authorities; class resources; premium lifecycle documentation; and existing focused tests.[1]–[17]

The authored class graph is broader than the two-path composition shown in the concept. A basic Recruit can currently choose among **Defender, Gunner, Mage Apprentice, Shock Trooper, and Swordmaster** at 100 XP. Standard classes promote at 400 XP into one or two entitlement-gated advanced classes; Mage Apprentice is the only current two-way advanced branch, into Sorcerer or Witch Doctor.[8] The redesign must therefore handle one, two, and five legal choices without treating the concept’s two seals as a fixed data shape.

## 3. Screen and state inventory

| Surface or state | Entry and exit | Current content | Functional interactions that must remain visible or reachable |
|---|---|---|---|
| **Mission recruit roster** | Mission opens from stage selection; `TRAIN OPERATORS` records origin `mission`; Back returns to stage selection | Active/Fallen tabs, All + four faction symbols, name/title query, recruitment/name sort, portrait cards, class, DP, premium lives, squad count, selected names | Filter and sort; select/deselect ready heroes up to squad limit; inspect Fallen as disabled; open Training without losing selected stage/squad context; deploy; Back |
| **Training roster / advancement landing** | From Company Command, Results, or Mission; unsupported campaign redirects to Company Command | Atelier header, promotion-ready count, roster filters, query/sort, scrollable rows, selected inspector, naming controls, XP/premium status, permanence copy, three-action footer | Select row; switch Active/Fallen and faction; search by callsign/title; sort; rename eligible recruit; open paths; review an accumulated plan; leave to origin |
| **Selected operator dossier** | Embedded in Training roster | Small portrait, callsign, optional title, class, continuity line, XP or premium lives/fixed-kit state, field record, eligibility, permanence warning | Maintain selected identity across refreshes; distinguish ordinary, premium, ready, fallen, promotable, planned, and locked states |
| **Custom naming editor** | Embedded at top of selected inspector | Callsign and optional title fields, guidance, Review action, inline error; locked copy for premium or non-ready heroes | Validate while typing; trim; review changed identity; submit by Enter; open confirmation; cancel to field; commit; show authoritative errors; refresh all projections |
| **Rename confirmation modal** | From naming Review/Enter | Current and proposed identity; Confirm and Cancel | Exclusive confirmation; prevent double dispatch; preserve focus; durable rename command; return errors to callsign input |
| **Promotion path selection** | `VIEW PATHS` only when selected hero is authoritatively promotable | Identity/progress heading, continuity strip, one card per legal target, class portrait, role, description, skill, DP/placement/block/range/cadence, kit copy, permanence warning | Select exactly one path; enable `ADD TO PLAN`; return to roster; add or replace draft choice; `ui_cancel` returns to roster |
| **Training-plan review and confirmation** | `REVIEW PLAN` when local draft is non-empty | All drafted callsign → class assignments, permanence copy, reconciliation removals, error region, Back, Confirm Training | Review batch; Back reopens last edited operator/path and restores selection; confirm once; reconcile stale choices; retry durable save; block leaving during pending retry |
| **Post-promotion acknowledgement** | Successful confirm currently always opens Company Command | One visit-scoped acknowledgement card listing callsign → class assignments | Consume once; use committed campaign projection; never duplicate acknowledgement on idempotent replay |
| **Results training prompt** | Results shows only when eligible count > 0 | Ready count and `Train Recruits` action | Enter Training with origin `results`; `Not Now`/cancel returns to Results |
| **Company Command training tile** | Visible but disabled unless eligible count > 0 | Training operation tile and optional acknowledgement | Open with origin `staging`; communicate unavailable state; consume success acknowledgement |

## 4. Feature contracts that must survive

### 4.1 Roster projection and filtering

1. **The campaign remains authoritative.** Training only adapts `data_copy()` and `promotion_options()`; it does not infer legal paths or mutate campaign rows.[6]
2. **Default browsing is Active + All factions.** Fallen heroes are hidden by default, but the Fallen tab remains available for inspection and never enables promotion or deployment.[7]
3. **Faction identity remains presentation-only.** An explicit canonical faction wins, known prefixes may derive one, and unknown rows safely fall back to Lunaris without altering save keys, hashes, or codecs.[7]
4. **All four faction controls remain present even at zero count.** Active/Fallen tabs and faction filters show live counts; changing filters preserves a still-visible selection and otherwise selects the first visible row.[7]
5. **Name/title filtering and sorting remain deterministic.** Query matches callsign or optional title case-insensitively. Sort modes are recruitment order, name ascending, and name descending, with title/recruitment/hero-ID tie breaks.[6]
6. **Empty results are explicit.** The roster must show an empty-state message rather than a blank rail. A filter must not clear the selected Mission squad.[6][7]

### 4.2 Operator identity and dossier

1. **Stable personhood must remain explicit.** Promotion changes `current_class_id` and `operator_def_id` while retaining hero ID, callsign, history, portrait identity, and recruitment identity; the existing `SAME PERSON. NEW DUTY.` and identity-continuity messaging encode this important rule.[1][2]
2. **Ordinary and premium heroes remain distinct.** Premium heroes show fixed elite kit and remaining lives, never XP progress, never enter eligible counts, cannot train, and cannot be renamed.[11]
3. **Life status controls interaction.** Only ready ordinary recruits can rename or train. Fallen rows may be inspected but are read-only.[2][7]
4. **Every roster state remains legible without color alone:** ready, fallen/dead, premium ready/locked, insufficient XP, promotion ready, already promoted, locked class, missing catalog, and planned path.

### 4.3 Custom naming

1. **Callsign constraints are authoritative:** non-empty, trimmed, 1–20 Unicode characters, no C0/C1 control characters, and unique case-insensitively across the roster.[9][10]
2. **Title constraints are authoritative:** optional (`null` when blank), trimmed, up to 24 Unicode characters, and no C0/C1 control characters.[9][10]
3. **Only ready, non-premium recruits can change identity.** Premium names are fixed; fallen/non-ready recruits are locked.[9]
4. **Unchanged identity is rejected.** Callsign-only and callsign-plus-title commands preserve their distinct authoritative error semantics.[9]
5. **Review precedes commit.** Confirmation shows both current and proposed identity, Cancel restores editing focus, and a rejected durable commit returns the authoritative message inline without losing the draft.[1]
6. **Rename is cosmetic but durable.** It increments save revision, records a command receipt/event, survives restore, and propagates to runtime, roster filters, Mission cards, acknowledgements, and future dossiers.[9][15]

### 4.4 Promotion planning and confirmation

1. **Legal paths come only from `promotion_options()`.** Premium, dead, under-XP, fully promoted, entitlement-locked, illegal-edge, missing-catalog, and unknown heroes must retain their exact rejection behavior.[8]
2. **Path cards are data-driven.** They must continue to expose localized class name, role, description, combat skill, DP, placement, block, range-cell count, attack cadence, and target operator portrait.[6]
3. **Choice permanence is disclosed before and during review.** The player selects a path, adds it to a local multi-hero draft, reviews the full batch, then confirms.[1]
4. **The batch is canonical and atomic.** Choices sort by hero ID before command creation; every choice is revalidated against the latest state; one accepted mutation changes all included heroes and appends one promotion receipt.[2][8]
5. **Double activation cannot duplicate a promotion.** The UI consumes the confirmation once, disables the control during dispatch, and command IDs remain idempotent.[1][2]
6. **Stale plans reconcile safely.** On a non-retryable rejection, still-legal draft entries remain and removed entries identify callsign, intended class, and reason.[1]
7. **Durable-save retry cannot be bypassed.** While a promotion mutation is pending retry, Back, `Not Now`, and `ui_cancel` cannot leave; Confirm retries the pending mutation rather than creating another command.[1][2]
8. **Fresh successful commits publish a one-time acknowledgement.** Duplicate/idempotent results do not republish it.[2]

### 4.5 Navigation, focus, and accessibility

1. `ui_cancel` means **review → paths, paths → roster, roster → contextual origin**, except during a pending save retry.[1]
2. Training origins remain validated to `staging`, `results`, or `mission`; invalid values fall back to Company Command.[2]
3. Mission → Training → Mission retains selected stage and squad because scene swaps are presentation-only and `Game.selected_stage_id` / `selected_squad` survive.[2][13]
4. Keyboard/controller focus remains cyclical, excludes disabled controls, and scrolls focused roster rows, fields, path-card headings, errors, and actions into view.[1]
5. Hit targets stay at least 44×44, text remains native/localizable, CJK fallback remains available, and icon-only faction controls keep accessible names/tooltips.[5][12]

## 5. Visual and component gap analysis

| Area | Current implementation | Approved direction | Gap and impact |
|---|---|---|---|
| **Overall composition** | One centered `AetheriaScreenShell` plate with outer scroll; roster and inspector are two columns | Near-full-safe-area, asymmetric three-region layout with compact roster, hero-centric dossier, and advancement inspector | The monolithic plate feels like a dialog. The operator is not the emotional focal point, and unrelated tasks compete in one scroll hierarchy. |
| **Selected operator** | `126×160` portrait beside name/class; naming form appears before dossier | Large adult operator portrait with lunar halo/ritual geometry, identity anchored at the portrait, progression beside it | The strongest gacha asset is visually subordinate to filters and form fields. It does not achieve “must-pull” presence or mature fashion-editorial framing.[4] |
| **Roster rail** | Rows are at least 500 px wide, with `96×104` portrait and dense text; filters consume three control bands | Narrow portrait-first rows with clear selection, class seal, XP, and readiness | The roster cannot act as a compact rail. Filter chrome and long eligibility prose reduce scan speed. |
| **Progression inspector** | XP/premium data and permanence copy sit under the dossier; path preview exists only after changing page | Dedicated right inspector with Field Record, readiness, class-path preview, and permanent-choice warning | The landing page does not answer “what can this operator become?” at a glance. Readiness and paths are separated from the selected operator. |
| **Promotion paths** | Large generic toggle cards in a scroll; >2 choices force a vertical stack; portrait art is a battle-operator portrait | Ceremonial class seals/cards with immediate before/after identity and role comparison | Five Recruit paths become a long form. There is no compact compare mode, locked-path context, or clear class-family visualization. |
| **Naming** | Large form embedded at the top of inspector; generic native `ConfirmationDialog` | Secondary identity action/sheet that supports the dossier without displacing it | Naming dominates the visual hierarchy. The native modal risks desktop-tool styling and does not share the Lunaris frame language. |
| **Surface language** | Mostly translucent flat boxes, uniform one/two-pixel borders, four-pixel radii | Engraved brass, black-blue glass, pointed cuts, restrained cyan mechanisms, texture-backed nine-patch frames | The palette is directionally correct but materials remain generic. Company Command already has the closer textured component vocabulary, creating intra-title inconsistency.[5] |
| **Typography** | Runtime Training applies size/color roles but not the approved Cinzel display font | Cinzel for Latin display/actions with Protos CJK fallback; readable sans for body | Titles, class names, metrics, and actions do not share Company Command’s premium editorial identity. Some 15 px details are too quiet over art. |
| **Primary action hierarchy** | `VIEW PATHS` can be primary while enabled `REVIEW PLAN` is also primary; cyan-filled primary dominates | One unambiguous primary action, usually warm gold for commitment; cyan indicates state/selection | Two primaries compete once a draft exists. Cyan is overused as both selection and action priority. |
| **Filters** | Active/Fallen row, five faction buttons, query, sort, and summary are always expanded | Compact filter strip/drawer with persistent state and roster count | Controls can occupy more first-view height than operator content, especially in portrait. Icon-only faction counts require tooltip knowledge. |
| **State communication** | Many states are prose labels using the same detail style | Seals, chips, bars, and typography distinguish ready/planned/fallen/premium/locked | Important distinctions are text-heavy and hard to scan. Color/state tokens are not centralized across Mission and Training. |
| **Contextual return** | Only Mission receives a prominent top-right return; other origins rely on `Not Now` | Clearly named origin action in a stable navigation location | Results and Company Command origins are less explicit. Successful promotion unexpectedly routes all origins to Company Command. |
| **Adult 21+ promise** | Runtime portraits are used correctly, but selected portrait scale is small and crops are utility-led | Mature face, hair, upper couture, confident posture, clear material separation | No age-policy violation is evident, but the presentation underuses the approved adult glamour and fashion identity. Any new portraits/seals must preserve 21+ cues and avoid sexualized accidental crops.[4] |

## 6. Recommended target design

### 6.1 Shared shell and visual system

Replace the centered “reading dialog” impression with a **full-safe-area Reliquary Atelier workspace**. Reuse the Staging skin’s Cinzel-with-CJK-fallback helper, Lunaris seal, engraved texture-frame logic, and focus treatment rather than cloning Company Command wholesale.[5] Create Training-specific nine-patch variants for a compact roster rail, hero stage, advancement inspector, selected row, path seal, modal sheet, and sticky action dock. Native text and controls must stay above these frames.

Use near-black lunar ink and black-blue glass for mass, antique brass for framing and headings, ivory for primary text, muted steel for detail, violet only for depth, and moon-cyan strictly for selection, readiness, progress fill, and focus. Primary commitment actions should use the warm engraved gold frame; secondary navigation uses dark glass; destructive or integrity failures use a restrained red edge. Corners should be clipped or remain within zero-to-six pixels.

Display roles should use Cinzel for **RELIQUARY ATELIER**, **OPERATOR ADVANCEMENT**, operator callsign, class names, ready counts, and action labels in English. Body explanations, errors, combat details, and long localized strings should use the existing sans/CJK fallback. Do not force spaced uppercase into CJK. Raise essential roster metadata to at least 16 px at the 1280×720 design canvas; reserve 13–14 px only for short high-contrast badges.

### 6.2 Landscape information architecture (`1280×720`)

Use a compact operational header, a fixed action dock, and an internally scrolling body:

| Region | Recommended allocation | Content |
|---|---:|---|
| Header | 72–84 px | Lunaris seal, `RELIQUARY ATELIER`, `OPERATOR ADVANCEMENT`, ready count, compact origin control |
| Left roster rail | 28–31% width | Collapsible filter strip; query/sort drawer; 76–88 px portrait rows; name/title, class, XP/readiness; local vertical scroll |
| Center hero dossier | 38–42% width | Large 21+ operator portrait, halo geometry, callsign/title/class, continuity statement, selected/fallen/premium treatment |
| Right advancement inspector | 27–31% width | Field Record, XP/lives, readiness, next-path preview, plan status, Naming entry, permanence copy; local scroll only if needed |
| Action dock | 76–88 px | Origin-aware Back/Not Now, View Paths, Review Plan/Confirm; exactly one primary |

The landing inspector should preview all legal next classes as compact class seals. Five Recruit options may appear as a 2×3 seal grid; one or two advanced options can use larger compare tiles. Selecting a seal opens the detailed path state without abandoning the operator portrait.

Move naming behind an `EDIT FIELD IDENTITY` secondary action. Open it as a right-inspector state or framed modal sheet with character counter, clear eligibility reason, current/proposed preview, and native text fields. This preserves discoverability without placing two tall inputs before the operator art.

### 6.3 Portrait information architecture (`720×1280`)

Do not simply stack every landscape region. Use a portrait-specific hierarchy:

1. A 64–76 px header with abbreviated but accessible origin control.
2. A 220–280 px selected-operator hero stage with an overlaid callsign/class/status block.
3. A 150–190 px horizontally scrolling roster carousel or compact two-row rail; keep Active/Fallen and selected faction in one collapsible filter bar.
4. A tabbed inspector with `RECORD`, `PATHS`, and `IDENTITY` segments. Each segment gets one internal scroll; switching tabs must not clear the selected hero or draft.
5. A bottom-safe action dock with three 56–64 px controls. The primary action remains visible without scrolling the whole page.

This sequence preserves character appeal while keeping roster changes reachable. If a horizontal roster is rejected for controller reasons, use a compact vertical rail in a 240–300 px local scroll, but do not allow it to push the action dock off-screen.

### 6.4 Promotion path and review states

Keep the same shell, selected hero stage, and origin control throughout the flow. Replace full-page cards with a **class compare inspector**:

- A compact “current duty” card anchors the left/top.
- Legal targets are seal-led cards with class name, role, portrait crop, deployment badge, and one-line purpose.
- Selecting a target reveals full skill/combat facts and a before/after duty strip.
- Locked advanced targets may be shown only if the authority can safely expose them; otherwise do not synthesize unavailable paths.
- `ADD TO PLAN` is the only primary in path selection.
- Plan count is persistent in the header/dock and survives changing operators/filters.

Review should use one framed assignment row per hero with portrait, callsign/title, old class → new class, and an `EDIT` affordance that restores the existing “last edited” behavior. Reconciliation removals must remain in a distinct integrity panel. Pending-save retry should transform the primary into `RETRY SAVE`, lock all exits, and explain that choices were applied prospectively but not durably recorded; it must not look like an ordinary validation error.

### 6.5 Contextual navigation policy

Use a stable top-left Back affordance for intra-flow movement and a top-right origin chip for external return. The visible label should be origin-aware: `RETURN TO MISSION`, `RETURN TO RESULTS`, or `RETURN TO COMMAND`. `Not Now` may remain in the dock, but its destination must be explicit in tooltip/accessibility text.

Before implementation, choose one of two accepted completion policies:

- **Preserve current behavior:** Confirmation states `PROMOTE & RETURN TO COMMAND`; success opens Company Command and shows the one-time acknowledgement.
- **Improve contextual continuity:** Success returns to the recorded origin and renders the same acknowledgement as an origin-safe toast/banner; Mission retains selected stage/squad and Results retains the battle debrief. Company Command still consumes the acknowledgement only when it is the origin.

The second policy is preferable for Mission prep, but it is a product/flow change and requires explicit tests. It must not weaken acknowledgement idempotency or save retry.

## 7. Responsive risk register

| Viewport | Risk | Severity | Required mitigation / gate |
|---|---|---:|---|
| `1280×720` | The shell requests `1210×660`, but 36 px safe margins leave only `1208×648`; header, two filter bands, name/sort toolbar, 250 px body, and 64 px footer therefore rely on outer scrolling | **High** | Pin header/dock; give roster and inspector their own bounded scrolls; verify no first-view action clipping |
| `1280×720` | Recruit has five legal paths, so current logic forces 492×420 cards into a vertical list with a 540 px minimum scroll area | **High** | Use compact grid/compare selection; test exactly 1, 2, and 5 choices |
| `1280×720` | Both View Paths and Review Plan can appear primary after a draft exists | **Medium** | Enforce a single primary token based on current task; use state color separately |
| `1280×720` | Long English/CJK class descriptions and errors increase card minimum height and can hide confirmation controls | **Medium** | Clamp summaries, expose detail in selected inspector, and render English + Simplified Chinese captures |
| `720×1280` | Current header’s internal top `BoxContainer` remains horizontal; the 230 px Return to Mission button competes with a 48 px seal and title block | **High** | Switch to portrait header layout or icon+short label; test all three origins |
| `720×1280` | Always-expanded status, five faction controls, query, sort, 300 px roster, 250 px inspector, and three stacked actions cannot all remain in the first view | **Critical** | Collapse filters, use tabbed inspector, local scrolling, and a fixed bottom dock |
| `720×1280` | Path cards switch to `540×780`; five paths produce extreme vertical traversal and nested-scroll focus jumps | **Critical** | Replace with horizontal/compact seals plus selected detail; prove controller focus and touch scrolling |
| `720×1280` | Rename confirmation requests `560×330`, which fits nominally but leaves little tolerance for CJK wrapping, virtual keyboard, or platform safe areas | **High** | Use a responsive in-shell sheet; test soft-keyboard visible state and 24-character title |
| Both | Project config defines a 1280×720 viewport but no explicit stretch/content-scale policy | **Medium** | Add a UI-level windowed probe at exact target sizes before any project-setting change; coordinate with global revamp owner rather than changing project settings in this family |
| Both | Icon-only faction filters communicate names through tooltips, which are weak for touch/controller users | **Medium** | Add accessible labels and a visible selected-faction caption; preserve 44 px targets |
| Both | Back/leave lock during retry can look broken if the pending-save state is not prominent | **High** | Show modal integrity state, disabled rationale, and focused `RETRY SAVE` action |

## 8. Implementation targets

| Target | Recommended responsibility |
|---|---|
| `scripts/ui/training.gd` | Retain mode/draft/dispatch logic; split rendering into roster, dossier, path, identity, review, and dock components; centralize origin labels and one-primary policy |
| `scenes/training.tscn` | Replace script-only root with stable authored anchors for backdrop, header, responsive body host, modal layer, and sticky action dock |
| `scripts/ui/components/training_roster_row.gd` | Add compact rail and portrait-carousel variants; state chips; accessible faction/status naming; remove fixed 500 px assumption |
| `scripts/ui/components/roster_filter_bar.gd` | Add collapsed/expanded modes, selected-faction caption, portrait overflow behavior, and accessible icon labels while preserving filter signals/counts |
| `scripts/ui/components/promotion_path_card.gd` | Add compact seal, compare, selected-detail, and one/two/five-choice layouts; separate summary from long description |
| `scripts/ui/components/training_support.gd` | Keep pure projection boundary; expose only additional presentation facts that can be derived without changing campaign authority |
| `scripts/ui/components/lunaris_ops_style.gd` | Align tokens with Staging skin, add explicit ready/planned/fallen/premium/integrity states, and stop treating cyan-filled controls as the universal primary |
| `scripts/ui/components/staging_skin.gd` | Reuse display font and texture-style factories; extract a shared Lunaris skin layer if Training and Company Command need common frame helpers |
| `scripts/ui/components/aetheria_screen_shell.gd` | Support fixed header/action regions with bounded content hosts, or introduce a dedicated full-safe-area operations shell rather than increasing preferred sizes |
| `scripts/ui/squad_select.gd` | Preserve mission roster filters, selected squad, training entry, and return continuity; adopt shared roster state chips/identity components |
| `scripts/ui/results.gd` | Preserve eligible-count entry; add origin acknowledgement if contextual completion is approved |
| `scripts/ui/staging.gd` | Preserve eligibility-gated tile and one-time acknowledgement; update only if acknowledgement becomes origin-agnostic |
| `autoloads/game.gd` | Preserve validated origins, atomic commit/retry, and acknowledgement idempotency; change success destination only through an explicit policy and tests |
| `sim/campaign_v3_promotion.gd`, `sim/campaign_v3_promotion_rules.gd`, `sim/campaign_v3_renaming.gd` | **No visual-revamp edits expected.** Treat as immutable feature authorities and regression targets |
| `data/classes/*.tres`, `data/operators/*.tres` | Continue to drive path cardinality, localized copy, kit facts, and portraits; do not bake class names or path counts into art |

Suggested new view components are `training_operator_dossier.gd`, `training_progression_inspector.gd`, `training_identity_sheet.gd`, `training_plan_row.gd`, and `lunaris_action_dock.gd`, each with a matching `.tscn`. Names may change, but responsibilities should remain separate so visual iteration does not enlarge the already broad controller.

## 9. Exact test targets

### 9.1 Existing tests that must remain green

| Test | Contract |
|---|---|
| `tests/faction_roster_filter_test.gd` | Active default, Fallen separation, faction counts, canonical derivation, safe Lunaris fallback |
| `tests/custom_naming_roster_test.gd` | Durable recruit rename survives restore and remains visible through roster annotation/filtering |
| `tests/premium_hero_system_test.gd` | Premium fixed-kit non-trainability, no premium XP, life/lockout/revival roster projections |
| `tests/premium_gacha_ui_test.gd` | Recruit acquisition UI remains compatible with the roster’s premium portrait/life projections |
| `tests/vahalla_ui_test.gd` | Fallen roster semantics and memorial navigation remain compatible with Training’s Fallen inspection |

### 9.2 New focused model/projection tests

1. **`tests/training_support_projection_test.gd`** — assert recruitment-order projection; callsign/title fallback; ordinary versus premium XP; eligible count; localized choice enrichment; 1/2/5 choice ordering; missing class/operator catalog rejection; and name/title filtering/sorting tie breaks.
2. **`tests/promotion_plan_commit_test.gd`** — create a multi-hero draft; assert canonical hero-ID ordering, atomic class/operator changes, stable hero identity, one receipt, duplicate-command idempotency, attempt-pending rejection, stale revision, locked entitlement, illegal edge, and premium/dead rejection.
3. **`tests/custom_naming_validation_test.gd`** — assert 1/20/21-character callsigns, null/24/25-character titles, leading/trailing whitespace, C0/C1 controls, Unicode, case-insensitive duplicate, unchanged identity, premium lock, dead lock, attempt-pending, receipt title recovery, and save restoration.

### 9.3 New scene and interaction tests

1. **`tests/training_ui_test.gd`** — instantiate `scenes/training.tscn` with a real campaign fixture and assert named nodes/states for default Active + All filters, promotion-ready count, first promotable selection, empty filters, Fallen read-only state, premium fixed-kit dossier, View Paths enablement, draft persistence, Review Plan enablement, and `ui_cancel` mode transitions.
2. **`tests/training_naming_ui_test.gd`** — exercise `RenameUnitInput`, `RenameTitleInput`, `RenameUnitAction`, identity review sheet/dialog, Cancel focus restoration, Confirm success, duplicate/invalid inline error, premium/fallen lock copy, and updated roster/dossier/Mission projection.
3. **`tests/training_promotion_ui_test.gd`** — assert path-card count for Recruit’s five paths and Mage Apprentice’s two paths; selected card state; Add to Plan; edit existing assignment; multi-row review; single dispatch; stale-draft removed section; pending retry disables every exit; retry success publishes acknowledgement.
4. **`tests/training_context_return_test.gd`** — for `mission`, `results`, and `staging`, assert Not Now and roster-level `ui_cancel` return correctly; paths/review cancel internally; Mission selected stage/squad survive; invalid origin falls back; and the approved success-destination policy is explicit.
5. **`tests/mission_roster_training_integration_test.gd`** — assert filters do not clear selected squad, Fallen cards are disabled/unfocusable, renamed title appears, premium lives appear, `TrainingButton` records Mission origin, and return restores Mission.

### 9.4 Responsive and visual gates

Create **`test/training_responsive_visual_harness.tscn`** with **`test/training_responsive_smoke.gd`**. Capture at minimum:

- `1280×720`: ordinary promotable Recruit with five paths; ordinary planned recruit; premium hero; Fallen hero; review with three assignments; pending-save error.
- `720×1280`: the same states plus expanded filters, long 20-character callsign, 24-character title, English long copy, and Simplified Chinese.

The smoke test should assert viewport containment for header, origin control, selected identity, action dock, modal sheet, and focused control; minimum 44×44 hit targets; no horizontal outer scroll; exactly one enabled primary action; no clipped/overlapped native text; and focus-driven local scrolling. Visual review should compare material, typography, portrait scale, and hierarchy against `docs/ui-concepts/assets/GPT Image 2 - Recruit Training.webp`, not demand pixel identity from a static concept.

## 10. Acceptance checklist

The family is ready for implementation acceptance when:

- Every current authority and error path survives without gameplay-source changes.
- The selected 21+ operator is the dominant emotional element, not the filter toolbar.
- Roster, dossier, progression, and identity are distinct components with consistent Mission/Training projections.
- All four factions, Active/Fallen, query, sorting, title, premium lives, and empty states remain functional.
- One, two, and five promotion choices are usable without long-card traversal.
- Promotion planning remains multi-hero, atomic, idempotent, reconcilable, and save-retry safe.
- Naming remains validated, reviewed, durable, and locked for premium/fallen heroes.
- Exactly one primary action is visible per state.
- Header, current identity, and action dock remain visible at `1280×720` and `720×1280`; only roster/inspector content scrolls locally.
- Keyboard/controller/touch routes, focus restoration, tooltips/accessibility labels, and CJK fallback pass.
- Contextual success destination is documented in copy and enforced by `tests/training_context_return_test.gd`.
- Runtime portraits and any new supporting art preserve the explicit adult 21+, non-explicit, premium anime-realism contract.[4]

## References

[1]: ../../../../scripts/ui/training.gd "Training screen controller"
[2]: ../../../../autoloads/game.gd "Scene flow, training commit/retry, and contextual return authority"
[3]: ../../MISSION_TRAINING_GACHA_UI.md "Approved Mission and Recruit Training UI concept"
[4]: ../../../ART_DIRECTION.md "Canonical Protos visual art direction"
[5]: ../../../../scripts/ui/components/staging_skin.gd "Approved Lunaris staging skin, font, icons, and textured frame helpers"
[6]: ../../../../scripts/ui/components/training_support.gd "Training roster and path presentation projection"
[7]: ../../../FACTION_ROSTER_AND_VAHALLA.md "Active/Fallen and faction roster contracts"
[8]: ../../../../sim/campaign_v3_promotion.gd "Promotion options and atomic confirmation authority"
[9]: ../../../../sim/campaign_v3_renaming.gd "Renaming authority"
[10]: ../../../../sim/campaign_hero_codec.gd "Callsign and title validation"
[11]: ../../../PREMIUM_HERO_SYSTEM.md "Premium fixed-kit and lifecycle contract"
[12]: ../../../../scripts/ui/components/aetheria_screen_shell.gd "Responsive shell and breakpoints"
[13]: ../../../../scripts/ui/squad_select.gd "Mission roster and Training route integration"
[14]: ../../../../scripts/ui/results.gd "Results Training entry"
[15]: ../../../../tests/custom_naming_roster_test.gd "Existing custom naming roster regression"
[16]: ../../../../tests/faction_roster_filter_test.gd "Existing roster filter regression"
[17]: ../reference-findings.md "Accepted concept reference findings"
