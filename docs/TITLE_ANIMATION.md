# Lunaris Reliquary Title Animation

## Global visual definition

| Dimension | Specification |
|---|---|
| Purpose | A seamless premium title-loop that extends the loading-screen world into the playable title screen and reinforces high-rarity gacha character appeal. |
| Duration and format | 4.0 seconds, seamless loop, 16:9, silent. Source MP4, optimized 12 fps GIF, and a Godot-compatible frame sequence derived from the same loop. |
| Rendering | Original polished anime tactical-fantasy illustration with crisp mature faces, painterly atmosphere, couture fabric, ivory sacred machinery, and fine gold/cyan effects. |
| Color and light | Moon-cyan volumetric energy, ivory ceramic, violet-black shadows, restrained brushed gold, and warm skin highlights against a deep mineral-blue city. |
| Camera | Locked heroic wide shot. No zoom, pan, reframing, parallax lurch, or shake. The first and last frame should align visually. |
| Audio | None. No dialogue, narration, effects, or background music. |

## Recurring adult character anchors

The central **Lunaris vessel** is the same clearly adult champagne-blond heroine from the approved loading artwork: mature face, braided crown, long loose hair, white and violet-black asymmetrical battle couture, brushed-gold mechanisms, and calm commanding eye contact. The left **reliquary duelist** remains the same clearly adult East Asian man with long black hair, dark teal sleeveless ceremonial tailoring, muscular arms, and a jade-cyan blade. The right **archive caster** remains the same clearly adult East Asian woman with short silver-lilac curls, black-plum ceremonial dress, translucent geometric layers, and a gold ritual focus. Their identities, ages, anatomy, clothing coverage, poses, and positions must not drift.

## Single-clip plan

| Field | Specification |
|---|---|
| Narrative purpose | Establish the faction’s premium aura and provide continuous ambient motion behind the title controls. |
| Pacing | Slow, restrained, hypnotic. |
| Scene | Moon-powered reliquary city with a colossal ivory ring, suspended towers, distant drones, cyan energy seams, and delicate constellation geometry. |
| Content action | Hair tips and loose fabric drift in one gentle cycle; gold/cyan aura pulses once; constellation rings rotate a few degrees and return to loop alignment; distant structures hover by only a few pixels. |
| Transition description | All three clearly adult characters, their costumes, weapons, faces, hands, and exact positions are present from the first frame and remain continuously visible. The heroine’s loose hair and cape edges lift slowly as if moved by low lunar gravity, the duelist’s ponytail and the caster’s translucent panels follow with smaller delayed motion, then all settle back into the starting silhouettes by the final frame. Moon-cyan aura gently brightens around the central reliquary and along gold mechanisms while thin constellation arcs rotate slowly behind the trio; distant drones and towers hover subtly without entering or leaving the shot. The camera stays perfectly locked, no character speaks or changes expression, and the final visual state matches the first for a seamless loop. |
| First keyframe | Approved Lunaris artwork composition, regenerated only as a motion-ready identity-preserving reference. |
| Sound | None. No background music. |

## Implementation note

The GIF is the requested archival and browser-compatible animation. Godot does not use an animated GIF decoder for this runtime path, so the title scene plays an Ogg Theora stream encoded from the same deterministic ping-pong master. This preserves the requested motion and appearance while keeping native and Web exports efficient.

## Native visual verification

The first 1280×720 Xvfb pass captured the existing Lunaris loading overlay at 53% and its synchronized 100% fade. Both remained visually intact after adding the title video resource. These early captures did not yet reach the redesigned title, so a later windowed pass is required for title composition and animation verification.

The later 1280×720 pass reached the redesigned title. Two frames captured 1.1 seconds apart have different hashes and visibly different hair, cyan aura, constellation arcs, and ritual-focus positions, confirming active video playback while the three adult character identities and camera remain stable. The faction header, wordmark, and lower information band match the loader; however, the first layout pass clipped the lower halves of the Start and locale controls at the window edge. That layout is not accepted and must be tightened before final native and Web validation.

The corrected 1280×720 pass expands the dark lower panel and tightens its typography. Both the complete cyan Start control and the complete language selector now sit inside the visible frame with clear focus styling, while the wordmark and faction labels remain separated from the adult character silhouettes. Two corrected frames captured one second apart retain identical UI placement while hair, aura, constellation arcs, and ritual focus advance visibly; the native title layout is accepted for final interaction and Web checks.

The first 720×1280 pass keeps the wordmark, Start control, seed, and language selector fully visible, and pressing **Enter** advances into Company Command successfully. The video layer itself stretches vertically in this pass instead of preserving the 16:9 composition, so the portrait visual is not accepted. The video control must use a calculated 16:9 cover rectangle before portrait validation is repeated.

The corrected 720×1280 pass uses a centered 16:9 cover rectangle. The flagship heroine keeps natural facial and body proportions, fills the vertical hero area without letterboxing, and retains the most important reliquary geometry behind her. The faction label, wordmark, tagline, complete Start control, seed, and complete language selector remain legible; pressing **Enter** again advances into Company Command. Portrait title and interaction validation now pass.

## Web preview verification

The browser-side managed-pack loader now reproduces the Godot loader’s gold top rule, faction/archive header, lower information band, PROTOS wordmark, staged status, percentage, moon-cyan progress bar, and detail copy. A fresh 74,798,156-byte PCK request visibly reached 65% in this unified design. After the in-engine loading sequence completed, the Web canvas displayed the redesigned title with active cyan aura and constellation geometry, complete Start/language controls, and identical visual hierarchy to native desktop.

A later Web title frame shows a different hair silhouette, aura state, constellation position, and hovering background state while every control stays fixed, confirming continuing animation playback in the Web export. The browser console remained empty: no Theora decoder, managed-asset, parser, or runtime errors were emitted.

Pressing **Enter** on the focused Web Start control replaces the animated title with Company Command as intended. The console remains empty after the transition, confirming the title video shuts down with the scene and does not leak decoder or runtime errors into the campaign flow.

Final WebDev screenshots show the complete animated title at 1280×720 with the heroine-led ensemble above the faction-branded Start and language controls. At 720×1280, the host correctly preserves the game’s 16:9 canvas with dark letterboxing while the unified loading layout retains its gold header, artwork, wordmark, cyan progress line, percentage, and detail copy without clipping.
