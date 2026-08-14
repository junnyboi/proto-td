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
- E: exact Round 5 concept packet approved; AUI-34 terminal lane receipt authenticated for the owner-authorized aggregate integration described below.
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

AUI-00 is durably closed. AUI-10 source/staging is closed, AUI-10R is the independent Agent D runtime successor, and AUI-12 remains Agent F's active UI lane. AUI-34 closes in the containing aggregate commit after fresh merged-union evidence qualifies; AUI-11 may be claimed only after that exact commit is remote-equal on `master`.

## AUI-34 — Deterministic character/VFX pipeline aggregate

- Status: `landed_closed` in this row's containing aggregate commit, conditional on the immutable external final-union record reporting PASS before publication.
- Lane owner: `AGENT E / AGENT 6`; owner-appointed integrator: `AGENT 6`.
- Union base: `master` at `bf3402c6e08baa8ec3ecc5157a7329bc27e51915` / tree `042dad117f2717a4fee1e2849427598e0dc9c285`.
- Terminal lane: `ff64367e1991299fbecf3e517dc554443d819e73` / tree `2e7b85bb2347068779b4c37c0295a383344045fb`; immutable receipt SHA-256 `109a8e76846e25a8a58ba97f0c102f2c8f00a4a60b4d0366857a9da67f65a9bd`.
- Delivered scope: offline Python/Pillow canonical normalizer, Godot `Image` fallback, strict schema/path contracts, deterministic synthetic fixtures, independent semantic oracle, same-backend byte proof, cross-backend decoded-RGBA differential, atomic publication, rollback salvage, runbook, and staging provenance fragments.
- Reconciliation: AUI-00 closure is present; all six exact Round 5 hashes match; reserved colors remain exact `#F4F4F4` and `#41A6F6`; current provenance fragments are staging contracts rather than runtime sidecars; no manifest, runtime asset, gameplay, simulation, localization, test, harness, threshold, or final-art surface is changed.
- Assurance: the aggregate is publishable only after a fresh cache-bypassed 600-check-or-higher differential, full repository gate, fresh image review, and non-implementer diff-vs-pins PASS are bound to the exact aggregate commit in external `mgs.final-union.v1` evidence.
- Preserved boundary: `runtime_binding = UNBOUND_AGENT_F_SEAM`, `human_final_art = UNSET_HUMAN_ONLY`, and no production Aetheria character/VFX asset is emitted or installed.
- Successor: AUI-11 may start after the exact aggregate commit is remote-equal on `master`; production content still requires its own claims, generated packets, QA, runtime-binding integration, and human final-art decisions.

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

