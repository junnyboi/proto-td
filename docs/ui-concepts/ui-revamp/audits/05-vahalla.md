# UI Revamp Audit 05 — Vahalla Memorial and Loss Dialogs

**Audit family:** Vahalla memorial, fallen roster, identity details, death/life messaging, and related loss confirmation UI  
**Repository revision:** `6f382b621c812c29dacfa79a41fe59e19909709c`  
**Target viewports:** `1280×720` landscape and `720×1280` portrait  
**Visual benchmark:** premium, clearly adult **21+** anime-gacha presentation in the approved Lunaris Reliquary language  
**Change boundary:** documentation only; no gameplay, simulation, scene, script, resource, or localization source was modified

## Executive assessment

Vahalla is functionally coherent but visually and emotionally underdeveloped. It already preserves the most important campaign rules: only terminally fallen heroes enter the memorial, faction filtering is presentation-only, a fallen hero cannot deploy, premium heroes enter only after their final stored life is consumed, and a later duplicate premium pull restores the same persistent hero and removes the memorial record. The screen also has a usable faction filter, localized copy, responsive one/two-column switching, an empty state, and a visit-local **HONOR** interaction.

The current presentation does not yet meet the accepted Lunaris target. It is a dark utility sheet composed from flat `StyleBoxFlat` surfaces, repeated red cards, small technical metadata, and narrow centered portraits. It neither uses the generated ceremonial memorial icon/frame vocabulary already present in `assets/ui/staging/` nor creates the character-forward editorial hierarchy established by the Mission and Training concepts. Most importantly, the loss flow is fragmented: the Results dialog reports premium life expenditure in hard-coded English but does not present ordinary permanent deaths, display the actual persistent callsign, or provide a direct route to Vahalla. Raw stage IDs, raw terminal-reason enums, and simulation ticks are exposed as if they were authored narrative.

The revamp should therefore treat this family as a single **continuity-and-consequence flow**: battle resignation warning → terminal result → explicit casualty/life ledger → Vahalla archive → selected hero dossier. Native campaign data must remain authoritative; the redesign should only improve projection, copy, information hierarchy, accessibility, and responsive containment.

## Sources reviewed

| Area | Files reviewed | Relevance |
|---|---|---|
| Project contract | `project.godot`, `README.md` | Godot 4.7.2 context, 1280×720 base viewport, deterministic model/view boundary, documentation-only validation policy |
| Approved art direction | `docs/ART_DIRECTION.md`, `docs/PREMIUM_HERO_SYSTEM.md` | 21+ adult character rule, premium anime realism, Lunaris materials, persistent identity, permanent death, stored-life and revival semantics |
| Accepted UI concepts | `docs/ui-concepts/LUNARIS_ENTRY_REDESIGN.md`, `docs/ui-concepts/MISSION_TRAINING_GACHA_UI.md`, `docs/ui-concepts/STAGING_CONCEPT_FIDELITY_PLAN.md`, `docs/ui-concepts/ui-revamp/reference-findings.md` | Character-forward asymmetry, full-safe-viewport layout, angular glass/brass/cyan components, Cinzel display hierarchy, persistent actions, portrait gates |
| Vahalla UI | `scenes/vahalla.tscn`, `scripts/ui/vahalla.gd` | Screen construction, cards, death record, honor state, back route, breakpoints |
| Shared roster UI | `scripts/ui/components/roster_filter.gd`, `scripts/ui/components/roster_filter_bar.gd`, `scripts/ui/components/faction_heraldry.gd`, `scripts/ui/components/training_support.gd` | Fallen classification, faction derivation, counts, filter interaction, callsign and class projection |
| Shared styling and copy | `scripts/ui/components/lunaris_ops_style.gd`, `scripts/ui/components/ui_copy.gd`, `localization/en-US.json`, `localization/zh-CN.json`, `autoloads/i18n.gd` | Flat surface roles, typography, localized strings, placeholder validation and bilingual parity |
| Navigation and entry | `autoloads/game.gd`, `scripts/ui/staging.gd` | `VahallaButton`, `Game.open_vahalla()`, return to Company Command, campaign projection seam |
| Loss and confirmation UI | `scenes/results.tscn`, `scripts/ui/results.gd`, `scripts/ui/battle_controls.gd`, `scripts/view/battle_view.gd`, `scripts/ui/components/aetheria_screen_shell.gd` | defeat summary, premium life-loss copy, consequence text, result actions, terminal continue route, resignation confirmation |
| Authoritative lifecycle | `sim/hero_identity.gd`, `sim/campaign_v3_attempts.gd`, `sim/campaign_state_v3.gd`, `sim/campaign_v3_codec.gd`, `sim/campaign_v3_history.gd` | persistent hero identity, death record and memorial schema, terminal lockout, lifecycle validation |
| Existing tests | `tests/vahalla_ui_test.gd`, `tests/faction_roster_filter_test.gd`, `tests/premium_hero_system_test.gd`, `tests/custom_naming_roster_test.gd` | current executable UI, filtering, identity, death, premium life, revival, and deployment contracts |
| Available visual assets | `assets/portraits/`, `assets/ui/factions/`, `assets/ui/staging/icons/memorial.png`, `assets/ui/staging/icons/lunaris_seal.png`, `assets/ui/staging/frames/command_deck.png`, `assets/ui/staging/frames/operation_tile.png`, `assets/ui/staging/frames/primary_button.png` | Existing production assets that can establish memorial fidelity without baking runtime copy into imagery |

