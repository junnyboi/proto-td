extends SceneTree

var _premium_id := "lunaris_vessel"
var _capture_seconds := 1.0
var _output_path := "/tmp/gacha-cinematic.png"
var _reduced_motion := false


func _init() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--premium-id="):
			_premium_id = argument.trim_prefix("--premium-id=")
		elif argument.begins_with("--capture="):
			_capture_seconds = float(argument.trim_prefix("--capture="))
		elif argument.begins_with("--output="):
			_output_path = argument.trim_prefix("--output=")
		elif argument == "--reduced-motion":
			_reduced_motion = true
	call_deferred("_run")


func _run() -> void:
	var game: Node = root.get_node_or_null("Game")
	if game == null:
		push_error("Game autoload missing")
		quit(1)
		return
	game.call("set_run_seed", 7007)
	if not bool(game.call("start_campaign", false, true)):
		push_error("campaign fixture failed")
		quit(1)
		return
	var screen: Control = load("res://scenes/gacha.tscn").instantiate()
	screen.set("reduced_motion", _reduced_motion)
	root.add_child(screen)
	await process_frame
	await process_frame
	var rarity := 5 if _premium_id == "lunaris_vessel" else 4
	var pull := {
		"premium_id": _premium_id,
		"hero_id": "cinematicvisual",
		"pull_index": 9 if rarity == 5 else 0,
		"new_hero": true,
		"revived": false,
		"lives_before": 0,
		"lives_after": 1,
		"pull_count_after": 1,
		"marks_before": 120,
		"marks_after": 80,
		"rarity": rarity,
		"five_star": rarity == 5,
		"pity_eligible": true,
		"pity_before": 9 if rarity == 5 else 0,
		"pity_after": 0 if rarity == 5 else 1,
		"pity_forced": rarity == 5,
		"guarantee_in_after": 10 if rarity == 5 else 9,
		"save_revision": 2,
	}
	screen.call("_begin_reveal", pull)
	await create_timer(_capture_seconds).timeout
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_viewport().get_texture().get_image()
	var save_error := image.save_png(_output_path)
	if save_error != OK:
		push_error("screenshot save failed: %d" % save_error)
		quit(1)
		return
	var reveal := screen.find_child("PullRevealLayer", true, false) as Control
	var video := screen.find_child("CinematicVideo", true, false) as VideoStreamPlayer
	var final_plate := screen.find_child("CinematicFinalPlate", true, false) as TextureRect
	if reveal == null or not reveal.visible:
		push_error("reveal layer unavailable during capture")
		quit(1)
		return
	print(
		"GACHA_CINEMATIC_VISUAL_CAPTURE premium_id=%s reduced=%s capture=%.2f video=%s final=%s path=%s"
		% [
			_premium_id,
			str(_reduced_motion),
			_capture_seconds,
			str(video != null and video.is_playing()),
			str(final_plate != null and final_plate.visible),
			_output_path,
		]
	)
	screen.call("_finish_reveal")
	await process_frame
	if reveal.visible:
		push_error("Skip/finalize did not close reveal")
		quit(1)
		return
	game.set("campaign_active", false)
	game.set("campaign", null)
	game.set("campaign_store", null)
	root.remove_child(screen)
	screen.free()
	var music := root.get_node_or_null("Music")
	if music != null and music.has_method("stop"):
		music.call("stop")
	var sfx := root.get_node_or_null("Sfx")
	if sfx != null and sfx.has_method("stop_all"):
		sfx.call("stop_all")
	for _frame: int in range(8):
		await process_frame
	await create_timer(0.25).timeout
	print("GACHA_CINEMATIC_VISUAL_HARNESS_OK")
	quit(0)
