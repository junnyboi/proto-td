# UI Revamp Audit 01 — Company Command and Global Staging Shell

> **Historical technical evidence — not narrative canon.** This document preserves superseded production, localization, visual, screenshot, and regression evidence. Any historical story text, labels, prompts, or approval language shown here is rejected as current lore and must not be used as narrative authority. The sole current narrative authority is [The Anima War canon](../../../NARRATIVE_CANON.md).


**Audit family:** Company Command and global staging shell  
**Repository revision:** `6f382b621c812c29dacfa79a41fe59e19909709c`  
**Target engine and design canvas:** Godot 4.7.2; 1280×720 viewport  
**Required responsive gates:** 1280×720 landscape and 720×1280 portrait  
**Scope boundary:** Company Command, top resource bar, faction standards, operation tiles, next-mission preview, shared shell components, and the title Settings sheet only as a shared-dialog reference. Gameplay authority and unrelated screen redesigns are out of scope.

## Executive assessment

Company Command already owns several valuable pieces of the approved Lunaris language: the recorded adult 21+ ensemble artwork, a shared animated backdrop, Cinzel-led display typography, black-blue glass, antique-gold frames, moon-cyan state accents, bespoke heraldry, and a responsive landscape/portrait split. These are credible foundations and should be retained. The family is not, however, a coherent premium staging experience yet. Its most important action—the next operation—is placed after a large passive faction gallery; the generated primary and operation frames exist but are not used by the corresponding live controls; a low-resolution monochrome pixel-art panorama is used as every mission preview; the resource bar presents a non-authoritative mock economy with purchase-like plus affordances; and Company Command advertises Settings and Messages as inert images rather than operable controls.

The largest structural regression is the addition of four 154–176 px faction cards before the mission card. At 1280×720, the command deck has roughly 598 px of outer height and substantially less internal reading height, while the complete content now requires far more than one viewport. The historical staging acceptance notes predate or do not account for this full content stack: they record Training as visible at 1280×720, but the current order makes later operations dependent on an initially non-obvious scroll. At 720×1280, the bottom sheet intentionally scrolls, but its first view is likewise consumed by campaign progress and standards before the primary operation path. A premium home screen should expose the current objective and primary action immediately, then allow personnel, recruitment, memorial, and reference content to follow.

The global-shell story is also fragmented. Title and Company Command use bespoke Lunaris framing; Mission Control opens `stage_select.gd`, which uses the older centered `AetheriaScreenShell`; Settings builds yet another modal structure directly in `title.gd`. `AetheriaScreenShell` is mechanically useful, but its generic rounded Aetheria theme and centered reading plate conflict with the accepted full-viewport, angular, character-forward gacha compositions. The Settings sheet is the strongest behavioral reference—modal veil, focus restoration, locale/music/motion controls, and `ui_cancel` close—but it should become a reusable shell/dialog component rather than remain title-only code.

## Sources reviewed

The audit reviewed the following technical or directly relevant files. Scene files are intentionally minimal because these screens build their hierarchies in scripts.

| Area | Files reviewed | Relevance |
|---|---|---|
| Project and product contract | `project.godot`; `README.md`; `docs/ART_DIRECTION.md` | Confirms Godot 4.7.2, configured loading entry, 1280×720 viewport, deterministic-view boundary, recorded premium adult 21+ Lunaris aesthetic, and title/loading benchmarks. |
| Approved UI concepts | `docs/ui-concepts/LUNARIS_ENTRY_REDESIGN.md`; `docs/ui-concepts/MISSION_TRAINING_GACHA_UI.md`; `docs/ui-concepts/STAGING_CONCEPT_FIDELITY_PLAN.md`; `docs/ui-concepts/ui-revamp/reference-findings.md` | Defines full-viewport premium density, character-forward editorial asymmetry, tight angular materials, title/Settings behavior, responsive gates, and staging asset intent. |
| Staging asset records | `docs/ui-concepts/staging-concept-fidelity/ASSET_MANIFEST.md`; `docs/ui-concepts/staging-concept-fidelity/ASSET_REVIEW.md`; `docs/ui-concepts/staging-concept-fidelity/frame-review-sheet.png`; `docs/ui-concepts/staging-concept-fidelity/icon-review-sheet.png` | Records generated frame/icon provenance, prior visual validation, and known nine-patch/density constraints. |
| Entry and Company Command | `scenes/loading.tscn`; `scripts/ui/loading.gd`; `scenes/title.tscn`; `scripts/ui/title.gd`; `scenes/staging.tscn`; `scripts/ui/staging.gd`; `autoloads/game.gd` | Defines boot/title/staging lifecycle, Settings behavior, Company Command hierarchy, responsive rules, action routing, and campaign reset/preservation semantics. |
| Shared shell and presentation | `scenes/ui/components/aetheria_screen_shell.tscn`; `scripts/ui/components/aetheria_screen_shell.gd`; `scripts/ui/components/aetheria_theme.gd`; `data/presentation/ui/threshold_theme.tres`; `scripts/ui/components/lunaris_animated_backdrop.gd`; `scripts/ui/game_typography.gd` | Defines the existing global reading shell, breakpoints, scale behavior, modal-adjacent panel vocabulary, animation fallback, and typography scale. |
| Staging components | `scripts/ui/components/staging_skin.gd`; `scripts/ui/components/staging_command_tile.gd`; `scripts/ui/components/staging_resource_chip.gd`; `scripts/ui/components/staging_glyph.gd`; `scripts/ui/components/faction_standard_card.gd`; `scripts/ui/components/faction_heraldry.gd`; `scripts/ui/staging_mock_wallet.gd` | Defines visual assets, operation states, resource values and formatting, faction order/content, tooltip behavior, and compact modes. |
| Copy and Settings controls | `scripts/ui/components/ui_copy.gd`; `localization/en-US.json`; `localization/zh-CN.json`; `scenes/ui/components/aetheria_locale_selector.tscn`; `scripts/ui/components/aetheria_locale_selector.gd`; `scenes/ui/components/aetheria_button.tscn`; `scripts/ui/components/aetheria_button.gd` | Defines localized copy, CJK fallback, logical versus presentation labels, locale selection, focus, and accessible button text. |
| Downstream shell continuity and tests | `scripts/ui/stage_select.gd`; `tests/vahalla_ui_test.gd`; `tests/premium_gacha_ui_test.gd` | Confirms Mission Control’s next shell, Vahalla staging-tile coverage, and the absence of a dedicated staging/title/shell responsive regression. |
| Runtime visuals | `assets/loading/lunaris_reliquary_loading.png`; `assets/title/lunaris-title-loop.ogv`; `assets/world/act1/panorama.png`; `assets/ui/staging/frames/*.png`; `assets/ui/staging/icons/*.png`; `assets/ui/factions/*.webp` | Establishes the difference between recorded painterly Lunaris art, low-resolution mission imagery, highly ornate small icons, and generated frame assets. |

