# TD-019 — Plain Class Display Names

**Owner:** AGENT 2  
**Branch:** `agent-2/td-019-class-display-names`  
**Base:** `98a9be388064aacaadd8fdc10570533a3cd9ef46`  
**Implementation commit:** `0e0c0c42b753d946b88889061ee7d46c5518061b`
**Date:** 2026-08-13

## Outcome

The ten existing operator templates keep their internal IDs and combat payloads while exposing the owner-approved plain English class names:

| Template ID | Display name |
|---|---|
| `vanguard_1` | Shock Trooper |
| `vanguard_2` | Banner Guard |
| `guard_1` | Swordmaster |
| `guard_2` | Sword Saint |
| `defender_1` | Defender |
| `defender_2` | Immovable |
| `sniper_1` | Gunner |
| `sniper_2` | Sniper |
| `caster_1` | Mage Apprentice |
| `caster_2` | Sorcerer |

S2 and its active playtest instruction now say **Shock Trooper**. Witch Doctor remains approved lore/planning only; no template, skill, unlock, simulation, save, hash, replay, or UI behavior was added.

## Protected boundaries

- Existing template IDs remain unchanged.
- `OperatorDef.OpClass` remains unchanged.
- Stats, skills, ranges, DP costs, art IDs, unlocks, simulation, save/hash/replay, thresholds, and AUI-12 paths remain unchanged.
- `caster_2` remains the Tempest damage/control projection and now displays **Sorcerer**.
- `localization/en-US.json` was not touched because AUI-12 owns it. Current resource labels are the exact English fallbacks keyed by stable template IDs.

## Verification chronology

1. Current master baseline: `scripts/verify.sh` — **ALL GREEN**.
2. Focused class contract: `3/3` tests, `55` assertions — **PASS**.
3. First `scripts/verify.sh --full`: **RED**, because the existing provenance gate correctly detected changed OperatorDef source hashes.
4. Repair: ran canonical `tools/gen_assets.gd`; only `assets/manifest.tres` and the exact eighteen operator/portrait sidecars for the nine changed resources changed.
5. Focused class + presentation contracts: `12/12` tests, `1,778` assertions — **PASS**; canonical provenance validator printed `AUI00_PROVENANCE_OK`.
6. Restarted `scripts/verify.sh --full` from the beginning: **ALL GREEN**, including 24 headless scenarios, 24 windowed scenarios, campaign/idle/stage bots, and all quality gates.
7. Obsolete player-facing label scan over operator/stage fallback strings and active `PLAYTEST.md`: **PASS**, zero matches.
8. `git diff --check`: **PASS**.
9. Independent non-implementer diff-vs-pins audit: **PASS**, zero findings; exact 33-file diff safe to commit. It independently reported `194/194` tests and `25,196` assertions green and verified that no AUI-12 path changed.

## Scope note

Internal identifiers, comments, and test diagnostics may still use `vanguard` because that is a stable implementation family/ID, not a player-facing label. Renaming those would create needless save, replay, and code churn—the sort of heroism usually performed by bugs.
