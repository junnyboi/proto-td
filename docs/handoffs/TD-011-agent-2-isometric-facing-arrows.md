# TD-011 — Isometric Facing Arrows Handoff

- Agent / branch: AGENT 2 / `agent-2/isometric-facing-arrows`
- Base: `master` at `3b7ba225c90add20924b5a3aef99133162f64531`
- Commits: `896318ba7b168754b7b9fa54ffb860b046ea6eaf` — claim; `2d9f351dca08158af4b8ec46ea38cc0b8be0cc32` — implementation
- Scope: replaced full-neighbor-cell cardinal controls with one fixed screen-space 2×2 cluster using `↖`, `↗`, `↙`, and `↘`; rigidly clamps the cluster inside the usable viewport; raises only the facing buttons above transient juice; adds real-input/runtime geometry coverage
- Non-goals: no model-facing enum or deploy-verb change; no simulation, balance, stage, art, map-navigation, localization, test/threshold, harness-core, or verifier change
- File ownership: changed `scripts/ui/deploy_bar.gd` and `selftest/scenarios/deploy_flow.gd`; closure records are `docs/todo.md`, `docs/completed.md`, and this handoff; all TD-011 reservations release after integration
- Verification: fresh clean `xvfb-run -a scripts/verify.sh --full` at `2d9f351dca08158af4b8ec46ea38cc0b8be0cc32` — ALL GREEN, 65/65 rungs in 151 wall seconds, 67 PNGs; targeted headless/windowed `deploy_flow` both green; external schema-valid evidence at `facing-arrows-agent-2/ORIENTATION.json`, screenshot `facing-arrows-agent-2/facing_chooser.png`, and review `facing-arrows-agent-2/visual-review.md`
- Docs: TD-011 moved from `docs/todo.md` to `docs/completed.md`; exactness plan is external at `facing-arrows-agent-2/TD-011-plan.md`; no decision or deviation required
- Risks: no machine blocker; the chooser intentionally draws above an active wave banner because an interactive placement ritual takes priority over a transient announcement. Agent 4 integrated soundtrack work as TD-009 while this lane was verifying, so the facing feature was renumbered to the first globally unused ID, TD-011, during the mandatory master merge.
- Next action: `git fetch --all --prune && git merge origin/master` on the feature branch, run routed merged-union verification, push the branch, fast-forward clean `master`, verify its merged commit, and push normally without force
