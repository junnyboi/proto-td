# UI Revamp Audit 04 — Premium Gacha and Reveal Lifecycle

**UI family:** Premium Resonance gacha  
**Repository revision audited:** `6f382b621c812c29dacfa79a41fe59e19909709c`  
**Target viewports:** `1280×720` landscape and `720×1280` portrait  
**Scope:** Company Command entry, premium banner/gallery, pity and economy presentation, pull confirmation, authoritative pull commit, reveal states, new/duplicate/revival outcome, and return to Company Command  
**Change boundary:** This is a presentation audit. The deterministic campaign, pull, pity, life, reward, persistence, and replay authorities must not move into UI code.

## Executive assessment

Premium Resonance is **functionally mature but visually one generation behind the approved Lunaris shell**. Its deterministic pull, pity, stored-life, duplicate, revival, input-lock, skip, and return contracts are already well isolated from presentation. The current screen also meets the basic desktop and portrait containment claims recorded in the premium gacha QA documents. Those strengths should be preserved.

The primary problem is continuity. The title and Company Command screens now establish a cinematic premium 21+ anime-gacha identity through an animated adult ensemble, Cinzel display typography, manufactured antique-brass frames, generated celestial symbols, clipped geometry, and a deliberate character-versus-command-deck composition. Premium Resonance drops that language on entry. It renders a solid near-black backdrop, a flat rounded `StyleBoxFlat` shell, three equal utility cards, mostly default typography, and a centered result dialog. The gacha—the product surface that most needs aspiration, rarity, glamour, and ceremony—therefore feels less premium than the navigation screen that launches it.

There is also **no pull-confirmation state**. Activating `RESONATE • 40 MARKS` immediately calls the durable authoritative pull command and opens the reveal only after a successful commit. This is safe and deterministic, but it offers no final cost/balance check or cancellation point. A confirmation sheet should be introduced as a presentation state before the command call, while preserving the rule that result selection, pity, charging, duplicate/revival classification, and persistence occur only in the campaign authority.

The reveal is contractually rich but visually under-realized. The script names signal lock, rarity, hero, and settle concepts, yet the current tween keeps the reveal card—including its stars—transparent while `_ignite_stars()` runs. As a result, the player sees the backdrop filaments move and then receives an already-lit result card rather than a readable four-star/five-star charge. There is no portrait light sweep, no distinct featured-hero staging, and little material difference between a natural five-star, a forced five-star, and a four-star beyond color, title text, and the guarantee eyebrow.

## Sources reviewed

| Area | Authoritative or relevant sources |
|---|---|
| Project shell and viewport | [`project.godot`](../../../../project.godot), [`README.md`](../../../../README.md) |
| Approved character and material direction | [`docs/ART_DIRECTION.md`](../../../ART_DIRECTION.md), [`docs/LUNARIS_CHARACTER_DESIGNS.md`](../../../LUNARIS_CHARACTER_DESIGNS.md), runtime premium portraits under [`assets/portraits/`](../../../../assets/portraits/) |
| Existing UI concepts | [`docs/ui-concepts/MISSION_TRAINING_GACHA_UI.md`](../../MISSION_TRAINING_GACHA_UI.md), [`docs/ui-concepts/LUNARIS_ENTRY_REDESIGN.md`](../../LUNARIS_ENTRY_REDESIGN.md), [`docs/ui-concepts/STAGING_CONCEPT_FIDELITY_PLAN.md`](../../STAGING_CONCEPT_FIDELITY_PLAN.md), [`reference-findings.md`](../reference-findings.md) |
| Current gacha presentation | [`scenes/gacha.tscn`](../../../../scenes/gacha.tscn), [`scripts/ui/gacha.gd`](../../../../scripts/ui/gacha.gd), [`scripts/ui/components/lunaris_ops_style.gd`](../../../../scripts/ui/components/lunaris_ops_style.gd), [`scripts/ui/components/resonance_star.gd`](../../../../scripts/ui/components/resonance_star.gd) |
| Entry and return flow | [`scripts/ui/staging.gd`](../../../../scripts/ui/staging.gd), [`autoloads/game.gd`](../../../../autoloads/game.gd), [`scenes/staging.tscn`](../../../../scenes/staging.tscn) |
| Premium model and data | [`sim/campaign_v3_gacha.gd`](../../../../sim/campaign_v3_gacha.gd), [`sim/campaign_state_v3.gd`](../../../../sim/campaign_state_v3.gd), [`data/campaigns/p16_v3.tres`](../../../../data/campaigns/p16_v3.tres), [`docs/PREMIUM_HERO_SYSTEM.md`](../../../PREMIUM_HERO_SYSTEM.md), [`docs/PREMIUM_GACHA_PITY_AND_PACING.md`](../../../PREMIUM_GACHA_PITY_AND_PACING.md) |
| Existing validation | [`docs/PREMIUM_GACHA_VISUAL_QA.md`](../../../PREMIUM_GACHA_VISUAL_QA.md), [`tests/premium_gacha_ui_test.gd`](../../../../tests/premium_gacha_ui_test.gd), [`tests/premium_gacha_pity_economy_test.gd`](../../../../tests/premium_gacha_pity_economy_test.gd), [`tests/premium_hero_system_test.gd`](../../../../tests/premium_hero_system_test.gd) |
| Approved reusable shell assets | [`scripts/ui/components/staging_skin.gd`](../../../../scripts/ui/components/staging_skin.gd), [`scripts/ui/game_typography.gd`](../../../../scripts/ui/game_typography.gd), [`docs/ui-concepts/staging-concept-fidelity/ASSET_MANIFEST.md`](../../staging-concept-fidelity/ASSET_MANIFEST.md), generated frames and symbols under [`assets/ui/staging/`](../../../../assets/ui/staging/) |

