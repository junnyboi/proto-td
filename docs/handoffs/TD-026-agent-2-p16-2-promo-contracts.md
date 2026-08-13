# TD-026 — P16.2-PROMO Core Handoff

**Owner:** AGENT 2

**Branch:** `agent-2/td-026-p16-2-promo-core`

**Status:** implementation complete; pending integration

## Delivered

TD-026 advances the strategic campaign schema from v1 to v2 and adds the persistent fields required by Company 33 promotion work: acquisition template, current projection, first and advanced class, progression rules version, XP, and immutable identity portrait.

Operation resolution now derives one sorted `+100 XP` row for each unique deployed survivor, applies it once to the expected strategic state, persists the receipt, and includes it in hashes and anchor reversal. Undeployed, fallen, pre-dead, and unknown heroes receive nothing. Checked overflow rejects atomically.

Canonical v1 saves are verified before migration, including their nested legacy anchor and receipt hashes. They then migrate to exact v2 bytes. Canonical v2 saves round-trip byte- and hash-exactly. The immutable v1 fixtures remain unchanged.

## Key files

- `sim/campaign_progression.gd`
- `sim/campaign_hero_codec.gd`
- `sim/campaign_migration.gd`
- `sim/campaign_legacy_hash.gd`
- `sim/campaign_codec.gd`
- `sim/campaign_hash.gd`
- `sim/campaign_invariants.gd`
- `data/campaigns/p16_v2.tres`
- `test/fixtures/p16/campaign_v2_seed42.json`
- `test/fixtures/p16/transaction_vectors_v2.json`
- `test/test_campaign_progression.gd`
- `test/test_mage_promotion_contract.gd`

## Verification

Focused strategic suites: 45/45 tests passed before the legacy-integrity remediation. The final P16 fixture suite passed 15/15 tests and 240 assertions, including independently forged and synchronously forged nested-hash cases.

Cross-process checks passed:

- model roster: two byte-identical processes;
- replay: 11 runs, SHA-256 `6f014cd5c5d792f22608bc37fac3a76c6b2728ace362a0376e6595f2285b365c`.

The first save/economy audit found that migration rewrote forged legacy nested hashes after validating only the outer checksum. TD-026 added the exact v1 core-hash validator and fail-closed migration checks. A focused re-audit passed with zero findings.

The final STANDARD result is recorded by the integration commit after the post-remediation run.

## Still deferred

The promotion command, exactly-once promotion receipt, Training terminal UI, localization, combat-template cutover, and human UI review remain separate follow-up work. Existing heroes can now store and earn the progression data those lanes require.
