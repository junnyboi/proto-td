# TD-006 — Prototype TD en-US / zh-CN localization and settings

**Author:** Manus AI (AGENT 8)  
**Mode:** active phase plan; dependency reconciliation complete  
**Audit input:** `TD-006-i18n-audit.md` (86 catalog candidates across 42 source files, amended below for literal all-in-game-text coverage)  
**Planning anchor:** `master` at `690f7617acdc710855c3c8e169ad673b1fa8fec0`, post-union `scripts/verify.sh` green on 2026-08-12  
**Target branch:** `agent-8/localization-settings`

## 1. Summary

TD-006 will add a presentation-owned localization system, keep English (`en-US`) as the development/default locale, add complete Simplified Chinese (`zh-CN`) support, expose a Settings button on the title screen, and provide a Settings page with English and Simplified Chinese choices. Every current player-facing string will resolve through `I18n.t(stable_key, current_english_fallback, params)`. Stable gameplay ids, resources, simulation state, hashes, replays, telemetry, node names, and save/progression values remain locale-independent.

The read-only audit found **86 canonical catalog candidates** and **16 proposed exclusion categories**. The user's wording is controlling: **all current in-game text** includes the visible F12 debug overlay even though it is developer-gated. TD-006 therefore adds 13 debug-overlay keys, seven Settings/system keys, and 15 strings from Agent A's now-landed Staging hub, producing a pinned **121-key catalog**. Logs/CI/test diagnostics remain excluded because they are not rendered inside the game. The audit also resolved conflicting Chinese terminology into one glossary and identified every English-coupled scenario assertion that must be migrated without weakening its behavioral intent.

### Player-visible outcome

The title screen gains a **Settings** button. Settings shows a Language section with one mutually exclusive two-button toggle: **English (US)** and **简体中文**, exactly one pressed at all times. Selecting a language updates the live Settings page immediately; returning to title and traversing campaign, squad, battle, and results shows the selected locale. Direct locale changes through the same seam refresh already-instantiated UI without resetting battle/campaign state.

### Non-goals

TD-006 does not localize developer logs, CI output, telemetry ids, internal ids, node names, paths, test descriptions, or invariant symbols (`II`, arrows, `4x`, stars, `DP`). The visible F12 overlay's linguistic labels and readouts **are** localized; the stable stage/operator/spell ids it deliberately exposes remain unchanged. TD-006 does not add plural rules, right-to-left scripts, locale-specific numbers/dates, voice-over, localized art, localized legal/store metadata, or language persistence across process restarts. Locale is session-scoped; `en-US` is applied before the first visible screen.

## 2. Dependency contract and collision law

Agent A's Staging union is closed on `master` at `690f761`; its handoff releases all TD-005 reservations. The Manus GitHub connector restored authenticated transport, no verification process is active, the authoritative master ledger has no in-progress lease, the post-union baseline is green, and all 15 landed Staging strings are frozen into the 121-key catalog. The development gate is open.

The dependency gate was satisfied in this order:

1. GitHub authentication is restored and `git fetch --all --prune` plus `git pull --ff-only origin master` succeed.
2. Agent A's lease is closed/released or its completed union is on `master`.
3. No Godot/verification process owns the worktree.
4. `docs/todo.md` has no active file overlap.
5. The post-union baseline `scripts/verify.sh` is green.
6. A re-audit scans the landed Staging/routing UI; its 15 new player-facing strings are included in the 121-key catalog freeze.

### Observable dependency assumptions

- **A1:** The landed router retains an observable title route and a callable route back to title. TD-006 adopts its mechanism; it does not restore old routing code.
- **A2:** `Game.content` remains the current presentation root or an equivalent observable current-screen seam exists.
- **A3 (resolved):** Agent A landed 15 Staging/routing strings on `master` at `690f761`; TD-006 adopts its routing mechanism and includes every landed string.
- **A4:** The simulation, tick conventions, model hash, and gameplay dispatcher remain unchanged.
- **A5:** Existing node names used by scenarios remain stable; localized display text never replaces lookup identity.

