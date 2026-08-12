# TD-009 — Three-cue soundtrack regeneration v3 handoff

- Agent / branch: AGENT 4 / `agent-4/music-revision-v3`
- Base: `master` at `a46fe9ca0e18abafaf011c8f1f1d487d9c65cfa3`
- Frozen implementation: `08ff849aa555f6676099c14d9e2f740353c20de2`
- Tree: `4611d8b9e86e2390672f6d6f11805ac689a462ba`
- Primary owner / route: `godot-2d-art-audio` / STANDARD
- Status: machine-conformant candidate; human acceptance remains open

## Outcome

Act I BGM was regenerated at 60 BPM with a sparse guitar/flute chamber palette and deliberately reduced activity. Act III BGM was regenerated as a 58 BPM C-Phrygian pressure drone with continuous acoustic low-register mass. Act III boss was regenerated as that same vault-pressure identity transformed by massed brass and taiko/odaiko war rhythm at 116 BPM. Act I boss and both Act II cues remain byte-identical to the base. Runtime playback, SFX, simulation, stages, tests, harness, engine/export, verification contracts, and thresholds were untouched.

All three raw sources were generated once and fell inside the predeclared duration band. Raw speech-to-text returned empty text and zero segments. The deterministic four-second loop and loudness pipeline produced 168.434229, 175.435104, and 172.326542-second stereo 48 kHz Ogg Vorbis files at −17.9 LUFS. All six catalog entries remain `placeholder: true`, and the playable build remains silent under `D-SFX`.

## Objective evidence

The unchanged structural music gate passed all six cues and their prompt/source/transcription/provenance links. Focused catalog GUT passed 3/3 tests and 239 assertions. The frozen local full ladder passed 65/65 rungs with 20 passing scenario reports, zero failed checks, zero required pixel skips, 67 fresh screenshots, all bots, and all quality gates. The v2 evidence record is `docs/media/TD-009-verification.json`, schema-valid against the active canonical verification schema.

External signal analysis supports the requested direction without claiming taste: Act I mean spectral flux fell 19.3%, onset proxies fell by 44.24 per minute, and upper-band share fell; Act III BGM low-band share rose 22.0%, variability fell, and its low-band floor rose 6.96 dB; Act III boss low-band share rose 4.0% and onset proxies rose 9.4% versus revision 2, while exceeding the paired BGM's onset and low-mid proxies.

## Numbered deviations

1. `D-MUSIC-4` persists: the tool accepted `.wav` paths but returned MP3-encoded 44.1 kHz stereo bytes. Provenance records the observed source format; shipping assets are deterministically converted.
2. `D-MUSIC-9`: the first bounded Act III shelves (+6 dB BGM, +5 dB boss at 180 Hz) were rejected because both did not exceed revision-2 low-band measurements. Final accepted deterministic shelves are +12 dB BGM and +7 dB boss at 180 Hz. Final sub-220 Hz means are −20.8 and −21.0 dBFS versus revision-2 −21.1 and −21.3 dBFS.
3. No generation retry was needed. Mood, simplicity, drone, pressure, brass, taiko, epic scale, loop feel, fatigue, gameplay space, originality, and licensing remain human-only judgments.

## Next action

TD-004 remains the only acceptance gate for these candidate bytes. A human should listen to all six cues, with particular focus on whether Act I now feels genuinely simple and peaceful, whether Act III BGM sustains oppressive drone pressure without mud, and whether Act III boss audibly adds recognizable brass and taiko while remaining coherent with the BGM. Do not clear placeholders or add runtime routing without that verdict and a separately scoped verified change.
