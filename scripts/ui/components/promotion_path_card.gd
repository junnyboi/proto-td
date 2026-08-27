class_name PromotionPathCard
extends "res://scripts/ui/components/aetheria_button.gd"

const TrainingLabelType := preload("res://scripts/ui/components/aetheria_label.gd")
const ArtType := preload("res://scripts/view/art.gd")

const REGULAR_CARD_SIZE := Vector2(680.0, 450.0)
const PORTRAIT_CARD_SIZE := Vector2(600.0, 450.0)
const REGULAR_PORTRAIT_SIZE := Vector2(124.0, 128.0)
const PORTRAIT_PORTRAIT_SIZE := Vector2(116.0, 124.0)
const CARD_PADDING := 24
const CLASS_FONT_SIZE := 40
const ROLE_FONT_SIZE := 28
const DETAIL_FONT_SIZE := 26
const COST_FONT_SIZE := 24
const NORMAL_BACKGROUND := Color(0.018, 0.055, 0.082, 0.98)
const HOVER_BACKGROUND := Color(0.038, 0.105, 0.132, 0.99)
const SELECTED_BACKGROUND := Color(0.075, 0.155, 0.142, 1.0)
const SELECTED_HOVER_BACKGROUND := Color(0.095, 0.19, 0.17, 1.0)
const NORMAL_BORDER := Color(0.58, 0.47, 0.29, 0.78)
const HOVER_BORDER := Color(0.43, 0.91, 0.94, 0.90)
const SELECTED_BORDER := Color(0.92, 0.75, 0.36, 1.0)

var class_id := ""
var operator_def_id := ""
var portrait_asset_id: StringName = &""
var _portrait: TextureRect
var _class_name: TrainingLabelType
var _placeholder: TrainingLabelType
var _role_label: TrainingLabelType
var _description: TrainingLabelType
var _skill: TrainingLabelType
var _cost: TrainingLabelType
var _kit: TrainingLabelType
var _content: VBoxContainer


func _init() -> void:
	toggle_mode = true
	custom_minimum_size = REGULAR_CARD_SIZE
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	set_presentation_text("Advanced training path", " ")
	mouse_entered.connect(_refresh_visual_state)
	mouse_exited.connect(_refresh_visual_state)
	focus_entered.connect(_refresh_visual_state)
	focus_exited.connect(_refresh_visual_state)
	toggled.connect(_on_toggled)
	_build_content()
	_refresh_visual_state()


func configure(
		choice: Dictionary,
		class_label: String,
		role_text: String,
		description_text: String,
		skill_text: String,
		cost_text: String,
		placeholder_text: String,
		kit_text: String,
		detail_tooltip: String = "",
	) -> void:
	class_id = String(choice["to_class_id"])
	operator_def_id = String(choice["operator_def_id"])
	portrait_asset_id = StringName(choice.get("specialization_portrait_asset_id", &""))
	_class_name.text = class_label.to_upper()
	_role_label.text = role_text.to_upper()
	_description.text = description_text
	_skill.text = skill_text
	_cost.text = cost_text
	_placeholder.text = placeholder_text
	_kit.text = kit_text
	_portrait.texture = ArtType.texture(portrait_asset_id)
	text = "%s — %s — %s — %s — %s — %s — %s" % [
		_class_name.text, _role_label.text, _description.text, _skill.text, _cost.text,
		_placeholder.text, _kit.text,
	]
	tooltip_text = detail_tooltip if not detail_tooltip.is_empty() else text
	_refresh_visual_state()


func set_selected(value: bool) -> void:
	button_pressed = value
	_refresh_visual_state()


func uses_flat_color_states() -> bool:
	return (
		get_theme_stylebox(&"normal") is StyleBoxFlat
		and get_theme_stylebox(&"hover") is StyleBoxFlat
		and get_theme_stylebox(&"pressed") is StyleBoxFlat
	)


func focus_visibility_target() -> Control:
	return _class_name


func _get_minimum_size() -> Vector2:
	return custom_minimum_size


func set_compact(value: bool) -> void:
	custom_minimum_size = PORTRAIT_CARD_SIZE if value else REGULAR_CARD_SIZE
	_portrait.custom_minimum_size = PORTRAIT_PORTRAIT_SIZE if value else REGULAR_PORTRAIT_SIZE
	update_minimum_size()


