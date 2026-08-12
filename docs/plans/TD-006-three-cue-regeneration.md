# Prototype TD — Three-Cue Soundtrack Regeneration Plan

**Mode:** companion asset-regeneration session
**Owner:** AGENT 4
**Base:** `master` at `690f7617acdc710855c3c8e169ad673b1fa8fec0`
**Human feedback:** regenerate `act_1_bgm`, `act_3_bgm`, and `act_3_boss`; retain the other three cues byte-for-byte.

## Summary

This pass keeps the six-slot logical catalog and replaces only three generated assets. The Act I exploration cue remains a warm near-surface fantasy journey but becomes quieter, more pastoral, more patient, and less conventionally adventurous. The Act III pair retains the Abyssal Vault setting while replacing funereal despair with resolute awe: both cues gain clear cavern echoes and controlled orchestral low-end weight, while the boss cue becomes unmistakably epic war music.

The user's named reference is treated as a communication shortcut, not an imitation target. Generation prompts contain no artist, franchise, soundtrack, song, or album names. They specify original harmonic, orchestral, rhythmic, spatial, and emotional traits instead.

## Pinned Parameters

| Parameter | Value |
|---|---|
| Generator | Manus `generate_music`, latest available backend; internal model ID/seed not exposed |
| Calls | One 180-second call per replacement cue; no stitching |
| Shared identity | Original descending four-note contour, scale degrees 5–4–flat-3–2 |
| Shipping format | Stereo 48 kHz Ogg Vorbis, four-second deterministic loop crossfade |
| Loudness | Approximately −18 LUFS integrated; true peak ≤ −1.5 dBFS |
| Duration gate | 160–180 seconds after loop treatment |
| Acceptance state | `placeholder: true`; this pass does not claim final human acceptance |
| Unchanged cues | Act I boss, Act II BGM, Act II boss remain byte-identical |
| Runtime | Remains silent; no playback, routing, autoload, scene, or bus work |

## Replacement Concepts and Exact Prompts

### 1. Act I BGM — peaceful pastoral journey

**Concept.** A mature, serene fantasy travel cue heard in sunlit cloisters and garden ruins after a very long road. It should feel safe without becoming sleepy, wistful without becoming sad, and quietly magical without becoming whimsical. The old D-Dorian motif and acoustic palette survive, but percussion, heroic horn weight, and forward expedition pressure recede. Intimacy, woodwind breath, harp/guitar detail, extended harmony, and deliberate silence carry the cue.

**Prompt.**

> Instrumental only, no vocals. Create a 180-second loop-oriented pastoral chamber-fantasy exploration track at 78 BPM in D Dorian, with a gentle flowing 6/8 pulse. The setting is a welcoming near-surface guild threshold: sunlit crypt cloisters, garden ruins, quiet aqueducts, expedition waystations, old stone warmed by morning light, and clear running water. The emotional center is peaceful, patient, tender, and quietly wise—a sense of long-lived memory, gentle companionship, and wonder at ordinary beauty. It must feel comforting and safe without becoming childish, sleepy, sentimental, or mournful. Use an intimate acoustic palette led by nylon-string guitar, Celtic harp, soft piano used sparingly, solo flute, clarinet, oboe, warm violas and cellos, delicate first violins, pizzicato double bass, and only the lightest brushed frame drum and triangle color. Keep French horns rare and velvety, never heroic. State an original four-note descending leitmotif with the contour scale degrees 5–4–flat-3–2 as a simple conjunct woodwind melody, then let guitar, harp, and strings remember fragments of it. Favor Dorian warmth, pentatonic turns, open fifths, quartal voicings, extended sixth, ninth, and eleventh chords, impressionistic chord planing, natural rubato inside the steady pulse, and deliberate silence between phrases. Use close, natural chamber acoustics with a soft halo of room reverb, a warm detailed stereo image, clear inner voices, restrained low end, and high-quality modern game-score production. The arrangement must remain breathable and unobtrusive under gameplay. Avoid choir, voices, lyrics, synthesizers, electronic bass, rock guitars, pop drums, trailer percussion, martial rhythms, forceful ostinatos, bright comic whimsy, sorrowful lament, heroic climax, terminal cadence, ritardando, and fade-out. The final bars must return to the exact opening guitar-harp texture, D pedal, room size, and low intensity for a seamless loop. [0:00 - 0:30] Morning Cloister: Begin with nylon guitar harmonics and harp arpeggios over a soft D pedal. A lone flute plays only the first two notes of the motif, leaving generous silence. Add a few transparent piano notes like sunlight on water. No percussion. Intensity: 1/10. [0:30 - 1:12] Quiet Road: Clarinet completes the four-note motif while pizzicato bass gives a barely perceptible 6/8 walking pulse. Viola and cello answer in warm parallel sixths; brushed frame drum appears only on occasional phrase openings. Peaceful forward motion, never urgency. Intensity: 3/10. [1:12 - 1:54] Garden Memory: Pull closer. Oboe and solo violin trade small pentatonic fragments above guitar, harp, and soft piano. Use one bittersweet modal turn, then restore Dorian warmth immediately. The feeling is affectionate remembrance, not loss. Intensity: 2/10. [1:54 - 2:30] Aqueduct Sunlight: Let the chamber strings bloom gently and allow one restrained horn cushion beneath the woodwind motif. Add flowing harp figures and subtle triangle reflections. This is a calm emotional opening of the landscape, not a climax. Intensity: 4/10. [2:30 - 3:00] Waystation Rest: Remove horn, percussion, and upper string density in stages. Return to the opening D pedal, guitar harmonics, harp pattern, two-note flute hint, piano spacing, and intimate room state. No cadence, no ritardando, no fade. Intensity: 2/10 returning to 1/10. Instrumental only, no vocals.

