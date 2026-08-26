extends SceneTree

const VIEWPORTS := {
	"ultrawide": Vector2i(2560, 1080),
	"regular": Vector2i(1280, 720),
	"short_baseline": Vector2i(1024, 576),
	"short": Vector2i(960, 420),
	"portrait": Vector2i(720, 1280),
	"narrow_390": Vector2i(390, 844),
	"narrow_360": Vector2i(360, 800),
}
const PATH := "user://title_ui_scale_test.cfg"
const EPSILON := 1.0
const WAIT_TIMEOUT := 1.0

var _failures: Array[String] = []
var _title: Control = null


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_remove()
	root.size = VIEWPORTS["regular"]
	_title = load("res://scenes/title.tscn").instantiate() as Control
	_title.call("set_preferences_path", PATH)
	root.add_child(_title)
	await process_frame
	await process_frame
	_verify_title_scale()
	for label: String in VIEWPORTS:
		root.size = VIEWPORTS[label]
		await process_frame
		await process_frame
		await _verify_settings(label, VIEWPORTS[label])
	await _cleanup()
	_remove()
	call_deferred("_finish")


func _verify_title_scale() -> void:
	var entry_scroll := _title.find_child("EntryScroll", true, false) as ScrollContainer
	var entry_host := _title.find_child("EntryControls", true, false) as Control
	var wordmark := _title.find_child("Wordmark", true, false) as Label
	var start := _title.find_child("StartButton", true, false) as Button
	var settings := _title.find_child("SettingsButton", true, false) as Button
	_check(wordmark.get_theme_font_size(&"font_size") == 207, "landscape wordmark is not 1.5×")
	_check(_title.find_child("CanonSynopsis", true, false) == null, "removed title synopsis returned to the start screen")
	_check(start.get_theme_font_size(&"font_size") == 83, "Start typography is not 1.5×")
	_check(settings.get_theme_font_size(&"font_size") == 69, "Settings typography is not 1.5×")
	_check(start.get_combined_minimum_size().y >= 141.0, "Start container did not grow with 1.5× typography")
	_check(settings.get_combined_minimum_size().y >= 121.0, "Settings container did not grow with 1.5× typography")
	_check(entry_scroll != null and entry_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "title entry is not scroll-safe")
	_check(_inside(entry_host, wordmark), "1.5× wordmark overflows title content")
	_check(_inside(entry_host, start), "1.5× Start action overflows title content")
	_check(_inside(entry_host, settings), "1.5× Settings action overflows title content")
	_check(entry_scroll != null and entry_scroll.scroll_vertical == 0, "title does not open at the top of its enlarged content")
	_check(entry_scroll != null and entry_scroll.get_global_rect().intersects(wordmark.get_global_rect()), "title wordmark is not visible in the initial viewport")