func fit_to_content() -> void:
	update_minimum_size()


func _on_toggled(_pressed: bool) -> void:
	_refresh_visual_state()


func _refresh_visual_state() -> void:
	var emphasized := is_hovered() or has_focus()
	var normal_bg := SELECTED_BACKGROUND if button_pressed else NORMAL_BACKGROUND
	var hover_bg := SELECTED_HOVER_BACKGROUND if button_pressed else HOVER_BACKGROUND
	var border := SELECTED_BORDER if button_pressed else NORMAL_BORDER
	var hover_border := SELECTED_BORDER if button_pressed else HOVER_BORDER
	add_theme_stylebox_override(&"normal", _flat_style(normal_bg, border, 2))
	add_theme_stylebox_override(&"hover", _flat_style(hover_bg, hover_border, 3))
	add_theme_stylebox_override(&"focus", _flat_style(hover_bg, hover_border, 3))
	add_theme_stylebox_override(&"pressed", _flat_style(SELECTED_BACKGROUND, SELECTED_BORDER, 3))
	add_theme_stylebox_override(
		&"hover_pressed", _flat_style(SELECTED_HOVER_BACKGROUND, SELECTED_BORDER, 3),
	)
	add_theme_stylebox_override(&"disabled", _flat_style(NORMAL_BACKGROUND.darkened(0.12), NORMAL_BORDER.darkened(0.15), 2))
	modulate = Color(1.04, 1.04, 1.04, 1.0) if emphasized else Color.WHITE


func _flat_style(background: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(14)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.38)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0.0, 4.0)
	return style


func _build_content() -> void:
	var presentation := get_node("PresentationLabel") as Label
	presentation.text = " "
	var margin := MarginContainer.new()
	margin.name = "PathCardMargin"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: StringName in [&"margin_left", &"margin_top", &"margin_right", &"margin_bottom"]:
		margin.add_theme_constant_override(side, CARD_PADDING)
	add_child(margin)
	_content = VBoxContainer.new()
	_content.name = "PathCardContent"
	_content.add_theme_constant_override(&"separation", 8)
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(_content)
	var header := HBoxContainer.new()
	header.name = "PathIdentityHeader"
	header.add_theme_constant_override(&"separation", 16)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(header)
	var portrait_column := VBoxContainer.new()
	portrait_column.name = "ClassKitColumn"
	portrait_column.custom_minimum_size.x = 132.0
	portrait_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(portrait_column)
	_portrait = TextureRect.new()
	_portrait.name = "ClassKitPortrait"
	_portrait.custom_minimum_size = REGULAR_PORTRAIT_SIZE
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_column.add_child(_portrait)
	_placeholder = _label("ClassKitPlaceholder", &"dense_detail")
	_placeholder.visible = false
	_placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait_column.add_child(_placeholder)
	var identity := VBoxContainer.new()
	identity.name = "PathIdentity"
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override(&"separation", 6)
	identity.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(identity)
	_class_name = _label("AdvancedClassName", &"dense_heading")
	_role_label = _label("AdvancedRole", &"dense_detail")
	_class_name.add_theme_font_size_override(&"font_size", CLASS_FONT_SIZE)
	_role_label.add_theme_font_size_override(&"font_size", ROLE_FONT_SIZE)
	identity.add_child(_class_name)
	identity.add_child(_role_label)
	_description = _label("ClassDescription", &"dense_detail")
	_skill = _label("SkillFacts", &"dense_detail")
	_cost = _label("DeployCost", &"cost_badge")
	_kit = _label("FieldKit", &"dense_detail")
	for detail_label: TrainingLabelType in [_description, _skill, _kit]:
		detail_label.add_theme_font_size_override(&"font_size", DETAIL_FONT_SIZE)
	_cost.add_theme_font_size_override(&"font_size", COST_FONT_SIZE)
	_cost.custom_minimum_size.y = 44.0
	_cost.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_kit.custom_minimum_size.y = 38.0
	_kit.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_content.add_child(_description)
	_content.add_child(_skill)
	_content.add_child(_cost)
	_content.add_child(_kit)


func _label(node_name: String, role: StringName) -> TrainingLabelType:
	var label := TrainingLabelType.new()
	label.name = node_name
	label.apply_role(role)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	return label
