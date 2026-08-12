# D-SFX — Deliberately silent build

- Date: 2026-08-11
- Owner: human
- Status: active deviation

The game intentionally contains no SFX and no music. Do not restore synthesized SFX, add audio assets, or log silence as a defect unless the owner explicitly reopens audio. The `sfx_played` telemetry seam remains as event-wiring evidence.

Authoritative references: `FEATURES.json` deviation `D-SFX`, `FINAL_REPORT.md` §9, `PLAYTEST.md` setup/audio notes, `JUICE_VERDICT.md`, and `CLAUDE.md` audio section.

Restoration recipe if reopened: `git show 81ec642^:tools/gen_sfx.gd`.
