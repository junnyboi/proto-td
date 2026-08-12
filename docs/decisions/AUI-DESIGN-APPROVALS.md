# AUI Design Approval and Gate Amendment

- Status: accepted
- Decision owner: Poseidon
- Effective date: 2026-08-12
- Scope: Aetheria D/E/F design gate and AUI-00 only

## Frozen facts

- `AUI-DESIGN-F` is approved at manifest SHA-256 `7dd6b1ca88d57bd4532c195f196f2ec44a46955dabf370ce774ea3ebc2037ed7`.
- `AUI-DESIGN-D` is approved by Poseidon's attestation, but its packet and accepted manifest hash are not available in the project files, uploads, repository, or remote branches. D runtime ingestion remains blocked until that exact packet/hash is supplied.
- `AUI-DESIGN-E` is still iterating. No E approval, accepted hash, asset consumption, or E-dependent successor claim is permitted.

## Narrow amendment

Poseidon explicitly authorized AGENT F to start **AUI-00** with D and F approved while E remains blocked. This does not retire the collective D/E/F gate for later E-dependent packages and does not convert a missing artifact into evidence.

AUI-00 may land additive presentation contracts, compatibility APIs, truthful provenance migration, probe ownership, tests, and current-build baselines. It may not ingest D runtime assets, consume E work, create visible Aetheria UI, or claim a player-facing milestone.

## Method enforcement

Poseidon activated MGS METHOD v2 `DEFAULT` project-wide with immediate effect. AUI-00 routes to `RELEASE` because it changes `test/**` and `selftest/**`; RELEASE evidence is fresh-only and cannot be reused.

## Coordination

Active Agent 8 lane `TD-006` owns `docs/todo.md` and `docs/completed.md`. AUI-00 excludes both shared hot files. Its canonical lease is external and mirrored in `docs/plans/AUI-IMPLEMENTATION-STATUS.md` until the Agent 8 lease releases.
