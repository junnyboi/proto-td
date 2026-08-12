# TD-009 — Three-cue soundtrack regeneration v3

## Authority and assignment

- Owner: AGENT 4
- Primary owner: `godot-2d-art-audio`
- Branch/worktree: `agent-4/music-revision-v3` / `/home/ubuntu/work/prototype-td-agent4-td009`
- Base: `master` at `a46fe9ca0e18abafaf011c8f1f1d487d9c65cfa3`
- Plan depth / route: Standard / STANDARD
- Human verdict classification: `prompt-change`

Poseidon requested a second revision of exactly three candidate slots:

1. Act I BGM: too much is happening; make it lighthearted, simple, peaceful, and slower.
2. Act III BGM: make it more droning, with oppressive bass and greater pressure.
3. Act III boss: use the Act III BGM identity but make it more epic with brass and taiko drums.

## Scope and exclusions

Replace only the selected sources, shipping Ogg files, exact prompts, transcriptions, catalog metadata, provenance, listening guide, and candidate-bound evidence. Preserve Act I boss and both Act II cues byte-for-byte. Preserve all six `placeholder: true` flags.

Do not add runtime playback, a `MusicPlayer`, SFX, stage-to-act routing, boss-transition signals, simulation changes, gameplay data changes, engine/export changes, tests, harness changes, `scripts/verify.sh` changes, or threshold changes. The current playable build remains silent under `D-SFX`.

## Shared score DNA

All three revisions retain the original descending four-note contour, scale degrees 5–4–flat-3–2. Act I states it as an unhurried, childlike-but-not-childish pastoral phrase. Act III stretches the same contour into a slow tectonic descent. The Act III boss uses that stretched descent as its low-brass war call.

## Cue concepts

### Act I BGM revision 3 — simple pastoral breathing room

- 60 BPM, 3/4, D major with rare D-Dorian color.
- One lead line at a time; no counterpoint and no busy arpeggiation.
- Core palette: nylon guitar, solo flute, soft viola/cello sustain, occasional harp harmonic.
- No percussion, piano runs, string ostinato, brass, dramatic build, or ornamental woodwind chatter.
- Maximum intensity 3/10; the final minute is not a climax.
- Gameplay role: restful, warm, and unobtrusive for long exploration.

### Act III BGM revision 3 — oppressive droning pressure

- 58 BPM, 4/4, C Phrygian with a rare Dorian lift withheld until late.
- Continuous acoustic C drone from contrabasses, low cellos, contrabassoon, tuba, and pipe-organ pedal.
- Slow flat-second pressure, semitone beating, low-register swells, chain resonance, and stone echoes.
- Almost no melody; the leitmotif is elongated into four immense notes.
- Sparse deep timpani/gran-cassa pressure every several bars, not battle rhythm.
- More sub-220 Hz energy than revision 2 after normalization; no post-hoc EQ is assumed unless measurement proves a bounded deterministic shelf is necessary.

### Act III boss revision 3 — the same vault, mobilized for war

- 116 BPM, broad 12/8, C Phrygian with controlled Dorian resistance.
- Retain the same continuous C drone, flat-second pressure, chain echoes, and stone-space identity as Act III BGM.
- Add eight horns, trumpets, bass trombones, tuba, and a clearly audible taiko ensemble with odaiko fundamentals.
- Taiko patterns are martial and spacious, leaving the drone audible between attacks.
- More epic and rhythmically forceful than the BGM without becoming generic trailer music or losing bass pressure.

## Exact generation prompts

### `act_1_guild_threshold_bgm`