## Screen and state inventory

The family is one Godot scene with several mutually exclusive or transient presentation states rather than a sequence of separate scenes. The table below treats each meaningful state as a screen-level player experience.

| Screen or state | Entry condition | Visible information and controls | Functional exit |
|---|---|---|---|
| **Company Command / Premium Resonance entry tile** | Active campaign reaches `staging.tscn` | Enabled `RecruitButton`, short label `Resonance`, full label `Premium Resonance`, generated recruit symbol | Activating the tile plays `ui_click` and calls `Game.open_gacha()` |
| **Premium Resonance idle/banner state** | `gacha.tscn` is instantiated with an active campaign | Return button, faction eyebrow, screen title, Marks balance, rule copy, base rate, guarantee window, ten-segment pity meter, three pool cards, status line, and pull action | Return calls `Game.open_staging()`; pull begins the transaction path |
| **Campaign-offline locked state** | No active campaign or no campaign state | `CAMPAIGN OFFLINE`, disabled `PULL UNAVAILABLE`, explanatory status | Return remains available unless a reveal is active |
| **Insufficient-Marks locked state** | Active campaign has fewer than the 40-Mark cost | Current Marks, disabled pull action, exact shortfall in status copy | Return remains available |
| **Attempt-pending locked state** | A battle attempt exists without a committed resolution | Disabled pull action and instruction to resolve the active operation | Return remains available |
| **Pool gallery / owned-state variants** | Every idle refresh | Three authored identities; rarity, portrait, class, acquisition/life status, copy count, and fixed-kit reminder | Gallery is informational; the player cannot target or select an identity |
| **Unacquired card** | Premium identity is absent from `premium_heroes` | `UNACQUIRED` and `Pull to recruit • Fixed elite kit` | No direct action |
| **Owned card** | Premium identity exists with one or more lives | Remaining lives and total copies | No direct action |
| **Locked/dead card** | Premium identity exists with zero lives and `life_status == dead` | Danger frame, `LOCKED • 0 LIVES`, and restoration guidance | No direct action; a future random duplicate may revive the hero |
| **Pull activation / alignment state** | Player activates an enabled pull button | Button disables and status becomes `Aligning the reliquary signal…` | There is currently no confirmation or cancellation state; the authoritative command is called immediately |
| **Rejected pull state** | Authoritative command rejects | Exact copy for insufficient Marks, attempt pending, life cap, or inactive campaign; generic safe copy for other codes | Refresh restores appropriate controls; no reveal opens |
| **Signal-lock reveal beat** | Pull commit succeeds | Full-screen input-stopping shade and twelve rotating cyan/gold filaments | Explicit skip is not yet visually available until the card appears; confirm/cancel input finalizes at any reveal time |
| **Rarity-charge reveal beat** | Tween reaches star callback | Intended four/five star ignition | Currently not legible as a beat because the entire result card remains transparent while stars are ignited |
| **Four-star reveal** | Committed receipt has rarity `4` | Cyan treatment, four lit code-drawn stars, selected portrait, result kind, life count, next guarantee distance, skip | Skip button or confirm/cancel finalizes |
| **Five-star reveal** | Committed receipt has rarity `5` | Gold treatment, `5-STAR RESONANCE`, five lit stars, stronger warm shade, portrait, result, life count, next guarantee distance | Skip button or confirm/cancel finalizes |
| **Forced-pity five-star variant** | `pity_forced == true` | Five-star presentation plus `GUARANTEE FULFILLED` eyebrow | Same finalization path |
| **New-hero outcome** | `new_hero == true` | Reveal result `NEW HERO`; settled status says the hero joins with one life | Finalization returns focus to Pull |
| **Duplicate outcome** | Existing ready hero is pulled | Reveal result `LIFE +1`; settled status identifies `DUPLICATE`, +1 life, total lives, and next guarantee | Finalization returns focus to Pull |
| **Revival outcome** | Existing zero-life dead hero is pulled | Reveal result `REVIVED`; settled status identifies `RESTORED`, one life, and next guarantee | Finalization returns focus to Pull; authoritative state has already removed the memorial entry |
| **Reduced-motion reveal** | Exported property or `accessibility/reduced_motion` is true | Final shade, result card, portrait, and lit stars appear immediately; skip gets focus | Finalization is identical and does not alter the receipt |
| **Post-reveal settled idle state** | Reveal is finalized or skipped | Updated gallery, Marks, pity meter, pull availability, and a one-line result summary | Another pull when eligible, or return to Company Command |
| **Return to Company Command** | Back button from non-reveal state | Deferred content swap to `staging.tscn`; campaign state/store remain authoritative and intact | Company Command restores its normal staging interactions |

