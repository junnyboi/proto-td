# Aetheria UI Implementation Status

## AUI-00 — Presentation contracts and baselines

- Status: `candidate_implemented`; frozen RELEASE verification pending
- Owner: `AGENT F`
- Branch: `agent-f/aui-00`
- Base: `master` at `975261e8e00a20a0b25fe17e7976d743d509c14b`
- Base tree: `cf4b3e1c0d8ae826c668765d994a032acbb8c0ad`
- Isolated worktree: `/home/ubuntu/Projects/prototype-td-agent-f-aui00`
- Lease acquired: `2026-08-12T12:42:17.172134Z`
- Lease expiry: `2026-08-12T20:42:17.172134Z`
- Plan SHA-256: `d62f55e07376354c2b1ddcc214cbb03a9c581f480eaa7401ac349b4f623285bd`
- Independent preflight: `PASS`, build-ready, zero blocker/major findings
- Enforcement: MGS v2 `DEFAULT`; effective lane `RELEASE`

### Dependency boundary

- D: owner-approved by attestation; authenticated AUI-10 staging handoff at archive SHA-256 `64a1bb4b87f09762a6f20fa77f289d158c91fa9c384ecd3c67b94a1266ef9e43` and `master` commit `3b7ba225c90add20924b5a3aef99133162f64531`; exact approved design manifest/hash still absent, so runtime ingestion remains blocked.
- F: approved at `7dd6b1ca88d57bd4532c195f196f2ec44a46955dabf370ce774ea3ebc2037ed7`.
- E: iterating; all E-dependent packages remain blocked.
- Agent 8 `TD-006` owns `docs/todo.md` and `docs/completed.md`; AUI-00 excludes both.

### Exact external lease mirror

- `assets/asset_manifest.gd`
- `assets/manifest.tres`
- `assets/sprites/**` — temporary generator-output write ownership; tracked bytes must remain unchanged
- `assets/portraits/**` — temporary generator-output write ownership; tracked bytes must remain unchanged
- `assets/provenance/**`
- `scripts/view/art.gd` and `.uid`
- `data/presentation/**`
- `tools/gen_assets.gd`
- `tools/presentation_qa/**`
- `test/test_presentation_contracts.gd` and `.uid`
- `selftest/scenarios/presentation_contract_floor.gd` and `.uid`
- `docs/decisions/AUI-DESIGN-APPROVALS.md`
- `docs/plans/AUI-IMPLEMENTATION-STATUS.md`
- `docs/handoffs/AUI-00-agent-f-contracts.md`

### Non-goals

No simulation, gameplay data, route, tick, hash/save/replay, BattleView, JuiceLayer, MapNavigator, IsoProjection, audio, threshold, export-preset, `scripts/verify.sh`, localization, Theme, visible copy, D/E runtime asset, or player-facing feature-status change.

### Required exit evidence

Exact contract GUT, generator double-run byte identity, `assets_floor`, `presentation_contract_floor` headless/windowed at seed 42 with ten fresh images and zero required skips, local Web/browser baseline, complete externalized `scripts/verify.sh --full` RELEASE union, secret/provenance scan, independent diff review, merged-master verification, and clean local/remote SHA equality.

### Candidate implementation facts

- Manifest v2 preserves the frozen 43 logical IDs and all 93 incumbent PNG digests while adding normalized pivots, exact legacy animation regions, and one canonical sidecar digest per entry.
- Six presentation-only Resource contracts and the exact 13-row reserved probe-color registry fail closed on malformed data and stay outside simulation/hash/save/replay.
- Focused GUT requires nonzero tests/assertions across every presentation contract; the Python provenance suite and deterministic contract lint must pass. Exact candidate counts live only in immutable external evidence.
- Generator double-run: 137 generated files byte-identical.
- `presentation_contract_floor`: 9 checks, 10 fresh windowed PNGs, zero pixel skips, and completion within the pinned 600-frame/<15 s bounds. Visual review rejected and corrected one clipped contact sheet and one color-only cue sheet before acceptance; exact measured values live in the immutable external candidate summary.
- The local Web baseline must reach the actual title, reject the loading splash, and record zero browser-console errors. Exact export bytes and timings live only in the immutable external candidate summary because embedding those values in an exported repository document changes the measured PCK. Browser process memory is explicitly `unsupported`/`null` when unavailable.
- Current 960×720 staging right-edge clipping is recorded as an incumbent baseline defect for later UI work, not misreported as an AUI-00 pass.

## Successor locks

AUI-10 and every E-dependent package remain blocked while E is unapproved. No successor claim occurs before AUI-00 durable closure.
