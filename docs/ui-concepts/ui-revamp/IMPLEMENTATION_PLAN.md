# Protos Unified UI Revamp — Implementation Plan

> **Historical technical evidence; not narrative canon.** This document preserves the UI migration contract, stable behavior boundaries, accessibility requirements, and completed verification record. It does not define narrative truth. The sole narrative authority is [`../../NARRATIVE_CANON.md`](../../NARRATIVE_CANON.md). Older copy, screenshots, and visual concepts are superseded wherever they conflict with that canon.

**Owner:** Agent 2
**Source repository:** `https://github.com/junnyboi/proto-td`
**Starting revision:** `6f382b621c812c29dacfa79a41fe59e19909709c`
**Engine:** Godot `4.7.2.stable.official.ed1daf0bf`
**Historical visual reference:** [`DESIGN_CONCEPT.md`](DESIGN_CONCEPT.md) and the eight GPT Image 2 concepts
**Technical behavior evidence:** [`UI_AUDIT.md`](UI_AUDIT.md), existing models/presenters, and focused tests

## Execution rules

Every phase begins from a clean, synchronized `master`, makes presentation-scoped changes, runs the repository’s direct import, bounded boot, focused tests, and log scans, and pushes the accepted phase to `origin/master` without rewriting history. Upstream is fetched and fast-forwarded before each final phase test because other agents may modify the shared branch.

The UI may format, stage, animate, filter, and invoke existing route/action bridges. It may not calculate campaign unlocks, mission legality, promotion paths, gacha outcomes, pity, Marks, premium lives, death, placement legality, targeting, rewards, or battle results.

## Product decisions frozen for this pass

| Decision | Approved behavior |
|---|---|
| Player-facing memorial spelling | Display **Valhalla**. Preserve stable internal `vahalla` identifiers, tests, save fields, and route handles for compatibility. |
| Training success destination | Preserve the current Company Manus command destination and one-time acknowledgement. Origin-aware Cancel/Back behavior remains unchanged. |
| Results cancel behavior | Preserve the visible Back to Title action, but route `ui_cancel` to Company Manus command while a campaign is active and to Title only when no campaign is active. This prevents an invisible destructive shortcut without removing the feature. |
| Generated concepts | Use as composition/material targets only. Runtime data, character identity, text, and behavior remain native and authoritative. |
| New gameplay | None. Barracks and Armory remain disabled; no economy or purchase system is created. |

## Phase 0 — Audit, visual targets, and contract freeze

The complete interface is inventoried across 79 screen/state entries. Eight GPT Image 2 concepts define desktop and portrait targets. The design concept, audit, asset manifest, review, and this implementation plan are committed before source migration. The synchronized pre-change baseline must pass direct import, bounded boot, all twelve focused tests, and error scans; the three legacy orientation/redesign scripts are accepted only when they print their explicit success sentinels and retain their known process-code-1 quirk.

**Deliverables:** `UI_AUDIT.md`, `DESIGN_CONCEPT.md`, `IMPLEMENTATION_PLAN.md`, concept images, audit annexes, and updated `todo.md`.

**Exit gate:** complete durable documentation, clean source baseline, and pushed `master`.

## Phase 1 — Shared Lunaris foundations

### 1.1 Semantic material and typography consolidation

Update `AetheriaTheme` to consume the established Staging palette, typography, textures, and tight angular geometry. Existing Aetheria controls remain native and retain stable handles, but Stage Select, Mission, Training, Results, locale lists, panels, badges, and action buttons inherit the premium Lunaris material system. Cinzel is used for Latin display/action roles with the existing CJK fallback. Body/detail roles remain optimized for reading.

Extend `LunarisOpsStyle` with semantic roles for standard, quiet, selected, primary, gold, disabled, danger, memorial, result, and dialog surfaces. Prefer existing generated nine-patch frames for major panels/buttons and use disciplined flat fallbacks for dense rows and overlays.

### 1.2 Full-safe-area shell behavior

Evolve `AetheriaScreenShell` into a full-safe-area-capable premium shell while retaining its public API. Add an explicit full-viewport mode, bounded local scroll ownership, safe margins, portrait/compact landscape layout classes, and persistent action-dock support. Existing callers may opt in incrementally; no screen loses its current scroll or resize behavior.

### 1.3 Shared modal and motion behavior

Add reusable presentation-only dialog helpers for a veil, angular sheet, Cancel-default focus, focus containment/restoration, resize clamping, `ui_cancel` parity, and submit-once pending state. Apply the helper first to battle resign and gacha pull confirmation. Continue using the existing title settings implementation until extraction can be done without regressing music, locale, or reduced-motion state; Company Manus command settings remains in the established route.

