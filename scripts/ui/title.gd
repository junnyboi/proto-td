extends Control

## Cinematic player entry. The animated Lunaris background continues the visual
## language established by the engine boot splash and loading scene.

const LOCALE_SCENE := preload("res://scenes/ui/components/aetheria_locale_selector.tscn")
const AetheriaButtonType := preload("res://scripts/ui/components/aetheria_button.gd")
const AetheriaLocaleSelectorType := preload(
	"res://scripts/ui/components/aetheria_locale_selector.gd"
)
const UiCopyType := preload("res://scripts/ui/components/ui_copy.gd")
const TITLE_ART := preload("res://assets/loading/lunaris_reliquary_loading.png")
const TITLE_LOOP := preload("res://assets/title/lunaris-title-loop.ogv")

const GOLD := Color("d8b978")
const MOON_CYAN := Color("86cbd4")
const IVORY := Color("eee8dc")
const MUTED := Color("aebdc3")
const VOID := Color("071019")
const PANEL := Color(0.012, 0.03, 0.048, 0.9)

var _locale_selector: AetheriaLocaleSelectorType = null
var _start_button: AetheriaButtonType = null
var _wordmark: Label = null
var _eyebrow: Label = null
var _tagline: Label = null
var _seed_label: Label = null
var _archive_label: Label = null
var _footer: MarginContainer = null
var _lower_shade: ColorRect = null
var _action_row: GridContainer = null
var _video: VideoStreamPlayer = null


func _ready() -> void:
	_build_screen()
	get_viewport().size_changed.connect(_apply_responsive_layout)
	_refresh_copy()
	_apply_responsive_layout()
	_start_button.grab_focus.call_deferred()
	Game.content = self


func _build_screen() -> void:
	var fallback := TextureRect.new()
	fallback.name = "TitleFallback"
	fallback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fallback.texture = TITLE_ART
	fallback.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fallback.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fallback)

	_video = VideoStreamPlayer.new()
	_video.name = "LunarisTitleLoop"
	_video.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_video.stream = TITLE_LOOP
	_video.autoplay = true
	_video.loop = true
	_video.expand = true
	_video.volume_db = -80.0
	_video.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_video)
	_video.play()

	var atmosphere := ColorRect.new()
	atmosphere.name = "Atmosphere"
	atmosphere.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	atmosphere.color = Color(0.005, 0.015, 0.03, 0.14)
	atmosphere.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(atmosphere)

	var top_rule := ColorRect.new()
	top_rule.name = "TopRule"
	top_rule.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_rule.offset_bottom = 3.0
	top_rule.color = GOLD
	top_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_rule)

	var header := MarginContainer.new()
	header.name = "Header"
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header.offset_left = 42.0
	header.offset_top = 27.0
	header.offset_right = -42.0
	header.offset_bottom = 86.0
	add_child(header)

	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override(&"separation", 18)
	header.add_child(header_row)

	var faction := _label("LUNARIS RELIQUARY", 17, GOLD)
	faction.name = "FactionLabel"
	faction.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(faction)

	_archive_label = _label("MOON ARCHIVE // ONLINE", 14, IVORY)
	_archive_label.name = "ArchiveLabel"
	_archive_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header_row.add_child(_archive_label)

	_lower_shade = ColorRect.new()
	_lower_shade.name = "LowerShade"
	_lower_shade.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_lower_shade.color = PANEL
	_lower_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_lower_shade)

	_footer = MarginContainer.new()
	_footer.name = "TitlePanel"
	_footer.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	add_child(_footer)

	var stack := VBoxContainer.new()
	stack.name = "TitleStack"
	stack.add_theme_constant_override(&"separation", 5)
	_footer.add_child(stack)

	_eyebrow = _label("RELIQUARY COMMAND // OPERATOR ACCESS", 13, GOLD)
	_eyebrow.name = "Eyebrow"
	stack.add_child(_eyebrow)

	_wordmark = _label("PROTOS", 58, IVORY)
	_wordmark.name = "Wordmark"
	_wordmark.add_theme_constant_override(&"outline_size", 10)
	_wordmark.add_theme_color_override(&"font_outline_color", Color(0.0, 0.01, 0.02, 0.78))
	stack.add_child(_wordmark)

	_tagline = _label("CUSTODIANS OF MEMORY, GRAVITY, AND RITUAL GEOMETRY", 12, MUTED)
	_tagline.name = "Tagline"
	_tagline.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	stack.add_child(_tagline)

	var divider := ColorRect.new()
	divider.name = "MoonDivider"
	divider.custom_minimum_size = Vector2(0.0, 2.0)
	divider.color = Color(MOON_CYAN, 0.72)
	stack.add_child(divider)

	_action_row = GridContainer.new()
	_action_row.name = "ActionRow"
	_action_row.columns = 2
	_action_row.add_theme_constant_override(&"separation", 14)
	stack.add_child(_action_row)

	_start_button = AetheriaButtonType.new()
	_start_button.name = "StartButton"
	_start_button.apply_role(&"primary")
	_start_button.custom_minimum_size = Vector2(330.0, 52.0)
	_start_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_start_button.add_theme_font_size_override(&"font_size", 20)
	_start_button.add_theme_color_override(&"font_color", VOID)
	_start_button.add_theme_color_override(&"font_hover_color", VOID)
	_start_button.add_theme_color_override(&"font_pressed_color", IVORY)
	_start_button.add_theme_stylebox_override(&"normal", _button_style(MOON_CYAN, Color(MOON_CYAN, 0.95), 1))
	_start_button.add_theme_stylebox_override(&"hover", _button_style(Color("a5dce2"), IVORY, 2))
	_start_button.add_theme_stylebox_override(&"pressed", _button_style(Color("2f6f79"), MOON_CYAN, 2))
	_start_button.add_theme_stylebox_override(&"focus", _button_style(Color(MOON_CYAN, 0.2), GOLD, 2))
	_start_button.pressed.connect(_on_start_pressed)
	_action_row.add_child(_start_button)

	var utility := VBoxContainer.new()
	utility.name = "UtilityStack"
	utility.custom_minimum_size = Vector2(270.0, 0.0)
	utility.add_theme_constant_override(&"separation", 5)
	_action_row.add_child(utility)

	_seed_label = _label("RUN SEED // 42", 12, GOLD)
	_seed_label.name = "SeedLabel"
	_seed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	utility.add_child(_seed_label)

	_locale_selector = LOCALE_SCENE.instantiate() as AetheriaLocaleSelectorType
	_locale_selector.name = "LocaleSelector"
	_locale_selector.alignment = BoxContainer.ALIGNMENT_END
	_locale_selector.locale_selected.connect(_on_locale_selected)
	utility.add_child(_locale_selector)

	var locale_list := _locale_selector.get_node("LocaleList") as ItemList
	_start_button.focus_neighbor_top = _start_button.get_path_to(locale_list)
	_start_button.focus_previous = _start_button.get_path_to(locale_list)
	_start_button.focus_neighbor_bottom = _start_button.get_path_to(locale_list)
	_start_button.focus_next = _start_button.get_path_to(locale_list)
	locale_list.focus_neighbor_top = locale_list.get_path_to(_start_button)
	locale_list.focus_previous = locale_list.get_path_to(_start_button)
	locale_list.focus_neighbor_bottom = locale_list.get_path_to(_start_button)
	locale_list.focus_next = locale_list.get_path_to(_start_button)


