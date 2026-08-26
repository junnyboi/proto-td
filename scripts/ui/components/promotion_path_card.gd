class_name PromotionPathCard
extends "res://scripts/ui/components/aetheria_button.gd"

const TrainingLabelType := preload("res://scripts/ui/components/aetheria_label.gd")
const ArtType := preload("res://scripts/view/art.gd")

const REGULAR_CARD_SIZE := Vector2(340.0, 225.0)
const PORTRAIT_CARD_SIZE := Vector2(300.0, 225.0)
const REGULAR_PORTRAIT_SIZE := Vector2(62.0, 64.0)
const PORTRAIT_PORTRAIT_SIZE := Vector2(60.0, 62.0)
const CLASS_FONT_SIZE := 20
const ROLE_FONT_SIZE := 14
const DETAIL_FONT_SIZE := 13
const COST_FONT_SIZE := 12

var class_id := ""
var operator_def_id := ""
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
	_build_content()


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
	_class_name.text = class_label.to_upper()
	_role_label.text = role_text.to_upper()
	_description.text = description_text
	_skill.text = skill_text
	_cost.text = cost_text
	_placeholder.text = placeholder_text
	_kit.text = kit_text
	_portrait.texture = ArtType.texture(StringName("portrait_%s" % operator_def_id))
	text = "%s — %s — %s — %s — %s — %s — %s" % [
		_class_name.text, _role_label.text, _description.text, _skill.text, _cost.text,
		_placeholder.text, _kit.text,
	]
	tooltip_text = detail_tooltip if not detail_tooltip.is_empty() else text


func set_selected(value: bool) -> void:
	button_pressed = value
	apply_role(&"selected" if value else &"secondary")


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


func _build_content() -> void:
	var presentation := get_node("PresentationLabel") as Label
	presentation.text = " "
	var margin := MarginContainer.new()
	margin.name = "PathCardMargin"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: StringName in [&"margin_left", &"margin_top", &"margin_right", &"margin_bottom"]:
		margin.add_theme_constant_override(side, 8)
	add_child(margin)
	_content = VBoxContainer.new()
	_content.name = "PathCardContent"
	_content.add_theme_constant_override(&"separation", 3)
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(_content)
	var header := HBoxContainer.new()
	header.name = "PathIdentityHeader"
	header.add_theme_constant_override(&"separation", 8)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(header)
	var portrait_column := VBoxContainer.new()
	portrait_column.name = "ClassKitColumn"
	portrait_column.custom_minimum_size.x = 68.0
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
	identity.add_theme_constant_override(&"separation", 3)
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
	for detail_label: TrainingLabelType in [_description, _skill, _cost, _kit]:
		detail_label.add_theme_font_size_override(&"font_size", DETAIL_FONT_SIZE)
	_cost.add_theme_font_size_override(&"font_size", COST_FONT_SIZE)
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
	return label
