extends SceneTree

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	await process_frame
	var game := root.get_node_or_null("Game")
	_check(game != null, "Game autoload missing")
	if game == null:
		_finish()
		return
	game.call("set_run_seed", 3302)
	_check(bool(game.call("start_campaign", false, true)), "battle UI campaign fixture failed")
	game.call("start_battle", &"s1", true)
	for _frame: int in range(12):
		await process_frame
	var battle := game.get("content") as Node
	_check(battle != null and bool(battle.get("startup_succeeded")), "battle view did not start")
	if battle == null:
		_finish()
		return
	var hud := battle.find_child("BattleHud", true, false) as Label
	var deployment_deck := battle.find_child("DeploymentCommandDeck", true, false) as PanelContainer
	var slot_box := battle.find_child("SlotBox", true, false) as GridContainer
	var controls_deck := battle.find_child("BattleCommandDeck", true, false) as PanelContainer
	var pause := battle.find_child("PauseButton", true, false) as Button
	var speed := battle.find_child("SpeedButton", true, false) as Button
	var resign := battle.find_child("ResignButton", true, false) as Button
	var recenter := battle.find_child("RecenterMap", true, false) as Button
	var tutorial_card := battle.find_child("TutorialCard", true, false) as PanelContainer
	var skip := battle.find_child("SkipTutorial", true, false) as Button
	_check(hud != null and hud.get_theme_stylebox(&"normal") is StyleBoxTexture, "battle HUD does not use the Lunaris command frame")
	_check(deployment_deck != null and deployment_deck.get_theme_stylebox(&"panel") is StyleBoxTexture, "deployment deck is not textured")
	_check(slot_box != null and slot_box.get_child_count() >= 3, "deployment slots are missing")
	if slot_box != null:
		for child: Node in slot_box.get_children():
			_check(child is Button and (child as Button).custom_minimum_size.y >= 44.0, "deployment slot is not touch safe")
	_check(controls_deck != null and controls_deck.get_theme_stylebox(&"panel") is StyleBoxTexture, "battle command deck is not textured")
	_check(pause != null and speed != null and resign != null and pause.focus_mode == Control.FOCUS_ALL, "battle commands are not controller focusable")
	_check(recenter != null and recenter.focus_mode == Control.FOCUS_ALL, "map recenter is not controller focusable")
	_check(tutorial_card != null and tutorial_card.get_theme_stylebox(&"panel") is StyleBoxTexture, "tutorial card did not inherit the Lunaris modal frame")
	var spell_probe := (load("res://scripts/ui/spell_bar.gd") as Script).new() as Control
	spell_probe.name = "Phase0SpellProbe"
	battle.add_child(spell_probe)
	spell_probe.call("setup", game.get("current_battle"), battle, [&"slow_field"] as Array[StringName])
	await process_frame
	var spell_deck := spell_probe.find_child("SpellCommandDeck", true, false) as PanelContainer
	_check(
		spell_deck != null and not spell_deck.get_global_rect().intersects(controls_deck.get_global_rect()),
		"landscape spell and battle command hit regions overlap; controls=%s spell=%s" % [
			controls_deck.get_global_rect(), spell_deck.get_global_rect() if spell_deck != null else Rect2(),
		],
	)

	if skip != null:
		skip.pressed.emit()
	for _frame: int in range(3):
		await process_frame
	var controls := battle.find_child("BattleControls", true, false)
	_check(controls != null, "battle controls missing")
	if controls != null:
		controls.call("_on_pause_pressed")
		_check(is_equal_approx(float(battle.get("ticks_per_frame_scale")), 0.0), "Pause did not stop battle tick consumption")
		controls.call("_on_pause_pressed")
		_check(is_equal_approx(float(battle.get("ticks_per_frame_scale")), 1.0), "Resume did not restore the prior battle speed")
		battle.set("ticks_per_frame_scale", 2.0)
		controls.call("_on_resign_pressed")
		await process_frame
		var resign_layer := battle.find_child("ResignConfirmLayer", true, false) as Control
		var cancel := battle.find_child("CancelResign", true, false) as Button
		var confirm := battle.find_child("ConfirmResign", true, false) as Button
		_check(resign_layer != null and resign_layer.visible, "resign confirmation did not open")
		_check(is_equal_approx(float(battle.get("ticks_per_frame_scale")), 0.0), "resign confirmation did not pause battle")
		_check(cancel != null and cancel.has_focus(), "resign Cancel is not the safe default focus")
		if cancel != null:
			cancel.pressed.emit()
		await process_frame
		_check(not resign_layer.visible, "Cancel did not close resign confirmation")
		_check(is_equal_approx(float(battle.get("ticks_per_frame_scale")), 2.0), "Cancel did not restore prior speed")
		_check(resign.has_focus(), "Cancel did not restore focus to Resign")
		_check(int(game.get("current_battle").result) == BattleModel.Result.RUNNING, "Cancel mutated battle result")
		controls.call("_on_resign_pressed")
		await process_frame
		if confirm != null:
			confirm.pressed.emit()
		for _frame: int in range(3):
			await process_frame
		_check(int(game.get("current_battle").result) == BattleModel.Result.DEFEAT, "Confirm did not apply the resign verb exactly once")
		var pan_hint := battle.find_child("MapPanHint", true, false) as Control
		_check(pause.disabled and resign.disabled, "terminal battle controls remain actionable")
		_check(pan_hint == null or not pan_hint.visible, "terminal map-navigation hint remains visible")

	game.set("content", null)
	game.set("current_battle", null)
	game.set("pending_stage", null)
	if battle != null and is_instance_valid(battle):
		var parent := battle.get_parent()
		if parent != null:
			parent.remove_child(battle)
		battle.free()
	game.set("campaign_active", false)
	game.set("campaign", null)
	game.set("campaign_store", null)
	var music := root.get_node_or_null("Music")
	if music != null and music.has_method("stop"):
		music.call("stop")
	var sfx := root.get_node_or_null("Sfx")
	if sfx != null and sfx.has_method("stop_all"):
		sfx.call("stop_all")
	await create_timer(0.25).timeout
	_finish()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("BATTLE_UI_LAYOUT_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)