- Status: `closed`; approved candidate `aa856d71d5e533f8267bed3b63c8c85fc0acfc9d` / tree `40be18f250689e140d8ded3b5f4863a486b6ea57` landed on `master` after fresh RELEASE, independent audit, and Poseidon L7 approval. Candidate `28b0391ab78b326772c11d040ad75f333183233b` remains immutable red history.
- Owner: `AGENT F`.
- Original claim/base: `agent-f/aui-12-claim` from `master` at `ed66d67e67e56f5b41f3fb52a812a78452b9db0d`.
- Web-remediation claim/base: `agent-f/aui-12-web-claim` from `master` at `6a578856d1893030011c557716bbb930559fa681`.
- Successor implementation branch/base: `agent-f/aui-12-web-remediation` from claimed master `9b834f54a218e3eeb77e89e014476300180dc33a`; do not rewrite the red branch.
- Successor implementation commits: byte-identical current-master reconstruction `40bec07056508cbd8f9a12b8539516fb61631228`; D-WEB-1 production/tool/test implementation `5441e27e47c6237541cb0a06dd3aeaaa02c3ddf9`.
- Exact union reconciliation: latest merge `930ff8965005ca81cd28c961b8fc3ab38451da0e` has first parent `02e3b54c4161df1b3b6dbd88e83db655fc112383` and exact current-master second parent `3376178219c4a9df94abfb24798a6ffe3d0c7aee`; the side diffs again had zero overlapping paths. Prior union merge `cd8298d01936c77b12c19e559ef67f0a748fab82` remains in history.
- Effective lane: MGS v2 `RELEASE` because the package is player-visible and changes `test/**` plus `selftest/**`.
- Final original implementation-plan SHA-256: `55e7daf91097e476719242203a6d3943e5db4e7a979f129cda0e08f6f3ba608b`.
- Normative component/copy/scenario/inventory hashes: `70efb6f83b1c59d45d7a5a6cfb7e4cea4dd5058827b2f908fa290e7beaecab90`, `0061b4e08b7c27bd3ed38ceb88897da2d3032369cfbfbaf92ef543f8ffb70c83`, `692f7f492cb94ed28d8f8c8a44b738846ef9037d6c923841b72388d099505a01`, `177ee1e6c5e1e49357bb54263f0659c3bc50f213f4d544bfc1f6ef9f5fa50a2f`.
- D-WEB-1 approval: exact manifest SHA-256 `0c7530b9bfa54bf8581d42596393cedfe3e06b410230c5c8565fe0a97520c200`; external Poseidon record SHA-256 `d616bc95eee2aeb3c226f167c2b45c71152d6856285b169af99eeabe7c1e3f17`.
- Independent Web-remediation preflight 07: PASS with zero findings >=80 confidence; exact contract freezes 38 focused tests, 105 negative fixtures, one content-equivalence positive fixture, 25/27 required-option families, and 18 exercised failure codes.
- Independent implementation audit 04: PASS with zero findings >=80 confidence after three preserved FAIL iterations closed production fail-closed/provenance gaps and made every one of the 105 observed fixture outcomes equal the frozen oracle.
- Clean-commit evidence requirement: dirty-tree focused/default greens are feedback only. The containing documentation commit becomes the frozen candidate only after exact 38-test, scenario, default/full, production Web generation, independent verify-output, replay, and external integrity evidence all pass on a clean detached worktree.
- Stale evidence boundary: `release-6a1d65a-r2` passed on the pre-union candidate but is not release qualification because master advanced during its run. The exact merged union must restart the complete RELEASE and both review gates from zero.
- Union copy reconciliation: `release-dd8a049-r1` is preserved red because the merged catalog predated current master's nine operator class names and S2 hint. The copy contract itself is unchanged and source-derived; the successor updates exactly those ten dynamic en-US values to their current `fallback_property` literals, with 72 keys, all static copy, and all placeholders unchanged.
- RELEASE result: `release-aa856d7-r1` passed 38 focused Web tests, 20 focused GUT tests / 1,987 assertions, 83 full rungs, 26 scenario reports, exact 65/142 `ui_shell_floor` checks with 62 PNGs and zero skips, two-process replay equality, `PASS_CONTENT_EQUIVALENT`, zero secret/stale matches, and 507 sealed artifacts after approval binding.
- Independent final build audit: PASS with zero findings >=80 confidence; audit SHA-256 `8a76e00683a221e84fcdb038cb59a160f08b297c20ff198306fa134c23305ce4`.
- Human L7: Poseidon approved exact `aa856d7` through WebDev checkpoint `292d2003`; external L7 record SHA-256 `3999ae03080c2f48cf0fb3861892bb35792ad1ddee51d943d93fc3f6db046d40`.
- Ownership release: the AUI-12 active claim has been removed from `docs/todo.md`; successor packages may claim paths only through a new exact-base transaction.
- Dependency boundary: AUI-12 consumes no Agent D or Agent E runtime bytes. AUI-34 is now closed on master, but AUI-11/AUI-20 remain separate packages and cannot enter this successor.
- Closure boundary: AUI-20 is unblocked by AUI-12 closure but remains a separate, newly claimed package; AUI-11 remains governed by its own dependencies and scope.

## AUI-20 — Integrated S1 slice and kill-gate verdict

- Status: `retired_superseded_pre_implementation` as of 2026-08-13 by Poseidon direction.
- Runtime truth: no AUI-20 implementation byte was written. The retired package consists only of landed claim/decision history on `agent-f/aui-20-claim`, `agent-f/aui-20-fixture-amendment`, and `agent-f/aui-20-rebase-claim`.
- Retirement base: clean master `8e6b0fa52faa935bc32f810c5048b43b61bb1132` / tree `1ef2e07cd9763725a91550e73b1c33e77fb5859a`; unchanged default verification passed 35/35 rungs. Baseline stdout SHA-256: `7709b69cc4360ef31c8ec3abdc2b334f562519f5a1cdffcfbe7a1c915a2fca95`; `verify.json` SHA-256: `75dd641a49ac1801e232271a848d97389abc50b707bdf1093f70a10f642d417a`.
- Supersession: Protos canon 3.3 required the broader Company 33/Act I comprehension tranche, which has landed. The separate turn-based tactical replacement experiment was subsequently killed and externally archived on 2026-08-14 after the owner reaffirmed the Arknights-style tower-defense RPG identity. The next product work belongs to the original battle model, operator abilities, and tower-defense presentation—not tactical replacement.
- Ownership release: every AUI-20 path claim is released. The fixture authorization and prior rebase decision remain preserved as historical evidence, not active runtime authority; reuse requires a new current-base claim and plan.
- Shared-state boundary: `FEATURES.json` remains unchanged because AUI-20 never became an implemented product feature. No tactical replacement feature entered production or remains authorized.
- Durable decision: `docs/decisions/AUI-20-RETIREMENT.md`.