### 2. Act III BGM — resonant low-end abyssal resolve

**Concept.** The vault remains colossal and dangerous, but the player is no longer emotionally defeated by it. This is awe, resolve, and forward movement: a bass-led ritual exploration pulse inside an enormous reflective stone-and-metal chamber. Echo is an active compositional device—antiphonal low-horn and cello calls, chain reflections, distant drum answers—rather than a washed-out master reverb. The center stays clear and the bass remains deep but controlled.

**Prompt.**

> Instrumental only, no vocals. Create a 180-second loop-oriented cinematic fantasy exploration track at 76 BPM in C Dorian with occasional restrained C-Phrygian tension, carried by a broad 6/8 ritual pulse. The setting is an Abyssal Vault of obsidian architecture, chained platforms, lava vents, and immense sealed mechanisms. The emotional center is vast, resolute, mysterious, and awe-inspiring—not depressed, hopeless, funereal, or emotionally defeated. The player should feel small before an ancient power but capable of crossing it. Build a bass-heavy acoustic orchestral foundation from contrabasses, low cellos, bass clarinet, contrabassoon, low French horns, bass trombone used sparingly, tuba fundamentals used with restraint, pipe organ pedals, deep timpani, orchestral bass drum, gran cassa, low frame drums, tam-tam, and tuned chain resonance. Balance the low end with burnished midrange cellos, horns, bass clarinet, and occasional distant violin harmonics so the mix stays readable rather than muddy. Transform an original four-note descending leitmotif with the contour scale degrees 5–4–flat-3–2 into a grounded cello-and-low-horn call; answer it with an original rising three-note figure that suggests determination. Favor C-Dorian open fifths, suspended fourths, minor ninth color, slow parallel chord planing, and brief flat-second pressure that resolves back into Dorian strength. Make the space conspicuously echoing: antiphonal low-brass calls from opposite sides of the vault, two- and three-beat cello echoes, distant chain reflections, and long dark stone reverberation on impacts. Keep the central bass pulse dry enough to retain articulation while the answers bloom into cavern depth. High-quality modern orchestral game-score production, wide stereo architecture, powerful controlled sub-bass, clear transients, and substantial dynamic range. Avoid choir, voices, lyrics, synthesizers, electronic drones, rock guitars, pop drums, generic trailer braams, funeral pacing, lamenting solo cello, bleak sustained dissonance, constant clusters, empty despair, busy melody, terminal cadence, ritardando, and fade-out. The final bars must recreate the opening C pedal, low-frame-drum pulse, horn-call echo, and chain reflection for a seamless loop. [0:00 - 0:28] Vault Threshold: Begin with a focused C pedal in contrabass, low cello, and organ fundamental. A single low frame drum marks the 6/8 pulse; a distant horn states the first half of the motif and its answer arrives from the opposite wall two beats later. Chain reflections reveal the scale of the room. Intensity: 3/10. [0:28 - 1:06] Chained Causeway: Cellos and bass clarinet state the full motif over deep pizzicato bass and restrained gran cassa. Low horns answer antiphonally, with echoes that decay clearly into the vault. The harmony stays minor and ancient but gains Dorian lift and forward purpose. Intensity: 5/10. [1:06 - 1:44] Obsidian Survey: Add contrabassoon, timpani, and slow pipe-organ movement. Split the rising answer between horns and cellos while chain resonance repeats fragments across the stereo field. Keep the bass physically present, rhythmic, and clean. Intensity: 6/10. [1:44 - 2:22] Lava Conduits: Increase low-string motion and let bass trombone reinforce structural downbeats. Tam-tam and distant drum echoes illuminate the chamber without turning the cue into battle music. The motif broadens into confident open intervals; no lament. Intensity: 6/10. [2:22 - 3:00] Vault Resolve: Gradually remove bass trombone, tam-tam, upper strings, and extra percussion. Preserve the C-Dorian weight and return precisely to the opening pedal, low-frame-drum pulse, horn half-motif, two-beat echo, and chain reflection. No cadence, no ritardando, no fade. Intensity: 5/10 returning to 3/10. Instrumental only, no vocals.

