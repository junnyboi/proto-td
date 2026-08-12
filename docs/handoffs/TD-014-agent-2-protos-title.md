# TD-014 — Protos Product Identity Handoff

- Agent / branch: AGENT 2 / `agent-2/protos-title`
- Base: `master` at `3447024e25f0438e51295ec98fdfa02112c7e41a`
- Commits: `706c3fe` — claim TD-014 and supersede TITLE-1 acceptance; `2d61131` — rename live identity to Protos
- Scope: Godot application/window metadata, live localized title, `ui.game_title` en-US value/fallback, automated acceptance, TITLE-1 criteria, and current identity headers now use exact name `Protos`
- Non-goals: TD-013 history, repository paths, hosted URLs, deterministic state, saves, replays, gameplay, thresholds, non-English localization, one-choice Settings UI, and title artwork did not change
- File ownership: product changes are `project.godot`, `autoloads/i18n.gd`, `localization/en-US.json`, `localization/README.md`, `scripts/ui/title.gd`, `selftest/scenarios/boot.gd`, `test/test_i18n.gd`, `CLAUDE.md`, `FINAL_REPORT.md`, `PLAYTEST.md`, `assets/music/README.md`, and `docs/README.md`; coordination changes are `FEATURES.json`, `docs/todo.md`, `docs/completed.md`, and this handoff
- Verification: new expectations rejected Proto Defense before the fix; localization GUT and headless/windowed `boot` then passed; stale-title audit found zero unexpected Proto Defense references outside TD-013 history; frozen implementation `2d61131c34f1d777ede05fb8b4d5da3f7ab1c279` passed fresh `xvfb-run -a scripts/verify.sh --full` with 65/65 rungs in 149 seconds; external evidence is under `protos-agent-2/`
- Docs: TD-014 moved from active to completed; TITLE-1 is passing with historical commits `17017cf`, `366a430`, and current `2d61131`; exactness plan, reviews, screenshots, logs, and orientation are external under `protos-agent-2/`
- Risks: `en-US` remains the only product-pinned locale; TD-013 intentionally retains Proto Defense as historical truth
- Next action: fetch current master, merge it into this branch if it moved, reverify, push the branch normally, fast-forward verified master, rerun its full gate, and push without force
