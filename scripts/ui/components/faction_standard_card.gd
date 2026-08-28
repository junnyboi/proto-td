class_name FactionStandardCard
extends PanelContainer

const FactionHeraldryType := preload("res://scripts/ui/components/faction_heraldry.gd")
const GameTypographyType := preload("res://scripts/ui/game_typography.gd")

const IVORY := Color("eee8dc")
const MUTED := Color("93a4ad")
const VOID := Color("071019")
const PANEL := Color(0.014, 0.034, 0.052, 0.96)

var faction_id: StringName = &""
var _banner_frame: MarginContainer = null
var _banner_overlay: Control = null
var _banner: TextureRect = null
var _symbol: TextureRect = null
var _name_label: Label = null
var _subtitle_label: Label = null
var _active_label: Label = null


func _init() -> void:
	custom_minimum_size = Vector2(132.0, 176.0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_content()
	var tree := Engine.get_main_loop() as SceneTree
	var i18n := tree.root.get_node_or_null("I18n") if tree != null else null
	if i18n != null:
		i18n.connect("locale_changed", _on_locale_changed)


func configure(value: StringName) -> void:
	faction_id = value
	_banner.texture = FactionHeraldryType.banner(faction_id)
	_symbol.texture = FactionHeraldryType.symbol(faction_id)
	_name_label.text = FactionHeraldryType.display_name(faction_id)
	_subtitle_label.text = FactionHeraldryType.subtitle(faction_id)
	tooltip_text = "%s\n%s" % [
		FactionHeraldryType.display_name(faction_id),
		FactionHeraldryType.specialization(faction_id),
	]
	var active := faction_id == FactionHeraldryType.ACTIVE_FACTION
	_active_label.visible = active
	_active_label.text = FactionHeraldryType.company_name()
	accessibility_name = _name_label.text
	accessibility_description = tooltip_text
	var accent := FactionHeraldryType.accent(faction_id)
	_name_label.add_theme_color_override(&"font_color", IVORY if active else Color(IVORY, 0.9))
	_subtitle_label.add_theme_color_override(&"font_color", accent)
	_active_label.add_theme_color_override(&"font_color", VOID)
	_active_label.add_theme_stylebox_override(&"normal", _pill_style(accent))
	add_theme_stylebox_override(&"panel", _panel_style(
		Color(PANEL, 0.99 if active else 0.9), Color(accent, 0.72 if active else 0.38),
		2 if active else 1,
	))


func _on_locale_changed(_locale_id: StringName) -> void:
	if not String(faction_id).is_empty():
		configure(faction_id)


func set_compact(compact: bool) -> void:
	custom_minimum_size = Vector2(116.0, 154.0) if compact else Vector2(132.0, 176.0)
	_banner_frame.custom_minimum_size.y = 78.0 if compact else 98.0
	_banner_overlay.custom_minimum_size.y = 78.0 if compact else 98.0
	_symbol.custom_minimum_size = Vector2(42.0, 42.0) if compact else Vector2(50.0, 50.0)
	_name_label.add_theme_font_size_override(
		&"font_size", GameTypographyType.BADGE if compact else GameTypographyType.DETAIL,
	)
	_subtitle_label.add_theme_font_size_override(
		&"font_size", GameTypographyType.MICRO_LABEL if compact else GameTypographyType.BADGE,
	)


func _build_content() -> void:
	var stack := VBoxContainer.new()
	stack.name = "StandardStack"
	stack.add_theme_constant_override(&"separation", 5)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stack)

	_banner_frame = MarginContainer.new()
	_banner_frame.name = "BannerFrame"
	_banner_frame.custom_minimum_size.y = 98.0
	_banner_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_banner_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_banner_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_frame.add_theme_constant_override(&"margin_left", 6)
	_banner_frame.add_theme_constant_override(&"margin_top", 6)
	_banner_frame.add_theme_constant_override(&"margin_right", 6)
	stack.add_child(_banner_frame)

	_banner_overlay = Control.new()
	_banner_overlay.name = "BannerOverlay"
	_banner_overlay.custom_minimum_size.y = 98.0
	_banner_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_frame.add_child(_banner_overlay)

	_banner = TextureRect.new()
	_banner.name = "Banner"
	_banner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_banner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_overlay.add_child(_banner)

	_symbol = TextureRect.new()
	_symbol.name = "Symbol"
	_symbol.custom_minimum_size = Vector2(50.0, 50.0)
	_symbol.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_symbol.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_symbol.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_symbol.offset_left = -50.0
	_symbol.offset_top = -50.0
	_symbol.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_overlay.add_child(_symbol)

	var copy := VBoxContainer.new()
	copy.name = "IdentityCopy"
	copy.add_theme_constant_override(&"separation", 1)
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(copy)

	_name_label = Label.new()
	_name_label.name = "FactionName"
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_name_label.add_theme_font_size_override(&"font_size", GameTypographyType.DETAIL)
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(_name_label)

	_subtitle_label = Label.new()
	_subtitle_label.name = "FactionSubtitle"
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_subtitle_label.add_theme_font_size_override(&"font_size", GameTypographyType.BADGE)
	_subtitle_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(_subtitle_label)

	_active_label = Label.new()
	_active_label.name = "ActiveCompanyBadge"
	_active_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_active_label.add_theme_font_size_override(&"font_size", GameTypographyType.MICRO_LABEL)
	_active_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_child(_active_label)


func _panel_style(fill: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(4)
	style.content_margin_left = 24.0
	style.content_margin_top = 24.0
	style.content_margin_right = 24.0
	style.content_margin_bottom = 24.0
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.34)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0.0, 2.0)
	return style


func _pill_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(2)
	style.content_margin_left = 4.0
	style.content_margin_right = 4.0
	return style
