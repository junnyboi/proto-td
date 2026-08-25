# Lunaris Vessel Animation Production Record

## Implemented scope

The Lunaris Vessel now has a unique production chibi presentation for the stationary tower renderer. The complete supported animation set is **idle and attack only** in four isometric directions. `NE` and `SE` are generated masters; `NW` and `SW` are deterministic horizontal mirrors. No walk, run, deploy, skill, hit, death, or victory animation is generated or registered because the current renderer has no consumer for those states.

The presentation mapping is intentionally separate from combat authority. The persistent premium portrait ID `portrait_lunaris_vessel` selects the `lunaris_vessel` visual template, while the deterministic battle operator remains `caster_2` and all premium save, life, class, pity, hash, and combat behavior remains unchanged.

## Source references and generation

| Role | Tool/model | SHA-256 |
|---|---|---|
| Canonical full-size sheet | Repository source | `b86d367a83c20c2796d3cca49d5e6234f3ab53b6dc106c78789ad824176b90b4` |
| Canonical chibi sheet | Repository source | `337a7b6d70b0250124885768d151ff43585253900a93c626cb120c7b1ae9bf22` |
| NE neutral keyframe | GPT Image 2 | `d08ff335f20fb0095b6b90a5acbd451680ec3a7dfe4c572525a4859683e84220` |
| SE neutral keyframe | GPT Image 2 | `2172403369108ee2ad4e24d791e3ecd5cd46d094ccc4e70816ccd97a2c1f96d2` |
| NE idle carrier | Veo 3.1, locked first/last frame | `c65ead7bb49508fbe00028fb9531480655c9df07dd2869cb3ed9feb3fed875e3` |
| SE idle carrier | Veo 3.1, locked first/last frame | `9dafa78fa67ca4ea6bcadccdd16f045f7ded7daa5aae3adccaac2600679ff9b0` |
| NE attack carrier | Gemini Omni Flash Preview | `c4409b8828cea7567ef8cac603cb9990c71aec09c69cb24afb2d6daf628bbc71` |
| SE attack carrier | Gemini Omni Flash Preview | `a3fd9e1aebe7f34bd771c4e101f3ef67e39ed4e824b9a10888cf8540def2eb19` |

Every carrier uses a locked 16:9 camera, fixed perspective, planted bottom-center root, constant character scale, and a uniform neon-green chroma stage. The corrected idle prompt explicitly prohibits charge, flare, pulse, beam, projectile, discharge, aura expansion, weapon recoil, and outward emission. Attack prompts authorize one concise Crescent Reliquary charge, discharge, follow-through, and recovery while keeping the character stationary.

## Processing contract

The global `/video-to-sprites` skill samples each four-second carrier into a 48-frame transparent 480p-bounded master. It measures the encoded carrier chroma rather than assuming the requested RGB value, performs channel-dominance alpha recovery, decontaminates fringes, and emits mirrored masters with explicit provenance.

The Godot runtime derivative uses lossless WebP horizontal strips with 192×192 cells, a normalized pivot of `(0.5, 0.94)`, and 12 FPS playback. Idle selects the even source indices from the 48-frame master, producing 24 looping frames. Attack resamples the complete source window `[0, 24)` into 13 non-looping frames with both endpoints preserved. Runtime scale and ground alignment come from the neutral anchor frame, not effect-union bounds, so the Vessel remains the same size while only off-cell discharge pixels are clipped.

## Runtime artifacts

| Logical asset | Frames | Loop | SHA-256 |
|---|---:|---:|---|
| `op_anim_lunaris_vessel_idle_ne` | 24 | Yes | `677ae98354b869a1a6ecfd497b2435e6bcd54bbcf143856de8ac25ea8f911d8f` |
| `op_anim_lunaris_vessel_idle_nw` | 24 | Yes | `95d4211844d3d39f048802461d2513f25267e76769e0b9f2083c7483f6998b4f` |
| `op_anim_lunaris_vessel_idle_se` | 24 | Yes | `79862a76f2d3403b0eb0cc3b5e10d220aa159cd59670a12c0b429e9d726a0c06` |
| `op_anim_lunaris_vessel_idle_sw` | 24 | Yes | `dc8626e2eb67436d6a8e75e7412587fb1b11d8b8603b8413595746b857ee85f8` |
| `op_anim_lunaris_vessel_attack_ne` | 13 | No | `7123b875956af94bc66911021cb7d9e07a93282d9b7191983e4885cc0d29574d` |
| `op_anim_lunaris_vessel_attack_nw` | 13 | No | `d86308ca61d1a107fe7cfb86a40ae5f1d2e74246b6d24e81deb39d04ab457e21` |
| `op_anim_lunaris_vessel_attack_se` | 13 | No | `b4536b5ca8dbad27b990aad06b9f52b52448229d44f1fb941ab95a4203004bf4` |
| `op_anim_lunaris_vessel_attack_sw` | 13 | No | `4a64f6bd93d8c983b173b4da6013f53f81b4896e3d2eb14ad01119dcaa6b3b9e` |

## Validation contract

The production validator requires exact strip dimensions, transparent RGBA data, frame counts, FPS, loop flags, pivot, bounded visible pixels, stable neutral-anchor character height, complete attack endpoint recovery, and pixel-exact west mirrors. The Godot-focused regression additionally proves premium portrait routing, catalog validity, manifest rows, WebP texture loading, first/last frame access, four-direction mapping, non-placeholder status, and the absence of unsupported action regions.
