extends Control

## Premium Lunaris player entry. The screen intentionally exposes only the
## PROTOS DEFENSE wordmark, Start, and Settings over the animated background.

const LOCALE_SCENE := preload("res://scenes/ui/components/aetheria_locale_selector.tscn")
const AetheriaLocaleSelectorType := preload(
	"res://scripts/ui/components/aetheria_locale_selector.gd"
)
const LunarisBackdropType := preload(
	"res://scripts/ui/components/lunaris_animated_backdrop.gd"
)
const StagingSkinType := preload("res://scripts/ui/components/staging_skin.gd")
const MusicPackStatusType := preload("res://scripts/ui/components/music_pack_status.gd")
const UiCopyType := preload("res://scripts/ui/components/ui_copy.gd")
const ViewPreferencesType := preload("res://scripts/view/view_preferences.gd")
const STAGING_THEME := preload("res://data/presentation/ui/threshold_theme.tres")

const GOLD := Color("d8b978")
const BRIGHT_GOLD := Color("f0d89a")
const MOON_CYAN := Color("91eaf1")
const IVORY := Color("f5efe1")
const MUTED := Color("aebfd0")
const VOID := Color("071019")
const FOCUS_PULSE_SECONDS := 2.8
const FOCUS_PULSE_MIN_ALPHA := 0.12
const FOCUS_PULSE_MAX_ALPHA := 0.30
const TITLE_UI_SCALE := 1.15

var _backdrop: LunarisBackdropType = null
var _entry_host: MarginContainer = null
var _entry_stack: VBoxContainer = null
var _wordmark: Label = null
var _start_button: Button = null
var _settings_button: Button = null
var _music_pack_status: MusicPackStatusType = null
var _settings_overlay: Control = null
var _settings_panel: PanelContainer = null
var _settings_title: Label = null
var _locale_selector: AetheriaLocaleSelectorType = null
var _music_button: Button = null
var _motion_button: Button = null
var _settings_back: Button = null
var _title_music_enabled := true
var _reduced_motion := false
var _preferences_path := ViewPreferencesType.DEFAULT_PATH
var _focus_pulse_elapsed := 0.0
var _focus_pulse_styles: Dictionary = {}
var _focus_pulse_colors: Dictionary = {}


func _ready() -> void:
	theme = STAGING_THEME
	_title_music_enabled = ViewPreferencesType.title_music_enabled(_preferences_path)
	_reduced_motion = bool(ProjectSettings.get_setting("accessibility/reduced_motion", false))
	_build_screen()
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_refresh_copy()
	_apply_responsive_layout()
	_start_button.grab_focus.call_deferred()
	Game.content = self
	if _music_pack_status.act() > 0:
		Music.prefetch_content_pack.call_deferred(_music_pack_status.act())
	if _title_music_enabled:
		Music.play_cue(&"title_lunaris")


func _exit_tree() -> void:
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
	if event.is_action_pressed("ui_cancel") and _settings_overlay.visible:
		get_viewport().set_input_as_handled()
		_close_settings()


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

	_entry_host = MarginContainer.new()
	_entry_host.name = "EntryControls"
	add_child(_entry_host)

	_entry_stack = VBoxContainer.new()
	_entry_stack.name = "EntryStack"
	_entry_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	_entry_stack.add_theme_constant_override(&"separation", 12)
	_entry_host.add_child(_entry_stack)

	_wordmark = Label.new()
	_wordmark.name = "Wordmark"
	_wordmark.text = "PROTOS DEFENSE"
	_wordmark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wordmark.add_theme_constant_override(&"outline_size", 12)
	_wordmark.add_theme_color_override(&"font_outline_color", Color(VOID, 0.94))
	StagingSkinType.apply_display_type(_wordmark, _title_font_size(66), IVORY, 650)
	_entry_stack.add_child(_wordmark)

	var orbit_rule := HBoxContainer.new()
	orbit_rule.name = "OrbitRule"
	orbit_rule.alignment = BoxContainer.ALIGNMENT_CENTER
	orbit_rule.add_theme_constant_override(&"separation", 8)
	_entry_stack.add_child(orbit_rule)
	orbit_rule.add_child(_rule(Color(GOLD, 0.72)))
	var seal := TextureRect.new()
	seal.name = "LunarisSeal"
	seal.custom_minimum_size = Vector2(26.0, 26.0)
	seal.texture = StagingSkinType.LUNARIS_SEAL
	seal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	seal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	orbit_rule.add_child(seal)
	orbit_rule.add_child(_rule(Color(MOON_CYAN, 0.72)))

	_start_button = _entry_button("StartButton", true)
	_start_button.pressed.connect(_on_start_pressed)
	_entry_stack.add_child(_start_button)

	_settings_button = _entry_button("SettingsButton", false)
	_settings_button.pressed.connect(_open_settings)
	_entry_stack.add_child(_settings_button)

	_music_pack_status = MusicPackStatusType.new()
	_music_pack_status.set_ui_scale(TITLE_UI_SCALE)
	_music_pack_status.set_act(Music.active_content_pack_act(1))
	_music_pack_status.retry_requested.connect(_on_music_pack_retry_requested)
	_music_pack_status.retry_availability_changed.connect(_on_music_pack_retry_availability_changed)
	_music_pack_status.visibility_changed.connect(_on_music_pack_visibility_changed)
	_entry_stack.add_child(_music_pack_status)
	_wire_entry_focus()

	_build_settings_overlay()


