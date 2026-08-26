class_name StagingCommandTile
extends Button

const GameTypographyType := preload("res://scripts/ui/game_typography.gd")
const StagingGlyphType := preload("res://scripts/ui/components/staging_glyph.gd")
const StagingSkinType := preload("res://scripts/ui/components/staging_skin.gd")

const GOLD := Color("d9b96e")
const BRIGHT_GOLD := Color("f0d89a")
const IVORY := Color("f5efe1")
const MUTED := Color("8d9aa3")
const FOCUS_PULSE_SECONDS := 2.8
const FOCUS_PULSE_MIN_ALPHA := 0.10
const FOCUS_PULSE_MAX_ALPHA := 0.26
const TILE_TITLE_FONT_SIZE := 18
const TILE_STATE_FONT_SIZE := 16
const RAIL_TITLE_FONT_SIZE := 36
const RAIL_STATE_FONT_SIZE := 32

var _glyph: TextureRect
var _title_label: Label
var _state_label: Label
var _status_indicator: TextureRect
var _margin: MarginContainer
var _row: HBoxContainer
var _focus_style: StyleBoxFlat
var _focus_pulse_elapsed := 0.0
var _reduced_motion := false


func _init() -> void:
	custom_minimum_size = Vector2(180.0, 68.0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_reduced_motion = bool(ProjectSettings.get_setting("accessibility/reduced_motion", false))
	_focus_style = StagingSkinType.transparent_focus_style(GOLD)
	add_theme_stylebox_override(&"focus", _focus_style)
	_build_content()


func _process(delta: float) -> void:
	_focus_pulse_elapsed = fmod(_focus_pulse_elapsed + delta, FOCUS_PULSE_SECONDS)
	var pulse := 0.18
	if not _reduced_motion:
		var wave := (sin((_focus_pulse_elapsed / FOCUS_PULSE_SECONDS) * TAU) + 1.0) * 0.5
		pulse = lerpf(FOCUS_PULSE_MIN_ALPHA, FOCUS_PULSE_MAX_ALPHA, wave)
	_focus_style.bg_color = Color(GOLD, pulse)
	queue_redraw()


func configure(
	glyph_kind: StagingGlyphType.Kind,
	title_text: String,
	accessible_text: String,
	enabled: bool,
) -> void:
	text = accessible_text
	tooltip_text = accessible_text
	disabled = not enabled
	focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
	mouse_default_cursor_shape = (
		Control.CURSOR_POINTING_HAND if enabled else Control.CURSOR_ARROW
	)
	_glyph.texture = StagingSkinType.icon_for_glyph(glyph_kind)
	_glyph.modulate = Color.WHITE if enabled else Color(0.58, 0.60, 0.62, 0.74)
	_title_label.text = title_text.to_upper()
	_title_label.add_theme_color_override(&"font_color", GOLD if enabled else MUTED)
	_state_label.text = _unavailable_state(accessible_text).to_upper()
	_state_label.visible = not enabled and not _state_label.text.is_empty()
	_status_indicator.modulate = Color.WHITE if enabled else Color(0.46, 0.54, 0.58, 0.44)
	_apply_styles()


func set_compact(compact: bool) -> void:
	custom_minimum_size.y = 72.0 if compact else 80.0
	_glyph.custom_minimum_size = Vector2(36.0, 36.0) if compact else Vector2(40.0, 40.0)
	_status_indicator.custom_minimum_size = Vector2(15.0, 15.0) if compact else Vector2(18.0, 18.0)
	StagingSkinType.apply_display_type(
		_title_label,
		TILE_TITLE_FONT_SIZE,
		MUTED if disabled else GOLD,
		540,
	)
	StagingSkinType.apply_display_type(_state_label, TILE_STATE_FONT_SIZE, MUTED, 520)


func set_rail_mode(rail_mode: bool) -> void:
	custom_minimum_size = Vector2(0.0, 120.0 if rail_mode else 72.0)
	_title_label.autowrap_mode = TextServer.AUTOWRAP_OFF if rail_mode else TextServer.AUTOWRAP_WORD_SMART
	_title_label.max_lines_visible = 1 if rail_mode else 2
	_margin.add_theme_constant_override(&"margin_left", 24 if rail_mode else 16)
	_margin.add_theme_constant_override(&"margin_top", 18 if rail_mode else 12)
	_margin.add_theme_constant_override(&"margin_right", 24 if rail_mode else 16)
	_margin.add_theme_constant_override(&"margin_bottom", 18 if rail_mode else 12)
	_row.add_theme_constant_override(&"separation", 14 if rail_mode else 12)
	_glyph.custom_minimum_size = Vector2(52.0, 52.0) if rail_mode else Vector2(40.0, 40.0)
	_status_indicator.custom_minimum_size = Vector2(18.0, 18.0)
	StagingSkinType.apply_display_type(
		_title_label,
		RAIL_TITLE_FONT_SIZE if rail_mode else TILE_TITLE_FONT_SIZE,
		MUTED if disabled else GOLD,
		540,
	)
	StagingSkinType.apply_display_type(
		_state_label,
		RAIL_STATE_FONT_SIZE if rail_mode else TILE_STATE_FONT_SIZE,
		MUTED,
		520,
	)


func _build_content() -> void:
	var transparent := Color(0.0, 0.0, 0.0, 0.0)
	for color_name: StringName in [
		&"font_color", &"font_hover_color", &"font_pressed_color",
		&"font_hover_pressed_color", &"font_focus_color", &"font_disabled_color",
	]:
		add_theme_color_override(color_name, transparent)

	_margin = MarginContainer.new()
	_margin.name = "TileMargin"
	_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_margin.add_theme_constant_override(&"margin_left", 16)
	_margin.add_theme_constant_override(&"margin_top", 12)
	_margin.add_theme_constant_override(&"margin_right", 16)
	_margin.add_theme_constant_override(&"margin_bottom", 12)
	add_child(_margin)

	_row = HBoxContainer.new()
	_row.name = "TileContent"
	_row.add_theme_constant_override(&"separation", 12)
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_margin.add_child(_row)

	_glyph = TextureRect.new()
	_glyph.name = "Glyph"
	_glyph.custom_minimum_size = Vector2(44.0, 44.0)
	_glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_glyph.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.add_child(_glyph)

	var copy := VBoxContainer.new()
	copy.name = "TileCopy"
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override(&"separation", 1)
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.add_child(copy)

	_title_label = Label.new()
	_title_label.name = "Title"
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_label.max_lines_visible = 2
	_title_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	StagingSkinType.apply_display_type(_title_label, GameTypographyType.BODY, GOLD, 540)
	copy.add_child(_title_label)

	_state_label = Label.new()
	_state_label.name = "State"
	_state_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_state_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	StagingSkinType.apply_display_type(_state_label, TILE_STATE_FONT_SIZE, MUTED, 520)
	copy.add_child(_state_label)

	_status_indicator = TextureRect.new()
	_status_indicator.name = "StatusIndicator"
	_status_indicator.custom_minimum_size = Vector2(18.0, 18.0)
	_status_indicator.texture = StagingSkinType.STATUS_DIAMOND
	_status_indicator.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_status_indicator.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_status_indicator.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_status_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.add_child(_status_indicator)


func _unavailable_state(accessible_text: String) -> String:
	var separator := accessible_text.find("—")
	if separator < 0:
		return ""
	return accessible_text.substr(separator + 1).strip_edges()


func _apply_styles() -> void:
	if disabled:
		var disabled_style := StagingSkinType.clean_button_style(
			Color(0.018, 0.028, 0.038, 0.78),
			Color(MUTED, 0.22),
		)
		add_theme_stylebox_override(&"normal", disabled_style)
		add_theme_stylebox_override(&"disabled", disabled_style)
	else:
		add_theme_stylebox_override(
			&"normal",
			StagingSkinType.clean_button_style(Color(0.018, 0.043, 0.065, 0.96), Color(GOLD, 0.34)),
		)
		add_theme_stylebox_override(
			&"hover",
			StagingSkinType.clean_button_style(Color(GOLD, 0.16), Color(BRIGHT_GOLD, 0.72)),
		)
		add_theme_stylebox_override(
			&"pressed",
			StagingSkinType.clean_button_style(Color(GOLD, 0.24), BRIGHT_GOLD),
		)
