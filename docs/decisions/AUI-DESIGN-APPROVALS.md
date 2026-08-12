# AUI Design Approval and Gate Amendment

- Status: accepted
- Decision owner: Poseidon
- Effective date: 2026-08-12
- Scope: Aetheria D/E/F design gates, AUI-00, and Agent D S1 runtime integration

## Frozen facts

- `AUI-DESIGN-F` is approved at manifest SHA-256 `7dd6b1ca88d57bd4532c195f196f2ec44a46955dabf370ce774ea3ebc2037ed7`.
- `AUI-DESIGN-D` is approved. The exact accepted manifest is now checked in at `docs/media/AUI-DESIGN-D-approved-manifest.json`; its accepted manifest SHA-256 is `91cfda9a1c5b199b5c69d42c82d58fbe4a186b270b828180b16ad7c1cb811e51`, its approval-receipt SHA-256 is `d7bdbb4b3401932a20fd1cfdf66b7ba3b05e3bab4b7b2133b9958162271781e1`, and all six canonical image hashes were reverified byte-for-byte.
- `AUI-DESIGN-E` is still iterating. No E approval, accepted hash, asset consumption, or E-dependent successor claim is permitted.

## Narrow amendment

Poseidon explicitly authorized AGENT F to start **AUI-00** with D and F approved while E remains blocked. This does not retire the collective D/E/F gate for later E-dependent packages and does not convert a missing artifact into evidence.

AUI-00 may land additive presentation contracts, compatibility APIs, truthful provenance migration, probe ownership, tests, and current-build baselines. It may not ingest D runtime assets, consume E work, create visible Aetheria UI, or claim a player-facing milestone.

## Agent D runtime amendment

Poseidon explicitly determined that Agent F is not a blocker for Agent D's own S1 assets and authorized Agent D to proceed. Agent F's remote `agent-f/aui-00` branch is fully contained in master at commit `a46fe9c`; its external lease expired, and no Agent F worktree, pull request, process, or active queue claim exists. Agent D therefore owns the isolated `AUI-10R` S1 runtime seam for the duration of its active lease.

This amendment is narrow: it permits `AUI-DESIGN-D`-verified S1 asset promotion, manifest IDs, presentation data, disposable view projection, tests, and visual evidence. It does not authorize any Agent E asset, deterministic-model change, stage-geometry change, threshold change, or inference of final human art acceptance.

## Method enforcement

Poseidon activated MGS METHOD v2 `DEFAULT` project-wide with immediate effect. AUI-00 and AUI-10R route to `RELEASE` because they change `test/**` and `selftest/**`; RELEASE evidence is fresh-only and cannot be reused.

## Coordination

`AUI-10R` owns its exact external lease and the active `docs/todo.md` row. `docs/completed.md` remains outside Agent D's lane. Shared-ledger and `FEATURES.json` edits are serialized and must be reconciled with current master before integration.
