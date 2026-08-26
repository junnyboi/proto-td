extends SceneTree

var _mode := "history"
var _premium_id := "archive_caster"
var _output_path := ""
var _viewport_size := Vector2i(1280, 720)


func _init() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--mode="):
			_mode = argument.trim_prefix("--mode=")
		elif argument.begins_with("--premium-id="):
			_premium_id = argument.trim_prefix("--premium-id=")
		elif argument.begins_with("--output="):
			_output_path = argument.trim_prefix("--output=")
		elif argument.begins_with("--viewport="):
			var parts := argument.trim_prefix("--viewport=").split("x")
			if parts.size() == 2:
				_viewport_size = Vector2i(int(parts[0]), int(parts[1]))
	call_deferred("_run")


func _run() -> void:
	if _output_path.is_empty():
		print("GACHA_HISTORY_VISUAL_HARNESS_OK")
		quit(0)
		return
	root.size = _viewport_size
	var game: Node = root.get_node_or_null("Game")
	if game == null:
		_fail("Game autoload missing")
		return
	game.call("set_run_seed", 9009)
	if not bool(game.call("start_campaign", false, true)):
		_fail("campaign fixture failed")
		return
	if _mode == "history" and not _seed_history(game):
		return

	var screen: Control = load("res://scenes/gacha.tscn").instantiate()
	screen.set("reduced_motion", true)
	root.add_child(screen)
	await process_frame
	await process_frame
	if _mode == "history":
		var history_button := screen.find_child("PullHistoryButton", true, false) as Button
		if history_button == null:
			_fail("History action missing")
			return
		history_button.pressed.emit()
		await process_frame
	else:
		var rarity := 5 if _premium_id == "lunaris_vessel" else 4
		var duplicate_pull := {
			"premium_id": _premium_id,
			"hero_id": "historyvisual00",
			"pull_index": 7,
			"new_hero": false,
			"revived": false,
			"lives_before": 2,
			"lives_after": 3,
			"pull_count_after": 3,
			"marks_before": 120,
			"marks_after": 80,
			"rarity": rarity,
			"five_star": rarity == 5,
			"pity_eligible": true,
			"pity_before": 2,
			"pity_after": 0 if rarity == 5 else 3,
			"pity_forced": false,
			"guarantee_in_after": 10 if rarity == 5 else 7,
			"save_revision": 2,
		}
		screen.call("_begin_reveal", duplicate_pull)
		await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_viewport().get_texture().get_image()
	var save_error := image.save_png(_output_path)
	if save_error != OK:
		_fail("screenshot save failed: %d" % save_error)
		return
	if _mode == "history":
		var drawer := screen.find_child("MoonArchiveDrawer", true, false) as Control
		var rows := screen.find_child("PullHistoryRows", true, false) as VBoxContainer
		if drawer == null or rows == null or rows.get_child_count() < 4:
			_fail("history visual state incomplete")
			return
	else:
		var conversion := screen.find_child("DuplicateConversionFeedback", true, false) as Control
		if conversion == null or not conversion.visible:
			_fail("conversion visual state incomplete")
			return
	print("GACHA_HISTORY_VISUAL_CAPTURE mode=%s viewport=%s path=%s" % [_mode, _viewport_size, _output_path])
	if bool(screen.get("_is_revealing")):
		screen.call("_finish_reveal")
		await process_frame
	var history_layer := screen.find_child("PremiumPullHistoryLayer", true, false) as Control
	if history_layer != null:
		history_layer.call("force_hide")
	game.set("campaign_active", false)
	game.set("campaign", null)
	game.set("campaign_store", null)
	game.set("content", null)
	root.remove_child(screen)
	screen.free()
	var music := root.get_node_or_null("Music")
	if music != null:
		music.call("stop")
	var sfx := root.get_node_or_null("Sfx")
	if sfx != null:
		sfx.call("stop_all")
	for _frame: int in 8:
		await process_frame
	await create_timer(0.25).timeout
	print("GACHA_HISTORY_VISUAL_HARNESS_OK")
	quit(0)


func _seed_history(game: Node) -> bool:
	for _index: int in 3:
		var committed: Dictionary = game.call("pull_premium_hero")
		if not committed.get("accepted", false):
			_fail("visual history pull failed")
			return false
	return true


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
