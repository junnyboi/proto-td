class_name GameConfig
extends Resource

## Global battle parameters (all balance is data — architecture rule 4; no
## gameplay number lives in logic code). DP/SP parameters join in Phases 2/5.

@export var base_hp_start: int = 10
@export var ticks_per_second: int = 30
@export var dp_start: int = 10
@export var dp_regen_interval_ticks: int = 30
@export var dp_cap: int = 99
@export var retreat_refund_percent: int = 50
@export var sp_progress_interval_ticks: int = 30


func debug_dp_value_valid(value: int) -> bool:
	return value >= 0 and value <= dp_cap


func debug_base_hp_value_valid(value: int) -> bool:
	return value >= 0
