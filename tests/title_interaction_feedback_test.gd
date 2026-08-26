extends SceneTree

const VIEW_PREFERENCES := preload("res://scripts/view/view_preferences.gd")
const PREFERENCES_PATH := "user://title_interaction_feedback_test.cfg"
const REDUCED_PREFERENCES_PATH := "user://title_interaction_feedback_reduced_test.cfg"
const EPSILON := 0.01
const WAIT_TIMEOUT := 1.0

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_remove_preferences(PREFERENCES_PATH)
	_remove_preferences(REDUCED_PREFERENCES_PATH)
	await _verify_animated_reveal_and_hover()
	await _verify_reduced_motion()
	_remove_preferences(PREFERENCES_PATH)
	_remove_preferences(REDUCED_PREFERENCES_PATH)
	call_deferred("_finish")


func _verify_animated_reveal_and_hover() -> void:
	var title := await _create_title(PREFERENCES_PATH)
	var wordmark := title.find_child("Wordmark", true, false) as Label
	var settings := title.find_child("SettingsButton", true, false) as Button
	var sfx := root.get_node_or_null("Sfx")
	_check(wordmark != null and wordmark.modulate.a < 1.0, "wordmark did not begin inside the fade-in window")
	_check(settings != null and settings.modulate.a < 1.0, "Settings did not begin inside its staggered fade window")
	await create_timer(1.1).timeout
	_check(wordmark != null and _near(wordmark.modulate.a, 1.0), "wordmark fade-in did not settle opaque")
	_check(settings != null and _near(settings.modulate.a, 1.0), "Settings fade-in did not settle opaque")
	if settings != null and sfx != null:
		var starts_before := int(sfx.call("audible_start_count"))
		title.call("_on_title_action_hover_changed", settings, true)
		await create_timer(0.24).timeout
		_check(sfx.call("last_raw_id") == &"ui_hover", "Settings hover did not request the semantic hover cue")
		_check(int(sfx.call("audible_start_count")) == starts_before + 1, "Settings hover did not start exactly one sound")
		_check(settings.scale.x > 1.0 and settings.scale.y > 1.0, "Settings hover did not apply visual emphasis")
		title.call("_on_title_action_hover_changed", settings, true)
		await process_frame
		_check(int(sfx.call("audible_start_count")) == starts_before + 1, "duplicate hover state replayed the sound")
		title.call("_on_title_action_hover_changed", settings, false)
		await create_timer(0.24).timeout
		_check(settings.scale.is_equal_approx(Vector2.ONE), "Settings hover scale did not settle after exit")
		title.call("_open_settings")
		var settings_state := title.get_node("TitleSettings") as Control
		await _wait_for_transition(settings_state, &"ACTIVE")
		var gated_starts := int(sfx.call("audible_start_count"))
		title.call("_on_title_action_hover_changed", settings, true)
		await process_frame
		_check(int(sfx.call("audible_start_count")) == gated_starts, "hidden title hover feedback remained active in Settings")
		_check(settings.scale.is_equal_approx(Vector2.ONE), "hidden title hover still transformed in Settings")
		title.call("_close_settings")
		await _wait_for_transition(settings_state, &"CLOSED")
	await _release_title(title)


func _verify_reduced_motion() -> void:
	_check(VIEW_PREFERENCES.set_reduced_motion(true, REDUCED_PREFERENCES_PATH), "reduced-motion preference was not written")
	var title := await _create_title(REDUCED_PREFERENCES_PATH)
	var wordmark := title.find_child("Wordmark", true, false) as Label
	var settings := title.find_child("SettingsButton", true, false) as Button
	_check(wordmark != null and _near(wordmark.modulate.a, 1.0), "reduced motion did not reveal the wordmark instantly")
	_check(settings != null and _near(settings.modulate.a, 1.0), "reduced motion did not reveal Settings instantly")
	if settings != null:
		title.call("_on_title_action_hover_changed", settings, true)
		await process_frame
		_check(settings.scale.is_equal_approx(Vector2.ONE), "reduced motion still scaled the hovered Settings button")
	await _release_title(title)
	ProjectSettings.set_setting("accessibility/reduced_motion", false)


func _wait_for_transition(state: Control, expected: StringName) -> bool:
	var elapsed := 0.0
	while StringName(state.call("transition_state_name")) != expected and elapsed < WAIT_TIMEOUT:
		await create_timer(0.01).timeout
		elapsed += 0.01
	var matched := StringName(state.call("transition_state_name")) == expected
	_check(matched, "transition timed out waiting for %s" % expected)
	return matched


func _create_title(path: String) -> Control:
	var title := load("res://scenes/title.tscn").instantiate() as Control
	title.call("set_preferences_path", path)
	root.add_child(title)
	await process_frame
	return title


func _release_title(title: Control) -> void:
	var game := root.get_node_or_null("Game")
	if game != null and game.get("content") == title:
		game.set("content", null)
	var music := root.get_node_or_null("Music")
	if music != null:
		music.call("stop")
	var sfx := root.get_node_or_null("Sfx")
	if sfx != null:
		sfx.call("stop_all")
	title.queue_free()
	for _frame: int in range(12):
		await process_frame
	await create_timer(0.5).timeout


func _near(actual: float, expected: float) -> bool:
	return absf(actual - expected) <= EPSILON


func _remove_preferences(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _finish() -> void:
	if _failures.is_empty():
		print("TITLE_INTERACTION_FEEDBACK_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