Instrumental only, no vocals. Create a complete 180-second loop-oriented pastoral chamber-fantasy exploration track at a slow 60 BPM in gentle 3/4, centered in D major with only occasional soft D-Dorian color. Keep the composition lighthearted, peaceful, simple, patient, and warmly curious. The setting is a sunlit near-surface guild threshold of quiet cloisters, garden ruins, clear aqueduct water, and a safe expedition waystation at morning. Use a deliberately sparse acoustic arrangement with one melodic voice at a time: fingerpicked nylon-string guitar as the constant foundation, a single solo flute for the main tune, very soft sustained viola and cello for occasional warmth, and rare harp harmonics as points of light. State an original descending four-note motif with contour scale degrees 5–4–flat-3–2 as an extremely simple, slow, conjunct flute phrase with generous silence between phrases. Use open fifths, plain major-sixth harmony, restrained modal color, long note values, natural breathing, and deliberate silence. At no moment should more than four instrument families be active. No countermelody and no dramatic orchestral layering. Use intimate close chamber acoustics, a warm natural stereo image, restrained bass, soft transients, and clean modern game-score production. Keep intensity between 1/10 and 3/10 for the entire cue. Avoid busy arpeggios, fast notes, ornament runs, contrapuntal writing, repeated ostinatos, pizzicato bustle, piano figures, percussion, drums, brass, choir, voices, synthesizers, trailer swells, heroic climax, melancholy, danger, tension, terminal cadence, ritardando, and fade-out. The final bars must restore the exact opening guitar pattern, D harmony, flute silence, room size, and 1/10 intensity for a seamless loop. [0:00 - 0:36] Morning Stillness: nylon guitar plays a very slow two-chord pattern with long empty spaces; one harp harmonic appears at phrase ends. No flute yet. Intensity: 1/10. [0:36 - 1:18] Small Adventure: solo flute states the four-note motif once, then waits; soft viola sustains only chord roots and sixths beneath the guitar. Keep phrases short and separated by silence. Intensity: 2/10. [1:18 - 2:00] Garden Path: cello joins only on alternate phrases while flute offers one plain variation using the same few notes. No additional rhythm or countermelody. Intensity: 2/10. [2:00 - 2:36] Sun on Water: allow a modest warm string swell and two harp harmonics, but keep guitar and flute exposed and simple. This is not a climax. Intensity: 3/10. [2:36 - 3:00] Waystation Rest: remove cello and viola, stop the flute after one half-motif, and return exactly to the opening nylon-guitar pattern, D harmony, silences, harp spacing, and intimate room. No cadence and no fade. Intensity: 1/10. Instrumental only, no vocals.

### `act_3_abyssal_vault_bgm`

Instrumental only, no vocals. Create a complete 180-second loop-oriented dark orchestral ambient exploration track at a slow 58 BPM in 4/4, rooted in C Phrygian with almost no harmonic relief. Sustain composed sound and an oppressive acoustic bass drone continuously for the full three minutes; do not end early. The setting is an immense Abyssal Vault of obsidian walls, chained platforms, sealed primordial machinery, and lava pressure beneath the floor. The emotional center is claustrophobic despite the scale: inexorable pressure, ancient weight, physical dread, and the sense that the architecture is pressing inward. Make the low-frequency drone the dominant feature in every section: layered bowed contrabasses, very low cellos, contrabassoon, bass clarinet, tuba fundamentals, bass trombone breath, and a sustained pipe-organ C pedal. Preserve strong clean energy below 220 Hz throughout, with slow amplitude beating and semitone friction between C and D-flat creating pressure without distortion. Use extremely little melody. Stretch the original descending four-note contour 5–4–flat-3–2 into four immense low notes that take many bars to unfold. Add only distant violin harmonics, scraped low-string textures, chain resonance, subsonic-feeling gran-cassa rolls, and isolated deep timpani impacts every several bars. Make the vault audibly enormous through long dark stone reverberation, slow echoes from opposite walls, and chain reflections, while keeping the central drone focused and mono-compatible. High-quality modern orchestral game-score production, wide but stable stereo architecture, powerful controlled sub-bass, dark upper spectrum, preserved headroom, and no mud. Keep continuous pressure between 5/10 and 8/10; quieter passages must remain heavy rather than restful. Avoid active melodies, lyrical solos, hopeful themes, busy rhythm, regular drum groove, heroic motion, choir, voices, lyrics, synthesizers, electronic bass, rock guitars, pop drums, generic trailer braams, funeral march rhythm, silence, terminal cadence, ritardando, and fade-out. The final bars must reproduce the exact opening C drone, D-flat beating layer, organ depth, chain reflection, and pressure level for a seamless loop. [0:00 - 0:32] Sealed Weight: begin immediately with layered contrabass, low cello, tuba, contrabassoon, and pipe-organ C drone. Introduce a faint D-flat beating layer and one distant chain echo. No melody and no pulse. Intensity: 5/10. [0:32 - 1:12] Walls Closing: bass clarinet and bass trombone add slow breath-like swells. The first two notes of the stretched motif emerge over many bars. One deep timpani strike opens a long echo; the drone never thins. Intensity: 6/10. [1:12 - 1:52] Primordial Machinery: gran-cassa rolls and low string pressure waves make the floor feel unstable. Complete the elongated four-note descent with almost imperceptible movement. Increase semitone friction and low-frequency mass without adding tempo. Intensity: 8/10. [1:52 - 2:28] Chained Platforms: remove the loudest drum layer but retain all foundational bass voices. Let opposing-wall echoes and chain resonance multiply while the harmony stays pinned between C and D-flat. Intensity: 7/10. [2:28 - 3:00] The Vault Breathes: slowly remove violin harmonics and bass-trombone swells, then return exactly to the opening layered C drone, D-flat beating layer, pipe-organ depth, chain reflection, stereo state, and 5/10 pressure. Continue sound through 3:00. No cadence and no fade. Instrumental only, no vocals.

