extends Control

## Premium Lunaris player entry. Title remains the presentation and music owner;
## Settings is an explicit exclusive full-viewport child state.

const LunarisBackdropType := preload("res://scripts/ui/components/lunaris_animated_backdrop.gd")
const StagingSkinType := preload("res://scripts/ui/components/staging_skin.gd")
const UiCopyType := preload("res://scripts/ui/components/ui_copy.gd")
const ViewPreferencesType := preload("res://scripts/view/view_preferences.gd")
const STAGING_THEME := preload("res://data/presentation/ui/threshold_theme.tres")

const GOLD := Color("d8b978")
const BRIGHT_GOLD := Color("f0d89a")
const MOON_CYAN := Color("91eaf1")
const IVORY := Color("f5efe1")
const VOID := Color("071019")
const FOCUS_PULSE_SECONDS := 2.8
const FOCUS_PULSE_MIN_ALPHA := 0.12
const FOCUS_PULSE_MAX_ALPHA := 0.30
const TITLE_UI_SCALE := 1.15
const TITLE_FONT_SCALE := 3.0
const ENTRY_FADE_SECONDS := 0.56
const ENTRY_STAGGER_SECONDS := 0.09
const HOVER_SCALE := Vector2(1.025, 1.025)
const HOVER_TWEEN_SECONDS := 0.16
const MASTER_BUS := &"Master"
const MUSIC_BUS := &"Music"
const SFX_BUS := &"SFX"

enum ScreenState { TITLE, SETTINGS, COMMITTING }

var _screen_state := ScreenState.TITLE
var _settings_snapshot: Dictionary = {}
var _backdrop: LunarisBackdropType = null
var _entry_scroll: ScrollContainer = null
var _entry_host: MarginContainer = null
var _entry_stack: VBoxContainer = null
var _wordmark: Label = null
var _orbit_rule: HBoxContainer = null
var _start_button: Button = null
var _settings_button: Button = null
var _title_music_enabled := true
var _reduced_motion := false
var _master_volume := 1.0
var _music_volume := 1.0
var _sfx_volume := 1.0
var _frame_limit := 0
var _preferences_path := ViewPreferencesType.DEFAULT_PATH
var _focus_pulse_elapsed := 0.0
var _focus_pulse_styles: Dictionary = {}
var _focus_pulse_colors: Dictionary = {}
var _entry_tween: Tween = null
var _hover_tweens: Dictionary = {}
var _highlighted_actions: Dictionary = {}
var _interaction_feedback_ready := false
var _title_focus_scroll_ready := false

@onready var _settings_state: TitleSettings = $TitleSettings


func _ready() -> void:
	theme = STAGING_THEME
	var stored_locale := ViewPreferencesType.locale(_preferences_path)
	I18n.set_locale(stored_locale)
	_title_music_enabled = ViewPreferencesType.title_music_enabled(_preferences_path)
	_reduced_motion = ViewPreferencesType.reduced_motion(_preferences_path)
	_master_volume = ViewPreferencesType.master_volume(_preferences_path)
	_music_volume = ViewPreferencesType.music_volume(_preferences_path)
	_sfx_volume = ViewPreferencesType.sfx_volume(_preferences_path)
	_frame_limit = ViewPreferencesType.frame_limit(_preferences_path)
	_apply_audio_settings()
	_apply_graphics_settings()
	_build_screen()
	move_child(_settings_state, get_child_count() - 1)
	_settings_state.cancel_requested.connect(_cancel_settings)
	_settings_state.apply_requested.connect(_apply_settings)
	_settings_state.preview_requested.connect(_preview_settings)
	_settings_state.close_completed.connect(_on_settings_close_completed)
	get_viewport().size_changed.connect(_apply_responsive_layout)
	I18n.locale_changed.connect(_on_locale_changed)
	_refresh_copy()
	_apply_responsive_layout()
	_begin_title_reveal.call_deferred()
	_start_button.grab_focus.call_deferred()
	Game.content = self
	Music.set_enabled(_title_music_enabled)
	if _title_music_enabled:
		Music.play_cue(&"title_lunaris")


func _exit_tree() -> void:
	if _entry_tween != null and _entry_tween.is_valid():
		_entry_tween.kill()
	for tween_value: Variant in _hover_tweens.values():
		if tween_value is Tween and (tween_value as Tween).is_valid():
			(tween_value as Tween).kill()
	if _backdrop != null:
		_backdrop.stop()