func _on_start_pressed() -> void:
	Sfx.play("ui_click")
	Game.start_campaign()


func _on_locale_selected(_locale_id: StringName) -> void:
	_refresh_copy()


func _refresh_copy() -> void:
	_wordmark.text = UiCopyType.text(&"ui.game_title", "Protos").to_upper()
	_start_button.text = UiCopyType.text(&"ui.title.start", "Start").to_upper()
	_seed_label.text = UiCopyType.format_text(
		&"ui.title.seed", "RUN SEED // {seed}", {&"seed": Game.run_seed},
	).to_upper()


func _apply_responsive_layout() -> void:
	if _footer == null:
		return
	var viewport_size := get_viewport_rect().size
	_fit_video_cover(viewport_size)
	var portrait := viewport_size.y > viewport_size.x
	if portrait:
		_lower_shade.offset_top = -370.0
		_footer.offset_left = 24.0
		_footer.offset_top = -350.0
		_footer.offset_right = -24.0
		_footer.offset_bottom = -18.0
		_wordmark.add_theme_font_size_override(&"font_size", 44)
		_tagline.add_theme_font_size_override(&"font_size", 10)
		_action_row.columns = 1
		_start_button.custom_minimum_size = Vector2(0.0, 52.0)
		_locale_selector.set_vertical_layout(false)
		_archive_label.visible = false
	else:
		_lower_shade.offset_top = -280.0
		_footer.offset_left = 42.0
		_footer.offset_top = -264.0
		_footer.offset_right = -42.0
		_footer.offset_bottom = -16.0
		_wordmark.add_theme_font_size_override(&"font_size", 50)
		_tagline.add_theme_font_size_override(&"font_size", 12)
		_action_row.columns = 2
		_start_button.custom_minimum_size = Vector2(330.0, 52.0)
		_locale_selector.set_vertical_layout(false)
		_archive_label.visible = true


func _fit_video_cover(viewport_size: Vector2) -> void:
	if _video == null or viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	const SOURCE_ASPECT := 16.0 / 9.0
	var viewport_aspect := viewport_size.x / viewport_size.y
	var fitted_size: Vector2
	if viewport_aspect > SOURCE_ASPECT:
		fitted_size = Vector2(viewport_size.x, viewport_size.x / SOURCE_ASPECT)
	else:
		fitted_size = Vector2(viewport_size.y * SOURCE_ASPECT, viewport_size.y)
	_video.position = (viewport_size - fitted_size) * 0.5
	_video.size = fitted_size


func _label(text_value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override(&"font_size", size)
	label.add_theme_color_override(&"font_color", color)
	return label


func _button_style(fill: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(3)
	style.content_margin_left = 22.0
	style.content_margin_right = 22.0
	return style
