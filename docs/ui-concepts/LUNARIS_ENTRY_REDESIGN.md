# Lunaris Entry Redesign

## Purpose

The entry screen should read as a premium 21+ anime-gacha title interface rather than a utility footer. The animated Lunaris artwork remains dominant and top-anchored. The interface contains only a centered **PROTOS DEFENSE** wordmark, a primary **START** control, and a secondary **SETTINGS** control. Language and title-music controls move into a dedicated settings sheet.

## Visual system

The wordmark uses the same Cinzel-based display face and ivory/gold hierarchy as Company Command. It floats without a full-width backing container, supported only by restrained dark text shadow and a short cyan-gold orbital rule. The two controls are centered, vertically stacked, and use the textured Lunaris primary-button frame. START receives brighter cyan focus energy and SETTINGS receives a darker glass treatment with a small gold settings glyph. Both remain visually readable over any motion frame through localized shadow and edge treatment rather than a giant footer panel.

The desktop/ultrawide composition places the control stack in the lower central third without covering faces. Portrait uses the same stack with a narrower width and slightly smaller type. The animated background uses a 16:9 cover rectangle anchored at the viewport’s top center: the top edge is always exactly aligned with the viewport, horizontal sides crop for portrait, and only the bottom may crop on screens wider than 16:9.

Company Command uses the same animated-background component and top-anchored cover rule, with its existing opaque command deck preserving text readability. The title music remains authoritative through the Music autoload and does not restart when entering Company Command.

## Settings behavior

SETTINGS opens a centered Lunaris command sheet containing Language, Title Music, Reduced Motion, and BACK. Language reuses the existing EN / 中文 selector. Title Music toggles the Music autoload playback and persists for the current runtime. Reduced Motion freezes the animated backdrop to the high-resolution fallback while the sheet remains usable; disabling it resumes playback. BACK closes the sheet and restores focus to SETTINGS.

## GPT Image 2 prompt

Create a high-fidelity 16:9 visual mockup for the start screen of an original premium adult anime tactical-gacha game named **PROTOS DEFENSE**. Use the approved Lunaris Reliquary animated-background composition as the full-bleed backdrop: three exceptionally attractive clearly adult heroes, blonde woman commander centered, black-haired man left, silver-haired woman right, celestial mechanical archive, ivory, gold, cyan, and deep navy. Keep the background art top-aligned with the top edge completely visible; bottom cropping is acceptable.

Remove all existing footer bars, language selectors, seed labels, taglines, and wide containers. Place only a refined centered wordmark **PROTOS DEFENSE** in large bold high-contrast classical serif display type, then two centered stacked controls below it: **START** and **SETTINGS**. Controls must match a sophisticated Lunaris command interface: dark navy glass, engraved ivory-and-gold mechanical frame, cyan energy edge, sharp rectangular geometry with clipped corners, subtle constellation ornament, no rounded mobile-app buttons. START is brighter and dominant; SETTINGS is narrower/darker with a small elegant gear or orbital glyph. Use localized shadows and thin framing only, not a full-width panel. Preserve generous breathing room, clear focus hierarchy, realistic game-ready spacing, and strong legibility at desktop and portrait adaptation. Original interface, no copied logos, no additional text, no characters under 21.

Avoid retro flat boxes, giant cyan rectangles, full-width footer panels, tiny typography, excessive labels, generic rounded buttons, purple gradients, neon overload, over-decoration, and text placed over faces.

## Acceptance

The final implementation must preserve the top edge at ultrawide, show no full-width title container, expose only the required wordmark and two main buttons, open a functional settings sheet, reuse the animated background in Company Command, retain keyboard/controller focus, and pass 2560×1080, 1920×1080, and 720×1280 visual checks.

## First ultrawide implementation pass

The 2560×1080 title capture confirms the animated artwork is flush to the top edge with the complete upper celestial arch visible; excess height is cropped only below the viewport. The former footer, language control, seed, tagline, and full-width container are gone. **PROTOS DEFENSE**, START, and SETTINGS form a centered Cinzel/engraved-frame hierarchy without covering any face.

The Settings sheet is centered, readable, and consistent with Company Command. Language and BACK render correctly, but the music and animated-background rows currently expose the literal `{STATE}` placeholder. That formatting defect is not accepted and must be corrected before the settings flow passes.

The placeholder schema now registers both state tokens. The repeated 2560×1080 capture renders **TITLE MUSIC // ON** and **ANIMATED BACKGROUND // ON** correctly. A first automated attempt to leave Settings captured the title again because Escape focus restoration and the next key were dispatched in one burst; the visual itself remained valid, and the route was repeated with deliberate focus delays before accepting Company Command.

