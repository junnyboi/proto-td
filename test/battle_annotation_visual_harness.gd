extends Node


func _ready() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var output := ""
	var mode := "tutorial"
	var locale_id := &"en-US"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--out="):
			output = argument.trim_prefix("--out=")
		elif argument.begins_with("--mode="):
			mode = argument.trim_prefix("--mode=")
		elif argument.begins_with("--locale="):
			locale_id = StringName(argument.trim_prefix("--locale="))
	if output.is_empty():
		push_error("battle annotation visual harness requires --out=<path>")
		get_tree().quit(1)
		return
	Music.set_enabled(false)
	if not I18n.set_locale(locale_id):
		push_error("battle annotation visual harness could not set locale %s" % locale_id)
		get_tree().quit(1)
		return
	Game.set_run_seed(3302)
	if not Game.start_campaign(false, true):
		push_error("battle annotation visual harness could not start campaign")
		get_tree().quit(1)
		return
	Game.start_battle(&"s1", true)
	for _frame: int in range(18):
		await get_tree().process_frame
	if mode in ["live", "paused"]:
		var tutorial_probe := get_tree().root.find_child("FirstStandTutorial", true, false) as Control
		var controls_probe := get_tree().root.find_child("BattleControls", true, false) as BattleControls
		var deployment_probe := get_tree().root.find_child("DeployBar", true, false) as DeployBar
		if tutorial_probe == null or controls_probe == null or deployment_probe == null:
			push_error("battle annotation visual harness could not compose live probe state")
			get_tree().quit(1)
			return
		tutorial_probe.visible = false
		controls_probe.set_interaction_enabled(true)
		deployment_probe.set_operator_interaction_enabled(true)
		if mode == "paused":
			controls_probe._on_speed_pressed()
			controls_probe._on_speed_pressed()
			controls_probe._on_speed_pressed()
			controls_probe._process(0.0)
			var speed := controls_probe.find_child("SpeedButton", true, false) as Button
			var pause := controls_probe.find_child("PauseButton", true, false) as Button
			var expected_pause := "继续" if locale_id == &"zh-CN" else "RESUME"
			if speed == null or pause == null or speed.text != "0×" or pause.text != expected_pause:
				push_error("battle annotation visual harness did not reach paused speed cycle")
				get_tree().quit(1)
				return
		for _frame: int in range(8):
			await get_tree().process_frame
	var tutorial := get_tree().root.find_child("FirstStandTutorial", true, false)
	var hud := get_tree().root.find_child("BattleHud", true, false)
	var controls := get_tree().root.find_child("BattleCommandDeck", true, false)
	var deployment := get_tree().root.find_child("DeploymentCommandDeck", true, false)
	if (mode == "tutorial" and tutorial == null) or hud == null or controls == null or deployment == null:
		push_error("battle annotation visual harness could not find the composed UI")
		get_tree().quit(1)
		return
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(output)
	if error != OK:
		push_error("battle annotation visual harness could not save %s (%d)" % [output, error])
		get_tree().quit(1)
		return
	print("BATTLE_ANNOTATION_VISUAL_OK mode=%s path=%s" % [mode, output])
	get_tree().quit(0)
