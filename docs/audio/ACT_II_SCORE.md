# Act II Gameplay Score — Anima War

**Status:** Implemented and runtime-routed

**Scope:** S9–S16, one unique cue per operation
**Runtime format:** stereo Vorbis, 48 kHz, loop-enabled

## Direction

The Act II score preserves Lunaris’s glass-and-orbit science-fantasy identity while giving every operation a distinct dramatic function inside the authoritative Anima War. S9 contrasts fragile human warmth against a controlled synthetic enclosure; S10 turns falling pulse layers into accumulating rescue debt; S11 opens cold vertical space for convoy and aerial pressure; S12 encodes the Unlit’s three-lane isolation as interlocking rhythms; S13 sets a lone human-string answer against mechanical enumeration; S14 converts sacrifice into forward motion; S15 exposes processed spectral pressure without treating souls as copies; and S16 expands rigid imperial machinery into a foundry-scale boss statement. The instrumental score contains no lyrics or independent story claims.

Each cue was generated as an original instrumental composition with explicit loop-compatible opening and closing harmony, retained under `/home/ubuntu/webdev-static-assets/proto-td-act2/` as the immutable generated source plus a true 24-bit/48 kHz PCM master. Runtime files are reproducibly created by `tools/audio/process_act2_score.sh` using loudness normalization, a transparent head-tail crossfade, true-peak limiting without automatic gain, and Vorbis quality 5 encoding.

## Runtime catalog

| Stage | Cue ID | Identity | BPM | Runtime duration | Integrated loudness | True peak |
|---|---|---|---:|---:|---:|---:|
| S9 — The Green Cage | `lunaris_act2_s09_return_path` | Exposed human tone inside a controlled synthetic gate pulse | 112 | 83.38 s | −19.5 LUFS | −6.8 dBFS |
| S10 — Rain Debt | `lunaris_act2_s10_covenant_orchard` | Accumulating plucked machinery beneath falling glass figures | 116 | 85.39 s | −19.6 LUFS | −5.6 dBFS |
| S11 — The Long Convoy | `lunaris_act2_s11_choir_without_witness` | Suspended convoy space and metallic aerial-pressure accents | 124 | 85.86 s | −20.4 LUFS | −2.7 dBFS |
| S12 — Unlit | `lunaris_act2_s12_archive_orchard` | Three isolated lane rhythms converging under tactical pressure | 120 | 82.36 s | −19.2 LUFS | −4.2 dBFS |
| S13 — Thirty-Three | `lunaris_act2_s13_witness_engine` | Prepared-piano enumeration against a singular human string answer | 126 | 85.75 s | −18.4 LUFS | −3.8 dBFS |
| S14 — The Price of Dawn | `lunaris_act2_s14_residual_mercy` | Fast combined-arms pulse with restrained remembrance fragments | 128 | 84.42 s | −18.7 LUFS | −2.1 dBFS |
| S15 — Soulstorm | `lunaris_act2_s15_public_ledger` | Processed spectral pressure opposed by transparent human counterpoint | 132 | 84.92 s | −18.3 LUFS | −3.0 dBFS |
| S16 — Empire Foundry | `lunaris_act2_s16_unfinished_proof` | Half-time imperial machinery with 168 BPM tactical subdivision | 84 | 94.23 s | −18.0 LUFS | −2.2 dBFS |

All tracks remain within the accepted **−21.5 to −17.5 LUFS** gameplay envelope and at or below **−2.0 dBFS true peak** after Vorbis encoding. No file contains a detected one-second-or-longer silence below −48 dB. Runtime hashes are pinned in `docs/audio/ACT_II_SCORE.sha256`.

The cue IDs and local production filenames retain their pre-reconciliation working slugs so checksums, generated masters, and runtime references remain stable. They are not displayed to players and carry no narrative authority; stage resources and localization supply the canonical Anima War titles.

## Routing and transitions

`assets/music/catalog.tres` registers all eight cues. `lunaris_profile.tres` exposes dedicated variants `act2_s09` through `act2_s16`; each stage resource owns its matching variant. Low, medium, high, and critical presentation states deliberately retain the same stage-specific cue rather than switching compositions mid-operation. `Music.request_battle_state()` accepts those state changes without seeking or restarting the stream, preserving continuity and authored tempo while existing Act I adaptive-cue timing remains unchanged.

Act II battle entry and terminal continuation now use `Act2StageTransition`: a centered, responsive overlay built around the existing 600px GPT Image 2 repair-platform seal, operation identity, localized stage title, a dark contextual veil, and transform-scale/veil transitions. The battle model is paused locally during the overlay; global time remains active, so UI tweens and audio continue. Reduced-motion mode replaces the 1.38-second entry with a 0.18-second static hold and makes exit immediate.

## Verification contract

`act2_music_transition_test.gd` enforces eight distinct cue IDs, valid looped battle surfaces, stage-to-variant routing, cue-continuous intensity changes, unmodified authored tempo, smooth entry/exit durations, and the reduced-motion path. `music_redesign_test.gd` protects all pre-existing adaptive soundtrack behavior. Landscape 1280×720 and portrait 720×1280 Xvfb captures confirm centered, unclipped operation identity and high-resolution seal presentation.