**Regression gate:** import, bounded boot, all focused tests, new semantic-style/shell/dialog smoke tests, and native title/Company Manus command/Stage Select/Training/Results captures at both target orientations.

## Phase 2 — Campaign, character workspaces, premium collection, and consequences

### 2.1 Campaign and Mission continuity

Restyle Stage Select as an expedition dossier using the existing eight unlocked/locked buttons, stars, selected-stage route, and next-stage projection. The first implementation pass does not invent a new world-map authority or stage art catalog; it uses native stage data, a vertical/dual-column route, Lunaris seal/progress ornament, explicit locked/cleared/next badges, and a selected/next-operation dossier. Mission retains its accepted operator-forward architecture and gains the shared material/type system automatically.

### 2.2 Training and roster continuity

Training and Squad Select retain their existing functional decomposition, filters, naming, promotion, review, save retry, premium restrictions, and origin routes. Their shared Aetheria and Lunaris components are migrated to the unified material/type system. Selected dossiers, path cards, roster rows, status seals, and action docks become visually consistent without changing authoritative promotion or naming logic.

### 2.3 Premium Recruit

Recompose Premium Resonance around the established Lunaris backdrop and a featured five-star hero hierarchy. Preserve the three-identity pool, 40-Mark cost, authoritative pity projection, single-pull behavior, stored-life and revival mechanics, Skip, and reduced motion. Presentation must describe one unique human soul, clean Resonance Shards, Soul Anchors, and prepared recovery bodies; it must never imply copied souls. Add an explicit pre-commit confirmation sheet showing cost, current balance, post-pull balance, and guarantee distance. Only Confirm invokes `Game.pull_premium_hero`; Cancel is presentation-only. The receipt-driven reveal keeps the same committed payload while receiving stronger rarity, forced-pity, and outcome hierarchy.

### 2.4 Valhalla and Results

Rebuild the player-facing Valhalla memorial as a selected fallen-identity archive while retaining internal `vahalla` compatibility: filter rail, selected memorial dossier, service record, visit-local Honor action, and stable `hero_id` selection. Preserve all filtering and campaign read-only behavior. Results becomes a full-safe-area after-action reliquary with distinct clear/defeat identity, native star indicators, typed reward/loss sections, readable consequence copy, and a persistent action dock. Existing Retry, Training, Company Manus command, and Title routes remain.

**Regression gate:** import, bounded boot, all focused tests, new gacha confirmation/cancel tests, Valhalla selection/Honor tests, Results route tests, and deterministic desktop/portrait captures for Stage Select, Mission, Training, Gacha, Valhalla, and Results.

## Phase 3 — Battle field-command layer

Replace default presentation surfaces without changing combat semantics. `BattleHudPresenter` emits concise Core/DP/Kills/State text rather than debug tick information and receives a Lunaris panel/type treatment. `BattleControls` uses styled focusable 44-pixel controls, localized labels, a dimming veil, Cancel-default focus, `ui_cancel` handling, and exact speed restoration. Deployment, spell, tutorial, navigation, placement, facing, and terminal controls receive shared color/material/type roles while retaining validators, signals, action verbs, pan suppression, and effects.

Battle geometry remains governed by the current `BattleView` relayout during this pass. New controls are kept inside measured top/right/bottom regions and verified against landscape and portrait captures. No new camera, deployment, targeting, pause, tutorial, or result rule is introduced.

**Regression gate:** all battle/map/placement smoke tests, new battle-controls focus/modal test, direct import/boot, input-exercised landscape/portrait captures, and clean logs.

## Phase 4 — Integration, export, and deployment

Before release, fetch and fast-forward `master`. If upstream changes the candidate, rerun affected gates. Execute all focused tests, both locale catalogs’ key/placeholder parity checks, full native visual matrices, and error scans. Export with the repository’s non-threaded `Web` preset and require HTML, JavaScript, WASM, and PCK artifacts with checksums. Serve the bundle over HTTP and inspect browser console, network, canvas initialization, input, and responsive resizing.

Update the existing `proto-td-web` project only. Preserve the dynamic-viewport, zero-margin, borderless fullscreen iframe, continuity files, and managed asset layout. Run `pnpm check` and `pnpm build`, restart/verify desktop and portrait previews, save a final checkpoint, and publish directly.

**Exit gate:** synchronized clean `master`, verified Web bundle, clean browser/runtime logs, updated durable plan status, final WebDev checkpoint, and published host.

## Verification matrix