### `act_3_abyssal_vault_boss`

Instrumental only, no vocals. Create a complete 180-second loop-oriented epic dark-fantasy war track at 116 BPM in broad 12/8, rooted in C Phrygian with brief controlled C-Dorian resistance. This is the combat transformation of the Act III exploration cue: preserve its continuous oppressive C drone, D-flat semitone pressure, immense obsidian-vault acoustics, chain echoes, low-string mass, tuba fundamentals, contrabassoon, and pipe-organ pedal throughout the full three minutes. Add an unmistakably epic brass army and Japanese taiko ensemble: eight French horns, trumpets, tenor and bass trombones, tuba, taiko drums, shime-daiko articulation, and huge odaiko fundamentals, supported by timpani, gran cassa, and low orchestral strings. The taiko must be clearly audible as deep skin-and-wood drums, not a generic cinematic boom. Use spacious martial patterns with strong rests so the bass drone remains exposed between attacks. Turn the original descending four-note contour 5–4–flat-3–2 into a massive bass-trombone, tuba, horn, and organ war call; answer it with a restrained rising three-note trumpet-and-horn resistance figure. Maintain heavy sub-220 Hz pressure in every section, including the tactical reduction and loop return. Use antiphonal brass across opposite vault walls, two-beat horn echoes, three-beat chain reflections, synchronized taiko-and-brass attacks, slow harmonic rhythm, flat-second threat, and decisive dynamic cuts. The emotional center is overwhelming, martial, colossal, and defiant under crushing pressure—not mournful or depressive. High-quality modern orchestral game-score production, very wide scale, focused mono-compatible bass center, enormous but controlled stone reverb, preserved taiko transients, powerful brass definition, and clean headroom. Avoid choir, voices, lyrics, synthesizers, electronic bass, rock guitars, pop drum kits, fast string noodling, constant cymbal wash, generic trailer braams, funeral march character, heroic major-key release, unbroken maximum loudness, terminal cadence, ritardando, and fade-out. The final bars must restore the exact opening drone, taiko spacing, unresolved C/D-flat pressure, low-brass call, organ level, and antiphonal echo for a seamless loop. [0:00 - 0:24] War Beneath Stone: continuous C drone begins immediately in contrabasses, low cellos, tuba, contrabassoon, and organ. Odaiko marks a spacious 12/8 war pattern; bass trombones state the descending call and distant horns answer. Intensity: 7/10. [0:24 - 1:00] Chained Advance: full taiko ensemble and low strings establish the martial pulse. Horns and trumpets broaden the resistance answer while tuba and bass trombones preserve the oppressive foundation. Leave audible rests between attacks. Intensity: 8/10. [1:00 - 1:38] Vault Legions: antiphonal brass, taiko cross-rhythms, timpani, gran cassa, and chain impacts expand the scale. Keep harmonic movement slow and the C/D-flat pressure continuous; epic weight, not frantic speed. Intensity: 9/10. [1:38 - 2:06] Under the Throne: cut upper brass and most taiko, leaving odaiko heartbeats, organ, drone, bass clarinet, contrabassoon, and distant horn echoes. Pressure must increase through exposure, not disappear. Intensity: 6/10. [2:06 - 2:42] Primordial War: rebuild to the largest statement with massed horns, trumpets, trombones, tuba, full taiko ensemble, low strings, organ, and chain echoes combining both motifs. Keep the drone audible beneath every attack. Intensity: 10/10. [2:42 - 3:00] Eternal Siege: remove upper countermelodies while retaining the oppressive drone, odaiko pattern, low brass, organ, and chain space. Restore the opening C/D-flat pressure, bass-trombone call, taiko spacing, and opposing horn echo exactly. No cadence and no fade. Intensity: 7/10. Instrumental only, no vocals.