## Current interaction lifecycle

1. Company Command owns the entry affordance. `RecruitButton` is an enabled `StagingCommandTile`, and activation calls `Game.open_gacha()`.
2. `Game._swap_content()` instantiates the gacha scene, lets it register itself as `Game.content`, then retires the previous scene. This is a presentation swap; it does not reset campaign state.
3. The gacha reads `campaign.runtime_projection()` and builds all three catalog cards. It never selects a result locally.
4. When eligible, the pull button shows the authored cost from `premium_pull_cost`. Pressing it disables the control and calls `Game.pull_premium_hero()` immediately.
5. `Game.pull_premium_hero()` derives an idempotent command ID from campaign UID and pull index, submits `CampaignStateV3.pull_premium_hero()`, commits through the runtime authority, and replaces the in-memory campaign only on success.
6. The accepted receipt drives every reveal distinction: identity, rarity, natural versus forced pity, new hero versus duplicate versus revival, lives after, and next guarantee distance.
7. During reveal, Back and Pull are disabled and a full-screen mouse-stopping layer blocks underlying controls. `ui_accept` and `ui_cancel` finalize. The explicit skip button finalizes after it becomes visible/focusable.
8. Finalization kills the tween, hides the overlay, refreshes committed state, writes result copy to the dock, and restores focus to the Pull button.
9. Back from idle calls `Game.open_staging()`, preserving the committed campaign and durable store.

## Feature contracts that must survive

| Contract | Required behavior after redesign |
|---|---|
| **Authority boundary** | UI may stage, animate, and format a committed receipt, but must never roll rarity, select an identity, calculate pity, infer the result kind, charge Marks, grant lives, revive a hero, or alter a memorial entry. |
| **Durable commit before reveal** | Reveal begins only after `Game.pull_premium_hero()` returns an accepted durable commit. A failed or retryable commit must never show a false reward. |
| **Cost and eligibility** | One accepted pull costs exactly 40 authored Marks. Pull is unavailable below cost, during an unresolved attempt, without an active campaign, or when the authoritative command rejects. |
| **No empty results** | Every accepted pull grants exactly one life to exactly one of the three authored premium identities. |
| **Pool and rarity** | The launch pool remains Archive Caster and Reliquary Duelist at four stars, and Lunaris Vessel as the sole five-star; authored natural weight remains `2/40` for the five-star unless product balance changes separately. |
| **Hard pity** | Each eligible non-five-star increments the streak; a five-star resets it; after nine misses, pull ten is forced to the five-star sub-pool. The UI must display receipt/projection values, not reconstruct them. |
| **Pity migration boundary** | Pre-pity historical pulls remain ineligible after migration, and the migrated campaign receives a fresh ten-pull window. Presentation must tolerate the activation boundary without inventing historical progress. |
| **First copy** | First acquisition creates one persistent hero row with its fixed callsign, portrait, class, kit, and one life. |
| **Duplicate** | Pulling an owned identity increments that same persistent hero’s life and pull count. It must not create a duplicate gallery or roster row. |
| **Revival** | Pulling a zero-life hero restores the same persistent identity to ready with one life and removes its memorial record. Reveal copy must distinguish this from an ordinary duplicate. |
| **Fixed kit** | Premium heroes remain non-trainable and receive no campaign XP. Card and rule copy must retain `PREMIUM / FIXED KIT` meaning. |
| **Input lock** | Once commit succeeds and reveal starts, underlying Pull and Back cannot issue navigation or another transaction. Exactly one visible skip/finalize affordance remains. |
| **Skip invariance** | Skip, confirm/cancel finalization, or reduced-motion finalization changes presentation only. All routes expose the same final receipt information and committed campaign state. |
| **Tween cleanup** | Leaving or freeing the scene kills active reveal tweens safely. No delayed callback may target a freed UI node. |
| **Focus restoration** | Finalization restores focus to the enabled Pull action, or to a deterministic safe alternative if Pull is disabled after spending the last eligible Marks. |
| **Navigation continuity** | Back returns to Company Command without clearing campaign, campaign store, selected progression, pity, Marks, or premium ownership. |
| **First-clear economy** | Stage first clears continue to award 40 Marks exactly once; repeats award zero. Gacha presentation may explain this source but cannot award it. |
| **Code-drawn rarity stars** | The runtime must not depend on a Unicode star glyph; the Web-safe geometry component remains the baseline unless replaced by an equally font-independent asset. |
| **Adult identity** | Every displayed hero must remain unmistakably adult (21+), glamorous, powerful, non-explicit, and consistent with the approved Lunaris character identity and equipment. |

### Confirmation-specific contract

A new confirmation state should be added, but it must be explicitly **pre-transactional**. Opening the sheet may snapshot only presentation values such as `marks`, `premium_pull_cost`, and `premium_guarantee_in`. `CANCEL` closes it with no command and no state mutation. `CONFIRM RESONANCE • 40 MARKS` is the sole action that invokes `Game.pull_premium_hero()`, disables both confirmation actions against double submission, and transitions to reveal only on accepted commit. If the authoritative state changed while the sheet was open, rejection copy and a refreshed projection take precedence over the stale snapshot.