### 3. Act III Boss — resonant bass-heavy epic war music

**Concept.** A colossal war orchestra fighting inside the same vault. It remains dark fantasy, but the core emotion is defiance and military momentum rather than doom. The low-frequency engine must be physical and articulate: low strings, organ, brass, timpani, gran cassa, and orchestral war drums. Echo creates antiphonal armies across the chamber. The descending motif represents the primordial enemy; an ascending horn answer represents the player's resistance.

**Prompt.**

> Instrumental only, no vocals. Create a 180-second loop-oriented epic dark-fantasy war track at 146 BPM in C Dorian with controlled C-Phrygian threat, driven by a powerful martial 12/8 pulse. The battle unfolds across chained platforms above lava vents inside a colossal obsidian vault. The emotional center is defiant, resolute, heroic under pressure, and overwhelmingly epic—not depressed, hopeless, funereal, or nihilistic. Build a bass-heavy symphonic war orchestra from aggressive low strings, contrabasses, cellos, bass clarinet, contrabassoon, eight French horns, trumpets, tenor and bass trombones, tuba, pipe organ, timpani, orchestral bass drum, gran cassa, deep field drums, low toms, tam-tam, anvils, and chain impacts. Preserve a clean game mix: low strings, organ, and drums form a tight dry rhythmic center while brass calls, anvils, and chain strikes produce long controlled echoes across the vault. Turn an original descending four-note leitmotif with the contour scale degrees 5–4–flat-3–2 into the enemy's massive low-brass and organ war call. Answer it with an original rising three-note horn-and-trumpet figure that embodies resistance, then combine both figures in counterpoint at the climax. Use C-Dorian strength, open fifths, suspended fourths, minor-mode brass harmony, brief flat-second pressure, driving string ostinatos, galloping 12/8 war drums, antiphonal brass, cross-rhythms, and decisive dynamic cuts. Make the cavern conspicuously echoing without washing out the pulse: two-beat horn replies from opposing walls, three-beat chain echoes, and deep drum tails that leave the next attack clear. High-quality modern orchestral game-score production, very wide stereo scale, powerful controlled sub-bass, preserved transients, and readable orchestral layers. Avoid choir, voices, lyrics, synthesizers, electronic bass, rock guitars, pop drum kits, generic trailer braams, mournful solo passages, funeral march character, passive doom drones, unbroken maximum loudness, terminal cadence, ritardando, and fade-out. The final bars must restore the exact opening low-string-organ war pulse, drum pattern, unresolved C harmony, and antiphonal horn echo for seamless looping. [0:00 - 0:18] Armies in the Vault: Low strings, organ, gran cassa, and deep field drums establish the 12/8 war pulse. Bass trombones state the descending enemy motif; horns answer from the far wall with the rising resistance figure. Intensity: 6/10. [0:18 - 0:54] First Charge: Full low strings drive a galloping ostinato. Horns and trumpets broaden the resistance figure while trombones and tuba reinforce structural attacks. Timpani and bass drum remain forceful but articulate; chain echoes answer every fourth bar. Intensity: 8/10. [0:54 - 1:30] Chained Legions: Add antiphonal brass, anvils, contrabassoon runs, and cross-rhythmic war drums. Pass the two motifs between left and right orchestral forces, building martial momentum without generic trailer hits. Intensity: 9/10. [1:30 - 1:58] Hold the Line: Cut to low cello ostinato, organ, bass clarinet, restrained timpani, and distant horn echoes. Keep the pulse alive and tense; this is strategic resolve, not grief or emptiness. Intensity: 5/10. [1:58 - 2:42] War Above the Flame: Rebuild into the largest statement. Combine the descending enemy motif and rising resistance figure in counterpoint across horns, trumpets, trombones, strings, and organ. Gran cassa, field drums, tam-tam, anvils, and chain impacts articulate a victorious-feeling surge without resolving the battle. Intensity: 10/10. [2:42 - 3:00] Eternal Battle: Remove upper brass and dense counterpoint in stages while preserving the low-string-organ pulse and deep war drums. Restore the opening bass-trombone call, opposing horn answer, unresolved C harmony, and echo timing exactly. No cadence, no ritardando, no fade. Intensity: 7/10 returning to 6/10. Instrumental only, no vocals.

