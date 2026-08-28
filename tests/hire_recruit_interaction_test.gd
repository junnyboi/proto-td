extends SceneTree

const HOVER_SCALE := Vector2(1.022, 1.022)
const FOCUS_SCALE := Vector2(1.012, 1.012)
const HOVER_TINT := Color("fff8df")
const FOCUS_TINT := Color("e9fcff")
const EPSILON := 0.006

var _failures: Array[String] = []
var _mission: Control = null
var _hire: Button = null


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	ProjectSettings.set_setting("accessibility/reduced_motion", false)
	var game := root.get_node_or_null("Game")
	var sfx := root.get_node_or_null("Sfx")
	var feedback := root.get_node_or_null("UiFeedback")
	_check(game != null, "Game autoload is available")
	_check(sfx != null, "Sfx autoload is available")
	_check(feedback != null, "UiFeedback autoload is available")
	if game == null or sfx == null or feedback == null:
		_finish()
		return
	game.call("set_run_seed", 1701)
	_check(bool(game.call("start_campaign", false, true)), "fresh campaign fixture starts")
	game.set("selected_stage_id", &"s1")
	_mission = load("res://scenes/squad_select.tscn").instantiate() as Control
	root.add_child(_mission)
	for _frame: int in range(4):
		await process_frame
	_hire = _mission.find_child("HireBasicRecruit", true, false) as Button
	_check(_hire != null and not _hire.disabled, "enabled Hire Recruit action is available")
	if _hire == null:
		_dispose(game, sfx)
		_finish()
		return
	await _verify_profile_and_motion(sfx)
	await _verify_hover_audio(sfx)
	await _verify_authoritative_click(game, sfx, feedback)
	_dispose(game, sfx)
	_finish()


func _verify_profile_and_motion(sfx: Node) -> void:
	_check(bool(_hire.get_meta(&"action_hover_feedback_wired", false)), "Hire Recruit uses shared action feedback")
	_check(
		_near_vec(_hire.get_meta(&"action_hover_feedback_hover_scale", Vector2.ZERO), HOVER_SCALE),
		"Hire Recruit records its 1.022 hover profile",
	)
	_check(
		_near_vec(_hire.get_meta(&"action_hover_feedback_focus_scale", Vector2.ZERO), FOCUS_SCALE),
		"Hire Recruit records its 1.012 focus profile",
	)
	_check(
		(_hire.get_meta(&"action_hover_feedback_hover_tint", Color.BLACK) as Color).is_equal_approx(HOVER_TINT),
		"Hire Recruit records its ivory hover tint",
	)
	_check(
		(_hire.get_meta(&"action_hover_feedback_focus_tint", Color.BLACK) as Color).is_equal_approx(FOCUS_TINT),
		"Hire Recruit records its cyan focus tint",
	)
	_check(_hire.pivot_offset.is_equal_approx(_hire.size * 0.5), "Hire Recruit pivot is centered")
	var size_before := _hire.size
	_hire.mouse_exited.emit()
	await create_timer(0.22).timeout
	_hire.mouse_entered.emit()
	await create_timer(0.22).timeout
	_check(_near_vec(_hire.scale, HOVER_SCALE), "hover uses the configured transform scale")
	_check(_hire.modulate.is_equal_approx(HOVER_TINT), "hover uses the configured ivory tint")
	_check(_hire.size.is_equal_approx(size_before), "hover scale does not alter layout geometry")
	_hire.mouse_exited.emit()
	await create_timer(0.22).timeout
	_hire.focus_entered.emit()
	await create_timer(0.22).timeout
	_check(_near_vec(_hire.scale, FOCUS_SCALE), "focus uses the configured transform scale")
	_check(_hire.modulate.is_equal_approx(FOCUS_TINT), "focus uses the configured cyan tint")
	_hire.focus_exited.emit()
	await create_timer(0.22).timeout
	ProjectSettings.set_setting("accessibility/reduced_motion", true)
	_hire.mouse_entered.emit()
	await process_frame
	_check(_near_vec(_hire.scale, Vector2.ONE), "reduced motion suppresses Hire Recruit scale")
	_check(_hire.modulate.is_equal_approx(HOVER_TINT), "reduced motion preserves hover tint feedback")
	_hire.mouse_exited.emit()
	ProjectSettings.set_setting("accessibility/reduced_motion", false)
	await process_frame
	_check(sfx != null, "motion fixture preserves SFX autoload")


