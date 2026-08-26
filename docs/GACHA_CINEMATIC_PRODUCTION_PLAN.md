# Premium Resonance Cinematic Production Plan

| Field | Value |
|---|---|
| **Status** | Centered looping media refresh implemented; final regression and deployment gate in progress |
| **Author** | Manus AI, Agents 7 and 10 |
| **Source candidate** | Synchronized from `7403c547069589e8c8b70eff26cfb0dad708d85a` |
| **Target runtime** | Godot `4.7.2.stable.official.ed1daf0bf` |
| **Scope** | Lunaris Vessel, Reliquary Duelist, and Archive Caster |

## Executive decision

Premium Resonance should replace its current approximately **1.12-second portrait-card transition** with **one bespoke eight-second cinematic per hero and per orientation**. The production target is therefore six masters: three 16:9 landscape films and three independently composed 9:16 portrait films. Each film uses the matching **full-size canonical character sheet**, never the chibi sheet, and resolves into an exact identity-locked final plate before Godot renders rarity, acquisition state, lives, pity, and guarantee copy.

The centered loop refresh supersedes the earlier frozen-settle treatment. Every replacement film now holds one complete hero on the visual centerline, removes the unintended radial filament/web overlay, and returns to its opening state after eight seconds. Godot reveals deterministic identity and rarity UI after the first complete cycle while the healthy cinematic continues looping beneath it; static plates remain only for reduced motion, Skip, failure, and watchdog fallback.

The recommended production stack is **GPT Image 2** for character identity anchors and first/last keyframes, followed by **Veo 3.1 at 1080p for eight seconds** using first-and-last-keyframe control. Visual clips are generated without embedded audio. Character sound effects follow the required video-carrier workflow, while short musical stings use **Lyria 3 Pro**. Final runtime video is transcoded to 24 fps Theora OGV, the format already proven by the current eight-second Lunaris title loop.

> **Creative thesis:** a pull should feel like the Reliquary has found, decoded, and materialized a dangerous adult hero—not like a modal has finished loading a portrait.

## Why the current reveal feels flat

The current implementation is correct, readable, deterministic, and accessible. It dims the screen, converges cyan filaments, charges four or five stars, raises a portrait, and settles result text. Its weakness is emotional rather than functional: the sequence has almost no time for uncertainty, escalation, character action, weapon authority, or a memorable final pose. The player sees a UI transition instead of witnessing a summoning ritual.

The new system should preserve every existing product and simulation contract. The pull must still commit before presentation begins; the committed receipt remains the only authority for identity, rarity, duplicate/revival state, lives, pity, and guarantee fulfillment. The cinematic layer adds desire and spectacle, never game logic.

## Canonical reference hierarchy

| Priority | Reference | Use |
|---:|---|---|
| 1 | [`lunaris_vessel_design_sheet.png`](lunaris-reliquary/lunaris_vessel_design_sheet.png) | Sole identity, anatomy, costume, and Crescent Reliquary authority for Lunaris Vessel |
| 1 | [`reliquary_duelist_design_sheet.png`](lunaris-reliquary/reliquary_duelist_design_sheet.png) | Sole identity, anatomy, costume, and Jade Meridian authority for Reliquary Duelist |
| 1 | [`archive_caster_design_sheet.png`](lunaris-reliquary/archive_caster_design_sheet.png) | Sole identity, anatomy, costume, and Archive Astrolabe authority for Archive Caster |
| 2 | [`LUNARIS_CHARACTER_DESIGNS.md`](LUNARIS_CHARACTER_DESIGNS.md) | Written identity and weapon contract |
| 3 | [`ART_DIRECTION.md`](ART_DIRECTION.md) | Mature adult presentation, premium anime realism, materials, sensuality, and rejection rules |
| 4 | [`lunaris-title-keyframe.png`](animations/lunaris-reliquary/lunaris-title-keyframe.png) | Environmental finish, cinematic lighting, architecture, and trio quality bar |
| 5 | [`Faction - Lunaris Reliquary.webp`](Faction%20-%20Lunaris%20Reliquary.webp) | Shared monumental stage language and ensemble hierarchy |
| 6 | [`PREMIUM_GACHA_PITY_AND_PACING.md`](PREMIUM_GACHA_PITY_AND_PACING.md) | Receipt authority, rarity, pity, Skip, reduced motion, and timing contract |