## 3. Pinned parameters and exactness contracts

| Parameter | Pinned value | Reason |
|---|---|---|
| Default/reference locale | `en-US` | Development default and exact fallback language |
| Second locale | `zh-CN` | User-requested Simplified Chinese support |
| Locale choices | Exactly `en-US`, `zh-CN` | Settings must expose only English and Chinese |
| Language control | One two-button `ButtonGroup`, exactly one pressed | Satisfies the requested toggle and avoids an ambiguous dropdown |
| Current audit candidates | 86 | Deduplicated inventory before the controlling all-in-game-text amendment |
| Visible debug-overlay keys | 13 | Linguistic F12 labels/readouts; internal ids/symbols stay invariant |
| New system/settings keys | 7 | `title.settings`, five Settings labels/actions, `common.list.separator` |
| Frozen post-union catalog size | 121 | 86 audit + 13 debug + 7 Settings/system + 15 Staging; fails closed on drift |
| Locale scope | Session only | Persistence was not requested; locale remains presentation session state |
| Seed | 42 | Existing harness convention |
| Scenario viewport matrix | 1280×720 and live-resized 960×640 | Existing supported resize surface; catches CJK reflow defects |
| Font | Deterministically subset Noto Sans CJK SC Regular | Covers zh-CN while avoiding a 16 MB full CJK font |
| Font source | `/usr/share/fonts/opentype/noto/NotoSansCJKsc-Regular.otf`, SHA-256 `2c76254f6fc379fddfce0a7e84fb5385bb135d3e399294f6eeb6680d0365b74b` | Pre-staged and independently measured; source identity is immutable |
| Subset tool | `fonttools/pyftsubset 4.63.0`, no network | Reproducible toolchain is already staged |
| Font license | SIL Open Font License 1.1 | Allows bundled/modified redistribution with license inclusion [2] |
| Project theme | `assets/ui/prototype_td_theme.tres`, default font = subset OTF, default size = 32 px | Required project-wide CJK font and 2× text floor |
| Runtime translation API | `I18n.t(key, fallback, params = {}) -> String` | Stable key + current English fallback contract |
| Formatting | Named `{placeholder}` tokens only | Allows locale reordering and parity validation |
| Format failure | Push an exact developer error and return the unformatted nonblank English fallback; locale/state unchanged | Fail visible, never crash/blank |
| Locale change observation | Synchronous state/signal; all bound visible text correct by next render frame | Falsifiable refresh convention |
| Model observation | Hash/snapshot immediately before and after locale switch | Proves zero authoritative state change |
| Existing English tests | Preserve semantic assertion; replace only locale-blind text oracle | Integrity rule; no check weakening |
| `localization_flow` watchdog | 3000 render frames; shell timeout 120 s | Derived below; no inherited default |

### Paper exactness rules

Let `C[L]` be the catalog for locale `L`, `F` the call-site English fallback, `K` the semantic key, `P` the named parameter map, and `fmt` deterministic named formatting.

1. **Default:** `resolve(en-US, K, F, P) = fmt(F, P)`. The runtime never depends on an en-US catalog row to remain usable.
2. **Translated hit:** if `K ∈ C[zh-CN]`, `resolve(zh-CN, K, F, P) = fmt(C[zh-CN][K], P)`.
3. **Missing locale/key:** `resolve(unknown, K, F, P) = fmt(F, P)` and `resolve(zh-CN, missing, F, P) = fmt(F, P)`.
4. **Placeholder parity:** for every catalog key, `placeholders(C[en-US][K]) = placeholders(C[zh-CN][K])`; the runtime params must contain the same set.
5. **Reject-with-zero-locale-change:** `set_locale(unsupported) == false` and the active locale plus every existing label remain unchanged.
6. **Model invariance:** for any model `M`, switching locale gives `state_hash(M_before) = state_hash(M_after)` and identical snapshot/tick/action availability.
7. **Live refresh:** after `set_locale(zh-CN)` returns and at most one render frame elapses, every visible text owner reports zh-CN; stable node names and button actions are unchanged.
8. **Catalog/resource relation:** for every shipping resource id `id`, the en-US row at `<kind>.<id>.<field>` equals the exact existing resource fallback field; ids and resource fields are not overwritten by locale.

