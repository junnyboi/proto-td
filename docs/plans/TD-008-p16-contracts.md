# TD-008 — P16.0 deterministic personnel contracts

## Identity

- Owner: AGENT A
- Branch: `agent-a/p16-contracts`
- Base: `master` at `a6bae9c24f4e6239da0821ef81107198bbf011c2`
- External orientation: `/home/ubuntu/mgs-state/prototype-td/p16-0/ORIENTATION.json`
- Canonical plan: Manus project document `td-phase-16-persistent-heroes-barracks-permadeath.md`
- Route: requested STANDARD, effective RELEASE because this batch changes mutable deterministic, hash, save, replay, and catalog contracts

## Dependency boundary

P16.0 freezes contracts and proof fixtures only. It may add pure identity/name/canonical-json/save/hash/replay modules, recovery-roster data and lint, replay fixtures and a two-process runner, a sandboxed filesystem probe, tests, and one non-player-facing scenario. It may not expose recruitment, Barracks, casualties, Continue, autosave, hero-ID battle deployment, or player-facing permadeath.

## Current-master adaptations

1. `FLOW-1` at `a6bae9c` supersedes the plan's obsolete `CampaignButton` compatibility sentence. P16 preserves one `StartButton` gameplay flow and no `CampaignButton`; later P16.5 adds `ContinueButton` without restoring a second New Campaign button. A valid slot makes Start open overwrite confirmation; no/corrupt slot keeps Start available.
2. Localization is not implemented on current master. P16.0 records no visible strings. At P16.4—the first visible P16 screen—stable keys, English fallbacks, en-US development default, Settings locale selector, catalog/placeholder parity, font/glyph/layout gates, and locale-outside-model/hash/save/replay become mandatory.
3. Current master advanced from the planning baseline `690f761` through TD-006 music and TD-007 campaign-only Start. All evidence and gates use the actual base above.

## Exact deliverables

- SplitMix64 campaign/hero IDs, lowercase-u64 codec, v1 fixed name table, and golden vectors.
- Canonical compact JSON helpers, campaign save/schema codec, strategic FNV-1a grammar, and exact SHA/hash fixtures.
- Strict replay v1 codec, S1–S8 fixtures proven equal to current StageBot sources, standalone runner, and two-process byte diff.
- `StageDef.recovery_roster`, exact S1–S8 authored values, and catalog/availability/squad-capacity lint.
- Isolated `user://` FileAccess/DirAccess main/tmp/bak probe under a temporary XDG root; no production save writes.
- Focused GUT suites and `p16_contract_probe` with completion sentinel and no screenshots.

## Evidence classes

- Logic: golden identity/name/hex/collision/save/SHA/FNV/replay schema tests; recovery lint.
- Integration: replay fixtures match current bots; two fresh OS processes emit identical replay manifests; standard regression stays green.
- Visual: not applicable in P16.0—no player-facing screen.
- Feel: not applicable in P16.0—no human feel claim.

## Exit gate

- All new pure suites pass twice and the replay digest matches across two OS processes.
- Filesystem probe passes within 45 seconds in an isolated temporary user root.
- Existing campaign model tests, scenarios, bots, and gates remain green.
- One fresh uninterrupted full gate passes at the frozen phase commit.
- Independent non-implementer diff-vs-contract audit is clean.
- Integrated `master` receives its own full gate, is pushed normally, and local/remote SHA equality is confirmed.
- `P16` remains pending after P16.0; this phase proves contracts, not gameplay.

## Activated pre-freeze amendment — D16-06

The independent audit proved that source IDs and counters alone could not decide several impossible historical states. Before the P16.0 freeze, CampaignSave v1 therefore gains:

- `HeroState.recruited_after_resolution_index`;
- `StageStarRow.first_clear_resolution_index`;
- `CampaignResolution.strategic_body_hash_before` (renamed from the misleading full-state name).

No production save exists, so the version remains v1. Load now proves exact starter mapping, 120-Mark contract accounting, reward chronology, recovery-before-source-clear timing, death-after-recruitment, monotonic grouped resolution history, exact latest created/dead sets, and reconstructed before/current core hashes. The adversarial corpus includes a draft after its source stage cleared, impossible Marks, arbitrary receipt hashes, reversed rewards, and conflicting deaths; every rejection preserves the prior valid strategic hash.

The final pre-freeze audit extended the amendment with contiguous immutable recruitment indices, exact first-clear attempt/tick fields, CampaignResolution terminal tick, one global resolution-event ledger, and a persistent ResolutionAnchor. The anchor closes the latest before/after core at its resolution save revision but remains valid after later rename, recovery, or begin-attempt saves. DeathRecord stores the battle terminal tick—not first-fall tick. Web proof exits Chromium normally from the resolved Godot engine promise; forced termination is failure-only cleanup.

Filesystem proof is exact on native and exported Web: 17 stable recovery cases, 150 checks, final probe-root cleanup, no mandatory failures, and normal browser completion after a success sentinel. Replay proof executes every supported verb with pinned accepted/rejected verdicts and rejection zero-state hashes.

## Owner-approved pre-freeze amendment — D16-07

Audit 6 proved that hash strings alone could be synchronized after a later durable mutation and that the earlier four-field anchor could not permanently prove its own provenance. The owner approved D16-07 before freeze:

- `ResolutionAnchor` adds canonical, validated `before_core` and `after_core` snapshots before its two body hashes;
- every direct core hash first validates the exact core schema plus identity, catalog, progression, offer, hero, and Marks invariants;
- load recomputes both body hashes, proves exact `before_core → CampaignResolution → after_core` closure, and accepts later state only when it differs through durable callsign rename, paid/recovery recruitment, or begin-attempt changes;
- the canonical resolution fixture retains `terminal_tick` and pins SHA-256 `f4e02e3036543b8b0e01e01893f713d1be7a56963cfaa8b55f82b01f26ffdd1b`;
- the canonical non-null-anchor save pins data checksum `5ac811665449d67382941e8218ca0b95acd6737cc914211729bf8f7f408dd983`, full save SHA-256 `1bb5d32ae1df9a5cb28997e30ab2d19d343f6456613cad14ae853b62d111a7e6`, body hashes `1d62ea3e4b4bea4e` / `3d715c766d8f66ce`, and full strategic hash `9f25771019b780ff`;
- the existing two-process replay oracle now includes and compares this save/hash proof.

The verifier's P16 count gate strips ANSI, delimits each exact suite block, requires exactly one exact summary line, and self-rejects unrelated headers plus injected/duplicate summary tokens.
