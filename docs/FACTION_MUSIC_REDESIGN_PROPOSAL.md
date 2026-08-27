# Protos Faction Music Redesign Proposal

**Author:** Manus AI

**Status:** Implemented Lunaris launch contract; future factions remain gated

**Scope:** Staging, campaign, battle, boss, and gameplay transition music

**Protected asset:** *Astra Memoriam* remains unchanged pending the scheduled listening review; this document does not authorize runtime audio replacement

## Executive decision

This is a technical music-direction record, not an independent narrative authority. The sole story authority is [`NARRATIVE_CANON.md`](./NARRATIVE_CANON.md). Existing runtime audio remains in place unless the scheduled listening review finds a clear conflict and a separately approved replacement preserves every cue ID and runtime contract.

The previous six act-based battle tracks were removed because their sound did not support the game's presentation or faction separation. The replacement Lunaris launch score is now implemented across staging, S1–S8, the Gatecrasher boss, and results. *Astra Memoriam* remains unchanged and exclusive to loading/title; Company Command begins the separate Memory Orbit vocabulary after title playback stops.

The replacement score should not be another set of generic act tracks. **Music remains a faction-authored tactical system.** Each faction receives a protected motif, instrumental palette, rhythmic grammar, harmonic behavior, and spatial identity derived from the faction production documents and references.[1] [2] [3] Current launch content is Lunaris-led, so implementation should first complete the entire playable Lunaris campaign score. Solcrest, Crimson, and Vesper suites should be produced when their corresponding playable content is scheduled; the design system below prevents those later releases from collapsing into palette-swapped versions of Lunaris.

> **Score thesis:** one premium science-fantasy world under the pressure of the Anima War. Lunaris protects and recovers unique human souls, Solcrest links disciplined formations, Crimson converts motion into breach force, and Vesper wins through hidden routing. PROTOS answers them with corrupted digital voices, stolen-soul tension, and imperial industrial scale.

## Scope boundary and removal baseline

The following audio remains approved:

| Surface | Approved state |
|---|---|
| Loading | Existing visual loading experience; no new music is introduced |
| Title | *Astra Memoriam* and its persistent ON/OFF setting remain unchanged pending listening review |
| Staging / Company Command | `lunaris_staging_archive_command` approved and integrated |
| Mission, squad, roster, training, gacha, Valhalla | Company Command loop continues without restart across command surfaces |
| Battle | Stage-authored Lunaris low/medium/high profiles approved for S1–S7 |
| Boss phases | Dedicated Gatecrasher suite approved for S8; result stingers route after terminal state |

Deleted material includes all `act_1_*`, `act_2_*`, and `act_3_*` Ogg streams, their import metadata, their catalog entries, the act-pack builder, download harnesses, runtime downloader/cache/mounter, transfer-status UI, and obsolete `music_act`/`music_boss_wave_index` stage metadata. This avoids carrying aesthetically rejected material or architecture that encodes the rejected three-act score model.

## Score language under the Anima War

The Anima War requires adult, premium anime science-fantasy with monumental composition, precise materials, selective glow, and clear faction silhouettes.[1] [3] The score should apply the same separation discipline to rhythm, timbre, harmony, and space while making the conflict audible: PROTOS is a corrupted rogue AI; farms, refineries, and foundries turn stolen **anima—the real and unique human soul** into imperial power. Processed anima suggests violet-magenta pressure through strained spectral clusters, compressed voices, and routed pulses. Free or rescued souls suggest singular warm or pale-blue lines through exposed human breath, solo strings, or glass tones. These meanings must remain distinguishable without relying on artwork.

