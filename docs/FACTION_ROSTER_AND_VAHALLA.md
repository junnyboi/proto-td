# Faction Roster Filtering and Valhalla

> **Narrative authority:** [`NARRATIVE_CANON.md`](NARRATIVE_CANON.md) is the sole binding narrative authority. This document specifies presentation, filtering, navigation, and save compatibility. It does not define story canon.

The Company Manus roster uses faction symbols as presentation filters without expanding the persisted campaign schema. Current authored operators resolve to Lunaris Reliquary. The adapter accepts validated future `faction_id` projections so Solcrest Accord, Vesper Circuit, and Crimson Aegis can be displayed without redesigning controls or changing save data.

Player-facing prose uses **Valhalla**. Existing internal `vahalla` paths, keys, node names, classes, and compatibility identifiers remain unchanged.

## Stable faction projections

| Faction | Stable ID | Known source prefix |
|---|---|---|
| **Solcrest Accord** | `solcrest_accord` | `solcrest_` |
| **Vesper Circuit** | `vesper_circuit` | `vesper_` |
| **Lunaris Reliquary** | `lunaris_reliquary` | `lunaris_` or `reliquary_` |
| **Crimson Aegis** | `crimson_aegis` | `crimson_` |

Faction identity is a UI projection, not a persisted field. A validated `faction_id` on a presentation row wins. Otherwise a known source prefix is used. Rows without a recognized projection safely default to `lunaris_reliquary`. The adapter must not add save keys, weaken codec validation, or alter deterministic hashes.

## Surface behavior

| Surface | Default state | Available views | Authority boundary |
|---|---|---|---|
| Mission squad selection | **Active** and **All factions** | Active or Fallen; All or one faction | Only active heroes may be selected or deployed. Fallen cards remain read-only and are excluded from deployment focus. |
| Training roster | **Active** and **All factions** | Active or Fallen; All or one faction | Fallen heroes may be inspected but never promoted. Existing promotion legality remains controlling. |
| Valhalla | **Fallen** and **All factions** | All fallen heroes or one faction | Memorial rows and terminal death records come from `CampaignStateV3`. Honoring is ceremonial and does not mutate campaign state. |

The shared filter bar contains **Active**, **Fallen**, **All**, and one symbol button for each of the four faction IDs. Tabs include live counts. Every faction button remains visible at a zero count so the four-faction interface remains stable as the roster expands.

Changing filters never clears a valid selected squad. If a new filter hides the training hero currently being inspected, the first visible row becomes the local inspection target. Fallen squad cards remain disabled.

## Life-state and soul-state boundary

The current roster mechanic filters `life_status == ready` as active and treats `life_status == dead` or an existing death record as fallen. That behavior, its receipts, and its persistence remain unchanged.

Under the Anima War canon, one hero has one unique, non-copyable soul. Valhalla may describe a fallen hero as missing, captured, recoverable but lacking a prepared body, permanently consumed, or shattered beyond recovery only when an existing authoritative record supports that distinction. Presentation must not invent a second soul, imply that a memorial action revives anyone, or convert narrative status into a new save field during this documentation phase.

## Valhalla navigation and memorial behavior

Company Command exposes an enabled button labeled **Valhalla**. The existing route remains `Game.open_vahalla()`, and internal implementation names such as `scripts/ui/vahalla.gd`, `VahallaScreen`, `ui.vahalla.*`, and `VahallaMemorialScroll` remain compatibility details.

The destination presents each memorial entry with portrait, callsign, class, faction symbol, battle-loss record, and an **Honor** action. Honor state lasts only for the current visit, plays presentation feedback, and never revives a hero, grants a reward, spends anima, or modifies Company Manus campaign state. An empty memorial provides a clear no-fallen state. Back navigation always returns to Company Command.

## Accessibility and responsive behavior

Filters, cards, memorial records, Honor, and primary navigation must remain keyboard-, controller-, pointer-, and touch-reachable. Fallen state and faction identity must not rely on color alone. Labels, symbols, disabled state, focus order, accessible names, live counts, and screen-reader descriptions must communicate the same information. Touch targets remain at least 44 px, text scaling remains supported, and desktop and portrait layouts retain scroll and focus containment.

## Acceptance contract

| Requirement | Verification |
|---|---|
| Dead heroes hidden by default | Squad and Training open on Active and render only ready rows. |
| Fallen roster view | Fallen renders only terminal rows and never enables deployment or promotion. |
| Symbol filtering | All four stable faction symbols are present; selecting one returns only that projected faction. |
| Selection stability | Filter changes do not clear a valid selected squad; hidden training inspection moves locally to the first visible row. |
| Save compatibility | No persisted key, codec, receipt, counter, or hash rule changes; fresh and migrated roster tests continue to pass. |
| Valhalla routing | Company Command opens Valhalla through the existing internal route; Back returns to Company Command. |
| Memorial immutability | Honor is visit-local presentation feedback and changes no roster, reward, life, or soul state. |
| Responsive accessibility | Desktop and portrait layouts keep controls reachable, labeled, focusable, and legible without color-only meaning. |