## File Contract

Only these existing cue slots change: the three Ogg assets, their prompt files, retained selected source files, raw transcription JSON, the corresponding entries in `catalog.tres` and `provenance.json`, cue-map/listening documentation, and regeneration evidence. Old selected hashes remain recorded as superseded revisions and remain recoverable from Git commit `321abc25f5d4866909d837cd335ade9579deaa95`.

No test, threshold, simulation, runtime, stage, scene, autoload, playback, or routing file changes are needed. Existing music verification and catalog tests must pass unchanged.

## Acceptance and Gates

1. Three new generator sources are nonempty, mutually unique, and differ from every unchanged source.
2. Post-processing produces stereo 48 kHz Vorbis cues in the 160–180 second band, around −18 LUFS, with no ≥2-second digital silence and loop-enabled imports.
3. Exact prompt/source/output/transcription hashes match catalog and provenance.
4. Raw speech-to-text reports contain zero segments and empty text.
5. Act I prompt materially reduces tempo, percussion, brass pressure, and peak intensity relative to v1.
6. Act III prompts explicitly reject grief/funeral/nihilistic character and explicitly require controlled bass weight plus antiphonal cavern echoes; the boss additionally requires martial 12/8 war momentum.
7. Existing three untouched shipping Ogg hashes remain exact: Act I boss `18a61c…`, Act II BGM `b3642e…`, Act II boss `43892a…`.
8. Existing focused GUT and `tools/music/verify_music.sh` pass unchanged; full `scripts/verify.sh --full` passes at the frozen candidate and merged master.
9. Independent adversarial audit confirms only the three requested slots changed semantically and placeholders remain true.
10. Human listening remains the only acceptance of peace, optimism, echo, bass weight, epic quality, loop feel, fatigue, and originality.

> Never weaken/remove/reinterpret a failing check — fix the game. Screenshots only from the run just executed (verify report.json + mtimes); never reuse or hand-craft evidence. Impossible checks stay failing and get logged as numbered deviations. Never conclude "works" from a hung or skipped run. Tests and thresholds are human-owned: never edit a test or a threshold to pass — retune `data/*.tres`.

## Non-Goals

No imitation of a named composition; no changes to the three accepted-for-now cues; no placeholder clearing; no runtime playback; no act routing; no SFX; no UI; no new audio buses; no test/threshold edits; no gameplay or simulation changes.

## Trim Order and Never-Cut List

