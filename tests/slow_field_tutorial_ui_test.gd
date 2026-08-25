extends SceneTree

class MockBattleView:
	extends Node2D
	var target := Vector2i(7, 3)

	func cell_at(_screen_pos: Vector2) -> Vector2i:
		return target

	func cell_center(cell: Vector2i) -> Vector2:
		return Vector2(320.0 + cell.x * 4.0, 280.0 + cell.y * 4.0)

	func grid_scale() -> float:
		return 1.0


var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var stage := load("res://data/stages/s7.tres") as StageDef
	var config := load("res://data/config/game.tres") as GameConfig
	var slow := load("res://data/spells/slow_field.tres") as SpellDef
	var model := BattleModel.create(
		stage,
		[],
		707,
		config,
		_load_catalog("res://data/enemies"),
		{},
		{},
		{&"slow_field": slow},
	)
	_check(model != null, "S7 tutorial fixture model failed")
	if model == null:
		_finish()
		return
	var view := MockBattleView.new()
	root.add_child(view)
	var spell_bar_script := load("res://scripts/ui/spell_bar.gd") as GDScript
	var tutorial_script := load("res://scripts/ui/slow_field_tutorial.gd") as GDScript
	_check(spell_bar_script != null, "SpellBar script failed to load")
	_check(tutorial_script != null, "SlowFieldTutorial script failed to load")
	if spell_bar_script == null or tutorial_script == null:
		view.queue_free()
		_finish()
		return
	var spell_bar: Variant = spell_bar_script.new()
	spell_bar.name = "SpellBar"
	view.add_child(spell_bar)
	var spell_ids: Array[StringName] = [&"slow_field"]
	spell_bar.setup(model, view, spell_ids)
	var tutorial: Variant = tutorial_script.new()
	tutorial.name = "SlowFieldTutorial"
	view.add_child(tutorial)
	tutorial.setup(model, view, spell_bar)
	for _frame: int in range(3):
		await process_frame

	var card := tutorial.find_child("SlowFieldTutorialCard", true, false) as PanelContainer
	var focus := tutorial.find_child("SlowFieldTutorialFocusRing", true, false) as PanelContainer
	var primary := tutorial.find_child("SlowFieldTutorialPrimary", true, false) as Button
	_check(card != null and card.visible, "Slow Field tutorial card is missing")
	_check(focus != null and focus.visible, "Slow Field spell card is not spotlighted")
	_check(tutorial.is_holding_battle(), "Slow Field tutorial did not hold battle time")
	_check(tutorial.current_step_name() == &"brief", "Slow Field tutorial did not start at brief")
	_check(primary != null, "Slow Field tutorial primary action is missing")
	if primary != null:
		primary.pressed.emit()
	await process_frame
	var marker := tutorial.find_child("SlowFieldTutorialTarget", true, false) as Polygon2D
	_check(tutorial.current_step_name() == &"target", "tutorial did not enter target step")
	_check(spell_bar.targeting_spell() == &"slow_field", "tutorial did not activate targeting")
	_check(marker != null and marker.visible, "shared-lane target marker is missing")
	_check(tutorial.is_holding_battle(), "battle resumed before the required cast")

	spell_bar.call("_cast_at_pointer")
	for _frame: int in range(2):
		await process_frame
	_check(model.slow_fields.size() == 1, "guided cast did not create Slow Field")
	_check(tutorial.current_step_name() == &"live", "tutorial did not enter live timer step")
	_check(not tutorial.is_holding_battle(), "battle stayed paused after a valid cast")
	_check(spell_bar.remaining_duration_ticks(&"slow_field") == 240, "duration ticks are wrong")
	_check(spell_bar.remaining_cooldown_ticks(&"slow_field") == 600, "cooldown ticks are wrong")
	var duration_label := spell_bar.find_child("DurationLabel_slow_field", true, false) as Label
	var cooldown_label := spell_bar.find_child("CooldownLabel_slow_field", true, false) as Label
	var duration_sweep := spell_bar.find_child("DurationSweep_slow_field", true, false) as ColorRect
	var cooldown_sweep := spell_bar.find_child("CooldownSweep_slow_field", true, false) as ColorRect
	_check(
		duration_label != null and duration_label.visible and "8.0" in duration_label.text,
		"active duration countdown is not explicit",
	)
	_check(
		cooldown_label != null and "20.0" in cooldown_label.text,
		"cooldown countdown is not explicit",
	)
	_check(duration_sweep != null and duration_sweep.size.x > 0.0, "duration sweep is missing")
	_check(cooldown_sweep != null and cooldown_sweep.size.x > 0.0, "cooldown sweep is missing")

	model.tick = 240
	model.call("_expire_slow_fields")
	spell_bar.call("_refresh_buttons")
	_check(spell_bar.remaining_duration_ticks(&"slow_field") == 0, "expired duration remained")
	_check(duration_label != null and not duration_label.visible, "expired duration label remained")
	_check(spell_bar.remaining_cooldown_ticks(&"slow_field") == 360, "cooldown did not continue")
	model.tick = 600
	spell_bar.call("_refresh_buttons")
	_check(spell_bar.remaining_cooldown_ticks(&"slow_field") == 0, "cooldown did not reach ready")
	_check(cooldown_label != null and cooldown_label.text == "READY", "ready label did not return")

	tutorial.call("_finish", false)
	var sfx := root.get_node_or_null("Sfx")
	if sfx != null:
		sfx.call("stop_all")
	for _frame: int in range(2):
		await process_frame
	view.queue_free()
	tutorial = null
	view.queue_free()
	for _frame: int in range(3):
		await process_frame
	# The production audio catalog uses real one-shot samples. Allow the audio
	# server to retire their playback objects before SceneTree leak checks run.
	await create_timer(0.5).timeout
	_finish()


func _load_catalog(path: String) -> Dictionary:
	var result: Dictionary = {}
	for filename: String in DirAccess.get_files_at(path):
		if not filename.ends_with(".tres"):
			continue
		var resource := load("%s/%s" % [path, filename])
		if resource != null:
			result[resource.id] = resource
	return result


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("SLOW_FIELD_TUTORIAL_UI_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)
