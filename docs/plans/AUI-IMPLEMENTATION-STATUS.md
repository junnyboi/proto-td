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

- D: exact parent/revision manifests are checked in; AUI-10R separately owns and verifies the S1 runtime successor. AUI-00 itself still consumed no D runtime bytes.
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

AUI-00 is durably closed. AUI-10 source/staging is closed, AUI-10R is the independent Agent D runtime successor, and AUI-12 remains Agent F's active UI lane. AUI-34 remains Agent E's lane; AUI-11 and every E-dependent package remain blocked until AUI-34 durably closes.

## AUI-10 — Agent D S1 world source/staging closure

- Status: `landed_staging_closed`; runtime binding moved to the separately approved AUI-10R successor.
- Source owner: `AGENT D`; closure owner: `AGENT F`.
- Closure branch/base: `agent-f/aui-10-closure` from `ec56def391269f96a1e596ec4245bcd940ebdcdc`.
- Landed validator: PASS with 8 assets, 8 provenance sidecars, 16 source records, stage-resource SHA-256 `c8d041bff7ce9a2b570997cbc2d09ee6ff0487c7666ff68875314cc39df0a1d9`, and all staged measurements within their pinned ranges.
- Superseded blocker: the exact parent/revision manifests and Poseidon's human-final receipt now exist under `docs/media/`; AUI-10R binds them without rewriting this historical source packet.
- No runtime manifest, view, scene, model, stage, harness, test, threshold, localization, feature-ledger, or import-guard surface changes in closure.
- Next independent Agent F package: AUI-12. AUI-20 remains blocked on AUI-12 closure; its former D-artifact blocker is satisfied by AUI-10R. AUI-11 remains blocked on Agent E AUI-34 closure.

## AUI-10R — Agent D S1 runtime integration and revision 2

- Status: `human_final_approved`; landing is conditional on the exact post-verdict union passing fresh RELEASE and default-branch verification.
- Owner: `AGENT D`.
- Owner-approved candidate: `60b69a6004a9c843851d9f6c9aee84c88389cb1f`.
- Human verdict: Poseidon approved Cloud-Seal Orrery + Alpine Escarpment on 2026-08-13; receipt `docs/media/AUI-10R-REVISION-2-HUMAN-APPROVAL.json`.
- Runtime scope: twelve exact `world.s1.*` assets; one continuous panorama; S1-only typed theme; fail-closed required-theme loading; no simulation/stage/save/hash/replay/localization/threshold change.
- Final-art state: all twelve manifest placeholders cleared; staging/runtime provenance binds the verdict owner, timestamp, receipt hash, and accepted candidate.
- Mandatory landing evidence: byte-idempotent base+revision regeneration, art validator, GUT, headless/windowed scenarios, cache-cleared `scripts/verify.sh --full`, separate-process replay identity, independent diff-vs-pins audit, localization-impact review, and merged-union default-branch verification.
- Agent F AUI-12 and all Agent E work remain outside this lane.

## AUI-12 — Protos Theme, components, localization, and compatible shells

- Status: `claimed`; implementation not started at this claim commit.
- Owner: `AGENT F`.
- Claim branch/base: `agent-f/aui-12-claim` from `master` at `ed66d67e67e56f5b41f3fb52a812a78452b9db0d`.
- Implementation branch: `agent-f/aui-12` after the verified claim lands on master.
- Effective lane: MGS v2 `RELEASE` because the package is player-visible and changes `test/**` plus `selftest/**`.
- Immutable plan SHA-256: `29022e14441c3842f5c364ae3423bb30d12b8897e11b4d2064e0f3a8e32586b0`.
- Normative copy/component/inventory/scenario hashes: `d7afa360523ad915aaa25f95d30fd0054d23078cd7a79ed3d25ce8d02d6dc37c`, `16e3f18ac23ecb846b288b7dbe4de454f3581faa3b27386885dd3d1e624285d4`, `78b57390c35343966b971cdcfe951f23950299ed78c03a44da3db0e347fc2a12`, `bca4ebd9c0ac364b3ca290896a0a54d005713a402c2d57cb4c1d5d5cbd18d01f`.
- Independent preflight: PASS with zero critical/warning findings.
- Serialized ownership amendment: AUI-12 owns `autoloads/i18n.gd`, `localization/en-US.json`, and `test/test_i18n.gd` because current project policy requires localization from the first visible AUI phase. The complete exact file lease is in `docs/todo.md`.
- Dependency boundary: AUI-12 consumes no Agent D or Agent E runtime bytes. AUI-20 remains blocked on AUI-12 closure and exact D runtime approval; AUI-11 remains blocked on AUI-34 closure.
- Human gate: implementation cannot land until fresh exact-candidate RELEASE/audit passes and Poseidon completes the commit-bound Web route/focus/cancel/locale/compact/portrait/en-US review.