Tick observation is otherwise unchanged: localization consumes no model steps and introduces no timers, RNG, or wall-clock decisions.

### Catalog schema and formatter exactness

Each locale JSON is a UTF-8 object keyed by semantic id. Each row has `text` and `params`; `params` maps every placeholder name to exactly one declared type (`int`, `float`, or `string`). Example: `{"title.seed":{"text":"seed {run_seed}","params":{"run_seed":"int"}}}`. The linter extracts placeholder names and multiplicity from `text`, requires the declared set to equal the extracted set, and requires en-US/zh-CN names, types, and multiplicities to match. `gear_list` is joined before formatting and is therefore `string`, not a catalog-level list type.

The formatter scans left-to-right. `{name}` is a token; `{{` and `}}` emit literal braces; unpaired braces, `%s`/`%d`, undeclared tokens, duplicate JSON keys, missing/extra runtime params, and wrong runtime types are errors. Runtime param keys must exactly equal the row declaration. On a valid row it stringifies only declared values and substitutes all occurrences. On a missing locale/key or malformed translated row it formats the call-site English fallback using the valid reference declaration. If the fallback itself or runtime params are malformed, it emits `I18N_FORMAT_ERROR key=<key> reason=<reason>` through `push_error` and returns the unformatted nonblank English fallback. It never changes locale, model, route, or catalog state. GUT exhaustively covers hit, repeated token, escaped braces, missing/extra/wrong-type params, unknown locale/key, malformed rows, and positional-format rejection.

### Scenario watchdog derivation

`localization_flow` budgets 8 screen/layout waits × 123 frames = 984; 12 real-input rituals × 10 = 120; 6 screenshot draw deadlines × 30 = 180; and setup/resize/locale settle = 216, totaling 1500 frames. A 2× high-refresh margin pins `h.max_frames = 3000`. At 60 fps that ceiling is 50 s; 2× wall margin + 20 s startup/import pins the shell watchdog at 120 s. If the final interaction count changes, this arithmetic must be updated before code rather than inheriting a default.

## 4. Catalog and glossary contract

The canonical 86-key inventory and exact translations are in the audit. Implementation adds these seven Settings/system rows:

| Key | en-US fallback | zh-CN |
|---|---|---|
| `title.settings` | Settings | 设置 |
| `settings.heading` | Settings | 设置 |
| `settings.language.label` | Language | 语言 |
| `settings.language.en_us` | English (US) | English (US) |
| `settings.language.zh_cn` | 简体中文 | 简体中文 |
| `settings.action.back` | Back | 返回 |
| `common.list.separator` | `, ` | `、` |

The visible F12 overlay adds 13 rows: `debug.no_battle` ("no battle - jump to a stage" / "当前无战斗——请跳转至关卡"), `debug.readout.header` (`{stage_id}  tick {tick}  wave {wave}  {result}  seed {seed}` / `{stage_id}  时刻 {tick}  波次 {wave}  {result}  种子 {seed}`), `debug.readout.resources` (`base HP {base_hp}  DP {dp}  speed {speed}x` / `基地生命 {base_hp}  DP {dp}  速度 {speed}x`), `debug.readout.counts` (`spawned {spawned}  alive {alive}  killed {killed}  leaked {leaked}  charmed {charmed}` / `生成 {spawned}  存活 {alive}  击杀 {killed}  漏敌 {leaked}  魅惑 {charmed}`), `debug.label.stage` (stage / 关卡), `debug.action.dp_plus` (DP +10 / DP +10), `debug.action.dp_max` (DP max / DP 最大), `debug.action.hp_minus` (HP -5 / HP -5), `debug.action.hp_plus` (HP +5 / HP +5), `debug.action.unlock_all` (Unlock all / 全部解锁), `debug.label.reset` (reset / 重置), `debug.label.speed` (speed / 速度), and `debug.operator.toggle` (`{sign} {operator_id}` / `{sign} {operator_id}`). Debug result words reuse `battle.hud.status.*`; stable ids, `0x`–`4x`, and `+`/`-` remain invariant parameters/symbols.