func _process(delta: float) -> void:
	_focus_pulse_elapsed = fmod(_focus_pulse_elapsed + delta, FOCUS_PULSE_SECONDS)
	var pulse := 0.20
	if not _reduced_motion:
		var wave := (sin((_focus_pulse_elapsed / FOCUS_PULSE_SECONDS) * TAU) + 1.0) * 0.5
		pulse = lerpf(FOCUS_PULSE_MIN_ALPHA, FOCUS_PULSE_MAX_ALPHA, wave)
	for button in _focus_pulse_styles:
		var style: StyleBoxFlat = _focus_pulse_styles[button]
		var accent: Color = _focus_pulse_colors[button]
		style.bg_color = Color(accent, pulse)
		(button as Button).queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if _screen_state in [ScreenState.SETTINGS, ScreenState.COMMITTING] and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _screen_state == ScreenState.SETTINGS:
			_cancel_settings()


func _build_screen() -> void:
	_backdrop = LunarisBackdropType.new()
	_backdrop.name = "LunarisBackdrop"
	add_child(_backdrop)
	_backdrop.set_reduced_motion(_reduced_motion)

	var atmosphere := ColorRect.new()
	atmosphere.name = "Atmosphere"
	atmosphere.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	atmosphere.color = Color(0.003, 0.012, 0.025, 0.08)
	atmosphere.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(atmosphere)

	_entry_scroll = ScrollContainer.new()
	_entry_scroll.name = "EntryScroll"
	_entry_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_entry_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_entry_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_entry_scroll.follow_focus = false
	_entry_scroll.draw_focus_border = false
	add_child(_entry_scroll)

	_entry_host = MarginContainer.new()
	_entry_host.name = "EntryControls"
	_entry_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_entry_scroll.add_child(_entry_host)

	_entry_stack = VBoxContainer.new()
	_entry_stack.name = "EntryStack"
	_entry_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	_entry_stack.add_theme_constant_override(&"separation", 12)
	_entry_host.add_child(_entry_stack)

	_wordmark = Label.new()
	_wordmark.name = "Wordmark"
	_wordmark.text = "PROTOS DEFENSE"
	_wordmark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wordmark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_wordmark.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_wordmark.max_lines_visible = 2
	_wordmark.add_theme_constant_override(&"outline_size", 12)
	_wordmark.add_theme_color_override(&"font_outline_color", Color(VOID, 0.94))
	StagingSkinType.apply_display_type(_wordmark, _title_font_size(66), IVORY, 650)
	_entry_stack.add_child(_wordmark)

	_orbit_rule = HBoxContainer.new()
	_orbit_rule.name = "OrbitRule"
	_orbit_rule.alignment = BoxContainer.ALIGNMENT_CENTER
	_orbit_rule.add_theme_constant_override(&"separation", 8)
	_entry_stack.add_child(_orbit_rule)
	_orbit_rule.add_child(_rule(Color(GOLD, 0.72)))
	var seal := TextureRect.new()
	seal.name = "LunarisSeal"
	seal.custom_minimum_size = Vector2(26.0, 26.0)
	seal.texture = StagingSkinType.LUNARIS_SEAL
	seal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	seal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_orbit_rule.add_child(seal)
	_orbit_rule.add_child(_rule(Color(MOON_CYAN, 0.72)))
	_orbit_rule.visible = false

	_start_button = _entry_button("StartButton", true)
	_start_button.pressed.connect(_on_start_pressed)
	_entry_stack.add_child(_start_button)
	_settings_button = _entry_button("SettingsButton", false)
	_settings_button.pressed.connect(_open_settings)
	_entry_stack.add_child(_settings_button)
	_wire_title_action_feedback(_start_button)
	_wire_title_action_feedback(_settings_button)
	_wire_entry_focus()


func _entry_button(node_name: String, primary: bool) -> Button:
	var button := Button.new()
	button.name = node_name
	button.custom_minimum_size = Vector2(
		_title_size(520.0 if primary else 430.0),
		_title_size(82.0 if primary else 72.0),
	)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	StagingSkinType.apply_display_type(button, _title_font_size(24 if primary else 20), IVORY, 600)
	button.add_theme_color_override(&"font_focus_color", BRIGHT_GOLD if primary else MOON_CYAN)
	button.add_theme_stylebox_override(
		&"normal",
		StagingSkinType.clean_button_style(
			Color(0.025, 0.08, 0.11, 0.96) if primary else Color(0.014, 0.035, 0.055, 0.94),
			Color(MOON_CYAN, 0.62) if primary else Color(GOLD, 0.40),
		),
	)
	button.add_theme_stylebox_override(
		&"hover",
		StagingSkinType.clean_button_style(
			Color(MOON_CYAN, 0.24) if primary else Color(GOLD, 0.16),
			Color(MOON_CYAN, 0.90) if primary else Color(BRIGHT_GOLD, 0.74),
		),
	)
	button.add_theme_stylebox_override(
		&"pressed",
		StagingSkinType.clean_button_style(
			Color(MOON_CYAN, 0.34) if primary else Color(GOLD, 0.24),
			MOON_CYAN if primary else BRIGHT_GOLD,
		),
	)
	_register_focus_pulse(button, BRIGHT_GOLD if primary else MOON_CYAN)
	return button


