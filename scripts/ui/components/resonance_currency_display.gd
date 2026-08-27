class_name ResonanceCurrencyDisplay
extends HBoxContainer

const ICON_TEXTURE := preload("res://assets/ui/economy/resonance_shard.png")
const UiCopyType := preload("res://scripts/ui/components/ui_copy.gd")
const GOLD := Color("d9bd79")

var icon: TextureRect
var amount_label: Label
var _currency_kind: StringName = &"resonance_shards"


func _init() -> void:
	name = "ResonanceCurrencyDisplay"
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override(&"separation", 8)
	mouse_filter = Control.MOUSE_FILTER_STOP

	icon = TextureRect.new()
	icon.name = "ResonanceShardIcon"
	icon.texture = ICON_TEXTURE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon)

	amount_label = Label.new()
	amount_label.name = "ResonanceShardAmount"
	amount_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	amount_label.add_theme_color_override(&"font_color", GOLD)
	amount_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(amount_label)

	configure("0")


func configure(
		amount_text: String,
		font_size := 30,
		icon_edge := 38.0,
		accessible_description := "",
		currency_kind: StringName = &"resonance_shards",
	) -> void:
	_currency_kind = currency_kind
	icon.custom_minimum_size = Vector2(icon_edge, icon_edge)
	amount_label.text = amount_text
	amount_label.add_theme_font_size_override(&"font_size", font_size)
	_apply_accessibility(amount_text, accessible_description)


func set_amount(amount_text: String, accessible_description := "") -> void:
	amount_label.text = amount_text
	_apply_accessibility(amount_text, accessible_description)


func _apply_accessibility(amount_text: String, accessible_description: String) -> void:
	var currency_name := accessible_description
	if currency_name.is_empty():
		currency_name = currency_name_for(_currency_kind)
	accessibility_name = "%s %s" % [amount_text, currency_name]
	accessibility_description = tooltip_copy("", _currency_kind)
	tooltip_text = accessibility_description


static func currency_name_for(currency_kind: StringName) -> String:
	if currency_kind == &"marks":
		return UiCopyType.text(&"ui.currency.marks_name", "Marks")
	return UiCopyType.text(&"ui.currency.resonance_shards_name", "Resonance Shards")


static func tooltip_copy(
		context := "", currency_kind: StringName = &"resonance_shards"
	) -> String:
	var concept := (
		UiCopyType.text(
			&"ui.currency.marks_tooltip",
			"Marks — ordinary salvage and Company Manus payment. They contain no anima or souls.",
		)
		if currency_kind == &"marks"
		else UiCopyType.text(
			&"ui.currency.resonance_shard_tooltip",
			"Resonance Shard — clean Lunaris crystal with no soul inside.\nUsed to locate one known soul and prepare a compatible recovery body.",
		)
	)
	if context.is_empty():
		return concept
	return "%s\n%s" % [context, concept]


static func apply_tooltip(
		control: Control, context := "", currency_kind: StringName = &"resonance_shards"
	) -> void:
	if control == null:
		return
	control.tooltip_text = tooltip_copy(context, currency_kind)
	control.accessibility_description = tooltip_copy("", currency_kind)


static func apply_to_button(
		button: Button,
		logical_text: String,
		visible_text: String,
		icon_edge := 34,
		accessible_description := "",
		currency_kind: StringName = &"resonance_shards",
	) -> void:
	var currency_name := accessible_description
	if currency_name.is_empty():
		currency_name = currency_name_for(currency_kind)
	button.text = visible_text
	button.icon = ICON_TEXTURE
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	button.add_theme_constant_override(&"icon_max_width", icon_edge)
	button.accessibility_name = "%s, %s" % [logical_text, currency_name]
	apply_tooltip(button, logical_text, currency_kind)
