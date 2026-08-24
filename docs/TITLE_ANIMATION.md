# Lunaris Reliquary Title Animation

## Global visual definition

| Dimension | Specification |
|---|---|
| Purpose | A seamless premium title-loop that extends the loading-screen world into the playable title screen and reinforces high-rarity gacha character appeal. |
| Duration and format | 8.0 seconds, continuous forward seamless loop, 1920×1080, 16:9, silent. High-bitrate MP4 master, optimized 12 fps GIF, and a full-1080p Godot Ogg Theora runtime derivative. |
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
| Content action | Hair tips and loose fabric complete one forward low-gravity wave cycle; gold/cyan aura completes two breathing pulses; constellation rings rotate continuously through whole-circle cycles; distant structures follow small closed hover paths. |
| Transition description | All three clearly adult characters, their costumes, weapons, faces, hands, and exact positions are present from the first frame and remain continuously visible. The heroine’s loose hair and cape edges travel through one smooth low-gravity wave while the duelist’s ponytail and caster’s translucent panels follow with restrained delayed motion; nothing reverses like rewound footage, and each material returns naturally to its opening phase by the final frame. Moon-cyan aura completes two soft breathing pulses while thin constellation mechanisms rotate continuously forward through full cycles; distant drones and towers follow small closed hover paths without entering or leaving the shot. The camera stays perfectly locked, no character speaks or changes expression, and the eighth-second visual state matches the first for immediate seamless repetition. |
| First keyframe | Approved Lunaris artwork composition, regenerated only as a motion-ready identity-preserving reference. |
| Sound | None. No background music. |

## Implementation note

The GIF remains the archival and browser-compatible animation. Godot does not use an animated GIF decoder for this runtime path, so the title scene plays a 1920×1080 Ogg Theora stream encoded directly from the continuous forward Veo master. No frames are reversed and no ping-pong construction remains.

## Continuous 1080p replacement

The replacement uses identical loop-locked opening and closing keyframes with an eight-second Veo 3.1 Fast generation. The selected source reports 1920×1080, 24 fps, exactly 8.0 seconds, and approximately 20.2 Mbps. A forward-only 0.6-second closing cross-dissolve into the opening keyframe improves the first/last PSNR from 16.31 dB to 33.63 dB while the first/mid-cycle PSNR remains 12.97 dB, proving the seam is substantially closer than the visible internal motion without introducing reversed frames. The final production master reports approximately 30.96 Mbps; the runtime Theora derivative retains 1920×1080, 24 fps, and exactly 8.0 seconds. The updated GIF is 960×540 at 12 fps for a sharper archival preview. Detailed motion and seam requirements are preserved in `docs/animations/lunaris-reliquary/CONTINUOUS_1080P_PLAN.md`.

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

After synchronizing with the latest master responsive-typography work, the merged-final 74,800,624-byte pack again passes the unified browser loader and animated title handoff. The merge reduces the locale-selector type and button scale too aggressively on this cinematic title, making the language utility visually weaker than the Start action; this title-specific regression must be corrected before the final checkpoint and Git integration.

The title now applies local font and minimum-size overrides without altering the shared responsive components. A fresh 1280×720 native capture shows a balanced utility column: **Language**, **EN**, and **中文** are readable at a glance, the complete selector remains inside the lower panel, and the Start action retains clear primary dominance. The merged-baseline title layout is accepted.

The final 74,800,752-byte managed PCK repeats the unified loader-to-title flow successfully in Chromium. The title-specific locale override is present in the Web export: Language, EN, and 中文 are readable, the selector remains fully contained, the cyan Start action remains dominant, and the adult character animation continues behind fixed controls.

The final browser console remains empty, and pressing **Enter** again replaces the animated title with the synchronized Company Command screen. Final Web runtime, decoder shutdown, focus, and scene-transition checks pass.

## Native 1080p continuous-loop verification

Godot `4.7.2.stable.official.ed1daf0bf` imports and bounded-boots the replacement cleanly. A native 1920×1080 Xvfb pass produces two full-resolution title captures four seconds apart with different hashes. Both frames retain crisp eyes, hair strands, couture seams, gold mechanisms, constellation linework, moon-city architecture, fixed UI placement, and stable clearly adult character identities; the halo, hair, fabric, aura, and hovering background states advance visibly rather than reversing. Native 1080p playback and presentation pass.

The refreshed WebDev host downloads the new 120,728,848-byte managed PCK through the unified Lunaris loader and reaches the title successfully. The Web canvas shows materially sharper facial, hair, fabric, halo, and city detail than the retired 720p stream while preserving fixed controls and stable identities. The displayed state several seconds after handoff differs visibly from the opening state, confirming active forward playback in the browser.

Two later Web observations show distinct forward halo alignments, aura phases, hair silhouettes, and hover states while the characters and title controls remain fixed. The sequence continues across multiple eight-second cycles without the previous visible play-then-rewind behavior, freezing, or identity drift. Continuous Web looping passes.

The browser console remains empty after multiple 1080p cycles. Pressing **Enter** replaces the title with the synchronized premium Company Command screen, confirming the larger Theora decoder shuts down cleanly and the Start flow remains intact.