| Faction | Protected sonic thesis | Staging grammar | Battle grammar | Boss transformation | Must not become |
|---|---|---|---|---|---|
| **Lunaris Reliquary — Soul Recovery** | Chamber-orchestral ritual, singular human breath, protective glass colors, circular clockwork, and controlled gravity | 62–76 BPM; cello pedal, harp/celesta fragments, brushed metal, sparse choir breath | 112–128 BPM; stable four with 3+3+2 or 5+3 inner orbit, strings and harp, restrained gravity sub | 76–84 BPM half-time with double-time subdivisions; motif inverted and compressed into bass | Sleepy moon ambience, generic sacred fantasy, EDM, trailer saturation, or a copy of *Astra Memoriam* |
| **Solcrest Accord — Dawn Phalanx** | Warm civic orchestra and restrained golden synthesis assembled as linked defensive planes | 76–88 BPM; low strings, bass clarinet, bronze pulse, incomplete horn answers | 116–132 BPM; square tactical grid, interlocking 3+3+2, formation layers, earned rally peaks | 138–150 BPM surface motion or 72–75 half-time; fragmented formation rebuilt into unified cadence | Medieval-paladin cliché, passive fortress drones, endless fanfare, lunar reverence, or siege aggression |
| **Crimson Aegis — Breach Caravan** | Dry precision-siege ensemble accumulating momentum toward gold-edged impact | 94–102 BPM; segmented bass, tom heartbeat, cable/ratchet detail, restrained brass inhale | 128–136 BPM; 3+3+2 forward wedge, clipped brass, low-string engine, recoil gaps | 140–148 BPM over 70–74 half-time; extended low-brass mass and controlled phrase fracture | Barbarian drums, metal swagger, indiscriminate industrial noise, heroic march, or sacred geometry |
| **Vesper Circuit — Midnight Relay** | Precision-noir chamber electronica built from hidden routes, split signals, and strategic silence | 72–88 BPM; felt piano, bass clarinet, isolated clicks, filtered city depth | 116–132 BPM; crisp relay pulse, displaced eighths above a dependable downbeat, routed counterpoint | 136–150 BPM or 72 half-time; false pickups, phase offsets, interference, then exposed unison | Synthwave nostalgia, EDM, wall-to-wall glitch, horror insects, lounge-spy parody, or heroic brass |

These identities follow the faction roles, symbols, materials, silhouettes, and environments established by the faction production system.[1] [2] The current roster remains Lunaris-led, and the music must not imply that the three future faction projections are already playable or narratively present.[4] The eight launch missions increase tactical complexity from setup through multi-front pressure to the Gatecrasher boss column, so score escalation must remain modular and readable rather than behave like a linear cinematic album cue.[5]

## Motif system

Each faction owns one short motif that can survive staging, battle, boss, mobile speakers, and horizontal transitions. **There is no universal faction melody and no all-faction finale.** *Astra Memoriam* remains the only title statement and is not quoted, reharmonized, stem-separated, or used as generative reference material.

| Faction | Motif | Functional transformation |
|---|---|---|
| Lunaris | **Memory Orbit:** upward minor-sixth outline, upper neighbor, lower semitone, return | Incomplete glass/cello fragment in staging; split viola/harp ostinato in battle; compressed inversion in boss bass |
| Solcrest | **Dawn Phalanx:** repeated anchor, rising fourth, two-step bridge, decisive return | Antiphonal preparation; interlocking battle imitation; threatened compression followed by restored unison |
| Crimson | **Spearhead:** scale degrees 5–4–♭2–1 in a short-short-long-long profile | Withheld final in staging; complete impact in battle; stretched half-time brass with controlled rhythmic fracture |
| Vesper | **Relay:** pitch classes 0–1–6–5, two mirrored semitone pairs across a tritone | Disconnected signals in staging; routed ostinato in battle; decoy shadows removed until exposed boss unison |

## Current launch soundtrack plan

The first implementation target is a **complete Lunaris campaign score**, because the authored roster, staging identity, and launch campaign belong to the Lunaris Reliquary.[1] [4] Rather than recreating the removed two-tracks-per-act model, the launch score uses mission function and adaptive intensity.