## Visual consistency assessment

### What already aligns

The palette constants in `lunaris_ops_style.gd` match the approved lunar ink, navy glass, ivory, moon-cyan, restrained gold, violet, and danger family. Cards show the three real premium portraits rather than placeholders. Rarity, callsign, class, lives, copy count, dead/locked state, rate, hard guarantee, cost, and balance remain native and readable. Code-drawn stars avoid the known Web fallback-font failure. The screen uses internal gallery scrolling with a fixed action dock, and the reveal uses a viewport-wide modal shade rather than navigating to an unrelated utility scene.

### Material and composition gaps

| Gap | Current evidence | Impact |
|---|---|---|
| **Abrupt shell downgrade** | `Style.add_backdrop(self)` is called without a texture, so gacha receives only a flat near-black fill. It does not reuse the title/Company Command animated Lunaris backdrop. | The transition from cinematic Company Command to the monetization/collection surface feels unfinished. |
| **Flat prototype surfaces** | Screen, cards, and buttons use one- or two-pixel `StyleBoxFlat` borders and four-pixel rounded corners. | These read as competent debug/admin UI beside the approved engraved brass, clipped-corner frame family. |
| **No banner thesis** | Three equal cards share the same width and hierarchy; the sole five-star is not compositionally featured. | The screen communicates a database pool, not a premium banner with must-pull focus. |
| **Weak character staging** | Square 512×512 bust portraits sit inside generic cards with no faction seal, weapon cue, signature mechanism, or editorial crop treatment. | Hero charisma and collectible identity are subordinate to labels. |
| **Uneven adult-age cues** | Archive Caster and Reliquary Duelist read relatively mature, while Lunaris Vessel’s large eyes, small lower face, and doll-like bust treatment approach a chibi/juvenile cue despite adult costume styling. | The featured five-star does not consistently meet the non-ambiguous 21+ portrait standard in `ART_DIRECTION.md`. A new approved mature portrait crop is the safest correction. |
| **Rarity lacks material distinction** | Four- and five-star cards share the same structure. Color and one text label do most of the work. | The five-star does not carry the promised high-rarity “must-pull” presence before or after acquisition. |
| **Reveal is a centered utility dialog** | A fixed `520×650`/`340×620` panel appears over rays. | The climax repeats the generic centered-dialog pattern rejected by the accepted concepts. |
| **Rarity charge is not visibly sequenced** | `_ignite_stars()` executes while `_reveal_panel.modulate.a == 0`. | The documented four-star charge and fifth-star ignition are effectively collapsed into an already-complete result. |
| **No portrait light sweep or rarity frame choreography** | Reveal only fades portrait alpha and scales the whole panel. | The hero reveal does not meet the authored signal-lock → charge → hero → settle spectacle. |
| **Forced pity is text-only** | `GUARANTEE FULFILLED` is an eyebrow label on the normal five-star card. | A major economy promise receives too little visual acknowledgement. |
| **Typography continuity is missing** | Gacha uses `lunaris_ops_style.gd` font sizes but does not apply the Cinzel-with-CJK-fallback display system used by Company Command. | Titles and actions lose the ceremonial title-level identity. |
| **Hard-coded English** | Gacha labels, status, error, card, pity, and reveal copy are inline strings rather than `UiCopy`/`I18n` keys. | The otherwise localized title/staging flow breaks on entry; longer translated strings have never been laid out. |
| **Economy continuity is weak** | Company Command presents a mock Aether/Sigil/Stamina wallet, while real Marks first appear only inside gacha. | Players cannot see the spendable gacha currency before entering and may confuse mock resources with real economy. |
| **No pull confirmation** | The button directly commits. | There is no cost-after-spend preview, intentionality check, or accessible cancellation point. |
| **Outcome persistence is too subtle** | After reveal, the rich overlay disappears and only a status line plus updated card remains. | Duplicate life gain or revival can be missed, especially when the updated hero card is below the current gallery scroll position. |
| **Idle keyboard entry is under-specified** | `_ready()` does not assign initial focus and idle `ui_cancel` does not return to staging. | Mouse use works, but controller/keyboard continuity is weaker than title and Company Command. |
| **Document/implementation skip drift** | The pacing document says a second pull action can skip, but Pull is disabled and covered during reveal. | The advertised shortcut is not reachable through ordinary UI. Either implement a reveal-level action alias or remove the unsupported claim. |

## Recommended target composition

### Landscape — `1280×720`

Use nearly the full safe viewport. Retain the animated Lunaris backdrop at restrained opacity, with a dark readability wash rather than a full flat fill. A shallow top command bar should contain a generated Return glyph and `COMPANY COMMAND`, Lunaris seal plus `PREMIUM RESONANCE`, an authoritative Marks chip, and the short rate/guarantee disclosure.

The body should be asymmetrical. The **left 58–62%** becomes the featured five-star banner stage: a new mature Lunaris Vessel key crop, celestial reliquary rings, a gold `5-STAR` seal, name, fixed class, concise identity statement, and acquisition/life state. The **right 38–42%** becomes a compact pool/economy rail: two four-star portrait cards, fixed-kit rule, a legible ten-step guarantee track, and exact `Guaranteed in N pulls` copy. This treatment features the five-star without implying that the player can select or target it; label the pool action clearly as random across the displayed pool.

