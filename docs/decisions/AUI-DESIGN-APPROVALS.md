# AUI Design Approval and Gate Amendment

- Status: accepted
- Decision owner: Poseidon
- Effective date: 2026-08-12
- Scope: Aetheria D/E/F design gate, AUI-00, AUI-10R human-final acceptance, and serialized AUI-12 presentation ownership

## Frozen facts

- `AUI-DESIGN-F` is approved at manifest SHA-256 `7dd6b1ca88d57bd4532c195f196f2ec44a46955dabf370ce774ea3ebc2037ed7`.
- `AUI-DESIGN-D` is approved. The exact parent manifest is checked in at `docs/media/AUI-DESIGN-D-approved-manifest.json`; Poseidon's revision-2 selection is checked in at `docs/media/AUI-DESIGN-D-REVISION-CORE-C-BACKDROP-B.json`.
- Agent D's source/staging package landed at `3b7ba225c90add20924b5a3aef99133162f64531`. AUI-10R promoted and revised it into twelve S1 runtime assets without changing stage geometry or deterministic model state.
- `AUI-DESIGN-E` is still iterating. No E approval, accepted hash, asset consumption, or E-dependent successor claim is permitted.

## Narrow amendment

Poseidon explicitly authorized AGENT F to start **AUI-00** with D and F approved while E remains blocked. This does not retire the collective D/E/F gate for later E-dependent packages and does not convert a missing artifact into evidence.

AUI-00 may land additive presentation contracts, compatibility APIs, truthful provenance migration, probe ownership, tests, and current-build baselines. It may not ingest D runtime assets, consume E work, create visible Aetheria UI, or claim a player-facing milestone.

## AUI-10R human-final amendment

Poseidon explicitly approved **AUI-10R revision 2** on exact candidate `60b69a6004a9c843851d9f6c9aee84c88389cb1f` after reviewing fresh in-game overview, Cloud-Seal Orrery, and Alpine Escarpment captures. The machine-readable receipt is `docs/media/AUI-10R-REVISION-2-HUMAN-APPROVAL.json`.

This verdict clears final-art placeholders only for the twelve `world.s1.*` manifest entries and binds all staging/runtime provenance to Poseidon, the verdict timestamp, receipt hash, and accepted candidate. It does not approve Agent E assets, AUI-12 UI, other stages, gameplay, stage geometry, save/hash/replay, localization, or thresholds. Because the verdict changes repository bytes, landing remains conditional on a fresh cache-cleared RELEASE, cross-process replay identity, independent audit, localization-impact review, and exact merged-union verification.

## Method enforcement

Poseidon activated MGS METHOD v2 `DEFAULT` project-wide with immediate effect. AUI-00 and AUI-10R route to `RELEASE` because they change `test/**` and `selftest/**`; RELEASE evidence is fresh-only and cannot be reused.

## Coordination

Shared ledgers and `FEATURES.json` remain serial integration surfaces. The AUI-10R closure transaction preserves Agent F's exact AUI-12 row and owned paths while removing only the completed Agent D claim.

## AUI-12 serialized ownership amendment

- Effective base: clean `master` at `ed66d67e67e56f5b41f3fb52a812a78452b9db0d`.
- Reason: current project policy requires stable localization keys, exact English fallbacks, `en-US` default, a Settings/locale selector seam, placeholder/catalog parity, glyph/layout gates, and deterministic-state exclusion from the first visible AUI phase.
- Added exclusive Agent F paths for AUI-12: `autoloads/i18n.gd`, `localization/en-US.json`, and `test/test_i18n.gd`, plus the UI component, presentation-Theme, five compatible-screen, focused-test, render-scenario, and handoff paths enumerated in `docs/todo.md`.
- Frozen pre-build authority: plan SHA-256 `29022e14441c3842f5c364ae3423bb30d12b8897e11b4d2064e0f3a8e32586b0`; independent preflight PASS with zero critical/warning findings.
- This amendment does not approve or ingest Agent D runtime assets, consume Agent E work, alter simulation/deterministic state, or authorize landing without fresh RELEASE evidence, independent audit, and Poseidon's exact-candidate playable-Web/en-US review.
- The historical Agent 8 `TD-006` claim never modified localization/runtime paths and is no longer active in `docs/todo.md`; AUI-12 is the current serialized owner of the three localization paths above.
