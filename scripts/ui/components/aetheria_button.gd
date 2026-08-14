class_name AetheriaButton
extends Button

const AetheriaLabelType := preload("res://scripts/ui/components/aetheria_label.gd")

const ROLE_VARIATIONS := {
	&"primary": &"AuiPrimaryButton",
	&"secondary": &"AuiSecondaryButton",
	&"selected": &"AuiSelectedButton",
	&"destructive": &"AuiDestructiveButton",
	&"disabled": &"AuiDisabledButton",
}

@export var role: StringName:
	get:
		return _role
	set(value):
		apply_role(value)

var _role: StringName = &"secondary"


func _init() -> void:
	custom_minimum_size = Vector2(44.0, 52.0)
	focus_mode = Control.FOCUS_ALL
	apply_role(&"secondary")


func _get_minimum_size() -> Vector2:
	return custom_minimum_size


func apply_role(value: StringName) -> bool:
	if not ROLE_VARIATIONS.has(value):
		return false
	_role = value
	theme_type_variation = ROLE_VARIATIONS[value]
	return true


func set_presentation_text(logical_text: String, rendered_text: String) -> bool:
	if logical_text.is_empty() or rendered_text.is_empty():
		return false
	text = logical_text
	autowrap_mode = TextServer.AUTOWRAP_OFF
	clip_text = true
	var transparent := Color(0.0, 0.0, 0.0, 0.0)
	for color_name: StringName in [
		&"font_color", &"font_hover_color", &"font_pressed_color",
		&"font_hover_pressed_color", &"font_focus_color", &"font_disabled_color",
	]:
		add_theme_color_override(color_name, transparent)
	var label := get_node_or_null("PresentationLabel") as AetheriaLabelType
	if label == null:
		label = AetheriaLabelType.new()
		label.name = "PresentationLabel"
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.clip_text = true
		label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.apply_role(&"body")
		add_child(label)
	label.text = rendered_text
	return true