`project.godot` currently launches `res://scenes/loading.tscn`, whereas `README.md` states that the main scene is `res://scenes/title.tscn`. The runtime configuration is authoritative; documentation should be reconciled so validation starts from the actual global entry shell.

## Screen and state inventory

| Screen or state | Current composition | Functional interactions | Required contract to preserve |
|---|---|---|---|
| Boot/loading bridge | Full-cover static Lunaris art, top identity, lower loading status/progress, then fade to title. | No player action; after the minimum display and fade, calls `Game.open_title()`. | Startup must never expose an empty root; the recorded Lunaris art remains continuous into title. |
| Title entry | Shared animated Lunaris backdrop, centered wordmark, Start, Settings. | Start stops title music and calls `Game.start_campaign()`; Settings opens the sheet; keyboard/controller focus cycles between Start and Settings. | Start must load or create campaign state and route to staging; Settings must remain reachable by mouse and keyboard; focus must be visible. |
| Title Settings sheet (shared-dialog reference) | Full-screen input-blocking veil, centered command-deck panel, locale selector, title-music toggle, animated-background/reduced-motion toggle, Back. | Locale selection updates copy; music toggles current-runtime title cue; motion toggles the static fallback; Back or `ui_cancel` closes; focus returns to Settings. | Modal input blocking, Back/Escape parity, focus restoration, locale selection, title music behavior, and reduced-motion behavior must survive extraction into a shared dialog. |
| Company Command — active campaign | Animated full-cover Lunaris backdrop, top bar, landscape hero stage plus right command deck or portrait hero stage plus bottom command sheet. | Mission Control, Resonance, Vahalla, conditional Training, Exit, scroll, focus cycle, and `ui_cancel`. | It remains a projection only: `Game` and campaign state stay authoritative. Returning from child screens must preserve active campaign state. |
| Company Command — no active campaign | Campaign summary resolves to 0/0; next title says no active campaign; no next record/stage; Mission Control is not automatically disabled unless narrative is marked missing. | Exit remains available; other route availability follows current construction. | The screen must fail safely and never mutate a campaign. The revamp should make this exceptional state explicit instead of presenting normal-looking actions with empty data. |
| Company Command — campaign complete | Next-operation title becomes “Campaign complete”; objective falls back to the command-body text because no next record exists; Mission Control remains enabled. | Mission Control still opens stage select, allowing replay. | Replay navigation must remain available; completion should be celebratory and semantically distinct from a next-operation briefing. |
| Company Command — missing narrative | Mission objective shows the missing-record error; Mission Control is disabled and removed from focus order. | Exit, Resonance, Vahalla, and eligible Training remain accessible. | Missing presentation data must not launch an invalid mission flow; the disabled reason must remain perceivable without hover-only discovery. |
| Company Command — training acknowledgement | One visit-local acknowledgement panel is inserted after Mission Control; acknowledgement is consumed after screen construction. | Informational only. | A committed promotion acknowledgement must render once, with callsign/class data, then be consumed without changing campaign authority. |
| Landscape layout | Top bar at 80 px; hero identity over character art; framed right command deck with vertical scrolling. | Same functional actions; hero identity hidden below 1040 px; compact treatment below 1120×700. | Content must remain reachable at 1280×720; primary operation and key destinations should not require discovery of a hidden scroll. |
| Portrait layout | Top bar, upper character stage, bottom-attached command sheet, internal vertical scroll. | Same actions; mission card stacks only below 560 px, so it remains two-column at 720 px. | At 720×1280, identity art, next operation, primary CTA, and a clear indication of additional destinations must coexist without overlap. |
| Top command/resource bar | Faction crest/identity; campaign status; three mock resources on full desktop; two on compact/portrait; optional inert Messages/Settings images; Exit. | Resource chips expose mouse tooltips only; Messages/Settings are noninteractive images; Exit calls `Game.open_title()` and clears campaign; Escape has parity with Exit. | Exit must continue to mean “return to title and end the active campaign session,” not quit the application. Mock wallet values must remain explicitly non-authoritative, nonpersistent, nonspendable, and nonpurchasable until replaced by a real model. |
| Faction standards | Four passive cards in fixed order: Solcrest, Vesper, Lunaris, Crimson; Lunaris carries the Company Manus badge. | Tooltip-only specialization text; no focus or activation. | The active faction remains Lunaris Reliquary and standards remain informational unless a real faction-selection feature is designed. Do not imply selectable factions without corresponding authority. |
| Next-operation preview | One generic 512×256 panorama, next unlocked/uncleared stage title, localized narrative objective, Mission Control CTA. | CTA calls `Game.open_stage_select()` unless narrative is missing. | Next-stage resolution must remain the first unlocked stage lacking stars; title/objective remain localized projections; missing narrative remains a hard guard. |
| Operation tiles | Barracks locked; Resonance enabled; Armory locked; Vahalla enabled; Training separately enabled only when eligible recruits exist. | Enabled routes call `Game.open_gacha()`, `Game.open_vahalla()`, or `Game.training_call("open", "staging")`; locked tiles are disabled and excluded from focus. | Node/action identity, disabled-state semantics, full accessible text, tooltip text, SFX, and campaign-preserving routes must remain stable. |
| Mission Control downstream shell | `stage_select.gd` opens a centered `AetheriaScreenShell` plate with stage rows and Back to Staging. | Stage rows select a stage and open squad selection; Back/Escape returns to Company Command. | Mission Control must retain focusable unlocked stages, disabled locked stages, stage-star projection, and a safe return route. Its visual shell may change without altering this logic. |

