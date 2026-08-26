extends Node

const AdvancedTrainingVisualHarness := preload(
	"res://test/advanced_training_path_visual_harness.gd"
)


func _ready() -> void:
	var locale := OS.get_environment("TRAINING_LOCALE")
	if not locale.is_empty():
		I18n.set_locale(StringName(locale))
	Game.set_run_seed(1701)
	if not Game.start_campaign(false, true):
		push_error("training_readability_visual_harness: campaign fixture failed")
		return
	if OS.get_environment("TRAINING_PROMOTION_READY") == "1":
		Game.campaign = AdvancedTrainingVisualHarness.TrainingPathVisualCampaign.new()
	Game.training_return_path = &"staging"
	var scene := load("res://scenes/training.tscn") as PackedScene
	var training := scene.instantiate()
	add_child(training)
	if OS.get_environment("TRAINING_EDIT_OPEN") == "1":
		await get_tree().process_frame
		await get_tree().process_frame
		training.call("_on_edit_identity_requested")
	if OS.get_environment("TRAINING_SCROLL_INSPECTOR_BOTTOM") == "1":
		await get_tree().process_frame
		await get_tree().process_frame
		var inspector_scroll := training.find_child(
			"TrainingInspectorScroll", true, false,
		) as ScrollContainer
		var promotion_action := training.find_child(
			"ChoosePromotion", true, false,
		) as Control
		if inspector_scroll != null and promotion_action != null:
			inspector_scroll.ensure_control_visible(promotion_action)