The three chibi sheets are **explicitly excluded** from image and video references. The full-size sheet remains the character authority for every generated anchor, keyframe, and master.

## Experience goals

| Goal | Required outcome |
|---|---|
| **Anticipation** | A clear build from signal acquisition through weapon awakening to final identity confirmation |
| **Character desire** | Mature beauty, glamour, confident sensuality, powerful physique, and luxury combat couture without explicit framing |
| **Recognition** | Face, hair, silhouette, costume construction, palette, and signature weapon remain stable from first frame to last |
| **Rarity differentiation** | Four-star feels premium; five-star feels categorically broader, warmer, heavier, and more architecturally consequential |
| **Readability** | One hero, one action arc, one signature weapon motion, one stable result plate |
| **Determinism** | Gameplay commits first; the film never chooses or infers the result |
| **Accessibility** | Skip is available immediately; reduced motion has the same final information; no rapid flashing or color-only meaning |
| **Platform fit** | Independently composed landscape and portrait masters; no careless center-crop of one orientation |
| **Web practicality** | Cinematics load as an optional verified content pack and cannot block or invalidate a pull |

## Production technology decision

| Stage | Selected capability | Reason |
|---|---|---|
| Cinematic identity anchors | **GPT Image 2** | Best match for the repository’s approved full-size sheets and required asset-generation policy |
| First and last keyframes | **GPT Image 2** | Precise character, costume, weapon, environment, composition, and negative-space control |
| Final video | **Veo 3.1**, 1080p, 8 seconds | First-and-last-keyframe control is more important here than lower cost; the ending must be an exact, UI-safe identity plate |
| Rapid internal motion exploration | Gemini Omni Flash Preview, 720p, optional | Useful only for disposable motion studies; not the final because it lacks last-keyframe control |
| Final music | **Lyria 3 Pro** | Three short, coherent character stings with a shared Lunaris motif |
| Character SFX | GPT Image 2 anchor → short audio-enabled carrier video → audio extraction | Required Mirelo-style SFX workflow; visuals from the carrier are not shipped |
| Runtime video | Theora OGV, 24 fps | Already proven in Godot desktop and Web by the current eight-second title loop |
| Runtime presentation | `VideoStreamPlayer` + static fallback + receipt-driven `AnimationPlayer` | Reuses established Godot media behavior while keeping result state deterministic |

Veo receives only the approved first and last keyframes because keyframe input supersedes a separate reference image. The full-size sheet therefore informs GPT Image 2’s identity anchor and both keyframes; the identity contract is already baked into the endpoints supplied to Veo.

## Deliverable matrix

| Asset class | Count | Master format | Runtime format |
|---|---:|---|---|
| Clean cinematic identity anchors | 3 | PNG, 3:4, full-size adult hero on white | Documentation/production only |
| Opening keyframes | 6 | PNG, 16:9 and 9:16 | Poster/fallback candidate |
| Final keyframes | 6 | PNG, 16:9 and 9:16 | Final fallback and UI settle plate |
| Character cinematic masters | 6 | MP4, 1080p, 8.000 s | OGV, 24 fps, landscape or portrait resolution |
| Character SFX carrier videos | 3 | MP4 with generated audio | Not shipped |
| Extracted character SFX beds | 3 | 48 kHz stereo WAV master | OGG or imported WAV |
| Character music stings | 3 | Lossless or high-quality master | OGG, 8.000 s |
| Shared Godot rarity cues | 3–5 | WAV/OGG | Signal lock, cyan star, gold fifth star, result settle, guarantee accent |
| Optional cinematic content pack | 1 | PCK + checksum manifest | Downloaded, verified, cached, and mounted on Web |

## Shared eight-second ritual

All characters use the same product grammar but not identical choreography.

