class_name LunarisOpsStyle
extends RefCounted

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
	art.modulate = Color(0.48, 0.62, 0.72, 0.18)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(art)


static func apply_panel(panel: PanelContainer, role: StringName) -> void:
	panel.add_theme_stylebox_override(&"panel", panel_style(role))


static func panel_style(role: StringName) -> StyleBoxFlat:
	var background := GLASS
	var border := Color(GOLD.r, GOLD.g, GOLD.b, 0.46)
	var width := 1
	var margin := 18.0
	match role:
		&"screen":
			background = Color(INK.r, INK.g, INK.b, 0.93)
			border = Color(GOLD.r, GOLD.g, GOLD.b, 0.72)
			width = 2
			margin = 22.0
		&"selected":
			background = GLASS_SELECTED
			border = CYAN
			width = 2
		&"quiet":
			background = Color(GLASS_SOFT.r, GLASS_SOFT.g, GLASS_SOFT.b, 0.72)
			border = Color(CYAN.r, CYAN.g, CYAN.b, 0.24)
			margin = 14.0
		&"danger":
			background = Color(0.18, 0.06, 0.09, 0.92)
			border = DANGER
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(4)
	style.content_margin_left = margin
	style.content_margin_top = margin
	style.content_margin_right = margin
	style.content_margin_bottom = margin
	return style


static func apply_button(button: Button, role: StringName) -> void:
	var background := GLASS_SOFT
	var hover := Color(0.12, 0.25, 0.34, 0.98)
	var pressed := Color(0.08, 0.18, 0.26, 1.0)
	var border := Color(CYAN.r, CYAN.g, CYAN.b, 0.36)
	var ink := IVORY
	match role:
		&"primary":
			background = CYAN
			hover = IVORY
			pressed = GOLD
			border = CYAN
			ink = INK_DEEP
		&"selected":
			background = Color(CYAN.r, CYAN.g, CYAN.b, 0.19)
			hover = Color(CYAN.r, CYAN.g, CYAN.b, 0.28)
			pressed = Color(CYAN.r, CYAN.g, CYAN.b, 0.14)
			border = CYAN
		&"gold":
			background = Color(GOLD.r, GOLD.g, GOLD.b, 0.16)
			hover = Color(GOLD.r, GOLD.g, GOLD.b, 0.25)
			pressed = Color(GOLD.r, GOLD.g, GOLD.b, 0.11)
			border = GOLD
		&"disabled":
			background = Color(0.12, 0.16, 0.2, 0.78)
			hover = background
			pressed = background
			border = Color(0.4, 0.46, 0.52, 0.28)
			ink = Color(MUTED.r, MUTED.g, MUTED.b, 0.56)
	button.add_theme_stylebox_override(&"normal", _button_box(background, border, 1))
	button.add_theme_stylebox_override(&"hover", _button_box(hover, border, 2))
	button.add_theme_stylebox_override(&"pressed", _button_box(pressed, border, 2))
	button.add_theme_stylebox_override(&"focus", _button_box(Color(0, 0, 0, 0), GOLD, 3))
	button.add_theme_stylebox_override(&"disabled", _button_box(background, border, 1))
	var presentation := button.get_node_or_null("PresentationLabel") as Label
	if presentation != null:
		var transparent := Color(0, 0, 0, 0)
		for item: StringName in [
			&"font_color", &"font_hover_color", &"font_pressed_color",
			&"font_hover_pressed_color", &"font_focus_color", &"font_disabled_color",
		]:
			button.add_theme_color_override(item, transparent)
		presentation.add_theme_color_override(&"font_color", ink)
		presentation.add_theme_font_size_override(&"font_size", 20)
	else:
		for item: StringName in [
			&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color",
		]:
			button.add_theme_color_override(item, ink)
		button.add_theme_color_override(&"font_disabled_color", ink)


static func apply_label(label: Label, role: StringName) -> void:
	var color := IVORY
	var size := 18
	match role:
		&"eyebrow":
			color = GOLD
			size = 15
		&"title":
			color = IVORY
			size = 38
		&"heading":
			color = GOLD
			size = 22
		&"body":
			color = IVORY
			size = 18
		&"detail":
			color = MUTED
			size = 15
		&"metric":
			color = CYAN
			size = 22
	label.add_theme_color_override(&"font_color", color)
	label.add_theme_font_size_override(&"font_size", size)
	label.add_theme_constant_override(&"outline_size", 0)


static func apply_line_edit(field: LineEdit, invalid: bool = false) -> void:
	var border := DANGER if invalid else Color(CYAN.r, CYAN.g, CYAN.b, 0.52)
	field.add_theme_stylebox_override(&"normal", _button_box(GLASS_SOFT, border, 1))
	field.add_theme_stylebox_override(
		&"focus", _button_box(Color(CYAN.r, CYAN.g, CYAN.b, 0.08), GOLD, 2),
	)
	field.add_theme_stylebox_override(
		&"read_only", _button_box(Color(0.12, 0.16, 0.2, 0.78), GOLD_DIM, 1),
	)
	field.add_theme_color_override(&"font_color", IVORY)
	field.add_theme_color_override(&"font_selected_color", INK_DEEP)
	field.add_theme_color_override(&"font_uneditable_color", MUTED)
	field.add_theme_color_override(&"caret_color", GOLD)
	field.add_theme_color_override(&"selection_color", CYAN_DIM)
	field.add_theme_color_override(&"placeholder_color", MUTED)
	field.add_theme_font_size_override(&"font_size", 18)


static func apply_progress(progress: ProgressBar) -> void:
	progress.add_theme_stylebox_override(
		&"background", _progress_box(Color(0.22, 0.3, 0.36, 0.64)),
	)
	progress.add_theme_stylebox_override(&"fill", _progress_box(CYAN))


static func _button_box(background: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(4)
	style.content_margin_left = 18.0
	style.content_margin_top = 10.0
	style.content_margin_right = 18.0
	style.content_margin_bottom = 10.0
	return style


static func _progress_box(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(2)
	return style
