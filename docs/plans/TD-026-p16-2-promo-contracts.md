# TD-026 — P16.2-PROMO XP, Migration, and Save/Load Core

**Owner:** AGENT 2

**Branch:** `agent-2/td-026-p16-2-promo-core`

**Base:** `4dd4eed725e19061a7220f26ba600d1d5c9d4ab9`

**Living authority:** `Protos-World-and-Lore-Bible.md` v3.2

## Goal

Install the persistent progression foundation needed by the Company 33 Training terminal:

- deterministic hero XP;
- total v1-to-v2 class migration;
- canonical v2 save/load;
- strategic hash and nested-anchor coverage;
- immutable acquisition and portrait identity.

This lane does **not** implement the promotion command, Training UI, battle projection cutover, or content reward cutover.

## Pinned behavior

- Every current combat template has one exact v2 progression row.
- A surviving hero with at least one deployment earns `100` XP after an accepted operation.
- Undeployed, unknown, pre-dead, or newly fallen heroes earn zero.
- Duplicate outcome rows produce one sorted award row per hero.
- XP is a nonnegative signed-64-bit integer; checked overflow rejects before mutation.
- Existing v1 saves remain immutable inputs and migrate to canonical v2 bytes.
- V1 outer checksum and nested anchor/receipt hashes are validated before migration.
- New v2 saves restore and re-encode byte-exactly.
- Acquisition template and identity portrait never change when current class projection later changes.
- Progression fields and XP receipts participate in the strategic hash and anchor reversal.

## Implementation

- `CampaignProgression`: total template mapping, class projection validation, XP derivation/apply/reverse.
- `CampaignHeroCodec`: strict canonical v2 hero rows.
- `CampaignMigration`: total v1-to-v2 migration.
- `campaign_legacy_hash.gd`: exact read-only v1 core hash validation at the migration boundary.
- `CampaignCodec`: save version 2, legacy migration, v2 hero and XP receipt normalization.
- `CampaignHash` and `CampaignInvariants`: progression/receipt hashing, transaction XP, anchor closure.
- `p16_v2.tres` plus canonical v2 save and transaction fixtures.

## Acceptance

1. Contract suite is in default discovery and green.
2. All eleven migration rows match the machine-readable contract.
3. XP award, dead/undeployed exclusion, deduplication, overflow, and no-mutation properties pass.
4. Immutable v1 fresh and resolved saves migrate to exact v2 goldens.
5. Forged legacy nested hashes reject even when the attacker recomputes the outer checksum.
6. V2 restore/encode/restore remains byte- and hash-exact.
7. Cross-process replay and model-roster outputs are identical.
8. One final `scripts/verify.sh` STANDARD run is green.

## Deferred

- promotion query and command;
- exactly-once promotion receipt/retry behavior;
- class selection UI and localization;
- current-template cutover to Witch Doctor or Sorcerer;
- human Training-terminal review.
