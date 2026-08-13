# TD-026 — P16.2-PROMO contract scaffold handoff

**Owner:** AGENT 2

**Branch:** `agent-2/td-026-p16-2-promo-contracts`

**Base:** `a26969770a5ed57206d0751c1d0f757ac576f733`

**Status:** blocked on canonical P16.2 strategic transaction/save authority

## Outcome

The requested Company 33 Mage promotion lane has begun at the deepest lawful boundary available on current master: exact machine-readable contracts plus executable red-first tests.

Production model code was deliberately not changed. Current master still has immutable P16.1 `CampaignState`, `CampaignCodec.SAVE_VERSION == 1`, no accepted strategic command ledger, no promotion transaction, and no hero progression fields. The governing companion plan forbids promotion mutation until the P16.2 base checkpoint lands.

## Frozen contract surface

- Company 33 Mage Apprentice source class.
- Exclusive permanent destinations in canonical order: Witch Doctor then Sorcerer.
- Current projections: `witch_doctor_1` and `caster_2`.
- 400-XP threshold, zero Marks, excess XP preserved.
- Complete exactly-once XP matrix for CLEAR, DEFEAT, retreat, undeployed, dead, already-promoted, duplicate, and overflow cases.
- Signed-int64 nonnegative XP with checked addition and whole-resolution `xp_overflow` rejection.
- Total exact v1-to-v2 migration over all eleven current templates.
- Immutable acquisition template, identity portrait, first class, recruitment provenance, callsign/history, life/death, rules version, and XP.
- Exact normalized command ID, key order, receipt order, retry/conflict/stale/post-commit behavior, cancellation, reject equality, and strategic replay-v2 shape/goldens.

## Evidence

### Fresh base

On base `a26969770a5ed57206d0751c1d0f757ac576f733`:

```text
scripts/verify.sh
R2 import PASS
R2.5 stage lint PASS
R3 GUT PASS
R3.5 replay PASS
R3.5 model-roster PASS
R3.6/R3.7 filesystem PASS
all 28 R4a scenarios PASS
ALL GREEN
```

### Manual red-first suite

Command:

```bash
$HOME/bin/godot --headless -d -s addons/gut/gut_cmdln.gd \
  -gtest=res://test/wip_mage_promotion_contract.gd -gexit
```

Measured final signature:

```text
4/6 passed
contract fixture tests: 4/4 PASS
dependency tests: 0/2 expected RED
- CampaignCodec.SAVE_VERSION is 1, required >= 2
- CampaignState/HeroState promotion surfaces are absent
```

The file begins `wip_`, not `test_`, so default GUT discovery excludes it. This is intentional and verified.

### Default gate with scaffold present

```text
scripts/verify.sh
R3 GUT PASS (272/272; WIP suite absent)
all remaining standard rungs PASS
ALL GREEN
```

### Independent review

- Audit 1: FAIL; found incomplete migration/XP/command executable pins.
- Remediation: fixture and WIP suite expanded to complete semantics.
- Audit 2: FAIL; found cardinality-only replay-golden/reject-code assertions.
- Remediation: both replaced with exact ordered array assertions.
- Final audit: PASS, zero findings; all prior findings verified closed.

## Owned diff only

- `docs/todo.md` TD-026 blocked claim
- `docs/plans/TD-026-p16-2-promo-contracts.md`
- `docs/handoffs/TD-026-agent-2-p16-2-promo-contracts.md`
- `test/fixtures/p16/promotion_contract_v1.json`
- `test/wip_mage_promotion_contract.gd` and generated UID

No `sim/**`, `data/**`, runtime UI, localization, `FEATURES.json`, thresholds, verification scripts, or frozen P16 v1 fixture bytes changed.

## Resume protocol

After a canonical P16.2 base checkpoint lands on `master`:

1. pull and record its exact SHA;
2. merge/rebase mechanisms to the incumbent strategic command/save conventions;
3. preserve the fixture's pinned semantics;
4. implement v2 migration, XP commit, promotion query/verb, receipt, save/hash, and strategic replay in a newly claimed model transaction;
5. make all six WIP tests green, then rename the suite into default discovery;
6. run all model/save/hash/replay/cross-process gates before any Training UI work.

This branch must not merge while the two dependency tests are intentionally red. It is a ready contract handoff, not a counterfeit completed feature. The difference is inconvenient but useful—much like armor plating.
