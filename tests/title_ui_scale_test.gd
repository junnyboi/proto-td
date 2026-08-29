extends SceneTree

const VIEWPORTS := {
	"4k": Vector2i(3840, 2160),
	"native_ultrawide": Vector2i(3440, 1440),
	"ultrawide": Vector2i(2560, 1080),
	"regular": Vector2i(1280, 720),
	"managed_tall_landscape": Vector2i(1280, 1100),
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
	await _verify_chinese_title_portrait()
	for label: String in VIEWPORTS:
		root.size = VIEWPORTS[label]
		await process_frame
		await process_frame
		if label == "managed_tall_landscape":
			_verify_tall_landscape_title()
		await _verify_settings(label, VIEWPORTS[label])
	await _verify_accessibility_scale()
	await _cleanup()
	_remove()
	call_deferred("_finish")


func _verify_title_scale() -> void:
	var entry_scroll := _title.find_child("EntryScroll", true, false) as ScrollContainer
	var entry_host := _title.find_child("EntryControls", true, false) as Control
	var wordmark := _title.find_child("Wordmark", true, false) as Label
	var start := _title.find_child("StartButton", true, false) as Button
	var language := _title.find_child("LanguageToggle", true, false) as Button
	var footer_dock := _title.find_child("FooterSettingsDock", true, false) as MarginContainer
	var footer_settings := _title.find_child("FooterSettingsButton", true, false) as Button
	_check(wordmark.get_theme_font_size(&"font_size") == 207, "landscape wordmark is not 1.5×")
	_check(_title.find_child("CanonSynopsis", true, false) == null, "removed title synopsis returned to the start screen")
	_check(_title.find_child("SettingsButton", true, false) == null, "removed duplicate main-stack Settings action returned")
	_check(start.get_theme_font_size(&"font_size") == 83, "Start typography is not 1.5×")
	_check(start.get_combined_minimum_size().y >= 141.0, "Start container did not grow with 1.5× typography")
	var expected_top_margin := 16 + roundi(float(VIEWPORTS["regular"].y) * 0.24) + 64
	_check(entry_host.get_theme_constant(&"margin_top") == expected_top_margin, "title and action stack did not move down by exactly 64px")
	for action: Button in [start, language]:
		for style_name: StringName in [&"normal", &"hover", &"pressed"]:
			var style := action.get_theme_stylebox(style_name) as StyleBoxFlat
			_check(style != null and style.get_corner_radius(CORNER_TOP_LEFT) >= 20, "%s lacks rounded %s borders" % [action.name, style_name])
	_check(entry_scroll != null and entry_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "title entry is not scroll-safe")
	_check(_inside(entry_host, wordmark), "1.5× wordmark overflows title content")
	_check(_inside(entry_host, start), "1.5× Start action overflows title content")
	_check(_inside(entry_host, language), "quick language toggle overflows title content")
	_check(
		language.get_global_rect().position.y >= start.get_global_rect().end.y,
		"quick language toggle is not below Start",
	)
	_check(entry_scroll != null and entry_scroll.scroll_vertical == 0, "title does not open at the top of its enlarged content")
	_check(entry_scroll != null and entry_scroll.get_global_rect().intersects(wordmark.get_global_rect()), "title wordmark is not visible in the initial viewport")
	_check(footer_dock != null and footer_settings != null, "fixed footer Settings control is missing")
	_check(_inside(_title, footer_dock) and _inside(footer_dock, footer_settings), "fixed footer Settings control overflows the title")
	_check(footer_settings.custom_minimum_size.y >= 44.0, "fixed footer Settings control is not touch safe")


func _verify_tall_landscape_title() -> void:
	var entry_scroll := _title.find_child("EntryScroll", true, false) as ScrollContainer
	var wordmark := _title.find_child("Wordmark", true, false) as Label
	var start := _title.find_child("StartButton", true, false) as Button
	var language := _title.find_child("LanguageToggle", true, false) as Button
	var footer := _title.find_child("FooterSettingsButton", true, false) as Button
	_check(wordmark.get_line_count() == 1, "managed tall-landscape wordmark wrapped")
	_check(entry_scroll.get_global_rect().intersects(wordmark.get_global_rect()), "managed tall-landscape wordmark is not initially visible")
	_check(entry_scroll.get_global_rect().intersects(start.get_global_rect()), "managed tall-landscape Start is not initially visible")
	_check(language.get_global_rect().end.y + 8.0 <= footer.get_global_rect().position.y, "managed tall-landscape language toggle overlaps the fixed Settings footer")


func _verify_chinese_title_portrait() -> void:
	root.size = VIEWPORTS["portrait"]
	root.get_node("I18n").call("set_locale", &"zh-CN")
	await process_frame
	await process_frame
	var wordmark := _title.find_child("Wordmark", true, false) as Label
	_check(wordmark.text == "PROTOS 防线", "Chinese title wordmark copy changed")
	_check(wordmark.get_line_count() == 1, "Chinese portrait wordmark isolates its final character")
	_check(wordmark.max_lines_visible == 1 and wordmark.autowrap_mode == TextServer.AUTOWRAP_OFF, "Chinese portrait wordmark can still wrap")
	_check(_inside(_title, wordmark), "Chinese portrait wordmark overflows the title viewport")
	root.size = VIEWPORTS["regular"]
	await process_frame
	await process_frame
	_check(wordmark.get_line_count() == 1, "Chinese landscape wordmark isolates its final character")
	_check(wordmark.max_lines_visible == 1 and wordmark.autowrap_mode == TextServer.AUTOWRAP_OFF, "Chinese landscape wordmark can still wrap")
	_check(_inside(_title, wordmark), "Chinese landscape wordmark overflows the title viewport")
	root.get_node("I18n").call("set_locale", &"en-US")
	await process_frame


func _verify_accessibility_scale() -> void:
	root.size = VIEWPORTS["regular"]
	var values := _title.call("_current_preferences") as Dictionary
	values[&"text_scale"] = 1.5
	_title.call("_apply_preference_values", values)
	for _frame: int in range(5):
		await process_frame
	var entry_scroll := _title.find_child("EntryScroll", true, false) as ScrollContainer
	var entry_host := _title.find_child("EntryControls", true, false) as Control
	var wordmark := _title.find_child("Wordmark", true, false) as Label
	var start := _title.find_child("StartButton", true, false) as Button
	var footer_settings := _title.find_child("FooterSettingsButton", true, false) as Button
	_check(wordmark.get_theme_font_size(&"font_size") <= 120, "150% decorative wordmark did not fit down")
	_check(start.get_theme_font_size(&"font_size") >= 120, "150% Start text did not receive the global scale")
	_check(_inside(entry_host, wordmark) and _inside(entry_host, start), "150% Title content escaped its scroll document")
	_check(_title.find_child("SettingsButton", true, false) == null, "150% Title retained the duplicate Settings action")
	_check(footer_settings != null and footer_settings.visible and _inside(_title, footer_settings), "150% fixed Settings action is unavailable")
	_check(entry_scroll.get_global_rect().intersects(start.get_global_rect()), "150% Start is not initially visible")
	values[&"text_scale"] = 1.0
	_title.call("_apply_preference_values", values)
	for _frame: int in range(4):
		await process_frame


func _verify_settings(label: String, viewport: Vector2i) -> void:
	var footer_dock := _title.find_child("FooterSettingsDock", true, false) as MarginContainer
	var footer_button := _title.find_child("FooterSettingsButton", true, false) as Button
	_check(footer_dock != null and footer_button != null and footer_dock.visible, "%s footer Settings action is not visible" % label)
	_check(_inside(_title, footer_dock) and _inside(footer_dock, footer_button), "%s footer Settings action escaped the viewport" % label)
	_check(absf(footer_dock.get_global_rect().end.y - float(viewport.y)) <= EPSILON, "%s footer dock is not fixed to the bottom edge" % label)
	_title.call("_open_settings")
	var state := _title.get_node("TitleSettings") as Control
	await _wait_for_transition(state, &"ACTIVE")
	await process_frame
	var safe := state.get_node("SafeFrame") as Control
	var frame := state.get_node("SafeFrame/CommandFrame") as Control
	var header := state.find_child("Header", true, false) as Control
	var scroll := state.find_child("SettingsScroll", true, false) as ScrollContainer
	var columns := state.find_child("SettingsColumns", true, false) as GridContainer
	var body_margin := state.find_child("BodyMargin", true, false) as MarginContainer
	var dock := state.find_child("ActionDock", true, false) as Control
	var apply := state.find_child("SettingsApplyButton", true, false) as Button
	var back := state.find_child("SettingsBackButton", true, false) as Button
	var back_padding := state.find_child("BackButtonPadding", true, false) as MarginContainer
	var locale_selector := state.find_child("LocaleSelector", true, false) as BoxContainer
	var locale_list := state.find_child("LocaleList", true, false) as ItemList
	var locale_label := state.find_child("LocaleLabel", true, false) as Label
	var language_section := state.find_child("LanguageAudioSection", true, false) as PanelContainer
	var graphics_section := state.find_child("GraphicsAccessibilitySection", true, false) as PanelContainer
	var music_button_container := state.find_child("MusicButtonContainer", true, false) as MarginContainer
	var motion_button_container := state.find_child("MotionButtonContainer", true, false) as MarginContainer
	var frame_row := state.find_child("FrameLimitRow", true, false) as BoxContainer
	var focus_owner := root.gui_get_focus_owner()
	var master_label := state.find_child("MasterVolumeLabel", true, false) as Label
	var master := state.find_child("MasterVolumeSlider", true, false) as HSlider
	var music := state.find_child("MusicVolumeSlider", true, false) as HSlider
	var sfx := state.find_child("SfxVolumeSlider", true, false) as HSlider
	var music_button := state.find_child("MusicButton", true, false) as Button
	var frame_option := state.find_child("FrameLimitOption", true, false) as OptionButton
	var motion := state.find_child("MotionButton", true, false) as Button
	var background_downloads := state.find_child("BackgroundDownloadsButton", true, false) as Button
	var background_hint := state.find_child("BackgroundDownloadsHint", true, false) as Label
	var text_scale_label := state.find_child("TextScaleLabel", true, false) as Label
	var text_scale := state.find_child("TextScaleSlider", true, false) as HSlider
	var clear_player_data := state.find_child("ClearPlayerDataButton", true, false) as Button
	var player_data_hint := state.find_child("PlayerDataHint", true, false) as Label
	var error := state.find_child("SettingsError", true, false) as Label
	_check(_rect_matches(state, viewport), "%s state root is not full viewport" % label)
	_check(
		_inside(state, safe) and _inside(state, frame),
		"%s safe command frame overflows: state=%s safe=%s frame=%s" % [
			label, state.get_global_rect(), safe.get_global_rect(), frame.get_global_rect(),
		],
	)
	_check(_inside(state, header) and _inside(state, dock), "%s persistent header/dock overflows" % label)
	_check(_inside(frame, header) and _inside(frame, scroll) and _inside(frame, dock), "%s command-frame content overflows" % label)
	_check(body_margin.get_theme_constant(&"margin_left") >= 0 and body_margin.get_theme_constant(&"margin_top") >= 0, "%s settings body margins are invalid" % label)
	var language_style := language_section.get_theme_stylebox(&"panel") if language_section != null else null
	var graphics_style := graphics_section.get_theme_stylebox(&"panel") if graphics_section != null else null
	var expected_section_padding := 48.0 if columns.columns == 2 else 24.0
	_check(
		language_style != null
		and is_equal_approx(language_style.content_margin_left, expected_section_padding)
		and is_equal_approx(language_style.content_margin_top, expected_section_padding)
		and is_equal_approx(language_style.content_margin_right, expected_section_padding)
		and is_equal_approx(language_style.content_margin_bottom, expected_section_padding),
		"%s language/audio custom surface has the wrong responsive padding" % label,
	)
	_check(
		graphics_style != null
		and is_equal_approx(graphics_style.content_margin_left, expected_section_padding)
		and is_equal_approx(graphics_style.content_margin_top, expected_section_padding)
		and is_equal_approx(graphics_style.content_margin_right, expected_section_padding)
		and is_equal_approx(graphics_style.content_margin_bottom, expected_section_padding),
		"%s graphics/accessibility custom surface has the wrong responsive padding" % label,
	)
	var expected_back_padding := (
		24
		if viewport.x >= 1200
		and viewport.y > 560
		and float(viewport.x) / maxf(float(viewport.y), 1.0) > 1.2
		else 0
	)
	_check(
		back_padding != null
		and back_padding.get_theme_constant(&"margin_left") == expected_back_padding
		and back_padding.get_theme_constant(&"margin_right") == expected_back_padding,
		"%s Back container has the wrong responsive horizontal padding" % label,
	)
	var expected_toggle_margin := 48 if columns.columns == 2 else 16
	for toggle_container: MarginContainer in [music_button_container, motion_button_container]:
		_check(
			toggle_container != null
			and toggle_container.get_theme_constant(&"margin_left") == expected_toggle_margin
			and toggle_container.get_theme_constant(&"margin_right") == expected_toggle_margin,
			"%s %s has the wrong responsive horizontal margin" % [label, toggle_container.name if toggle_container != null else "toggle container"],
		)
	_check(scroll.size.y > 0.0 and scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "%s body scroll is invalid" % label)
	_check(header.get_global_rect().end.y <= scroll.get_global_rect().position.y + EPSILON, "%s header entered body scroll" % label)
	_check(scroll.get_global_rect().end.y <= dock.get_global_rect().position.y + EPSILON, "%s dock entered body scroll" % label)
	_check(apply.custom_minimum_size.y >= 44.0 and back.custom_minimum_size.y >= 44.0, "%s actions are not touch safe" % label)
	_check(apply.custom_minimum_size.x >= 180.0 and apply.custom_minimum_size.x <= 483.0 + EPSILON, "%s Apply action does not use a centered fixed-width contract" % label)
	_check(dock.size_flags_horizontal == Control.SIZE_SHRINK_CENTER and absf(dock.custom_minimum_size.x - apply.custom_minimum_size.x) <= EPSILON, "%s Apply dock is not centered at its fixed width" % label)
	for color_name: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color"]:
		_check(apply.get_theme_color(color_name).is_equal_approx(Color.WHITE), "%s Apply %s is not white" % [label, color_name])
	var apply_style := apply.get_theme_stylebox(&"normal") as StyleBoxTexture
	_check(
		apply_style != null
		and apply_style.texture != null
		and apply_style.texture.resource_path.ends_with("/primary_button.png"),
		"%s Apply does not use the shared ornate golden button art" % label,
	)
	_check(
		apply_style != null
		and apply_style.content_margin_left >= 28.0
		and apply_style.content_margin_top >= 18.0
		and apply_style.content_margin_right >= 28.0
		and apply_style.content_margin_bottom >= 18.0,
		"%s Apply does not retain the shared ornate action padding" % label,
	)
	_check(not apply.clip_text and not back.clip_text, "%s title actions clip doubled copy" % label)
	_check(apply.autowrap_mode != TextServer.AUTOWRAP_OFF, "%s Apply action does not wrap doubled copy" % label)
	_check(back.autowrap_mode == TextServer.AUTOWRAP_OFF, "%s Back action is not constrained to one line" % label)
	_check(master.custom_minimum_size.y >= 48.0 and music.custom_minimum_size.y >= 48.0 and sfx.custom_minimum_size.y >= 48.0 and text_scale.custom_minimum_size.y >= 48.0, "%s sliders are below the 48 px hit target" % label)
	_check(text_scale.min_value == 80.0 and text_scale.max_value == 150.0 and text_scale.step == 5.0, "%s text-scale slider has the wrong accessibility range" % label)
	_check(text_scale_label.text.contains("100%") or text_scale_label.text.contains("100％"), "%s text-scale readout omits its percentage" % label)
	_check(not back.clip_text and not music_button.clip_text and not motion.clip_text and not background_downloads.clip_text and not clear_player_data.clip_text and not apply.clip_text, "%s translated actions still clip text" % label)
	_check(background_downloads.custom_minimum_size.y >= 82.0, "%s background-download toggle is not touch safe" % label)
	_check(clear_player_data != null and clear_player_data.custom_minimum_size.y >= 82.0, "%s Clear Player Data action is not touch safe" % label)
	_check(player_data_hint != null and not player_data_hint.text.is_empty() and player_data_hint.autowrap_mode != TextServer.AUTOWRAP_OFF, "%s player-data warning is missing or cannot wrap" % label)
	_check(
		motion.autowrap_mode != TextServer.AUTOWRAP_ARBITRARY
		and background_downloads.autowrap_mode != TextServer.AUTOWRAP_ARBITRARY,
		"%s compact Settings toggle can wrap into fragmented labels" % label,
	)
	_check(not background_hint.text.is_empty() and background_hint.autowrap_mode != TextServer.AUTOWRAP_OFF, "%s metered-connection hint is missing or cannot wrap" % label)
	_check(not state.accessibility_name.is_empty() and not state.accessibility_description.is_empty(), "%s Settings root lacks accessibility semantics" % label)
	_check(not back.accessibility_name.is_empty() and not locale_list.accessibility_name.is_empty() and not apply.accessibility_name.is_empty(), "%s key actions lack accessibility names" % label)
	_check(master.accessibility_name.contains("%") or master.accessibility_name.contains("percent") or master.accessibility_name.contains("百分"), "%s master slider name lacks its percentage" % label)
	_check(text_scale.accessibility_name.contains("%") or text_scale.accessibility_name.contains("percent") or text_scale.accessibility_name.contains("百分"), "%s text-scale slider name lacks its percentage" % label)
	_check(not text_scale.accessibility_description.is_empty(), "%s text-scale slider lacks an accessibility description" % label)
	_check(not music_button.accessibility_description.is_empty() and not motion.accessibility_description.is_empty() and not background_downloads.accessibility_description.is_empty() and not clear_player_data.accessibility_description.is_empty() and not frame_option.accessibility_description.is_empty(), "%s settings controls lack accessibility descriptions" % label)
	_check(error.accessibility_live == AccessibilityServer.LIVE_ASSERTIVE, "%s Settings error is not assertive live content" % label)
	_check(locale_list.custom_minimum_size.x <= EPSILON, "%s locale selector retains a fixed width" % label)
	_check(
		not locale_list.auto_height and locale_list.custom_minimum_size.y <= 104.0,
		"%s locale selector is not bounded to a compact row: custom=%s size=%s"
		% [label, locale_list.custom_minimum_size, locale_list.size],
	)
	_check(locale_list.fixed_column_width > 0, "%s locale selector columns have no stable spacing" % label)
	_check(
		not locale_list.get_v_scroll_bar().visible and not locale_list.get_h_scroll_bar().visible,
		"%s locale selector still exposes scrollbars: custom=%s size=%s vertical=%s horizontal=%s"
		% [label, locale_list.custom_minimum_size, locale_list.size, locale_list.get_v_scroll_bar().visible, locale_list.get_h_scroll_bar().visible],
	)
	_check(locale_selector.alignment == BoxContainer.ALIGNMENT_CENTER, "%s locale selector content is not centered" % label)
	_check(locale_list.get_theme_font_size(&"font_size") < master_label.get_theme_font_size(&"font_size"), "%s locale text was not reduced below settings body type" % label)
	var compact := viewport.x <= 720 or viewport.y <= 560 or float(viewport.x) / float(viewport.y) <= 1.2
	var compact_locale_visibility := viewport.x <= 720 or float(viewport.x) / float(viewport.y) <= 1.2
	if compact_locale_visibility:
		_check(
			_inside(scroll, locale_selector) and _inside(scroll, locale_label) and _inside(scroll, locale_list),
			"%s initial locale selector is clipped by the Settings header" % label,
		)
		_check(locale_label.size.y >= 44.0, "%s locale heading collapsed below readable height" % label)
		_check(locale_label.get_line_count() == 1, "%s locale heading wraps character by character" % label)
		_check(locale_label.text.length() >= 6, "%s locale heading was truncated instead of resized" % label)
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
		for control: Control in [master, music, sfx, frame_option, text_scale]:
			_check(control.focus_neighbor_left == control.get_path_to(control) and control.focus_neighbor_right == control.get_path_to(control), "%s stacked value control does not retain native Left/Right" % label)
	else:
		_check(master.get_node_or_null(master.focus_neighbor_right) == frame_option, "%s wide Master does not move spatially to frame limit" % label)
		_check(frame_option.get_node_or_null(frame_option.focus_neighbor_left) == locale_list, "%s wide frame limit does not return to the locale peer" % label)
		_check(music_button.get_node_or_null(music_button.focus_neighbor_right) == text_scale, "%s wide music toggle does not move to text scale" % label)
		_check(motion.get_node_or_null(motion.focus_neighbor_left) == music_button, "%s wide motion toggle does not return to music" % label)
		_check(text_scale.get_node_or_null(text_scale.focus_neighbor_left) == music_button, "%s wide text scale does not return to the audio column" % label)
		_check(motion.get_node_or_null(motion.focus_neighbor_bottom) == background_downloads, "%s wide motion toggle does not move down to background downloads" % label)
		_check(background_downloads.get_node_or_null(background_downloads.focus_neighbor_bottom) == text_scale, "%s wide background downloads does not move down to text scale" % label)
		_check(text_scale.get_node_or_null(text_scale.focus_neighbor_bottom) == clear_player_data, "%s wide text scale does not move down to Clear Player Data" % label)
		_check(clear_player_data.get_node_or_null(clear_player_data.focus_neighbor_top) == text_scale, "%s wide Clear Player Data does not return to text scale" % label)
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
			state.find_child("BackgroundDownloadsButton", true, false) as Control,
			state.find_child("TextScaleSlider", true, false) as Control,
			state.find_child("ClearPlayerDataButton", true, false) as Control,
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