| Phase | Purpose | Godot responsibility | Generated-film responsibility |
|---|---|---|---|
| **Signal Lock** | Establish anticipation and lock the transaction | Lock Back/Pull, show Skip, converge reticle, start playback/audio | Establish hero, environment, and dormant weapon |
| **Rarity Charge** | Declare four-star or five-star tier | Render exactly four cyan stars, or four cyan plus one gold fifth star | Keep film text-free; support tier through light and architecture |
| **Character Invocation** | Deliver the hero fantasy | Keep UI minimal | Execute one character-specific weapon action |
| **Resonance Arrest** | Resolve motion into authority | Prepare final frame and result panel | Settle to the approved last keyframe by 7.440 s |
| **Result Settle** | Explain what the pull changed | Render name, rarity, `NEW HERO` / `LIFE +1` / `REVIVED`, lives, pity, and guarantee | Hold a clean, stable plate with no generated text |

The final plate begins at **7.440 seconds**. Godot runs the hero/frame rise from 7.440–7.760 and result copy from 7.760–8.000, then holds until input. Skip at any time jumps idempotently to the same committed 8.000-second state.

## Cinematic 1 — Lunaris Vessel, five-star

### Creative thesis

**“Gravity acknowledges its sovereign.”** The Vessel does not attack. She awakens the Crescent Reliquary, guides one majestic vertical orbit, stops it with a finger close, and makes the colossal lunar architecture answer her. Her desirability comes from statuesque authority, direct mature eye contact, fitted ceremonial couture, and complete control of the room.

| Time | Beat | Character and weapon action | Camera and effects |
|---|---|---|---|
| `0.00–0.56` | Sovereign signal lock | Full-size Vessel stands beneath a dormant aperture, weight elegantly over one hip; her gaze rises to camera | Low wide full figure, very slow dolly; cyan filaments converge; four cyan stars and the fifth gold star are Godot overlays |
| `0.56–2.20` | Relic answers | She opens two fingers; the hip mechanism releases and unfolds into the canonical Crescent Reliquary | Move to knees-up with a restrained orbit; cyan core wakes and gold constellation marks ignite |
| `2.20–4.70` | Gravity crescent | One outward hand sweep guides one complete vertical ring orbit; small reliquary fragments and layered panels rise | Camera follows the weapon laterally while keeping face, hands, boots, and ring readable |
| `4.70–6.60` | Orbital crown | She closes her fingers; the ring brakes and locks behind her right shoulder, clearly separate from her body | The ring motivates a foreground wipe; camera rises to eye level; one controlled gold-white architectural pulse |
| `6.60–8.00` | Five-star command | She lowers her hand, squares her shoulders, lifts her chin slightly, and holds a restrained knowing smile | Stable medium-full slight-low hero angle by 7.440; ivory-gold halo and cyan core resolve for the UI plate |

**Landscape composition.** Keep her on the central axis with full body visible through the action. Reserve the lower 18% as dark reflective floor and leave quiet space to screen-left in the final plate. The expanded Reliquary uses the right third and retains an 8% edge margin.

**Portrait composition.** Keep the hero within the central 62%, with the lower 18% reserved for results. The ring unfolds upward and behind her right shoulder and performs a tighter near-body vertical orbit. The final crop is knees-up to medium-full, never cleavage-first and never cutting hands, hip mechanism, ring, or chin.

**Five-star escalation.** Four cyan star events occur at 0.180, 0.275, 0.370, and 0.465 seconds; the categorical escalation arrives at 0.560 with the fifth gold star, a warmer and heavier chime, one restrained gold-white five-point architectural burst, broader low-frequency weight, and the cathedral-scale response. `GUARANTEE FULFILLED` appears only when the committed receipt says `pity_forced`.

## Cinematic 2 — Reliquary Duelist, four-star

### Creative thesis

**“One cut; no wasted motion.”** The Duelist turns from a poised warning into one flawless Jade Meridian strike. The weapon opens a cyan meridian seam through the monumental mechanism; he settles into dangerous stillness. His appeal comes from powerful exposed arms, broad shoulders, fitted ceremonial tailoring, long black ponytail motion, and unbroken eye contact.