## Feature contracts that must survive

| Contract | Current source of truth | Revamp requirement |
|---|---|---|
| Presentation never owns campaign truth | `README.md`; `autoloads/game.gd`; comments in `staging.gd` | Components may receive view models, but no resource chip, tile, progress meter, standard, or mission preview may invent mutable campaign/economy state. |
| Next operation resolution | `staging.gd::_resolve_next_operation()` | Continue selecting the first unlocked campaign stage not present in `stage_stars`; preserve campaign-complete and no-campaign states. |
| Narrative validation gate | `_narrative_missing`, `_build_mission_button()`, `_on_mission_control()` | Mission Control must be visibly and programmatically disabled when its narrative record is absent. Disabled rationale must be available to keyboard/touch users, not only via hover. |
| Route semantics | `Game.open_stage_select()`, `open_gacha()`, `open_vahalla()`, `training_call("open", "staging")`, `open_title()` | Keep scene destinations and return paths unchanged. Exit clears active campaign runtime state; child operations preserve it. |
| Training eligibility and acknowledgement | `TrainingSupport`, `Game.training_call`, staging acknowledgement construction | Training is enabled only when `eligible_count > 0`; successful assignments appear once on return and are consumed only after projection. |
| Locked operation semantics | `StagingCommandTile.configure()` | Barracks and Armory remain disabled/nonfocusable until features exist. An ornamental redesign must not make them appear actionable. |
| Accessible operation labels | Hidden native `Button.text`, custom visual title, tooltips, focus cycle | Preserve logical full text (“Premium Resonance,” unavailable reasons) independently from shortened presentation text. Keep minimum 44 px targets and strong focus visibility. |
| Mock wallet isolation | `staging_mock_wallet.gd` | Until real economy authority exists, the three values remain deterministic presentation scaffolding only. No plus affordance may initiate purchasing, spending, persistence, or progression. |
| Faction identity | `FactionHeraldry.ORDER`, `ACTIVE_FACTION`, assets | Preserve all four stable identities and Lunaris as Company Manus’s active faction. If cards stay passive, style them as reference/affiliation, not tabs. |
| Localization and font fallback | `UiCopy`, localization JSON, `StagingSkin.apply_display_type()` | Dynamic staging and Settings copy remains localized, and CJK renders through the fallback font without missing glyphs or forced Latin letterspacing. Hard-coded identity content should be moved behind copy keys. |
| Shared backdrop and reduced motion | `lunaris_animated_backdrop.gd`; title Settings | Preserve top-anchored 16:9 cover, static-first decode, loop, and stop behavior. Reduced motion must apply to every instance, including a newly created Company Command backdrop. |
| Settings dialog behavior | `title.gd` | Preserve input-blocking veil, close on Back/Escape, focus restoration, language update, current-runtime music state, and immediate motion update. |
| Responsive modes | Staging’s direct portrait test; `AetheriaScreenShell` modes | Preserve intentional landscape and portrait compositions rather than uniformly scaling a desktop canvas. Scrolling must be local, obvious, and never hide the only safe exit. |
| Existing node/test handles | `MissionControlButton`, `RecruitButton`, `VahallaButton`, `TrainingButton`, `ExitButton`, faction-standard names | Keep these stable where practical so functional tests and automation remain resilient through visual replacement. |

