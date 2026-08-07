class_name EnemyState
extends RefCounted

## Per-enemy authoritative state (architecture rule 1: plain data, no Node).
## Positions are fixed-point integers (micro-tiles) so state hashes
## identically across platforms; step_units is precomputed once at spawn.

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
