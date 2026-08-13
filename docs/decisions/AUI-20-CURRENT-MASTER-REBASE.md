# AUI-20 Current-Master Rebase Decision

- **Decision:** ADOPT INCUMBENT; RE-PREFLIGHT BEFORE IMPLEMENTATION
- **Date:** 2026-08-13
- **Owner:** AGENT F (Agent 7)
- **Owner verdict:** Poseidon approved the exact AUI-20 fixture packet.
- **Exact approval record SHA-256:** `05b37ab6d48ddcdd6e561c31699502fc53e0e70ecabd9eaa48b5e4323cc0cac6`
- **Fixture contract SHA-256:** `bd0f253b561a530905eb862dd1640ca53f940c9700fd4087a8592f018174f97f`
- **Current implementation base:** `b8a8474f1641980e9d056b39d727eea71e0f15d9`
- **Current tree:** `55a6a3c43a944cb0283956ceb7b9905b5645949a`
- **Current-base gate:** external `rebase-base-b8a8474-r2`, 35/35 default rungs PASS; `verify.json` SHA-256 `c22dfca6ae95d997a37ad571629b29f4a0507df7fcce7cd81cc47559b0a5c739`

## Why this decision exists

AUI-20 plan preflight 05 passed on ownership amendment `ee263ab`. Before implementation dispatch, default branch advanced to `b8a8474` with the incumbent directional grunt-animation runtime. Its exact AUI-20 overlap is `scripts/view/battle_view.gd`; the advance also established protected production conventions in `scripts/view/enemy_animator.gd`, `scripts/view/art.gd`, `assets/manifest.tres`, directional grunt assets/provenance, and `test/test_enemy_animator.gd`.

MGS requires a package to adopt a landed incumbent convention rather than reconstructing or overriding it. Therefore the v5 PASS is historical, not implementation authority. The approved fixture bytes remain exact and valid, but plan/Web identities must be re-preflighted against the current base.

## Frozen compatibility boundary

1. `EnemyAnimator`, `Art`, production `assets/manifest.tres`, directional grunt assets/provenance, and `test_enemy_animator.gd` are protected and may not change under AUI-20.
2. `BattleView` retains the explicit `EnemyAnimator` preload and delegates all production enemy position, z-order, direction, attack, charm, blend, shadow, and fallback behavior to that incumbent seam.
3. The AUI-20 selector is presentation-only and applies only to exact S1 fixture subjects: `vanguard_1` and ordinary noncharmed `grunt`.
4. Non-S1, charmed, nonbasic, missing-data, and fallback paths remain incumbent.
5. The fixture manifest is additive and AUI-20-only; no incumbent logical ID or production manifest entry is replaced.
6. Simulation, model, state hash, save/load, replay, telemetry, gameplay content, balance, audio, localization, `scripts/verify.sh`, and human thresholds remain untouched.
7. Independent plan-v6 PASS and a separate RELEASE orientation are required before any implementation byte.

## Evidence law

The final candidate must preserve the exact protected hashes recorded in plan v6, pass the unchanged nine-test EnemyAnimator suite, the landed `grunt_animation` scenario, full GUT, exact AUI-20 scenario/Web contracts, full RELEASE, independent diff-vs-pins audit, and Poseidon milestone review. Any attempted fix that changes the protected incumbent runtime requires a new owner amendment; it cannot be smuggled in as a PIVOT.
