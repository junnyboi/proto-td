class_name StagingCommandTile
extends Button

const GameTypographyType := preload("res://scripts/ui/game_typography.gd")
const StagingGlyphType := preload("res://scripts/ui/components/staging_glyph.gd")

const GOLD := Color("d8b978")
const MOON_CYAN := Color("86cbd4")
const IVORY := Color("eee8dc")
const MUTED := Color("93a4ad")
const VOID := Color("071019")
const PANEL := Color(0.018, 0.043, 0.065, 0.94)
const PANEL_HOVER := Color(0.035, 0.082, 0.11, 0.97)

var _glyph: StagingGlyphType
var _title_label: Label
var _status_indicator: ColorRect


func _init() -> void:
	custom_minimum_size = Vector2(180.0, 68.0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_build_content()


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
	_glyph.kind = glyph_kind
	_glyph.line_color = GOLD if enabled else MUTED
	_title_label.text = title_text.to_upper()
	_title_label.add_theme_color_override(&"font_color", IVORY if enabled else MUTED)
	_status_indicator.color = MOON_CYAN if enabled else Color(MUTED, 0.34)
	_apply_styles()


func set_compact(compact: bool) -> void:
	custom_minimum_size.y = 60.0 if compact else 68.0
	_title_label.add_theme_font_size_override(
		&"font_size", GameTypographyType.DETAIL if compact else GameTypographyType.BODY,
	)


func _build_content() -> void:
	var transparent := Color(0.0, 0.0, 0.0, 0.0)
	for color_name: StringName in [
		&"font_color", &"font_hover_color", &"font_pressed_color",
		&"font_hover_pressed_color", &"font_focus_color", &"font_disabled_color",
	]:
		add_theme_color_override(color_name, transparent)

	var margin := MarginContainer.new()
	margin.name = "TileMargin"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override(&"margin_left", 16)
	margin.add_theme_constant_override(&"margin_top", 10)
	margin.add_theme_constant_override(&"margin_right", 14)
	margin.add_theme_constant_override(&"margin_bottom", 10)
	add_child(margin)

	var row := HBoxContainer.new()
	row.name = "TileContent"
	row.add_theme_constant_override(&"separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)

	_glyph = StagingGlyphType.new()
	_glyph.name = "Glyph"
	_glyph.custom_minimum_size = Vector2(34.0, 34.0)
	_glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_glyph)

	var rule := ColorRect.new()
	rule.name = "Rule"
	rule.custom_minimum_size = Vector2(1.0, 26.0)
	rule.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rule.color = Color(GOLD, 0.34)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(rule)

	_title_label = Label.new()
	_title_label.name = "Title"
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_title_label.add_theme_font_size_override(&"font_size", GameTypographyType.BODY)
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_title_label)

	_status_indicator = ColorRect.new()
	_status_indicator.name = "StatusIndicator"
	_status_indicator.custom_minimum_size = Vector2(8.0, 8.0)
	_status_indicator.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_status_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_status_indicator)


func _apply_styles() -> void:
	if disabled:
		add_theme_stylebox_override(&"normal", _style(Color(PANEL, 0.58), Color(MUTED, 0.32), 1))
		add_theme_stylebox_override(&"disabled", _style(Color(PANEL, 0.58), Color(MUTED, 0.32), 1))
	else:
		add_theme_stylebox_override(&"normal", _style(PANEL, Color(GOLD, 0.42), 1))
		add_theme_stylebox_override(&"hover", _style(PANEL_HOVER, MOON_CYAN, 1))
		add_theme_stylebox_override(&"pressed", _style(Color("143343"), GOLD, 2))
	add_theme_stylebox_override(&"focus", _style(Color(MOON_CYAN, 0.08), GOLD, 2))


func _style(fill: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(3)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.34)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0.0, 2.0)
	return style
