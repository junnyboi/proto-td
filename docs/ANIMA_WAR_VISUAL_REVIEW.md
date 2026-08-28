# Protos Anima War Phase 8 Visual Review

## English S1 dialogue smoke, 150% text scale

- **Landscape, 1280×720:** Pass. Company Manus, speaker, and rescue language are readable; the dialogue plate contains all lines without clipping or overlap.
- **Portrait, 720×1280:** Pass. The larger plate remains inside the viewport; heading, speaker, and full mission line remain visible. Background battlefield telemetry is intentionally subordinate.

## English Anima Archive, 150% text scale

- Initial capture exposed a real accessibility regression: the three-column header consumed the viewport and the record/detail workspace was effectively hidden.
- The repaired layout suppresses redundant eyebrow/intro copy only at large text, uses a compact title, stacks the record rail over the detail panel, enables focus-follow scrolling, shortens player-facing rail labels while preserving full titles and tooltips, and reduces concept-art height.
- **Landscape, 1280×720:** Pass after repair. The active second record is visible as `02 · DIGITAL BIRTH`; its concept, record category, and full `THE FIRST DIGITAL BIRTH` title fit horizontally. Remaining body copy is available through the existing detail scroll.
- **Portrait, 720×1280:** Pass with scroll. The full-width rail and detail panel remain inside the safe frame; rail and detail scroll containers provide access to content below the fold.

## English title and Company Command, 150% text scale

The Company Command capture passes: the PROTOS Defense header, next-operation card, rescue objective, Exit action, and large Mission Control control remain contained; lower content is available through the existing rail scroll.

The title capture fails at 150% scale: the oversized `PROTOS DEFENSE` wordmark extends below the viewport and obscures the primary controls. This is a real accessibility defect and requires responsive wordmark/control tuning before Phase 8 can close.

## Corrected max-scale title and archive outcome

The title harness now applies text scale through the same preference flow used by players. At 150%, the title presents one contained `START` action and the fixed footer `SETTINGS` control; the duplicate central Settings action is intentionally hidden above 120% scale. The full `PROTOS DEFENSE` wordmark and both actions remain visible without overlap.

The archive now shows focused records through its scroll rail. At 150% landscape, the active `02 · DIGITAL BIRTH` row and the full detail title fit horizontally; body copy remains accessible through the existing detail scroll. Compact rail titles are localized presentation labels only—the complete titles remain in detail, tooltips, and accessibility text.

## English Premium Resonance and Training, 150% text scale

Premium Resonance passes in landscape: the balance, pity statement, Return, Resononate, cost, and History controls are visible and contained.

Training fails at 150%: roster filters, sort controls, and lower action panels collide and clip. The screen needs a large-text responsive mode rather than trying to preserve the desktop two-panel density.

## Corrected Training outcome

Training now switches to a stacked, scroll-owned composition above 120% text scale. Filters and auxiliary controls no longer share a narrow row; roster and inspector stack; long selectors widen; inspector controls stack; and the persistent Return action uses a full-width button. Selecting a specialization card promotes that operator immediately without a separate action or bulk-plan review step. At 1280×720 and 720×1280, visible labels stay inside their controls and the remaining roster/inspector content is reachable through the vertical document and panel scrolls.

## English Valhalla and Act II dossier, 150% text scale

Valhalla fails: its two-column composition squeezes the memorial title and return action until words split into fragments and overflow their panels. It needs the same large-text stacked strategy used elsewhere.

The S9 Campaign dossier remains usable. Its route and dossier columns wrap only at word boundaries, each panel owns vertical scrolling, and `ACT II · 09 · THE GREEN CAGE` remains legible. The denser wrapping is expected at 150% and does not overlap controls.

## Corrected Valhalla outcome

Valhalla now hides only redundant explanatory copy above 120% scale, shortens the visible Back label while preserving its full tooltip/accessibility name, and uses a compact title role. Landscape and portrait captures keep Back, Valhalla, the fallen count, faction filters, empty memorial dossier, and fallen-company panel inside the frame without character-by-character wrapping.

## Chinese title matrix correction

The first Chinese title captures rendered the English catalog because the title's preference application restored its saved locale after the harness selected `zh-CN`. This is a harness defect, not a runtime translation defect. The harness will now set locale and text scale together through the real title preference path before recapture.

## Chinese title, 150% text scale

After correcting the harness preference flow, both orientations render the proper `PROTOS 防线`, `开始游戏`, and `设置` catalog entries. Landscape and portrait remain single-line where required, with the primary and fixed Settings actions fully contained.

## Chinese Training, 150% text scale

Landscape and portrait pass. Status/faction filters, name search, recruitment order, shown count, roster card, and the full-width `返回` action stay contained. The English operator callsign is user identity data and correctly remains unchanged.

## Chinese Valhalla and Anima Archive, 150% text scale

Valhalla passes with compact `返回`, `英灵殿`, fallen count, faction filters, empty roster, and memorial dossier contained. The fourth archive record passes: `04 · 人类养殖场` is visibly selected, the full detail title remains legible, and the rail/detail scroll bars expose all remaining content.

## Chinese S16 dossier and Results, 150% text scale

The S16 Campaign dossier passes with independent route and dossier scrolling; `第二幕 · 16 · 帝国铸造厂` remains available in the dossier panel even though the route rail opens at its first item.

Results actions and debrief panels remain contained, but the operator callsign in the reward card is vertically clipped at 150%. This is a genuine Results card height/typography defect and must be repaired before acceptance.

## Corrected Results outcome

The earlier reward-card clipping was partly caused by the old harness forcing the rewards panel to its bottom. Captures now reflect the real initial position. At 150%, the Results screen stacks headline/meta data, keeps the two information panels in landscape, resets panel scrolls after layout, and uses reduced decorative action typography. Landscape and portrait retain the stage result, stars, tally, Mission Yield, Marks, consequence text, Retry, Command, and Back without horizontal overflow; deeper reward and transmission content remains scrollable.

## Chinese S8 dialogue, 150% text scale

S8 mission-start and mid-wave transmissions pass in landscape and portrait. Speaker names, real-time transmission labels, and full objective lines remain inside the dialogue plate with no overlap. The stable tactical telemetry backdrop remains intentionally untranslated test scenery; runtime player copy is localized.

## Matrix completion

The final matrix contains **100 PNG captures**: English and Simplified Chinese; 1280×720 landscape and 720×1280 portrait; 150% text scale; Title, Company Command, Premium Resonance, Training, Valhalla, Results, all four Anima Archive records with audio controls, S9/S12/S16 dossiers, and S1/S3/S7/S8 mission-start and mid-wave transmissions. Every capture completed through Godot 4.7.2 under Xvfb with dummy audio, and every capture log passed the parse/runtime/resource error scan.

Representative manual inspection covered both locales across all named surface families. The final candidate passes containment, word wrapping, scroll reachability, locale correctness, and hierarchy. The fixes discovered by the matrix are now code- and regression-backed rather than being politely ignored—the traditional method favored by haunted menus.

## Evidence scope

This is a technical verification record, not a source of narrative authority. The sole binding lore remains [`NARRATIVE_CANON.md`](./NARRATIVE_CANON.md).
