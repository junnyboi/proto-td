extends Node

## Session state + scene flow (all in-memory; every launch starts fresh).
## Phase 0 shell: seed seam + content-swap plumbing. start_battle() gains its
## real body in Phase 1 when StageDef/BattleModel/battle.tscn exist.

var run_seed: int = 42
var default_stage_id: StringName = &"test_lane"
var content: Node = null


func set_run_seed(value: int) -> void:
	run_seed = value
	seed(value)


func start_battle(stage_id: StringName) -> void:
	push_warning("start_battle(%s): battle scene lands in Phase 1" % stage_id)


func _swap_content(scene_path: String) -> void:
	if content != null and is_instance_valid(content):
		content.queue_free()
	var packed: PackedScene = load(scene_path)
	var node: Node = packed.instantiate()
	get_tree().root.add_child(node)
	content = node