| Cue ID | Surfaces | Duration / grid | Musical role | Runtime behavior |
|---|---|---|---|---|
| `lunaris_staging_archive_command` | Company Command, mission selection, squad selection, roster/training, Valhalla | 150 s, 70 BPM, 4/4 | Tense rescue planning: incomplete Memory Orbit, singular cello line, harp/celesta, brushed mechanisms, and distant imperial pressure | Seamless loop; starts only after staging is ready; no combat percussion |
| `lunaris_battle_orbit_early` | S1 First Stand, S2 Tempo, S3 The Choke | 168 s master, 120 BPM, 4/4 | Introduces pursuit and stolen-soul pressure while preserving player-learning clarity | One generated master segmented into aligned low, medium, and high 16-bar loops |
| `lunaris_battle_air_raid` | S4 Air Raid | 168 s master, 126 BPM, 4/4 with 3+3+2 inner motion | Adds hunter-drone pressure, corrupted signal fragments, faster glass routing, and sharper counter-rotation | Three horizontal intensity loops plus one elite-entry transition; no separate generic boss track |
| `lunaris_battle_gravity_lattice` | S5 High Ground, S6 Turncoat, S7 Full Kit | 168 s master, 124 BPM, 4/4 with selective 5+3 | Denser rescue-versus-imperial counterpoint, lower foundry weight, and less instructional space | Three horizontal intensity loops; high state remains recoverable after pressure drops |
| `lunaris_boss_gatecrasher` | S8 The Gatecrasher boss phase | 180 s, 80 BPM half-time / 160 subdivision | Compressed inverted Memory Orbit against a soul-fed imperial bass, contrabass winds, restrained brass, and processed choir clusters | 12 s reveal, phase A/B/C loop regions, break-state transition, victory release |
| `lunaris_result_victory` | Clear result | 6–8 s | Bright modal recovery without title-scale coronation | Non-looping and SFX-safe |
| `lunaris_result_defeat` | Failed result | 6–8 s | Suspended reduction, not funeral music | Non-looping and non-revivifying |
| `lunaris_wave_transitions` | Wave, elite, leak danger, operator loss | 1–4 s each | Compact mechanic confirmations voiced in Lunaris grammar | Quantized at the next safe beat/bar; never blocks simulation |

### Why horizontal adaptive states first

Lyria 3 Pro should generate one continuous master per battle family with low, medium, and high sections on a locked tempo and bar grid. Post-production then extracts and loop-closes each section. This produces more reliable thematic and tempo continuity than asking a generative model for independent phase-aligned stems. The runtime crossfades among horizontal loops at authored bar boundaries. True vertical stems may replace this system later if they are arranged from a common session and verified sample-aligned.

## Lyria 3 Pro production prompts

All generation uses **Lyria 3 Pro or its latest successor**. Every prompt must request original material, carry the exact duration first, use explicit timestamps whose final mark equals the requested duration, and prohibit imitation of *Astra Memoriam* or any known franchise score.

### Company Command staging master

> Instrumental only, no lyrics or vocal solo. Create a 150-second seamless-loop staging track at 70 BPM in D minor, 4/4. Original premium chamber-orchestral science fantasy for Company Manus operating through the Lunaris Reliquary: elegant, adult, moonlit, strategic, controlled, and tense beneath the scale of a soul-powered robot empire. Use intimate cello and viola, concert harp, sparse celesta and glass mallets, prepared soft piano, brushed-gold metallic ticks, smooth gravity sub-bass, restrained analog harmonics, and only a distant wordless adult choir breath as an occasional texture. Establish an original five-note Memory Orbit motif that leaps upward toward a minor-sixth outline, circles the arrival with upper neighbor and lower semitone, then returns. Do not quote, imitate, reharmonize, or resemble Astra Memoriam. No combat drums, no EDM, no trailer braams, no generic fantasy, no constant glitter, no horror choir, no fade-out. Wide but controlled dark-hall space, centered motif and bass, clean 1–4 kHz UI space. [0:00–0:24] cello pedal and incomplete glass motif, intensity 2/10. [0:24–0:58] harp circles and brushed mechanism enter, intensity 3/10. [0:58–1:34] divided strings create poised orbital counterpoint without climax, intensity 4/10. [1:34–2:06] reduce to cello, harp, and distant breath, intensity 3/10. [2:06–2:30] restore the exact opening harmony, ambience, and pickup for a seamless loop, intensity 2/10.

