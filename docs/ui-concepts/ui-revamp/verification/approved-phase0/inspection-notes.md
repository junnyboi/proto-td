# Approved UI Phase 0 Visual Inspection

## Premium Resonance confirmation

The `720×1280` capture passes the approved portrait-sheet contract: the veiled transaction state remains visibly connected to Premium Resonance, the command sheet is bottom-attached, the 520 px frame stays inside the safe viewport, Cancel remains the safe left/default action, and the complete authoritative cost, balance delta, hard-pity distance, and one-life rule remain visible. The `1280×720` capture preserves the centered landscape exception and keeps both actions visible, but the local body scroller clips the final line by several pixels at the initial allocation. The body-scroll height will be increased without changing panel width or transaction behavior, then recaptured.

## Battle field command

The corrected `1280×720` live state passes the release-blocking geometry contract. The battle command strip remains at the top-right, while the spell command deck now occupies the bottom-right and no longer intersects Pause, Speed, or Resign. The HUD omits the debug tick and retains only authoritative core HP, DP, eliminations, and battle state. The `720×1280` state also passes hit-region separation: spell actions sit in the upper-right rail, controls occupy a distinct row below, the HUD remains at the upper-left, Recenter stays independent, the first-use pan hint clears deployment controls, and the deployment deck remains touch-reachable. All five controls are focusable in source and covered by regression assertions.

## Withdrawal boundary

The landscape withdrawal modal passes: the battlefield remains visible beneath a strong veil, the destructive action is visually separated, and the complete consequence copy fits without clipping. The portrait sheet is correctly bottom-attached and contained, but the map-pan hint currently draws above its title because `MapNavigationOverlay` has a higher battle-layer z-index than the generic modal. The dialog overlay will receive a local modal z-index so the veil and sheet fully dominate every transient battle affordance while open.

## Training persistent command dock

Training now passes the first-view action requirement in both orientations. At `1280×720`, `NOT NOW`, `VIEW PATHS`, and `REVIEW PLAN` remain continuously visible beneath independent roster/inspector scrolling. At `720×1280`, the same three actions stack into a touch-safe bottom dock while the roster and selected-operator dossier continue to scroll locally above it. Existing node names, enablement, callbacks, transaction states, and safe-exit routing are unchanged; the new campaign regression explicitly rejects any future scroll ancestor for `TrainingBack`.

## Premium Resonance asymmetric stage

The three authoritative premium identities now read as a composed banner rather than an equal-card utility grid. Lunaris Vessel receives a 460×430 five-star hero stage with a substantially larger portrait, while Archive Caster and Reliquary Duelist remain visible as secondary 250×350 identities. The sole 40-Mark action, rate, hard-pity meter, life/revival states, node handles, and confirmation boundary remain unchanged. Both `1280×720` and `720×1280` confirmation captures pass: landscape copy no longer clips, and the portrait sheet remains contained beneath the enlarged featured identity.

## Vahalla selected memorial

Vahalla now gives the selected fallen identity clear visual primacy. Landscape uses a 680 px memorial dossier with a 320×420 portrait and a ruled terminal-service ledger; portrait moves the dossier first and expands the identity portrait to a 380 px presentation before the searchable fallen roster. Faction, class, death stage/reason/tick, permanence copy, Honor action, filters, hero IDs, and navigation are preserved. The new ledger is slightly compressed by its textured frame in both captures; a fixed minimum height will be added before final recapture.

## Results ceremony hierarchy

Results now opens with a dedicated textured outcome band: `CLEAR`/`DEFEAT` is the dominant 40 px display headline, while stage identity, stars, kills, and leaks remain authoritative supporting metrics. Landscape retains the two-column mission-yield/consequence body and persistent Retry/Command/Back actions; portrait stacks the complete ceremony, rewards, consequence, casualty record, and three actions without clipping. No payload, routing, or transaction semantics changed.

## Campaign selected-operation dossier

Stage Select now projects the localized authoritative objective and threat plus typed first-clear reward identity alongside squad limit, wave windows, reward count, leak limit, stars, and unlock state. This materially closes the approved mission-dossier gap in both orientations. The added content currently pushes the final stage hint below the visible dossier bounds at `1280×720` and clips its lower line at `720×1280`; the dossier will own a vertical `ScrollContainer` so route scrolling and dossier scrolling remain independent and no content is lost.

**Vahalla corrective recheck:** the 132 px service ledger now contains the terminal record and permanence statement cleanly in portrait, with Honor remaining reachable and the fallen roster beginning below the selected identity. Accepted.

**Campaign corrective recheck:** independent dossier scrolling now prevents content loss and exposes a dedicated scrollbar, but the initial landscape view still places the first-clear reward below the fold. The fact block will be compressed to two lines and local spacing reduced so objective, threat, key constraints, and first-clear identity all appear before scrolling; the original hint remains available immediately below.

**Campaign density recheck:** objective, threat, constraints, and first-clear identity are now all present before scrolling in landscape and portrait. The reward line sits too close to the lower ornament, so its display order will move immediately above the two-line constraint block; the content and independent scroll contract remain unchanged.

**Withdrawal final recheck:** the modal veil and sheet now render above the pan hint and every other transient battle affordance in both orientations. Portrait remains bottom-attached; landscape remains centered. Full consequence copy, safe Return default, destructive Confirm, focus restoration, and Confirm-only mutation are accepted.

## Final acceptance

The accepted candidate passes direct Godot 4.7.2 import, bounded boot, all 29 current repository tests, localization parity, and a clean consolidated error scan. The 12-screen non-battle matrix and eight-state battle matrix pass at `1280×720` and `720×1280`. Existing authoritative inputs and mutation boundaries remain intact; visual changes are projection, layout, typography, localized copy, and focus behavior only. The last Stage Select ordering adjustment places first-clear identity above the two-line constraint block, leaving the original stage hint inside the dossier’s independent local scroller.