If a generated cue fails three distinct attempts, first simplify orchestration density, then reduce spatial-effect instructions, then shorten the arrangement target to 170 seconds. Never cut one of the requested replacements, exact prompts, raw source retention, transcription, hash parity, loop treatment, human placeholder state, or the three untouched-cue hash checks.

## Numbered Assumptions and Deviation Candidates

- **A1.** The user's feedback is a `prompt-change` verdict for three slots, not final acceptance of the other slots.
- **A2.** “Same vibe” means preserve Act I world identity, D-Dorian acoustic palette, and shared motif—not preserve the v1 tempo or orchestral pressure.
- **A3.** “Echo-ey” means deliberate antiphonal orchestration and long impact tails with a dry low-frequency center, not indiscriminate full-mix reverb.
- **A4.** “Bass heavy” means stronger low-string, organ, brass, and drum energy with controlled articulation; it does not authorize electronic sub-bass.
- **A5.** The strongest configured music tool exposes only “latest available backend”; provenance must continue recording the unexposed model and seed rather than inventing them.
- **D-MUSIC-5 candidate.** If any source is shorter than 164 seconds before the four-second loop overlap, regenerate that slot once before accepting it.
- **D-MUSIC-6 candidate.** If speech detection finds any segment or text, reject and regenerate that slot; do not edit the transcript.
- **D-MUSIC-7 candidate.** If the tool again writes MP3 bytes to a `.wav` destination, preserve and record the observed codec as before.

## Generation Outcome

The selected Act I BGM source measures 178.155042 seconds. Its loop-treated shipping asset measures 174.155042 seconds at −17.9 LUFS and −6.1 dBFS true peak. The selected Act III boss source measures 176.639958 seconds; its shipping asset measures 172.640000 seconds at −17.9 LUFS and −6.6 dBFS true peak.

**D-MUSIC-5 activated.** The first Act III BGM regeneration measured only 110.785250 seconds and was rejected. Its raw bytes are retained at `assets/music/sources/rejected_act_3_abyssal_vault_bgm_short.mp3.source` with SHA-256 `8a1ca434b7b99ab4389b2e5a2a666c2e27ee516015c776d33858960be470ca7e`. The selected retry measures 167.575458 seconds before loop treatment and 163.575521 seconds after the four-second overlap.

**D-MUSIC-7 observed again.** All three generation calls returned MP3-encoded 44.1 kHz stereo bytes despite `.wav` destinations. Provenance records the observed codec; selected raw bytes are retained under `.mp3.source` names.

**D-MUSIC-8 added.** The Act III raw generations contained the requested low-register orchestration, but deterministic measurement showed the selected BGM still had less absolute sub-220 Hz energy than revision 1. Before the shared loop/loudness pipeline, Act III BGM received the documented low shelf `bass=g=4:f=180:w=0.7`; Act III boss received `bass=g=3:f=180:w=0.7`. After normalization, BGM sub-220 Hz mean level increased from revision 1's −22.1 to −21.1 dBFS; boss increased from −24.7 to −21.3 dBFS. This is a reproducible asset-processing correction, not an unverifiable prompt claim.

All three selected raw sources produced empty speech-to-text results with zero segments and duration parity. The three replacement assets are mutually unique and remain `placeholder: true` for final human listening.

## Preflight Lint

- **Contradictions:** pass; each replacement has one emotional target, one harmonic center, one rhythmic identity, and an exact loop return.
- **Pinned parameters:** pass; duration, BPM, mode, meter, instrumentation, spatial behavior, processing, placeholders, and unchanged cues are explicit.
- **Exactness and integrity:** pass; byte hashes and probes own machine facts, while subjective feedback remains human-owned.
- **Scope hygiene:** pass; no runtime or test edits are needed, and only three logical slots change.
- **Falsifiability:** pass; file counts, hashes, codecs, sample rates, channels, durations, loudness, silence, transcription, loops, untouched-cue stability, and placeholder state can all fail.
- **Dependencies/offline fallback:** pass; generator, ffmpeg/ffprobe, speech-to-text, Godot 4.7.1, and the checked-in processing/gate scripts are present. A generation outage stops the lane rather than substituting synthetic music.
