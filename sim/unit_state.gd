class_name UnitState
extends RefCounted

## Per-deployed-unit authoritative state (architecture rule 1: plain data, no
## Node). Stats are copied from OperatorDef at deploy so the model never
## re-reads Resources mid-battle. The units array in BattleModel is
## append-only: retreated and dead units stay in it (alive = false) for hash
## stability and history; redeploying creates a fresh UnitState.

enum Facing { RIGHT, DOWN, LEFT, UP }

var id: int = 0
var op_id: StringName = &""
var cell: Vector2i = Vector2i.ZERO
var facing: Facing = Facing.RIGHT
var hp: int = 1
var hp_max: int = 1
var alive: bool = true
var block: int = 0
var dp_cost: int = 0
var atk: int = 0
var atk_interval_ticks: int = 30
var atk_counter: int = 0
var dp_generation_interval_ticks: int = 0
var dp_generation_counter: int = 0
var blocked_ids: Array[int] = []
var op_class: OperatorDef.OpClass = OperatorDef.OpClass.GUARD
var range_offsets: Array[Vector2i] = []
var last_attack_tick: int = -1
var last_attack_cell: Vector2i = Vector2i(-1, -1)