The landed Staging hub adds 15 rows: `staging.heading` (STAGING AREA / 集结区), `staging.campaign_summary` (`CAMPAIGN SUMMARY\n{cleared}/{total} missions cleared` / `战役概览\n已完成 {cleared}/{total} 个任务`), `staging.next_mission.active` (`NEXT MISSION\n{campaign_index}. {stage_title}\n{stage_hint}` / `下一任务\n{campaign_index}. {stage_title}\n{stage_hint}`), `staging.next_mission.none` (`NEXT MISSION\nNo active campaign` / `下一任务\n当前没有进行中的战役`), `staging.next_mission.complete` (`NEXT MISSION\nCampaign complete` / `下一任务\n战役已完成`), `staging.operations.unavailable` (FUTURE PERSONNEL OPERATIONS — UNAVAILABLE / 后续人员行动——暂不可用), `staging.action.mission_control` (Mission Control / 任务指挥), `staging.action.barracks_unavailable` (Barracks — Unavailable / 营房——暂不可用), `staging.action.recruit_unavailable` (Recruit — Unavailable / 招募——暂不可用), `staging.action.training_unavailable` (Training — Unavailable / 训练——暂不可用), `staging.action.armory_unavailable` (Armory — Unavailable / 军械库——暂不可用), `staging.action.memorial_unavailable` (Memorial — Unavailable / 纪念堂——暂不可用), `staging.action.back_to_title` (Back to Title / 返回标题界面), `campaign.action.back_to_staging` (Back to Staging / 返回集结区), and `results.action.return_to_staging` (Return to Staging / 返回集结区).

The language options use native/self-identifying names so a player can recover even after choosing an unfamiliar locale. Canonical glossary choices include `原型塔防`, `初次坚守`, `制高点`, `倒戈`, `织焰者`, `唤雷者`, `防卫者`, `疾刃`, `远射`, `鹰眼`, `沥青坑`, `雷击`, `通关`, and `失败`. `DP` remains an invariant game acronym.

## 5. Exclusive file plan after claim

The exact owned set will be re-pinned against the landed union. Expected ownership is:

| Surface | Expected files |
|---|---|
| Runtime localization | `autoloads/i18n.gd`, `autoloads/i18n.gd.uid`, `localization/en-US.json`, `localization/zh-CN.json`, `localization/README.md` |
| Routing/settings | landed router (`autoloads/game.gd` or successor), `scenes/settings.tscn`, `scripts/ui/settings.gd`, `scripts/ui/title.gd` |
| Existing UI migration | `scripts/ui/stage_select.gd`, `scripts/ui/squad_select.gd`, `scripts/ui/results.gd`, `scripts/ui/battle_controls.gd`, `scripts/ui/deploy_bar.gd`, `scripts/ui/spell_bar.gd`, `scripts/view/battle_view.gd`, `scripts/view/juice_layer.gd`, `autoloads/debug.gd` |
| Project/font | `project.godot`, `assets/ui/prototype_td_theme.tres`, `assets/fonts/PrototypeTD-CJK-Subset.otf`, `assets/fonts/PrototypeTD-CJK-Subset.otf.import`, `assets/fonts/OFL-1.1.txt`, `assets/fonts/README.md`, `tools/build_font_subset.sh` |
| New-script sidecars | `scripts/ui/settings.gd.uid`, `tools/i18n_lint.gd.uid`, `test/test_i18n.gd.uid`, `selftest/scenarios/localization_flow.gd.uid` |
| Gates/tests | `tools/i18n_lint.gd`, `test/test_i18n.gd`, `selftest/scenarios/localization_flow.gd`, `selftest/scenarios/{battle_controls,blocking,campaign_flow,charm_runback,drone_counter,resign_flow,skill_timing,wave_banner_victory,debug_reach,resize_relayout}.gd`, `test/test_music_catalog.gd`, `scripts/verify.sh` |
| Evidence/coordination | `FEATURES.json`, `docs/todo.md`, `docs/completed.md`, `docs/plans/TD-006-localization-settings.md`, `docs/handoffs/TD-006-agent-8-localization.md`, `docs/media/TD-006-verification.json` |

