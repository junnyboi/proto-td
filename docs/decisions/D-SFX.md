# D-SFX — Deliberately silent SFX; approved music is active

- Date: 2026-08-11
- Owner: human
- Status: superseded for music assets and runtime music on 2026-08-12; SFX waiver remains active

The original decision made the game intentionally silent: no SFX, no music, and no silence defect. On 2026-08-12 the owner first reopened music creation, then approved the current six-cue score and explicitly requested runtime integration with one invariant: exactly one cue may play, cues must never layer, and repeated requests must never restart the same cue. TD-017 therefore authorizes the catalog-backed `Music` singleton, data-owned act/boss routing, and hard replacement on one `AudioStreamPlayer`. This does **not** restore synthesized SFX. The `sfx_played` telemetry seam remains event-wiring evidence for the still-silent SFX layer.

Authoritative references: `FEATURES.json` deviation `D-SFX`, `FINAL_REPORT.md` §9, `PLAYTEST.md` setup/audio notes, `JUICE_VERDICT.md`, `CLAUDE.md` audio section, and `assets/music/provenance.json`.

SFX restoration recipe if separately reopened: `git show 81ec642^:tools/gen_sfx.gd`.
