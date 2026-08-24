class_name StagingCommandTile
extends Button

const GameTypographyType := preload("res://scripts/ui/game_typography.gd")
const StagingGlyphType := preload("res://scripts/ui/components/staging_glyph.gd")
const StagingSkinType := preload("res://scripts/ui/components/staging_skin.gd")

const GOLD := Color("d9b96e")
const IVORY := Color("f5efe1")
const MUTED := Color("8d9aa3")

var _glyph: TextureRect
var _title_label: Label
var _status_indicator: TextureRect


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
	_glyph.texture = StagingSkinType.icon_for_glyph(glyph_kind)
	_glyph.modulate = Color.WHITE if enabled else Color(0.58, 0.60, 0.62, 0.74)
	_title_label.text = title_text.to_upper()
	_title_label.add_theme_color_override(&"font_color", GOLD if enabled else MUTED)
	_status_indicator.modulate = Color.WHITE if enabled else Color(0.46, 0.54, 0.58, 0.44)
	_apply_styles()


func set_compact(compact: bool) -> void:
	custom_minimum_size.y = 60.0 if compact else 68.0
	_glyph.custom_minimum_size = Vector2(38.0, 38.0) if compact else Vector2(44.0, 44.0)
	_status_indicator.custom_minimum_size = Vector2(15.0, 15.0) if compact else Vector2(18.0, 18.0)
	StagingSkinType.apply_display_type(
		_title_label,
		GameTypographyType.DETAIL if compact else GameTypographyType.BODY,
		MUTED if disabled else GOLD,
		540,
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
	margin.add_theme_constant_override(&"margin_left", 18)
	margin.add_theme_constant_override(&"margin_top", 8)
	margin.add_theme_constant_override(&"margin_right", 16)
	margin.add_theme_constant_override(&"margin_bottom", 8)
	add_child(margin)

	var row := HBoxContainer.new()
	row.name = "TileContent"
	row.add_theme_constant_override(&"separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)

	_glyph = TextureRect.new()
	_glyph.name = "Glyph"
	_glyph.custom_minimum_size = Vector2(44.0, 44.0)
	_glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_glyph.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_glyph)

	_title_label = Label.new()
	_title_label.name = "Title"
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	StagingSkinType.apply_display_type(_title_label, GameTypographyType.BODY, GOLD, 540)
	row.add_child(_title_label)

	_status_indicator = TextureRect.new()
	_status_indicator.name = "StatusIndicator"
	_status_indicator.custom_minimum_size = Vector2(18.0, 18.0)
	_status_indicator.texture = StagingSkinType.STATUS_DIAMOND
	_status_indicator.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_status_indicator.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_status_indicator.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_status_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_status_indicator)


func _apply_styles() -> void:
	if disabled:
		var disabled_tint := Color(0.56, 0.58, 0.60, 0.78)
		add_theme_stylebox_override(&"normal", StagingSkinType.operation_tile_style(disabled_tint))
		add_theme_stylebox_override(&"disabled", StagingSkinType.operation_tile_style(disabled_tint))
	else:
		add_theme_stylebox_override(&"normal", StagingSkinType.operation_tile_style())
		add_theme_stylebox_override(&"hover", StagingSkinType.operation_tile_style(Color(1.0, 1.03, 1.08, 1.0)))
		add_theme_stylebox_override(&"pressed", StagingSkinType.operation_tile_style(Color(0.76, 0.84, 0.88, 1.0)))
	add_theme_stylebox_override(&"focus", StagingSkinType.transparent_focus_style(GOLD))
