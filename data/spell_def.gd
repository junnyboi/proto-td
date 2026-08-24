class_name SpellDef
extends Resource

## Player-cast spell archetype (all balance is data — architecture rule 4).
## from the spell bar, validated by the model against the full catalog.
## COOLDOWN spells are castable when tick >= ready_at_tick; ONCE_PER_WAVE
## spells are castable once per wave window (windows delimited by
## StageDef.wave_starts; a cast on the wave-start tick itself is allowed).
## radius is Chebyshev (1 = the 3x3 square). target_kind CELL takes a
## Vector2i grid cell; ENEMY takes an enemy id.

enum Availability { COOLDOWN, ONCE_PER_WAVE }
enum TargetKind { CELL, ENEMY }
enum Effect { BURST_DAMAGE, SLOW_FIELD, CHARM }

const DamageRulesScript := preload("res://sim/damage_rules.gd")

@export var id: StringName = &""
@export var display_name: String = ""
@export var cooldown_ticks: int = 0
@export var availability: Availability = Availability.COOLDOWN
@export var target_kind: TargetKind = TargetKind.CELL
@export var effect: Effect = Effect.BURST_DAMAGE
@export var damage: int = 0
@export_enum("Physical", "Arts") var damage_kind: int = DamageRulesScript.Kind.PHYSICAL
@export var radius: int = 1
@export var duration_ticks: int = 0
@export var slow_permille: int = 0
@export var icon_id: StringName = &""
