extends Node

## Session state + scene flow (all in-memory; every launch starts fresh, no
## persistence — per the POC scope). start_battle() swaps the content scene
## manually so it works both under the normal main-scene boot and under the
## selftest harness (which parents the main scene to root itself).

const BATTLE_SCENE_PATH := "res://scenes/battle.tscn"

var run_seed: int = 42
var default_stage_id: StringName = &"test_lane"
var default_squad: Array[StringName] = [&"vanguard_1", &"defender_1"]
var pending_stage: StageDef = null
var current_battle: BattleModel = null
var content: Node = null


func set_run_seed(value: int) -> void:
	run_seed = value
	seed(value)


func start_battle(stage_id: StringName) -> void:
	var stage_path := "res://data/stages/%s.tres" % stage_id
	if not ResourceLoader.exists(stage_path):
		push_error("unknown stage: " + stage_path)
		return
	pending_stage = load(stage_path) as StageDef
	_swap_content.call_deferred(BATTLE_SCENE_PATH)


func _swap_content(scene_path: String) -> void:
	if content != null and is_instance_valid(content):
		content.queue_free()
	var packed: PackedScene = load(scene_path)
	var node: Node = packed.instantiate()
	get_tree().root.add_child(node)
	content = node