**Forbidden:** `sim/**`, gameplay `data/*.tres` values, tick semantics, action dispatch, telemetry schema/ids, playtest thresholds, SFX/music bytes, unrelated art, and human verdict wording.

## 6. Ordered work packages

### Phase 0 — Reconcile, claim, and freeze the landed text inventory

**Deliverables:** pull current master; inspect Agent A's union; re-run the text audit for Staging/new routes; publish a TD-006 claim with exact files/base SHA; mirror this actionable contract into `docs/plans/`; establish a fresh green baseline.

**Exit gate:** authentication works; no overlapping lease; baseline green; landed Staging inventory frozen at 15 additions and total catalog count 121.

**Explicitly not:** implementation edits or auto-discovered test files before claim.

### Phase 1 — Translation seam, catalog contract, and font proof (riskiest system first)

**Deliverables:**

- `autoloads/i18n.gd` with `t`, `set_locale`, supported-locale metadata, synchronous `locale_changed`, named formatting, missing-key fallback, and runtime window-title refresh.
- `localization/en-US.json` and `zh-CN.json` with exact key parity, the canonical glossary, and no blanks.
- `tools/i18n_lint.gd` validating locale ids, exact 121-key count/parity, row schema, placeholder names/types/multiplicity, exact resource fallbacks, no orphan aliases, and narrow source-literal/allowlist rules.
- `tools/build_font_subset.sh` builds a sorted UTF-8 glyph file from both catalog texts, English fallbacks, digits, `DP`, stars, arrows, and punctuation, then runs `pyftsubset` against the pinned source with `--text-file=<sorted-glyph-file> --layout-features='*' --glyph-names --symbol-cmap --legacy-cmap --notdef-glyph --notdef-outline --recommended-glyphs --name-IDs='*' --name-legacy --name-languages='*' --no-recalc-timestamp --canonical-order`. It writes the subset to a temporary path, rebuilds twice byte-identically, records the output SHA-256 and recipe in `assets/fonts/README.md`, and atomically replaces the committed OTF. No download is allowed. If source/tooling is unavailable, the committed subset is used only after its recorded hash and glyph gate pass; no substitute font is silently generated.
- `assets/ui/prototype_td_theme.tres` sets the subset as `default_font` and 32 px as the default size; Phase 2 wires it through `gui/theme/custom`. Godot supports TTF/OTF/WOFF/WOFF2 and project-wide custom fonts through GUI theme settings [1].
- `test/test_i18n.gd` proves all eight exactness rules, formatter failures, active Theme/font resolution, all catalog glyphs, and model hash/snapshot invariance. The render scenario measures glyph pixels; a file/codepoint scan alone cannot prove the active font.

**Exit gate:** L1; focused GUT; headless import/boot; i18n lint green; font contains every codepoint used by both catalogs.

**Explicitly not:** UI migration, Settings route, gameplay data mutation.

### Phase 2 — Settings route and title localization

**Deliverables:** add I18n autoload and wire `assets/ui/prototype_td_theme.tres` through `gui/theme/custom`; add a real Settings scene/page and router seam following the landed routing convention; add the title Settings button; language choices exactly English (US)/简体中文 in one mutually exclusive two-button `ButtonGroup`; session default en-US; live Settings refresh; localized runtime window title.