func _verify_hover_audio(sfx: Node) -> void:
	_hire.disabled = false
	_hire.mouse_exited.emit()
	await process_frame
	var starts_before := int(sfx.call("audible_start_count"))
	_hire.mouse_entered.emit()
	_check(int(sfx.call("audible_start_count")) == starts_before + 1, "first enabled hover starts exactly one semantic cue")
	_check(sfx.call("last_raw_id") == &"hire_recruit_hover", "Hire Recruit requests its semantic hover cue")
	_check(sfx.call("last_resolved_id") == &"ability_ready", "Hire Recruit hover resolves to ability_ready")
	_hire.mouse_entered.emit()
	_check(int(sfx.call("audible_start_count")) == starts_before + 1, "duplicate hover entry signal is suppressed")
	_hire.mouse_exited.emit()
	await process_frame
	_hire.mouse_entered.emit()
	_check(int(sfx.call("audible_start_count")) == starts_before + 2, "hover exit re-arms one new entry cue")
	_hire.mouse_exited.emit()
	_hire.disabled = true
	await process_frame
	var disabled_starts := int(sfx.call("audible_start_count"))
	_hire.mouse_entered.emit()
	_check(int(sfx.call("audible_start_count")) == disabled_starts, "disabled Hire Recruit hover is silent")
	_hire.mouse_exited.emit()
	_hire.disabled = false
	await process_frame


func _verify_authoritative_click(game: Node, sfx: Node, feedback: Node) -> void:
	var before: Dictionary = game.call("campaign_projection")
	var click_starts_before := int(sfx.call("audible_start_count"))
	var click_count_before := int(feedback.call("click_play_count"))
	_hire.pressed.emit()
	await process_frame
	await process_frame
	var after: Dictionary = game.call("campaign_projection")
	_check(int(after.get("marks", 0)) == int(before.get("marks", 0)) - 5, "Hire Recruit dispatches the authoritative five-Mark command")
	_check(
		(after.get("ready_heroes", []) as Array).size() == (before.get("ready_heroes", []) as Array).size() + 1,
		"authoritative hire adds exactly one Recruit",
	)
	var newest: Dictionary = (after.get("ready_heroes", []) as Array)[-1]
	_check(
		newest.get("recruit_source") == "basic_hire" and newest.get("source_id") == "mission_control",
		"Hire Recruit preserves the authoritative source contract",
	)
	_check(int(sfx.call("audible_start_count")) == click_starts_before + 1, "Hire Recruit starts exactly one click voice")
	_check(int(feedback.call("click_play_count")) == click_count_before + 1, "UiFeedback remains the sole Hire Recruit click owner")
	_check(sfx.call("last_resolved_id") == &"ui_click", "Hire Recruit click resolves to ui_click")


func _dispose(game: Node, sfx: Node) -> void:
	ProjectSettings.set_setting("accessibility/reduced_motion", false)
	if _mission != null and is_instance_valid(_mission):
		_mission.queue_free()
	await process_frame
	game.set("campaign_active", false)
	game.set("campaign", null)
	game.set("campaign_store", null)
	sfx.call("stop_all")


func _near_vec(actual: Variant, expected: Vector2) -> bool:
	return actual is Vector2 and (actual as Vector2).distance_to(expected) <= EPSILON


func _finish() -> void:
	ProjectSettings.set_setting("accessibility/reduced_motion", false)
	if _failures.is_empty():
		print("HIRE_RECRUIT_INTERACTION_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
