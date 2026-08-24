# Lunaris Reliquary Title Loop

The title animation is a confirmed **8.0-second silent continuous forward 1920×1080 loop** derived from the approved Lunaris loading composition. The generated source maintains a locked camera and rich restrained motion: adult character hair and fabric complete smooth low-gravity cycles, cyan aura breathes twice, constellation geometry rotates continuously forward, and distant reliquary structures follow closed hover paths. No reversed or ping-pong frames remain.

| File | Purpose |
|---|---|
| `lunaris-title-keyframe.png` | Motion-ready identity reference generated from the approved loading artwork. |
| `lunaris-title-source.mp4` | Selected high-bitrate eight-second 1920×1080 Veo generation with identical loop-locked opening and closing keyframes. |
| `lunaris-title-loop.mp4` | Continuous forward eight-second 1920×1080 production master with a 0.6-second closing cross-dissolve into the opening state; no reversal or ping-pong post-processing. |
| `lunaris-title-loop.gif` | Optimized 960×540, 12 fps continuous looping GIF for archival and browser-compatible reuse. |
| `SHA256SUMS` | Checksums for the generated and converted media assets. |
| `CONTINUOUS_1080P_PLAN.md` | Production prompt, cyclic-motion design, forward-only seam policy, and acceptance gates. |

Godot uses `res://assets/title/lunaris-title-loop.ogv`, encoded directly from the same 1920×1080 continuous forward master. This avoids relying on a native animated-GIF decoder while preserving the full-resolution motion sequence in desktop and Web exports.
