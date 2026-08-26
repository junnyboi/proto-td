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
	var wordmark := _title.find_child("Wordmark", true, false) as Label
	var synopsis := _title.find_child("CanonSynopsis", true, false) as Label
	var start := _title.find_child("StartButton", true, false) as Button
	var settings := _title.find_child("SettingsButton", true, false) as Button
	_check(wordmark.get_theme_font_size(&"font_size") == 138, "landscape wordmark did not retain near-doubled readability")
	_check(synopsis != null and synopsis.get_theme_font_size(&"font_size") >= 27, "canon synopsis typography is unreadable")
	_check(synopsis != null and synopsis.get_visible_line_count() == synopsis.get_line_count(), "canon synopsis is clipped")
	_check(start.get_theme_font_size(&"font_size") == 55, "Start typography is not doubled")
	_check(settings.get_theme_font_size(&"font_size") == 46, "Settings typography is not doubled")
	_check(start.custom_minimum_size.y >= 90.0, "Start container did not grow with typography")
	_check(settings.custom_minimum_size.y >= 80.0, "Settings container did not grow with typography")
	_check(_inside(_title, wordmark), "doubled wordmark overflows the title viewport")
	_check(_inside(_title, synopsis), "canon synopsis overflows the title viewport")
	_check(_inside(_title, start), "doubled Start action is outside the title viewport")
	_check(_inside(_title, settings), "doubled Settings action is outside the title viewport")


func _verify_settings(label: String, viewport: Vector2i) -> void:
	_title.call("_open_settings")
	await process_frame
	await process_frame
	var state := _title.get_node("TitleSettings") as Control
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
	_check(locale_list.custom_minimum_size.x <= EPSILON, "%s locale selector retains a fixed width" % label)
	var compact := viewport.x <= 720 or float(viewport.x) / float(viewport.y) <= 1.2
	_check(columns.columns == (1 if compact else 2), "%s has wrong section composition" % label)
	_check(frame_row.vertical == compact, "%s frame-limit row has wrong compact orientation" % label)
	_check(locale_selector.vertical == compact, "%s locale selector has wrong compact orientation" % label)
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
	if label == "short":
		var body := state.find_child("SettingsColumns", true, false) as Control
		_check(body.size.y > scroll.size.y, "short settings body does not expose vertical overflow")
	_check(apply.focus_next == apply.get_path_to(back), "%s Apply traversal does not wrap to Back" % label)
	_check(back.focus_previous == back.get_path_to(apply), "%s Back reverse traversal does not wrap to Apply" % label)
	var retained_focus := state.find_child("MotionButton", true, false) as Button
	retained_focus.grab_focus()
	root.get_node("I18n").call("set_locale", &"zh-CN")
	await process_frame
	await process_frame
	_check(retained_focus.has_focus(), "%s locale refresh lost logical focus" % label)
	_check(not apply.text.is_empty() and apply.text != "APPLY", "%s locale refresh did not update mounted copy" % label)
	root.get_node("I18n").call("set_locale", &"en-US")
	await process_frame
	_title.call("_close_settings")
	await process_frame


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
