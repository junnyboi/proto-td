# TD-006 — Three-cue soundtrack regeneration handoff

- Agent / branch: AGENT 4 / `agent-4/three-cue-regen`
- Base: `master` at `690f7617acdc710855c3c8e169ad673b1fa8fec0`
- Implementation commit: `a58e2d5d41579d3f8fe0427f005dba5b14558f84` — regenerated Act I BGM, Act III BGM, and Act III boss from the 2026-08-12 human prompt-change verdict
- Scope: Act I is now a quieter 78 BPM pastoral chamber-fantasy cue; Act III BGM is resolute, echo-led, and low-register; Act III boss is defiant bass-heavy 12/8 orchestral war music. The other three cue assets and sources remain byte-identical.
- Non-goals: no runtime playback/routing, SFX, scenes, stages, autoloads, simulation, existing tests, thresholds, or `scripts/verify.sh` changes; all six cues remain `placeholder: true`
- File ownership: TD-006 reservations release after integration; exact paths are recorded in `docs/plans/TD-006-three-cue-regeneration.md`
- Verification: frozen commit `a58e2d5`; `tools/music/verify_td006.sh` and unchanged `tools/music/verify_music.sh` green; focused catalog GUT 3/3 tests and 239 assertions; `scripts/verify.sh --full` 63/63 rungs in the combined 163-second evidence run; 19 reports, 464 checks, zero skips, 64 screenshots reviewed; two-process campaign telemetry diff empty; independent audit PASS with zero findings
- Evidence: `docs/media/TD-006-verification.json`; exact prompts/sources/transcriptions/hashes are in `assets/music/provenance.json`
- Deviations: D-MUSIC-5 rejected a 110.785250-second Act III BGM attempt; D-MUSIC-7 records MP3 bytes returned to `.wav` paths; D-MUSIC-8 records deterministic +4 dB/+3 dB low shelves at 180 Hz before shared processing
- Risks: musical mood, audible echo character, war-music read, loop feel, fatigue, gameplay-space balance, originality, and commercial terms remain human-only judgments
- Next action: human completes TD-004 using the six-cue checklist, with special attention to the three replacement targets, before any placeholder flag clears