| Time | Beat | Character and weapon action | Camera and effects |
|---|---|---|---|
| `0.00–1.20` | Poised warning | Blade tip rests lightly on the reflective floor; he looks back over his shoulder toward camera | Low rear-left full figure; slow dolly; cold rim light separates black ponytail and teal tailoring |
| `1.20–2.70` | Measured turn | One planted pivot lifts the blade into compact low guard; hair, panels, and chains follow naturally | Restrained 25-degree clockwise orbit toward frontal three-quarter view |
| `2.70–4.55` | Meridian cut | One mechanically plausible one-handed rising diagonal cut; no spin, second strike, or teleport | Lateral camera preservation of the complete blade path; thin cyan/indigo seam stays behind silhouette |
| `4.55–6.20` | Reliquary answers | He arrests the blade; the seam travels outward and unlocks the segmented lunar ring | Camera stops and compresses slightly; exactly four cyan architectural nodes answer as one grouped event |
| `6.20–8.00` | Duelist authority | He lowers into a stable diagonal guard and gives a faint confident half-smile as hair and panels settle | Low frontal three-quarter finish; silver-indigo halo, jade-cyan blade channel, and antique-gold hardware remain crisp |

**Landscape composition.** Place him left-center with his face near the upper-left power point. The full Jade Meridian forms a strong diagonal toward lower center-right without crossing his face. Reserve the rightmost 30% and bottom 14% for quiet result space.

**Portrait composition.** Center him slightly left with the face in the upper third and the sword running steeply down the right side. Preserve full ponytail, shoulders, boots, guard, channel, and blade tip. Reserve the lower 22% for result UI.

**Four-star language.** Use cyan, indigo, silver, and antique gold. Exactly four steady nodes appear; there is no fifth light, no gold-white starburst, no guarantee flourish, and no exposure pump. Four-star should still feel luxurious—the difference is spatial authority and harmonic weight, not quality.

## Cinematic 3 — Archive Caster, four-star

### Creative thesis

**“A sealed memory is decoded and claimed.”** The Archive Caster expands her Astrolabe, draws four abstract memory streams into its core, closes her fingers, and seals the recovered radiance. Her appeal comes from mature knowing eye contact, silver-lilac curls, poised curves, black-plum couture, translucent geometry, and intellectually precise weapon control.

| Time | Beat | Character and weapon action | Camera and effects |
|---|---|---|---|
| `0.00–1.20` | Sealed archive | She stands on the reliquary dais with compact Astrolabe beside her open hand and turns her gaze to camera | Waist-low architectural wide push; cold moon rim on curls and sheer edging |
| `1.20–3.00` | Instrument unfolds | Two fingers rise; concentric rings expand on separate axes and chain weights drop under gravity | Medium-full 25-degree clockwise arc; thin cyan filaments wake each ring channel |
| `3.00–5.30` | Memory decoded | Four non-linguistic moon-cyan ribbons stream from the aperture into the core | Subtle push-in; cyan light rolls across face, gloves, gold harness, and translucent panels without obscuring them |
| `5.30–6.50` | Archive seals | Her fingers close; four ribbons collapse into the core, rings decelerate and lock | One crisp cyan-white pulse; silver-indigo afterglow, controlled gold edge light |
| `6.50–8.00` | Archivist revealed | She lowers her chin into direct knowing eye contact; Astrolabe hovers beside her shoulder and settles | Stable eye-level editorial hold by 7.440; four faint cyan orbital points remain |

**Landscape composition.** Stage her on the right 55% with the left 30% reserved for architectural scale and later result copy. Keep the expanded Astrolabe beside, not behind, her head. Reserve the bottom 15% and top-right Skip zone.

**Portrait composition.** Stack the composition vertically: aperture and convergence above, face and expanded Astrolabe through the middle, couture silhouette and reflective dais below. Keep a complete full figure early and push only to three-quarter figure by the settle. Never crop the bob, guiding hand, Astrolabe circumference, chain weights, controlled slit, or boots.

**Late charge variant.** To preserve her decode fantasy, the generated action stays clean until 6.880 seconds. Godot places Signal Lock at 6.880–7.060 and the four-star charge at 7.060–7.440, immediately before the shared hero/result settle. This preserves the common ritual grammar without forcing every hero into the same sentence.