func _verify_settings(label: String, viewport: Vector2i) -> void:
	_title.call("_open_settings")
	var state := _title.get_node("TitleSettings") as Control
	await _wait_for_transition(state, &"ACTIVE")
	await process_frame
	var safe := state.get_node("SafeFrame") as Control
	var frame := state.get_node("SafeFrame/CommandFrame") as Control
	var header := state.find_child("Header", true, false) as Control
	var scroll := state.find_child("SettingsScroll", true, false) as ScrollContainer
	var columns := state.find_child("SettingsColumns", true, false) as GridContainer
	var dock := state.find_child("ActionDock", true, false) as Control
	var apply := state.find_child("SettingsApplyButton", true, false) as Button
	var back := state.find_child("SettingsBackButton", true, false) as Button
	var locale_selector := state.find_child("LocaleSelector", true, false) as BoxContainer
	var locale_list := state.find_child("LocaleList", true, false) as ItemList
	var frame_row := state.find_child("FrameLimitRow", true, false) as BoxContainer
	var focus_owner := root.gui_get_focus_owner()
	var master := state.find_child("MasterVolumeSlider", true, false) as HSlider
	var music := state.find_child("MusicVolumeSlider", true, false) as HSlider
	var sfx := state.find_child("SfxVolumeSlider", true, false) as HSlider
	var music_button := state.find_child("MusicButton", true, false) as Button
	var frame_option := state.find_child("FrameLimitOption", true, false) as OptionButton
	var motion := state.find_child("MotionButton", true, false) as Button
	var error := state.find_child("SettingsError", true, false) as Label
	_check(_rect_matches(state, viewport), "%s state root is not full viewport" % label)
	_check(_inside(state, safe) and _inside(state, frame), "%s safe command frame overflows" % label)
	_check(_inside(state, header) and _inside(state, dock), "%s persistent header/dock overflows" % label)
	_check(_inside(frame, header) and _inside(frame, scroll) and _inside(frame, dock), "%s command-frame content overflows" % label)
	_check(scroll.size.y > 0.0 and scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "%s body scroll is invalid" % label)
	_check(header.get_global_rect().end.y <= scroll.get_global_rect().position.y + EPSILON, "%s header entered body scroll" % label)
	_check(scroll.get_global_rect().end.y <= dock.get_global_rect().position.y + EPSILON, "%s dock entered body scroll" % label)
	_check(apply.custom_minimum_size.y >= 44.0 and back.custom_minimum_size.y >= 44.0, "%s actions are not touch safe" % label)
	_check(not apply.clip_text and not back.clip_text, "%s title actions clip doubled copy" % label)
	_check(apply.autowrap_mode != TextServer.AUTOWRAP_OFF and back.autowrap_mode != TextServer.AUTOWRAP_OFF, "%s title actions do not wrap doubled copy" % label)
	_check(master.custom_minimum_size.y >= 48.0 and music.custom_minimum_size.y >= 48.0 and sfx.custom_minimum_size.y >= 48.0, "%s sliders are below the 48 px hit target" % label)
	_check(not back.clip_text and not music_button.clip_text and not motion.clip_text and not apply.clip_text, "%s translated actions still clip text" % label)
	_check(not state.accessibility_name.is_empty() and not state.accessibility_description.is_empty(), "%s Settings root lacks accessibility semantics" % label)
	_check(not back.accessibility_name.is_empty() and not locale_list.accessibility_name.is_empty() and not apply.accessibility_name.is_empty(), "%s key actions lack accessibility names" % label)
	_check(master.accessibility_name.contains("%") or master.accessibility_name.contains("百分"), "%s master slider name lacks its percentage" % label)
	_check(not music_button.accessibility_description.is_empty() and not motion.accessibility_description.is_empty() and not frame_option.accessibility_description.is_empty(), "%s settings controls lack accessibility descriptions" % label)
	_check(error.accessibility_live == AccessibilityServer.LIVE_ASSERTIVE, "%s Settings error is not assertive live content" % label)
	_check(locale_list.custom_minimum_size.x <= EPSILON, "%s locale selector retains a fixed width" % label)
	var compact := viewport.x <= 720 or viewport.y <= 560 or float(viewport.x) / float(viewport.y) <= 1.2
	_check(columns.columns == (1 if compact else 2), "%s has wrong section composition" % label)
	_check(frame_row.vertical, "%s frame-limit row is not stacked for 1.5× type" % label)
	_check(locale_selector.vertical, "%s locale selector is not stacked for 1.5× type" % label)
	_check(focus_owner != null and state.is_ancestor_of(focus_owner), "%s initial focus escaped Settings" % label)
	for control: Control in _focus_controls(state):
		for path: NodePath in [
			control.focus_next,
			control.focus_previous,
			control.focus_neighbor_top,
			control.focus_neighbor_bottom,
			control.focus_neighbor_left,
			control.focus_neighbor_right,
		]:
			var target := control.get_node_or_null(path) as Control
			_check(target != null and state.is_ancestor_of(target), "%s has an open focus edge at %s" % [label, control.name])
	if columns.columns == 1:
		for control: Control in [master, music, sfx, frame_option]:
			_check(control.focus_neighbor_left == control.get_path_to(control) and control.focus_neighbor_right == control.get_path_to(control), "%s stacked value control does not retain native Left/Right" % label)
	else:
		_check(master.get_node_or_null(master.focus_neighbor_right) == frame_option, "%s wide Master does not move spatially to frame limit" % label)
		_check(frame_option.get_node_or_null(frame_option.focus_neighbor_left) == locale_list, "%s wide frame limit does not return to the locale peer" % label)
		_check(music_button.get_node_or_null(music_button.focus_neighbor_right) == motion, "%s wide music toggle does not move to motion" % label)
		_check(motion.get_node_or_null(motion.focus_neighbor_left) == music_button, "%s wide motion toggle does not return to music" % label)
	if label == "short":
		var body := state.find_child("SettingsColumns", true, false) as Control
		_check(body.size.y > scroll.size.y, "short settings body does not expose vertical overflow")
	_check(apply.focus_next == apply.get_path_to(back), "%s Apply traversal does not wrap to Back" % label)
	_check(back.focus_previous == back.get_path_to(apply), "%s Back reverse traversal does not wrap to Apply" % label)
	var retained_focus := state.find_child("MotionButton", true, false) as Button
	retained_focus.grab_focus()
	await process_frame
	var external := _title.find_child("StartButton", true, false) as Button
	external.focus_mode = Control.FOCUS_ALL
	external.grab_focus()
	await process_frame
	await process_frame
	_check(retained_focus.has_focus(), "%s focus containment did not redirect external focus" % label)
	root.get_node("I18n").call("set_locale", &"zh-CN")
	await process_frame
	await process_frame
	_check(retained_focus.has_focus(), "%s locale refresh lost logical focus" % label)
	_check(not apply.text.is_empty() and apply.text != "APPLY", "%s locale refresh did not update mounted copy" % label)
	root.get_node("I18n").call("set_locale", &"en-US")
	await process_frame
	_title.call("_close_settings")
	await _wait_for_transition(state, &"CLOSED")


