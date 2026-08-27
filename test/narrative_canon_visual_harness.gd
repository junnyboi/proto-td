extends Node


class VisualCampaign:
	extends RefCounted

	var projection: Dictionary

	func _init(value: Dictionary) -> void:
		projection = value.duplicate(true)

	func runtime_projection() -> Dictionary:
		return projection.duplicate(true)


var _mode := "archive"
var _output_path := "/tmp/proto-td-narrative.png"
var _locale := "en-US"
var _entry_index := 1
var _text_scale := 1.0
var _stage_id := "s9"


func _ready() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--mode="):
			_mode = argument.trim_prefix("--mode=")
		elif argument.begins_with("--out="):
			_output_path = argument.trim_prefix("--out=")
		elif argument.begins_with("--locale="):
			_locale = argument.trim_prefix("--locale=")
		elif argument.begins_with("--entry="):
			_entry_index = clampi(argument.trim_prefix("--entry=").to_int(), 1, 4)
		elif argument.begins_with("--text-scale="):
			_text_scale = clampf(argument.trim_prefix("--text-scale=").to_float(), 0.8, 1.5)
		elif argument.begins_with("--stage="):
			_stage_id = argument.trim_prefix("--stage=")
	call_deferred("_run")


func _run() -> void:
	var i18n := get_tree().root.get_node_or_null("I18n")
	if i18n != null:
		i18n.call("set_locale", StringName(_locale))
	var text_scale := get_tree().root.get_node_or_null("TextScale")
	if text_scale != null:
		text_scale.call("set_scale", _text_scale)
	var game := get_tree().root.get_node("Game")
	if _mode == "title":
		var title := load("res://scenes/title.tscn").instantiate() as Control
		_mount(title)
		for _frame: int in range(3):
			await get_tree().process_frame
		var preferences := title.call("_current_preferences") as Dictionary
		preferences[&"locale"] = StringName(_locale)
		preferences[&"text_scale"] = _text_scale
		title.call("_apply_preference_values", preferences)
		await get_tree().create_timer(1.2).timeout
	elif _mode in ["staging", "campaign", "premium", "training", "valhalla"]:
		game.call("set_run_seed", 3310)
		game.call("start_campaign", false, true)
		var scene_path: String = {
			"staging": "res://scenes/staging.tscn",
			"campaign": "res://scenes/stage_select.tscn",
			"premium": "res://scenes/gacha.tscn",
			"training": "res://scenes/training.tscn",
			"valhalla": "res://scenes/vahalla.tscn",
		}[_mode]
		var screen := load(scene_path).instantiate() as Control
		_mount(screen)
		for _frame: int in range(10):
			await get_tree().process_frame
		if _mode == "campaign":
			screen.call("_show_dossier", StringName(_stage_id))
			for _frame: int in range(4):
				await get_tree().process_frame
		elif _mode == "training":
			var training_scroll := screen.find_child("TrainingDialogScroll", true, false) as ScrollContainer
			if training_scroll != null:
				training_scroll.scroll_vertical = 0
			for _frame: int in range(2):
				await get_tree().process_frame
	elif _mode == "archive" or _mode == "archive_audio":
		game.call("set_run_seed", 3308)
		game.call("start_campaign", false, true)
		var staging := load("res://scenes/staging.tscn").instantiate() as Control
		_mount(staging)
		await get_tree().process_frame
		await get_tree().process_frame
		var archive_button := staging.find_child("AnimaArchiveButton", true, false) as Button
		if archive_button != null:
			var projection: Dictionary = game.call("campaign_projection")
			var all_stage_stars := {}
			for stage_number: int in range(1, 8):
				all_stage_stars[StringName("s%d" % stage_number)] = 3
			projection["stage_stars"] = all_stage_stars
			game.set("campaign", VisualCampaign.new(projection))
			archive_button.emit_signal("pressed")
		for _frame: int in range(8):
			await get_tree().process_frame
		var archive := game.get("content") as Control
		var record_button := archive.find_child("ArchiveRecord_%02d" % _entry_index, true, false) as Button
		if record_button != null:
			record_button.disabled = false
			record_button.emit_signal("pressed")
			record_button.grab_focus()
		for _frame: int in range(4):
			await get_tree().process_frame
		if _mode == "archive_audio":
			var detail_scroll := archive.find_child("ArchiveDetailScroll", true, false) as ScrollContainer
			if detail_scroll != null:
				detail_scroll.scroll_vertical = 100000
			for _frame: int in range(4):
				await get_tree().process_frame
	elif _mode == "results":
		game.call("set_run_seed", 3309)
		game.call("start_campaign", false, true)
		var projection: Dictionary = game.call("campaign_projection")
		var hero_id := String(projection.get("ready_heroes", [])[0].get("hero_id", ""))
		game.set("last_result", {
			"stage_id": &"s1",
			"result": BattleModel.Result.CLEAR,
			"stars": 3,
			"kills": 14,
			"leaks": 0,
			"rewards_granted": [{"kind": "currency", "id": "marks", "amount": 40}],
			"class_entitlements_granted": [&"mage_apprentice"],
			"xp_awards": [{"hero_id": hero_id, "delta": 100}],
			"dead_hero_ids": [],
			"premium_life_losses": [],
		})
		_mount(load("res://scenes/results.tscn").instantiate())
		await get_tree().create_timer(0.9).timeout
		for _frame: int in range(3):
			await get_tree().process_frame
	else:
		push_error("Unknown narrative visual mode: %s" % _mode)
		get_tree().quit(1)
		return
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(_output_path)
	if error != OK:
		push_error("Could not save narrative capture: %s" % error)
		get_tree().quit(1)
		return
	await _cleanup()
	print("NARRATIVE_VISUAL_CAPTURE_OK mode=%s path=%s locale=%s entry=%d stage=%s text_scale=%.2f" % [_mode, _output_path, _locale, _entry_index, _stage_id, _text_scale])
	get_tree().quit(0)


func _mount(node: Node) -> void:
	get_tree().root.add_child(node)


func _cleanup() -> void:
	var game := get_tree().root.get_node_or_null("Game")
	if game != null:
		var content := game.get("content") as Node
		game.set("content", null)
		if content != null and is_instance_valid(content):
			var parent := content.get_parent()
			if parent != null:
				parent.remove_child(content)
			content.free()
		game.set("campaign_active", false)
		game.set("campaign", null)
		game.set("campaign_store", null)
	var music := get_tree().root.get_node_or_null("Music")
	if music != null and music.has_method("stop"):
		music.call("stop")
	var sfx := get_tree().root.get_node_or_null("Sfx")
	if sfx != null and sfx.has_method("stop_all"):
		sfx.call("stop_all")
	for _frame: int in range(12):
		await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout
