# AUI-11 Agent E S1 Production Packet Claim

## Claim

- Status: `in_progress`
- Contract version: `aui-11.s1-production.v1`
- Owner: `AGENT 6 / AGENT E`
- Branch: `agent-e/aui-11-s1-roster`
- Frozen base commit: `9b834f54a218e3eeb77e89e014476300180dc33a`
- Frozen base tree: `3739db8445e337621eb1dc989c91c4eee5d358ba`
- External plan SHA-256: `1d2fb715be2659a88d1c2156e27d82d79c32c9a027b02914fce002f98860628e`
- Pre-dispatch contract: `mgs.serial-integration.v2`
- Named integrator: `AGENT F`

## Exact production slice

AUI-11 stages seven runtime-unbound deterministic packets through AUI-34:

1. `vanguard_1`
2. `grunt`
3. `grunt_charmed`
4. `portrait_vanguard_1`
5. `vfx_deploy`
6. `vfx_attack_hit`
7. `vfx_charm`

No runtime asset, manifest, view, scene, model, save, replay, localization, test, scenario, verifier, threshold, shared ledger, `FEATURES.json`, or final-art flag is owned by this lane.

## Exclusive paths

- `staging/character-vfx/aui-11/**`
- `staging/qa/character-vfx/aui-11/**`
- `staging/provenance/characters/aui-11/**`
- `staging/provenance/vfx/aui-11/**`
- `docs/art/character-vfx/AUI-11-production-packets.md`
- this handoff

## Approval identity

- Round 5 approval token SHA-256: `5ab42289310a3176718a2d2c4c70f91aa87041564aaac0c6652bbf3295ece93b`
- Reference-manifest SHA-256: `0389dd44621684d65636c5d4d549311ab39e090d77ca9560b7522f107162c1d6`
- Final production art remains `UNSET_HUMAN_ONLY`.
- Runtime binding remains `UNBOUND_AGENT_F_SEAM`.

## Closure contract

Agent E will push one clean terminal lane and write the immutable external receipt:

`/home/ubuntu/project-docs/Prototype TD/aetheria-production/aui-11/AUI-11-TERMINAL-RECEIPT.json`

The receipt schema is `mgs.lane-terminal-receipt.v1`. Agent E will not fetch, merge, rebase, edit shared ledgers, form exact U, or publish master after launch. Agent F alone authenticates exact B+C, composes `B + terminal AUI-11 lane`, projects shared ledgers, runs fresh exact-union RELEASE/audit, and publishes without force push.