func _wait_for_transition(state: Control, expected: StringName) -> bool:
	var elapsed := 0.0
	while StringName(state.call("transition_state_name")) != expected and elapsed < WAIT_TIMEOUT:
		await create_timer(0.01).timeout
		elapsed += 0.01
	var matched := StringName(state.call("transition_state_name")) == expected
	_check(matched, "transition timed out waiting for %s" % expected)
	return matched


func _focus_controls(state: Control) -> Array[Control]:
	return [
		state.find_child("SettingsBackButton", true, false) as Control,
		state.find_child("LocaleList", true, false) as Control,
		state.find_child("MasterVolumeSlider", true, false) as Control,
		state.find_child("MusicVolumeSlider", true, false) as Control,
		state.find_child("SfxVolumeSlider", true, false) as Control,
		state.find_child("MusicButton", true, false) as Control,
		state.find_child("FrameLimitOption", true, false) as Control,
		state.find_child("MotionButton", true, false) as Control,
		state.find_child("SettingsApplyButton", true, false) as Control,
	]


func _rect_matches(control: Control, viewport: Vector2i) -> bool:
	var rect := control.get_global_rect()
	return rect.position.length() <= EPSILON and absf(rect.size.x - viewport.x) <= EPSILON and absf(rect.size.y - viewport.y) <= EPSILON


func _inside(parent: Control, child: Control) -> bool:
	if parent == null or child == null:
		return false
	var outer := parent.get_global_rect()
	var inner := child.get_global_rect()
	return inner.position.x >= outer.position.x - EPSILON and inner.position.y >= outer.position.y - EPSILON and inner.end.x <= outer.end.x + EPSILON and inner.end.y <= outer.end.y + EPSILON


func _cleanup() -> void:
	var game := root.get_node_or_null("Game")
	if game != null and game.get("content") == _title:
		game.set("content", null)
	var music := root.get_node_or_null("Music")
	if music != null:
		music.call("stop")
	var sfx := root.get_node_or_null("Sfx")
	if sfx != null:
		sfx.call("stop_all")
	_title.queue_free()
	for _frame: int in range(12):
		await process_frame
	await create_timer(0.5).timeout


func _remove() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


func _finish() -> void:
	if _failures.is_empty():
		print("TITLE_UI_SCALE_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
