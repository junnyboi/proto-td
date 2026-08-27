# Simplified Chinese visual acceptance notes

## Loading and title — landscape

The 1280×720 loading screen renders all Simplified Chinese glyphs cleanly in the bundled typeface. Faction, archive, phase, and detail labels are legible, correctly positioned, and free of tofu, replacement characters, clipping, or Latin fallback artifacts. The 62% state and progress geometry remain intact.

The 1280×720 title screen renders `PROTOS 防线`, `开始游戏`, and `设置` without missing glyphs, overflow, or mixed-font substitution. The large Chinese action labels remain centered and contained within their authored button frames.

## Settings — landscape and portrait

The 1280×720 settings state cleanly renders the localized headings, locale choice, frame-limit section, return action, and apply action; all controls remain within the command frame. The 720×1280 responsive state stacks the language, audio, and graphics sections into the intended scroll layout. `主音量`, `音乐音量`, `音效音量`, and `音乐 // 关` remain legible and tofu-free; the fixed Apply action does not cover active controls. The compact `返回` action is tight but fully readable and inside the safe frame.

## Company Command — landscape and portrait

Both Company Command captures render the localized shell, mission progress, next-operation dossier, action labels, and destination controls with complete glyphs. The corrected operation summary remains readable in the landscape card and in the narrower portrait card without overflow. Portrait reflow preserves the mission command tile, `兵营`, and `共鸣` navigation inside the ornate frame; no English leakage or tofu is visible.

## Campaign — landscape and portrait

The campaign route and dossier render complete Chinese mission titles, status labels, objective, threat, completion count, and return navigation. The corrected `行动路线` and `下一行动` terminology is consistent in both orientations. Landscape keeps both columns readable within independent scroll regions; portrait stacks the route and dossier without horizontal clipping. All Han glyphs, punctuation, stars, numerals, and mixed Latin/Chinese text render cleanly.

## Field Team / mission setup — landscape and portrait

The Field Team screen renders localized mission identity, threat, squad limits, filters, deployment-order copy, objective/threat prose, and actions. `训练干员` and `部署小队` use the new catalog-backed presentation labels rather than hard-coded English. Landscape keeps both information columns and the persistent action dock readable; portrait stacks the roster and dock without overflow. No fallback boxes, replacement glyphs, or untranslated primary controls are visible.

## Training — landscape and portrait

Training renders localized roster counts, faction filters, search/sort controls, class/status/XP labels, selected-operator actions, and promotion readiness without tofu. Proper user callsigns remain intentionally unchanged while surrounding class and status copy is Chinese. The portrait layout preserves the roster card, selected-operator panel, edit action, `暂不训练`, and `查看计划` within the scrollable safe frame; no destructive text clipping is visible.

## Premium Resonance browse — landscape and portrait

The browse state renders `高级共鸣`, the bounded five-star guarantee, shard balance, localized hero/class/status copy, and all actions with complete glyphs. Portrait preserves the top-aligned background and full premium card while keeping `返回`, `开始共鸣`, and `共鸣记录` within the safe frame. Landscape keeps the action bar readable while cards remain in their intended scroll/crop region. No use of the deprecated “copy” or “fixed elite set” terminology remains on screen.

## Premium Resonance history — landscape and portrait

The populated Moon Archive renders its corrected `月之档案` title, localized premium identity `档案术师`, ordinal pull labels, life conversion, pity countdown, and close action in both orientations. All stars, arrows, numerals, and Han glyphs are intact. The small square at the focused Close action is the authored focus indicator—the button text itself is exactly `关闭`, not a missing-glyph box. Rows remain contained and readable across the full-height portrait drawer.

## Resonance reveal and victory Results — landscape

The reveal state renders the localized premium identity, star rating, duplicate conversion, reserve-life increment, life transition, and repeat-pull action with complete glyphs over the top-aligned cinematic plate. The corrected terminology is concise and readable.

The victory debrief renders `第1关已通关`, tally, `行动收益`, `行动后果`, reward reserve, consequence narrative, and persistent actions without tofu or English fallback. Long narrative copy remains inside its independently scrollable column rather than overflowing the ornate frame.

## Results — portrait victory and landscape defeat

Portrait victory stacks the ceremony, tally, reward, consequence, and three actions without horizontal clipping; localized narrative paragraphs wrap naturally and remain within scrollable panels. Landscape defeat renders `第1关未通过`, subdued stars, tally, corrected `行动收益`/`行动后果` terminology, localized consequence copy, and persistent actions with no tofu. The reward and consequence regions retain independent scrolling for additional XP/reward rows.

## Mercy Archive — landscape and portrait

The archive shell renders `仁慈档案`, decryption progress, corrected explanatory prose, encrypted record rows, record title, image, subtitle, and long-form Chinese body text with complete glyphs. Portrait uses the intended nested scroll regions for the record list and dossier; long prose continues below the viewport rather than being cut from the layout. Mixed `PROTOS`, numerals, punctuation, and Han text share a coherent font chain.

## Vahalla memorial — landscape and portrait

The memorial renders the localized shell, fallen count, reviewed permanence text, faction filters, memorial roster, service record, terminal reason, battle tick, and honor action with complete glyphs. Proper callsigns remain intentionally unchanged. Portrait makes the long dossier fully inspectable and shows `第20刻` plus the permanent-death explanation without replacement boxes or clipped Han text; landscape retains the intended scrollable dossier composition.

## Battle tutorial — landscape and portrait

The battle HUD, spell cards, controls, deployment cards, tutorial progress, title, approved route copy, and actions all render in Chinese with complete glyphs. The corrected leak rule is explicit: three enemies may pass and the fourth ends the mission. Landscape and portrait retain the left-aligned tutorial card, responsive type scale, centered HUD copy, and contained actions. No `CENTER` control or tofu glyph is present.

## Live battle — landscape and portrait

The live HUD, wave banner, pause/speed controls, operation-withdraw action, deployment roster, traps, spells, status text, DP costs, and portrait reflow all render in Chinese with no tofu. `撤出行动` is visibly distinct from per-unit `撤回干员` in the catalog/test contract. Buttons stay inside their command decks, spell and deployment regions remain separate, and all mixed numerals/Latin `DP`/multiplication signs render correctly.

## Overall visual result

All 28 captured states pass visual inspection for Simplified Chinese glyph integrity, primary-copy localization, responsive containment, and the absence of replacement boxes or nonsensical codepoint symbols. Scrollable screens preserve access to long prose and dense rows rather than silently truncating content.