func _register_focus_pulse(button: Button, accent: Color) -> void:
	var style := StagingSkinType.transparent_focus_style(accent)
	button.add_theme_stylebox_override(&"focus", style)
	_focus_pulse_styles[button] = style
	_focus_pulse_colors[button] = accent


func _wire_entry_focus() -> void:
	var actions: Array[Control] = [_start_button, _settings_button]
	for index: int in actions.size():
		var current := actions[index]
		var previous := actions[(index - 1 + actions.size()) % actions.size()]
		var following := actions[(index + 1) % actions.size()]
		current.focus_neighbor_top = current.get_path_to(previous)
		current.focus_previous = current.get_path_to(previous)
		current.focus_neighbor_bottom = current.get_path_to(following)
		current.focus_next = current.get_path_to(following)
		current.focus_entered.connect(_on_title_action_focused.bind(current))


func _on_title_action_focused(action: Control) -> void:
	if _title_focus_scroll_ready and _entry_scroll != null:
		_entry_scroll.ensure_control_visible.call_deferred(action)


func _begin_title_reveal() -> void:
	var reveal_nodes: Array[CanvasItem] = [
		_wordmark, _orbit_rule, _start_button, _settings_button,
	]
	_interaction_feedback_ready = false
	_title_focus_scroll_ready = false
	if _entry_tween != null and _entry_tween.is_valid():
		_entry_tween.kill()
	for item: CanvasItem in reveal_nodes:
		item.modulate.a = 1.0 if _reduced_motion else 0.0
	if _reduced_motion:
		_finish_title_reveal()
		return
	_entry_tween = create_tween().set_parallel(true)
	_entry_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for index: int in reveal_nodes.size():
		_entry_tween.tween_property(reveal_nodes[index], "modulate:a", 1.0, ENTRY_FADE_SECONDS).set_delay(float(index) * ENTRY_STAGGER_SECONDS)
	_entry_tween.chain().tween_callback(_finish_title_reveal)


func _finish_title_reveal() -> void:
	for item: CanvasItem in [_wordmark, _orbit_rule, _start_button, _settings_button]:
		if item != null:
			item.modulate.a = 1.0
	_reset_title_scroll.call_deferred()
	_interaction_feedback_ready = true


func _reset_title_scroll() -> void:
	if _entry_scroll != null:
		_entry_scroll.scroll_vertical = 0
	_title_focus_scroll_ready = true


func _wire_title_action_feedback(button: Button) -> void:
	button.set_meta(&"sfx_hover_disabled", true)
	_highlighted_actions[button] = false
	button.resized.connect(_center_action_pivot.bind(button))
	button.mouse_entered.connect(_on_title_action_hover_changed.bind(button, true))
	button.mouse_exited.connect(_on_title_action_hover_changed.bind(button, false))
	_center_action_pivot.call_deferred(button)


func _center_action_pivot(button: Button) -> void:
	if button != null and is_instance_valid(button):
		button.pivot_offset = button.size * 0.5


func _on_title_action_hover_changed(button: Button, highlighted: bool) -> void:
	if _screen_state != ScreenState.TITLE or button == null or not is_instance_valid(button):
		return
	if bool(_highlighted_actions.get(button, false)) == highlighted:
		return
	_highlighted_actions[button] = highlighted
	if highlighted and _interaction_feedback_ready:
		Sfx.play("ui_hover")
	_animate_action_scale(button, HOVER_SCALE if highlighted else Vector2.ONE)


func _animate_action_scale(button: Button, target: Vector2) -> void:
	var active_value: Variant = _hover_tweens.get(button)
	if active_value is Tween and (active_value as Tween).is_valid():
		(active_value as Tween).kill()
	if _reduced_motion:
		button.scale = Vector2.ONE
		return
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", target, HOVER_TWEEN_SECONDS)
	_hover_tweens[button] = tween


