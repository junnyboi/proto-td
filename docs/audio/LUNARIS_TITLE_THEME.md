# Lunaris Reliquary Title Theme

## Musical identity

**Working title:** *Astra Memoriam*  
**Purpose:** Premium anime-gacha title music for the Lunaris Reliquary player-entry screen.  
**Generation target:** Original 60-second stereo instrumental at 96 BPM in D minor, designed as 24 complete 4/4 bars.  
**Emotional promise:** Majestic, seductive, celestial, resolute, and expensive rather than frantic or boss-battle aggressive.

The theme combines European symphonic drama with East Asian tonal color: soaring string orchestra, intimate piano, glass celesta, low brass, controlled taiko and hybrid tactical percussion, subtle guzheng-like plucks, restrained sub-bass, luminous analog synth pulses, and distant wordless choir pads. It must support the title rather than overwhelm it, with a memorable ascending three-note lunar motif and generous space around the midrange so UI confirmation sounds remain readable.

## Sixty-second arrangement

| Time | Bars | Intensity | Musical action |
|---|---:|---:|---|
| 0:00–0:10 | 1–4 | 3/10 | Moonlit opening state: solo piano, glass bell, quiet low strings, distant wordless choir, and the three-note lunar motif. |
| 0:10–0:25 | 5–10 | 5/10 | Elegant build: violas and cellos widen, guzheng-like plucks answer the motif, restrained taiko pulse and soft synth arpeggio enter. |
| 0:25–0:45 | 11–18 | 8/10 | Main title statement: full strings, noble low brass, cinematic percussion, broad wordless choir, and the lunar motif in a soaring but uncluttered form. |
| 0:45–0:55 | 19–22 | 5/10 | Controlled release: percussion reduces, brass resolves, piano and celesta return to the foreground while aura-like synth harmonics remain. |
| 0:55–1:00 | 23–24 | 3/10 | Loop closure: return to the exact opening harmony, instrumentation density, ambience, and motif pickup with no fade-out or terminal cadence. |

## Generation prompt

Instrumental title music with wordless choir textures and no lyrics or vocal solo. Create a 60-second stereo track at 96 BPM in D minor, exactly 24 bars of 4/4. Original premium anime tactical-fantasy and gacha title theme, majestic, seductive, celestial, resolute, luxurious, and emotionally magnetic without becoming frantic battle music. Fuse European cinematic orchestra with tasteful East Asian color: soaring violins and violas, rich cellos, intimate grand piano, glass celesta and bells, noble restrained low brass, controlled taiko and modern hybrid tactical percussion, subtle guzheng-like plucks, deep clean sub-bass, luminous analog synth pulses, and a distant wide wordless choir. Introduce a memorable ascending three-note lunar motif. Dense and luminous at the central climax but leave clean midrange space for title UI sounds. Wide stereo image, deep hall ambience, polished AAA game soundtrack production, controlled low end, detailed transients, no clipping, no lo-fi texture, no pop vocals, no EDM drop, no comedy, no horror dissonance, no abrupt ending, and no fade-out.

[0:00 - 0:10] Moonlit opening: solo piano states the ascending three-note lunar motif over quiet low strings, one glass-bell answer, distant wordless choir, and a subtle celestial synth bed. Establish the exact harmony and ambience that must return at the end. Intensity: 3/10.

[0:10 - 0:25] Elegant build: violas and cellos widen, guzheng-like plucks answer the motif, a restrained taiko pulse and soft tactical synth arpeggio enter, and the harmony gains confidence without rushing. Intensity: 5/10.

[0:25 - 0:45] Main title statement: full strings carry a broad heroic version of the motif, noble low brass supports rather than dominates, cinematic percussion becomes powerful but controlled, and the wordless choir opens into a celestial crown. Luxurious, attractive, awe-inspiring, and emotionally immediate. Intensity: 8/10.

[0:45 - 0:55] Controlled release: gradually remove the heavy percussion, resolve the brass, and return piano and celesta to the foreground while strings, choir, and aura-like synth harmonics remain suspended. Intensity: 5/10.

[0:55 - 1:00] Seamless loop closure: return precisely to the opening D-minor harmony, instrument density, ambience, tempo grid, and three-note motif pickup. End in an ongoing musical state that connects naturally back to 0:00; no fade, no final hit, no terminal cadence. Intensity: 3/10.

## Runtime and mix targets

The generator returned a 58.096-second stereo MP3 source. The production loop rotates past the opening five-second pickup and uses a five-second forward equal-power crossfade back into that pickup, yielding a 52.500-second cycle with no reversed audio, no fade-out, and no terminal cadence. The Godot Ogg Vorbis derivative measures −16.3 LUFS integrated, 9.6 LU loudness range, and −2.1 dBFS true peak at 48 kHz stereo.

The Music autoload remains the sole runtime owner. The title requests cue `title_lunaris`; campaign entry stops or replaces that cue cleanly. Source, lossless production master, checksums, and construction details are archived under `docs/audio/lunaris-title-theme/`.
