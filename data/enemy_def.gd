class_name EnemyDef
extends Resource

## Enemy archetype (all balance is data — architecture rule 4). Full schema
## declared from Phase 1; combat fields (atk, block_weight) activate in
## Phase 3, aerial in Phase 4, charm_immune in Phase 7.

const TargetPolicyDefScript := preload("res://data/target_policy_def.gd")

@export var id: StringName = &""
@export var hp: int = 1
@export var atk: int = 0
@export var atk_interval_ticks: int = 30
@export var speed_tiles_per_s: float = 1.0
@export var aerial: bool = false
@export var block_weight: int = 1
@export var leak_damage: int = 1
@export var charm_immune: bool = false
## Chebyshev range for ranged enemies (spellcaster); 0 = melee-only.
@export var atk_range_cells: int = 0
@export var target_policy: TargetPolicyDefScript = null
@export var sprite_id: StringName = &""
