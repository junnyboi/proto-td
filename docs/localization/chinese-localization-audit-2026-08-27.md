# Simplified Chinese Localization and Glyph Rendering Audit

**Author:** Manus AI

**Project:** Protos / `junnyboi/proto-td`

**Audit date:** 2026-08-27

**Target engine:** Godot 4.7.2 stable

## Executive summary

The game now has **complete English/Simplified Chinese catalog parity across 925 keys**, including the complete Act II narrative catalog, with no missing Chinese entries, no extra Chinese-only entries, no placeholder drift, no production localization keys absent from the catalogs, and no unresolved hard-coded player-visible strings detected by the strict repository auditor.[1] The remaining 30 values that are intentionally identical across locales are brand names, speaker names such as `PROTOS`, numeric templates, input abbreviations such as `DP`, language labels, or layout-only templates whose dynamic values are localized.

The Chinese glyph failure was caused by an incomplete runtime font contract rather than by the catalog itself. Several standalone battle and utility controls relied on inherited or platform fallback fonts, while the bundled CJK font was loaded through runtime path lookup rather than as an explicit export dependency. The repair makes `ProtosSansSC.otf` an explicit preloaded resource, installs a Chinese-capable global project theme, and applies the same deterministic body/display chain to Aetheria, StagingSkin, Lunaris operations controls, spell status labels, line edits, deployment cards, and accessibility text.[2]

The release candidate was visually inspected through **28 deterministic Godot/Xvfb captures** covering loading, title, settings, Company Command, campaign, Field Team, Training, Premium Resonance browse/history/reveal, victory/defeat Results, Mercy Archive, Vahalla, and battle tutorial/live states in landscape and portrait. Every inspected frame was free of tofu boxes, replacement-character glyphs, nonsensical codepoint symbols, destructive clipping, and untranslated primary controls.[3]

## Audit scope and results

| Audit dimension | Result | Acceptance evidence |
|---|---:|---|
| English catalog keys | 925 | Strict catalog audit[1] |
| Simplified Chinese catalog keys | 925 | Strict catalog audit[1] |
| Missing Chinese keys | 0 | Strict catalog audit[1] |
| Extra Chinese keys | 0 | Strict catalog audit[1] |
| Placeholder mismatches | 0 | Strict catalog audit and Godot parity regression[1] |
| Production localization keys scanned | 616 | Strict source scan[1] |
| Missing production catalog keys | 0 | Strict source scan[1] |
| Unresolved hard-coded visible strings | 0 | `tools/audit_localization.py --strict-hardcoded`[1] |
| Major routed screens visually checked | 14 screen/state families | Visual matrix[3] |
| Landscape/portrait screenshots inspected | 28 | Visual matrix and checksums[3] |
| Tofu/replacement-character findings | 0 | Font regression and visual inspection[2] [3] |

## Root-cause analysis

The bundled `ProtosSansSC.otf` already contained the required catalog glyphs, but the font was not guaranteed to own every UI path. The project had no global custom theme; controls outside an Aetheria shell could therefore resolve through `ThemeDB` or a system font. StagingSkin obtained CJK coverage indirectly from another theme, and standalone Lunaris labels, buttons, and line edits often changed only size/color without installing a font. That architecture could look correct on a development machine while producing missing-glyph boxes on Web or minimal-font systems.

The repair establishes one deterministic chain. The project-level custom theme now points to `threshold_theme.tres`; Aetheria preloads the bundled CJK font as an export dependency; StagingSkin directly preloads and exposes the same CJK body font; Cinzel display text falls back to that body font; and Lunaris battle controls explicitly install the StagingSkin font chain. The regression test enumerates every codepoint used by the Chinese catalog and verifies it against the bundled font, Aetheria body/display fonts, StagingSkin body/display fonts, the global project theme, and representative standalone controls.[2]

## Translation and terminology corrections

The audit did more than fill missing keys. It corrected gameplay semantics and established consistent terminology across screen families.

| Domain | Canonical Chinese contract | Corrected risks |
|---|---|---|
| Mission organization | `任务指挥中心`, `连队指挥部`, `行动收益`, `行动后果` | Removed inconsistent literal translations of “Mission Control,” “staging,” and “yield.” |
| Battle withdrawal | `撤出行动` for resigning; `撤回干员` for withdrawing one unit | Eliminated an ambiguity that previously used `撤退` for both operations. |
| Leak rules | `最多允许3名敌人漏过；第4名敌人漏过时，任务失败` | Replaced game-jargon calques and clarified the exact failure condition. |
| Premium Resonance | `共鸣`, `高级英雄`, `固定精英配置`, `再共鸣…次内必得五星` | Removed “copy” terminology and expressed the pity guarantee as an upper bound rather than an exact pull. |
| Training and identity | `干员`, `新兵`, `晋升`, `进阶专精`, `代号` | Preserved identity continuity and removed generic unit/personnel wording. |
| Memorial | `阵亡名册`, `永久离队`, `第{tick}刻` | Removed unsupported resurrection implications and awkward service-record phrasing. |
| Narrative canon | `日冠`, `延续`, `静默`, `第一花园`, `炉心渡`, `档案术师`, `月辉载体`, `圣物决斗者` | Corrected faction and premium-identity mistranslations, normalized Reliquary terminology, and restored canonical philosophical meaning across Act I/II prose. |