### Early-campaign adaptive master

> Instrumental only, no vocals. Create a 168-second adaptive battle master at 120 BPM in D minor, 4/4, with an exact tactical downbeat and 3+3+2 inner grouping. Original premium Lunaris chamber-orchestral science fantasy: controlled gravity, ritual geometry, individual souls under threat, corrupted PROTOS signals, and elegant tactical propulsion. Use divided viola and cello ostinati, harp, sparse celesta, tuned toms and frame drums, bass clarinet, restrained French horns, smooth mono gravity sub, and selective brushed metal. Use the original Memory Orbit motif; do not resemble Astra Memoriam or any known game score. No EDM drop, no taiko wall, no constant choir, no generic trailer, no terminal cadence. [0:00–0:52] low state for setup and early waves, sparse pulse and incomplete motif, intensity 3/10. [0:52–1:44] medium state adds interlocking strings, tuned toms, and full motif, intensity 5/10. [1:44–2:36] high state adds bass gravity, horn support, and upper glass counter-rotation while retaining SFX space, intensity 7/10. [2:36–2:48] return to the exact low-state harmony, pulse, ambience, and pickup for loop extraction, intensity 3/10.

### Air Raid adaptive master

> Instrumental only, no vocals. Create a 168-second adaptive aerial-pressure battle master at 126 BPM in D minor, 4/4 with a clear tactical downbeat and 3+3+2 orbit. Original Lunaris science-fantasy scoring: precise, elegant, airborne, dangerous, and controlled, with hunter-drone signals cutting across protected individual-soul lines. Use agile violas, harp harmonics, glass mallets, bass clarinet, tuned toms, restrained low brass, smooth gravity sub, and narrow high-frequency orbital echoes. Transform the Memory Orbit motif into ascending intercept gestures without copying Astra Memoriam. Avoid frantic anime rock, EDM, wall-to-wall percussion, aviation cliché, heroic fanfare, or dense high frequencies that mask alerts. [0:00–0:52] low interception state, intensity 3/10. [0:52–1:44] medium state with faster routed glass answers and tom pulse, intensity 5/10. [1:44–2:36] high aerial-pressure state with counter-rotating strings and restrained brass gravity, intensity 7/10. [2:36–2:48] exact low-state loop return, intensity 3/10.

### Late-campaign adaptive master

> Instrumental only, no vocals. Create a 168-second adaptive battle master at 124 BPM in D minor, 4/4 with selective 5+3 subdivision. Original premium Lunaris chamber-orchestral tactical science fantasy for collaborator exposure, command-link sabotage, and the discovery of a human farm. Use lower divided strings, viola/harp orbital ostinati, bass and contrabass clarinet, tuned toms, brushed metal, restrained horns, smooth centered sub, sparse celesta, and rare wordless choir clusters. The Memory Orbit motif should gain contrapuntal density and semitone bass gravity while remaining readable. Do not quote Astra Memoriam. No horror, no requiem, no industrial cyberpunk, no generic trailer climax, no excessive reverb. [0:00–0:52] low combined-arms state, intensity 4/10. [0:52–1:44] medium state with layered counter-orbits and firmer low pulse, intensity 6/10. [1:44–2:36] high state with compressed harmony, restrained brass, and rare processed choir architecture that suggests blended captive souls without intelligible speech, intensity 8/10. [2:36–2:48] recover to exact low-state pickup for loop extraction, intensity 4/10.

