extends Node

var _mode := "archive"
var _output_path := "/tmp/proto-td-narrative.png"


func _ready() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--mode="):
			_mode = argument.trim_prefix("--mode=")
		elif argument.begins_with("--out="):
			_output_path = argument.trim_prefix("--out=")
	call_deferred("_run")


func _run() -> void:
	var game := get_tree().root.get_node("Game")
	if _mode == "title":
		_mount(load("res://scenes/title.tscn").instantiate())
		await get_tree().create_timer(1.2).timeout
	elif _mode == "archive" or _mode == "archive_audio":
		game.call("set_run_seed", 3308)
		game.call("start_campaign", false, true)
		var staging := load("res://scenes/staging.tscn").instantiate() as Control
		_mount(staging)
		await get_tree().process_frame
		await get_tree().process_frame
		var archive_button := staging.find_child("MercyArchiveButton", true, false) as Button
		if archive_button != null:
			archive_button.emit_signal("pressed")
		for _frame: int in range(8):
			await get_tree().process_frame
		if _mode == "archive_audio":
			var archive := game.get("content") as Control
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
			"xp_awards": [{"hero_id": hero_id, "xp": 6}],
			"dead_hero_ids": [],
			"premium_life_losses": [],
		})
		_mount(load("res://scenes/results.tscn").instantiate())
		for _frame: int in range(6):
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
	print("NARRATIVE_VISUAL_CAPTURE_OK mode=%s path=%s" % [_mode, _output_path])
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
