# Protos — Luminous Descent Music Catalog

This directory contains six original instrumental orchestral cues: one exploration BGM and one boss cue for each planned act. They share a new four-note descending leitmotif and progress from peaceful pastoral warmth to crystalline archaeological tension and, finally, resonant abyssal resolve and war-scale orchestral weight.

## Cue Map

| Logical ID | Title | Role | Act identity | Duration |
|---|---|---|---|---:|
| `act_1_bgm` | Lanterns Beneath the Guild | Exploration BGM | Sparse, lighthearted pastoral miniature at 60 BPM in 3/4 | 168.434 s |
| `act_1_boss` | Oath at the Broken Aqueduct | Boss | Courageous tactical 12/8 orchestral drive | 172.640 s |
| `act_2_bgm` | Stars Beneath Stone | Exploration BGM | Crystalline 5/4 archaeology and wonder | 172.405 s |
| `act_2_boss` | The Observatory Wakes | Boss | Mechanical 7/8 observatory assault | 174.181 s |
| `act_3_bgm` | Chains Across the Abyss | Exploration BGM | Near-static C-Phrygian vault drone with oppressive low-frequency pressure | 175.435 s |
| `act_3_boss` | Throne of the First Flame | Boss | The same vault-pressure identity transformed by massed brass and taiko-scale war rhythm | 172.327 s |

All shipping assets are stereo 48 kHz Ogg Vorbis, loudness-normalized to approximately −18 LUFS integrated, loop-enabled by Godot import metadata, and treated with a four-second end-to-start crossfade. Exact prompts live under `prompts/`; retained generator outputs live under `sources/` with the non-importable `.mp3.source` suffix so they are auditable without entering Godot/Web exports; raw empty speech-transcription results live under `evidence/transcriptions/`; hashes and generation facts live in `provenance.json`; logical resolution lives in `catalog.tres`. The two Act III revision-3 cues use documented deterministic acoustic low-shelf preprocessing before the common loop/loudness pipeline: +12 dB at 180 Hz for BGM and +7 dB at 180 Hz for boss. Their normalized sub-220 Hz means are −20.8 and −21.0 dBFS, exceeding revision-2 values of −21.1 and −21.3 dBFS.

## Acceptance State

Every catalog entry remains `placeholder: true`. Structural gates establish that the files are distinct, loadable, loop-enabled, correctly formatted, within the pinned duration and loudness bands, free of detected speech, and fully provenance-linked. `tools/music/verify_music.sh` hashes the prompts, shipping assets, retained sources, and raw transcription JSON; probes both source and shipping media; validates empty transcription content; and checks the rejected short source. They do not establish taste. Only a human listening pass may flip a cue to final.

The 2026-08-12 second listening feedback is captured as another `prompt-change`, not final acceptance. Revision 3 makes Act I BGM slower, materially simpler, lighter, and more peaceful; makes Act III BGM more droning, bass-oppressive, and pressurized; and transforms that same Act III pressure identity into an epic brass-and-taiko boss cue. The other three cues remain byte-for-byte unchanged.

External deterministic signal analysis supports—without pretending to replace listening—the requested direction. Relative to revision 2, Act I revision 3 has 19.3% lower mean spectral flux, 44.24 fewer onset proxies per minute, and less upper-band activity. Act III BGM has a 22.0% larger sub-220 Hz spectral share, lower low-band variability, and a 6.96 dB higher low-band floor. Act III boss has 4.0% more low-band share and 9.4% more onset proxies than its revision-2 predecessor; against its paired revision-3 BGM it has 15.7% more onset proxies and 7.5% more low-mid activity. Simplicity, peacefulness, oppression, brass, taiko, and epic character remain human-only verdicts.

## Human Listening Checklist

Listen to each cue at normal gameplay volume for at least ninety seconds, then cross the loop boundary twice. A cue passes only if all of the following statements are true:

| Check | Falsifiable pass condition |
|---|---|
| Act identity | Act I reads peaceful, warm, and quietly capable; Act II reads wondrous/archaeological with mounting danger; Act III reads vast, resonant, resolute, and climactic without needing the title as a hint. |
| Pair coherence | The BGM and boss cue clearly belong to the same act, but the boss version has materially higher rhythmic and orchestral pressure. |
| Cross-act descent | Moving I → II → III audibly reduces warmth and increases depth, darkness, and scale. |
| Loop seam | No click, silence, obvious restart, or smeared downbeat is audible at either tested boundary. |
| Gameplay space | Exploration cues do not monopolize attention; boss cues stay rhythmically legible under combat SFX that may be added later. |
| Fatigue | No cue becomes grating, piercing, muddy, or monotonous during the ninety-second listen. |
| Revision targets | Act I BGM feels clearly slower, lighthearted, sparse, simple, and peaceful rather than merely quieter. Act III BGM sustains an unmistakable drone, oppressive bass, and increasing architectural pressure without turning muddy. Act III boss belongs to that same pressure world but clearly adds epic massed brass and recognizable taiko/odaiko drums. |
| Vocal absence | No sung, spoken, whispered, or choir-like vocal content is audible. |
| Originality check | No listener recognizes a copied melody or close imitation of an existing composition. |

Record failures as `data-edit`, `asset-regeneration`, or `prompt-change`. Do not clear `placeholder` merely because the files load. Loading is a low bar. Rocks also load.

## Runtime Integration Boundary

This lane intentionally does not add a `MusicPlayer` or hardcode current stages to future acts. The planned three-act stage mapping and boss-transition signal are not yet stable in the repository. A later playback lane should consume `catalog.tres`, own volume/crossfade/pause behavior, and define an observable act/boss routing contract with tests.

## Legal and Provenance Note

The generator backend identifier and seed are not exposed by the tool, and music-model commercial terms must be reviewed before release. The exact prompts, source/output hashes, processing recipe, rejected attempt, and human-acceptance state are preserved so the project can audit or regenerate this candidate score.
