# Lunaris Reliquary Title Loop

The title animation is a confirmed **4.0-second silent 16:9 loop** derived from the approved Lunaris loading composition. The generated source maintains a locked camera and restrained motion: adult character hair and fabric drift, cyan aura breathes, constellation geometry rotates slowly, and distant reliquary structures hover.

| File | Purpose |
|---|---|
| `lunaris-title-keyframe.png` | Motion-ready identity reference generated from the approved loading artwork. |
| `lunaris-title-source.mp4` | Original four-second image-to-video generation. |
| `lunaris-title-loop.mp4` | Deterministic four-second ping-pong master made from the first two seconds and their reverse, ensuring first/last visual continuity. |
| `lunaris-title-loop.gif` | Requested optimized 800×450, 10 fps looping GIF for archival and browser-compatible reuse. |
| `SHA256SUMS` | Checksums for the generated and converted media assets. |

Godot uses `res://assets/title/lunaris-title-loop.ogv`, encoded from the same deterministic loop. This avoids relying on a native animated-GIF decoder while presenting the same motion sequence in desktop and Web exports.
