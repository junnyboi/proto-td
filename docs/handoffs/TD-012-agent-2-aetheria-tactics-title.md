# TD-012 — Aetheria Tactics Product Identity Handoff

- Agent / branch: AGENT 2 / `agent-2/aetheria-tactics-title`
- Base: `master` at `3936eeda3e25c5f45def229b168fd11c41a048d9`
- Commits: `1d3781f` — claim TITLE-1/TD-012; `17017cf` — rename application, localized title, tests, scenario, and current identity headers
- Scope: the Godot application name, desktop window title, live title label, `ui.game_title` en-US catalog entry, and current product-facing document headers now use exact identity `Aetheria Tactics`; the sole Start flow is unchanged
- Non-goals: repository/worktree paths, hosted URLs, historical plans/handoffs/evidence, simulation/save/hash/replay identifiers, non-English localization, one-choice Settings UI, title-screen artwork, gameplay, thresholds, and verifier behavior did not change
- File ownership: product changes are `project.godot`, `autoloads/i18n.gd(.uid)`, `localization/en-US.json`, `localization/README.md`, `scripts/ui/title.gd`, `selftest/scenarios/boot.gd`, `test/test_i18n.gd(.uid)`, `CLAUDE.md`, `FINAL_REPORT.md`, `PLAYTEST.md`, `assets/music/README.md`, and `docs/README.md`; coordination changes are `FEATURES.json`, `docs/todo.md`, `docs/completed.md`, and this handoff; reservations release after integration
- Verification: targeted localization GUT and headless/windowed `boot` passed; tracked-title allowlist found zero unexpected aliases; frozen implementation `17017cf74052e007f372dda5c3e9046f8e974d2b` passed fresh `xvfb-run -a scripts/verify.sh --full` with 65/65 rungs in 149 seconds; evidence is external under `aetheria-tactics-agent-2/`
- Docs: TD-012 moved from `docs/todo.md` to `docs/completed.md`; TITLE-1 is passing at `17017cf`; the exactness plan, localization review, visual review, screenshot, logs, and orientation are external under `aetheria-tactics-agent-2/`; no decision or threshold change was required
- Risks: `en-US` is the only product-pinned locale, so this batch exposes `supported_locales()` / `set_locale()` but deliberately does not add a one-choice Settings selector; the title background remains intentionally plain and lore/world-art expansion is separate future scope
- Next action: `git fetch --all --prune && git merge origin/master`, resolve only semantic conflicts on this branch, rerun required gates, push the branch normally, fast-forward verified `master`, run its full gate, and push without force