## Screen and state inventory

| Surface or state | Entry and exit | Current visible content | Functional interactions |
|---|---|---|---|
| **Company Command memorial entry** | `Staging/VahallaButton` → `Game.open_vahalla()` | Enabled Memorial glyph tile labeled **Vahalla** | Pointer/keyboard activation; staging focus order includes the tile |
| **Vahalla — populated archive** | Dedicated `scenes/vahalla.tscn`; Back or `ui_cancel` → Company Command | Lunaris heraldry, title, fallen count, permanence intro, faction filter, two-column memorial grid | Back; select All or one of four factions; scroll; activate Honor |
| **Vahalla — filtered archive** | Faction filter buttons | Count updates to the visible faction subset; only matching fallen records render | Selected filter updates visual state and emits `filters_changed`; status remains forced to Fallen |
| **Vahalla — empty state** | Campaign has no fallen heroes or selected faction has no match | Centered “No fallen soldiers…” copy | Filter remains available; Back remains available |
| **Memorial card — unhonored** | Created for each visible fallen projection row | Portrait, faction symbol/name, callsign, class, one-line death record, **HONOR** | Honor marks the hero in visit-local `_honored` state, plays click SFX, and rebuilds the grid |
| **Memorial card — honored** | Same visit after Honor | **HONORED** disabled action | State is intentionally presentation-only and resets when the screen is re-entered; no campaign write occurs |
| **Squad-selection Fallen roster dependency** | `FallenRosterTab` in squad selection | Fallen count and disabled fallen card | Fallen hero is hidden from Active by default, revealed by Fallen, and remains non-deployable |
| **Battle terminal defeat overlay** | Battle model becomes terminal | **DEFEAT** stamp and `ContinueButton` | Continue routes to Results |
| **Results — defeat/loss summary** | `Game.open_results()` | Defeat headline, kills/leaks, premium life-loss rows when present, stage consequence, action row | Retry, optional Train Recruits, Return to Staging, Back to Title; `ui_cancel` returns to title |
| **Resign confirmation** | In-battle Resign | Centered “Resign this battle?” / “Counts as a defeat.” panel | Opening pauses; Cancel restores prior speed; Confirm applies `resign`; Space pause is suppressed while open |
| **Premium revival dependency** | Duplicate pull of a zero-life premium hero | Outside this screen family, but changes memorial membership | Same hero returns to Ready, death is cleared, and memorial entry is removed |

## Current information and interaction flow

```text
Company Command
  └─ Vahalla tile
      └─ Vahalla projection: fallen_heroes + memorial
          ├─ faction filter (presentation only)
          ├─ memorial card
          │   └─ HONOR → visit-local HONORED
          └─ Back / Escape → Company Command

Battle
  ├─ Resign → confirmation → defeat
  └─ terminal defeat → Continue → Results
      ├─ premium_life_losses (shown)
      ├─ dead_hero_ids / memorial_ids (not shown as identities)
      ├─ Retry
      ├─ Return to Staging
      └─ Back to Title

Premium Resonance
  └─ duplicate pull at zero lives → same hero Ready → memorial entry removed
```

## Feature contracts that must survive

