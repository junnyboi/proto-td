# Simplified Chinese Localization Audit and Remediation

**Status:** Implemented and release-gated

**Locale:** `zh-CN`

**Scope:** Catalog quality, runtime source consumption, font coverage, accessibility metadata, responsive layouts, and locale switching

## Executive result

The Simplified Chinese release is now **structurally complete, font-complete, and visually verified**. The audit found that the reported strange symbols were primarily a **font-packaging defect**, not widespread bad translation. The former bundled subset directly omitted hundreds of required glyphs, leaving rendering dependent on the host operating system. A smaller but material set of translation defects, untranslated source paths, inaccessible English metadata, and responsive layout collisions also existed.

The remediation replaces the incomplete subset with a licensed complete Noto Sans CJK Simplified Chinese face, makes that face deterministic in both body and display font chains, expands the bilingual catalogs from 539 to **761 matched entries**, localizes previously bypassed runtime paths, corrects reviewed Chinese copy, and adds responsive repairs for the highest-risk screens.[1][2][3]

The final candidate has exact key and placeholder parity, **zero missing catalog glyphs**, zero replacement-character markers, and no unresolved player-facing Chinese localization defects in the tested surface matrix.

## What caused the strange symbols?

The original `ProtosSansSC-Subset.otf` covered only part of the shipped Chinese catalog. Before remediation, the effective UI font chain lacked 295 required code points across 212 keys, including 291 Han characters and the directional/book-title symbols `←`, `→`, `《`, and `》`. Missing glyphs could therefore appear as tofu boxes, fallback-style characters, inconsistent metrics, or apparently corrupted symbols depending on the host.

This was distinct from translation quality. Most existing translations were usable, but the audit did identify several incorrect or awkward sentences, inconsistent terminology, English source literals that bypassed valid translations, and untranslated accessibility descriptions. Decorative chevrons and heraldic marks in the faction and memorial UI are image assets rather than text glyphs; those were retained.

## Audit methodology

The audit evaluated all localization layers independently rather than treating the JSON catalog as the entire system.

| Layer | Verification performed |
|---|---|
| Catalog structure | Exact bilingual key parity, nonempty values, stable ordering, and exact placeholder-name parity |
| Translation quality | Domain-by-domain human review of data definitions, campaign narrative, battle, Training, Resonance, Results, memorial, Settings, loading, and accessibility copy |
| Source consumption | Review of production `UiCopy`/I18n lookup paths and removal of hard-coded or raw-resource English presentation strings |
| Font packaging | Direct cmap coverage for every printable character in the final Chinese catalog, plus runtime body/display chain coverage |
| Accessibility | Chinese names, descriptions, status regions, destructive-action consequences, and locale-refresh behavior |
| Responsive layout | Automated geometry assertions plus Xvfb captures at `1280×720` and `720×1280` for ten major UI states |
| Runtime switching | English-to-Chinese-to-English refresh checks with focus retention and no scene reconstruction where supported |

## Implemented fixes

### Font and theme reliability

The incomplete subset was replaced by `ProtosSansSC.otf`, sourced from `NotoSansCJKsc-Regular.otf` under the SIL Open Font License. The copyright and license notice is bundled beside the font. `AetheriaTheme` now uses the Chinese-capable face deterministically for body text and as the display fallback, and the memorial screen explicitly inherits the intended theme.[3][4][5]

A reproducible font-refresh tool validates the source font against every printable code point in `zh-CN.json` before installation. The exhaustive localization test independently verifies direct bundled-font and effective UI-chain coverage.

### Catalog and translation remediation

The bilingual catalogs now contain **761 entries each**, up from 539. Added entries cover missing production keys, accessibility metadata, campaign and squad presentation, Mission Control recruitment, battle stamps and dialogue, faction identity, loading states, Training details, premium identities, cinematic and Moon Archive history states, narrated-archive statuses, Results reward kinds, and memorial records.[1][2]

Reviewed Chinese corrections include:

- grammatically correct Shock Trooper description;
- corrected Stage 6 consent narrative and Stage 7 tactical hint;
- accurate Recruit blocking/deployment tutorial instructions;
- Chinese Training combat facts without misleading `ATK`/`T` abbreviations;
- consistent `迟缓领域`, `部署点`, `高级共鸣`, `露娜莉丝圣物库`, `月辉载体`, `第33连队`, and `英灵殿` terminology;
- natural classifier and spacing rules for lives, pulls, Marks, stars, rewards, and numeric placeholders;
- corrected Settings, Results, memorial, archive, and gacha phrasing;
- exact placeholder compatibility for every bilingual entry.

The seventeen remaining English-identical entries are intentional proper names, speaker names, language labels, time formats, or language-neutral formatting templates such as `PROTOS`, `EN`, `{index}. {title}{status}`, and `{name}\n{cost} DP`.

### Runtime localization coverage

