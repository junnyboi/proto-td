# Lunaris Gameplay Score and UI Audio

**Status:** Implemented launch soundtrack

**Protected asset:** *Astra Memoriam* remains unchanged pending the scheduled listening review. This document does not authorize replacement of runtime audio.

## Production decision

This is a technical production record, not an independent narrative authority. The sole story authority is [`NARRATIVE_CANON.md`](../NARRATIVE_CANON.md). Runtime files, cue IDs, routing, checksums, and mixes remain unchanged unless a later listening review separately approves replacements in place.

The launch soundtrack follows the faction-led contract in [`FACTION_MUSIC_REDESIGN_PROPOSAL.md`](../FACTION_MUSIC_REDESIGN_PROPOSAL.md). Company Command and related campaign surfaces use a restrained Lunaris rescue-planning loop. Act I stages S1–S7 retain three authored adaptive battle families, and S8 retains its dedicated Gatecrasher boss suite. In response to the approved Act II score request, S9–S16 now each own a unique operation-length loop documented in [`ACT_II_SCORE.md`](./ACT_II_SCORE.md). Victory and defeat retain their compact Lunaris resolutions rather than reusing combat or title material.

All music masters were generated as original instrumental material with the Manus Lyria 3 Pro production path. The prompts and structural timing are recorded in the proposal. Runtime derivatives were mastered from true 48 kHz, 24-bit PCM masters to stereo Ogg Vorbis, gain-staged beneath tactical SFX, and loop-closed with bar-length head/tail crossfades. The exact generated sources, lossless masters, anchors, carrier videos, and raw outputs are preserved in the Manus project archive `audio-production-2026-08-25`; checksums are recorded in [`LUNARIS_GAMEPLAY_SCORE.sha256`](./LUNARIS_GAMEPLAY_SCORE.sha256).

## Runtime cue map

| Surface | Cue family | Routing |
|---|---|---|
| Loading and title | `title_lunaris` | Existing *Astra Memoriam* asset; persistent global music toggle |
| Company Command, mission, squad, training, gacha, Valhalla | `lunaris_staging_archive_command` | One uninterrupted staging-family loop |
| S1–S3 | `lunaris_battle_orbit_early_{low,medium,high}` | Horizontal adaptive states at 120 BPM |
| S4 | `lunaris_battle_air_raid_{low,medium,high}` | Horizontal aerial-pressure states at 126 BPM |
| S5–S7 | `lunaris_battle_gravity_lattice_{low,medium,high}` | Horizontal combined-arms states at 124 BPM |
| S8 | `lunaris_boss_gatecrasher` | Dedicated 80 BPM half-time boss loop |
| S9–S16 | `lunaris_act2_s09_*` through `lunaris_act2_s16_*` | Eight stage-unique cues at 84–132 BPM |
| Clear | `lunaris_result_victory` | Non-looping eight-second result resolution |
| Defeat | `lunaris_result_defeat` | Non-looping eight-second result reduction |

## Adaptive behavior

`MusicProfile` declares faction cue routing and transition timing. Each `StageDef` references a `music_profile_id` and `music_variant_id`; no file path or generic act number appears in stage data. `MusicDirector` reads presentation-safe facts from the already authoritative `BattleModel` and requests low, medium, high, critical, or boss states. Escalation requires stable pressure, de-escalation is deliberately slower, and an eight-second minimum hold prevents musical chatter.

Routine Act I state changes quantize to a four-bar boundary. Danger changes quantize to the next bar. When base health falls **below 30%**, a 150 ms anti-flap window bypasses the routine hold, reuses the authored high-intensity arrangement, and raises playback tempo by 8%; recovery returns to the ordinary state ladder through normal de-escalation hysteresis. Act II state metadata remains cue-continuous at authored tempo because each operation has one dedicated composition; state changes never seek or restart that stream. Scheduling follows the audio playback clock rather than wall time, so pauses, suspended tabs, and device stalls cannot advance a transition off-grid. The `Music` autoload owns two players and performs bounded crossfades; missing profiles, cues, or streams reject without changing routing metadata, battle state, or navigation. Result routing interrupts the adaptive queue with the appropriate non-looping stinger. The global persisted music setting now governs title, staging, battle, boss, result, and premium-cinematic music.

The synchronized title Settings surface provides persisted Master, Music, and SFX volume sliders. Both adaptive players route through the `Music` bus, all pooled interaction voices route through `SFX`, and browser/native sessions restore the same levels. Existing premium-reveal cinematic cues remain in the mixed catalog; finishing or skipping a reveal returns to the Company Command loop instead of leaving the gacha surface silent.

Final runtime measurements are 48 kHz stereo with staging at −20.0 LUFS, Act I battle low/medium/high states calibrated to approximately −19.5/−18.0/−16.5 LUFS, the Act I boss suite at −17.5 LUFS, Act II stage cues between −20.4 and −18.0 LUFS, and both result stingers at approximately −18 LUFS. Act II true peaks remain at or below −2.1 dBFS after Vorbis encoding. Mono fold-down checks preserve the principal motifs and transient identity.