| Contract | Required behavior | Audit consequence |
|---|---|---|
| **Simulation remains authoritative** | UI reads `Game.campaign_projection()` / `Game.last_result`; it must not independently determine death, consume lives, revive heroes, or edit memorial rows. | New cards, drawers, and summaries must be projections only. No honor state may enter campaign hashes unless separately designed as a gameplay feature. |
| **Persistent identity** | `hero_id` remains the stable person. Custom callsign takes precedence; premium identity is fixed; portrait and class come from the projected hero/memorial record. | Selection, card keys, focus restoration, and dossier updates must key by `hero_id`, never display name or list index. |
| **Fallen classification** | A row is fallen when `life_status == "dead"` or a death record exists. Active filters exclude fallen; Fallen filters exclude active. | Visual redesign cannot loosen deployment eligibility or invent a third lifecycle state from color alone. |
| **Faction filtering is noncanonical** | Faction annotation and derivation remain presentation-only; explicit canonical faction wins, known prefixes derive faction, unknown identity safely falls back to active Lunaris. | Keep filter state out of saves and hashes. Preserve All + four faction choices and visible per-faction counts. |
| **Ordinary death is permanent** | A terminal ordinary fall produces `ready → dead`, a death record, a sorted `dead_hero_ids` entry, and a memorial record. Healing cannot revive the dead. | Use unambiguous permanent-loss language; do not imply a generic revive purchase for ordinary recruits. |
| **Premium stored lives** | A premium fall consumes exactly one life. If lives remain, the hero stays Ready and does not enter the memorial. Final-life loss sets Dead/0 and creates the memorial. | Results must distinguish **life spent** from **terminal lockout**; Vahalla should show zero-life premium state without presenting every premium fall as death. |
| **Premium restoration** | Pulling the zero-life premium identity restores that same hero, clears death, and removes memorial membership. | Memorial UI must tolerate records disappearing after a campaign refresh and must not call premium lockout “permanent death.” Copy should say locked until resonated/pulled again. |
| **Deployment exclusion** | Fallen heroes never appear as deployable Active roster choices and fallen squad cards remain disabled. | Any “view in roster” or memorial-to-mission affordance must remain informational, never deploy directly. |
| **Memorial record integrity** | Terminal records carry `stage_id`, `terminal_reason`, `terminal_tick`; unknown/absent records safely display a sealed-record fallback. | Presentation may map IDs to authored stage titles and reason copy, but must retain a safe fallback and must not mutate the source record. |
| **Honor is visit-local** | Current `_honored` state is non-persistent, idempotent within one visit, disables the button, and changes copy to HONORED. | Preserve this unless product explicitly approves persistence. The revamp should retain local state while filtering/rebuilding and restore focus to the honored item. |
| **Back and cancellation semantics** | Vahalla Back and `ui_cancel` return to Company Command. Results and resign confirmation preserve their existing routes and time-scale behavior. | Restyling cannot change destination or allow battle ticks to run behind the confirmation. |
| **Localization schema** | English and Simplified Chinese catalogs have identical sorted keys and matching placeholder sets; `ui.vahalla.record` requires exactly `stage:String`, `reason:String`, `tick:int`. | New copy must be added to both canonical JSON catalogs and `UiCopy.STATIC_FALLBACKS`; placeholder types must be registered. |
| **Native accessible controls** | Text stays native, filters and actions remain focusable, minimum targets remain at least 44×44, and generated frames contain no baked labels. | Use NinePatch/StyleBoxTexture decoration around Buttons and Panels; preserve tooltips and visible focus. |

## Visual and UX gap analysis

### 1. The memorial is a flat administrative list, not a Lunaris reliquary

`VahallaScreen` uses a solid near-black backdrop, one large rectangular shell, a quiet intro panel, and red `danger` cards. The same four-pixel rounded `StyleBoxFlat` construction appears across every surface. There is no lunar mechanism, engraved brass, constellation geometry, memorial seal, ceremonial light, archive-depth staging, or asymmetrical editorial composition. The available `memorial.png`, Lunaris seal, faction heraldry, command-deck frame, and generated button frames are unused.

The saturated burgundy danger treatment also frames every hero as an error state. A memorial should communicate gravity and prestige, not only system danger. Crimson can mark terminal status in a small seal or rule; the dominant materials should remain ivory, moon-cyan, violet-black, brushed gold, and deep glass.

### 2. Portraits exist but are not the emotional focus

Each card gives the portrait a fixed `150×205` region and centers the texture without a deliberate editorial crop. The design does not distinguish premium hero art from ordinary recruit portraits, does not provide a selected dossier, and does not use the face/hair/upper-costume priority mandated by the art direction. The resulting two-column list reads as repeated database rows rather than a hall honoring attractive, clearly adult operators.

The screen should not sexualize death or turn loss into a pull advertisement. Character appeal should come from mature portrait rendering, confident identity preservation, restrained framing, and ceremonial material treatment—not provocative crops, excessive bloom, or a celebratory gacha-reveal pose.

### 3. Identity details are incomplete and sometimes wrong for player recognition

The card correctly resolves the callsign and class, but omits custom title, hero kind, premium fixed identity, remaining/terminal life state, recruitment/service continuity, and a clear status label. It does not expose a larger selected portrait or selected-record dossier. Results is worse: `_premium_name()` title-cases the `premium_id`, so loss messaging can display an implementation-derived label instead of the hero’s actual persistent callsign. Ordinary `dead_hero_ids` are not resolved to any visible identity at all.

A memorial should foreground **who was lost** before where or when. The minimum identity hierarchy is callsign, optional title, class/role, faction, recruit/premium status, and terminal state. Internal `hero_id` should remain available for diagnostics/accessibility but should not become primary copy.