A fixed bottom action dock should preserve status on the left and the pull action on the right. The pull action should use the approved textured primary frame, show `RESONATE`, `40 MARKS`, and a small `BALANCE 120 → 80` preview. The actual after-balance preview must be presentation-only; the authoritative commit remains decisive.

### Portrait — `720×1280`

Use the full portrait safe area with a compact 72–82 px top bar. The five-star stage occupies the upper visual region with a face-safe crop and restrained halo. Under it, place the rate and guarantee module, then a horizontally scrollable two-card four-star rail or a compact stacked pair. Keep a **fixed bottom confirmation/action dock** visible while only the hero/pool body scrolls.

Do not stack three current 380 px cards into one long content column and rely on the user to find the featured hero. The five-star thesis, guarantee distance, Marks balance, status, and primary action must all be visible in the first view. Portrait reveal should become a full-height ceremonial composition rather than a narrow desktop card centered in empty space.

## Component recommendations

| Component | Specific change | Functional constraint |
|---|---|---|
| **Gacha shell** | Reuse `LunarisAnimatedBackdrop`, `StagingSkin.navbar_style()`, `command_deck_style()`, and Cinzel display roles. Add a gacha-specific dark scrim and only the additional nine-patch assets genuinely needed for banner/reveal framing. | Background and frames remain presentation-only and must not delay state reads or navigation. |
| **Header / economy chip** | Add an authoritative Marks chip with a distinct Marks icon and cost disclosure. Reconcile it with staging’s presentation-only wallet rather than relabeling a mock currency as real Marks. | Values come from `runtime_projection()` and authored cost. No plus/purchase affordance until a real purchase route exists. |
| **Featured banner stage** | Feature Lunaris Vessel with an approved mature 21+ portrait/key art, gold rarity seal, class, signature Crescent Reliquary cue, and owned/locked state. | Must not imply rate-up, targeting, or selection; current pool is random and the five-star base rate is 5%. |
| **Four-star pool cards** | Compress Archive Caster and Reliquary Duelist into premium secondary cards with cyan/silver frames, callsign, class, lives, copies, and fixed-kit status. | Both remain equal 19/40 natural-weight outcomes. |
| **Guarantee track** | Replace bare `ColorRect` bars with a reusable ten-cell resonance track using native accessible labels, current miss count, next-guarantee number, and forced-next state. | Read `premium_pity_streak` and `premium_guarantee_in`; do not compute from local pull history. |
| **Rule disclosure** | Use two concise chips: `EVERY PULL GRANTS 1 LIFE` and `PREMIUM HEROES • FIXED KIT`. Put detailed rate/pity explanation behind a native details sheet if needed. | No concealment of cost, base five-star rate, or hard guarantee. |
| **Confirmation sheet** | Add `CONFIRM RESONANCE`, exact cost, current and projected balance, current guarantee distance, random-pool statement, `CANCEL`, and one dominant confirm action. | Opening/canceling never mutates state; confirm calls the authoritative command exactly once. |
| **Reveal director** | Separate visible nodes and timings for signal lock, star charge, hero rise, and result settle. Keep the star rail outside any transparent parent during charge, or animate the parent before ignition. | Receipt is immutable input. Back/Pull stay locked; skip stays available from the first reveal frame. |
| **Four-star reveal** | Use cyan/indigo/silver filaments, four sequential ignitions, a silver-cyan hero frame, and restrained motion. The fifth star remains visibly unlit. | Information must remain readable without color. |
| **Five-star reveal** | Use gold-white material, a visible fifth-star ignition after four cyan/gold precursors, broader radial geometry, larger hero crop, and `5-STAR RESONANCE`. | Avoid flashes above three changes per second and avoid excessive bloom over face/hands. |
| **Forced-pity variant** | Add a compact gold guarantee seal and one ceremonial lock-release motion, not only an eyebrow string. | `pity_forced` comes directly from the receipt. Natural and forced five-stars produce the same gameplay reward semantics. |
| **Outcome panel** | Persist the final result as a bottom sheet/card with hero name, `NEW HERO`, `LIFE +1`, or `REVIVED`, before/after life delta where applicable, updated guarantee, and `CONTINUE`. | Duplicate and revival remain distinct; continue only dismisses presentation. |
| **Navigation and focus** | Give initial focus to Pull when enabled, otherwise Back. Support idle `ui_cancel` as Back. During reveal, route explicit Skip plus accept/cancel to finalization, and restore focus to Pull or Back according to eligibility. | No navigation out while an accepted reveal is unresolved; tween cleanup remains mandatory. |
| **Localization** | Move all gacha copy into `UiCopy`/canonical `en-US` and `zh-CN` catalogs with typed placeholders for Marks, lives, copies, and guarantee count. | Key parity and placeholder parity must pass; Cinzel must fall back to the current CJK font. |
| **Audio/haptics seam** | Add presentation hooks for signal lock, each star, five-star turn, duplicate life increment, revival, confirm, cancel, and continue. | Audio never gates commit/finalization and reduced motion does not imply muted audio unless settings say so. |

