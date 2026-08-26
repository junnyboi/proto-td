# Premium Resonance History and Conversion Runtime

| Field | Value |
|---|---|
| **Phase** | 3 — Godot presentation runtime |
| **Engine** | `4.7.2.stable.official.ed1daf0bf` |
| **Authority** | Canonical `pull_premium_hero` command receipts |
| **Save schema** | Unchanged |
| **Generated assets** | GPT Image 2 Moon Archive glyph and reserve-life sigil |

## Moon Archive

`gacha_history_drawer.gd` is a reusable presentation component owned by the Premium Resonance screen. It receives a defensive runtime projection and never invokes campaign mutation methods. The drawer renders the newest ten committed receipt copies, while `premium_pull_history_total` reports the complete committed count.

The component uses the generated Moon Archive glyph, full-size character-sheet portraits, generated astral rarity stars, acquisition-state text, life deltas, guarantee countdowns, and pull ordinals. Landscape uses a compact 430-pixel right drawer. Portrait and tablet-tall viewports use a full-width reliquary sheet. The list scrolls independently as it approaches the ten-entry bound.

Opening the drawer stores the active browse focus, disables focus behind the scrim, focuses a self-contained Close action, and restores the exact opener after dismissal. `ui_cancel`, Close, and the scrim all dismiss the drawer. Reduced motion replaces the slide transition with an immediate opacity state.

## Duplicate conversion feedback

The settled character reveal reads the current committed receipt. First acquisitions preserve the existing title, astral stars, and Pull Again sequence. Duplicate and revival receipts additionally reveal a generated reserve-life sigil after all rarity stars settle:

- `DUPLICATE RESONANCE CONVERTED`
- `RESERVE LIFE +1` or `REVIVAL PROTOCOL • LIFE +1`
- the authoritative `lives_before → lives_after` delta

The plate fades and scales from 88% to 100%, then the sigil enters a low-amplitude luminance pulse. Reduced-motion mode presents the final plate immediately and suppresses the pulse. The cinematic-only Skip action retires when the identity result appears, leaving the complete result hierarchy and Pull Again inside the landscape and portrait safe areas.

## Localization and accessibility

All new strings are registered in `UiCopy`, `en-US`, and `zh-CN` with typed placeholder contracts. The archive exposes a localized accessibility name, polite total-count summary, row descriptions, focus containment, and deterministic focus restoration. Receipt states use text and star count rather than color alone.

## Verification

Focused validation covers:

- empty and populated archive states;
- exact receipt-derived total and newest-first rows;
- generated manifest assets;
- landscape and portrait containment;
- controller cancel and exact focus restoration;
- first-acquisition suppression of conversion feedback;
- duplicate and revival copy accuracy;
- reduced-motion pulse suppression;
- existing Pull Again, click dismissal, cinematic looping, SFX/BGM, and pity behavior.

Xvfb captures were produced at `1280×720` and `720×1280` for both the archive and conversion states with dummy audio. All four visual harness runs exited without parser, runtime, resource, or leak diagnostics.