### 4. Death metadata is technically accurate but narratively raw

The line `FELL AT S1 • RESIGN • TICK 20` exposes raw `stage_id`, enum formatting, and simulation tick. This is compact but not player-authored language. Stage IDs should resolve through the stage catalog to localized titles, terminal reasons should map to localized consequence labels, and tick should be demoted to an optional archival detail such as “Record 20” only if product wants technical provenance visible.

The unknown fallback **SERVICE RECORD SEALED** is appropriate and should remain. The known-record treatment should use authored copy such as **Final operation — First Stand** and **Cause — Command withdrawal**, with raw IDs available only in a secondary record line or debug tooltip.

### 5. Life-loss messaging is incomplete, hard-coded, and inconsistent

Results reports premium loss using hard-coded English strings:

- `{premium_id} spent 1 life • N remaining`
- `{premium_id} spent their last life • LOCKED until pulled again`

These strings bypass `UiCopy` and both locale catalogs, and use implementation IDs rather than the projected callsign. Results does not list ordinary permanent deaths, despite receiving `dead_hero_ids` and `memorial_ids`. It also gives no direct **View Memorial** action after a terminal loss. Therefore the immediate consequence screen can say **DEFEAT** while failing to name the person newly lost.

The semantic distinction must remain precise:

| Event | Required player-facing meaning |
|---|---|
| Premium fall with lives remaining | **Reserve spent; hero remains deployable** with exact lives remaining |
| Premium final-life fall | **Signal lost / locked at 0 lives; memorialized until resonance restores the same hero** |
| Ordinary terminal fall | **Permanent death; hero cannot deploy or train and is now recorded in Vahalla** |
| Defeat with no hero fall | Mission consequence only; do not imply a casualty |

### 6. Honor rebuilds the whole grid and can break interaction continuity

Honor is a useful non-economic ritual, but `_on_honor_pressed()` rebuilds every card. The focused Button is destroyed; focus and scroll anchor are not explicitly restored. Filtering does the same. This is particularly visible in portrait after scrolling to a later record. The action also has no animation, sound distinction, focus return, or accessible status announcement beyond the disabled label.

The local-only behavior is acceptable and safer than silently introducing persistence. It should be made explicit in implementation comments and tests. Update the selected card in place where possible, or capture `hero_id`, scroll position, and focus before rebuild and restore them after.

### 7. Filtering is functional but visually anonymous

The Vahalla screen hides status tabs and keeps only faction buttons, which is correct because the screen is already exclusively Fallen. However, the filter group has no visible section label, the non-All faction controls display only a symbol and number, and faction names exist only as tooltips. This is weak for touch, controller, and first-time users. The filter also has no “showing X of Y” summary, and no selected-faction name beside the total.

Use an explicit **Archive filter** label, retain the icon/count compact controls, and show the selected faction name in the results summary. Tooltips should supplement—not replace—visible or accessible names.

### 8. Naming and copy governance are inconsistent

The branded spelling **Vahalla** is embedded in scene names, node names, keys, navigation methods, tests, English copy, and Chinese title translation. Conventional English is “Valhalla,” while the eyebrow says **Hall of the Fallen**. Renaming this casually would create broad key/test churn. Product must decide whether **Vahalla** is an intentional in-world proper noun. Until then, preserve identifiers and routes, but add a copy decision gate before visual production. If corrected, migrate visible copy separately from stable scene/function identifiers unless a planned refactor covers all call sites.

The English back label uses the Unicode arrow `←`, while prior Web validation found a diagonal Unicode arrow missing from a bundled font and switched to ASCII. The memorial should use the generated exit/back glyph or a verified icon rather than relying on a potentially unsupported text glyph.

### 9. Loss-adjacent surfaces do not share one component system

Vahalla uses `LunarisOpsStyle`; Results uses the centered Aetheria dialog shell; Resign uses an unthemed code-built `PanelContainer` and default Buttons. This creates three unrelated visual dialects for one emotional flow. The accepted concepts explicitly reject generic centered utility dialogs and call for a persistent action dock, character-forward dossiers, black-blue glass, clipped corners, and restrained cyan/gold state accents.

The redesign should share a **Lunaris consequence kit**: archival panel, casualty row, state seal, modal scrim, focused action frame, and typography roles. The simulation and navigation code can stay separate.

### 10. Focus, accessibility, and modal behavior need explicit contracts

Vahalla does not explicitly grab initial focus or restore focus after rebuild. Resign confirmation gives every Button `FOCUS_NONE`; it works for pointer input but offers no controller/keyboard selection model for Confirm/Cancel. The confirmation has no full-screen scrim, no focus trap, and no `ui_cancel` handling that maps to Cancel. Results does wire focus, but `ui_cancel` jumps to title rather than the visually adjacent staging action, an existing behavior that should be retained unless product explicitly changes it.