## Reveal lifecycle specification for the revamp

| Phase | Recommended visible state | Input | Completion rule |
|---|---|---|---|
| **Confirmation** | Cost, balance before/after, pity distance, random-pool statement | Cancel or confirm | No command before confirm |
| **Commit pending** | Confirmation controls disabled; restrained `ALIGNING SIGNAL` progress | No repeat submit; optional cancel is no longer offered once command dispatch begins | Accepted result enters reveal; rejection returns to confirmation/idle with exact reason |
| **Signal lock** | Existing banner dims; reticle and reliquary rings converge; skip visible immediately | Skip/accept/cancel finalizes presentation once a receipt exists | Approximately 0.18 s in full motion |
| **Rarity charge** | Four stars ignite sequentially; fifth ignition only for a five-star; forced pity adds lock-release seal | Skip remains active | Approximately 0.38 s, with no rapid flashing |
| **Hero reveal** | Hero art rises from 96% scale; rarity frame and a masked light sweep appear | Skip remains active | Approximately 0.32 s |
| **Result settle** | Callsign, result kind, lives, guarantee distance, and continue/skip settle | Continue/skip/accept/cancel | Approximately 0.24 s before stable final state |
| **Reduced motion** | Short opacity transition directly to the same stable final state; no rotation, overshoot, or moving filaments | Continue/skip/accept/cancel | Receipt information and focus outcome are identical |

## Responsive risk analysis

### `1280×720`

| Risk | Why it exists now | Required mitigation or gate |
|---|---|---|
| **Reveal vertical fit has almost no reserve** | The reveal card requests 650 px height inside 18 px top/bottom safe margins, leaving only 34 px total viewport reserve before content-driven minimums. Its children, ten separations, 310 px portrait, and panel content margins can force expansion. | Keep every reveal state inside a measured safe rect. Prefer a landscape split reveal rather than increasing the centered card. Assert the final rect is contained with at least 18 px margins. |
| **Three-card minimum width is tight after shell padding** | Three 280 px cards, two 16 px gaps, 42 px outer margins, and 22 px screen-panel content margins consume most of the width before text or scrollbar reserve. | Replace equal three-column composition with featured stage + compact rail; let only the rail scroll. |
| **Header competition** | Back label, title stack, and Marks metric share a three-column grid with no explicit column allocation. Longer copy or CJK can compress the center title. | Use a top bar with fixed 44 px navigation target, flexible identity center, and measured economy chip; add ellipsis only to noncritical identity copy. |
| **Bottom dock status wrapping** | Status and a 280 px pull button share two columns. Duplicate/revival result summaries are long and can add a line, reducing gallery height or clipping at 720 px. | Give the dock a fixed measured height, shorten visible summary, and expose full details in the persistent outcome sheet/tooltips. |
| **Generated frame visual weight** | Existing staging integration showed that textured nine-patches consume more perceived and actual interior space than flat styles. | Establish protected margins early and rerun density review at exact 1280×720 before final polish. |
| **No explicit stretch policy in `project.godot`** | The project declares a 1280×720 viewport but no explicit stretch/aspect settings. | Validate native and exported behavior at real window sizes; do not assume editor design-canvas scaling. |

### `720×1280`

| Risk | Why it exists now | Required mitigation or gate |
|---|---|---|
| **Pity row width is structurally brittle** | The label has a 210 px minimum; ten segments each request 24 px plus nine 5 px gaps and row separation. This consumes roughly 507 px before translated text pressure. | In portrait, place the numeric guarantee label above a full-width ten-cell track. Do not keep label and track in one horizontal row. |
| **Header becomes a long vertical stack** | Back, title box, and Marks become three one-column children, consuming first-view height before rate/pity or hero content. | Use one compact top bar with icon navigation, two-line identity maximum, and economy chip. |
| **Three 380 px cards create a gallery tunnel** | The one-column hero grid requires more than 1,100 px before spacing, while the rule panel and action dock are also fixed. | Feature the five-star in the upper stage and use a compact horizontal/stacked four-star rail with local scrolling. |
| **Fixed bottom action must remain visible** | The accepted concept system requires actions never fall below the safe area. Larger translated status or confirmation copy can push the button. | Isolate body scrolling from a fixed dock; cap status to two lines and provide accessible full copy separately. |
| **Reveal risks excessive empty side logic rather than portrait intent** | The current solution only narrows the same centered card to 340 px and lowers portrait height to 280 px. | Author a dedicated portrait reveal composition with full-width hero art, bottom result sheet, and safe-zone-aware filaments. |
| **Localized copy is untested** | Every gacha string is hard-coded English today. Chinese labels and count grammar have no responsive contract. | Add canonical keys and capture `en-US` and `zh-CN` for every target state at 720×1280. |
| **Touch target ambiguity** | Current code does not enforce 44×44 minimum size on Back and Skip, while the portrait layout relies on touch. | Set explicit minimum targets and verify no ornamental child intercepts input. |
| **Aspect breakpoint is width-only** | Any viewport under 900 px uses portrait layout even if it is short landscape; the code does not test aspect ratio. | Use aspect plus width breakpoints, or explicit layout classes shared with staging. Test 720×1280 and a compact landscape guard such as 896×504. |

