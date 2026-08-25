# Faction Roster Filtering and Vahalla

The playable roster UI uses the canonical faction symbols as filters without expanding the persisted campaign schema. Existing and current authored operators resolve to **Lunaris Reliquary**; the presentation adapter accepts a validated future `faction_id` projection so Solcrest Accord, Vesper Circuit, and Crimson Aegis rosters can appear without redesigning the controls.

| Surface | Default state | Available views | Authority boundary |
|---|---|---|---|
| Mission squad selection | **Active** and **All factions** | Active or Fallen; All or one canonical faction | Only active heroes can be selected or deployed. Fallen cards remain read-only. |
| Training roster | **Active** and **All factions** | Active or Fallen; All or one canonical faction | Fallen heroes may be inspected but never promoted. Existing promotion legality remains authoritative. |
| Vahalla | **Fallen** and **All factions** | All fallen heroes or one canonical faction | Memorial entries and terminal death records come from `CampaignStateV3`; honoring is ceremonial and does not mutate campaign state. |

## Filter contract

The shared filter bar contains an **Active** tab, a **Fallen** tab, an **All** control, and one button for each canonical faction symbol. Tabs include live counts. A faction button remains visible with a zero count so the four-faction vocabulary is stable as content expands. The default Active tab prevents dead soldiers from appearing in normal squad or training browsing.

Changing filters never clears a valid selected squad. If the currently inspected training hero is hidden by a new filter, the first visible row becomes the local inspection target. Fallen squad cards are disabled and excluded from focusable deployment controls.

## Faction derivation

Faction identity is a UI projection, not a new save field. A validated faction ID already present on a presentation row wins; known source prefixes may map future content to a canonical faction; otherwise the current campaign safely defaults to `lunaris_reliquary`. This keeps all existing saves byte-compatible and avoids weakening canonical codec key validation.

## Vahalla memorial

Company Command replaces the unavailable Memorial operation with an enabled button labeled exactly **Vahalla**. The destination presents each canonical memorial entry with portrait, callsign, class, faction symbol, battle-loss record, and an **Honor** action. Honor state lasts for the current visit only, plays presentation feedback, and never revives, rewards, or modifies a soldier. An empty memorial displays a clear no-fallen state and always offers a return to Company Command.

## Acceptance contract

| Requirement | Verification |
|---|---|
| Dead soldiers hidden by default | Squad and Training open on Active; only `life_status == ready` rows are rendered. |
| Fallen roster tab | Switching to Fallen renders only terminally dead rows and never enables deployment or promotion. |
| Symbol filtering | All four canonical symbols are present; selecting one produces only rows with that faction projection. |
| Save compatibility | No persisted keys or codec/hash rules change; fresh and migrated premium-hero tests continue to pass. |
| Memorial navigation | Company Command opens Vahalla; Back returns to Company Command; empty and populated states both render. |
| Responsive behavior | Desktop and portrait layouts keep tabs, symbols, roster cards, memorial records, and primary navigation reachable. |
