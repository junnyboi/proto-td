# D-SFX — Deliberately silent SFX and runtime audio

- Date: 2026-08-11
- Owner: human
- Status: partially superseded for music assets on 2026-08-12

The original decision made the game intentionally silent: no SFX, no music, and no silence defect. On 2026-08-12 the owner explicitly reopened **music asset creation** and requested one BGM plus one boss cue for each of three planned acts. TD-003 may therefore add generated music, its logical catalog, provenance, and asset QA. This does **not** restore synthesized SFX and does not authorize provisional runtime playback before the act/boss routing contract exists. The current playable build remains silent until a separately scoped integration lane. The `sfx_played` telemetry seam remains event-wiring evidence.

Authoritative references: `FEATURES.json` deviation `D-SFX`, `FINAL_REPORT.md` §9, `PLAYTEST.md` setup/audio notes, `JUICE_VERDICT.md`, `CLAUDE.md` audio section, and `assets/music/provenance.json`.

SFX restoration recipe if separately reopened: `git show 81ec642^:tools/gen_sfx.gd`.
