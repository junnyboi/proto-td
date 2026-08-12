# Aetheria UI Implementation Status

## AUI-00 — Presentation contracts and baselines

- Status: `landed_closed`; frozen RELEASE, independent audit, and merged-union verification pass
- Owner: `AGENT F`
- Implementation branch: `agent-f/aui-00`
- Closure branch: `agent-f/aui-00-closure`
- Final base: `master` at `709781b596c0a3f21494a1be91713952f99d94e3`
- Landed implementation: `1a28721d23183bf9755ba6c90ba7c578cebc5850`
- Landed tree: `59a76fac697b7b0c610eefe241e905bf6928841a`
- Isolated worktree: `/home/ubuntu/Projects/prototype-td-agent-f-aui00`
- Lease acquired: `2026-08-12T12:42:17.172134Z`
- Lease expiry: `2026-08-12T20:42:17.172134Z`
- Plan SHA-256: `d62f55e07376354c2b1ddcc214cbb03a9c581f480eaa7401ac349b4f623285bd`
- Independent preflight and final audit: `PASS`, zero blocker/major findings
- Enforcement: MGS v2 `DEFAULT`; effective lane `RELEASE`
- Immutable RELEASE evidence: external `release-1a28721d-final7`
- Merged-master union: `scripts/verify.sh --full` PASS at the exact landed commit; local and remote SHA equal

### Dependency boundary

- D: owner-approved by attestation; authenticated AUI-10 staging handoff at archive SHA-256 `64a1bb4b87f09762a6f20fa77f289d158c91fa9c384ecd3c67b94a1266ef9e43` and `master` commit `3b7ba225c90add20924b5a3aef99133162f64531`; exact approved design manifest/hash still absent, so runtime ingestion remains blocked.
- F: approved at `7dd6b1ca88d57bd4532c195f196f2ec44a46955dabf370ce774ea3ebc2037ed7`.
- E: iterating; all E-dependent packages remain blocked.
- Shared-ledger exclusion ended after implementation landed; this dedicated closure branch owns only the compact AUI-00 completion transaction.

### Released implementation lease

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

### Satisfied exit evidence

Exact contract GUT, generator double-run byte identity, `assets_floor`, `presentation_contract_floor` headless/windowed at seed 42 with ten fresh images and zero required skips, local Web/browser baseline, complete externalized `scripts/verify.sh --full` RELEASE union, falsifiable secret/provenance scans, independent diff review, merged-master verification, and clean local/remote SHA equality all passed at `1a28721d23183bf9755ba6c90ba7c578cebc5850`.

### Landed implementation facts

- Manifest v2 preserves the frozen 43 logical IDs and all 93 incumbent PNG digests while adding normalized pivots, exact legacy animation regions, and one canonical sidecar digest per entry.
- Six presentation-only Resource contracts and the exact 13-row reserved probe-color registry fail closed on malformed data and stay outside simulation/hash/save/replay.
- Focused GUT requires nonzero tests/assertions across every presentation contract; the Python provenance suite and deterministic contract lint must pass. Exact candidate counts live only in immutable external evidence.
- Generator double-run: 137 generated files byte-identical.
- `presentation_contract_floor`: 9 checks, 10 fresh windowed PNGs, zero pixel skips, and completion within the pinned 600-frame/<15 s bounds. Visual review rejected and corrected one clipped contact sheet and one color-only cue sheet before acceptance; exact measured values live in the immutable external candidate summary.
- The local Web baseline must reach the actual title, reject the loading splash, and record zero browser-console errors. Exact export bytes and timings live only in the immutable external candidate summary because embedding those values in an exported repository document changes the measured PCK. Browser process memory is explicitly `unsupported`/`null` when unavailable.
- Current 960×720 staging right-edge clipping is recorded as an incumbent baseline defect for later UI work, not misreported as an AUI-00 pass.

## Successor locks

AUI-00 is durably closed. AUI-10 source/staging closure and AUI-12 may now proceed as separate serial Agent F packages from the closure commit. AUI-34 remains Agent E's lane; AUI-11 and every later E-dependent package remain blocked until AUI-34 durably closes.

## AUI-10 — Agent D S1 world source/staging closure

- Status: `landed_staging_closed`; runtime binding remains blocked.
- Source owner: `AGENT D`; closure owner: `AGENT F`.
- Closure branch/base: `agent-f/aui-10-closure` from `ec56def391269f96a1e596ec4245bcd940ebdcdc`.
- Landed validator: PASS with 8 assets, 8 provenance sidecars, 16 source records, stage-resource SHA-256 `c8d041bff7ce9a2b570997cbc2d09ee6ff0487c7666ff68875314cc39df0a1d9`, and all staged measurements within their pinned ranges.
- Preserved blocker: exact approved `AUI-DESIGN-D` packet/accepted manifest hash is absent. `runtime_binding` remains `UNBOUND_AGENT_F_SEAM`; `human_final_art` remains `UNSET`.
- No runtime manifest, view, scene, model, stage, harness, test, threshold, localization, feature-ledger, or import-guard surface changes in closure.
- Next independent Agent F package: AUI-12. AUI-20 remains blocked on AUI-12 closure and the exact D runtime approval artifact; AUI-11 remains blocked on Agent E AUI-34 closure.
