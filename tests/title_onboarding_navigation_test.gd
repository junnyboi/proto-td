extends SceneTree

const PREFS := preload("res://scripts/view/view_preferences.gd")
const SKIP_PATH := "user://command_tutorial_skip_test.cfg"
const DONE_PATH := "user://command_tutorial_done_test.cfg"
const TITLE_PATH := "user://command_tutorial_title_start_test.cfg"
const SAVE_PATHS := [
	"user://campaign_v1.json",
	"user://campaign_v1.bak",
	"user://campaign_v1.tmp",
	"user://campaign_v1.invalid",
	"user://campaign_v1.bak.invalid",
	"user://campaign_v1.tmp.invalid",
]

var _failures: Array[String] = []
var _preserved: Dictionary = {}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_preserve_files()
	_clear_production_files()
	_remove(SKIP_PATH)
	_remove(DONE_PATH)
	_remove(TITLE_PATH)
	var game := root.get_node_or_null("Game")
	var i18n := root.get_node_or_null("I18n")
	_check(game != null and i18n != null, "required autoloads are unavailable")
	if game == null or i18n == null:
		_finish()
		return
	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)
	await process_frame
	var title := load("res://scenes/title.tscn").instantiate() as Control
	title.call("set_preferences_path", TITLE_PATH)
	root.add_child(title)
	for _frame: int in range(4):
		await process_frame
	title.call("_on_start_pressed")
	for _frame: int in range(180):
		if game.get("content") != title:
			break
		await process_frame
	var title_staging := game.get("content") as Control
	_check(
		title_staging != null and String(title_staging.get_script().resource_path) == "res://scripts/ui/staging.gd",
		"Title Start did not open Command Center",
	)
	var title_tutorial := title_staging.find_child("CommandCenterTutorial", true, false) as Control if title_staging != null else null
	_check(title_tutorial != null and bool(title_tutorial.call("is_active")), "real Title Start ordering lost the first-run tutorial request")
	if title_tutorial != null:
		title_tutorial.call("skip")
		await process_frame
	await _dispose_content(title_staging, game)
	game.set("campaign_active", false)
	game.set("campaign", null)
	game.set("campaign_store", null)
	game.call("set_run_seed", 82317)
	_check(bool(game.call("start_campaign", false, true)), "campaign fixture failed")
	game.set("selected_stage_id", &"sentinel")
	_check(not bool(game.call("open_field_team_for_stage", &"missing")), "unknown stage route was accepted")
	_check(game.get("selected_stage_id") == &"sentinel", "unknown stage route mutated selection")
	_check(not bool(game.call("open_field_team_for_stage", &"s2")), "locked stage route was accepted")
	_check(game.get("selected_stage_id") == &"sentinel", "locked stage route mutated selection")

	game.call("request_command_tutorial")
	var staging := await _create_staging(SKIP_PATH)
	var tutorial := staging.find_child("CommandCenterTutorial", true, false) as Control
	_check(tutorial != null and bool(tutorial.call("is_active")), "requested first-run tutorial did not mount")
	if tutorial != null:
		await _verify_tutorial_step(staging, tutorial, &"mission_control", "MissionControlButton")
		var external := staging.find_child("ExitButton", true, false) as Button
		external.grab_focus()
		await process_frame
		await process_frame
		var focus_owner := root.gui_get_focus_owner()
		_check(focus_owner != null and tutorial.is_ancestor_of(focus_owner), "tutorial focus containment allowed focus to escape")
		tutorial.call("advance")
		await process_frame
		await _verify_tutorial_step(staging, tutorial, &"resonance", "RecruitButton")
		_check(bool(i18n.call("set_locale", &"zh-CN")), "Chinese locale activation failed")
		await process_frame
		var tutorial_title := tutorial.find_child("TutorialTitle", true, false) as Label
		_check(tutorial_title != null and tutorial_title.text == "召唤特殊英雄", "mounted tutorial did not refresh Chinese copy")
		tutorial.call("skip")
		await process_frame
		_check(PREFS.has_seen_command_tutorial(SKIP_PATH), "Skip did not persist tutorial completion")
		_check(staging.find_child("CommandCenterTutorial", true, false) == null, "skipped tutorial remained mounted")
	_check(bool(i18n.call("set_locale", &"en-US")), "English locale restoration failed")
	await _dispose_content(staging, game)

	game.call("request_command_tutorial")
	var routed_staging := await _create_staging(SKIP_PATH)
	_check(routed_staging.find_child("CommandCenterTutorial", true, false) == null, "completed tutorial mounted again")
	var action := routed_staging.find_child("NextOperationAction", true, false) as Button
	_check(action != null and not action.disabled and action.focus_mode == Control.FOCUS_ALL, "next operation card is not actionable")
	_check(action != null and not action.accessibility_name.is_empty() and not action.accessibility_description.is_empty(), "next operation action lacks accessibility copy")
	_check(_transparent_gold_focus(action), "next operation action focus is not a transparent gold outline")
	game.set("selected_stage_id", &"")
	action.pressed.emit()
	for _frame: int in range(8):
		await process_frame
	var mission_control := game.get("content") as Node
	_check(game.get("selected_stage_id") == &"", "next operation bypassed the mission cinematic gate")
	_check(mission_control != null and mission_control.name == "StageSelect", "next operation did not open Mission Control")
	_check(mission_control != null and mission_control.find_child("Stage_s1", true, false) != null, "Mission Control did not expose the exact unlocked operation")
	_check(game.get("current_battle") == null and game.get("pending_stage") == null, "Mission Control shortcut started a battle")
	await _dispose_content(mission_control, game)

	ProjectSettings.set_setting("accessibility/reduced_motion", true)
	game.call("request_command_tutorial")
	var completion_staging := await _create_staging(DONE_PATH)
	var completion := completion_staging.find_child("CommandCenterTutorial", true, false) as Control
	_check(completion != null, "completion-path tutorial did not mount")
	if completion != null:
		var card := completion.find_child("TutorialCallout", true, false) as Control
		_check(card != null and card.scale.is_equal_approx(Vector2.ONE) and is_equal_approx(card.modulate.a, 1.0), "reduced-motion tutorial did not settle immediately")
		completion.call("advance")
		await process_frame
		completion.call("advance")
		await process_frame
		_check(PREFS.has_seen_command_tutorial(DONE_PATH), "Done did not persist tutorial completion")
	await _dispose_content(completion_staging, game)
	await _cleanup(game)
	_remove(SKIP_PATH)
	_remove(DONE_PATH)
	_remove(TITLE_PATH)
	_clear_production_files()
	_restore_files()
	_finish()