## Anima War listening direction

The retained cue map should be reviewed against the Anima War rather than caretaker-era intent. Lunaris material should frame Company Manus as a rescue force protecting **anima—the real and unique human soul**. A single free or rescued soul is represented by an exposed, warm human breath, solo string, or pale-blue glass tone; processed anima is represented by strained violet-magenta spectral pressure, compressed wordless voices, and bundled pulses. PROTOS should read as corrupted, calm, and imperial through processed digital fragments, rigid many-to-one routing, low mechanical scale, and the pressure of farms, refineries, and foundries. The music must never imply that PROTOS is benevolent, that souls are safe copies, or that human farms are peaceful gardens.

The completed [`ANIMA_WAR_LISTENING_REVIEW.md`](./ANIMA_WAR_LISTENING_REVIEW.md) accepts the checked-in score for the current release. These directions remain review criteria rather than automatic replacement instructions. Any approved future replacement must preserve the stable cue IDs above, BPM and bar grids, transition anchors, routing, loudness hierarchy, loop behavior, mobile and mono compatibility, and safe silence fallback.

## UI sound direction

The complementary UI suite uses a **moon-glass and brushed-gold mechanism** vocabulary. Each sound was produced through the required carrier workflow: a GPT Image 2 visual anchor, a short audio-capable carrier video, extraction, 48 kHz normalization, and a controlled tail. Every delivered SFX is between one and three seconds.

| Cue | Interaction | Sound brief |
|---|---|---|
| `ui_hover` | Pointer enters any eligible interactive control | Quiet glass-filament shimmer and airy focus tick, globally debounced and suppressed for hidden or disabled controls |
| `ui_click` | Ordinary button activation | Close-miked glass tick, tiny gold latch, short orbital shimmer |
| `ui_back` | Back navigation | Descending glass gesture, soft gravity retreat, muted release |
| `ui_confirm` | Mission launch and decisive acceptance | Gold-cyan convergence, three aligned orbit points, compact gravity seal |
| `menu_open` | Modal or scene deck opening | Layered glass planes unfolding with clockwork alignment |
| `menu_close` | Modal or scene deck dismissal | Descending retraction and one clean reliquary latch |
| `slow_field_cast` | Accepted Slow Field cast | Cold polar howl blooms outward with ice-grain hiss and a restrained frost activation accent |
| `slow_field_expire` | Active field reaches its exclusive end tick | Blizzard pressure pulls inward, snow hiss recedes, and a faint brittle frost crack dissolves |

The catalog retains aliases for `ui_select`, `ui_accept`, and `menu_transition`; the semantic `slow_field` cast ID resolves to `slow_field_cast`. `BattleView` reads accepted casts from the existing SpellBook ledger and detects expiration from disappearance of a previously observed authoritative field ID, so audio remains presentation-only and cannot mutate simulation state or hashing. The `Sfx` autoload automatically binds hover audio to eligible buttons, sliders, selectors, text inputs, tabs, lists, and custom focusable controls as they enter the scene tree. A short readiness delay prevents newly opened menus from sounding under a stationary pointer, and a global debounce prevents dense control grids from producing chatter.

## Reproduction

Run the checked-in mastering script from the repository root:

```bash
PRODUCTION_ROOT=/home/ubuntu/projects/proto-td-1515240c/audio-production-2026-08-25 \
  tools/audio/process_lunaris_score.sh
```

The script regenerates all runtime Ogg and WAV derivatives from the durable project archive. It requires `ffmpeg`, `ffprobe`, and `bc`. Godot 4.7.2 then generates the corresponding import metadata during direct import.

Regenerate the Act II operation cues from their retained 24-bit PCM masters with:

```bash
PRODUCTION_ROOT=/home/ubuntu/webdev-static-assets/proto-td-act2 \
  tools/audio/process_act2_score.sh
```

Slow Field blizzard cues use their own GPT Image 2 carrier anchors and audio-capable videos. Rebuild their 48 kHz stereo WAV derivatives with:

```bash
PRODUCTION_ROOT=/home/ubuntu/projects/proto-td-9a1e4085/audio-production-slow-field-blizzard \
  tools/audio/process_slow_field_sfx.sh
```

The cast derivative is 2.900 seconds at −18.0 LUFS; expiration is 2.950 seconds at −21.0 LUFS. Their production anchors, carriers, raw audio, hashes, and complete brief are preserved in the project archive `audio-production-slow-field-blizzard`.

## Acceptance contract

The candidate is accepted only when *Astra Memoriam* remains bit-identical, the persistent toggle controls every music surface, title transitions cleanly into Company Command, adaptive requests cannot thrash or mutate simulation state, missing audio falls back safely, every new SFX resolves through the catalog, direct import and all tests pass without leak diagnostics, and the Web export loads all audio without MIME, CORS, decoding, or console errors. Listening review must also confirm stolen-soul pressure, corrupted PROTOS presence, imperial scale, and clear separation between singular free souls and processed anima, without masking alerts or depending on stereo width alone.
