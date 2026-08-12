# Prototype TD — Luminous Descent Music Catalog

This directory contains six original instrumental orchestral cues: one exploration BGM and one boss cue for each planned act. They share a new four-note descending leitmotif and progressively darken from warm expedition music to crystalline archaeological tension and, finally, monumental abyssal weight.

## Cue Map

| Logical ID | Title | Role | Act identity | Duration |
|---|---|---|---|---:|
| `act_1_bgm` | Lanterns Beneath the Guild | Exploration BGM | Warm chamber orchestra, 6/8 expedition pulse | 173.528 s |
| `act_1_boss` | Oath at the Broken Aqueduct | Boss | Courageous tactical 12/8 orchestral drive | 172.640 s |
| `act_2_bgm` | Stars Beneath Stone | Exploration BGM | Crystalline 5/4 archaeology and wonder | 172.405 s |
| `act_2_boss` | The Observatory Wakes | Boss | Mechanical 7/8 observatory assault | 174.181 s |
| `act_3_bgm` | Chains Across the Abyss | Exploration BGM | Slow C-Phrygian monumental descent | 173.633 s |
| `act_3_boss` | Throne of the First Flame | Boss | Climactic 12/8 primordial orchestral battle | 168.042 s |

All shipping assets are stereo 48 kHz Ogg Vorbis, loudness-normalized to approximately −18 LUFS integrated, loop-enabled by Godot import metadata, and treated with a four-second end-to-start crossfade. Exact prompts live under `prompts/`; hashes and generation facts live in `provenance.json`; logical resolution lives in `catalog.tres`.

## Acceptance State

Every catalog entry remains `placeholder: true`. Structural gates establish that the files are distinct, loadable, loop-enabled, correctly formatted, within the pinned duration and loudness bands, free of detected speech, and fully provenance-linked. They do not establish taste. Only a human listening pass may flip a cue to final.

## Human Listening Checklist

Listen to each cue at normal gameplay volume for at least ninety seconds, then cross the loop boundary twice. A cue passes only if all of the following statements are true:

| Check | Falsifiable pass condition |
|---|---|
| Act identity | Act I reads warm/capable; Act II reads wondrous/archaeological with mounting danger; Act III reads oppressive/vast/climactic without needing the title as a hint. |
| Pair coherence | The BGM and boss cue clearly belong to the same act, but the boss version has materially higher rhythmic and orchestral pressure. |
| Cross-act descent | Moving I → II → III audibly reduces warmth and increases depth, darkness, and scale. |
| Loop seam | No click, silence, obvious restart, or smeared downbeat is audible at either tested boundary. |
| Gameplay space | Exploration cues do not monopolize attention; boss cues stay rhythmically legible under combat SFX that may be added later. |
| Fatigue | No cue becomes grating, piercing, muddy, or monotonous during the ninety-second listen. |
| Vocal absence | No sung, spoken, whispered, or choir-like vocal content is audible. |
| Originality check | No listener recognizes a copied melody or close imitation of an existing composition. |

Record failures as `data-edit`, `asset-regeneration`, or `prompt-change`. Do not clear `placeholder` merely because the files load. Loading is a low bar. Rocks also load.

## Runtime Integration Boundary

This lane intentionally does not add a `MusicPlayer` or hardcode current stages to future acts. The planned three-act stage mapping and boss-transition signal are not yet stable in the repository. A later playback lane should consume `catalog.tres`, own volume/crossfade/pause behavior, and define an observable act/boss routing contract with tests.

## Legal and Provenance Note

The generator backend identifier and seed are not exposed by the tool, and music-model commercial terms must be reviewed before release. The exact prompts, source/output hashes, processing recipe, rejected attempt, and human-acceptance state are preserved so the project can audit or regenerate this candidate score.
