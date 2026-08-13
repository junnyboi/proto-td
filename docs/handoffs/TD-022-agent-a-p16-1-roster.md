# TD-022 — P16.1 canonical hero/roster model handoff

## Identity

- Owner: AGENT A / Agent 1
- Implementation commit: `099614c7a57951580d72a851d9f4ce14ee4d7aff`
- Branch: `agent-a/p16-1-roster`
- Refreshed base merge: `8e973dc94303d556d1a42261b6d95a64dd8f045d`
- Route: RELEASE
- Decision: owner-approved D16-08
- Canonical plan: `td-phase-16-persistent-heroes-barracks-permadeath.md`
- Repository contract: `docs/plans/TD-022-p16-1-roster.md`

## Outcome

P16.1 adds the canonical model-only hero/roster campaign aggregate while deliberately preserving current player sessions through `LegacyCampaignAdapter`. Game never owns both authorities. P16 remains `pending`: this phase adds no recruit, rename, attempt, resolution, death, recovery, persistence, hero-ID battle, Continue, Barracks, Contract Board, or player-facing behavior.

The delivered boundary includes:

- immutable `HeroState` and `RosterState` defensive views over whole-document-normalized CampaignSave rows;
- canonical `CampaignState.create/restore` delegating bytes and the sole strategic hash to frozen P16.0 CampaignCodec/CampaignHash/CampaignInvariants;
- exact seed/generation identity, starter order, names, counters, 120 Marks, and unconsumed 80-Mark caster contract;
- pure collision-bounded hero allocation and first-clear reward preview with no state/counter/hash mutation;
- READY filtering, DEAD ownership retention, duplicate-definition compatibility projection, and exact stage lock projection;
- strict CampaignDef/catalog/stage/reward/recovery normalization plus a data-owned and compiled exact environment fingerprint;
- temporary `LegacyCampaignAdapter` preserving current definition-ID progression and current campaign screens/bots;
- nonpersistent Game debug catalog projection, cleared by New Campaign and Title without mutating roster/progression;
- a two-fresh-process reversed-input oracle and UI-free zero-shot model sentinel scenario.

## Exact pins

| Contract | Pin |
|---|---|
| P16 authored-environment SHA-256 | `cf4a272e5aa14a2c8606a6aa6de8efb8345af37d10c82ecf2e579987f7fdb8b6` |
| Fresh save checksum | `516eb349d33fbb40408d742f86ef0784fc8ab9c473ab66893a730c28712f0c6a` |
| Fresh strategic hash | `85f2c11018249153` |
| Campaign UID, seed 42/generation 1 | `ce46150984346591` |
| Fresh S1 reward hero, recruitment index 5 | `e54c103e46898f5d` |
| Paid-contract-then-S1 reward hero, index 6 | `fe0ff2c1e3ecc49d` |
| Anchored full strategic hash | `9f25771019b780ff` |

## Verification and audits

- Focused suites, repeated twice after the final model edit: HeroState 3/3, RosterState 5/5, CampaignState 11/11, Game compatibility 2/2; 21 tests and 230 assertions per pass.
- `model_roster_check.sh`: two fresh Godot processes, normal and reversed catalog/stage input order, byte-identical manifest and exact pins.
- `model_roster_probe`: mandatory completion sentinel, 18 checks, 10 frames, zero screenshots.
- Existing campaign/resign/staging scenarios and S1–S8 campaign bot remain green.
- Existing replay v1 and native/Web filesystem differentials remain in the canonical verifier.
- STANDARD is green after the final source edit.
- Audit A found and closed shallow authored-environment validation and allocator occupancy/bounds defects.
- Audit B found and closed recovery anti-soft-lock factory validation.
- Audit C found and closed acceptance of self-consistent but non-authored environment drift.
- Audit D PASS: zero blocker/high findings and explicit candidate-freeze authorization.
- Final immutable clean RELEASE and merged-union evidence remain external under their exact commit identities.

## Exact authority boundary

- `CampaignState` is immutable/model-only in P16.1 and owns the one P16 CampaignSave value when explicitly created by tests/tools.
- `LegacyCampaignAdapter` is the sole current Game campaign authority and contains no P16 CampaignSave or CampaignHash state.
- Debug unlock is a Game catalog projection only.
- Frozen P16.0 codec/hash/invariant/fixture/replay files, BattleModel, thresholds, player UI, localization, art, and audio are unchanged.

## Next implementation sequence

1. **P16.2 — Strategic verbs and exactly-once resolution:** recruit, rename, begin-attempt, resolve-attempt, typed tickets/outcomes/receipts, paid/recovery contracts, and minimal durable SaveStore plus Retry/Abandon.
2. **P16.3 — Dual-identity battle integration:** immutable hero manifests and battle IDs through BattleModel, sticky falls, terminal outcomes, Game ticket ownership, and replay v2 compatibility; internal-only and unreleasable.
3. **P16.4 — Contract Board and Muster Ledger:** localized player surfaces, callsign-only customization, READY hero-ID squad selection, casualty Results, emergency contracts, and transaction telemetry; unreleasable until P16.5.
4. **P16.5 — Canonical saves, Continue, and durable terminal boundary:** one-slot startup recovery, title state table, overwrite, visible autosave failure, backup recovery, Continue-to-Staging, and exhaustive fault/cross-process proof.
5. **P16.6 — Closure, audit, and human loop:** accessibility/error copy, strategic bot, ledgers, Web export/browser smoke, merged-master RELEASE, and human verdict.

P16.2 must consume the canonical aggregate and remove no D16-08 proof. The P16.3 cutover must be atomic: a live Game session may own `LegacyCampaignAdapter` or canonical `CampaignState`, never both.