| Domain | Required evidence |
|---|---|
| State integrity | Cancel/filter/Honor/Skip/reduced-motion paths do not mutate authoritative state. |
| Navigation | Stable route handles and every Back/Cancel/return path remain valid. |
| Transactions | Launch, rename, promotion, pull, and result boundaries retain accepted/rejected/idempotent behavior. |
| Responsive | `1280×720` and `720×1280` contain all primary actions and avoid horizontal overflow. |
| Localization | English/Chinese catalogs retain identical key sets and typed placeholder schemas; CJK fallback renders. |
| Accessibility | Native logical labels, visible focus, disabled skipping, modal containment/restoration, and 44-pixel targets. |
| Motion | Reduced motion preserves complete state; hidden tweens/process loops stop. |
| Visual | All non-title UI uses the unified Lunaris palette, angular material, character hierarchy, and safe adult crops. |
| Runtime | Direct import, bounded boot, focused tests, Xvfb captures, Web export, HTTP, browser console, and network checks pass. |

## Completion record

| Phase | Status | Revision / evidence |
|---|---|---|
| **0 — Audit and contract freeze** | Complete | Pushed in `4b6a728`; 79-state audit, eight GPT Image 2 concepts, preserved-feature ledger, and accepted pre-change suite. |
| **1 — Shared Lunaris foundations** | Complete | Unified textured Aetheria theme, upgraded programmatic Lunaris style, full-safe-area shell mode, reusable modal helper, and `lunaris_ui_foundation_test.gd`. Import and Xvfb logs are clean. Landscape Stage Select confirms the material migration. Portrait Stage Select was completed in Phase 2. The three historical success-sentinel process-code quirks were corrected upstream before final integration. |
| **2 — Screen-family migration** | Complete | Stage Select now uses a full-area route+dossier workspace; Training uses the full-area atelier; Mission keeps its proven scaled contract with a fixed action dock; Premium Resonance adds a Confirm-only transaction sheet and featured five-star banner; Valhalla uses a selected memorial dossier; Results uses a two-pane after-action reliquary with persistent actions. `campaign_ui_layout_test.gd`, expanded gacha tests, `results_ui_test.gd`, existing internal `vahalla` tests, full import, and all focused suites pass. Twelve accepted Xvfb captures cover `1280×720` and `720×1280`; logs are clean. |
| **3 — Battle field-command layer** | Complete | Battle HUD, spell/deployment decks, pause-speed-resign strip, veiled Confirm-only withdrawal sheet, tutorial, map guidance, wave/result ceremony, and debrief handoff now share the engraved Lunaris command material. `battle_ui_layout_test.gd` verifies Cancel invariance, safe modal focus, pause/speed restoration, Confirm-only defeat, terminal disablement, and navigation suppression. The complete integrated focused suite passes with zero failures. Eight accepted Xvfb captures cover tutorial/live/resign/terminal at `1280×720` and `720×1280`; logs are clean. |
| **4 — Export and deployment** | Complete / public | Synchronized runtime source `a6f358e286fd62eadb729ecce93c86fb530ec5e9` integrates the unified UI, 15% title readability, capped Company Manus command deck, soundtrack-redesign Phase 0, and Slow Field gameplay/UI. Direct import, bounded boot, all 20 current focused tests, English/Chinese parity, CJK glyph coverage, and error scans pass with zero failures. Twenty native landscape/portrait captures, title-specific input captures, and Slow Field Xvfb evidence are accepted. The historical Godot 4.7.2 Web export contained non-empty HTML, JavaScript, WASM, and a 98,202,864-byte PCK with checksums; this is retained as past release evidence, not a current artifact-size claim. Managed and public verification proved exact resource loading, no obsolete pack requests or status, zero-chrome geometry, title containment, capped deck height, pointer and Enter navigation, and clean consoles. Public checkpoint `4f4e6ce6` is live at `https://protohost-sqtjrsla.manus.space/`. |
| **Title readability follow-up** | Complete | A title-local `1.15` scale contract enlarges the wordmark, Start/Settings actions, settings panel typography/actions, and locale list without changing shared component defaults. `title_ui_scale_test.gd` enforces exact landscape/portrait dimensions and safe-area containment. Direct import, bounded boot, all 20 standalone regressions, five input-exercised Xvfb captures, and error scans pass. |
| **Company Manus command sizing reimplementation** | Complete | Replaced the stretched divider-bearing navbar with GPT Image 2 segmented HUD/rail frames; separated navigation, hero, and command surfaces; enlarged the 1280×720 hierarchy to 24px command, 18px section/status, 26px mission/action, 20px body, and 18/15px operation/state roles; applied per-frame content-safe margins; and added standard, compact-landscape, tall-landscape, and portrait reflow with display-safe-area insets and local scrolling. `staging_command_layout_test.gd` enforces exact English/Chinese viewport geometry, typography floors, 72px primary/navigation targets, text containment, rail ornament clearance, and breakpoint placement. Four exact-resolution native captures are accepted with clean self-terminating harness logs. |
| **Gameplay extension — Slow Field** | Complete | Added a deterministic CELL spell with a 600-tick cooldown, radius-1 footprint, 240-tick duration, and strongest-only 50% ground slow. S6 grants the spell; S7 teaches it at the three-front convergence; S8 retains it for boss-column control. GPT Image 2 icon/VFX assets are manifest-backed. `slow_field_spell_test.gd`, the expanded stage smoke, the full focused suite, direct import/boot, and landscape/portrait Xvfb field captures pass with clean logs. |
| **Slow Field onboarding, indicators, and telemetry** | Complete | First-clear S7 now pauses battle time, spotlights the Slow Field card, marks the median shared corridor, and requires an accepted cast before resuming. SpellBar projects separate cyan field-duration and gold cooldown countdowns from authoritative model ticks. `slow_field_tutorial_ui_test.gd` covers the guided cast and timer lifecycle; `slow_field_balance_telemetry_test.gd` runs deterministic no-combat paired S7/S8 wave telemetry with JSON/CSV output. English/Chinese parity and four native target/active landscape/portrait captures pass. The isolated policy adds 9.2% mean ground transit in S7 and 8.6% in S8 while changing aerial transit by 0.0 ticks; current 240/600-tick balance is retained. |
| **Slow Field aura refinement** | Complete | Reduced the active field projection from 0.72 to 0.46 opacity and added a continuous 18-second rotation around the aura center. The native harness now rejects opaque or static projections; landscape and portrait captures retain field readability without obscuring terrain, enemies, path art, health bars, or the dual timer card. |
| **Slow Field blizzard SFX** | Complete | Produced dedicated cast and expiration cues through GPT Image 2 anchors and audio-capable carrier videos, mastered 2.900/2.950-second 48 kHz stereo derivatives, routed semantic cast and one-shot authoritative-ID expiration edges through `Sfx`, and added catalog plus lifecycle regressions without changing battle authority. |
| **Global 1.5× typography and Mission Preparation redesign** | Complete | Increased every shared typography role and remaining runtime-local override by exactly 50%, including the title-local multiplier. Mission Preparation now uses a transparent First Stand crest, padded Active/Fallen controls, a 3:1 Field Team/intelligence body split, two-column left-information/right-portrait operator cards, enlarged portraits, exact 30%-shorter actions, and a clean Train Operators style without the strike-through ornament. `global_font_scale_test.gd` and the expanded four-breakpoint Mission layout contract lock the result. |
| **Annotated Training roster redesign** | Complete | Removed the redundant roster subtitle and standalone promotion metric; added a pure projected **Promotion Ready** status filter; expanded status, faction, search, sort, and return controls with text-safe padding; moved faction counts to the right of their icons; fixed desktop roster cards at 560px with exact 48px horizontal and 24px vertical padding; introduced a 64px roster/inspector gutter; reordered the selected operator dossier before Field Identity; and hid identity inputs behind an accessible Edit control. Roster actions remain fixed at up to 260×84, matching the newest concurrently enlarged 260×84 Advanced Training action contract. English/Chinese parity, focused authority/lifecycle/layout tests, and native `1280×720`, `1024×576`, `720×1280`, and `390×844` captures pass with clean logs. |
| **Annotated Training roster refinement — pass 2** | Complete | Every Training filter and action now retains at least 24px horizontal and 12px vertical content padding. Ultrawide Training uses a fixed 1,136px two-column roster grid containing two 560px cards, while desktop/portrait safely collapse to one column. The selected-operator inspector removes its cyan fill in favor of a transparent gold frame, gold metrics/progress, enlarged typography, a fixed padded Edit control, and a tripled 378×480 portrait that yields to the identity form only while editing. Recruitment Order remains fixed at 220×96 with centered word wrapping rather than dynamic width. Focus restoration no longer double-scrolls past enlarged inputs. Focused Training, rename, campaign, localization, Mission, and shared-filter tests pass; clean native acceptance covers `1912×761`, `1280×720`, `720×1280`, and `390×844`. |
| **Contextual Training promotion action** | Complete | Removed the global **View Paths** footer action and replaced it with a promotion-eligible-only **Choose Promotion** action directly below the selected operator's **Promotion Ready** status. The contextual control uses exact 24×12 insets, a fixed 360×96 text-safe landscape footprint, a wrapped 260×96 portrait footprint, centered 30px action type, localized accessibility copy, and the existing authoritative specialization route. Focused lifecycle/layout/localization tests and eligible-operator `1912×761` / `1280×720` native captures pass with clean logs. |