func _create_staging(path: String) -> Control:
	var staging := load("res://scenes/staging.tscn").instantiate() as Control
	staging.call("set_preferences_path", path)
	root.add_child(staging)
	for _frame: int in range(6):
		await process_frame
	return staging


func _verify_tutorial_step(staging: Control, tutorial: Control, step: StringName, target_name: String) -> void:
	_check(StringName(tutorial.call("current_step_name")) == step, "%s tutorial step is not active" % step)
	_check(StringName(tutorial.call("current_target_name")) == StringName(target_name), "%s tutorial points to the wrong target" % step)
	var target := staging.find_child(target_name, true, false) as Control
	var ring_rect := tutorial.call("current_target_rect") as Rect2
	_check(
		target != null and ring_rect.encloses(target.get_global_rect()),
		"%s tutorial ring %s does not enclose target %s" % [step, ring_rect, target.get_global_rect() if target != null else Rect2()],
	)
	var card := tutorial.find_child("TutorialCallout", true, false) as Control
	_check(
		card != null and _contains(tutorial, card),
		"%s tutorial card %s escapes viewport %s" % [step, card.get_global_rect() if card != null else Rect2(), tutorial.get_global_rect()],
	)
	if card != null:
		_check(
			card.get_global_rect().get_center().distance_to(tutorial.get_global_rect().get_center()) <= 2.0,
			"%s tutorial card is not centered in the viewport" % step,
		)
	var ring := tutorial.find_child("TutorialTargetRing", true, false) as Control
	_check(ring != null and not ring.visible, "%s tutorial target border is still visible" % step)
	var arrow_head := tutorial.find_child("TutorialArrowHead", true, false) as Polygon2D
	_check(
		arrow_head != null and arrow_head.visible and arrow_head.polygon.size() == 3,
		"%s tutorial connector is missing its arrowhead" % step,
	)
	if arrow_head != null and arrow_head.polygon.size() == 3:
		_check(
			tutorial.get_global_rect().grow(1.0).has_point(arrow_head.polygon[0]),
			"%s tutorial arrowhead escapes the viewport" % step,
		)
	var card_insets := tutorial.find_child("CalloutInsets", true, false) as MarginContainer
	_check(
		card_insets != null
		and card_insets.get_theme_constant(&"margin_top") == 24
		and card_insets.get_theme_constant(&"margin_bottom") == 24
		and card_insets.get_theme_constant(&"margin_left") == 12
		and card_insets.get_theme_constant(&"margin_right") == 12,
		"%s tutorial callout padding changed" % step,
	)
	var action_insets := tutorial.find_child("TutorialActionInsets", true, false) as MarginContainer
	_check(
		action_insets != null
		and action_insets.get_theme_constant(&"margin_top") == 12
		and action_insets.get_theme_constant(&"margin_bottom") == 12
		and action_insets.get_theme_constant(&"margin_left") == 12
		and action_insets.get_theme_constant(&"margin_right") == 12,
		"%s tutorial action padding changed" % step,
	)
	var primary := tutorial.find_child("TutorialPrimary", true, false) as Button
	var skip := tutorial.find_child("TutorialSkip", true, false) as Button
	_check(
		primary != null
		and primary.get_theme_color(&"font_color").is_equal_approx(Color("040a12"))
		and primary.get_theme_stylebox(&"normal") is StyleBoxFlat,
		"%s tutorial primary action is not solid gold with readable dark ink" % step,
	)
	_check(
		primary != null
		and skip != null
		and primary.get_theme_stylebox(&"focus") is StyleBoxEmpty
		and skip.get_theme_stylebox(&"focus") is StyleBoxEmpty,
		"%s tutorial actions still show a focus border" % step,
	)


