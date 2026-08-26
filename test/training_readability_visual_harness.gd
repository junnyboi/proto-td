extends Node


func _ready() -> void:
	var locale := OS.get_environment("TRAINING_LOCALE")
	if not locale.is_empty():
		I18n.set_locale(StringName(locale))
	Game.set_run_seed(1701)
	if not Game.start_campaign(false, true):
		push_error("training_readability_visual_harness: campaign fixture failed")
		return
	Game.training_return_path = &"staging"
	var scene := load("res://scenes/training.tscn") as PackedScene
	var training := scene.instantiate()
	add_child(training)
	if OS.get_environment("TRAINING_EDIT_OPEN") == "1":
		await get_tree().process_frame
		await get_tree().process_frame
		training.call("_on_edit_identity_requested")
