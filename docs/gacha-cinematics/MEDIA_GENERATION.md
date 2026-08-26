# Premium Resonance Cinematic Media Generation

| Field | Value |
|---|---|
| **Phase** | Full-HD action and native-audio regeneration |
| **Status** | Runtime media integrated; final repository and deployment gates pending |
| **Visual output** | Six eight-second 1080p MP4 masters and six exact 24 fps Theora OGV runtime streams |
| **Fallback output** | Six identity-matched WebP plates generated from the approved final keyframes |
| **Runtime video size** | 155,764,928 bytes across six independently streamed objects |
| **Runtime audio** | Three synchronized 48 kHz stereo Vorbis mixes, exactly 8.000 seconds each |

## Generation route

The replacement route uses **GPT Image 2** for three clean identity anchors and twelve dedicated 16:9 or 9:16 opening/final keyframes. Each full-size character reference sheet under `docs/lunaris-reliquary/` is the sole identity, anatomy, costume, and weapon authority. The approved Lunaris title keyframe contributes only environmental materials, lighting, and monumental architectural finish. All shots contain exactly one clearly adult hero on the centerline and exclude generated text, UI, character duplication, side-standing composition, and unintended filament webs.

The six masters were generated with **Wan 3.0 Prime** using first-and-last-frame control, reasoning enabled, native synchronized audio, and dedicated landscape or portrait composition. Veo 3.1 and Veo 3.1 Fast were attempted first but rejected the production batch for capacity; the pipeline moved to Wan rather than reducing resolution. Every master is 8.080 seconds at true 1920×1080 or 1080×1920 with a stereo AAC source track.

The final runtime streams are conformed to exactly 8.000 seconds and 24 fps, encoded as full-resolution `yuv420p` Theora, and contain no embedded audio. Keeping the synchronized mix separate preserves the existing Godot Music volume, Skip, crossfade, scene-exit, reduced-motion, and fallback contracts. The landscape native-audio bed is the orientation-independent runtime authority for each hero.

## Runtime streams

| Stream | Resolution | Duration | Codec | Bytes | SHA-256 |
|---|---:|---:|---|---:|---|
| `archive-caster-landscape.ogv` | 1920×1080 | 8.000 s | Theora | 39,223,400 | `94331bef149513a790fcfc2c8fc0440cbb413504d9185311672ef9c53a86653f` |
| `archive-caster-portrait.ogv` | 1080×1920 | 8.000 s | Theora | 19,959,147 | `2289a2737bb354949fa19cbfae9c0f4cdfdf997ec08eff3024a65007e0b6fbf4` |
| `lunaris-vessel-landscape.ogv` | 1920×1080 | 8.000 s | Theora | 16,638,104 | `906011683d0abb8446db648b74ec13b79aea3e9c6234e8cae8fd2a4b1ae1db99` |
| `lunaris-vessel-portrait.ogv` | 1080×1920 | 8.000 s | Theora | 23,555,321 | `32c6cab0847a8f9c1e5dbcde199ee57dbb301fba86135e505b482d7dade189f2` |
| `reliquary-duelist-landscape.ogv` | 1920×1080 | 8.000 s | Theora | 29,259,884 | `b843467f29774c8679751ab274b2aa0a7d7a75293a0a1f7c4eade6fcc57c97fc` |
| `reliquary-duelist-portrait.ogv` | 1080×1920 | 8.000 s | Theora | 27,129,072 | `2d2041a1be6c50b7e003ada11fa9da4a1f97114aa12d4f3d389abf54d80384cc` |

The aggregate is larger than the retired 720p pack by design. Web delivery still downloads only the active hero and orientation, verifies its exact byte count and SHA-256, caches it under `user://`, and never places these six objects inside the initial PCK.

## Runtime audio

| Mix | Duration | Format | Bytes | SHA-256 |
|---|---:|---|---:|---|
| `archive-caster-cinematic.ogg` | 8.000 s | Vorbis, 48 kHz stereo | 173,404 | `8b3949efce0bf20b227bd94e5e4aa60f2edcc7610f73cee9fa05d43e0691968e` |
| `lunaris-vessel-cinematic.ogg` | 8.000 s | Vorbis, 48 kHz stereo | 164,291 | `c754b96b801337784d2ea0e4d695770a2fb3168595645189848d19b2ca90f9a2` |
| `reliquary-duelist-cinematic.ogg` | 8.000 s | Vorbis, 48 kHz stereo | 157,754 | `308ef77956c3be5d6ace8d3f59b304dfeec5ac5f66e6aa3efa45f8751184fb51` |

Each mix is extracted from the corresponding landscape generated master, loudness-normalized to `-16 LUFS` with a `-1.5 dBTP` ceiling, resampled to 48 kHz stereo, and sample-bounded to exactly eight seconds. The generated video audio therefore ships as the audible cinematic experience without creating a second uncontrolled playback path.

## Runtime behavior

The result controller announces deterministic identity and rarity UI after the first complete eight-second cycle, while a healthy video continues looping beneath the result interface. Skip, reduced motion, download failure, decode failure, and watchdog fallback stop motion and expose the matching static endpoint plate. Gameplay authority, pull commitment, pity state, and result copy remain independent of presentation media.