## Sensuality direction

All three heroes are clearly adult, age 21 or older. The target is **luxury-editorial combat glamour**, not explicit sexual content.

| Hero | Positive direction |
|---|---|
| Lunaris Vessel | Statuesque curves, regal drapery, asymmetric exposed shoulder, elegant hip-weight shift, measured wrist motion, direct calm gaze |
| Reliquary Duelist | Broad shoulders, powerful bare arms, narrow fitted waist, over-shoulder eye contact, immaculate ponytail motion, restrained half-smile |
| Archive Caster | Mature knowing gaze, poised curvy silhouette, exposed shoulders, fitted bodice, controlled slit revealed naturally by motion |

## Identity and weapon locks

Every generated image and video candidate must preserve the following invariants.

| Category | Acceptance rule |
|---|---|
| Age and face | Clearly adult 21+; mature facial planes, aligned eyes, stable identity, no juvenile proportions |
| Anatomy | Stable body volume, plausible joints, complete hands, coherent contact or levitation |
| Hair | Exact color, length, construction, silhouette, and accessories from the matching full-size sheet |
| Costume | Exact topology, coverage, asymmetry, materials, palette, footwear, chains, and mechanisms |
| Weapon | Exact part inventory, geometry, palette, scale, and motion logic; never converted into a generic fantasy object |
| Environment | Monumental Lunaris architecture; circular devices remain architecture/equipment and never become angel wings |
| Cast | Exactly one hero; no doubles, companions, reflections that resemble people, mascots, or chibi forms |
| Media content | No generated text, rarity labels, logos, borders, subtitles, dialogue, or pseudo-lettering |

## Image and keyframe workflow

### Phase A — Cinematic identity anchors

Generate one clean, full-size cinematic identity anchor per hero with **GPT Image 2**. Each uses the matching full-size sheet as the primary reference, a 3:4 white studio background, one complete adult hero, and a clearly presented signature weapon. These are not redesigns; they are simplified model-facing identity locks with no text, labels, logos, or chibi reference.

### Phase B — Opening keyframes

Generate six opening keyframes with GPT Image 2: one 16:9 and one 9:16 per hero. Each prompt specifies exact face, hair, costume, weapon state, environment, lens, framing, UI-safe regions, and rejection rules. Use the matching cinematic identity anchor, full-size sheet, and Lunaris faction/title references.

### Phase C — Final keyframes

Generate six final plates with GPT Image 2 using the approved opening frame and cinematic identity anchor as references. The final plate must show the exact settled pose, weapon geometry, tier lighting, and negative space described above. It must be capable of replacing the video at 7.440 seconds without a visible identity or exposure jump.

### Phase D — Keyframe approval gate

Do not generate final video until all twelve opening/final keyframes pass a human review for identity, age, anatomy, costume, weapon, environment, landscape/portrait safe areas, and non-explicit framing. Rejected keyframes are regenerated before video work; attempting to “fix it in motion” is how expensive nonsense is born.

## Video generation workflow

Each orientation is one continuous eight-second Veo 3.1 generation with its approved first and last keyframes. A single clip avoids inter-clip identity drift and removes the need for cross-clip camera or costume continuity. If a future treatment must be split, the last frame of clip N becomes the first frame of clip N+1.

The Veo prompt must include the premium painterly-anime style, clearly adult identity, exact costume and weapon locks, monumental environment, one action arc, physical camera path, controlled effects, final static timing, and exhaustive negative instructions. Generate with `generate_audio=false`; audio is produced separately so Skip, reduced motion, volume settings, and rarity logic remain controllable.

The final master passes technical integrity with `ffprobe`. Visual acceptance is performed through human playback and the actual Godot presentation; do not use automated generated-video analysis as an artistic judge.

## Audio production

### Character music

Generate three eight-second **Lyria 3 Pro** instrumental stings at 120 BPM in a shared D-minor Lunaris motif. The shared palette is glass harmonics, bowed metal, low synth pulse, restrained orchestral strings, harp/plucked mechanism accents, and a wide stone-reliquary reverb. No vocals.

