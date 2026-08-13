# AUI-11 Agent E S1 Production Packet Claim

## Claim

- Status: `production_packets_ready_pending_terminal_receipt`
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

Agent E will push one clean terminal lane and write the immutable `AUI-11-TERMINAL-RECEIPT.json` in the durable external AUI-11 project-docs workspace.

The receipt schema is `mgs.lane-terminal-receipt.v1`. Agent E will not fetch, merge, rebase, edit shared ledgers, form exact U, or publish master after launch. Agent F alone authenticates exact B+C, composes `B + terminal AUI-11 lane`, projects shared ledgers, runs fresh exact-union RELEASE/audit, and publishes without force push.

## Production result

All seven planned packets are staged under `staging/character-vfx/aui-11/`. The directory contains six GPT Image 2 masters, 56 native source frames, seven strict AUI-34 specs, and seven canonical four-file packets. `batch-manifest.json` binds each tracked byte and records the unchanged runtime/final-art barriers.

Python 3.12.3/Pillow 12.3.0 and Godot 4.7.1 each built every packet twice from the staged repository inputs. The cryptographically bound differential passed 133 build/differential assertions; the self-regenerating repository-copy verifier rebuilt all 28 runs and passed 1,464 checks. All seven final atlas/contact pairs passed visual review. The initial attack-hit packet remains recorded as red because it resembled a four-point flare; its replacement directional slash packet passed independent focused review.

The first terminal package audit returned `REVISE` for four evidence gaps without finding a production-byte defect. Remediation now preserves and hash-chains the pre-compression attack-hit frames, binds every dual-backend run to sources/specs/outputs and the final manifest, validates the complete Git diff plus both provenance records, and independently measures the Charmed binding bands, tabs, knot, unchanged alpha, and grayscale separation. Both independent semantic oracles rerun from the staged verifier and must reproduce their tracked receipts exactly.

## Tracked evidence

| Surface | Path |
| --- | --- |
| Packet contract and runbook | `docs/art/character-vfx/AUI-11-production-packets.md` |
| Canonical batch manifest | `staging/character-vfx/aui-11/batch-manifest.json` |
| QA package | `staging/qa/character-vfx/aui-11/` |
| Character provenance | `staging/provenance/characters/aui-11/batch-provenance.json` |
| VFX provenance | `staging/provenance/vfx/aui-11/batch-provenance.json` |

## Boundary retained

No runtime manifest, runtime sprite, scene, view, model, save/replay, localization, threshold, shared ledger, feature status, or human-final flag changed. Agent F must authenticate the terminal receipt and form the exact union before any runtime adaptation or publication.
