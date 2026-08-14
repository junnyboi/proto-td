# AUI-20 Retirement and Supersession

- **Decision owner:** Poseidon
- **Executed by:** Manus AI
- **Effective:** 2026-08-13
- **Status:** Retired before implementation; all claimed paths released
- **Retirement base:** `8e6b0fa52faa935bc32f810c5048b43b61bb1132`
- **Retirement tree:** `1ef2e07cd9763725a91550e73b1c33e77fb5859a`
- **Canon authority:** *Protos World and Lore Bible* 3.3, SHA-256 `da442ced518da9d4690e2dcb381120bb17aaf9d822ffc71b016ff74762e3e2aa`

## Decision

AUI-20, **Integrated S1 slice and kill-gate verdict**, is retired before implementation. Its narrow experiment—binding one representative 192 px operator/enemy pair into an S1 presentation slice—no longer answers the next product question. Protos now needs a canon-comprehension tranche across the full Act I player flow, while the owner has also directed a separate evaluation of XCOM-like turn-based tactical combat.

Every path claimed by AUI-20 is released. No AUI-20 runtime, art, model, scene, test, threshold, localization, verification-entrypoint, or `FEATURES.json` byte was implemented.

## Preserved history

The following remain in Git as historical inputs, not active implementation authority:

- `docs/decisions/AUI-20-REPRESENTATIVE-FIXTURE-AUTHORIZATION.md`;
- `docs/decisions/AUI-20-CURRENT-MASTER-REBASE.md`;
- remote branches `agent-f/aui-20-claim`, `agent-f/aui-20-fixture-amendment`, and `agent-f/aui-20-rebase-claim`;
- the approved fixture contract and its approval record.

The fixture authorization does not grant future runtime binding. Any reuse requires a new task, a current-base claim, and acceptance appropriate to the new feature.

## Verification

Before this docs-only retirement, current master passed the unchanged default gate: 35/35 rungs, `ALL GREEN`. Baseline stdout SHA-256 is `7709b69cc4360ef31c8ec3abdc2b334f562519f5a1cdffcfbe7a1c915a2fca95`; `artifacts/verify.json` SHA-256 is `75dd641a49ac1801e232271a848d97389abc50b707bdf1093f70a10f642d417a`.

## Successor boundary

This decision authorizes no successor implementation. The external E1 Canon Comprehension execution plan and the tactical-combat proposal each require their own current-base orientation, scope, proof, and feature-ledger entry when work starts. AUI-20 cannot be silently reactivated or merged into either successor.

## 2026-08-14 tactical-retirement addendum

E1 Canon Comprehension landed. The isolated G1–G3 turn-based tactical greybox was then stopped because it changed Protos too far from its intended Arknights-style tower-defense RPG identity. No tactical-greybox byte entered this repository. Its standalone repository, Git history, plans, audits, screenshots, verification outputs, and source bundles were consolidated into the external archive `protos-tactical-greybox-retired-2026-08-14.tar.gz` with SHA-256 `968953873e07ac8c1c87d590437aeab8417eb0105dfd027a1a8c39599fdff430`, then removed from active workspaces. Future combat work must extend the original continuous wave, deployment, blocking, DP, skill, trap, spell, and Charm systems.

## Rollback

Reverting the retirement commit restores only the old claim text; it does not make its stale base, plan, or runtime authorization current. A real reactivation still requires an explicit owner decision and a fresh claim from current master.
