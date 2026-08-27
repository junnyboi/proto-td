extends Node


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var output_path := _output_path()
	if output_path.is_empty():
		push_error("staging sparkle visual output path is required")
		get_tree().quit(1)
		return
	ProjectSettings.set_setting("accessibility/reduced_motion", false)
	I18n.set_locale(&"en-US")
	Game.set_run_seed(82417)
	if not Game.start_campaign(false, true):
		push_error("staging sparkle visual campaign fixture failed")
		get_tree().quit(1)
		return
	var staging := load("res://scenes/staging.tscn").instantiate() as Control
	add_child(staging)
	for _frame: int in range(50):
		await get_tree().process_frame
	var mission_sparkles := staging.find_child("MissionControlSparkles", true, false) as Control
	var resonance_sparkles := staging.find_child("ResonanceSparkles", true, false) as Control
	if (
		mission_sparkles == null
		or resonance_sparkles == null
		or int(mission_sparkles.call("visible_particle_count")) < 1
		or int(resonance_sparkles.call("visible_particle_count")) < 1
	):
		push_error("staging sparkle visual frame has no active particles")
		get_tree().quit(1)
		return
	var image := get_viewport().get_texture().get_image()
	var save_error := image.save_png(output_path)
	if save_error != OK:
		push_error("staging sparkle visual capture failed: %s" % error_string(save_error))
		get_tree().quit(1)
		return
	print(
		"STAGING_SPARKLES_VISUAL_OK|%s|%dx%d|mission=%d|resonance=%d"
		% [
			output_path,
			image.get_width(),
			image.get_height(),
			int(mission_sparkles.call("visible_particle_count")),
			int(resonance_sparkles.call("visible_particle_count")),
		]
	)
	Game.content = null
	staging.queue_free()
	var music := get_tree().root.get_node_or_null("Music")
	if music != null:
		music.call("stop")
	var sfx := get_tree().root.get_node_or_null("Sfx")
	if sfx != null:
		sfx.call("stop_all")
	for _frame: int in range(8):
		await get_tree().process_frame
	get_tree().quit(0)


func _output_path() -> String:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			return argument.trim_prefix("--output=")
	return ""
