# TD-003 — Three-Act Luminous Descent Music Catalog

## Authority and scope

The owner explicitly requested one exploration BGM and one boss cue for each planned act on 2026-08-12. This reopens music asset creation under `D-SFX` but leaves synthesized SFX and runtime playback silent. The lane is catalog-first because the repository does not yet expose the final three-act stage mapping or an authoritative boss-transition signal.

## Act contract

| Act | World | Emotional lead | Cue transformation |
|---|---|---|---|
| I — Guild Threshold | Crypt cloisters, aqueducts, garden ruins, expedition waystations | Welcoming, capable, adventurous | Warm chamber orchestra and a walking 6/8 pulse; boss version becomes tactical 12/8 |
| II — Twilight Grotto | Crystal undercroft, aquifers, fragmented observatory, monumental ruins | Wonder, archaeology, mounting threat | Crystalline acoustic colors and asymmetrical pulse; boss version becomes a 7/8 mechanism |
| III — Abyssal Vault | Obsidian vaults, chained platforms, primordial architecture, lava vents | Oppressive, vast, climactic | Monumental low orchestra and Phrygian gravity; boss version becomes volcanic 12/8 |

A new four-note descending contour, scale degrees 5–4–flat-3–2, connects all six cues. Exact final prompts are immutable provenance under `assets/music/prompts/`.

## Owned implementation

| Surface | Contract |
|---|---|
| `assets/music/*.ogg` | Six stereo 48 kHz Ogg Vorbis cues, one BGM/boss pair per act |
| `assets/music/catalog.tres` | Logical IDs resolve paths and carry act, role, prompt, hashes, loop, and human acceptance metadata |
| `assets/music/provenance.json` | Generator facts, exact hashes, processing recipe, speech result, deviations, and legal review flag |
| `tools/music/process_track.sh` | Deterministic source decode, four-second loop crossfade, −18 LUFS normalization, Ogg export |
| `tools/music/verify_music.sh` | Exact count, codec, sample rate, channels, duration, loudness, peak, silence, prompt, loop, and uniqueness gate |
| `test/test_music_catalog.gd` | Godot loadability, role pairing, loop state, duration, prompt, provenance, and placeholder assertions |

## Pinned acceptance

Exactly six unique cues must exist. Each act has one `bgm` and one `boss` logical ID. Every output is Vorbis, 48 kHz, stereo, 160–180 seconds, within −18.3 to −17.7 LUFS integrated, at or below −1.5 dBFS true peak, without at least two seconds of sub−50 dB digital silence, loop-enabled by Godot import metadata, and linked to a nonempty no-vocals prompt. Generated sources must produce empty speech transcription. Catalog entries remain `placeholder: true` until human listening verifies act fit, pair coherence, descent, seam, gameplay space, fatigue, vocal absence, and originality.

## Non-goals

TD-003 does not add a `MusicPlayer`, stage-to-act routing, boss-state transitions, runtime crossfades, bus ducking, volume UI, SFX, or edits to historical playtest/audit claims that the current build is silent. A later lane must define and test the missing observable routing contract, then consume `catalog.tres` rather than hardcoding file paths.

## Numbered deviations

- **D-MUSIC-1:** The first Act I BGM source was materially short at 162.403 seconds. One regeneration produced a selected 177.528-second source; both hashes are preserved.
- **D-MUSIC-4:** The generator accepted `.wav` paths but emitted MP3-encoded 44.1 kHz stereo bytes. Shipping assets were decoded and converted to the pinned 48 kHz Ogg format; provenance records the actual codec.

## Exit evidence

The feature branch and merged master must both pass `tools/music/verify_music.sh`, focused music GUT, `scripts/verify.sh --full`, fresh artifact integrity checks, and adversarial diff review. The completion record points to `docs/media/TD-003-verification.json` and the exact integration commit.