## Visual and component-gap assessment

### Information hierarchy

The current order is campaign header, progress, milestones, four faction standards, next operation, Mission Control, optional training acknowledgement, then operations. This makes passive lore/reference content more prominent than the player’s current task. Four equal faction cards also imply faction choice even though the system has one fixed active faction. The accepted Mission and Training concepts instead establish a **current intent first** hierarchy: large character or mission focus, concise live state, then persistent actions. Company Command should lead with the current Company Manus identity and next operation, not with a faction catalogue.

Progress is repeated in the top campaign chip, landscape hero identity, command header, progress bar, and milestone row. The redundancy consumes scarce horizontal and vertical space while failing to communicate richer campaign meaning such as current chapter, next reward, or completion state. One strong status treatment plus a compact milestone rail is sufficient.

### Character-forward premium appeal

The recorded backdrop strongly satisfies the adult 21+ and high-rarity character promise. Yet Company Command reuses the same title ensemble as a generic wallpaper and overlays a largely administrative deck; it does not connect the heroes to the player’s current company, roster, mission, or operation. Compared with the approved Mission/Training concepts, the shell lacks a selected adult operator/duty officer, live squad portrait strip, or current-operation character crop. A staging home does not need a full roster browser, but one contextual command portrait or rotating adult Company Manus hero vignette would make the screen feel like a premium gacha hub rather than a decorated menu.

All character additions must follow `docs/ART_DIRECTION.md`: clearly adult 21+, mature faces and proportions, fashion-editorial combat couture, non-explicit framing, faction-specific ivory/cyan/violet-black/brushed-gold material language, complete hands and coherent weapons, and crops that prioritize face, hair, upper costume, and signature focus.

### Material system and component consistency

The generated `operation_tile.png` and `primary_button.png` frames are exposed by `StagingSkin.operation_tile_style()` and `primary_button_style()`, but no runtime control calls either method. `StagingCommandTile` and Mission Control instead use `StyleBoxFlat` through `clean_button_style()`. Consequently, the command deck, mission card, navbar, and resource chips look manufactured, while the two most actionable component families flatten into generic bordered controls. This is a direct concept-fidelity gap, not a missing asset problem.

The title Settings panel reuses `command_deck_style()`, but its internal actions use flat buttons and the locale list inherits the older rounded Aetheria theme. `AetheriaScreenShell` similarly uses 8–12 px rounded flat panels and a centered reading plate. The premium system calls for zero-to-six-pixel corners, clipped cuts, thin antique-gold rules, and cyan reserved for state/priority. A single token layer should reconcile Lunaris surfaces, button roles, focus, disabled treatment, and modal structure across Company Command, Settings, and Mission Control.

### Top resource bar

The full landscape bar tries to show faction identity, campaign status, 444 px of resource chips, two utility icons, and Exit in an 80 px strip. It fits nominally at 1280 px, but has little localization or platform-safe slack. In portrait it hides stamina and utility icons without any overflow affordance; the player cannot tell that stamina exists. The two remaining currencies still look real and purchasable because each framed chip includes a plus symbol and help cursor, even though `StagingMockWallet` explicitly forbids persistence, spending, purchasing, and progression.

Messages and Settings are `TextureRect`s, not Buttons. They are excluded from keyboard focus and activation; because their mouse filter is inherited from the helper’s ignore setting, the “unavailable” tooltip is not a dependable interaction contract. Showing a polished gear beside a working Settings sheet on the title, but making the same symbol inert in Company Command, is especially inconsistent. Either promote Settings to a real reusable dialog action and represent Messages as an explicit disabled button with a visible status, or remove both from the navigation bar until functional.

### Faction standards

The four source banners and symbols are useful production assets, but their current two-by-two gallery consumes at least 308–352 px plus heading and gaps. At 1280×720 this is over half the visible command deck. Cards are passive but use panel emphasis, pointer pass-through, tooltips, and an active badge, so their interaction semantics are ambiguous. Names, subtitles, specializations, “COMPANY MANUS,” top identity, and the landscape `LUNARIS / RELIQUARY` lockup are hard-coded English in `faction_heraldry.gd` or `staging.gd`; a Chinese session therefore mixes localized command copy with English faction metadata.

The standards should become a single compact **affiliation rail**: active Lunaris standard at meaningful size, with the other three represented as smaller allied/archive seals or a horizontally scrollable codex strip. If they are not selectable, use non-button surfaces, no pointer cursor, and a clear “Archive” or “Affiliations” label. Full specialization copy belongs in a deliberate details affordance or codex, not hover-only tooltip text.

