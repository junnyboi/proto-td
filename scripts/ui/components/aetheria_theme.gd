class_name AetheriaTheme
extends Theme

const CJK_FONT := preload("res://assets/fonts/ProtosSansSC-Subset.otf")
const COLORS := {
	&"backdrop": Color("111827"),
	&"panel": Color("1c2433"),
	&"secondary": Color("263147"),
	&"secondary_hover": Color("34425c"),
	&"body": Color("f7f3e8"),
	&"muted": Color("c7d6e8"),
	&"primary": Color("e3b341"),
	&"primary_hover": Color("f0cf65"),
	&"primary_pressed": Color("c58b24"),
	&"selected": Color("5dc8d3"),
	&"selected_hover": Color("79dbe3"),
	&"selected_pressed": Color("3ea9b8"),
	&"destructive": Color("7f2d2d"),
	&"destructive_hover": Color("973a34"),
	&"destructive_pressed": Color("642222"),
	&"disabled_background": Color("303846"),
	&"disabled_text": Color("aeb8c6"),
	&"focus": Color("f0cf65"),
	&"boundary": Color("8998ac"),
	&"dark_ink": Color("111827"),
	&"transparent": Color("00000000"),
}


func _init() -> void:
	var composite_font := FontVariation.new()
	composite_font.base_font = ThemeDB.fallback_font
	composite_font.fallbacks = [CJK_FONT]
	default_font = composite_font
	default_font_size = 44
	_build_buttons()
	_build_locale_list()
	_build_panels()
	_build_labels()


func _build_buttons() -> void:
	_button(
		&"AuiPrimaryButton", &"primary", &"primary_hover", &"primary_pressed",
		&"dark_ink",
	)
	_button(
		&"AuiSecondaryButton", &"secondary", &"secondary_hover", &"panel", &"body",
	)
	_button(
		&"AuiSelectedButton", &"selected", &"selected_hover", &"selected_pressed",
		&"dark_ink",
	)
	_button(
		&"AuiDestructiveButton", &"destructive", &"destructive_hover",
		&"destructive_pressed", &"body",
	)
	_button(
		&"AuiDisabledButton", &"disabled_background", &"disabled_background",
		&"disabled_background", &"disabled_text",
	)
func _button(
		variation: StringName, normal: StringName, hover: StringName,
		pressed: StringName, ink: StringName, base: StringName = &"Button",
		) -> void:
	set_type_variation(variation, base)
	set_font_size(&"font_size", variation, 44)
	for item_name: StringName in [
		&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color",
	]:
		set_color(item_name, variation, COLORS[ink])
	set_color(&"font_disabled_color", variation, COLORS[&"disabled_text"])
	set_stylebox(&"normal", variation, _button_box(normal))
	set_stylebox(&"hover", variation, _button_box(hover))
	set_stylebox(&"pressed", variation, _button_box(pressed))
	set_stylebox(&"focus", variation, _focus_box())
	set_stylebox(&"disabled", variation, _button_box(&"disabled_background"))
	set_constant(&"outline_size", variation, 0)
	set_constant(&"h_separation", variation, 12)
	set_constant(&"icon_max_width", variation, 96)


func _build_locale_list() -> void:
	var variation := &"AuiLocaleList"
	set_type_variation(variation, &"ItemList")
	set_font_size(&"font_size", variation, 44)
	set_color(&"font_color", variation, COLORS[&"body"])
	set_color(&"font_hovered_color", variation, COLORS[&"body"])
	set_color(&"font_selected_color", variation, COLORS[&"dark_ink"])
	set_color(&"font_hovered_selected_color", variation, COLORS[&"dark_ink"])
	set_stylebox(&"panel", variation, _button_box(&"secondary"))
	set_stylebox(&"focus", variation, _focus_box())
	set_stylebox(
		&"hovered", variation,
		_box(&"secondary_hover", &"boundary", 2, 8, [8, 4, 8, 4]),
	)
	set_stylebox(
		&"selected", variation,
		_box(&"selected", &"boundary", 2, 8, [8, 4, 8, 4]),
	)
	set_stylebox(
		&"selected_focus", variation,
		_box(&"selected", &"boundary", 2, 8, [8, 4, 8, 4]),
	)
	set_stylebox(
		&"hovered_selected", variation,
		_box(&"selected_hover", &"boundary", 2, 8, [8, 4, 8, 4]),
	)
	set_stylebox(
		&"hovered_selected_focus", variation,
		_box(&"selected_hover", &"boundary", 2, 8, [8, 4, 8, 4]),
	)
	set_stylebox(
		&"cursor", variation,
		_box(&"transparent", &"focus", 3, 8, [0, 0, 0, 0]),
	)
	set_stylebox(
		&"cursor_unfocused", variation,
		_box(&"transparent", &"boundary", 2, 8, [0, 0, 0, 0]),
	)
	set_constant(&"outline_size", variation, 0)