## Exact implementation targets

The redesign should remain concentrated in presentation files. Gameplay source under `sim/` and authored balance under `data/campaigns/p16_v3.tres` are reference contracts, not visual implementation targets.

| Path | Targeted work |
|---|---|
| `scenes/gacha.tscn` | Keep the stable scene route/root; optionally promote durable high-level presentation nodes from runtime construction into the scene for inspectable anchors and testability. |
| `scripts/ui/gacha.gd` | Refactor into explicit idle, confirmation, commit-pending, reveal-phase, settled-outcome, and locked states; preserve projection/receipt authority and navigation. |
| `scripts/ui/components/lunaris_ops_style.gd` | Stop using the flat style as the gacha’s final shell, or update it to delegate display typography and textured frame primitives to the approved skin system. |
| `scripts/ui/components/staging_skin.gd` | Expose reusable navbar, command-deck, primary-button, resource-chip, display-font, focus, and icon helpers without coupling gacha to staging state. |
| `scripts/ui/components/lunaris_animated_backdrop.gd` | Reuse the accepted top-anchored backdrop behavior with a gacha-specific intensity/scrim option. |
| `scripts/ui/components/resonance_star.gd` | Preserve font independence; add accessible state metadata and optional ignition progress/glow that does not require flashing. |
| `scripts/ui/components/premium_guarantee_track.gd` | **New proposed component:** own the ten native cells, numeric label, forced-next state, and portrait/landscape arrangements; consume projection values only. |
| `scripts/ui/components/premium_hero_card.gd` | **New proposed component:** render catalog plus owned-state projection for featured or compact card variants without transaction behavior. |
| `scripts/ui/components/premium_pull_confirmation.gd` | **New proposed component:** render cost/balance/pity confirmation and emit cancel/confirm signals only. |
| `scripts/ui/components/premium_reveal_director.gd` | **New proposed component:** animate immutable receipt-driven phases, expose skip/finalize, and kill tweens safely. It must not call campaign mutation methods. |
| `scripts/ui/game_typography.gd` | Use the existing type scale for native body text and the Cinzel composite for Latin display/action roles. |
| `scripts/ui/components/ui_copy.gd` | Add static fallbacks and typed placeholders for gacha strings. |
| `localization/en-US.json` and `localization/zh-CN.json` | Add canonically sorted, parity-checked gacha keys for all states, errors, outcomes, counts, rate, confirmation, and accessibility labels. |
| `assets/ui/staging/frames/` and `assets/ui/staging/icons/` | Reuse approved frames/symbols where semantically correct. Do not modify them solely to bake in gacha text. |
| `assets/ui/gacha/` | **New proposed asset family:** only for a Marks symbol, featured banner/reveal frame, guarantee seal, and rarity-specific ornament not covered by staging assets; preserve transparent standalone provenance. |
| `assets/portraits/lunaris_vessel_premium.png` | Replace only through the approved character-art pipeline with a clearly mature 21+ crop that preserves identity, costume, hair, palette, and Crescent Reliquary authority. Review the other two portraits in the same pass for ensemble consistency. |
| `scripts/ui/staging.gd` | Surface real Marks on or adjacent to the Premium Resonance tile/header, clearly separate from the presentation-only mock wallet, and preserve `Game.open_gacha()` entry behavior. |
| `autoloads/game.gd` | Preserve the `open_gacha()`, `pull_premium_hero()`, durable commit, and `open_staging()` bridges. UI redesign should not bypass these methods. |

## Exact test targets

### Existing automated targets that must continue to pass

| Test file | Exact retained assertions |
|---|---|
| `tests/premium_gacha_ui_test.gd` | `PremiumHeroGrid` (or a documented replacement host) represents all three pool identities; `MarksLabel` projects 120; fresh guarantee says 10; ten cells exist; all portraits resolve; pull/back lock during reveal; five-star title/result are receipt-driven; skip is available; skip restores navigation/final copy; reduced motion reaches the same final state. |
| `tests/premium_gacha_pity_economy_test.gd` | Pool size 3; total weight 40; Lunaris Vessel sole 5-star with weight 2; forced tenth pull after nine misses; natural five-star reset; migration activation boundary; 40 Marks on each first clear; zero on repeat; 320 campaign reward Marks; 11 lifetime funded pulls. |
| `tests/premium_hero_system_test.gd` | Idempotent duplicate command; exactly 40 Marks per pull; duplicate lives on same hero; premium non-trainability/no XP; one life consumed per fall; terminal lockout/memorial; later pull revival and memorial removal. |

### Required additions to `tests/premium_gacha_ui_test.gd`

Target the following exact state contracts rather than testing ornamental coordinates alone:

