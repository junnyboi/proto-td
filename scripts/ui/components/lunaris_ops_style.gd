class_name LunarisOpsStyle
extends RefCounted

const StagingSkinType := preload("res://scripts/ui/components/staging_skin.gd")

const INK := Color("07111c")
const INK_DEEP := Color("040a12")
const GLASS := Color("0b1827e8")
const GLASS_SOFT := Color("13263bd9")
const GLASS_SELECTED := Color("173849eb")
const IVORY := Color("f5efe1")
const MUTED := Color("aebfd0")
const CYAN := Color("91eaf1")
const CYAN_DIM := Color("4f9ca8")
const GOLD := Color("d9b96e")
const GOLD_DIM := Color("79683f")
const VIOLET := Color("66577f")
const DANGER := Color("d16f78")


static func add_backdrop(root: Control, texture: Texture2D = null) -> void:
	var backdrop := ColorRect.new()
	backdrop.name = "AstralBackdrop"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = INK_DEEP
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(backdrop)
	if texture == null:
		return
	var art := TextureRect.new()
	art.name = "AstralBackdropArt"
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.texture = texture
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.modulate = Color(0.48, 0.62, 0.72, 0.24)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(art)


static func apply_panel(panel: PanelContainer, role: StringName) -> void:
	panel.add_theme_stylebox_override(&"panel", panel_style(role))


static func panel_style(role: StringName) -> StyleBox:
	if role == &"screen" or role == &"dialog":
		return _texture_margin(StagingSkinType.command_deck_style(), 22.0)
	if role == &"hud":
		return _texture_margin(StagingSkinType.command_deck_style(), 10.0)
	if role == &"workspace":
		return _flat_panel(Color(0.035, 0.075, 0.12, 0.94), Color(CYAN.r, CYAN.g, CYAN.b, 0.34), 1, 20.0)
	if role == &"result" or role == &"memorial":
		var tint := Color.WHITE if role == &"result" else Color(0.88, 0.78, 0.90, 1.0)
		return _texture_margin(StagingSkinType.mission_card_style(tint), 18.0)
	if role == &"selected":
		return _flat_panel(GLASS_SELECTED, CYAN, 2, 16.0)
	if role == &"quiet":
		return _texture_margin(StagingSkinType.operation_tile_style(Color(0.86, 0.93, 1.0, 0.92)), 14.0)
	if role == &"danger":
		return _flat_panel(Color(0.18, 0.06, 0.09, 0.94), DANGER, 2, 16.0)
	return _flat_panel(GLASS, Color(GOLD.r, GOLD.g, GOLD.b, 0.46), 1, 18.0)


static func apply_button(button: Button, role: StringName) -> void:
	var ink := IVORY
	var normal: StyleBox
	var hover: StyleBox
	var pressed: StyleBox
	var disabled: StyleBox
	match role:
		&"primary", &"gold":
			normal = _texture_margin(StagingSkinType.primary_button_style(), 10.0)
			hover = _texture_margin(StagingSkinType.primary_button_style(Color("fff2c6")), 10.0)
			pressed = _texture_margin(StagingSkinType.primary_button_style(GOLD), 10.0)
			ink = INK_DEEP if role == &"primary" else IVORY
		&"selected":
			normal = _texture_margin(StagingSkinType.operation_tile_style(Color("b9f8fb")), 10.0)
			hover = _texture_margin(StagingSkinType.operation_tile_style(Color.WHITE), 10.0)
			pressed = _texture_margin(StagingSkinType.operation_tile_style(CYAN), 10.0)
		&"disabled":
			var muted_tint := Color(0.42, 0.48, 0.55, 0.56)
			normal = _texture_margin(StagingSkinType.operation_tile_style(muted_tint), 10.0)
			hover = normal
			pressed = normal
			ink = Color(MUTED.r, MUTED.g, MUTED.b, 0.58)
		&"danger":
			normal = _button_box(Color(0.18, 0.06, 0.09, 0.96), DANGER, 1)
			hover = _button_box(Color(0.28, 0.08, 0.12, 0.98), GOLD, 2)
			pressed = _button_box(Color(0.12, 0.03, 0.06, 1.0), GOLD, 2)
		_:
			normal = _texture_margin(StagingSkinType.operation_tile_style(), 10.0)
			hover = _texture_margin(StagingSkinType.operation_tile_style(Color("b9f8fb")), 10.0)
			pressed = _texture_margin(StagingSkinType.operation_tile_style(CYAN), 10.0)
	disabled = _button_box(Color(0.10, 0.14, 0.18, 0.86), Color(0.4, 0.46, 0.52, 0.28), 1)
	button.add_theme_stylebox_override(&"normal", normal)
	button.add_theme_stylebox_override(&"hover", hover)
	button.add_theme_stylebox_override(&"pressed", pressed)
	button.add_theme_stylebox_override(&"focus", StagingSkinType.transparent_focus_style(CYAN))
	button.add_theme_stylebox_override(&"disabled", disabled)
	StagingSkinType.apply_display_type(button, 18, ink, 560)
	var presentation := button.get_node_or_null("PresentationLabel") as Label
	if presentation != null:
		var transparent := Color(0, 0, 0, 0)
		for item: StringName in [
			&"font_color", &"font_hover_color", &"font_pressed_color",
			&"font_hover_pressed_color", &"font_focus_color", &"font_disabled_color",
		]:
			button.add_theme_color_override(item, transparent)
		StagingSkinType.apply_display_type(presentation, 18, ink, 560)
	else:
		for item: StringName in [
			&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color",
		]:
			button.add_theme_color_override(item, ink)
		button.add_theme_color_override(&"font_disabled_color", ink)


