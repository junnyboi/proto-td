# Premium Gacha Reveal, Pity, and Marks Tuning

- [x] Synchronize clean `master` with `origin/master` and verify Godot 4.7.2.
- [x] Audit current deterministic pull, command ledger, save migration, reward tables, and gacha UI animation seams.
- [x] Document the 5-star rarity contract, hard-pity reset semantics, non-5-star outcome, and deterministic seed inputs.
- [x] Model campaign Marks earned, cumulative pulls, and pity access by stage.
- [x] Implement pity counters and checksum-preserving migration for existing premium saves.
- [x] Implement deterministic natural 5-star and forced 10th-pull outcomes.
- [x] Tune stage-clear and milestone Marks so progression supports the intended pull cadence without unlimited farming.
- [x] Build a skippable, input-safe premium pull reveal with reduced-motion support.
- [x] Surface pity progress, odds, costs, reward outcome, and next guarantee in the gacha UI.
- [x] Add deterministic migration, pity, economy, animation-state, and UI regressions.
- [x] Run focused tests, full headless import/boot, Xvfb desktop and portrait validation, and error scans.
- [ ] Fetch and integrate concurrent `master` changes, rerun both feature sets, and push directly to `origin/master`.
- [ ] Export a matching Godot 4.7.2 Web bundle, refresh the existing preview, verify network/runtime integrity, and checkpoint the live version.
