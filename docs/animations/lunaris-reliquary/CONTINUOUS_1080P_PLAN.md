# Lunaris Reliquary — Continuous 1080p Title Loop Plan

## Global definition

| Dimension | Production requirement |
|---|---|
| Purpose | Replace the visible 720p four-second ping-pong title animation with a premium high-rarity gacha presentation that holds at fullscreen 1080p. |
| Duration | Exactly 8.0 seconds. One forward-moving cycle; no reversed frames, rewind, bounce, or ping-pong construction. |
| Frame | 1920×1080, 16:9, upright, 24 fps, locked heroic wide composition. |
| Audio | None. No dialogue, sound effects, narration, or music. |
| Model | Veo 3.1 Fast, the strongest available production image-to-video path for this workflow. |
| Runtime | High-quality 1920×1080 Ogg Theora for Godot desktop and Web; MP4 master and optimized GIF retained in the documentation archive. |

## Recurring adult character anchors

The central **Lunaris vessel** remains the same clearly adult champagne-blond heroine with a mature face, braided crown, long loose hair, white and violet-black asymmetrical couture, brushed-gold mechanisms, and calm commanding eye contact. The left **reliquary duelist** remains the same clearly adult East Asian man with long black hair, dark teal sleeveless ceremonial tailoring, muscular arms, and a jade-cyan blade. The right **archive caster** remains the same clearly adult East Asian woman with short silver-lilac curls, black-plum ceremonial dress, translucent geometric layers, and a gold ritual focus. Their faces, anatomy, clothing, poses, hands, silhouettes, ages, and screen positions remain stable for the full loop.

## Single-clip plan

| Field | Specification |
|---|---|
| Narrative purpose | Deliver an impressive premium title tableau with continuous ambient motion and a natural seamless return to the opening state. |
| Pacing | Slow, hypnotic, confident, sensual but non-explicit. |
| Scene | Moon-powered reliquary city, colossal ivory halo, suspended towers, distant drones, cyan energy seams, gold star charts, and layered constellation geometry. |
| Camera | Perfectly locked. No pan, tilt, zoom, dolly, reframing, parallax lurch, or shake. |
| Content action | Hair and fabric complete one smooth low-gravity wave cycle; cyan/gold aura completes two breathing pulses; constellation rings complete whole forward rotations; suspended structures trace small closed hover paths; all elements return naturally to their opening phase at 8.0 seconds. |
| Transition description | All three clearly adult characters and every major reliquary structure exist from the first frame and remain continuously visible. The heroine’s loose hair and cape edges drift in a single smooth forward sinusoidal cycle while the duelist’s ponytail and caster’s translucent layers follow with restrained delayed motion; nothing reverses direction like rewound footage, and each material settles naturally into its opening phase at the end. Cyan aura completes two soft breathing pulses, thin constellation mechanisms rotate continuously forward through whole-circle cycles, and distant towers and drones travel tiny closed hovering paths without entering or leaving frame. The camera remains perfectly locked, expressions remain composed, faces and hands do not morph, and the eighth-second frame visually matches the opening state for a seamless repeat. |
| Existence constraints | No new characters, limbs, weapons, text, logos, sparks, architecture, or foreground objects appear or disappear. No blinking cut, camera cut, flash transition, morph, deformation, lip movement, or expression change. |
| Sound | None. No background music. |

## Forward-only seam policy

The generated 8.0-second source is evaluated directly. If its last frame is not sufficiently aligned with the first, only the final 0.6 seconds may use a forward cross-dissolve into the opening 0.6 seconds. This preserves an exact eight-second duration and continuous forward motion while explicitly prohibiting reversed frames or ping-pong construction.

## Acceptance gates

The master must report 1920×1080 at 24 fps and 8.0 seconds. Frame-difference measurements must show visible motion inside the clip and a smaller first/last seam difference than the mid-cycle difference. Native title playback must remain sharp at 1920×1080 with stable identities, and the Web export must load, loop, and transition to Company Command without decoder or runtime errors.