| Hero | Musical identity | Climax |
|---|---|---|
| Lunaris Vessel | Regal, suspended, warm gold over cyan; broadest spectral and spatial scale | Gold-white harmonic arrival and controlled low-end impact at the orbital arrest |
| Reliquary Duelist | Taut, percussive, dark teal/indigo; pulse follows one measured draw and cut | One precise transient and silver-cyan resolve, no five-star breadth |
| Archive Caster | Glassy, intelligent, circular polyrhythmic mechanism; sparse and elegant | Four-note cyan resolution around the seal, with delicate gold decay |

### Character SFX

For each hero, create an audio-enabled carrier video from a GPT Image 2 anchor following the exact cinematic timing. Request only mechanisms, cloth, weapon motion, architectural resonance, air, and impacts—no dialogue, narration, vocals, or music. Extract the carrier audio to 48 kHz stereo WAV, trim or pad sample-accurately to 8.000 seconds, and split it into short catalog cues where Skip behavior requires independently stoppable transients.

| Hero | Signature sound events |
|---|---|
| Lunaris Vessel | Sub signal lock, five-star chimes, gold ring release, silk/metal orbit, magnetic arrest, cathedral lunar bloom |
| Reliquary Duelist | Chain tick, blade tip lift, leather/bracer articulation, one heavy spellblade whoosh, meridian unlock, four-node harmonic answer |
| Archive Caster | Gold ring servos, chain-weight ticks, four spatial memory passes, finger-seal accent, compact lunar pulse, orbital settle |

### Deterministic UI cues

Generic rarity cues remain independent Godot-triggered assets: signal lock, cyan star, gold fifth star, result settle, and guarantee fulfilled. They are scheduled from the committed receipt and remain correct even when the player skips the film.

## Runtime architecture

### Proposed components

| Component | Responsibility |
|---|---|
| `GachaCinematicProfile` resource | Per-hero landscape/portrait streams, posters, final plates, music/SFX IDs, charge placement, and safe-area metadata |
| `GachaCinematicPlayer` control | Chooses orientation, displays poster until video decodes, synchronizes film and audio, freezes to the final plate, and exposes completion/failure state |
| `GachaRevealController` | Owns receipt-driven state, fixed timeline, Skip, reduced motion, final result application, and focus restoration |
| `GachaCinematicPack` loader | Downloads, validates, caches, mounts, and reports readiness for the optional Web PCK |
| Existing `gacha.gd` | Continues to commit the pull, populate receipt-derived copy, and route the immutable result into the reveal controller |

### State machine

| State | Entry | Exit |
|---|---|---|
| `IDLE` | Gacha screen ready | Confirmed pull accepted |
| `PREPARE` | Snapshot committed receipt, choose profile/orientation, lock navigation | Media ready or fallback selected |
| `PLAYING` | Start poster/video, music, SFX, and AnimationPlayer at time zero | Clock reaches 7.440, Skip, error, or scene exit |
| `SETTLING` | Swap/freeze exact final plate and animate deterministic UI | Clock reaches 8.000 or Skip |
| `HOLDING_RESULT` | Final copy readable; gameplay already committed | Pull/Back input after unlock |
| `CANCELLED` | Scene exit | Cleanup complete |

The video’s `finished` signal is a health observation, not the state authority. The controller uses one monotonic clock and explicit event times. Skip kills active tweens and playback, stops the cinematic music cue, applies the same final plate and receipt copy, and cannot mutate campaign state.

### Reduced motion

Reduced-motion mode does not play the full character action. It presents the final approved plate through a brief opacity transition, renders the correct four/five-star ornament without rotation or overshoot, and settles the same receipt-derived result. The visual hierarchy and information remain identical.

### Failure fallback

If the cinematic pack is missing, invalid, late, or undecodable, the accepted pull still succeeds. The player immediately uses the approved final still and an enhanced version of the existing 1.12-second reticle/star/portrait reveal. The fallback has the same Skip, final copy, focus restoration, and reduced-motion behavior. Media availability must never gate the command.