### Gatecrasher boss master

> Instrumental only, no lyrics or vocal solo. Create a 180-second boss master at 80 BPM half-time with precise 160 BPM subdivisions in D minor. Original Lunaris-versus-PROTOS boss music: monumental soul-fed imperial mass, corrupted digital inevitability, adult premium restraint, and tactical clarity. Invert and interval-compress the Memory Orbit motif into contrabass clarinet, basses, cellos, restrained bass trombone and horns; add gran cassa, tuned low toms, bowed metal, smooth sub drops, high glass warning points, and sparse wordless adult choir clusters. No Astra Memoriam quotation or imitation, no generic apocalypse, no horror liturgy, no trailer braam wall, no EDM, no final fade. [0:00–0:12] non-looping reveal with descending gravity and exposed inverted motif, intensity 6/10. [0:12–1:04] phase A recoverable loop state, intensity 6/10. [1:04–1:56] phase B shortens orbit cycles and adds escort-pressure counterpoint, intensity 7/10. [1:56–2:48] phase C strengthens semitone descent, percussion, and restrained choir architecture while preserving the downbeat, intensity 9/10. [2:48–3:00] break-state release that can transition to victory or return to phase A, intensity 5/10.

## Implemented runtime architecture

The replacement runtime should be data-driven and should not recreate the deleted hard-coded `music_act` pair. A `MusicProfile` resource should define the staging cue, battle state set, boss set, transitions, loop metadata, and faction identity. `StageDef` should reference a profile ID and optional encounter override only after the audio for that profile exists.

| Component | Responsibility |
|---|---|
| `Music` autoload | Own one player graph, title preference, bus routing, deterministic transition queue, and bar-boundary scheduling; never mutate battle state |
| `MusicProfile` | Declare faction, staging cue, battle low/mid/high cues, boss phases, BPM, meter, loop samples, transition quantization, and mix offsets |
| `MusicDirector` | Observe presentation-safe battle facts such as wave phase, pressure tier, boss state, and results state; request transitions with hysteresis |
| `AudioCue` | Reference runtime Ogg, source master checksum, loop start/end samples, loudness, true peak, and approved use surfaces |
| Stage data | Reference `music_profile_id` and optional encounter variant; never encode file paths or generic act numbers |
| Web packaging | Keep the title cue in the base PCK; package approved faction suites independently only when their playable content requires them |

The first implementation may use horizontal low/medium/high loops. State changes should quantize to one bar for danger and four bars for routine escalation, with minimum hold time and hysteresis to prevent musical chatter. Music remains presentation-only and failure must always degrade to silence without blocking navigation or simulation.

## Mix and delivery contract

| Deliverable | Production target |
|---|---|
| Master archive | 48 kHz, 24-bit WAV, lossless, with prompt/model/provenance record and SHA-256 |
| Runtime derivative | 48 kHz stereo Ogg Vorbis, loop-tested in Godot 4.7.2 |
| Staging loudness | Approximately −20 LUFS integrated, ceiling no higher than −2 dBTP |
| Battle loudness | Approximately −18 LUFS integrated, ceiling no higher than −1.5 dBTP |
| Boss loudness | Approximately −17.5 LUFS integrated, ceiling no higher than −1 dBTP |
| Tactical clarity | Keep principal warnings, SFX, and voice intelligible; reserve 1–4 kHz and avoid sustained sub occupation |
| Compatibility | Mono-compatible below 120 Hz; motif and pulse remain intelligible on mobile/tablet speakers |
| Loop QA | No click, fade, terminal cadence, ambience jump, tempo drift, or stereo-image discontinuity at the sample boundary |

Every candidate should be reviewed against the faction concept art, the affected scene in both landscape and portrait, a dense combat capture, SFX-only playback, and the complete mix. Reviewers should reject technically polished tracks that fail faction identity. Expensive generic music is still generic music; it merely invoices with confidence.

