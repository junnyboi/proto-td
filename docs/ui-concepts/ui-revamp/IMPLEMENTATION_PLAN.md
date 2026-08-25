# Protos Unified UI Revamp — Implementation Plan

**Owner:** Agent 2  
**Canonical repository:** `https://github.com/junnyboi/proto-td`  
**Starting revision:** `6f382b621c812c29dacfa79a41fe59e19909709c`  
**Engine:** Godot `4.7.2.stable.official.ed1daf0bf`  
**Visual authority:** [`DESIGN_CONCEPT.md`](DESIGN_CONCEPT.md) and the eight GPT Image 2 concepts  
**Behavior authority:** [`UI_AUDIT.md`](UI_AUDIT.md), existing models/presenters, and focused tests

## Execution rules

Every phase begins from a clean, synchronized `master`, makes presentation-scoped changes, runs the repository’s direct import, bounded boot, focused tests, and log scans, and pushes the accepted phase to `origin/master` without rewriting history. Upstream is fetched and fast-forwarded before each final phase test because other agents may modify the shared branch.

The UI may format, stage, animate, filter, and invoke existing route/action bridges. It may not calculate campaign unlocks, mission legality, promotion paths, gacha outcomes, pity, Marks, premium lives, death, placement legality, targeting, rewards, or battle results.

## Product decisions frozen for this pass

| Decision | Approved behavior |
|---|---|
| Player-facing memorial spelling | Retain **Vahalla** for compatibility with current copy, identifiers, tests, and route handles. A later naming migration may change it deliberately. |
| Training success destination | Preserve the current Company Command destination and one-time acknowledgement. Origin-aware Cancel/Back behavior remains unchanged. |
| Results cancel behavior | Preserve the visible Back to Title action, but route `ui_cancel` to Company Command while a campaign is active and to Title only when no campaign is active. This prevents an invisible destructive shortcut without removing the feature. |
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

Add reusable presentation-only dialog helpers for a veil, angular sheet, Cancel-default focus, focus containment/restoration, resize clamping, `ui_cancel` parity, and submit-once pending state. Apply the helper first to battle resign and gacha pull confirmation. Continue using the existing title settings implementation until extraction can be done without regressing music, locale, or reduced-motion state; Company Command settings remains in the established route.

**Regression gate:** import, bounded boot, all focused tests, new semantic-style/shell/dialog smoke tests, and native title/Company Command/Stage Select/Training/Results captures at both target orientations.

## Phase 2 — Campaign, character workspaces, premium collection, and consequences

### 2.1 Campaign and Mission continuity

Restyle Stage Select as an expedition dossier using the existing eight unlocked/locked buttons, stars, selected-stage route, and next-stage projection. The first implementation pass does not invent a new world-map authority or stage art catalog; it uses native stage data, a vertical/dual-column route, Lunaris seal/progress ornament, explicit locked/cleared/next badges, and a selected/next-operation dossier. Mission retains its accepted operator-forward architecture and gains the shared material/type system automatically.

### 2.2 Training and roster continuity

Training and Squad Select retain their existing functional decomposition, filters, naming, promotion, review, save retry, premium restrictions, and origin routes. Their shared Aetheria and Lunaris components are migrated to the unified material/type system. Selected dossiers, path cards, roster rows, status seals, and action docks become visually consistent without changing authoritative promotion or naming logic.

### 2.3 Premium Recruit

Recompose Premium Resonance around the canonical Lunaris backdrop and a featured five-star hero hierarchy. Preserve the three-identity pool, 40-Mark cost, authoritative pity projection, single-pull behavior, duplicate lives, revival, Skip, and reduced motion. Add an explicit pre-commit confirmation sheet showing cost, current balance, post-pull balance, and guarantee distance. Only Confirm invokes `Game.pull_premium_hero`; Cancel is presentation-only. The receipt-driven reveal keeps the same committed payload while receiving stronger rarity, forced-pity, and outcome hierarchy.

### 2.4 Vahalla and Results

Rebuild Vahalla as a selected fallen-identity archive: filter rail, selected memorial dossier, service record, visit-local Honor action, and stable `hero_id` selection. Preserve all filtering and campaign read-only behavior. Results becomes a full-safe-area after-action reliquary with distinct clear/defeat identity, native star indicators, typed reward/loss sections, readable consequence copy, and a persistent action dock. Existing Retry, Training, Company Command, and Title routes remain.

**Regression gate:** import, bounded boot, all focused tests, new gacha confirmation/cancel tests, Vahalla selection/Honor tests, Results route tests, and deterministic desktop/portrait captures for Stage Select, Mission, Training, Gacha, Vahalla, and Results.

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
| Authority | Cancel/filter/Honor/Skip/reduced-motion paths do not mutate authoritative state. |
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
| **2 — Screen-family migration** | Complete | Stage Select now uses a full-area route+dossier workspace; Training uses the full-area atelier; Mission keeps its proven scaled contract with a fixed action dock; Premium Resonance adds a Confirm-only transaction sheet and featured five-star banner; Vahalla uses a selected memorial dossier; Results uses a two-pane after-action reliquary with persistent actions. `campaign_ui_layout_test.gd`, expanded gacha tests, `results_ui_test.gd`, existing Vahalla tests, full import, and all focused suites pass. Twelve accepted Xvfb captures cover `1280×720` and `720×1280`; logs are clean. |
| **3 — Battle field-command layer** | Complete | Battle HUD, spell/deployment decks, pause-speed-resign strip, veiled Confirm-only withdrawal sheet, tutorial, map guidance, wave/result ceremony, and debrief handoff now share the engraved Lunaris command material. `battle_ui_layout_test.gd` verifies Cancel invariance, safe modal focus, pause/speed restoration, Confirm-only defeat, terminal disablement, and navigation suppression. The complete integrated focused suite passes with zero failures. Eight accepted Xvfb captures cover tutorial/live/resign/terminal at `1280×720` and `720×1280`; logs are clean. |
| **4 — Export and deployment** | Complete / publish handoff | Definitive runtime source `fff95c16242a59cdd63e8e4a69e6b80f49ad2c43` is pushed to `master`. Direct import, bounded boot, all 20 focused tests, English/Chinese parity, CJK glyph coverage, and error scans pass with zero failures. Twenty native landscape/portrait captures are accepted. The Godot 4.7.2 Web export contains non-empty HTML, JavaScript, WASM, and the definitive 98,213,344-byte PCK with checksums. Managed HTTPS verification proved exact resource loading, zero-chrome desktop/portrait framing, pointer and Enter navigation, a clean console, checksum-correct music packs, explicit Web response persistence, and browser-cache copy fallback. WebDev checkpoint `f74dd226` is ready for the Publish control; this session exposes no separate direct publish tool. |
| **Title readability follow-up** | Complete | A title-local `1.15` scale contract enlarges the wordmark, Start/Settings actions, settings panel typography/actions, and locale list without changing shared component defaults. `title_ui_scale_test.gd` enforces exact landscape/portrait dimensions and safe-area containment. Direct import, bounded boot, all 20 standalone regressions, five input-exercised Xvfb captures, and error scans pass. |
