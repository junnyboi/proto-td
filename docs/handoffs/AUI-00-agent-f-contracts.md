# AUI-00 — Agent F Presentation Contracts Handoff

**State:** landed and durably closed; frozen RELEASE, independent audit, and merged-master union pass
**Owner:** AGENT F
**Implementation branch:** `agent-f/aui-00`
**Closure branch:** `agent-f/aui-00-closure`
**Original base:** `975261e8e00a20a0b25fe17e7976d743d509c14b`
**Plan:** SHA-256 `d62f55e07376354c2b1ddcc214cbb03a9c581f480eaa7401ac349b4f623285bd`
**Final base:** `709781b596c0a3f21494a1be91713952f99d94e3`
**Landed commit/tree:** `1a28721d23183bf9755ba6c90ba7c578cebc5850` / `59a76fac697b7b0c610eefe241e905bf6928841a`
**Immutable evidence:** external `release-1a28721d-final7`
**Independent audit:** PASS, zero critical findings or warnings

## Delivered contracts

AUI-00 upgrades `AssetManifest` additively to schema v2. The frozen 43-ID inventory retains every legacy pattern, frame count, native size, placeholder flag, and all 93 incumbent PNG byte hashes. Entries add normalized descriptive pivots, exact legacy animation regions, and the SHA-256 of a canonical sidecar under `assets/provenance/`. `Art.texture`, `Art.frame_count`, and `Art.size` are unchanged; new metadata, pivot, animation, and provenance APIs fail closed for unknown inputs.

Six presentation-only Resource contracts are available under `data/presentation/`: `StagePresentationDef`, `EnvironmentTheme`, `UiMaterialTier`, `TacticalCueConfig`, `CharacterVisualDef`, and `ProbeColorOwnerRegistry`. Each is schema v1, validates without repair/coercion, rejects unknown or malformed nested values, saves/reloads exactly, and imports no simulation surface. `probe_color_owners.tres` is the sole AUI-00 concrete fixture and pins the exact 13 current WHITE/SKY owners, legacy exceptions, and base/charmed differential pairs.

The canonical asset generator now emits schema-v2 metadata and 43 compact, deterministic provenance sidecars. A committed executable JSON Schema, deterministic validator/migrator, and negative Python tests reject missing/extra/wrong-type/null/path/hash/input-closure drift. Current bytes are explicitly `unknown_per_current_byte`; no historical family acceptance is forged into per-asset approval.

## Verification implemented

`test_presentation_contracts.gd` exercises the exact Resource, manifest, resolver, probe-owner, provenance, and model-isolation contracts with a required nonzero test/assert count. `test_provenance.py` covers schema, canonicalization, and input-closure failures. `contract_lint.gd` verifies manifest validity, sidecar binding, exact runtime color symbols, asset positive/negative pixel ownership, unregistered literal exclusion, and presentation/simulation separation. Two isolated generator worktrees must prove all 137 generated outputs byte-identical to the frozen commit; exact run counts live only in immutable external evidence.

`presentation_contract_floor` is auto-discovered, seed 42, and capped at 600 frames. Its accepted fresh windowed run must pass nine measured checks within budget, emit ten screenshots, and record zero pixel skips. During visual review, a clipped portrait/icon sheet and a color-only high-contrast cue sheet were rejected and corrected; only the regenerated set is admissible. Exact wall time and frame counts live in the immutable external RELEASE summary keyed to the tested commit.

The local Web baseline exports through the unchanged `Web` preset, serves with COOP/COEP, launches installed Chromium through Playwright, rejects the Godot loading splash, waits for the actual title, captures browser console errors, and externalizes all output. Exact export bytes and timings live only in the immutable external RELEASE summary keyed to the tested commit, avoiding a self-referential PCK-size claim in an exported repository document. Browser process memory remains explicitly `unsupported`/`null` when unavailable.

## Truthful current defects

The current staging screen clips its briefing and unavailable-operation labels at 960×720. This is deliberately recorded as an incumbent baseline defect. AUI-00 does not alter production layout and therefore does not pretend that future responsive UI criteria already pass.

## Agent D dependency boundary

`AUI-10-Agent-D-Handoff.zip` was authenticated at SHA-256 `64a1bb4b87f09762a6f20fa77f289d158c91fa9c384ecd3c67b94a1266ef9e43`; all 40 manifest-listed files verify. Its source/staging lane is on `master` at `3b7ba225c90add20924b5a3aef99133162f64531` / tree `bf80de76a3298882d384a6669b67301e66f72862`. The packet explicitly remains `STAGED_UNBOUND`, human-final unset, and requires the exact approved `AUI-DESIGN-D` packet plus accepted manifest hash before runtime ingestion. That approval artifact is still absent. No Agent D PNG is copied into the AUI-00 runtime manifest.

The packet also contains a documentary inconsistency: `AUI-10-agent-d.md` names old full-log and `verify.json` digests, while machine `HANDOFF.json`, packaged `SHA256SUMS`, and actual packaged bytes agree on `7940def0faee8862b2f03609456fbeb39ee24db2195d340e25fcfedcd3614517` and `4919afc082295ea5ed25ca96e246fad218a3c18989a31802c25a12d5fdcb5e07`. Runtime ingestion remains blocked independently of that documentation defect.

## Successor seams

A later Agent F integration package may adapt approved D/E assets to these contracts without changing their visual semantics. D runtime work requires its missing approved design manifest/hash and fresh player-facing union evidence. E-dependent packages remain blocked while E iterates. AUI-00 itself changes no gameplay, stage geometry, route, simulation, hash/save/replay, Theme, production screen, localization catalog, audio, threshold, or export preset.

## Closure proof

The frozen final union passed all 67 RELEASE rungs and all 21 scenario reports, with nonzero checks, zero failed checks, and zero pixel skips. Focused presentation contracts passed with nonzero tests/assertions; both empty-cache generator worktrees matched all frozen outputs; the two-process campaign replay normalized to an empty diff; targeted presentation and asset lanes passed; the Web export reached the real localized `Protos` title with zero console errors; protected-value and stale-marker scans were explicitly falsifiable and empty. The exact landed master commit then passed `scripts/verify.sh --full` again, with local and remote master equal and the tested tree clean.
