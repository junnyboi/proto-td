# Prototype TD — Final Audit Report (Phase 11)

## 1. The frozen build

| | |
|---|---|
| Frozen commit | `218aaea` ("lane A v2: terrain read + portrait fidelity pass") |
| Tag | `poc-v1-audit` |
| Audit date | 2026-08-09 |
| Engine | Godot 4.7.1 stable (pinned; `~/bin/godot`) |
| Reproduce | `scripts/verify.sh --full` (artifacts wiped first) |
| Full-ladder wall time | **109 s** (53 rungs; the polish round's budget line) |

Fresh-evidence discipline: `artifacts/` was deleted at the frozen hash before the run — every
artifact cited below was produced by this audit's own uninterrupted `--full` pass, unattended.

## 2. Acceptance criteria (parent plan §9, all 12 rows)

| # | Criterion | Status | Evidence |
|---|---|---|---|
| 1 | Ladder green every phase | **PROVEN** | per-phase as-built docs (`td-phase-0-1` … `td-phase-10` + Lane A commit) + the commit trail; `artifacts/verify.json` is per-run and gitignored, so the *history* lives in the docs — stated honestly, per plan F2 |
| 2 | Determinism oracle | **PROVEN** | GUT in-process oracles every phase (P1 core; trap-heavy P6; spell-heavy P7; debug-heavy P8; s8 campaign P10) **+ this audit's cross-process check**: `bot_campaign` ×2 and `bot_stage_08` ×2 as separate OS processes → normalized telemetry byte-identical (§4.1) |
| 3 | Conservation invariants | **PROVEN** | P3 full invariant + P7 charm ledger (`spawned == alive+killed+leaked+charmed`; `charmed == alive+dead+exited`) asserted every tick in GUT; re-run green in this sweep |
| 4 | Composition beats stats | **PROVEN** | P4 drone proof (all-Defender DEFEAT → +1 Sniper CLEAR); twist analogue: S6 charm win/loss GUT pair + `bot_stage_06_no_charm` DEFEAT in R5 while `bot_stage_06` clears |
| 5 | Debug reaches everything | **PROVEN** | `debug_reach`: all 11 stages jumped by scan, all 10 operators granted + one deployed through normal validation, both traps + both spells reachable, DP/HP/cooldowns set, pause/4× |
| 6 | Fun (human) | **HUMAN-PENDING** | `PLAYTEST.md` §2–§3, verdict ledger row family "fun" |
| 7 | A stage forces a composition change (human) | **HUMAN-PENDING** | `PLAYTEST.md` — S4 (Snipers) and S6 (Charm) are the designed forcing stages |
| 8 | Skills/deploys feel responsive (human) | **HUMAN-PENDING** | `PLAYTEST.md` juice questionnaire |
| 9 | Voluntary replay (human) | **HUMAN-PENDING** | `PLAYTEST.md` §2 final block (observed, not asked) |
| 10 | ≥80% of verdicts are data edits | **LEDGER OPEN** | `PLAYTEST.md` §4 verdict ledger (numerator/denominator at the bottom). Interim signal: P10's stage tuning was 4 rounds, 100% data/timeline edits |
| 11 | PAINPOINTS delivered | **PROVEN** | `PAINPOINTS.md` — 20+ entries across all phases, category index appended (audio generation honestly empty) |
| 12 | Juice-automation verdict | **PROVEN-INTERIM** | `JUICE_VERDICT.md` — spec-first automation verdict + 7 item entries; final slot stays open for post-polish |

## 3. Rung results (this audit's run)

- **R2 import + R2.5 stage lint**: pass — 11 stages green over all lint families (paths, waves,
  rewards resolve + no double grants, dense campaign 1..8, teach-before-use via the shared
  derivation, hp monotonicity 240→1155, hygiene, filename⇔id).
- **R3 GUT**: 15 suites, **102 tests / 21,778 asserts — run twice back-to-back, identical**.
- **R4a headless**: 14/14 scenarios pass.
- **R4b windowed**: 14/14 pass, 48 shots captured, **zero `pixel_skipped`** across all
  pixel-bearing scenarios (the render-lane gate condition). 7 scenarios carry the
  `expect_done` completion sentinel (all pixel-bearing/abort-prone ones; pre-P9 model-assert
  scenarios predate it by design).
- **R5 bots**: 11/11 pass — `bot_idle` (stability floor), `bot_stage_01..08` (clears, in
  band), `bot_stage_06_no_charm` (expected DEFEAT), `bot_campaign` (S1→S8 through the real
  unlock flow).
- **R6 gates**: 11/11 tier-1 GO; tier-2 bands confirmed still `{}` (human-owned, correct
  pre-round-1 state).

Per-stage campaign readout (from `bot_campaign`, cross-process stable):

| Stage | Result | Leaks | Stars | Terminal tick |
|---|---|---|---|---|
| s1 First Stand | CLEAR | 0 | 3 | 902 |
| s2 Tempo | CLEAR | 2 | 2 | 972 |
| s3 The Choke | CLEAR | 1 | 2 | 1130 |
| s4 Air Raid | CLEAR | 2 | 2 | 957 |
| s5 High Ground | CLEAR | 0 | 3 | 1495 |
| s6 Turncoat | CLEAR | 1 | 2 | 1439 |
| s7 Full Kit | CLEAR | 0 | 3 | 1642 |
| s8 The Gatecrasher | CLEAR | 1 | 2 | 2144 |

Standalone `bot_campaign` wall time: **0.56 s** (parent budget ~90 s; model-driven stepping).

## 4. Audit-only checks

1. **Cross-process replay determinism** (acceptance #2's missing half — in-process oracles
   can't see load-order/interning effects): `bot_campaign` and `bot_stage_08`, two fresh OS
   processes each, telemetry normalized (`wall_ms`/engine dropped) → **identical** both pairs.
2. **Ledger ⇔ tree ⇔ run**: every `FEATURES.json` `passing` entry's scenarios exist on disk
   and ran green in this sweep; zero `wip_` scenarios; 11 bots on disk == 11 in the R5 sweep.
3. **Vacuous-green sweep**: zero pixel skips (checked per report.json), sentinel adoption
   enumerated, tier-2 bands empty. The two known lying channels are closed and checked closed.
4. **Code-blind shot review**: 48 shots reviewed against their originating phase-doc
   checklists (16 in close review this audit, the remainder at their phase gates against the
   same checklists). All items pass — block clusters form with ticking HP bars; deploy
   highlights are the verb's own validation; the sniper tracer visibly downs drones; tar/spike
   glyphs distinct; charm conversion unmistakable (ally-blue vs enemy-red on the road); banner,
   stamp + star count == model stars; debug overlay reaches all 11 stages; squad cards, locks,
   stars and reward reveal legible; contact sheet shows the v2 art (road tile, portrait cards).
   One L7-flagged observation (not a gate item): warm-palette operator battle sprites can read
   grunt-like at a glance in a mixed cluster — PLAYTEST.md asks the human to judge.

## 5. Per-phase summary (the growth curve)

| Phase | Commits | Headline gate | Deviations |
|---|---|---|---|
| P0–P1 scaffold + model core | `1afa105`, `3f21539` | determinism oracle | 7 (td-phase-0-1 §8) |
| P2–P3 economy + combat | `daf6f3a`, `1c2f5be` | DP ledger property; conservation with kills | 9 (td-phase-2-3 §8) |
| P4–P5 classes + skills | `257edad`…`394aea1` | composition proof; skill-timing pair | 10 (td-phase-4-5 §8) |
| P6–P7 traps + spells/charm | `16f9091`, `44630f4` | trap exactness; charm win/loss pair + extended conservation | 8 (td-phase-6-7 §8.4, incl. Frost Field OUT) |
| P8 debug mode | `d31dc36` | acceptance #5 via debug_reach | 4 (td-phase-8 §9) |
| P9 juice pass | `70299bd`, `b9d1b2f` | 7 checklists, zero pixel skips | 6 (td-phase-9 §11) |
| P10 campaign (+ Lanes B/C) | `0eaf9ad`, `13f5251` | full-campaign bot clear + differentials | 5 + 7 pre-numbered exercised (td-phase-10 §11/§8) |
| Lane A art v1 | `c8ee84d` | assets_floor gate | 6 (commit report) |
| Pre-freeze audit + art v2 | `83b7368`, `218aaea` | P10 adversarial audit findings fixed; fidelity pass | 3 (§6 below) |

Suite growth: 1 scenario / 0 bots / ~450 asserts (P1) → 14 scenarios × 2 lanes / 11 bots /
21,778 asserts (frozen build).

## 6. Master deviations log

Every numbered deviation lives in its phase doc's as-built record with original numbering
preserved (pointers above; none silent — the per-phase counts sum to **58**). The audit
session's own three:

1. **Lane A policy (plan §1.2.4)**: resolved as option (a) — Lane A ran *before* the audit
   (`c8ee84d`, separate session, human-sanctioned), then a user-directed **art v2 fidelity
   pass** (`218aaea`: road/ground terrain read, portrait cards + glint/blush, portrait
   `placeholder` flags retired) landed pre-freeze so the audit covers it. Owner: human.
2. **A P10 adversarial code audit ran pre-freeze** (this session) and found one major defect —
   the spell bar's "empty loadout = show all" sentinel collided with the campaign's
   legitimately-empty starting spell set (Bolt/Charm castable from S1) — plus four hygiene
   items (lint scope holes: filename⇔id, campaign_index 0, dead campaign metadata;
   debug_reach budget note; bot_stage_08 row order). All fixed in `83b7368`; campaign_flow
   now asserts the S1 in-battle spell bar is empty. Verified-clean list in the audit record.
3. **Shot re-review scope**: 16 shots re-reviewed closely this audit; the rest stand on their
   phase-gate reviews against identical checklists (all 48 re-captured fresh this run).

## 7. Known gaps carried forward

- **Juice VFX are still rect placeholders** (dust/sparks/vignette/swirl/banner/stamp) — Lane A
  deviation 5, deliberate scope; polish round owns sprite-frame VFX.
- **Bolt has no impact visual** (P9 §2.1.11) — was mitigated by SFX only; with audio removed
  under deviation D-SFX (§9) the hole is fully unmitigated.
- **`boss_hit` shake whitelist entry unwired** — P10 added no boss-attack model record; the
  slot waits in `juice_config.tres`.
- **All audio silent by owner decision** — deviation D-SFX (§9): no SFX playback, no
  `MusicPlayer`; the `sfx_played` telemetry seam stays wired.
- **`--render` Movie Maker lane not re-proven this audit** (proven once in P9; not in
  per-commit verify by design).
- **Juice durations are render-frame counts** — visual lifetimes halve at 120 Hz vs 60 Hz
  (P9 §2.1.2; conversion to seconds is a schema-level data edit reserved for L7 verdicts).
- **Operator-vs-enemy palette proximity** (shot-review observation) — L7 question.

## 8. Handoff

- **Human rounds** (next): play per `PLAYTEST.md`; fill the verdict ledger; round-1 companion
  work (tier-2 evaluator in `quality_gate.sh`, bands, baselines, data edits) is specced in
  td-phase-11 §6 and lands *after* this tag.
- **Polish round** owns: Lane A VFX/portrait fidelity beyond v2, music, Bolt visual,
  `boss_hit` wiring, final `JUICE_VERDICT.md` entry.

## 9. Phase 14 addendum (2026-08-11) — post-audit remediation

Sections 1–8 above are the frozen record of the Phase 11 audit at `218aaea` and are preserved
as written. Since that freeze: P12 (iso view), P13 (battle QoL), the web-export fixes, and the
2026-08-11 **comprehensive build audit at `200aec5`** (fresh evidence ALL GREEN — verify
`--full` 119 s, GUT twice-identical 120/22,358, cross-process replay IDENTICAL, zero pixel
skips — plus 25 verifier-confirmed findings). Phase 14 (td-phase-14.md) is the remediation
round for those findings. This round's entries in this file:

1. **Deviation D-SFX** (owner decision, 2026-08-11): **audio is intentionally absent** — the
   placeholder synth SFX were removed at `81ec642` and the owner ruled the silence deliberate;
   the presentation-floor audio rule is **waived** until audio returns. The `sfx_played`
   telemetry seam stays wired (event-wiring evidence). Restoration recipe:
   `git show 81ec642^:tools/gen_sfx.gd`. Recorded in FEATURES.json `deviations`; PLAYTEST.md
   audio questions struck N/A-by-design; JUICE_VERDICT.md open audio questions closed as
   waived. The defect the audit flagged was the *unrecorded* silence, not the silence.
2. **s6 wave-window retune** (phase 14.3): `wave_starts` `(0, 500, 900)` → `(0, 500)` — the
   last spawn is tick 690, so the 900 boundary produced a ghost "WAVE 3" banner with zero
   spawns and a phantom third Charm window. `bot_stage_06`'s timeline was rewritten to one
   charm per remaining window (tick 320 → heavy 3 in window 0; tick 700 → heavy 8 in
   window 1). New terminal readout (supersedes the s6 row in §3's frozen-build table):
   **CLEAR, 1 leak, 2 stars, terminal tick 1319**; `bot_stage_06_no_charm` still DEFEATs at
   4 leaks — the charm differential holds untouched.
3. **Ledger backfill**: the 14 hollow `commits` rows in FEATURES.json (P1–P11, LA, LB, LC)
   now point at their phase commits; a P14 row tracks this round.