func _build_panels() -> void:
	_panel(&"AuiReadingPanel", &"reading_panel", &"panel", &"boundary", 2, 12, 40)
	_panel(&"AuiHudPanel", &"hud_panel", &"panel", &"boundary", 2, 8, 16)
	_panel(&"AuiCardPanel", &"card_panel", &"secondary", &"boundary", 2, 10, 20)
	_panel(&"AuiModalPanel", &"modal_panel", &"panel", &"focus", 3, 12, 40)
	_panel(
		&"AuiInspectorPanel", &"inspector_panel", &"secondary", &"boundary", 2, 8, 20,
	)
	_panel(&"AuiRewardPanel", &"reward_panel", &"panel", &"primary", 3, 12, 40)
	set_type_variation(&"AuiFocusRing", &"PanelContainer")
	set_stylebox(&"panel", &"AuiFocusRing", _focus_box(12))


func _panel(
		variation: StringName, _style_id: StringName, background: StringName,
		border: StringName, border_width: int, corner_radius: int, margin: int,
	) -> void:
	set_type_variation(variation, &"PanelContainer")
	set_stylebox(
		&"panel", variation,
		_box(background, border, border_width, corner_radius, [margin, margin, margin, margin]),
	)


func _build_labels() -> void:
	_label(&"AuiTitleLabel", 64, &"primary")
	_label(&"AuiHeadingLabel", 48, &"primary")
	_label(&"AuiBodyLabel", 44, &"body")
	_label(&"AuiDetailLabel", 44, &"muted")
	_label(&"AuiDenseHeadingLabel", 34, &"primary")
	_label(&"AuiDenseBodyLabel", 34, &"body")
	_label(&"AuiDenseDetailLabel", 34, &"muted")
	_label(&"AuiLocaleLabel", 44, &"body")
	_badge(&"AuiClassBadge", &"class_badge", &"selected", &"dark_ink")
	_badge(&"AuiCostBadge", &"cost_badge", &"primary", &"dark_ink")
	_badge(&"AuiCooldownBadge", &"cooldown_badge", &"secondary", &"body")
	_badge(
		&"AuiLockedBadge", &"locked_badge", &"disabled_background", &"disabled_text",
	)
	_badge(&"AuiCompletedBadge", &"completed_badge", &"selected", &"dark_ink")


func _label(variation: StringName, font_size: int, color: StringName) -> void:
	set_type_variation(variation, &"Label")
	set_font_size(&"font_size", variation, font_size)
	set_color(&"font_color", variation, COLORS[color])


func _badge(
		variation: StringName, _style_id: StringName, background: StringName,
		ink: StringName,
		) -> void:
	_label(variation, 44, ink)
	set_stylebox(
		&"normal", variation,
		_box(background, &"boundary", 2, 8, [8, 4, 8, 4]),
	)


func _button_box(background: StringName) -> StyleBoxFlat:
	return _box(background, &"boundary", 2, 8, [18, 10, 18, 10])


func _focus_box(corner_radius: int = 10) -> StyleBoxFlat:
	var style := _box(&"transparent", &"focus", 4, corner_radius, [0, 0, 0, 0])
	style.set_expand_margin_all(4.0)
	return style


func _box(
		background: StringName, border: StringName, border_width: int,
		corner_radius: int, margins: Array,
	) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = COLORS[background]
	style.border_color = COLORS[border]
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner_radius)
	style.content_margin_left = float(margins[0])
	style.content_margin_top = float(margins[1])
	style.content_margin_right = float(margins[2])
	style.content_margin_bottom = float(margins[3])
	return style
