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

Godot renders the pristine 2560×1440 texture as the base. The generated video is composited above it with a custom CanvasItem shader that applies only controlled low-frequency motion and color deltas while restoring high-frequency luminance detail from the base texture. High-detail regions therefore inherit the loading image’s edge quality rather than the video codec’s softened reconstruction.

The same 16:9 cover rectangle is applied to both layers in landscape and portrait. The existing title UI, Astra Memoriam music lifecycle, Start behavior, locale controls, and loading-screen artwork remain unchanged.

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