The review also synchronized the Stage 2–4 tactical hints with the retained Shieldbearer, Breacher, and Interceptor content. After the complete Act II narrative landed concurrently, all 123 new English/Chinese entries were re-audited, and inconsistent `档案术士`, `月之容器`, and `圣匣决斗者` references were normalized to the canonical `档案术师`, `月辉载体`, and `圣物决斗者` identities. Because gameplay resources participate in the campaign validation environment, the corresponding campaign environment hash was regenerated and synchronized in both the campaign definition and campaign resource.[4]

## Runtime localization coverage

All high-risk text paths now route through the catalog. Deployment cards use localized templates for operator/trap name and DP cost. Isometric facing buttons expose localized Chinese direction names and descriptions. Premium hero names resolve through one centralized stable-key helper in browse, history, and Results. Results unknown values use localized generic fallbacks rather than converting raw identifiers into English. Field Team presentation labels and Training roster accessibility text no longer branch to hard-coded English. The battle HUD also refreshes immediately when `locale_changed` fires, rather than waiting for a model mutation.

## Visual verification matrix

| Surface | Landscape | Portrait | Key acceptance observations |
|---|---:|---:|---|
| Loading and title | Yes | Title settings portrait | Complete CJK phase/title/action labels; no font substitution artifacts. |
| Settings | Yes | Yes | Audio, graphics, language, return, and apply controls remain contained. |
| Company Command | Yes | Yes | Narrative, mission status, and navigation remain readable after reflow. |
| Campaign | Yes | Yes | Route, dossier, objective, threat, and mission status use Chinese consistently. |
| Field Team | Yes | Yes | Localized training/deploy presentation labels and squad guidance fit. |
| Training | Yes | Yes | Filters, roster rows, identity copy, promotion copy, and actions render correctly. |
| Premium Resonance browse | Yes | Yes | Pity guarantee, balance, premium identities, and actions are localized. |
| Premium history | Yes | Yes | Premium names, ordinal pull labels, life conversion, and pity countdown fit. |
| Premium reveal | Yes | N/A | Full-screen identity and conversion receipt remain legible. |
| Results victory | Yes | Yes | Yield, consequence, rewards, narrative, and actions remain accessible. |
| Results defeat | Yes | N/A | Defeat semantics and consequence layout remain intact. |
| Mercy Archive | Yes | Yes | Long-form Chinese prose stays in scrollable dossier regions. |
| Vahalla | Yes | Yes | Memorial record, permanence copy, tick, and honor action are complete. |
| Battle tutorial/live | Yes | Yes | HUD, tutorial, controls, spells, deploy cards, costs, and wave banner are tofu-free. |

The complete matrix, visual inspection notes, and SHA-256 checksums are stored with the release evidence.[3]

## Regression coverage

The final post-merge release gate passed direct import, bounded boot, **all 57 current repository tests and smokes**, and a strict zero-error log scan. This includes localization parity, Chinese primary flow, Chinese Training, battle UI layout and live locale switching, Slow Field tutorial UI, Premium Resonance UI, Results UI, Vahalla UI, mission layout, title settings, global font scale, early-enemy-variety, Act 2 campaign, non-premium portrait catalog, and Restoration Lattice coverage. The strict localization auditor is now a repository tool and can be rerun with:

```bash
python3 tools/audit_localization.py --strict-hardcoded
```

This command fails on catalog-key drift, placeholder drift, production localization keys missing from the catalogs, or unresolved hard-coded player-visible strings. The generated machine-readable report is written to `docs/localization/latest-audit.json`.[1]

## Conclusion

The Simplified Chinese release is structurally complete, semantically reviewed, export-deterministic, and visually accepted across the game’s primary and dense secondary surfaces. The previous square-and-number glyph failures are addressed at the theme/font ownership layer rather than masked screen by screen. Future changes are protected by catalog parity, codepoint coverage, source-key auditing, hard-coded-copy auditing, live locale-switch tests, and reproducible bilingual visual harnesses.

## References

[1]: ./latest-audit.json "Protos machine-readable localization audit"
[2]: ../../scripts/ui/components/aetheria_theme.gd "Aetheria deterministic CJK font chain"
[3]: ../ui-concepts/ui-revamp/verification/chinese-localization-full-audit/INSPECTION.md "Simplified Chinese visual acceptance matrix"
[4]: ../../data/campaign_def.gd "Campaign environment hash contract"
