# Lunaris Title High-Resolution Composite Plan

## Problem

The current title exposes a 1920×1080 YUV420 Theora stream as the entire background. Even at a high bitrate, generated-video texture and chroma subsampling soften faces, hair strands, jewelry, and architecture compared with the pristine 2560×1440 loading artwork.

## Production direction

The approved loading artwork remains the authoritative visible-detail layer. The new eight-second motion pass is generated from that exact composition with a locked camera and restrained cyclic motion: hair and fabric drift, aura breathing, slow constellation rotation, and hovering reliquary structures. Character identity, anatomy, costume geometry, framing, and background architecture must remain stable.

The opening and closing states are compositionally identical. Motion advances continuously through the full cycle; no reversed or ping-pong frames are allowed. The motion pass contains no text, UI, particles crossing faces, cuts, zooms, pans, or newly invented objects.

## Character motion cycle

| Character | Hair and costume motion | Facial micro-expression cycle |
|---|---|---|
| Central blonde reliquary commander | Long braids, loose lengths, sleeve edge, and mantle tips move in a slow low-amplitude astral breeze without changing her silhouette or pose. | One gentle natural blink near the first third; a very small eye-focus shift toward the viewer; subtle breathing in cheeks and shoulders; the mouth corners soften by only a few pixels and return to the original calm expression. |
| Left dark-haired swordsman | Ponytail and loose strands arc slightly behind him, settle, then complete the same forward circular motion; no sword or torso displacement. | One restrained blink near the middle; a small confident narrowing and release of the eyes; minimal jaw and breathing change; no head turn, speech, or aggressive expression change. |
| Right violet-haired astrologer | Short curls, translucent fabric, and hanging ornament tips drift independently while the astrolabe continues a slow controlled orbit. | One soft blink in the latter third; a slight knowing eye-focus shift; a nearly imperceptible mouth-corner lift and release; no lip-sync movement, face warping, or gaze reversal. |

Every character remains visibly adult. Facial landmarks, eye color, costume construction, anatomy, hands, jewelry, and placement stay fixed. All three motion cycles return naturally to the opening state at eight seconds.

## Runtime architecture

The pristine 2560×1440 loading texture is now a startup fallback only. It remains visible while the Ogg Theora stream decodes its first frame, then the title controller hides it as soon as playback position advances beyond zero.

The animated background renders at **100% opacity** through a video-only unsharp-mask shader. The shader samples only the current video frame and never samples or blends the static artwork, so moving characters cannot reveal a doubled or ghosted pose behind them. The same 16:9 cover rectangle is applied in landscape and portrait. The existing title UI, Astra Memoriam music lifecycle, Start behavior, locale controls, and loading-screen artwork remain unchanged.

## Acceptance targets

The final title must remain visibly animated at multiple points in the eight-second cycle while reading as sharp as the loading artwork at 1920×1080. Faces, hair, costume embroidery, jewelry, constellation lines, and reliquary architecture must remain stable. Native and Web captures must show no stretching, doubled silhouettes, ghosted faces, decoder errors, parser errors, or title-input regressions.

## Native visual validation

The first 1920×1080 composite captures pass the sharpness target. Hair strands, jewelry, costume embroidery, constellation lines, and reliquary architecture remain materially cleaner than the prior direct-video title because the pristine loading image supplies the visible high-frequency detail.

Frames sampled several seconds apart confirm forward motion without a ping-pong reversal. The central commander’s loose hair, facial focus, and mouth softness change subtly; the left swordsman’s ponytail and gaze state shift; the right astrologer’s curls and eyelids change independently. Character identities and silhouettes remain stable. A brief cyan-gold astral haze crosses the lower scene in one phase but clears in the later frame without obscuring the title controls.

The later third frame confirms the haze is transient and the composition returns to a clean, sharply rendered state while all three hair silhouettes and facial states remain distinct from the earlier samples. The background-region SSIM against the pristine loading artwork rises from **0.280900** for the retired direct-video renderer to **0.594107** for the new composite, more than doubling structural similarity at native 1920×1080. Edge energy remains strong across the sampled cycle without visible block artifacts.

The accepted expression-enabled source is an eight-second 1920×1080 H.264 stream at 24 fps and approximately 20.16 MB. The Godot runtime derivative is an eight-second 1920×1080 Theora stream at 24 fps and approximately 49.28 MB. Checksums are recorded in `HIGH_RES_SHA256SUMS`.

The final 720×1280 portrait capture preserves the 16:9 cover crop without stretching the central commander, retains sharp hair and costume detail, and keeps the full title, Start, seed, and locale controls visible. Activating the focused Start control exits the composite video and Astra Memoriam cleanly into the synchronized premium staging screen. A full editor import was required after the latest master sync so newly added faction WebP resources were available; the post-import run is free of parser, resource, shader, and navigation errors.

The refreshed managed Web pack loads successfully under the standard `?from_webdev=1` route. The first rendered title frame retains crisp hair strands, facial landmarks, garment edges, jewelry, and lunar-gate detail at the browser canvas scale while showing the expression-enabled motion state. The browser-side loader hands off without a blank frame or layout regression.

Later browser observations show distinct forward cycle states without a freeze or ping-pong reversal. The commander’s loose hair, hand-side strands, eyes, and mouth softness change; the swordsman’s ponytail silhouette shifts; the astrologer’s curls and eyelids move independently. The high-resolution base continues to preserve clean linework and architecture detail through those states.

The browser console remains empty after multiple cycles: no shader, Theora decoder, resource, script, null-child, or animation errors are emitted. Activating Start stops the composite title and Astra Memoriam cleanly and enters the synchronized Company Command screen with the latest faction heraldry and premium staging work intact.

## Full-opacity handoff validation

A deterministic rendered-scene probe confirms the fallback is hidden after the first decoded frame, the video remains playing with opacity exactly `1.0`, and the active shader contains no static-base sampler. Two native 1920×1080 frames sampled at different cycle positions show a single clean silhouette for every character: the earlier astral-haze state and later clear state both contain no doubled faces, hair, hands, costumes, or architecture. The motion stream remains independently animated while the fallback stays hidden.

The 720×1280 portrait capture also shows a single full-opacity animated character image with no static pose visible behind the moving hair, face, hand, or costume. The 16:9 cover crop, title hierarchy, Start control, seed, and locale selector remain complete. The automated Enter transition completed without parser, shader, video, music, or navigation errors; the saved post-transition frame is a valid 720×1280 PNG, although one subsequent sandbox image-view request encountered a transient DNS-resolution failure.

The refreshed managed Web pack downloads and reaches the in-engine Lunaris loading sequence successfully. One browser-view request briefly reset to `about:blank`; reopening the same preview route recovered normally, and the 100% loading frame renders with the expected static artwork before the title video handoff.

Two later Web title observations confirm the fallback has been removed: the commander moves from open eyes to a closed-eye expression, hair and aura positions change, and every character remains a single fully opaque silhouette. No static face, hair, hand, garment, or architecture pose is visible behind the animated frame in either cycle state.

The browser console remains empty after the fallback handoff and multiple animated cycles. Activating Start stops the video and Astra Memoriam cleanly and enters the synchronized Company Command screen without leaving any title or fallback layer behind.