Memorial portraits have no accessible description, faction-only icon buttons depend on tooltips, and status change has no live announcement seam. At minimum, set useful `tooltip_text`/accessible descriptions, preserve 44×44 targets, provide visible focus on all active controls, and verify controller navigation in both orientations.

## Proposed target design

### Landscape composition — 1280×720

Use the full safe viewport instead of a centered monolithic plate. Keep a compact top operational header and a persistent archive body:

1. **Top rail (72–88 px):** generated Memorial glyph, eyebrow **LUNARIS RELIQUARY / MEMORY ARCHIVE**, large **VAHALLA** wordmark pending spelling decision, visible fallen metric, and a framed Company Command back action.
2. **Left archive rail (approximately 34%):** scrollable compact fallen roster with 88–104 px portrait crops, callsign, title/class, faction seal, and a clear terminal-status marker. Faction filters sit above this rail.
3. **Right selected dossier (approximately 66%):** one large adult portrait with safe face/upper-costume crop, lunar record halo, callsign/title, class/faction, life/death state, authored final-operation summary, and a secondary technical record.
4. **Bottom ritual/action dock:** **HONOR MEMORY** as the focused ceremonial action, with nonpersistent semantics; optional **RETURN TO COMMAND** remains available in the header. Do not add monetization to ordinary death. A premium zero-life dossier may show informational copy **Resonance can restore this same hero** but should route to Premium Resonance only if product approves the cross-navigation.

This roster/dossier structure follows the accepted Training pattern while adapting it for solemn archival use. When no record is selected, select the first visible hero deterministically. When filtering removes the selected hero, select the first remaining hero; if none remain, render the empty archive state without a stale dossier.

### Portrait composition — 720×1280

Use a full-height sheet with fixed header and filter summary, then one controlled internal scroll region:

1. Compact top rail with icon back action, two-line identity, and fallen count.
2. Horizontally scrollable or wrapping faction filter strip with visible selected-faction name.
3. Selected dossier first: wide portrait crop capped near 300–340 px high, identity and terminal state immediately below.
4. A collapsed **Service record** disclosure followed by the fallen roster, or a roster-first selector with a sticky selected-summary header. Do not nest two uncontrolled vertical scroll containers.
5. Sticky bottom **HONOR MEMORY** action within the safe area. The action must remain visible without forcing the portrait to an ambiguous or overly tight crop.

### Component specification

| Component | Visual treatment | Functional requirements |
|---|---|---|
| `MemorialArchiveShell` | Near-black/violet glass, protected clipped corners, fine brass engraving, restrained cyan memory traces | Full-viewport responsive host; fixed header/action regions; one owned scroll region |
| `MemorialRosterRow` | Compact adult portrait, faction micro-seal, ivory callsign, muted class, crimson terminal diamond | Stable `hero_id` key; selected/focus states; no deployment action |
| `MemorialDossier` | Large portrait stage, moon-ring mechanism, asymmetric identity block, narrow archival dividers | Custom callsign/title, localized class/faction, hero kind, terminal status, safe crop and alt description |
| `TerminalStateSeal` | Small crimson/ivory seal for **FALLEN**; gold/cyan variant for premium **SIGNAL LOST / 0 LIVES** | State cannot be communicated by color alone |
| `DeathRecordBlock` | Gold labels, ivory authored value, muted technical provenance | Localized stage title and reason; sealed-record fallback; raw tick de-emphasized |
| `HonorMemoryButton` | Generated primary frame with subdued gold activation and cyan focus, not reward-confetti | Visit-local idempotence; disabled Honored state; SFX; focus and scroll preservation |
| `CasualtyLedger` | Results-section rows using the same dossier identity grammar | Show ordinary permanent deaths and premium losses separately; actual callsigns; localization |
| `LunarisConfirmSheet` | Dark scrim, command-deck frame, warning seal, explicit destructive/secondary actions | Opening pauses; Cancel/Escape restores prior speed; Confirm resigns; focus trapped and restored |
| `ArchiveEmptyState` | Memorial glyph, one concise paragraph, current faction label | Filter controls and Back remain usable; no fake card or disabled action |

### Color and typography hierarchy

Use the established palette: moonless ink `#040A12`, black-blue glass `#0B1827`, ivory `#F5EFE1`, restrained gold `#D9B96E`, moon-cyan `#91EAF1`, muted steel `#AEBFD0`, violet depth `#66577F`, and crimson only for terminal status. Cinzel or the established staging display face should serve Latin display headings and callsigns; body copy and all Simplified Chinese text must use the complete Noto-based fallback. Avoid glow-heavy cyberpunk treatment, rounded mobile cards, flat red slabs, giant centered utility dialogs, and tiny uppercase metadata.

