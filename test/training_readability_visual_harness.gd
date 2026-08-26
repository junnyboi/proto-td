extends Node


func _ready() -> void:
	Game.set_run_seed(1701)
	if not Game.start_campaign(false, true):
		push_error("training_readability_visual_harness: campaign fixture failed")
		return
	Game.training_return_path = &"staging"
	var scene := load("res://scenes/training.tscn") as PackedScene
	var training := scene.instantiate()
	add_child(training)