## Web and payload strategy

The existing eight-second 1920×1080 title loop is a 24 fps Theora OGV of approximately 36 MB, demonstrating runtime compatibility but also warning against placing six similar files in the initial PCK. The base Web export is already roughly 159 MB in the current sandbox candidate.

The recommended Web design keeps opening/final poster images and fallback cues in the base PCK while placing the six OGV films and cinematic music/SFX in **one optional verified PCK**. Opening Premium Resonance starts a background prefetch using the same SHA-256, byte-count, cache, timeout, and non-blocking failure principles used by optional music packs. A pull may proceed before the pack is ready; it uses the fallback if necessary.

Target a combined cinematic pack of **80 MB or less**. Start encoding at 24 fps and native runtime dimensions of 1280×720 and 720×1280. If the pack exceeds budget, reduce Theora quality before reducing resolution; never auto-crop the landscape master into portrait. Record exact sizes and SHA-256 hashes in the asset manifest.

Proposed Web argument:

```text
--gacha-cinematic-pack=URL|SHA256|BYTES
```

## Proposed repository layout

```text
assets/cinematics/gacha/
  posters/
    lunaris_vessel_landscape.png
    lunaris_vessel_portrait.png
    reliquary_duelist_landscape.png
    reliquary_duelist_portrait.png
    archive_caster_landscape.png
    archive_caster_portrait.png
  video/
    lunaris_vessel_landscape.ogv
    lunaris_vessel_portrait.ogv
    reliquary_duelist_landscape.ogv
    reliquary_duelist_portrait.ogv
    archive_caster_landscape.ogv
    archive_caster_portrait.ogv
  music/
    lunaris_vessel_sting.ogg
    reliquary_duelist_sting.ogg
    archive_caster_sting.ogg
  sfx/
    lunaris_vessel_cinematic.ogg
    reliquary_duelist_cinematic.ogg
    archive_caster_cinematic.ogg
  profiles/
    lunaris_vessel.tres
    reliquary_duelist.tres
    archive_caster.tres
  manifest.json

docs/gacha-cinematics/
  anchors/
  keyframes/
  masters/
  prompts/
  validation/

tools/build_gacha_cinematic_pack.gd
scripts/ui/components/gacha_cinematic_player.gd
scripts/ui/components/gacha_reveal_controller.gd
```

Large generation masters and carrier videos should remain in project files or external production storage rather than the Git source repository. The repository should contain approved runtime assets, manifests, checksums, prompts, and validation records.

## Acceptance gates

### Creative and identity

| Gate | Pass condition |
|---|---|
| Adult identity | All heroes unambiguously read as 21+ in face, anatomy, posture, and context |
| Face/hair | Stable canonical face and hairstyle throughout |
| Costume | No missing, invented, or mutated construction; canonical coverage preserved |
| Weapon | Complete canonical weapon with coherent geometry and one readable motion cycle |
| Sensuality | Beautiful, glamorous, confident, non-explicit, and never juvenile or voyeuristic |
| Environment | Monumental Lunaris architecture with controlled gold/cyan mechanisms |
| Text | No generated text, logos, badges, pseudo-lettering, or dialogue |

### Technical media

| Gate | Pass condition |
|---|---|
| Duration | Exactly 8.000 seconds or frame-equivalent at 24 fps |
| Loop seam | Final motion returns to the approved opening state at 8.000 s without a frozen hold or visible camera jump |
| Orientation | Dedicated 16:9 and 9:16 compositions pass without unsafe crop |
| Encoding | Valid Theora OGV; audio is separate; correct dimensions and 24 fps |
| Playback | Native and Web decode without stalls, blank frames, or fatal logs |
| Payload | Cinematic pack meets agreed byte budget and checksum manifest |

### Gameplay and accessibility

| Gate | Pass condition |
|---|---|
| Authority | Pull commits exactly once before reveal; cinematic never chooses state |
| Skip | Available from time zero and idempotently reaches the final committed state |
| Input lock | Pull and Back remain locked until final state; focus returns correctly |
| Result copy | Correct new/duplicate/revival, lives, pity, and forced-guarantee treatment |
| Reduced motion | Same final information without rotation, overshoot, or full action playback |
| Flash safety | No more than three major luminance changes per second; no uncontrolled whiteout |
| Color independence | Rarity and result remain understandable without color |