**GUT/Scenario:** extend `test_i18n.gd`; begin `localization_flow` at seed 42 through real title and Settings controls.

**Falsifiable shots:** Settings button is visible beneath the existing title actions; Settings has exactly two language choices with exactly one pressed; zh-CN heading/labels render as Chinese glyphs through the active custom Theme, not tofu; Back returns to a Chinese title without route duplication or lost seed.

**Exit gate:** targeted headless/windowed `localization_flow`; fresh PNG read; no title/campaign behavior regression.

**Explicitly not:** campaign/battle/results migration.

### Phase 3 — Campaign, content-name, battle, and results migration

**Deliverables:** replace every audited player-facing assignment/composition with `I18n.t(key, exact-current-fallback, named_params)`; derive resource keys from stable ids at the rendering boundary; use locale-specific list separator; refresh existing controls on locale signal; retain pass-through semantics in `juice_layer.gd`; localize the F12 overlay's visible prose while preserving its ids/node names/actions; catalog music and unused skill names without pretending they have visible consumers.

The eight English-coupled scenarios (`battle_controls`, `blocking`, `campaign_flow`, `charm_runback`, `drone_counter`, `resign_flow`, `skill_timing`, `wave_banner_victory`) and `test/test_music_catalog.gd` are migrated exactly as predeclared by the audit: each English oracle becomes its original semantic-state assertion plus the exact locale-resolved widget assertion. `debug_reach` adds localized visible-label checks while retaining node/action-id checks. No assertion, branch, threshold, or failure is removed to clear a red run.

**Scenario:** complete `localization_flow`: title → Settings zh-CN → campaign → squad → battle → resign/results, with an in-battle direct seam switch proving live refresh and hash equality, then restore zh-CN. Headless checks run in both locales; windowed shots cover representative screens.

**Falsifiable shots/checks:** at both 1280×720 and live-resized 960×640, Chinese glyphs exist; no tofu; every localized Control rect stays within its parent/viewport; no labels/buttons report clipping; operator grid retains five columns and hit targets; stage hint wraps; top-right spell/controls do not overlap; bottom deploy strip remains onscreen; HUD is legible; result actions fit. Each locale switch awaits the pinned settle window before rect checks/shot. Text changes but node identities and model hash do not.

**Exit gate:** focused GUT; all touched headless scenarios; `localization_flow` both lanes; source/catalog/font lints green.

**Explicitly not:** debug logs/CLI text or translation of ids exposed by the debug overlay, enemy names without a player surface, music-player UI, persistence.

### Phase 4 — Verification integration, ledger closure, and final audit

**Deliverables:** add an explicit i18n lint rung to `scripts/verify.sh`; add `I18N-1` to `FEATURES.json`; execute the full ladder; write durable verification JSON and handoff; move TD-006 from todo to completed only after evidence is green.

**Repository integrity rules (verbatim):**

> - Never weaken a failing check to make it pass — fix the game.
> - Screenshots must come from the run just executed (fresh evidence only).
> - Impossible checks stay failing and get logged, never deleted.
> - Thresholds (`playtests/thresholds.json`) are human-owned; tier-2 bands are written only after
>   human playtest round 1.

The predeclared text-oracle migrations above land with the localization behavior before the feature gate runs. They preserve the original semantic assertion and add the exact resolved-widget assertion; they do not reinterpret a red, delete a branch, or alter a human threshold.

**Final gates:** L1 parse/lint → L2 full headless GUT → L3 import/boot → L4 every seeded scenario headless then windowed → L5 independent PNG review against the checklist, zero render skips → L6 green commit with evidence → L7 human-playtestable Web export. At the frozen hash, remove `artifacts/`, run one uninterrupted `scripts/verify.sh --full`, run the campaign twice as separate processes with wall/engine metadata normalized and diffed, then obtain an independent adversarial diff-vs-pins review.

