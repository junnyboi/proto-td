# TD-021 — P16.1 canonical hero/roster model

- Owner: AGENT A / Agent 1
- Branch: `agent-a/p16-1-roster`
- Base: `origin/master` at `6a578856d1893030011c557716bbb930559fa681`
- Oriented commit: `8e973dc94303d556d1a42261b6d95a64dd8f045d`
- Route: RELEASE
- Canonical plan: `td-phase-16-persistent-heroes-barracks-permadeath.md`
- Companion plan: `td-phase-16-1-hero-roster-model.md`
- Decision: owner-approved D16-08

## Goal

Add the model-only canonical P16 HeroState, RosterState, and CampaignState over the frozen P16.0 CampaignSave/Hash grammar. Preserve current player flow through a separately named LegacyCampaignAdapter until real ticket/outcome production permits the P16.3 atomic runtime cutover.

## Authority boundary

- Canonical CampaignState stores only whole-document-normalized CampaignSave `data` and exposes defensive derived views.
- HeroState and RosterState are read-only views; reward allocation is preview-only and cannot mutate state, counters, progression, bytes, or hash.
- Existing Game sessions use LegacyCampaignAdapter only. A Game session never owns both authorities.
- Game debug unlock becomes a nonpersistent catalog projection and never mutates either campaign model.
- CampaignCodec, CampaignHash, CampaignInvariants, P16.0 fixtures, replay v1, BattleModel, player-facing UI, thresholds, localization, presentation, music, and SFX policy are frozen.

## Exact acceptance

1. Seed 42/generation 1 canonical factory output matches the frozen fresh fixture data and retains checksum `516eb349d33fbb40408d742f86ef0784fc8ab9c473ab66893a730c28712f0c6a` and full strategic hash `85f2c11018249153`.
2. Five starters retain exact recruitment order, IDs, names, source fields, 120 Marks, counters, and the unconsumed 80-Mark caster offer.
3. Catalog/stage input order and fresh-process load order cannot change canonical bytes, identity, names, projection, or hash; a data-owned SHA-256 fingerprint rejects any different catalog membership, stage identity/order, squad size, reward mapping/order, or recovery roster.
4. Allocation proves collision ordinals 0, 1, and 31 plus exhaustion with zero state/counter/hash change.
5. S1 reward preview allocates index 5 without a paid recruit and index 6 / `fe0ff2c1e3ecc49d` after the valid paid-contract fixture; repeated preview is byte-identical and hash-preserving; an already-cleared anchored fixture allocates nothing.
6. Roster lookup, READY filtering, duplicate-definition projection, DEAD ownership retention, and compatibility projection are exact and defensive.
7. Valid field-family changes alter the frozen full hash; malformed/impossible states reject rather than hash.
8. Debug override exposes full catalogs but leaves legacy campaign bytes/fields unchanged and clears on New Campaign and Title.
9. Existing campaign, resign, staging, results, bot, quick/direct battle, replay v1, and P16.0 contract behavior remains exact.
10. No player-facing P16 status is claimed.

## Proof and integrity

- Focused HeroState, RosterState, canonical CampaignState, and Game compatibility GUT suites run twice.
- `model_roster_runner.gd` emits compact canonical fresh model/projection/reward-preview evidence.
- `model_roster_check.sh` runs two fresh OS processes and requires byte-identical output.
- `model_roster_probe` is UI-free, `max_frames=600`, has a mandatory completion sentinel, and takes no screenshots.
- Existing replay and filesystem differentials remain green.
- STANDARD and full RELEASE run on a frozen clean candidate; independent non-implementer diff-vs-pins audit is required.
- Merge current master into the feature branch, verify the exact union, fast-forward master, push normally, and confirm local/remote SHA equality.

## Non-goals

No accepted recruit/rename/begin/resolve/death/recovery commands, tickets/outcomes/receipts, SaveStore/autosave/Continue, hero-ID squad selection, replay v2, Barracks/Contract Board UI, localization, screenshots, or feel claim.

## Rollback

Before the P16.3 cutover, remove the canonical model files and restore current Game references to LegacyCampaignAdapter. No production P16 save or player-visible state requires migration.
