class_name SelectedSquadChip
extends Button

signal reorder_requested(source_hero_id: StringName, target_hero_id: StringName)
signal move_requested(hero_id: StringName, direction: int)

const Style := preload("res://scripts/ui/components/lunaris_ops_style.gd")

var hero_id: StringName = &""
var position_index := 0


func _init() -> void:
	name = "SelectedSquadChip"
	custom_minimum_size = Vector2(178.0, 58.0)
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_DRAG
	_apply_readable_style()


func configure(id: StringName, callsign: String, index: int, drag_hint: String) -> void:
	hero_id = id
	position_index = index
	name = "SelectedSquad_%s" % hero_id
	text = "%d  %s" % [position_index + 1, callsign.to_upper()]
	tooltip_text = drag_hint
	accessibility_name = text
	accessibility_description = drag_hint
	set_meta(&"hero_id", hero_id)
	set_meta(&"position_index", position_index)


func _get_drag_data(_at_position: Vector2) -> Variant:
	if hero_id == &"":
		return null
	var preview := Label.new()
	preview.text = text
	preview.custom_minimum_size = Vector2(178.0, 52.0)
	preview.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	preview.add_theme_font_size_override(&"font_size", 22)
	preview.add_theme_color_override(&"font_color", Style.IVORY)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(&"panel", Style.panel_style(&"selected"))
	panel.add_child(preview)
	set_drag_preview(panel)
	return {
		"type": &"selected_squad_operator",
		"hero_id": hero_id,
	}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return (
		typeof(data) == TYPE_DICTIONARY
		and StringName((data as Dictionary).get("type", &"")) == &"selected_squad_operator"
		and StringName((data as Dictionary).get("hero_id", &"")) != &""
		and StringName((data as Dictionary).get("hero_id", &"")) != hero_id
	)


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(Vector2.ZERO, data):
		return
	reorder_requested.emit(
		StringName((data as Dictionary)["hero_id"]),
		hero_id,
	)


func _gui_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or not key.alt_pressed:
		return
	if key.keycode == KEY_LEFT or key.keycode == KEY_UP:
		move_requested.emit(hero_id, -1)
		accept_event()
	elif key.keycode == KEY_RIGHT or key.keycode == KEY_DOWN:
		move_requested.emit(hero_id, 1)
		accept_event()


func _apply_readable_style() -> void:
	var normal := _flat_style(Color(0.045, 0.12, 0.16, 0.98), Style.GOLD, 1)
	var hover := _flat_style(Color(0.065, 0.19, 0.22, 1.0), Style.CYAN, 2)
	var pressed := _flat_style(Color(0.025, 0.08, 0.11, 1.0), Style.GOLD, 2)
	add_theme_stylebox_override(&"normal", normal)
	add_theme_stylebox_override(&"hover", hover)
	add_theme_stylebox_override(&"focus", hover)
	add_theme_stylebox_override(&"pressed", pressed)
	add_theme_stylebox_override(&"hover_pressed", pressed)
	add_theme_font_size_override(&"font_size", 20)
	add_theme_color_override(&"font_color", Style.IVORY)
	add_theme_color_override(&"font_hover_color", Color.WHITE)
	add_theme_color_override(&"font_focus_color", Color.WHITE)
	add_theme_color_override(&"font_pressed_color", Style.GOLD)
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_theme_constant_override(&"outline_size", 1)


func _flat_style(background: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(10)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	return style
