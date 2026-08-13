class_name OperatorDef
extends Resource

## Operator archetype (all balance is data — architecture rule 4). Full schema
## declared from Phase 2; range_offsets/facing rotation activate in Phase 4;
## the skill field lands in Phase 5 with the SkillDef class (as pinned in
## td-phase-2-3.md §3.2).

## Append-only: .tres resources serialize this enum by integer ordinal.
enum OpClass { VANGUARD, GUARD, DEFENDER, SNIPER, CASTER, HEALER }
enum Placement { GROUND, ELEVATED }

@export var id: StringName = &""
@export var display_name: String = ""
@export var op_class: OpClass = OpClass.GUARD
@export var rarity: int = 1
@export var dp_cost: int = 10
@export var block: int = 1
@export var hp: int = 100
@export var atk: int = 10
@export var atk_interval_ticks: int = 30
@export var range_offsets: Array[Vector2i] = []
@export var placement: Placement = Placement.GROUND
@export var dp_generation_interval_ticks: int = 0
## square splash side length for basic attacks; 0 = single target (P14:
## moved out of unit_state logic — rule 4)
@export var splash_dim: int = 0
@export var skill: SkillDef = null
@export var sprite_id: StringName = &""
@export var portrait_id: StringName = &""