### Mission preview

Every next operation uses `assets/world/act1/panorama.png`, a 512×256 desaturated pixel-art mountain image, tinted cyan and cropped into a 168×84 rectangle. It does not represent the resolved stage and materially conflicts with the recorded painterly anime-realism/science-fantasy monumentality. Its tiny landscape footprint gives the next operation less emotional weight than any standard card. Campaign-complete and no-campaign states also keep the same generic image.

The preview should be stage-specific, ideally driven by presentation data rather than conditionals in the view. Use a 16:9 painterly environment or tactical key art with monumental sacred machinery, route/terrain silhouette, stage index, location, threat shorthand, and a deliberate character-safe crop. When no new operation exists, replace the image with a completion reliquary seal and replay callout. When narrative data is missing, use an explicit corrupted-record visual state, not merely muted body copy.

### Operation tiles and state language

Operation tiles have useful accessible logical text, minimum targets, disabled focus removal, and route separation. Visually, however, enabled tiles differ mainly by gold text and disabled tiles by desaturation. The same status diamond is shown in both states with only modulate changes, so it does not clearly say “available,” “locked,” “new,” or “requires promotion-ready recruit.” Training is detached as a full-width tile after a two-column grid, which gives it inconsistent weight relative to Resonance and Vahalla.

Use a stable operation-card anatomy: optical-size icon, operation name, one short live metric/status, and a state badge. Examples are “Resonance · 120 Marks,” “Vahalla · 1 Fallen,” “Training · 2 Ready,” and “Armory · Locked.” Preserve authority by deriving only metrics already available from campaign projections. Enabled cards should use restrained cyan edge/state accents; gold denotes identity and premium material; disabled cards retain legible labels and an explicit lock reason. Do not use pulsing fill as the sole focus indication.

The label “Vahalla” is repeated in route and copy. If it is not an intentional setting term, correct player-facing copy to “Valhalla” while retaining existing internal scene/node identifiers until a separate safe migration. If intentional, document it as a proper noun so localization and future UI do not oscillate.

### Shared shell and Settings reference

`AetheriaScreenShell` provides three modes, safe margins, local dialog scrolling, and a useful content host. It also clamps content scale to a minimum of 1.0, so it never scales a preferred layout down; overflow must be solved by content reflow and scrolling. That behavior is appropriate for readable text, but child minimum sizes must be tested aggressively. Its visual layer is not appropriate as the final premium global shell: a generic centered plate loses the artwork, asymmetry, and near-full-viewport density established by accepted concepts.

Create a visual shell layer above the mechanical layout helper rather than deleting its responsive logic. A `LunarisScreenShell` should provide full-cover/background slots, an angular top command rail, safe-area gutters, a flexible body slot, a persistent action-dock slot, and optional local scroll regions. A `LunarisDialogSheet` should provide veil, angular command sheet, title/icon slot, close semantics, and focus trapping/restoration. The title Settings sheet should be the first consumer; Company Command’s gear should call the same dialog. Mission Control can then replace its generic centered plate while preserving stage-selection behavior.

There is also a concrete reduced-motion inconsistency: title calls `_backdrop.set_reduced_motion(_reduced_motion)`, but Company Command creates a new `LunarisAnimatedBackdrop` without applying the stored project setting. Entering staging after freezing the title can therefore resume video motion. Every owner must pass the current reduced-motion state during construction, or the component must initialize itself from the shared setting.

## Recommended target composition

### Landscape, 1280×720

Use an 72–80 px top command rail with active Lunaris crest/company identity on the left, one compact campaign state in the center, and real utility actions plus Exit on the right. Resource values should occupy a subordinate wallet cluster; until authoritative, remove plus affordances and visibly classify them as preview/dev scaffolding outside production builds.

Below the rail, retain the cinematic adult Lunaris command figure/ensemble across roughly 45–50% of the viewport. Add only a compact Company Manus lockup and, if data exists, a small live roster or duty-officer identity. The right 50–55% becomes a full-height command stack with three fixed zones: **Next Operation** at the top, **primary Mission Control CTA** immediately below, and a compact operation grid in the remaining space. Campaign milestones and faction affiliations move to a short tertiary rail or collapsible/archive area below the primary actions. The initial 720 px view must expose Mission Control plus Resonance, Vahalla, Training state, and a visible locked-state sample without requiring scroll.

### Portrait, 720×1280

Keep the top rail to one line of crest/company, one concise progress value, two essential resource values, and Exit/overflow. The upper 35–40% remains character art. Attach a bottom sheet that initially shows Next Operation, its CTA, and a two-column compact operation grid. Use a visible drag/scroll affordance if standards or milestones continue below. At 720 px width, the mission preview may remain side-by-side only if localized objective copy retains a tested minimum width; otherwise stack image over copy at a more generous breakpoint such as 680–720 px, not only below 560 px.

### Component changes