## Detailed copy recommendations

| Current | Recommended direction | Reason |
|---|---|---|
| `FELL AT S1 • RESIGN • TICK 20` | `FINAL OPERATION  •  FIRST STAND` / `COMMAND WITHDRAWAL  •  ARCHIVE RECORD 20` | Resolves raw IDs to authored meaning and demotes simulation vocabulary |
| `Those recorded here are no longer deployable…` | Keep the permanence sentence, then add premium exception only where relevant: `Ordinary death is permanent. A zero-life premium signal can be restored only by resonating that same hero again.` | Prevents contradictory death/revival messaging |
| `Archive Caster spent 1 life • 1 remaining` | `{callsign} expended one stored life and remains READY • {lives} remaining` | States deployability and persistent identity clearly |
| `…spent their last life • LOCKED until pulled again` | `{callsign} lost their final stored life • SIGNAL LOST • recorded in Vahalla until the same resonance returns` | Connects terminal lockout to memorial and avoids generic revival implication |
| No ordinary casualty row | `{callsign} fell permanently and has been entered in Vahalla.` | Makes the loss immediate and names the person |
| `Resign this battle? Counts as a defeat.` | `WITHDRAW FROM OPERATION?` plus `This records a defeat. Any terminal falls in the resolved battle remain subject to ordinary death and premium-life rules.` | Communicates actual consequence without claiming resignation itself kills heroes |
| `HONOR` | `HONOR MEMORY` / `MEMORY HONORED` | More specific ceremonial intent |

Every new string should be represented by a `ui.vahalla.*`, `ui.results.loss.*`, or `ui.battle.resign.*` key in `UiCopy`, `en-US.json`, and `zh-CN.json`. Terminal reasons require a finite localized mapping with a safe unknown fallback; do not localize by replacing underscores at runtime.

## Responsive risk assessment

### 1280×720

| Risk | Current cause | Required mitigation and acceptance |
|---|---|---|
| **Vertical crowding above the scroll region** | Header, intro panel, filter bar, and 16 px separations all consume fixed height before cards. | Collapse intro into the dossier or one-line archive note. Header, filter, selected record, and primary action must be visible together at 720 px; only roster/record detail may scroll. |
| **Two-column card overflow** | Each card has a 420 px minimum, 36 px panel padding, 150 px portrait, and unwrapped detail labels; each grid column is only roughly half of the remaining 1160 px content width. | Replace cards with a rail+dossier layout. Until then, enable controlled wrapping/truncation and test longest English/Chinese stage/reason strings with horizontal scrolling disabled. |
| **Action/focus loss after rebuild** | Honor and filters destroy and recreate all cards. | Preserve selected `hero_id`, focus owner, and vertical scroll; assert honored control remains visible and focusable/announced after update. |
| **Centered Results plate feels detached** | Results is capped at `900×600` within a centered Aetheria shell. | Convert loss ledger to the shared consequence shell or at least add character identity rows and a persistent action dock without expanding beyond the 720 px safe area. |
| **Resign modal competes with battle HUD** | Code-built panel has no scrim and is positioned by its current size. | Add full-viewport scrim and safe-area clamp; verify it stays above HUD and below no interactive battle controls. |

### 720×1280

| Risk | Current cause | Required mitigation and acceptance |
|---|---|---|
| **Unwrapped death record forces horizontal minimum** | `detail` Labels do not enable autowrap; the memorial scroll explicitly disables horizontal scrolling. | Use wrapping RichText/Label with a defined width, or split metadata into labeled rows. No horizontal clipping in English or Chinese. |
| **Portrait plus details can exceed card width** | Fixed 150 px portrait remains side-by-side at the portrait breakpoint. | Stack or use roster/dossier composition. Portrait crop must preserve face, hair, upper costume, and adult identity without covering actions. |
| **Header becomes three full rows** | Grid changes from 3 columns to 1 but retains Back, identity, and count as separate children. | Use a compact portrait top rail with icon Back, flexible title block, and inline metric; target 72–96 px rather than three generic rows. |
| **Filter wrapping and ambiguous icon buttons** | All + four factions can wrap; faction names are tooltip-only. | Use a horizontal filter rail or compact single-row selector, with selected name in visible summary and 44×44 minimum targets. |
| **Long roster hides Honor** | Honor currently lives inside each scrolled card. | Move selected-record ritual action to a sticky safe-area dock. Keep exactly one primary Honor action visible. |
| **Nested scroll danger in redesign** | A dossier, service record, and roster can each invite scrolling. | Assign one vertical scroll owner. If the roster scrolls separately, service details must collapse rather than create a second competing region. |
| **Results action stack height** | Portrait changes all Result actions to one column and may also show training availability plus consequence copy. | Keep the action dock visible; constrain narrative/casualty ledger to internal scroll. Test maximum four actions and multiple casualty rows. |
| **Chinese expansion and glyph support** | Longer Chinese Back copy and Unicode arrows; display font lacks CJK. | Use icon assets for arrows, switch all CJK display roles to the Noto fallback, and test `zh-CN` at target portrait size. |
| **Modal controller accessibility** | Resign buttons are `FOCUS_NONE`; no Escape-to-cancel path. | Give Confirm/Cancel focus, default safely to Cancel, trap focus, map `ui_cancel` to Cancel, and restore focus to Resign afterward. |