func _transparent_gold_focus(button: Button) -> bool:
	if button == null:
		return false
	var style := button.get_theme_stylebox(&"focus") as StyleBoxFlat
	return (
		style != null
		and style.bg_color.a <= 0.01
		and style.get_border_width(SIDE_LEFT) >= 2
		and style.border_color.r > style.border_color.b
		and style.border_color.a >= 0.5
	)


func _contains(outer: Control, inner: Control) -> bool:
	if outer == null or inner == null:
		return false
	var outer_rect := outer.get_global_rect().grow(1.0)
	var inner_rect := inner.get_global_rect()
	return outer_rect.has_point(inner_rect.position) and outer_rect.has_point(inner_rect.end - Vector2.ONE)


func _dispose_content(node: Node, game: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	if game.get("content") == node:
		game.set("content", null)
	var parent := node.get_parent()
	if parent != null:
		parent.remove_child(node)
	node.free()
	for _frame: int in range(4):
		await process_frame


func _cleanup(game: Node) -> void:
	game.set("campaign_active", false)
	game.set("campaign", null)
	game.set("campaign_store", null)
	game.set("selected_stage_id", &"")
	game.set("content", null)
	game.call("set_view_preferences_path", PREFS.DEFAULT_PATH)
	ProjectSettings.set_setting("accessibility/reduced_motion", false)
	var music := root.get_node_or_null("Music")
	if music != null:
		music.call("stop")
	var sfx := root.get_node_or_null("Sfx")
	if sfx != null:
		sfx.call("stop_all")
	for _frame: int in range(12):
		await process_frame
	await create_timer(0.5).timeout


func _remove(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _preserve_files() -> void:
	for path: String in SAVE_PATHS:
		if FileAccess.file_exists(path):
			_preserved[path] = FileAccess.get_file_as_bytes(path)


func _clear_production_files() -> void:
	for path: String in SAVE_PATHS:
		_remove(path)


func _restore_files() -> void:
	for path: String in _preserved:
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file != null:
			file.store_buffer(_preserved[path] as PackedByteArray)
			file.close()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("TITLE_ONBOARDING_NAVIGATION_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)