func _reset_title_action_feedback() -> void:
	for button_value: Variant in _highlighted_actions.keys():
		var button := button_value as Button
		if button == null or not is_instance_valid(button):
			continue
		_highlighted_actions[button] = false
		var tween_value: Variant = _hover_tweens.get(button)
		if tween_value is Tween and (tween_value as Tween).is_valid():
			(tween_value as Tween).kill()
		button.scale = Vector2.ONE
	_hover_tweens.clear()


func _rule(color: Color) -> ColorRect:
	var rule := ColorRect.new()
	rule.custom_minimum_size = Vector2(116.0, 2.0)
	rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rule.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rule.color = color
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rule


func _on_start_pressed() -> void:
	if _screen_state != ScreenState.TITLE:
		return
	Sfx.play("ui_confirm")
	Game.start_campaign()


func _open_settings() -> void:
	if _screen_state != ScreenState.TITLE:
		return
	var return_focus := get_viewport().gui_get_focus_owner()
	if return_focus == null or not _entry_host.is_ancestor_of(return_focus):
		return_focus = _settings_button
	_settings_snapshot = _current_preferences()
	_settings_snapshot[&"return_focus"] = return_focus
	_screen_state = ScreenState.SETTINGS
	Sfx.play("menu_open")
	_reset_title_action_feedback()
	_set_title_interaction_enabled(false)
	_entry_host.visible = false
	_settings_state.open(_settings_snapshot)


func _close_settings() -> void:
	_cancel_settings()


func _cancel_settings() -> void:
	if _screen_state != ScreenState.SETTINGS or _settings_state.transition_state_name() != &"ACTIVE":
		return
	var snapshot := _settings_snapshot.duplicate(true)
	_settings_snapshot[&"closing_return_focus"] = snapshot.get(&"return_focus") as Control
	if not _settings_state.close():
		return
	_restore_snapshot(snapshot)
	Sfx.play("menu_close")


func _apply_settings(draft: Dictionary) -> void:
	if _screen_state != ScreenState.SETTINGS:
		return
	_screen_state = ScreenState.COMMITTING
	_settings_state.set_committing(true)
	if not ViewPreferencesType.save_batch(draft, _preferences_path):
		_screen_state = ScreenState.SETTINGS
		_settings_state.show_save_failure()
		return
	_apply_preference_values(draft)
	Sfx.play("ui_confirm")
	_settings_snapshot[&"closing_return_focus"] = _settings_snapshot.get(&"return_focus") as Control
	_screen_state = ScreenState.SETTINGS
	_settings_state.close()


func _preview_settings(draft: Dictionary) -> void:
	if _screen_state != ScreenState.SETTINGS:
		return
	_apply_preference_values(draft)


func _restore_snapshot(snapshot: Dictionary) -> void:
	_apply_preference_values(snapshot)


func _apply_preference_values(values: Dictionary) -> void:
	var locale_id := StringName(values.get(&"locale", I18n.locale()))
	if I18n.locale() != locale_id:
		I18n.set_locale(locale_id)
	_reduced_motion = bool(values.get(&"reduced_motion", _reduced_motion))
	_frame_limit = int(values.get(&"frame_limit", _frame_limit))
	_master_volume = float(values.get(&"master_volume", _master_volume))
	_music_volume = float(values.get(&"music_volume", _music_volume))
	_sfx_volume = float(values.get(&"sfx_volume", _sfx_volume))
	var previous_music_enabled := _title_music_enabled
	_title_music_enabled = bool(values.get(&"title_music_enabled", _title_music_enabled))
	_apply_graphics_settings()
	_apply_audio_settings()
	_backdrop.set_reduced_motion(_reduced_motion)
	_settings_state.set_reduced_motion(_reduced_motion)
	Music.set_enabled(_title_music_enabled)
	if _title_music_enabled and (not previous_music_enabled or Music.current_id() != &"title_lunaris"):
		Music.play_cue(&"title_lunaris")
	if _reduced_motion:
		_reset_title_action_feedback()
	_refresh_copy()


func _on_settings_close_completed() -> void:
	if _screen_state != ScreenState.SETTINGS:
		return
	var return_focus := _settings_snapshot.get(&"closing_return_focus") as Control
	_settings_snapshot = {}
	_leave_settings(return_focus)


func _leave_settings(return_focus: Control) -> void:
	_screen_state = ScreenState.TITLE
	_entry_host.visible = true
	_set_title_interaction_enabled(true)
	var target := return_focus
	if target == null or not is_instance_valid(target) or not target.is_visible_in_tree() or target.focus_mode == Control.FOCUS_NONE:
		target = _settings_button
	target.grab_focus()


