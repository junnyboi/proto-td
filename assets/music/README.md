# Aetheria Tactics — Luminous Descent Music Catalog

This directory contains six original instrumental candidates: one exploration BGM and one boss cue for each planned act. Revision 4 established a shared mid-to-late-1990s Japanese 32-bit console-RPG lo-fi production language for all six slots. Revision 5 keeps the three exploration cues byte-identical and replaces every boss cue with a consistently epic, battle-forward, adrenaline-driven transformation of its act palette.

The supplied reference was used only to extract general traits—sparse ROMpler/sampler arrangements, FM/Rhodes color, jazz extensions, warm mono bass, crunchy original drums, restrained cassette drift, grainy early-digital reverb, and discrete L/C/R sequencing. No reference melody, chord loop, hook, recording, commercial break, sample, lyric, title, or protected compositional identity was copied or requested.

## Cue map

| Logical ID | Title | Role | Act/location identity | BPM | Duration |
|---|---|---|---|---:|---:|
| `act_1_bgm` | Cloister Tape at First Light | Exploration | Warm cloisters, aqueducts, garden ruins, and expedition preparation; welcoming/capable/adventurous | 72 | 171.882 s |
| `act_1_boss` | Broken Aqueduct Showdown | Boss | The guild palette mobilized immediately through heroic motif variations, driving original breaks, bright FM brass, and buoyant tactical courage | 129 | 173.998 s |
| `act_2_bgm` | Observatory Reflections | Exploration | Crystal aquifers, fragmented observatory, submerged archaeology, and mounting threat | 80 | 176.088 s |
| `act_2_boss` | Orrery in Fracture | Boss | The crystal palette fractured into relentless displaced breaks, rotating FM-mallet figures, brass punches, and accelerating observatory pressure | 135 | 171.282 s |
| `act_3_bgm` | Vault on Worn Tape | Exploration | Obsidian vaults, chains, primordial mechanisms, and lava pressure in near-total darkness | 74 | 163.523 s |
| `act_3_boss` | Primordial Break Sequence | Boss | The vault pressure escalated into relentless original breaks, sub-bass ostinato, chain percussion, sampled brass/tom impacts, and final-boss momentum | 141 | 175.383 s |

All six files are stereo 48 kHz Ogg Vorbis, loudness-normalized to approximately −18 LUFS integrated, loop-enabled by Godot import metadata, and treated with the unchanged four-second end-to-start crossfade. Exact prompts live under `prompts/`; selected generator outputs live under `sources/` with a non-importable `.mp3.source` suffix; raw empty speech-transcription records live under `evidence/transcriptions/`; hashes and generation facts live in `provenance.json`; logical resolution lives in `catalog.tres`.

## Shared score DNA

- Original five-note `wayfinder` motif: scale degrees 1–2–5–4–3, with the final two notes rhythmically delayed.
- BGM arrangements target 4–6 simultaneous voices. Boss cues may peak at 7–8 clearly separated voices.
- Rhodes/FM keys, warm centered mono FM/electric bass, original generated 12-bit-style drums, restrained wow/flutter, sampler aliasing, limited high-frequency bandwidth, and grainy early-digital spaces.
- Act I is the warmest and most open; Act II is refractive and increasingly unstable; Act III is darkest, lowest, and most claustrophobic.
- Every revision-five boss cue preserves its act palette while sustaining a higher combat-motion floor. Deterministic analysis measured boss-to-BGM mean spectral-flux ratios of 2.760, 1.894, and 1.569 and centroid increases of 345.703 Hz, 240.727 Hz, and 306.207 Hz for Acts I–III. Relative to revision four, spectral flux increased by factors of 1.535, 1.173, and 1.073; every selected cue improved at least one forward-motion proxy and had no eight-second low-energy collapse. These are signal proxies, not judgments of epicness, battle feel, adrenaline, quality, or style.

## Acceptance state

Every catalog entry remains `placeholder: true`. Structural gates establish that the files are distinct, loadable, loop-enabled, correctly formatted, within duration and loudness bands, free of detected speech, and exactly provenance-linked. They do not establish nostalgia, charm, act identity, instrument recognition, originality, or whether the reference distance is sufficient. Only a human listening pass may flip a cue to final.

The built-in generation tool uses its latest available backend but exposes neither a model selector nor a backend identifier. The owner requested Lyria 3 Pro or latest available; provenance records `not exposed by tool` rather than inventing a Lyria version claim. Commercial terms for the actual backend must be reviewed before shipping.

## Human listening checklist

Listen to each cue at normal gameplay volume for at least ninety seconds, then cross its loop boundary twice. A cue passes only when every applicable row is true.

| Check | Falsifiable pass condition |
|---|---|
| Retro lo-fi language | Each cue audibly reads as original mid-to-late-1990s Japanese console-RPG lo-fi through restrained hardware color, sparse sequencing, FM/Rhodes or ROMpler timbres, and crunchy original rhythm—not modern synthwave, trap, generic orchestral scoring, or vinyl-crackle cosplay. |
| Act I identity | Both cues suggest warm near-surface cloisters, aqueducts, garden ruins, and capable adventure. The BGM is welcoming and leaves gameplay space; the boss cue is courageous and tactically urgent rather than grim. |
| Act II identity | Both cues suggest crystal-fed aquifers, fragmented observatory machinery, archaeology, wonder, and mounting threat. Crystal/delay colors remain legible without becoming piercing or watery mush. |
| Act III identity | Both cues suggest near-lightless obsidian vaults, chained platforms, primordial architecture, and lava pressure. The BGM is oppressive and vast; the boss is climactic and forceful without losing lo-fi identity. |
| Pair coherence | Each BGM/boss pair clearly belongs to the same act through motif, harmony, timbre, and space; the boss cue has materially higher rhythmic pressure without becoming a different genre. |
| Boss adrenaline floor | Every boss cue establishes combat urgency within the opening eight seconds, remains epic and battle-forward through its tactical contrast, and contains no ambient, sleepy, exploratory, or energy-killing valley. |
| Cross-act descent | Moving I → II → III audibly reduces warmth and openness while increasing darkness, pressure, scale, and threat. |
| Loop seam | No click, silence, obvious restart, smeared downbeat, or doubled transient is audible at either tested boundary. |
| Gameplay space | Exploration cues do not monopolize attention; boss cues remain rhythmically legible under future combat SFX. |
| Fatigue | No cue becomes grating, piercing, muddy, overcompressed, monotonous, or gimmicky during the ninety-second listen. |
| Vocal absence | No sung, spoken, whispered, or choir-like vocal content is audible. |
| Originality/reference distance | No listener recognizes a copied melody, hook, chord loop, breakbeat, or close imitation of the supplied reference or another composition. |
| Commercial review | The actual latest-backend usage terms have been reviewed and recorded before shipping. |

Record failures as `data-edit`, `asset-regeneration`, or `prompt-change`. Do not clear a placeholder merely because the file loads. A doorstop can also pass a file-existence check.

## Runtime integration boundary

This lane intentionally does not add a `MusicPlayer` or hardcode current stages to future acts. The planned three-act stage mapping and boss-transition signal are not yet stable in the repository. A later playback lane must consume `catalog.tres`, own volume/crossfade/pause behavior, and define an observable act/boss routing contract with tests. Until then the playable build remains silent under `D-SFX`.