## Implementation targets

The following are exact presentation-layer targets; authoritative gameplay behavior in `sim/` should not be changed for this revamp.

| Priority | Target | Change package |
|---:|---|---|
| P0 | `scripts/ui/results.gd` | Resolve actual casualty identities; localize premium-life copy; show ordinary deaths; distinguish nonterminal life spend from terminal lockout; add a conditional **View Vahalla** route after memorial creation. |
| P0 | `scripts/ui/vahalla.gd` | Replace repeated flat two-column cards with responsive roster+dossier selection; retain filter, empty, honor, back, and sealed-record behavior; preserve focus/scroll across state changes. |
| P0 | `scripts/ui/components/ui_copy.gd`, `localization/en-US.json`, `localization/zh-CN.json` | Add typed casualty, premium-life, terminal-reason, selected-faction, dossier, resign-warning, and honor-status strings with exact placeholder parity. |
| P1 | `scripts/ui/components/roster_filter_bar.gd` | Add visible/accessibility labels and selected-faction summary while preserving counts, icon order, and `filters_changed(status, faction_id)`. |
| P1 | New `scripts/ui/components/memorial_roster_row.gd` | Compact hero selector keyed by `hero_id`, with portrait, callsign/title, class, faction, and terminal seal. |
| P1 | New `scripts/ui/components/memorial_dossier.gd` | Selected identity, large adult portrait, record block, premium/ordinary lifecycle message, and honor action. |
| P1 | New `scripts/ui/components/casualty_ledger.gd` | Shared Results rows for ordinary death, premium reserve loss, and premium terminal lockout. |
| P1 | `scripts/ui/battle_controls.gd` | Restyle `ResignConfirm` as a proper modal with scrim, focus trap, Escape-to-cancel, safe default, and focus restoration while retaining pause/restore/apply-action semantics. |
| P1 | `scenes/vahalla.tscn`, `scenes/results.tscn` | Keep thin root scenes but attach reusable layout hosts/components where useful; preserve full-rect anchors and existing scene paths. |
| P1 | `scripts/ui/components/lunaris_ops_style.gd` or a new narrowly scoped `lunaris_consequence_style.gd` | Add textured/NinePatch archival, terminal seal, selected row, scrim, and modal roles without regressing current users of flat roles. |
| P2 | `scripts/ui/staging.gd`, `autoloads/game.gd` | Preserve `VahallaButton` and `Game.open_vahalla()`; optionally add a Results-to-Vahalla return context without changing the stable scene path. |
| P2 | `scripts/view/battle_view.gd` | Preserve `ContinueButton` → Results; visually align the terminal stamp/continue affordance with the consequence kit if included in the polish pass. |
| P2 | `assets/ui/staging/icons/memorial.png`, `assets/ui/staging/icons/lunaris_seal.png`, `assets/ui/staging/frames/*`, `assets/ui/factions/*` | Reuse approved runtime assets through scalable native controls; commission only missing standalone archive frames or terminal seals, with no baked text. |

## Exact test targets

### Existing regressions to retain and expand

| Test file | Existing contract | Required additions |
|---|---|---|
| `tests/vahalla_ui_test.gd` | Fallen soldier is absent from Active squad, visible and disabled in Fallen; staging tile is enabled; memorial card exists; Honor becomes disabled and reads HONORED. | Assert Back and `ui_cancel` route to staging; All/faction counts; populated and empty states; selected dossier identity; custom callsign/class/faction; sealed record; localized stage/reason; honor state survives filter round-trip within visit; focus and scroll preservation; portrait mode switches to the intended composition. |
| `tests/faction_roster_filter_test.gd` | Active/Fallen exclusivity, faction counts, explicit/derived/fallback faction identity. | Add death-present-but-status-default row; all four factions; unknown prefix fallback; stable order; filter input immutability; zero-result selected faction. |
| `tests/premium_hero_system_test.gd` | One life consumed per fall, Ready while lives remain, zero-life Dead/memorial, cannot deploy, repeat pull restores same hero and removes memorial. | Assert UI projection has enough actual callsign/portrait/faction data for the ledger; ensure nonterminal premium loss never appears in `fallen_heroes`; final loss has matching death and memorial IDs. Do not weaken model assertions for presentation. |
| `tests/custom_naming_roster_test.gd` | Custom callsign survives runtime projection, annotation, and filtering. | Assert memorial and Results casualty projections use custom callsign, optional title, and stable `hero_id`; premium fixed names remain unchanged. |