| Component | Specific change | Contract retained |
|---|---|---|
| `StagingSkin` / theme tokens | Introduce semantic roles for shell, primary CTA, operation available/locked, status badge, dialog sheet, resource display, and focus ring. Use generated nine-patch frames where designed. | Existing colors/assets may remain; functional controls stay native. |
| Top command rail | Replace inert utility textures with Buttons; wire Settings to shared sheet; remove or explicitly disable Messages; add overflow for hidden stamina/utility in portrait. | Exit and `ui_cancel` still call `Game.open_title()`. |
| Resource chip | Remove purchase-like plus from mock values; expose resource name without hover dependency; support value/capacity and authoritative/mock source state. | Formatting, IDs, compact mode, and non-authoritative isolation survive. |
| Faction standard | Convert the four-card block into an affiliation rail with one featured active standard and three compact archive seals; localize identity metadata. | Four factions and active Lunaris remain unchanged; cards remain passive unless a real selector is added. |
| Mission preview | Bind stage-specific preview art and threat/location metadata through presentation resources; add complete/no-campaign/missing-record variants. | Next-stage and narrative selection logic remains unchanged. |
| Mission CTA | Apply `primary_button_style()` or a corrected semantic derivative; retain native logical text and disabled/focus behavior. | `MissionControlButton` and route guard survive. |
| Operation tile | Apply `operation_tile_style()`; add a short metric/status slot and explicit badge; simplify icons for 38–44 px optical size. | Enabled/disabled route semantics and full accessible text survive. |
| Shared shell | Add `LunarisScreenShell` as a premium visual/layout wrapper with header/body/action slots rather than repurposing every caller ad hoc. | Existing responsive modes, safe margins, local scroll, and view-only role survive. |
| Shared dialog | Extract title’s Settings overlay into `LunarisSettingsSheet`/`LunarisDialogSheet`; centralize focus trap, close, and settings refresh. | Locale, music, reduced motion, Back/Escape, and focus restoration survive. |
| Motion | Initialize each backdrop from the shared reduced-motion state and stop processing invisible owners. | Static fallback and animated loop behavior survive. |

## Responsive risks

| Severity | 1280×720 landscape | 720×1280 portrait | Required mitigation |
|---|---|---|---|
| Critical | The two-row faction gallery precedes the mission and operations in a command deck with under 600 px outer height; later operation tiles are below the first fold. | A 704 px bottom sheet still spends most of its first view on progress/standards, pushing operations into scroll. | Reorder next operation and operations before standards; compact standards into a rail; reserve fixed first-view action space. |
| High | The 80 px top bar has minimal width slack once three 148 px resource chips, campaign state, utility icons, identity, and Exit are present. Longer locale text or safe-area insets can force clipping. | Two 108 px resources plus status/identity/Exit nearly fill the 720 px width; there is no overflow route to hidden stamina. | Use breakpoint-aware slots, one-line compact identity, semantic overflow, and explicit width-budget tests. |
| High | Command content is inside a `ScrollContainer`, but there is no obvious visual scroll affordance on the ornate deck. | Bottom sheet scroll is expected, but there is no grab handle, fade, “more” cue, or persistent operation dock. | Add scroll edge fade/handle and keep primary navigation outside the long-form scroll region. |
| High | The main mission art is only 168×84 and generic, weakening hierarchy despite available space. | At exactly 720 px, mission remains two-column because stacking begins only below 560 px; Chinese objective copy may become narrow/tall. | Increase preview footprint in landscape; raise stack breakpoint based on measured text width rather than phone-only width. |
| Medium | Full-size 512 px ornate icons render at 38–52 px under the project’s default texture filtering, risking shimmer/aliasing and lost detail. | The same icons shrink further in compact mode. | Supply optical-size 64/96 px derivatives or set appropriate linear filtering/mipmaps and simplify silhouettes. |
| Medium | Focus pulse runs every frame on staging and every command tile, even when not focused; reduced motion only stops oscillation, not processing. | More controls remain active behind a scroll, increasing unnecessary redraw. | Process animation only while focused/visible; use a static high-contrast focus frame under reduced motion. |
| Medium | Top identity, faction names/subtitles, specializations, and active badge are hard-coded English. | Chinese layout becomes mixed-language; Cinzel Latin and CJK fallback produce inconsistent rhythm. | Add localization keys and test both locales at both target resolutions. |
| Medium | No project stretch mode/aspect policy is declared in `project.godot`; screens rely on runtime viewport size and anchors. | Portrait depends on actual window/embedding behavior rather than an explicit stretch contract. | Declare and validate window stretch/content-scale policy for native and Web; keep responsive layout driven by logical viewport. |
| Medium | `AetheriaScreenShell`’s generic 900×620 centered Mission Control plate visually breaks continuity immediately after the premium CTA. | Portrait reflows to one column but remains a utility dialog rather than a full staging shell. | Migrate stage select to the premium shell without changing stage logic. |
| Medium | Campaign-complete and no-campaign states reuse normal mission imagery/copy and can look actionable or erroneous. | Their longer localized labels may wrap unpredictably in the same mission card. | Build explicit state variants and snapshot each variant. |
| High | Staging does not pass reduced-motion state to its new shared backdrop. | Motion can resume after the player disabled it on title, most noticeable in portrait where the face occupies the upper stage. | Initialize component state centrally and add title→staging reduced-motion regression. |