## Deterministic acceptance and evidence

- Exactly the three selected Ogg/source/prompt/transcription slots change; the other three cue asset and source hashes remain byte-identical.
- Selected generated sources must measure 164–184 seconds so the four-second loop treatment produces 160–180-second shipping cues.
- Shipping files remain stereo 48 kHz Ogg Vorbis, approximately −18 LUFS, true peak no higher than −1.5 dBFS, loop-enabled, unique, silence-free, and provenance-linked.
- Raw speech transcription must return empty `full_text` and zero segments for every selected source.
- Act III normalized sub-220 Hz measurements must exceed their revision-2 values (`-21.1 dBFS` BGM, `-21.3 dBFS` boss) or a bounded deterministic preprocessing deviation must be recorded before acceptance.
- Human-only judgments remain open: simplicity, peacefulness, drone character, oppression, pressure, brass/taiko identity, epic scale, loop feel, fatigue, gameplay space, originality, and commercial terms.
- Required machine gates: `tools/music/verify_music.sh`, Godot import, focused `test_music_catalog.gd`, full headless `scripts/verify.sh`, clean-tree/source-hash proof, and merged-union rerun at the integration commit.
- No windowed gameplay evidence is applicable because this lane changes unplayed candidate bytes and the runtime remains silent by `D-SFX`; human audio review is the applicable player-facing gate.

## Rollback

Revert the TD-009 implementation and closure commits. The complete revision-2 assets, sources, prompts, metadata, and transcriptions remain recoverable from commit `a58e2d5d41579d3f8fe0427f005dba5b14558f84` and its descendants.

## Actual generation outcome

All three first-call sources met the predeclared 164–184-second source band: Act I BGM is 172.434208 seconds, Act III BGM is 179.435042 seconds, and Act III boss is 176.326458 seconds. The generation tool again wrote MP3-encoded 44.1 kHz stereo bytes to the requested `.wav` paths, consistent with existing `D-MUSIC-4`. No regeneration retry was necessary. Raw speech-to-text returned empty `full_text` and zero segments for all three selected sources.

The shared four-second loop/loudness pipeline produced 168.434229, 175.435104, and 172.326542-second stereo 48 kHz Ogg Vorbis cues at −17.9 LUFS. Act I required no tonal processing. The first bounded Act III shelves (+6 dB BGM, +5 dB boss at 180 Hz) were measured and rejected because both did not exceed revision-2 low-band values. Final accepted deterministic preprocessing is +12 dB for BGM and +7 dB for boss at 180 Hz. Their normalized sub-220 Hz means are −20.8 and −21.0 dBFS versus revision-2 −21.1 and −21.3 dBFS.

External deterministic NumPy/ffmpeg analysis records objective directional proxies, not taste certification. Act I revision 3 has 19.3% lower mean spectral flux, 44.24 fewer onset proxies per minute, and 0.018746 less upper-band spectral share than revision 2. Act III BGM has 22.0% more sub-220 Hz spectral share, 0.72 dB less low-band variability, and a 6.96 dB higher low-band floor. Act III boss has 4.0% more low-band share and 9.4% more onset proxies than revision 2; versus the paired revision-3 BGM, it has 15.7% more onset proxies and 7.5% more low-mid activity. Whether the cue actually reads as simple, peaceful, droning, oppressive, brass-led, taiko-led, or epic remains TD-004 human evidence.

The unchanged structural music gate passed all six unique cues, retained sources, prompts, transcriptions, loop flags, durations, codec/rate/channel constraints, loudness, peak, silence, and hash linkage. Focused catalog GUT passed 3/3 tests and 239 assertions after import. All six catalog placeholders remain true.