### New focused UI tests

| Proposed exact path | Required assertions |
|---|---|
| `tests/vahalla_responsive_ui_test.gd` | Instantiate at `1280×720` and `720×1280`; no control escapes viewport; no horizontal scroll; header/filter/selected identity/Honor visible; roster scrolls; longest `en-US` and `zh-CN` strings do not clip; portrait crop remains bounded. |
| `tests/loss_messaging_ui_test.gd` | Fixture A: ordinary permanent death names the callsign and exposes View Vahalla. Fixture B: premium loss with lives remaining says Ready and does not imply memorial. Fixture C: premium final-life loss says 0/locked and exposes Vahalla. Fixture D: no casualties produces no false ledger. All copy changes under `zh-CN`. |
| `tests/resign_confirm_ui_test.gd` | Opening pauses and focuses Cancel; Confirm and Cancel are keyboard/controller reachable; `ui_cancel` cancels; Cancel restores exact prior scale; Confirm applies one resign action; modal traps pointer/focus; resizing both target viewports keeps it centered and fully visible. |
| `tests/vahalla_navigation_ui_test.gd` | Company Command tile → Vahalla; Back/Escape → Company Command; Results conditional View Vahalla → archive; returning preserves the documented Results or staging context; no route operates without an active campaign. |
| `tests/vahalla_localization_test.gd` | New keys exist in both canonical catalogs, are sorted, have identical placeholders, reason mapping has an unknown fallback, no raw `{token}` renders, and the memorial uses CJK-capable fonts under `zh-CN`. |
| `tests/vahalla_accessibility_ui_test.gd` | Initial focus exists; focus order includes Back, filters, roster, Honor; selected and fallen state are not color-only; icon filters have accessible names; all active targets are at least 44×44; focus returns after Honor/filter rebuild and after closing Resign. |

Suggested focused commands, following the repository’s SceneTree-script convention, are:

```bash
tools/run_godot_test.sh tests/vahalla_ui_test.gd
tools/run_godot_test.sh tests/faction_roster_filter_test.gd
tools/run_godot_test.sh tests/premium_hero_system_test.gd
tools/run_godot_test.sh tests/custom_naming_roster_test.gd
```

After implementation, run the proposed focused tests plus the repository checks from `README.md`:

```bash
tools/run_godot_isolated.sh --headless --import
tools/run_godot_isolated.sh --headless --fixed-fps 60 --quit-after 120
```

Visual acceptance must include native captures at exactly `1280×720` and `720×1280` for populated, filtered-empty, long-identity, ordinary-death, premium-life-remaining, premium-final-life, honored, resign-confirm, and Simplified Chinese states.

## Acceptance checklist

- [ ] The screen reads as a ceremonial Lunaris memory archive, not a red administrative card grid.
- [ ] All depicted portraits remain recognizably adult **21+**, non-explicit, identity-consistent, and safely cropped.
- [ ] Callsign and selected hero identity are more prominent than class or technical death metadata.
- [ ] Ordinary permanent death, premium reserve loss, and premium terminal lockout use distinct localized language.
- [ ] Results names every newly terminal casualty and offers a conditional direct memorial route.
- [ ] Stage title and terminal reason are localized authored copy; raw IDs/ticks are secondary or hidden.
- [ ] Faction filtering remains presentation-only and retains All + four faction counts.
- [ ] Honor remains non-transactional and visit-local, is idempotent, and does not lose focus or scroll.
- [ ] Back, Escape, Result actions, Resign pause/Cancel/Confirm, and terminal Continue retain their routes and authority boundaries.
- [ ] English and Simplified Chinese pass at `1280×720` and `720×1280` with no clipping or missing glyphs.
- [ ] Generated decoration is standalone and scalable; all copy and values remain native Godot controls.
- [ ] No presentation component writes death, life, revival, deployment eligibility, faction identity, or memorial state.

## Final recommendation

Proceed with a **roster-and-dossier memorial redesign** and a shared **casualty ledger / loss confirmation component kit**. The first implementation milestone should not be ornamental asset work; it should correct the consequence projection so ordinary deaths and premium-life outcomes are named accurately, localized, and linked to Vahalla. The second milestone should replace the repeated cards with the character-forward archive composition and make focus/scroll behavior deterministic. Only then should generated brass/glass frames and memory ornament be layered around the native controls.

This order preserves every deterministic campaign contract while delivering the largest improvements in comprehension, emotional weight, adult character appeal, and consistency with the approved Lunaris title aesthetic.
