# TD-026 — P16.2-PROMO contract scaffold

**Owner:** AGENT 2

**Branch:** `agent-2/td-026-p16-2-promo-contracts`

**Base:** `a26969770a5ed57206d0751c1d0f757ac576f733`

**Living authority:** `Protos-World-and-Lore-Bible.md` v3.2

**Companion authority:** external `td-mage-apprentice-promotion-choice-companion-plan.md` v2.0

## Summary

The requested promotion feature cannot mutate the canonical campaign yet. Current master contains P16.1's immutable `CampaignState`; `CampaignCodec.SAVE_VERSION` is still `1`, and there is no accepted strategic command/receipt/save-owner API. The companion plan explicitly requires that P16.2 base checkpoint before `P16.2-PROMO` model mutation.

This bounded scaffold starts implementation lawfully by freezing the machine-readable promotion contract and executable red tests while leaving the green production tree and immutable P16.1 contracts untouched.

## Exact current-tree facts

- Fresh `scripts/verify.sh` on the base passed import, stage lint, GUT, replay, model-roster, native/Web filesystem, and all 28 headless scenarios.
- P16.0 and P16.1 are complete; P16 remains pending.
- `CampaignState` is model-only and exposes no accepted mutation commands.
- `CampaignCodec.SAVE_VERSION == 1`.
- Existing hero rows contain no XP, semantic class, promotion, acquisition-template, or identity-portrait fields.
- `caster_2` and `witch_doctor_1` exist only as combat templates; their existence is not a legal personnel transition.
- AUI-20 is retired on the base, so its former shared-ledger lease no longer blocks a later Training UI lane.

## Pinned contract

- Source class: `mage_apprentice`.
- Legal destinations, in canonical order: `witch_doctor`, `sorcerer`.
- Projection mapping: `witch_doctor -> witch_doctor_1`; `sorcerer -> caster_2`.
- Rules version: `1`.
- XP: `+100` per committed operation for each unique deployed living hero; zero for undeployed or dead-at-commit heroes.
- Threshold: `400` XP; promotion cost `0`; excess XP remains.
- Choice is permanent; respec and resurrection are unavailable.
- Identity, callsign, history, recruitment provenance, acquisition template, and identity portrait remain unchanged.
- All eleven current templates have a total v1-to-v2 semantic migration row.
- Accepted promotion changes only advanced class, current combat projection, revision/receipt/hash state.
- Every reject is canonical-byte-equal and strategic-hash-equal.

The exact machine-readable values live in `test/fixtures/p16/promotion_contract_v1.json`.

## Red-first contract

Manual command:

```bash
$HOME/bin/godot --headless -d -s addons/gut/gut_cmdln.gd \
  -gtest=res://test/wip_mage_promotion_contract.gd -gexit
```

Expected state before P16.2 lands:

1. Company 33, Mage branch, and headline progression tests pass;
2. the complete exactly-once XP matrix and checked-overflow contract test passes;
3. the exact total eleven-template migration test passes;
4. immutable identity, command, receipt, reject, and strategic replay-v2 contract tests pass;
5. save-schema/P16.2 authority test fails because `CampaignCodec.SAVE_VERSION == 1`;
6. model-surface test fails because promotion query/verb and hero progression accessors do not exist.

The measured signature is `4/6 passed`: all four fixture-only contracts are green and only the two absent-dependency tests are red.

The test filename intentionally does not match `test/test_*.gd`, so default GUT discovery remains green. Renaming it into discovery before the dependency lands is forbidden.

## Dependency contract for the next owner

P16.2 base must land a canonical, tested strategic mutation owner with:

- accepted/rejected typed command results;
- exactly-once command identity and conflict behavior;
- deterministic save revision ownership;
- immutable receipt storage or an equally strict canonical command ledger;
- minimal durable save seam as defined by the P16 phase authority;
- explicit extension points for promotion and operation-resolution XP;
- all existing P16.0/P16.1 fixtures and proofs preserved or migrated through an owner-approved versioned contract.

After that checkpoint lands, reconcile this scaffold against the actual API. Revise mechanisms, never the pinned semantics. Then claim core files as a new non-overlapping implementation transaction and rename the WIP suite into default discovery only after it passes.

## Explicitly not in this scaffold

| Excluded | Deferred to |
|---|---|
| P16.2 recruit/rename/attempt/resolution implementation | Canonical P16.2 base lane |
| Hero/save/hash mutation | P16.2-PROMO after base |
| Battle projection | P16.3-PROMO |
| Training UI and Mage content cutover | P16.4-PROMO |
| Durable restart/recovery | P16.5-PROMO |
| Human gameplay verdict | P16.6-PROMO |

## Exit

This scaffold may be committed and pushed as a blocked branch but must not merge to `master` while its dependency test is intentionally red. Closure requires either adoption by the landed P16.2 owner or a replacement implementation that preserves the exact contract.

The bureaucracy has been compressed to one useful fact: the engine lacks the transaction spine. Installing the buttons first would be a very attractive lie.

## Independent audit remediation

The first read-only audit returned FAIL because the initial fixture pinned only headline values. The scaffold was strengthened without touching production code:

- every migration row now pins acquisition template, current projection, first/advanced class, rules version, zero XP, and immutable identity portrait;
- XP now pins unique deployed-hero derivation, CLEAR/DEFEAT/retreat/already-promoted behavior, preview/retry zero deltas, signed-64-bit domain, and whole-resolution overflow rejection;
- promotion now pins exact command constants, deterministic ID format, ordered receipt fields, exact retry, conflict, post-commit, stale-revision, cancellation, and replay-v2 semantics;
- the preservation set now includes `first_class_id` and `progression_rules_version`;
- four executable fixture tests prove those pins before the two deliberate dependency reds.