## Test plan

Add focused tests for profile lookup, orientation choice, pack-missing fallback, poster-to-video transition, final-plate swap, receipt-only overlay state, Skip at multiple timestamps, scene exit cleanup, reduced motion, four-star/five-star distinction, forced-pity copy, and focus restoration. Existing premium lifecycle, pity/economy, gacha UI, migration, and replay tests remain mandatory.

For each implementation phase, run direct import, bounded headless boot, focused tests, and log error scans. Final candidates additionally require Xvfb visual checks at 1280×720 and 720×1280 with representative Pull, Skip, natural four-star, natural five-star, forced five-star, duplicate, and revival flows. Export through the repository’s Web preset, build optional packs, serve over HTTP, and inspect browser console, network status, MIME types, pack download, checksum validation, video decode, and fallback behavior.

## Phased implementation and push gates

| Phase | Work | Completion gate before pushing `master` |
|---:|---|---|
| 1 | Approve this creative direction; generate three cinematic identity anchors | Full-size-only reference audit, identity review, hashes, and documentation checks |
| 2 | Generate and approve six opening plus six final keyframes; build a keyframe animatic | Landscape/portrait safe-area review, exact weapon/costume review, no generated text, import sanity |
| 3 | Generate six Veo 3.1 masters; create three Lyria stings and carrier-derived SFX | File integrity, human playback approval, OGV transcode, duration/fps/dimension verification, Godot decode harness |
| 4 | Implement profiles, player, reveal controller, fallback, Skip, reduced motion, and tests | Focused regressions, direct import, bounded boot, log scan, native Xvfb interaction and visual approval |
| 5 | Build optional cinematic pack and integrate WebDev delivery | Final upstream fetch, full regressions, Web export, HTTP/network/runtime verification, desktop/portrait preview, checkpoint, publish |

After each phase, synchronize with upstream, run that phase’s regression gate, commit, and push directly to `master` without rewriting shared history.

## Production risk register

| Risk | Mitigation |
|---|---|
| Face or age drift | Full-size sheet → GPT Image 2 identity anchor → approved first/last frames; reject rather than patch identity drift |
| Weapon mutation | Explicit part inventories, mechanically constrained motion, last-keyframe lock, one action per film |
| Circular devices become wings | Maintain clear depth and mechanical separation from the body; reject tangencies |
| Four-star and five-star feel similar | Different node count, palette, sound weight, architectural scale, fifth-star event, and forced-guarantee UI |
| Portrait becomes a sexualizing crop | Generate a dedicated 9:16 composition with full-body/three-quarter safe areas and explicit rejection rules |
| Generated UI contradicts receipt | Keep every word, star, badge, and result state in Godot |
| Video unavailable after committed pull | Static final-plate fallback; media cannot gate gameplay |
| Web payload balloons | Optional verified PCK, prefetch on gacha entry, byte budget, poster-first fallback |
| Skip leaks audio or stale state | One reveal controller, cancellable music, short SFX cues, idempotent final-state application |
| Concurrent `master` changes | Fetch/pull before each phase and again before final validation; rerun affected gates after integration |

## Approval requested before generation

This proposal assumes the following production decisions:

1. **Eight seconds per hero reveal.**
2. **Six final masters:** separate 16:9 and 9:16 films for each hero.
3. **No spoken dialogue** in version one; identity and result copy remain localized Godot UI.
4. **GPT Image 2** for all generated anchors and keyframes.
5. **Veo 3.1 at 1080p** with first-and-last-keyframe control for final video.
6. **Three Lyria 3 Pro musical stings** plus character-specific carrier-derived SFX.
7. **Optional Web cinematic pack** with a deterministic static fallback.
8. **Full-size design sheets only; chibi references are prohibited.**

Once these choices are approved, Phase 1 begins with the three cinematic identity anchors. No generation should begin before that approval gate.