1. `PremiumPullButton.pressed` opens `PullConfirmation` and **does not** call the mutation bridge or change Marks/pull index.
2. `CancelPullButton` closes confirmation, restores Pull focus, and leaves the projection byte-equivalent.
3. `ConfirmPullButton` dispatches once; repeated press/input while pending cannot create a second command.
4. Rejection after confirmation closes the pending state, shows exact error copy, and never opens `PullRevealLayer`.
5. `SkipRevealButton` is visible and enabled from the first rendered reveal frame, not only after the result card fades in.
6. Four-star reveal has exactly four lit stars and one visibly unlit star; five-star reveal has five lit stars.
7. Natural five-star and forced five-star use the same rarity title, while only the forced receipt exposes the guarantee seal/copy.
8. `new_hero`, ordinary duplicate, and `revived` receipts each render distinct result labels and correct life delta/total.
9. Finalization restores focus to Pull if enabled and to Back if spending leaves Pull disabled.
10. Idle `ui_cancel` returns to staging; reveal `ui_cancel` finalizes without navigating away.
11. Scene exit during each reveal phase leaves no valid tween and emits no deferred callback error.
12. Locale changes rebuild visible copy without losing pool identity, focus, or state.

### New automated presentation targets

| Proposed exact file | Required coverage |
|---|---|
| `tests/premium_gacha_navigation_test.gd` | Instantiate staging with an active campaign, activate `RecruitButton`, verify `PremiumGachaRoot`, activate idle Back/`ui_cancel`, verify `StagingRoot`, and prove campaign UID, save revision, Marks, pity, and owned premium rows survive the round trip. |
| `tests/premium_gacha_responsive_test.gd` | Instantiate idle, confirmation, four-star reveal, natural five-star reveal, forced five-star reveal, duplicate outcome, revival outcome, insufficient-Marks, and attempt-pending states at `1280×720` and `720×1280`; assert essential named controls are visible, contained in viewport safe bounds, and non-overlapping. |
| `tests/premium_gacha_localization_test.gd` | Exercise `en-US` and `zh-CN` key parity, typed placeholders, no literal keys/missing glyphs, no clipped essential labels, and correct singular/plural or locale-appropriate count formatting. |
| `tests/premium_reveal_director_test.gd` | Use an immutable sample receipt to test phase order, skip from every phase, reduced-motion bypass, no gameplay calls, final-state equivalence, and tween cleanup. |

### Native visual targets

Capture and review the following exact matrix at both `1280×720` and `720×1280`:

| State | Required visual evidence |
|---|---|
| Fresh idle, 120 Marks | Featured five-star, both four-stars, 5% disclosure, guarantee-in-10, ten cells, balance, cost, fixed action dock, return affordance |
| Pity at 9/10 | Forced-next state is unambiguous without relying only on color |
| Pull confirmation | Cost, balance before/after, guarantee distance, random-pool statement, cancel, and confirm all fit |
| Insufficient Marks | Pull is visibly disabled and exact shortfall is readable |
| Attempt pending | Disabled state points to operation resolution, with Back still available |
| Four-star new hero | Four lit/one unlit stars, mature hero crop, `NEW HERO`, lives, next guarantee, visible skip/continue |
| Four-star duplicate | `LIFE +1`, before/after or total lives, no false new-hero language |
| Revival | `REVIVED`, one life ready, restoration tone, no generic duplicate ambiguity |
| Natural five-star | Gold-white hierarchy, visible fifth-star turn, five-star title, no guarantee-fulfilled badge |
| Forced five-star | Same reward clarity plus restrained `GUARANTEE FULFILLED` seal |
| Reduced motion | Same final information and hierarchy without rotation, overshoot, moving filaments, or light sweep |
| Simplified Chinese | Full first view, correct font fallback, no overflow, no missing glyphs, stable economy and outcome hierarchy |

Every capture must verify adult-age readability, face-safe cropping, signature costume/equipment continuity, text contrast, 44×44 minimum interactive targets, keyboard/controller focus, no content under the fixed dock, no horizontal overflow, and no ornament crossing native copy.

## Acceptance priorities

1. **Do not regress deterministic gameplay.** All receipt, pity, economy, life, revival, replay, and migration tests remain authoritative.
2. **Add a real pre-commit confirmation state.** Cancellation is mutation-free; confirmation submits exactly once.
3. **Restore visual continuity with title and Company Command.** Animated Lunaris atmosphere, Cinzel display hierarchy, clipped engraved surfaces, native localized copy, and generated symbols should form one system.
4. **Make rarity visible in composition and motion.** Feature the five-star in idle, expose a genuinely visible star-charge phase, and distinguish natural/forced five-star without obscuring information.
5. **Protect the 21+ promise.** Replace or re-approve any featured portrait whose facial proportions create ambiguous youth cues, especially Lunaris Vessel.
6. **Keep actions and economy facts in the first view.** Marks, cost, rate, guarantee, status, Back, and the primary action remain reachable at both target viewports.
7. **Close accessibility and localization gaps.** Deterministic initial focus, idle cancel parity, always-available skip, reduced-motion equivalence, CJK fallback, and information not encoded by color alone are release gates.

## Final disposition

The existing family should be treated as a **sound functional reference, not the final visual template**. Preserve its runtime projection and receipt boundaries, three-identity gallery semantics, ten-pull guarantee, fixed-kit/life messaging, reveal lock, skip invariance, reduced-motion path, and staging return. Replace the flat equal-card shell and centered result dialog with a character-forward banner, explicit confirmation sheet, visible phase-based reveal, persistent outcome treatment, and the already-approved Lunaris material/type/component system. This will make Premium Resonance feel like the ceremonial core of the product rather than a utility screen attached to it.
