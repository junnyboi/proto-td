# Lunaris Reliquary Title Theme

This is a technical production record, not an independent narrative authority. The sole story authority is [`NARRATIVE_CANON.md`](../NARRATIVE_CANON.md). *Astra Memoriam* and cue `title_lunaris` remain unchanged pending the scheduled listening review; this document does not authorize runtime audio replacement.

## Musical identity

**Working title:** *Astra Memoriam*
**Purpose:** Premium anime-gacha loading/title music for the Lunaris resistance player-entry screen only.
**Generation target:** Original 60-second stereo instrumental at 96 BPM in D minor, designed as 24 complete 4/4 bars.
**Emotional promise:** Majestic, seductive, celestial, resolute, and expensive, with restrained stolen-soul tension beneath the surface rather than frantic or boss-battle aggression.

The theme combines European symphonic drama with East Asian tonal color: soaring string orchestra, intimate piano, glass celesta, low brass, controlled taiko and hybrid tactical percussion, subtle guzheng-like plucks, restrained sub-bass, luminous analog synth pulses, and distant wordless choir pads. It must support the title rather than overwhelm it, with a memorable ascending three-note lunar motif and generous space around the midrange so UI confirmation sounds remain readable. Under the Anima War, the title must frame Lunaris and Company Manus as resistance forces facing corrupted PROTOS and a soul-powered robot empire; celestial beauty is not evidence of a benevolent machine order.

## Sixty-second arrangement

| Time | Bars | Intensity | Musical action |
|---|---:|---:|---|
| 0:00–0:10 | 1–4 | 3/10 | Moonlit resistance opening: solo piano, one pale glass bell, quiet low strings, distant singular human breath, and the three-note lunar motif. |
| 0:10–0:25 | 5–10 | 5/10 | Elegant build: violas and cellos widen, guzheng-like plucks answer the motif, restrained taiko pulse and soft synth arpeggio enter. |
| 0:25–0:45 | 11–18 | 8/10 | Main title statement: full strings, noble low brass, cinematic percussion, and broad processed choir pressure opposed by the lunar motif in a soaring but uncluttered form. |
| 0:45–0:55 | 19–22 | 5/10 | Controlled release: percussion reduces, brass resolves, piano and celesta return to the foreground while aura-like synth harmonics remain. |
| 0:55–1:00 | 23–24 | 3/10 | Loop closure: return to the exact opening harmony, instrumentation density, ambience, and motif pickup with no fade-out or terminal cadence. |

## Generation prompt

Instrumental title music with wordless choir textures and no lyrics or vocal solo. Create a 60-second stereo track at 96 BPM in D minor, exactly 24 bars of 4/4. Original premium anime tactical-fantasy and gacha title theme for a resistance confronting a corrupted rogue AI and soul-powered robot empire: majestic, seductive, celestial, resolute, luxurious, tense, and emotionally magnetic without becoming frantic battle music. Fuse European cinematic orchestra with tasteful East Asian color: soaring violins and violas, rich cellos, intimate grand piano, glass celesta and bells, noble restrained low brass, controlled taiko and modern hybrid tactical percussion, subtle guzheng-like plucks, deep clean sub-bass, luminous analog synth pulses, and a distant wide wordless choir whose processed clusters suggest stolen souls under imperial pressure without lyrics or intelligible speech. Introduce a memorable ascending three-note lunar motif. Dense and luminous at the central climax but leave clean midrange space for title UI sounds. Wide stereo image, deep hall ambience, polished AAA game soundtrack production, controlled low end, detailed transients, no clipping, no lo-fi texture, no pop vocals, no EDM drop, no comedy, no horror dissonance, no abrupt ending, and no fade-out.

[0:00 - 0:10] Moonlit resistance opening: solo piano states the ascending three-note lunar motif over quiet low strings, one glass-bell answer, one distant singular human breath, and a subtle celestial synth bed. Establish the exact harmony and ambience that must return at the end. Intensity: 3/10.

[0:10 - 0:25] Elegant build: violas and cellos widen, guzheng-like plucks answer the motif, a restrained taiko pulse and soft tactical synth arpeggio enter, and the harmony gains confidence without rushing. Intensity: 5/10.

[0:25 - 0:45] Main title statement: full strings carry a broad heroic version of the motif, noble low brass supports rather than dominates, cinematic percussion becomes powerful but controlled, and processed wordless choir pressure opens behind the singular lunar motif, suggesting imperial scale without glorifying PROTOS. Luxurious, attractive, awe-inspiring, and emotionally immediate. Intensity: 8/10.

[0:45 - 0:55] Controlled release: gradually remove the heavy percussion, resolve the brass, and return piano and celesta to the foreground while strings, choir, and aura-like synth harmonics remain suspended. Intensity: 5/10.

[0:55 - 1:00] Seamless loop closure: return precisely to the opening D-minor harmony, instrument density, ambience, tempo grid, and three-note motif pickup. End in an ongoing musical state that connects naturally back to 0:00; no fade, no final hit, no terminal cadence. Intensity: 3/10.

## Runtime and mix targets

The generator returned a 58.096-second stereo MP3 source. The production loop rotates past the opening five-second pickup and uses a five-second forward equal-power crossfade back into that pickup, yielding a 52.500-second cycle with no reversed audio, no fade-out, and no terminal cadence. The Godot Ogg Vorbis derivative measures −16.3 LUFS integrated, 9.6 LU loudness range, and −2.1 dBFS true peak at 48 kHz stereo.

The Music autoload remains the sole runtime owner. The title requests cue `title_lunaris`, and navigation away from the title stops and releases that stream before the separate Lunaris Memory Orbit score begins. Source, lossless production master, checksums, and construction details for the retained title theme remain archived under `docs/audio/lunaris-title-theme/`; the gameplay score contract is documented in `docs/audio/LUNARIS_GAMEPLAY_SCORE.md`.

## Listening and accessibility review

Review the retained cue in stereo, mono, mobile speakers, and with title UI sounds. The ascending motif and rhythmic arrival must survive mono fold-down; corrupted or processed choir color must not be the only carrier of danger. In the visual-to-musical brief, processed **anima—the real and unique human soul** is violet-magenta, while a singular free soul is warm-white or pale-blue. Their musical distinction must remain clear without color or artwork. Preserve midrange space, user volume control, browser gesture unlock, and silence-safe navigation. Reject any interpretation that reads as benevolent PROTOS, a peaceful human farm, safe soul copying, or uncomplicated imperial triumph. Replacement, if ever required, must preserve `title_lunaris`, the title-only scope, handoff behavior, persistent setting, loop construction, and mix targets.

## Web validation

The merged managed PCK loaded successfully through the fullscreen WebDev host and reached the animated Lunaris title without parser, resource, or startup failure. Browser audio remains subject to the standard user-gesture unlock. A neutral click on the title background unlocks the browser audio context. Activating Start must reach Company Command, stop `title_lunaris`, and start `lunaris_staging_archive_command`; no title audio may leak into staging or battle. The Settings music toggle persists its on/off state in `user://view_preferences.cfg` and now governs every title, staging, battle, boss, and result cue across native and browser sessions.