## 7. Verification evidence contract

`docs/media/TD-006-verification.json` must record the frozen SHA, full-run command/wall time/status, lint key count, locale parity, font codepoint count, model-hash equality, scenario reports/shots with mtimes, replay normalization/hash/diff result, independent visual checklist, independent adversarial review, deviations, and final integration SHA.

The feature ledger row remains `pending` until every machine gate is green. Machine verification does not claim Chinese linguistic quality; the glossary remains subject to human/native-language L7 review.

## 8. Trim order and never-cut list

After three distinct implementation attempts on one red, trim in this order and log a numbered deviation: (1) localized runtime music titles with no consumer; (2) localized platform/window metadata covered by D-I18N-2. If the red remains, escalate rather than silently reducing player-visible scope. Never cut current visible copy (including F12 prose), both catalogs, fallback/formatter behavior, Settings route/two-button toggle, `locale_changed` refresh of every persistent visible text owner on the current title/campaign/squad/battle/results/debug screen by the next render frame, stable-id boundary, font recipe/license/glyph coverage, source lint, model hash invariance, or full verification. Only the individually evidenced transient exception in D-I18N-5 may survive.

## 9. Numbered deviation candidates

- **D-I18N-1 (realized):** Agent A's Staging union added 15 player-facing strings; the frozen catalog count rose from 106 to 121 before implementation.
- **D-I18N-2:** `DisplayServer.window_set_title` cannot affect Web document title consistently; runtime in-game title remains localized and platform metadata limitation is recorded.
- **D-I18N-3:** exact subset font generation is not reproducible from the pre-staged system font after sandbox reset; committed font/hash/license remain valid while the recipe records the missing source package.
- **D-I18N-4:** a supported Godot locale API normalizes hyphens to underscores. The public catalog/settings ids remain `en-US`/`zh-CN`; any engine-adapter normalization is internal and tested.
- **D-I18N-5:** one live battle transient cannot be safely rebuilt on locale change without presentation duplication. The existing transient completes in its birth locale; all persistent labels and subsequent transients refresh. This deviation may be accepted only with explicit evidence.

## 10. Plan-lint preflight

| Reviewer check | Result |
|---|---|
| Contradictions | Pass: 86 audit candidates + 13 debug + 7 Settings/system + 15 Staging = 121; realized delta is D-I18N-1 |
| Content obtainability | Pass: all shipping resource ids are catalog-linted; developer test stages remain excluded/reachability-tested |
| Parameters | Pass: locales, key count, seed, viewport, font, observation timing, persistence scope pinned |
| Exactness/observation | Pass: 8 paper rules; locale has zero model ticks; visible refresh by next render frame |
| Integrity/ladder | Pass: verbatim integrity rule and L1–L7/final audit included |
| Watchdogs | Pass: 1500-frame interaction derivation ×2 = 3000; 50 s engine ceiling ×2 + 20 s startup = 120 s shell watchdog |
| Scope/trim/resume | Pass: forbidden files, per-phase exclusions, trim order, dependency resume gate included |
| Dependencies/offline | Pass: Agent A/auth explicit; source hash + fonttools 4.63.0 + no-network command pinned; committed subset hash/glyph check is the offline fallback |
| Phase order | Pass: contract/font risk → Settings route → UI migration → verification/ledger |
| Falsifiability | Pass: exact text/state/hash/glyph/rect criteria and named shots |
| Localization | Pass: 121-key freeze, typed formatter failures, en-US default, zh-CN parity, two-button Settings, live refresh, state boundary, custom Theme, 1280/960 layout proof, allowlist lint |

No unresolved semantic question blocks implementation after repository authentication and Agent A ownership are resolved.

## References

[1]: https://docs.godotengine.org/en/stable/tutorials/ui/gui_using_fonts.html "Godot Engine documentation — Using fonts"

[2]: https://notofonts.github.io/noto-docs/website/use/ "Noto documentation — Use Noto fonts (Open Font License)"
