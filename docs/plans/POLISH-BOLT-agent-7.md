# POLISH-BOLT — AGENT 7 Lane Contract

- Branch: `agent-7/polish-bolt`
- Base: `master` at `f65498a15a2375f3d71450441a372c0705cbf7ce`
- Goal: accepted Bolt casts produce a manifest-resolved, render-frame-aged impact centered on the authoritative target cell, with no combat or audio change.
- Canonical plan: `/home/ubuntu/project-docs/prototype-td/agent-7-polish-bolt-companion.md`

## Pinned behavior
1. Accepted CELL casts immediately record `last_cell_spell_id` and `last_cell_spell_target`; rejected casts mutate nothing.
2. The view edge-detects the accepted spell cast count, never UI or wall-clock state.
3. `vfx_bolt_impact` is four 32×32 hard-alpha TD32 frames, displayed at the project’s normal 2× integer art scale for 12 render frames; its manifest flag stays `placeholder=true` until an L7 human accepts it.
4. `charm_runback` proves the existing raw Bolt input path, active→expired state, exact-WHITE pixel presence→absence, and current-run screenshots.
5. D-SFX remains in force: no sound asset or audio behavior is added.

## Exclusive files
`sim/battle_model.gd`, `sim/battle_hash.gd`, `test/test_spells.gd`, `test/test_hash_paranoia.gd`, `data/juice_config.gd`, `data/juice_config.tres`, `scripts/view/battle_view.gd`, `scripts/view/juice_layer.gd`, `tools/gen_assets.gd`, `assets/manifest.tres`, `assets/sprites/vfx_bolt_impact_{0..3}.png` plus `.import`, `docs/art/source/bolt-impact/bolt_impact_{0..3}.png` plus `.import`, `docs/art/source/bolt-impact/provenance.json`, `docs/art/source/bolt-impact/normalize_bolt.py`, `selftest/scenarios/charm_runback.gd`, this plan, the AGENT 7 handoff/evidence files, and claim/closure rows in the shared ledgers.

## Do not touch
`scripts/verify.sh`, `playtests/thresholds.json`, spell damage/radius/cooldown data, tick order, Charm, boss-hit behavior, audio policy/assets, bots, or unrelated VFX.

## Gates
L1 touched GDScript → focused spell/hash tests → `scripts/verify.sh --scenario=charm_runback --windowed` → current-run PNG checklist → `scripts/verify.sh --full` → adversarial diff-vs-plan read → merge-current-master and rerun before push/integration.