The corrected Company Command capture shows the same later animated Lunaris frame behind the command deck, proving the static staging texture has been replaced rather than merely restyled. The celestial arch is top-aligned and the opaque navigation/deck surfaces preserve readability.

The 720×1280 title capture keeps the commander’s full face and upper celestial arch visible at the top edge, crops horizontally rather than vertically, and places the centered PROTOS DEFENSE / START / SETTINGS stack below the face. All three controls fit within the first view without a footer or full-width container.

The portrait Settings sheet fits all four controls within the first view with correct ON states, visible focus, and no text clipping. The portrait Company Command screen uses the same animated frame behind its top bar and scrollable command sheet; the commander remains visible above the sheet and the top edge of the celestial arch stays flush with the viewport.

A deterministic rendered-scene probe at 2560×1080 confirms both fallback and animated video rectangles have `y = 0`, the cover height exceeds the viewport, and the title video reaches a decoded ready state. The same probe opens and closes Settings, toggles title music off/on, toggles reduced motion to the fallback and back to video, then instantiates Company Command and confirms its shared animated backdrop reaches ready state. The probe passes without script, shader, focus, music, or navigation errors.

## GPT Image 2 concept review

The completed 1920×1080 concept validates the intended hierarchy: a large centered serif PROTOS DEFENSE wordmark, a dominant engraved START control, a narrower SETTINGS control with an orbital glyph, no footer bar, and no utility copy competing with the three adult heroes. The implementation follows its stacked composition and clipped gold/cyan frame language while using the project’s actual Cinzel fonts and StagingSkin assets instead of baking visual text into artwork.

The concept is archived at `docs/ui-concepts/assets/Lunaris Entry - Start Screen Concept.webp` with SHA-256 `35b921a81c6e58cba7f7ae8088f3a78043e3fc804042fdf7b9004932612b1bc8`.

## Web preview validation

The synchronized preview requests the 134,023,952-byte redesigned PCK successfully and hands the browser loader into the matching in-engine Lunaris loading sequence. The first post-download frame shows the expected loading artwork, status hierarchy, and progress treatment without a blank canvas or asset error.

The loaded Web title renders the animated top-anchored Lunaris frame, centered PROTOS DEFENSE wordmark, and two engraved controls with no footer container. A later frame shows the characters continuing to move, and Arrow Down moves visible focus from START to SETTINGS without disturbing the responsive composition.

Enter opens the functional centered Settings sheet. It renders LANGUAGE, TITLE MUSIC // ON, ANIMATED BACKGROUND // ON, and BACK with the same engraved command styling; Arrow Up moves visible focus from BACK to ANIMATED BACKGROUND, confirming the keyboard path into the new settings controls.

Activating ANIMATED BACKGROUND changes the state to OFF and immediately freezes to the high-resolution fallback without losing top alignment or settings readability. Activating it again restores the ON state and the live animated frame, confirming that reduced-motion behavior is functional rather than decorative.

Escape closes Settings and returns focus to the SETTINGS control; Arrow Up restores focus to START. The intervening title frames show independent character pose and expression changes, confirming the animation remains active after the settings round trip.

Enter on START transitions directly into Company Command. Two later command frames show different facial, hair, and aura states behind the unchanged command deck, confirming Company Command uses the shared animated stream instead of a static placeholder. The top celestial edge remains aligned while the deck preserves character-safe readability.

The current Web session console is empty after title, Settings, reduced-motion, music, and Company Command operations. The redesigned 134,023,952-byte PCK returns HTTP 200 with the expected byte count. Historical August 24 compile messages remain in the cumulative log but are absent from the scoped August 25 session; the scoped script, shader, video, audio, null-child, and resource-error audit passes.

## Merged-candidate acceptance

After merging the latest custom naming, faction roster filters, Vahalla, premium gacha, and terrain placement feedback work, Godot import, bounded boot, and all five focused SceneTree regressions pass. The repeated 2560×1080 captures preserve the top-aligned PROTOS DEFENSE title and show Company Command’s animated backdrop coexisting with the new Vahalla operation tile and incoming staging content without overlap or lost controls.

The final merged 134,086,324-byte PCK loads in the reconciled shared preview and reaches the redesigned animated PROTOS DEFENSE title. The top celestial edge, centered controls, full-opacity animation, title music, and latest synchronized gameplay assets coexist in the same final bundle.

The later published portrait map-navigation branch was also merged into the definitive candidate. Its orientation, overlay, and placement-feedback smoke markers pass alongside the rendered Lunaris entry probe, preserving two-axis portrait panning, elastic edge feedback, recenter controls, and the redesigned entry/command screens in one source tree.