static func apply_label(label: Label, role: StringName) -> void:
	var color := IVORY
	var size := 18
	var display := false
	var weight := 520
	match role:
		&"eyebrow":
			color = GOLD
			size = 14
			display = true
		&"title":
			color = IVORY
			size = 38
			display = true
			weight = 620
		&"heading":
			color = GOLD
			size = 22
			display = true
			weight = 580
		&"body":
			color = IVORY
			size = 18
		&"detail":
			color = MUTED
			size = 15
		&"metric":
			color = CYAN
			size = 21
			display = true
	if display:
		StagingSkinType.apply_display_type(label, size, color, weight)
	else:
		label.add_theme_color_override(&"font_color", color)
		label.add_theme_font_size_override(&"font_size", size)
	label.add_theme_constant_override(&"outline_size", 0)


static func apply_line_edit(field: LineEdit, invalid: bool = false) -> void:
	var border := DANGER if invalid else Color(CYAN.r, CYAN.g, CYAN.b, 0.52)
	field.add_theme_stylebox_override(&"normal", _button_box(GLASS_SOFT, border, 1))
	field.add_theme_stylebox_override(&"focus", _button_box(Color(CYAN.r, CYAN.g, CYAN.b, 0.08), GOLD, 2))
	field.add_theme_stylebox_override(&"read_only", _button_box(Color(0.12, 0.16, 0.2, 0.78), GOLD_DIM, 1))
	field.add_theme_color_override(&"font_color", IVORY)
	field.add_theme_color_override(&"font_selected_color", INK_DEEP)
	field.add_theme_color_override(&"font_uneditable_color", MUTED)
	field.add_theme_color_override(&"caret_color", GOLD)
	field.add_theme_color_override(&"selection_color", CYAN_DIM)
	field.add_theme_color_override(&"placeholder_color", MUTED)
	field.add_theme_font_size_override(&"font_size", 18)


static func apply_progress(progress: ProgressBar) -> void:
	progress.add_theme_stylebox_override(&"background", _progress_box(Color(0.22, 0.3, 0.36, 0.64)))
	progress.add_theme_stylebox_override(&"fill", _progress_box(CYAN))


static func _texture_margin(style: StyleBoxTexture, margin: float) -> StyleBoxTexture:
	style.content_margin_left = margin
	style.content_margin_top = margin
	style.content_margin_right = margin
	style.content_margin_bottom = margin
	return style


static func _flat_panel(background: Color, border: Color, width: int, margin: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(3)
	style.content_margin_left = margin
	style.content_margin_top = margin
	style.content_margin_right = margin
	style.content_margin_bottom = margin
	return style


static func _button_box(background: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(3)
	style.content_margin_left = 18.0
	style.content_margin_top = 10.0
	style.content_margin_right = 18.0
	style.content_margin_bottom = 10.0
	return style


static func _progress_box(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(1)
	return style
