# TD-018 — P16.0 deterministic personnel contracts handoff

## Identity

- Owner: AGENT A / Agent 1
- Implementation commit: `cd35d19d01983aff1390c37167d9140954b3700a`
- Branch: `agent-a/p16-contracts`
- Base: `a6bae9c24f4e6239da0821ef81107198bbf011c2`
- Route: RELEASE
- Canonical plan: `td-phase-16-persistent-heroes-barracks-permadeath.md`, including owner-approved D16-07
- Repository contract: `docs/plans/TD-018-p16-contracts.md`

## Outcome

P16.0 freezes deterministic personnel contracts only. It does not expose recruitment, Barracks, Continue, autosave, hero-ID squad deployment, casualties, or permadeath to players. `FEATURES.json` P16 therefore remains `pending` while recording the P16.0 implementation commit.

The frozen contract includes:

- SplitMix64 campaign/hero identity, fixed v1 name derivation, and exact lowercase-u64 boundaries;
- strict canonical CampaignSave v1, validated before/after core snapshots, ResolutionAnchor, D16-07 permanent receipt closure, and FNV-1a strategic hashing;
- canonical replay v1 fixtures for S1–S8, every supported verb, pinned action verdicts, and rejection zero-state hashes;
- deterministic stage recovery rosters with catalog/capacity/availability lint;
- isolated native and Web main/tmp/bak recovery probes covering 17 cases and 150 checks;
- authoritative action-domain predicates shared by GameConfig, StageDef, and BattleModel without changing action semantics.

## Exact pins

| Contract | Pin |
|---|---|
| Fresh save checksum | `516eb349d33fbb40408d742f86ef0784fc8ab9c473ab66893a730c28712f0c6a` |
| Fresh strategic hash | `85f2c11018249153` |
| Resolution fixture SHA-256 | `f4e02e3036543b8b0e01e01893f713d1be7a56963cfaa8b55f82b01f26ffdd1b` |
| Non-null save checksum | `5ac811665449d67382941e8218ca0b95acd6737cc914211729bf8f7f408dd983` |
| Non-null full save SHA-256 | `1bb5d32ae1df9a5cb28997e30ab2d19d343f6456613cad14ae853b62d111a7e6` |
| Anchored body hashes | `1d62ea3e4b4bea4e` → `3d715c766d8f66ce` |
| Anchored full strategic hash | `9f25771019b780ff` |
| Campaign UID for seed 42/generation 1 | `ce46150984346591` |

## Verification and audits

- Focused P16 contract suite: 15/15, 211 assertions.
- Replay codec suite: 5/5, 108 assertions.
- Full GUT discovery: 146/146.
- Two fresh Godot processes emit byte-identical replay/save/hash manifests: 10 runs, 54 accepted and 9 rejected actions.
- Native and exported Web filesystem probes: 17 cases, 150 checks, zero mandatory failures, normal browser engine exit.
- STANDARD ladder: all green after the final source edit.
- Independent Audit 8: PASS with zero blocking findings and explicit candidate-freeze authorization.
- Frozen clean RELEASE and merged-master union evidence are recorded below when integration closes.

## Prior audit closures

1. ResolutionAnchor persists canonical before/after core snapshots, validates every direct core hash, recomputes both hashes, proves exact receipt transition closure, and constrains later save revision cardinality to callsign rename, paid/recovery recruitment, and begin-attempt operations.
2. First-clear resolution and attempt chronology is strict; the merged global event ledger rejects attempt reuse across StageStarRow, DeathRecord, and latest receipt.
3. P16 suite counts are bound to exact ANSI-normalized suite blocks; unrelated, duplicate/injected, and CSI-prefixed false summaries self-reject.
4. `terminal_tick` remains in CampaignResolution and DeathRecord uses BattleOutcome terminal tick, not first-fall tick.
5. Web completion requires the resolved engine promise and normal Chromium exit; kill is failure-only cleanup.

## Next implementation sequence

1. **P16.1 — Hero/Roster model:** implement HeroState/RosterState, CampaignState personnel/economy projection, reward allocation, and strategic hash properties.
2. **P16.2 — Strategic verbs and exactly-once resolution:** implement recruit, rename, begin-attempt, resolve-attempt, typed tickets/outcomes/receipts, paid/recovery contracts, and the minimal durable SaveStore plus Retry/Abandon seam.
3. **P16.3 — Dual-identity battle integration:** route immutable hero manifests and battle IDs through BattleModel, sticky falls, terminal outcomes, Game ticket ownership, and replay v2 compatibility. This checkpoint is internal-only and unreleasable.
4. **P16.4 — Contract Board and Muster Ledger:** enable localized Recruit/Barracks surfaces, callsign-only customization, READY hero-ID squad selection, casualty Results, emergency contracts, and transaction telemetry. This checkpoint remains unreleasable until P16.5 durability is green.
5. **P16.5 — Canonical saves, Continue, and durable terminal boundary:** complete one-slot startup recovery, title state table, overwrite, visible autosave failure UI, backup recovery, Continue-to-Staging, and exhaustive fault/cross-process proof. This is the earliest permissible player-facing P16 release boundary.
6. **P16.6 — Closure, audit, and human loop:** finish accessibility/overflow/error copy, strategic bot summary, ledgers, PLAYTEST, Web export/browser smoke, merged-master RELEASE evidence, and the human verdict on recruitment, duplicate identity, death fairness, recovery clarity, and save trust.

Every later contract mutation requires a new differential/cross-process oracle and RELEASE routing. P16.4 is the first visible P16 phase and activates PRESENT localization obligations from its first screen.

## Final integration evidence

Final clean RELEASE and merged-master union evidence is stored externally under the verified
commit identity rather than written back into the tested tree. The integration executor must
report the immutable evidence path plus local/remote SHA equality when delivering this handoff.
