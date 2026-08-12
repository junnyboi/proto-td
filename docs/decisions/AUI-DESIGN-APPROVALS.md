# AUI Design Approval and Gate Amendment

- Status: accepted
- Decision owner: Poseidon
- Effective date: 2026-08-12
- Scope: Aetheria D/E/F design gate, AUI-00, AUI-34, and serialized AUI-12 presentation ownership

## Frozen facts

- `AUI-DESIGN-F` is approved at manifest SHA-256 `7dd6b1ca88d57bd4532c195f196f2ec44a46955dabf370ce774ea3ebc2037ed7`.
- `AUI-DESIGN-D` is approved by Poseidon's attestation. The authenticated `AUI-10-Agent-D-Handoff.zip` arrived at SHA-256 `64a1bb4b87f09762a6f20fa77f289d158c91fa9c384ecd3c67b94a1266ef9e43`, and its 40-file internal manifest verifies. It is a source/staging handoff—not the exact approved design packet/accepted manifest hash—and its own `HANDOFF.json` requires that missing evidence before runtime ingestion. D runtime ingestion therefore remains blocked.
- Agent D's staged world package is present on `master` at `3b7ba225c90add20924b5a3aef99133162f64531` / tree `bf80de76a3298882d384a6669b67301e66f72862`; all eight candidates remain `STAGED_UNBOUND` and human-final unset.
- `AUI-DESIGN-E` is approved by Poseidon's exact Round 5 token, authenticated at SHA-256 `5ab42289310a3176718a2d2c4c70f91aa87041564aaac0c6652bbf3295ece93b`. The accepted hashes are: roster `f3c338ec52a394e3e02a92bad65ca00e881fd340673ee6c120dec09c86b3b883`; Vanguard `db59ac74296fe4cbf6c78a3011bf78cdfd1c7814c576c7f22e8d02853d7135c9`; enemies `f512c5022533c53c4a84bcfd036a513d13ee5ec2667cba15283dff21fd373ea8`; portraits `d6db376800af86f300f6fa8ea7c62865ce4c8bb05dadd9dbe9d470776fa22ee9`; Charm `64039ab91598423982031948fefc30b5f9b2d93b803d51617cb88fcea2aa8dd3`; VFX `0a13437c7284fac6fbaf9e67be8223443bbdb3e47158a46325d007d691d17667`. This approves the concept packet for deterministic pipeline use; it does not flip `human_final_art`, bind runtime assets, or claim player-facing acceptance.

## Narrow amendment

Poseidon explicitly authorized AGENT F to start **AUI-00** while E was still blocked. That historical amendment did not convert missing evidence into approval. The later exact Round 5 token above now satisfies the E design gate for AUI-34 and successor planning.

## AUI-34 integrator amendment

Poseidon explicitly authorized AGENT 6 to integrate the terminal Agent E lane without Agent F. The immutable lane receipt remains unchanged; the owner override changes only the receiving integrator. AUI-34 may land its deterministic offline pipeline and synthetic QA fixtures after exact-union RELEASE and audit. Production character, portrait, enemy, Charm, and VFX runtime bytes remain deferred; `human_final_art` stays human-only and runtime binding stays unbound.

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
