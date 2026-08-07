class_name EnemyState
extends RefCounted

## Per-enemy authoritative state (architecture rule 1: plain data, no Node).
## Positions are fixed-point integers (micro-tiles) so state hashes
## identically across platforms; step_units is precomputed once at spawn.
## faction: a charmed entity stays in this one list (one movement system,
## one-list conservation arithmetic — td-phase-6-7.md §2.1); engaged_with
## is the 1v1 duel partner's entity id (-1 when free).

enum Faction { ENEMY, CHARMED }

var id: int = 0
var def_id: StringName = &""
var hp: int = 1
var hp_max: int = 1
var path_idx: int = 0
var progress_units: int = 0
var step_units: int = 0
var leak_damage: int = 1
var block_weight: int = 1
var atk: int = 0
var atk_interval_ticks: int = 30
var atk_counter: int = 0
var blocked_by: int = -1
var alive: bool = true
var aerial: bool = false
var atk_range_cells: int = 0
var stunned_until_tick: int = 0
var charm_immune: bool = false
var faction: Faction = Faction.ENEMY
var engaged_with: int = -1
# tick of death via a kill path (units/traps/Bolt/duels, either faction);
# stays -1 for leaks and charmed exits — kill juice keys off this because
# `alive == false` alone is reachable four ways (td-phase-9.md §2.1.7)
var died_at_tick: int = -1
