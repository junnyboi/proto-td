# Lunaris Reliquary Title Loop

> **Historical technical evidence; not narrative canon.** This production record documents title media, checksums, rendering, and measured image quality. It does not define the world or character story. The sole narrative authority is [`../../NARRATIVE_CANON.md`](../../NARRATIVE_CANON.md). Any superseded story implications in source media or older plans are non-canon.

The title animation represented by this production record was verified as a **8.0-second silent continuous forward 1920×1080 loop** generated from the pristine Lunaris loading composition with Veo 3.1. The locked camera preserves all three clearly adult characters while each receives an independent hair cycle and restrained facial micro-expression sequence. Cyan aura breathes, constellation geometry rotates continuously forward, and distant reliquary structures follow closed hover paths. No reversed or ping-pong frames remain.

| File | Purpose |
|---|---|
| `lunaris-title-keyframe.png` | Motion-ready identity reference generated from the approved loading artwork. |
| `lunaris-title-source.mp4` | Selected high-bitrate eight-second 1920×1080 Veo generation with identical loop-locked opening and closing keyframes. |
| `lunaris-title-loop.mp4` | Continuous forward eight-second 1920×1080 production master with a 0.6-second closing cross-dissolve into the opening state; no reversal or ping-pong post-processing. |
| `lunaris-title-loop.gif` | Optimized 960×540, 12 fps continuous looping GIF for archival and browser-compatible reuse. |
| `lunaris-title-loop-hires-source.mp4` | Recorded 1920×1080 Veo 3.1 master with three-character hair motion and facial micro-expressions. |
| `SHA256SUMS` | Checksums for the generated and converted media assets. |
| `HIGH_RES_SHA256SUMS` | Historical checksums for the recorded high-resolution master, Godot stream, and pristine base artwork. |
| `CONTINUOUS_1080P_PLAN.md` | Production prompt, cyclic-motion design, forward-only seam policy, and acceptance gates. |
| `HIGH_RES_COMPOSITE_PLAN.md` | Recorded sharpness diagnosis, expression cycles, composite architecture, and native/Web acceptance evidence. |

In the verified implementation, Godot used `res://assets/title/lunaris-title-loop.ogv` as a motion source rather than the final visible-detail layer. `scripts/ui/title.gd` keeps the pristine 2560×1440 loading artwork as the authoritative base and applies controlled motion/color deltas through a custom CanvasItem shader while restoring high-frequency detail from the base texture. The recorded comparison raised native background-region SSIM against the loading artwork from **0.280900** for the retired direct-video renderer to **0.594107** for the current composite.

The older `lunaris-title-source.mp4`, `lunaris-title-loop.mp4`, and `lunaris-title-loop.gif` remain only as historical derivatives. They are not packaged as the runtime title background.
