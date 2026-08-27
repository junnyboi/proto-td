extends Node


class TrainingPathVisualCampaign:
	extends RefCounted

	const HERO_ID := "0000000000000001"
	const PATHS := [
		{"to_class_id": "defender", "operator_def_id": "defender_1"},
		{"to_class_id": "gunner", "operator_def_id": "sniper_1"},
		{"to_class_id": "mage_apprentice", "operator_def_id": "caster_1"},
		{"to_class_id": "shock_trooper", "operator_def_id": "vanguard_1"},
		{"to_class_id": "swordmaster", "operator_def_id": "guard_1"},
	]

	var _data := {
		"heroes": [{
			"hero_id": HERO_ID,
			"custom_callsign": "Niko Cinder",
			"custom_title": null,
			"name_version": 1,
			"recruitment_index": 0,
			"current_class_id": "recruit",
			"first_class_id": null,
			"advanced_class_id": null,
			"operator_def_id": "recruit",
			"portrait_asset_id": "portrait_recruit_00",
			"identity_portrait_id": "portrait_recruit_00",
			"life_status": "ready",
			"hero_kind": "recruit",
			"premium_id": null,
			"premium_lives": 0,
			"premium_pull_count": 0,
			"xp": 100,
		}],
	}

	func data_copy() -> Dictionary:
		return _data.duplicate(true)

	func promotion_options(hero_id: Variant) -> Dictionary:
		if String(hero_id) != HERO_ID:
			return {"accepted": false, "error_code": &"unknown_hero", "choices": []}
		var current_class_id := String(_data["heroes"][0]["current_class_id"])
		if current_class_id != "recruit":
			return {"accepted": false, "error_code": &"insufficient_xp", "choices": []}
		var choices: Array[Dictionary] = []
		for path: Dictionary in PATHS:
			choices.append({
				"from_class_id": "recruit",
				"to_class_id": path["to_class_id"],
				"operator_def_id": path["operator_def_id"],
			})
		return {"accepted": true, "error_code": &"", "choices": choices}

	func campaign_uid() -> String:
		return "training-path-visual"

	func save_revision() -> int:
		return 1

	func strategic_hash() -> Dictionary:
		return {"accepted": true, "value": "training-path-visual"}


	func set_identity_variant(variant: StringName) -> void:
		var portrait_id := "portrait_recruit_01" if variant == &"male" else "portrait_recruit_00"
		_data["heroes"][0]["portrait_asset_id"] = portrait_id
		_data["heroes"][0]["identity_portrait_id"] = portrait_id


	func set_current_class(class_id: String) -> void:
		if class_id.is_empty() or class_id == "recruit":
			return
		var definition := load("res://data/classes/%s.tres" % class_id) as ClassDef
		if definition == null:
			return
		_data["heroes"][0]["current_class_id"] = class_id
		_data["heroes"][0]["operator_def_id"] = String(definition.operator_def_id)
		_data["heroes"][0]["first_class_id"] = class_id
		_data["heroes"][0]["advanced_class_id"] = class_id
		_data["heroes"][0]["xp"] = 0


func _ready() -> void:
	Game.set_run_seed(1701)
	if not Game.start_campaign(false, true):
		push_error("advanced_training_path_visual_harness: campaign fixture failed")
		get_tree().quit(2)
		return
	var campaign := TrainingPathVisualCampaign.new()
	var requested_variant := StringName(OS.get_environment("TRAINING_IDENTITY_VARIANT"))
	campaign.set_identity_variant(requested_variant)
	campaign.set_current_class(OS.get_environment("TRAINING_CURRENT_CLASS"))
	Game.campaign = campaign
	Game.training_return_path = &"staging"
	var scene := load("res://scenes/training.tscn") as PackedScene
	var training := scene.instantiate()
	add_child(training)
	await _frames(6)
	if OS.get_environment("TRAINING_CURRENT_CLASS").is_empty():
		training.call("_show_paths")
		await _frames(6)
	if OS.get_environment("TRAINING_SELECT_FIRST") == "1":
		training.call("_on_path_selected", "defender")
		await _frames(3)
	var scroll_y_text := OS.get_environment("TRAINING_SCROLL_Y")
	if not scroll_y_text.is_empty():
		var outer_scroll := training.find_child("TrainingDialogScroll", true, false) as ScrollContainer
		if outer_scroll != null:
			outer_scroll.scroll_vertical = maxi(0, int(scroll_y_text))
			await _frames(3)
	var inspector_scroll_y_text := OS.get_environment("TRAINING_INSPECTOR_SCROLL_Y")
	if not inspector_scroll_y_text.is_empty():
		var inspector_scroll := training.find_child(
			"TrainingInspectorScroll", true, false,
		) as ScrollContainer
		if inspector_scroll != null:
			inspector_scroll.scroll_vertical = maxi(0, int(inspector_scroll_y_text))
			await _frames(3)
	var output := OS.get_environment("TRAINING_SCREENSHOT")
	if not output.is_empty():
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		var error := image.save_png(output)
		if error != OK:
			push_error("advanced_training_path_visual_harness: screenshot failed %s" % error)
			get_tree().quit(3)
			return
	var grid := training.find_child("PathCards", true, false) as GridContainer
	var back := training.find_child("PathBack", true, false) as Button
	var choose := training.find_child("ChoosePath", true, false) as Button
	print(
		"ADVANCED_TRAINING_PATH_VISUAL_OK columns=%d back=%s choose=%s" % [
			grid.columns if grid != null else 0,
			back.size if back != null else Vector2.ZERO,
			choose.size if choose != null else Vector2.ZERO,
		]
	)
	if OS.get_environment("TRAINING_AUTO_QUIT") == "1":
		get_tree().quit(0)


func _frames(count: int) -> void:
	for _index: int in count:
		await get_tree().process_frame
