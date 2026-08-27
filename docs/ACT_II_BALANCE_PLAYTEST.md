# Act II Balance Playtest — S9, S12, and S16

**Author:** Manus AI

**Engine:** Godot 4.7.2
**Method:** deterministic simulation against canonical `BattleModel` actions and content

## Purpose

This playtest evaluated the opening Act II operation (**S9 — The Green Cage**), the mid-act mechanics exam (**S12 — Unlit**), and the final boss operation (**S16 — Empire Foundry**). Stage identity changed during concurrent Anima War reconciliation, but stable IDs, maps, paths, enemies, mechanics, and deterministic simulation remained intact. The goal was to preserve the intended progression curve: S9 must teach the repair-platform mechanic without stalling, S12 must demand deliberate Slow Field timing across three lanes, and S16 must defeat an under-equipped field policy while remaining clearable by a disciplined six-operator squad.

## Method

The permanent `act2_balance_playtest_test.gd` harness executes three deterministic policies twice and rejects any replay mismatch. **Field** deploys four operators without spells or traps. **Standard** deploys the full recovery roster, places Tar Pit and Spike Plate, activates skills, heals, Charms priority ground targets, casts Bolt into groups, and places Slow Field over occupied Restoration Lattices. **Rapid** uses the same tools with a five-tick decision interval to stress discrete cooldown timing. Every run records outcome, stars, duration, leaks, base HP, concurrent enemy pressure, unit losses, Restoration healing, and action counts.

The raw before/after datasets are retained beside this report. They are generated from real repository content and simulation logic; no random or synthetic observations were introduced.

## Baseline findings

| Stage | Standard result | Stars | Duration | Leaks | Peak alive | Restoration healed | Finding |
|---|---:|---:|---:|---:|---:|---:|---|
| S9 | Clear | 3 | 58.3 s | 0 | 8 | 11 HP | Safe but slightly too spacious after the mechanic tutorial |
| S12 | Clear | 2 | 79.3 s | 1 | 11 | 20 HP | Pressure was appropriate, but the 30-tick irregularity at the wave boundary made cadence feel accidental |
| S16 | Clear | 2 | 102.5 s | 1 | 14 | 8 HP | Correct outcome, but one-leak defeat tolerance and 30-tick inter-wave rests made the finale brittle rather than demanding |

The field profile cleared S9 and S12 at two stars but failed S16. That is the desired qualitative hierarchy. S16 therefore needed **readability and recovery space**, not lower enemy composition or boss HP.

## Tuning applied

| Stage | Spawn-rate change | Difficulty change | Design rationale |
|---|---|---|---|
| S9 | Waves two and three tighten from 60-tick to 50-tick cadence; the final wave begins at tick 870 instead of 900 | Enemy roster and leak limit remain unchanged | Raises the opening Act II tempo without invalidating the Restoration Lattice lesson |
| S12 | All spawns now follow a continuous 60-tick cadence; wave boundaries align at ticks 480 and 1020 | Enemy roster, lattice tuning, and leak limit remain unchanged | Removes the anomalous 30-tick burst and makes pressure legible, rhythmic, and learnable |
| S16 | Wave boundaries move to 0/510/1050/1590 with 120-tick inter-wave recovery; final spawn moves to tick 2100 | Leak limit rises from 1 to 2; enemy roster, dual minibosses, and lattice healing remain unchanged | Keeps the boss lethal to incomplete play while giving a disciplined squad enough deployment and cooldown recovery to execute the intended counterplay |

The post-balance presentation pass marks the escalation windows with authored high-threat telegraphs: S9 waves two and three, S12 waves two and three, and S16 waves two through four. These indicators do not change simulation. They make the tuned cadence legible with stage-specific HUD emblems and spawn-point particle effects; the full contract is recorded in [High-Threat Wave Warning System](HIGH_THREAT_WAVE_WARNINGS.md).

## Final results

| Stage | Policy | Result | Stars | Duration | Leaks | Base HP | Peak alive | Weighted pressure | Unit falls | Restoration healed |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| S9 | Field | Clear | 2 | 54.5 s | 1 | 9 | 10 | 11 | 2 | 0 HP |
| S9 | Standard | Clear | 3 | 54.4 s | 0 | 10 | 8 | 9 | 1 | 9 HP |
| S9 | Rapid | Clear | 3 | 54.4 s | 0 | 10 | 8 | 9 | 1 | 9 HP |
| S12 | Field | Clear | 2 | 68.3 s | 2 | 8 | 11 | 13 | 2 | 40 HP |
| S12 | Standard | Clear | 3 | 68.1 s | 0 | 10 | 11 | 13 | 2 | 20 HP |
| S12 | Rapid | Clear | 2 | 73.7 s | 1 | 9 | 11 | 13 | 3 | 30 HP |
| S16 | Field | Defeat | 0 | 87.9 s | 3 | 7 | 13 | 16 | 2 | 144 HP |
| S16 | Standard | Clear | 2 | 107.5 s | 1 | 9 | 13 | 16 | 2 | 56 HP |
| S16 | Rapid | Clear | 2 | 107.0 s | 1 | 9 | 13 | 16 | 2 | 56 HP |

S9 is **6.6% shorter** under the standard policy while retaining a clean three-star clear. S12 is **14.1% shorter** and improves from a two-star to a three-star standard clear; the field policy still leaks twice, so spell discipline remains meaningfully rewarded. S16 is **4.8% longer**, still defeats the field profile, and gives both full-tool policies stable two-star clears. Slow Field reduces hostile Restoration healing from 144 HP to 56 HP in S16, preserving the act-defining mechanic as the decisive counter rather than decorative floor art.

## Acceptance envelope

The regression now requires deterministic replay parity; clear results for standard and rapid policies on all three stages; field clears on S9/S12; a field defeat on S16; three stars on standard S9; at least two stars on standard S12; exactly two stars on standard S16; bounded durations of 45–70, 60–90, and 90–125 seconds; and measurable Restoration suppression on S12/S16. This protects the intended curve without freezing every incidental tick, leaving future enemy-stat tuning possible.