func _set_title_interaction_enabled(enabled: bool) -> void:
	_entry_host.mouse_filter = Control.MOUSE_FILTER_PASS if enabled else Control.MOUSE_FILTER_IGNORE
	_start_button.disabled = not enabled
	_settings_button.disabled = not enabled
	_start_button.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
	_settings_button.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE


func _current_preferences() -> Dictionary:
	return {
		&"locale": I18n.locale(),
		&"title_music_enabled": _title_music_enabled,
		&"master_volume": _master_volume,
		&"music_volume": _music_volume,
		&"sfx_volume": _sfx_volume,
		&"frame_limit": _frame_limit,
		&"reduced_motion": _reduced_motion,
	}


func set_preferences_path(path: String) -> void:
	if is_node_ready() or path.is_empty():
		return
	_preferences_path = path


func screen_state() -> StringName:
	match _screen_state:
		ScreenState.SETTINGS:
			return &"SETTINGS"
		ScreenState.COMMITTING:
			return &"COMMITTING"
		_:
			return &"TITLE"


func title_music_enabled() -> bool:
	return _title_music_enabled


func master_volume() -> float:
	return _master_volume


func music_volume() -> float:
	return _music_volume


func sfx_volume() -> float:
	return _sfx_volume


func frame_limit() -> int:
	return _frame_limit


func reduced_motion() -> bool:
	return _reduced_motion


func settings_draft() -> Dictionary:
	return _settings_state.draft()


func _apply_audio_settings() -> void:
	_set_bus_volume(MASTER_BUS, _master_volume)
	_set_bus_volume(MUSIC_BUS, _music_volume)
	_set_bus_volume(SFX_BUS, _sfx_volume)


func _set_bus_volume(bus_name: StringName, value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	AudioServer.set_bus_mute(bus_index, value <= 0.001)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(value, 0.001)))


func _apply_graphics_settings() -> void:
	Engine.max_fps = _frame_limit
	ProjectSettings.set_setting("accessibility/reduced_motion", _reduced_motion)


func _on_locale_changed(_locale_id: StringName) -> void:
	_refresh_copy()
	_apply_responsive_layout()


func _refresh_copy() -> void:
	if _wordmark == null:
		return
	_wordmark.text = UiCopyType.text(&"ui.title.full_title", "PROTOS DEFENSE").to_upper()
	_start_button.text = UiCopyType.text(&"ui.title.start", "Start").to_upper()
	_settings_button.text = UiCopyType.text(&"ui.title.settings", "Settings").to_upper()


func _apply_responsive_layout() -> void:
	if _entry_scroll == null or _entry_host == null:
		return
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	_backdrop.fit_top_cover(viewport_size)
	var portrait := viewport_size.y > viewport_size.x
	var narrow := viewport_size.x <= 520.0
	var short := viewport_size.y <= 600.0
	var horizontal_margin := 16 if narrow else (24 if portrait or short else 36)
	var vertical_margin := 12 if short else 16
	_entry_host.add_theme_constant_override(&"margin_left", horizontal_margin)
	_entry_host.add_theme_constant_override(&"margin_right", horizontal_margin)
	_entry_host.add_theme_constant_override(&"margin_top", vertical_margin)
	_entry_host.add_theme_constant_override(&"margin_bottom", vertical_margin)
	var entry_width := maxf(0.0, viewport_size.x - float(horizontal_margin * 2))
	_entry_host.custom_minimum_size = Vector2(viewport_size.x, viewport_size.y)
	_entry_stack.add_theme_constant_override(&"separation", 8)
	var wordmark_size := 26 if narrow else (18 if short else (46 if portrait else 60))
	var chinese := I18n.locale() == &"zh-CN"
	if chinese:
		wordmark_size = 16 if narrow else (18 if short else (22 if portrait else 26))
	_wordmark.autowrap_mode = TextServer.AUTOWRAP_OFF if chinese else TextServer.AUTOWRAP_WORD_SMART
	_wordmark.max_lines_visible = 1 if chinese else 2
	_wordmark.add_theme_font_size_override(&"font_size", _title_font_size(wordmark_size))
	_start_button.custom_minimum_size = Vector2(minf(entry_width, _title_size(520.0)), _title_size(82.0 if not portrait else 76.0))
	_settings_button.custom_minimum_size = Vector2(minf(entry_width * 0.88, _title_size(460.0)), _title_size(72.0 if not portrait else 68.0))


func _title_size(value: float) -> float:
	return value * TITLE_UI_SCALE


func _title_font_size(value: int) -> int:
	return roundi(float(value) * TITLE_UI_SCALE * TITLE_FONT_SCALE)