## Phased implementation plan

| Phase | Work package | Exit criteria |
|---|---|---|
| **0 — Silence and contract** | Delete rejected gameplay audio and pack infrastructure; retain title audio and preference; stop title at staging; land this proposal | Repository contains only approved title music; staging and battle are silent; tests and Web export pass; push `master` and checkpoint |
| **1 — Runtime foundation** | Add `AudioCue`, `MusicProfile`, transition scheduler, horizontal-state director, bar quantization, hysteresis, and test seams | No generated audio required; deterministic battle state unchanged; unit tests cover cue rejection, transition timing, missing assets, and silence fallback; push and checkpoint |
| **2 — Lunaris staging vertical slice** | Generate three Company Command candidates with Lyria 3 Pro, blind-review against the Anima War direction, master one loop, integrate staging and related command surfaces | Approved loop, provenance, checksums, clean title-to-staging handoff, responsive browser verification; push and checkpoint |
| **3 — Early campaign suite** | Generate and segment early battle and Air Raid masters; add low/mid/high state routing and wave/elite transitions | S1–S4 pass tactical mix review, loop tests, transition tests, and representative playthroughs; push and checkpoint |
| **4 — Late campaign and boss** | Generate late battle and Gatecrasher masters; integrate boss reveal/phases, victory/defeat, leak/operator-loss transitions | S5–S8 complete; boss phase behavior and results tails verified; full launch campaign has no placeholder music; push and checkpoint |
| **5 — Mix, accessibility, and release** | Final loudness pass, music/SFX bus controls, dynamic-range mode, mobile/mono QA, Web size/caching plan, regression and playtest sweep | All current gameplay music approved, no masked alerts, export/runtime logs clean, rollback checkpoint saved and published |
| **6 — Future faction suites** | Produce Solcrest, Crimson, and Vesper staging/battle/boss families when each faction becomes playable | Each faction passes the same narrative-alignment, mix, adaptive-runtime, and deployment gates independently; no premature lore or unused payload ships |

After every implementation phase, run the repository regression suite and focused audio tests, visually inspect representative scenes, push the completed phase to `master` without rewriting shared history, update this document and `todo.md`, save a WebDev checkpoint, and publish the verified build.

## Acceptance tests

The soundtrack redesign is complete only when all of the following are true:

1. *Astra Memoriam* is bit-identical to its approved runtime asset and plays only on loading/title surfaces.
2. The title music preference still persists across native restarts and browser sessions.
3. Navigation from title to staging stops and releases the title stream exactly once.
4. No rejected act track, import metadata, catalog entry, pack builder, download UI, or managed pack argument remains.
5. Each implemented gameplay cue declares source provenance, Lyria model version, generation prompt, edit history, master checksum, runtime checksum, loudness, true peak, and exact loop samples.
6. Every adaptive transition is bar-safe, cannot thrash, and cannot affect deterministic battle state.
7. Missing or failed audio always becomes silence without blocking gameplay.
8. Music remains legible but subordinate to tactical alerts, combat SFX, unit feedback, and UI confirmation sounds.
9. Landscape, portrait, Web, and native builds produce equivalent cue selection and clean runtime logs.
10. Narrative review confirms that the cue belongs to its faction and does not imply benevolent PROTOS, safe soul copying, or caretaker-era truth when heard without artwork.

## References

[1]: ./FACTIONS.md "Faction production directions"
[2]: ./FACTION_REDESIGN_PROPOSAL.md "Faction redesign proposal"
[3]: ./ART_DIRECTION.md "Protos art direction"
[4]: ./FACTION_ROSTER_AND_VAHALLA.md "Faction roster and Valhalla contract"
[5]: ./LEVEL_DESIGNS.md "Campaign level designs"
[6]: ./factions/UI_INTEGRATION.md "Faction UI integration"
[7]: ./audio/LUNARIS_TITLE_THEME.md "Approved Lunaris title theme"
