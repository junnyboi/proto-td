# AUI Design Approval and Gate Amendment

- Status: accepted
- Decision owner: Poseidon
- Effective date: 2026-08-12
- Scope: Aetheria D/E/F design gate, AUI-00, and serialized AUI-12 presentation ownership

## Frozen facts

- `AUI-DESIGN-F` is approved at manifest SHA-256 `7dd6b1ca88d57bd4532c195f196f2ec44a46955dabf370ce774ea3ebc2037ed7`.
- `AUI-DESIGN-D` is approved by Poseidon's attestation. The authenticated `AUI-10-Agent-D-Handoff.zip` arrived at SHA-256 `64a1bb4b87f09762a6f20fa77f289d158c91fa9c384ecd3c67b94a1266ef9e43`, and its 40-file internal manifest verifies. It is a source/staging handoff—not the exact approved design packet/accepted manifest hash—and its own `HANDOFF.json` requires that missing evidence before runtime ingestion. D runtime ingestion therefore remains blocked.
- Agent D's staged world package is present on `master` at `3b7ba225c90add20924b5a3aef99133162f64531` / tree `bf80de76a3298882d384a6669b67301e66f72862`; all eight candidates remain `STAGED_UNBOUND` and human-final unset.
- `AUI-DESIGN-E` is still iterating. No E approval, accepted hash, asset consumption, or E-dependent successor claim is permitted.

## Narrow amendment

Poseidon explicitly authorized AGENT F to start **AUI-00** with D and F approved while E remains blocked. This does not retire the collective D/E/F gate for later E-dependent packages and does not convert a missing artifact into evidence.

AUI-00 may land additive presentation contracts, compatibility APIs, truthful provenance migration, probe ownership, tests, and current-build baselines. It may not ingest D runtime assets, consume E work, create visible Aetheria UI, or claim a player-facing milestone.

## Method enforcement

Poseidon activated MGS METHOD v2 `DEFAULT` project-wide with immediate effect. AUI-00 routes to `RELEASE` because it changes `test/**` and `selftest/**`; RELEASE evidence is fresh-only and cannot be reused.

## Coordination

Active Agent 8 lane `TD-006` owns `docs/todo.md` and `docs/completed.md`. AUI-00 excludes both shared hot files. Its canonical lease is external and mirrored in `docs/plans/AUI-IMPLEMENTATION-STATUS.md` until the Agent 8 lease releases.

## AUI-12 serialized ownership amendment

- Effective base: clean `master` at `ed66d67e67e56f5b41f3fb52a812a78452b9db0d`.
- Reason: current project policy requires stable localization keys, exact English fallbacks, `en-US` default, a Settings/locale selector seam, placeholder/catalog parity, glyph/layout gates, and deterministic-state exclusion from the first visible AUI phase.
- Added exclusive Agent F paths for AUI-12: `autoloads/i18n.gd`, `localization/en-US.json`, and `test/test_i18n.gd`, plus the UI component, presentation-Theme, five compatible-screen, focused-test, render-scenario, and handoff paths enumerated in `docs/todo.md`.
- Frozen pre-build authority: plan SHA-256 `29022e14441c3842f5c364ae3423bb30d12b8897e11b4d2064e0f3a8e32586b0`; independent preflight PASS with zero critical/warning findings.
- This amendment does not approve or ingest Agent D runtime assets, consume Agent E work, alter simulation/deterministic state, or authorize landing without fresh RELEASE evidence, independent audit, and Poseidon's exact-candidate playable-Web/en-US review.
- The historical Agent 8 `TD-006` claim never modified localization/runtime paths and is no longer active in `docs/todo.md`; AUI-12 is the current serialized owner of the three localization paths above.
