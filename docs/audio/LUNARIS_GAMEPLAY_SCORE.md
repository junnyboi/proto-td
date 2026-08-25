# Lunaris Gameplay Score and UI Audio

**Status:** Implemented launch soundtrack

**Protected asset:** *Astra Memoriam* remains the unchanged loading/title cue.

## Production decision

The launch soundtrack now follows the faction-led contract in [`FACTION_MUSIC_REDESIGN_PROPOSAL.md`](../FACTION_MUSIC_REDESIGN_PROPOSAL.md). Company Command and related campaign surfaces use a restrained Sacred Archive staging loop. Stages S1–S7 route to three authored adaptive battle families, and S8 routes to a dedicated Gatecrasher boss suite. Victory and defeat use compact Lunaris resolutions rather than reusing combat or title material.

All music masters were generated as original instrumental material with the Manus Lyria 3 Pro production path. The prompts and structural timing are recorded in the proposal. Runtime derivatives were mastered from true 48 kHz, 24-bit PCM masters to stereo Ogg Vorbis, gain-staged beneath tactical SFX, and loop-closed with bar-length head/tail crossfades. The exact generated sources, lossless masters, anchors, carrier videos, and raw outputs are preserved in the Manus project archive `audio-production-2026-08-25`; checksums are recorded in [`LUNARIS_GAMEPLAY_SCORE.sha256`](./LUNARIS_GAMEPLAY_SCORE.sha256).

## Runtime cue map

| Surface | Cue family | Routing |
|---|---|---|
| Loading and title | `title_lunaris` | Existing *Astra Memoriam* asset; persistent global music toggle |
| Company Command, mission, squad, training, gacha, Vahalla | `lunaris_staging_archive_command` | One uninterrupted staging-family loop |
| S1–S3 | `lunaris_battle_orbit_early_{low,medium,high}` | Horizontal adaptive states at 120 BPM |
| S4 | `lunaris_battle_air_raid_{low,medium,high}` | Horizontal aerial-pressure states at 126 BPM |
| S5–S7 | `lunaris_battle_gravity_lattice_{low,medium,high}` | Horizontal combined-arms states at 124 BPM |
| S8 | `lunaris_boss_gatecrasher` | Dedicated 80 BPM half-time boss loop |
| Clear | `lunaris_result_victory` | Non-looping eight-second result resolution |
| Defeat | `lunaris_result_defeat` | Non-looping eight-second result reduction |

## Adaptive behavior

`MusicProfile` declares faction cue routing and transition timing. Each `StageDef` references a `music_profile_id` and `music_variant_id`; no file path or generic act number appears in stage data. `MusicDirector` reads presentation-safe facts from the already authoritative `BattleModel` and requests low, medium, high, or boss states. Escalation requires stable pressure, de-escalation is deliberately slower, and an eight-second minimum hold prevents musical chatter.

Routine state changes quantize to a four-bar boundary. Danger changes quantize to the next bar. Scheduling follows the audio playback clock rather than wall time, so pauses, suspended tabs, and device stalls cannot advance a transition off-grid. The `Music` autoload owns two players and performs bounded crossfades; missing profiles, cues, or streams reject without changing routing metadata, battle state, or navigation. Result routing interrupts the adaptive queue with the appropriate non-looping stinger. The global persisted music setting now governs title, staging, battle, boss, result, and premium-cinematic music.

The synchronized title Settings surface provides persisted Master, Music, and SFX volume sliders. Both adaptive players route through the `Music` bus, all pooled interaction voices route through `SFX`, and browser/native sessions restore the same levels. Existing premium-reveal cinematic cues remain in the mixed catalog; finishing or skipping a reveal returns to the Company Command loop instead of leaving the gacha surface silent.

Final runtime measurements are 48 kHz stereo with staging at −20.0 LUFS, battle low/medium/high states calibrated to approximately −19.5/−18.0/−16.5 LUFS, the boss suite at −17.5 LUFS, and both result stingers at approximately −18 LUFS. Music true peaks remain at or below −2.6 dBFS. Mono fold-down checks preserve the principal motifs and transient identity.

## UI sound direction

The complementary UI suite uses a **moon-glass and brushed-gold mechanism** vocabulary. Each sound was produced through the required carrier workflow: a GPT Image 2 visual anchor, a short audio-capable carrier video, extraction, 48 kHz normalization, and a controlled tail. Every delivered SFX is between one and three seconds.

| Cue | Interaction | Sound brief |
|---|---|---|
| `ui_click` | Ordinary button activation | Close-miked glass tick, tiny gold latch, short orbital shimmer |
| `ui_back` | Back navigation | Descending glass gesture, soft gravity retreat, muted release |
| `ui_confirm` | Mission launch and decisive acceptance | Gold-cyan convergence, three aligned orbit points, compact gravity seal |
| `menu_open` | Modal or scene deck opening | Layered glass planes unfolding with clockwork alignment |
| `menu_close` | Modal or scene deck dismissal | Descending retraction and one clean archive latch |

The catalog retains aliases for `ui_select`, `ui_accept`, and `menu_transition`. Existing combat SFX remain intact. New routing covers title settings, scene changes, stage launch, squad confirmation, battle pause/resume, resign dialogs, result continuation, and all existing ordinary button-click call sites.

## Reproduction

Run the checked-in mastering script from the repository root:

```bash
PRODUCTION_ROOT=/home/ubuntu/projects/proto-td-1515240c/audio-production-2026-08-25 \
  tools/audio/process_lunaris_score.sh
```

The script regenerates all runtime Ogg and WAV derivatives from the durable project archive. It requires `ffmpeg`, `ffprobe`, and `bc`. Godot 4.7.2 then generates the corresponding import metadata during direct import.

## Acceptance contract

The candidate is accepted only when *Astra Memoriam* remains bit-identical, the persistent toggle controls every music surface, title transitions cleanly into Company Command, adaptive requests cannot thrash or mutate simulation state, missing audio falls back safely, every new SFX resolves through the catalog, direct import and all tests pass without leak diagnostics, and the Web export loads all audio without MIME, CORS, decoding, or console errors.