Source paths were updated so Chinese is consumed at presentation time rather than stored as translated state. The remediation covers:

- Campaign route, dossier, state, progress, briefing, and basic-recruitment text;
- Squad identity, cards, loadout, tactical hints, and accessibility;
- operator, trap, spell, wave, result-stamp, deployment, and map-overlay presentation;
- Training identity, statistics, skills, eligibility, progression, rename, errors, tooltips, and accessibility landmarks;
- faction names, subtitles, specializations, and Company 33 identity;
- loading phases and cinematic streaming status;
- premium hero callsigns, classes, receipts, state, confirmation, Moon Archive history, duplicate conversion, and screen-reader transaction consequences;
- Results rewards, transmissions, actions, and consequences;
- memorial heading, classes, factions, stage titles, terminal reasons, counts, and records.

Locale-sensitive colors and behavior remain driven by structured state rather than translated strings.

### Responsive and visual repairs

The Chinese stress pass exposed and fixed several geometry defects that ordinary English tests did not catch:

| Screen | Repair |
|---|---|
| Title | Keeps `PROTOS 防线` on one centered line at landscape and portrait breakpoints with locale-aware display fitting |
| Settings portrait | Keeps `返回`, `设置`, and `语言` on readable single lines; the EN/中文 selector remains fully visible when initial focus enters the compact scroll area |
| Premium Resonance portrait | Increases hero-card height so Chinese name, class, and acquisition state clear lower ornaments |
| Confirm Resonance | Removes redundant card eyebrow labels, increases readable card height/padding, preserves wrapped Chinese copy, and keeps compact padded actions right aligned |
| Shared dialogs | Preserves doubled typography while using safe responsive margins, scrolling, and non-trimming wrapping |

## Final metrics

| Metric | Final result |
|---|---:|
| English catalog entries | 761 |
| Chinese catalog entries | 761 |
| Chinese entries containing Han text | 743 |
| Bilingual key differences | 0 |
| Placeholder mismatches | 0 |
| Literal production lookup keys validated | 330 |
| Unique printable catalog code points | 991 |
| Missing bundled-font code points | 0 |
| Replacement-glyph markers in catalog | 0 |
| Focused Chinese localization/layout tests | 23 passed, 0 failed |
| Complete Godot repository tests | 49 passed, 0 failed |
| Visual stress captures | 20 accepted frames across 10 states |

## Visual stress matrix

The accepted landscape and portrait matrix covers Title, Settings, Campaign, Squad, Training, Premium Resonance, Confirm Resonance, Company Command, Results, and Valhalla. The pass checked missing glyphs, mixed font fallback, clipping, ellipsis, ornament collisions, action padding, scroll ownership, and safe-area containment.

The final matrix confirms that Chinese copy remains readable in the major command loop. Results uses independent scroll regions for long reward and consequence payloads; a partially visible next reward card is an intentional scroll affordance rather than text escaping its card.

## Regression protection

The repository now includes focused Chinese tests for primary-flow consumption, Training, Confirm Resonance geometry, exhaustive font/key parity, runtime locale refresh, accessibility, and responsive layout. Existing campaign, battle, gacha, Results, memorial, title, loading, cinematic, roster, naming, and controller-accessibility tests were extended where necessary.[6][7][8][9]

The deterministic verification commands are:

```bash
python3 tools/refresh_chinese_font.py \
  --source /usr/share/fonts/opentype/noto/NotoSansCJKsc-Regular.otf

godot --headless --fixed-fps 60 --path . \
  --script tests/localization_ui_parity_test.gd

godot --headless --fixed-fps 60 --path . \
  --script tests/chinese_primary_flow_ui_test.gd

godot --headless --fixed-fps 60 --path . \
  --script tests/chinese_training_ui_test.gd

godot --headless --fixed-fps 60 --path . \
  --script tests/chinese_confirmation_layout_test.gd
```

## Conclusion

The strange-symbol report was valid: the build did not ship enough glyphs and was relying on environment-dependent fallback. That root cause is removed. The Chinese catalog, runtime consumption, accessibility surface, and responsive layouts have also been audited and repaired as one release unit rather than hiding rendering defects with alternate wording. Direct import, bounded boot, all 49 repository tests, and strict error-log scanning pass; the candidate is ready for Web export and WebDev deployment.

[1]: ../localization/en-US.json
[2]: ../localization/zh-CN.json
[3]: ../assets/fonts/ProtosSansSC.otf
[4]: ../assets/fonts/NotoSansCJK-COPYRIGHT.txt
[5]: ../scripts/ui/components/aetheria_theme.gd
[6]: ../tests/localization_ui_parity_test.gd
[7]: ../tests/chinese_primary_flow_ui_test.gd
[8]: ../tests/chinese_training_ui_test.gd
[9]: ../tests/chinese_confirmation_layout_test.gd
