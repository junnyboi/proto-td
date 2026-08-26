class_name StagingResourceChip
extends PanelContainer

const StagingSkinType := preload("res://scripts/ui/components/staging_skin.gd")
const UiCopyType := preload("res://scripts/ui/components/ui_copy.gd")

var resource_id: StringName = &""
var _icon: TextureRect
var _value: Label
var _plus: Label


func _init() -> void:
	custom_minimum_size = Vector2(148.0, 42.0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_HELP
	add_theme_stylebox_override(&"panel", StagingSkinType.resource_chip_style())
	_build_content()


func configure(row: Dictionary) -> void:
	resource_id = row.get(&"id", &"") as StringName
	_icon.texture = row.get(&"icon", null) as Texture2D
	_value.text = _format_value(row)
	_plus.visible = bool(row.get(&"show_plus", false))
	var resource_name := UiCopyType.text(
		row.get(&"name_key", &"") as StringName,
		String(row.get(&"name_fallback", "Resource")),
	)
	tooltip_text = "%s — %s" % [resource_name, _value.text]


func set_compact(compact: bool) -> void:
	custom_minimum_size = Vector2(108.0 if compact else 148.0, 40.0 if compact else 42.0)
	_icon.custom_minimum_size = Vector2(23.0, 23.0) if compact else Vector2(26.0, 26.0)
	StagingSkinType.apply_display_type(_value, 21 if compact else 23, StagingSkinType.IVORY, 520)
	_plus.visible = not compact
	_plus.custom_minimum_size.x = 0.0 if compact else 20.0


func _build_content() -> void:
	var margin := MarginContainer.new()
	margin.name = "ChipMargin"
	margin.add_theme_constant_override(&"margin_left", 12)
	margin.add_theme_constant_override(&"margin_top", 6)
	margin.add_theme_constant_override(&"margin_right", 8)
	margin.add_theme_constant_override(&"margin_bottom", 6)
	add_child(margin)

	var row := HBoxContainer.new()
	row.name = "ChipContent"
	row.add_theme_constant_override(&"separation", 7)
	margin.add_child(row)

	_icon = TextureRect.new()
	_icon.name = "ResourceIcon"
	_icon.custom_minimum_size = Vector2(29.0, 29.0)
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_icon)

	_value = Label.new()
	_value.name = "ResourceValue"
	_value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_value.autowrap_mode = TextServer.AUTOWRAP_OFF
	_value.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	StagingSkinType.apply_display_type(_value, 26, StagingSkinType.IVORY, 520)
	row.add_child(_value)

	_plus = Label.new()
	_plus.name = "PlusAffordance"
	_plus.text = "+"
	_plus.custom_minimum_size.x = 20.0
	_plus.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_plus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_plus.mouse_filter = Control.MOUSE_FILTER_IGNORE
	StagingSkinType.apply_display_type(_plus, 24, StagingSkinType.MUTED, 520)
	row.add_child(_plus)


func _format_value(row: Dictionary) -> String:
	var value := int(row.get(&"value", 0))
	var capacity := int(row.get(&"capacity", -1))
	if capacity > 0:
		return "%s / %s" % [_group(value), _group(capacity)]
	return _group(value)


func _group(value: int) -> String:
	var digits := str(absi(value))
	var chunks: Array[String] = []
	while digits.length() > 3:
		chunks.push_front(digits.right(3))
		digits = digits.left(digits.length() - 3)
	chunks.push_front(digits)
	return ("-" if value < 0 else "") + ",".join(chunks)
