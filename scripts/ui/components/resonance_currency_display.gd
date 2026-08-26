class_name ResonanceCurrencyDisplay
extends HBoxContainer

const ICON_TEXTURE := preload("res://assets/ui/economy/resonance_shard.png")
const GOLD := Color("d9bd79")

var icon: TextureRect
var amount_label: Label


func _init() -> void:
	name = "ResonanceCurrencyDisplay"
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override(&"separation", 8)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

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
		accessible_description := "Resonance Shards",
	) -> void:
	icon.custom_minimum_size = Vector2(icon_edge, icon_edge)
	amount_label.text = amount_text
	amount_label.add_theme_font_size_override(&"font_size", font_size)
	accessibility_name = "%s %s" % [amount_text, accessible_description]
	tooltip_text = accessibility_name


func set_amount(amount_text: String, accessible_description := "Resonance Shards") -> void:
	amount_label.text = amount_text
	accessibility_name = "%s %s" % [amount_text, accessible_description]
	tooltip_text = accessibility_name


static func apply_to_button(
		button: Button,
		logical_text: String,
		visible_text: String,
		icon_edge := 34,
		accessible_description := "Resonance Shards",
	) -> void:
	button.text = visible_text
	button.icon = ICON_TEXTURE
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	button.add_theme_constant_override(&"icon_max_width", icon_edge)
	button.accessibility_name = "%s, %s" % [logical_text, accessible_description]
	button.tooltip_text = button.accessibility_name