## Implementation targets

The recommended implementation should be isolated to presentation scenes, scripts, resources, assets, and tests. Gameplay simulation and campaign authority must not be modified.

| Priority | Exact target | Work |
|---:|---|---|
| P0 | `scripts/ui/staging.gd` | Reorder hierarchy; create explicit next-operation/complete/no-campaign/missing-record variants; reserve first-view operation space; wire real Settings action; apply reduced motion; preserve current route handlers and node names. |
| P0 | `scripts/ui/components/staging_command_tile.gd` | Adopt generated operation frame; add semantic state/metric slot; keep hidden logical label, focus exclusion when disabled, and minimum target. |
| P0 | `scripts/ui/components/staging_skin.gd` | Replace ad hoc styling with semantic premium roles; use the already exposed primary and operation frame methods; add consistent focus/disabled/dialog styles. |
| P0 | `scripts/ui/components/lunaris_animated_backdrop.gd` | Initialize from shared reduced-motion state or require owners to pass it before playback; stop unnecessary processing when static/invisible. |
| P1 | `scripts/ui/components/staging_resource_chip.gd`; `scripts/ui/staging_mock_wallet.gd` | Make mock/source semantics visible to callers, remove purchase implication, add accessible resource naming, and support portrait overflow without inventing authority. |
| P1 | `scripts/ui/components/faction_standard_card.gd`; `scripts/ui/components/faction_heraldry.gd` | Build featured-active/compact-archive variants; localize names, subtitles, specializations, and Company badge; remove ambiguous interaction cues. |
| P1 | `data/presentation/narrative/stage_narrative_catalog.tres` plus a presentation-only stage-preview resource/catalog | Bind stage-specific preview art and compact location/threat metadata without adding state to gameplay definitions. |
| P1 | `scripts/ui/title.gd` and new `scenes/ui/components/lunaris_settings_sheet.tscn` / `scripts/ui/components/lunaris_settings_sheet.gd` | Extract the Settings sheet into a reusable dialog with focus trap/restoration, locale refresh, music, motion, Back, and Escape. |
| P1 | New `scenes/ui/components/lunaris_screen_shell.tscn` / `scripts/ui/components/lunaris_screen_shell.gd` | Provide full-viewport premium header/body/action slots, safe margins, portrait mode, and local scrolling; compose or reuse mechanical behavior from `AetheriaScreenShell`. |
| P2 | `scripts/ui/stage_select.gd` | Move Mission Control’s stage list into the premium shell while preserving row names, stage projection, disabled states, focus wiring, and Back/Escape behavior. |
| P2 | `scripts/ui/components/aetheria_theme.gd`; `scripts/ui/game_typography.gd`; `data/presentation/ui/threshold_theme.tres` | Consolidate semantic tokens and reduce rounded generic styling where premium Lunaris shell components still inherit Aetheria defaults. |
| P2 | `localization/en-US.json`; `localization/zh-CN.json`; `scripts/ui/components/ui_copy.gd` | Add faction identity, specialization, operation-state, mission-state, and dialog keys with placeholder parity. |
| P2 | Runtime staging icons and imports | Create optical-size derivatives or validated import/filter settings; keep high-resolution masters/provenance in documentation, not as unnecessarily expensive tiny runtime samples. |
| Documentation | `README.md` | Reconcile the stated main scene with `project.godot` (`loading.tscn` is configured). |

## Exact test targets

There is no dedicated staging, title Settings, shared-shell, or responsive UI regression in the current test set. `tests/vahalla_ui_test.gd` checks only that `VahallaButton` exists and is enabled; `tests/premium_gacha_ui_test.gd` validates the destination screen independently. The following exact targets should be added before implementation is accepted.