func _build_settings_overlay() -> void:
	_settings_overlay = Control.new()
	_settings_overlay.name = "SettingsOverlay"
	_settings_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_settings_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_settings_overlay)

	var veil := ColorRect.new()
	veil.name = "SettingsVeil"
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(VOID, 0.72)
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	_settings_overlay.add_child(veil)

	_settings_panel = PanelContainer.new()
	_settings_panel.name = "SettingsPanel"
	_settings_panel.add_theme_stylebox_override(&"panel", StagingSkinType.command_deck_style())
	_settings_overlay.add_child(_settings_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override(&"margin_left", 46)
	margin.add_theme_constant_override(&"margin_top", 34)
	margin.add_theme_constant_override(&"margin_right", 46)
	margin.add_theme_constant_override(&"margin_bottom", 38)
	_settings_panel.add_child(margin)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override(&"separation", 14)
	margin.add_child(stack)

	_settings_title = Label.new()
	_settings_title.name = "SettingsTitle"
	_settings_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	StagingSkinType.apply_display_type(_settings_title, _title_font_size(36), IVORY, 620)
	stack.add_child(_settings_title)
	stack.add_child(_rule(Color(MOON_CYAN, 0.68)))

	_locale_selector = LOCALE_SCENE.instantiate() as AetheriaLocaleSelectorType
	_locale_selector.name = "LocaleSelector"
	_locale_selector.locale_selected.connect(_on_locale_selected)
	_locale_selector.set_vertical_layout(false)
	stack.add_child(_locale_selector)
	var locale_label := _locale_selector.get_node("LocaleLabel") as Label
	StagingSkinType.apply_display_type(locale_label, _title_font_size(17), GOLD, 560)
	var locale_list := _locale_selector.get_node("LocaleList") as ItemList
	locale_list.custom_minimum_size = Vector2(0.0, _title_size(60.0))
	StagingSkinType.apply_display_type(locale_list, _title_font_size(20), IVORY, 560)

	_music_button = _settings_action("MusicButton")
	_music_button.pressed.connect(_toggle_music)
	stack.add_child(_music_button)
	_motion_button = _settings_action("MotionButton")
	_motion_button.pressed.connect(_toggle_reduced_motion)
	stack.add_child(_motion_button)
	_settings_back = _settings_action("SettingsBackButton")
	_settings_back.pressed.connect(_close_settings)
	stack.add_child(_settings_back)

	_settings_overlay.visible = false


func _entry_button(node_name: String, primary: bool) -> Button:
	var button := Button.new()
	button.name = node_name
	button.custom_minimum_size = Vector2(
		_title_size(520.0 if primary else 430.0),
		_title_size(68.0 if primary else 58.0),
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


func _settings_action(node_name: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.custom_minimum_size = Vector2(0.0, _title_size(54.0))
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	StagingSkinType.apply_display_type(button, _title_font_size(17), IVORY, 560)
	button.add_theme_color_override(&"font_focus_color", MOON_CYAN)
	button.add_theme_stylebox_override(
		&"normal",
		StagingSkinType.clean_button_style(Color(0.014, 0.035, 0.055, 0.96), Color(MOON_CYAN, 0.34)),
	)
	button.add_theme_stylebox_override(
		&"hover",
		StagingSkinType.clean_button_style(Color(MOON_CYAN, 0.16), Color(MOON_CYAN, 0.72)),
	)
	button.add_theme_stylebox_override(
		&"pressed",
		StagingSkinType.clean_button_style(Color(MOON_CYAN, 0.26), MOON_CYAN),
	)
	_register_focus_pulse(button, MOON_CYAN)
	return button


func _register_focus_pulse(button: Button, accent: Color) -> void:
	var style := StagingSkinType.transparent_focus_style(accent)
	button.add_theme_stylebox_override(&"focus", style)
	_focus_pulse_styles[button] = style
	_focus_pulse_colors[button] = accent


func _wire_entry_focus() -> void:
	if _start_button == null or _settings_button == null:
		return
	var actions: Array[Control] = [_start_button, _settings_button]
	var retry := _music_pack_status.retry_button() if _music_pack_status != null else null
	if _music_pack_status != null and _music_pack_status.visible and retry != null and retry.visible:
		actions.append(retry)
	for index: int in actions.size():
		var current := actions[index]
		var previous := actions[(index - 1 + actions.size()) % actions.size()]
		var following := actions[(index + 1) % actions.size()]
		current.focus_neighbor_top = current.get_path_to(previous)
		current.focus_previous = current.get_path_to(previous)
		current.focus_neighbor_bottom = current.get_path_to(following)
		current.focus_next = current.get_path_to(following)


func _on_music_pack_visibility_changed() -> void:
	if not is_node_ready():
		return
	var retry := _music_pack_status.retry_button()
	if not _music_pack_status.visible and get_viewport().gui_get_focus_owner() == retry:
		_start_button.grab_focus.call_deferred()
	_wire_entry_focus()
	_apply_responsive_layout()


func _on_music_pack_retry_requested(_act: int) -> void:
	Sfx.play("ui_click")


func _on_music_pack_retry_availability_changed(_available: bool) -> void:
	if not is_node_ready():
		return
	_wire_entry_focus()


func _rule(color: Color) -> ColorRect:
	var rule := ColorRect.new()
	rule.custom_minimum_size = Vector2(116.0, 2.0)
	rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rule.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rule.color = color
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rule


func _title_size(value: float) -> float:
	return value * TITLE_UI_SCALE


func _title_font_size(value: int) -> int:
	return roundi(float(value) * TITLE_UI_SCALE)


func _on_start_pressed() -> void:
	Sfx.play("ui_click")
	Game.start_campaign()


func _open_settings() -> void:
	Sfx.play("ui_click")
	_entry_host.visible = false
	_settings_overlay.visible = true
	_settings_back.grab_focus.call_deferred()


func _close_settings() -> void:
	Sfx.play("ui_back")
	_settings_overlay.visible = false
	_entry_host.visible = true
	_settings_button.grab_focus.call_deferred()


func _toggle_music() -> void:
	_title_music_enabled = not _title_music_enabled
	ViewPreferencesType.set_title_music_enabled(_title_music_enabled, _preferences_path)
	if _title_music_enabled:
		Music.play_cue(&"title_lunaris")
	else:
		Music.stop()
	_refresh_copy()


func set_preferences_path(path: String) -> void:
	if is_node_ready() or path.is_empty():
		return
	_preferences_path = path


func title_music_enabled() -> bool:
	return _title_music_enabled


func _toggle_reduced_motion() -> void:
	_reduced_motion = not _reduced_motion
	ProjectSettings.set_setting("accessibility/reduced_motion", _reduced_motion)
	_backdrop.set_reduced_motion(_reduced_motion)
	_refresh_copy()


func _on_locale_selected(_locale_id: StringName) -> void:
	_refresh_copy()


func _refresh_copy() -> void:
	_wordmark.text = UiCopyType.text(&"ui.title.full_title", "PROTOS DEFENSE").to_upper()
	_start_button.text = UiCopyType.text(&"ui.title.start", "Start").to_upper()
	_settings_button.text = UiCopyType.text(&"ui.title.settings", "Settings").to_upper()
	_settings_title.text = UiCopyType.text(&"ui.title.settings", "Settings").to_upper()
	_music_button.text = UiCopyType.format_text(
		&"ui.title.music_state", "TITLE MUSIC  //  {state}",
		{&"state": UiCopyType.text(&"ui.common.on" if _title_music_enabled else &"ui.common.off", "On" if _title_music_enabled else "Off")},
	).to_upper()
	_motion_button.text = UiCopyType.format_text(
		&"ui.title.motion_state", "ANIMATED BACKGROUND  //  {state}",
		{&"state": UiCopyType.text(&"ui.common.off" if _reduced_motion else &"ui.common.on", "Off" if _reduced_motion else "On")},
	).to_upper()
	_settings_back.text = UiCopyType.text(&"ui.common.back", "Back").to_upper()


func _apply_responsive_layout() -> void:
	if _entry_host == null or _settings_panel == null:
		return
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	_backdrop.fit_top_cover(viewport_size)
	var portrait := viewport_size.y > viewport_size.x
	var entry_width := minf(
		viewport_size.x - 48.0,
		_title_size(660.0 if not portrait else 520.0),
	)
	var status_extra := _title_size(60.0) if _music_pack_status.visible else 0.0
	var entry_height := _title_size(300.0 if not portrait else 276.0) + status_extra
	var entry_top := minf(viewport_size.y - entry_height - 28.0, viewport_size.y * (0.58 if not portrait else 0.66))
	_entry_host.position = Vector2((viewport_size.x - entry_width) * 0.5, maxf(24.0, entry_top))
	_entry_host.size = Vector2(entry_width, entry_height)
	_wordmark.add_theme_font_size_override(&"font_size", _title_font_size(66 if not portrait else 46))
	_start_button.custom_minimum_size = Vector2(
		minf(entry_width, _title_size(520.0)),
		_title_size(68.0 if not portrait else 60.0),
	)
	_settings_button.custom_minimum_size = Vector2(
		minf(entry_width * 0.82, _title_size(430.0)),
		_title_size(58.0 if not portrait else 54.0),
	)
	_music_pack_status.set_compact(portrait or viewport_size.x < 720.0)

	var panel_width := minf(viewport_size.x - 40.0, 640.0)
	var panel_height := minf(viewport_size.y - 56.0, 560.0)
	_settings_panel.position = Vector2((viewport_size.x - panel_width) * 0.5, (viewport_size.y - panel_height) * 0.5)
	_settings_panel.size = Vector2(panel_width, panel_height)
	_settings_title.add_theme_font_size_override(&"font_size", _title_font_size(36 if not portrait else 30))
