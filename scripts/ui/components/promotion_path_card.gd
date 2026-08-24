class_name PromotionPathCard
extends "res://scripts/ui/components/aetheria_button.gd"

const TrainingLabelType := preload("res://scripts/ui/components/aetheria_label.gd")
const ArtType := preload("res://scripts/view/art.gd")

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
	custom_minimum_size = Vector2(492.0, 420.0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	tooltip_text = text


func set_selected(value: bool) -> void:
	button_pressed = value
	apply_role(&"selected" if value else &"secondary")


func focus_visibility_target() -> Control:
	return _class_name


func _get_minimum_size() -> Vector2:
	var minimum := custom_minimum_size
	if _content != null:
		var content_minimum := _content.get_combined_minimum_size() + Vector2(28.0, 28.0)
		minimum.x = maxf(minimum.x, content_minimum.x)
		minimum.y = maxf(minimum.y, content_minimum.y)
	return minimum


func set_compact(value: bool) -> void:
	custom_minimum_size = Vector2(540.0, 780.0) if value else Vector2(492.0, 420.0)
	_portrait.custom_minimum_size = (
		Vector2(200.0, 220.0) if value else Vector2(190.0, 184.0)
	)


func fit_to_content() -> void:
	if _content == null:
		return
	var content_minimum := _content.get_combined_minimum_size() + Vector2(28.0, 28.0)
	custom_minimum_size.x = maxf(custom_minimum_size.x, content_minimum.x)
	custom_minimum_size.y = maxf(custom_minimum_size.y, content_minimum.y)
	update_minimum_size()


func _build_content() -> void:
	var presentation := get_node("PresentationLabel") as Label
	presentation.text = " "
	var margin := MarginContainer.new()
	margin.name = "PathCardMargin"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: StringName in [&"margin_left", &"margin_top", &"margin_right", &"margin_bottom"]:
		margin.add_theme_constant_override(side, 14)
	add_child(margin)
	_content = VBoxContainer.new()
	_content.name = "PathCardContent"
	_content.add_theme_constant_override(&"separation", 8)
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(_content)
	var header := HBoxContainer.new()
	header.name = "PathIdentityHeader"
	header.add_theme_constant_override(&"separation", 12)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(header)
	var portrait_column := VBoxContainer.new()
	portrait_column.name = "ClassKitColumn"
	portrait_column.custom_minimum_size.x = 210.0
	portrait_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(portrait_column)
	_portrait = TextureRect.new()
	_portrait.name = "ClassKitPortrait"
	_portrait.custom_minimum_size = Vector2(190.0, 184.0)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_column.add_child(_portrait)
	_placeholder = _label("ClassKitPlaceholder", &"dense_detail")
	_placeholder.add_theme_font_size_override(&"font_size", GameTypographyType.DETAIL)
	_placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait_column.add_child(_placeholder)
	var identity := VBoxContainer.new()
	identity.name = "PathIdentity"
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override(&"separation", 8)
	identity.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(identity)
	_class_name = _label("AdvancedClassName", &"dense_heading")
	_role_label = _label("AdvancedRole", &"dense_detail")
	identity.add_child(_class_name)
	identity.add_child(_role_label)
	_description = _label("ClassDescription", &"dense_detail")
	_skill = _label("SkillFacts", &"dense_detail")
	_cost = _label("DeployCost", &"cost_badge")
	_kit = _label("FieldKit", &"dense_detail")
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