| Test target | Exact assertions |
|---|---|
| **New:** `tests/staging_ui_test.gd` | Instantiate a valid fresh campaign and `scenes/staging.tscn`; assert `MissionControlButton`, `RecruitButton`, `VahallaButton`, `TrainingButton`, `ExitButton`, four named faction standards, and resource chips exist. Assert Barracks/Armory disabled and nonfocusable; Resonance/Vahalla enabled; Training equals `eligible_count > 0`; Lunaris has `ActiveCompanyBadge`; next title/objective match the first unlocked uncleared stage; campaign progress/milestones match projection; mock wallet formats 12,450, 1,240, and 88/120 without mutating campaign state. |
| **New:** `tests/staging_state_variants_test.gd` | Cover no campaign, campaign complete, missing narrative, zero and nonzero training eligibility, and a queued training acknowledgement. Assert missing narrative disables Mission Control and removes it from focus; complete campaign retains replay route; acknowledgement renders once and is consumed only after staging projection. |
| **New:** `tests/staging_navigation_test.gd` | Activate each enabled control and assert exact destination/return contract: Mission Control→stage select→Back/Escape→staging; Resonance→gacha→staging; Vahalla→memorial→staging; Training opens with return path `staging`; Exit and `ui_cancel` route to title and clear campaign runtime state. Locked operations must never route. |
| **New:** `tests/title_settings_ui_test.gd` | Open Settings by button; assert veil blocks underlying input, correct initial focus, locale list values, music/motion copy, and Back. Toggle music off/on; toggle reduced motion and assert fallback/video visibility; close by Back and Escape; assert focus returns to Settings. Start Company Command with reduced motion enabled and assert its backdrop remains static. |
| **New:** `tests/global_shell_ui_test.gd` | Exercise shell modes at 1280×720 and 720×1280; assert safe margins, no horizontal scroll, persistent action/exit region, local vertical scrolling, and stable `layout_mode_changed`. Verify dialog focus cannot escape to controls behind the veil. |
| **New:** `test/staging_responsive_smoke.gd` | Programmatically resize to 1280×720 and 720×1280 in both `en-US` and `zh-CN`; assert every visible top-bar child is within viewport bounds; no label has zero width/height; Mission Control and at least the enabled operation set are visible in the first view or a persistent dock; portrait sheet does not overlap the top bar; hidden stamina has an overflow/details route. Emit `STAGING_RESPONSIVE_SMOKE_OK`. |
| **New visual harness:** `test/staging_visual_harness.tscn` and `test/staging_visual_harness.gd` | Deterministically render fresh campaign, partially cleared campaign, complete campaign, missing narrative, Training-ready, and Settings-open states at both required resolutions and both locales. Capture focus, disabled, hover/pressed, reduced-motion fallback, and campaign-complete states for image comparison/review. |
| **Existing:** `tests/vahalla_ui_test.gd` | Retain the current `VahallaButton` existence/enabled assertion and extend return-to-staging verification after memorial interaction. |
| **Existing:** `tests/premium_gacha_ui_test.gd` | Retain independent destination behavior; add or pair with navigation test so staging Resonance is proven to reach this screen without losing campaign state. |
| **Existing engine gates** | Run `tools/run_godot_isolated.sh --headless --import` and `tools/run_godot_isolated.sh --headless --fixed-fps 60 --quit-after 120` on the final candidate. Then run each SceneTree target with `tools/run_godot_test.sh <target>.gd`. |

The responsive smoke test should fail on geometry, not screenshots alone. For every required node, compare `get_global_rect()` against the viewport; verify interactive targets are at least 44×44; verify no two visible interactive rectangles overlap; inspect `ScrollContainer.get_v_scroll_bar().visible` and ensure a visible scroll cue exists whenever true; and check that focused controls are within the visible scroll region after `grab_focus()`.

## Acceptance criteria

| Gate | Acceptance result |
|---|---|
| Premium aesthetic | Company Command reads as an adult 21+ Lunaris anime-gacha command hub: mature character focus, painterly stage-specific operation art, angular black-blue glass, antique gold, and state-only cyan. No generic admin dashboard or retro centered dialog dominates. |
| First-view hierarchy | At 1280×720 and 720×1280, the next operation, Mission Control, and enabled operation destinations are immediately discoverable. Passive standards never displace the primary loop. |
| Functional parity | All route, eligibility, acknowledgement, completion, missing-data, lock, Exit, and return contracts above pass without campaign-authority changes. |
| Resource honesty | Mock resources cannot be mistaken for a real purchase/spend system; no decorative plus behaves like or promises a transaction. |
| Shared shell | Title Settings and Company Command use the same dialog behavior; Mission Control transitions into a visually continuous premium shell; backdrop motion preference survives scene changes. |
| Accessibility | Mouse, keyboard, controller, touch-sized targets, high-contrast focus, disabled rationale, non-hover access to important labels, reduced motion, English, and Simplified Chinese all pass. |
| Responsive safety | Bounds/overlap tests and deterministic visual captures pass at 1280×720 and 720×1280 in both locales, including exceptional state variants. |
| Performance | Tiny runtime icons use appropriate optical sizes/import settings; invisible animation and focus pulses do not redraw continuously; static fallback is used under reduced motion. |
| Repository discipline | Gameplay/simulation authority is unchanged; documentation reflects the real loading entry; focused tests plus import/bounded boot pass on Godot 4.7.2. |

## Final recommendation

Treat this as a **hierarchy and shell unification pass**, not another ornamental asset pass. The repository already contains adequate Lunaris frames, icons, fonts, heraldry, and recorded adult art. The highest-value work is to put the next operation first, compact passive standards, make utility controls truthful and functional, use stage-specific premium preview art, apply the generated action frames to live Buttons, and extract the title Settings behavior into a reusable premium dialog. Once those changes are protected by dedicated state, navigation, localization, and geometry tests, Company Command can become the stable visual and functional home for the rest of the UI revamp without changing gameplay authority.

---

**Audit limitation:** This is a source, asset, concept, and contract audit of synchronized revision `6f382b621c812c29dacfa79a41fe59e19909709c`. No gameplay source was modified. Prior visual-validation claims in existing concept documents were treated as historical evidence, not as proof that the current post-standards content order still passes first-view requirements; the proposed responsive harness is required to re-establish that gate.
