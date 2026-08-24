extends Control

## Cinematic boot bridge. The engine boot splash and this first scene share the
## same art so startup is visually continuous while the title scene is prepared.

const LOADING_ART := preload("res://assets/loading/lunaris_reliquary_loading.png")
const TITLE_SCENE := preload("res://scenes/title.tscn")
const GOLD := Color("d8b978")
const MOON_CYAN := Color("86cbd4")
const IVORY := Color("eee8dc")
const MUTED := Color("aebdc3")
const VOID := Color("071019")

const MINIMUM_DISPLAY_SECONDS := 1.8
const FADE_SECONDS := 0.35

var _elapsed := 0.0
var _finishing := false
var _progress: ProgressBar
var _status: Label
var _percentage: Label
var _veil: ColorRect


func _ready() -> void:
	_build_screen()
	Game.content = self
	set_process(true)
	# Resolve the destination up front so the transition never exposes an empty root.
	TITLE_SCENE.resource_path


func _process(delta: float) -> void:
	if _finishing:
		return
	_elapsed += delta
	var ratio := clampf(_elapsed / MINIMUM_DISPLAY_SECONDS, 0.0, 1.0)
	var eased := 1.0 - pow(1.0 - ratio, 3.0)
	_progress.value = eased * 100.0
	_percentage.text = "%02d%%" % int(round(eased * 100.0))
	_status.text = _status_for_ratio(ratio)
	if ratio >= 1.0:
		_finish_loading()


func _build_screen() -> void:
	var art := TextureRect.new()
	art.name = "LunarisArtwork"
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.texture = LOADING_ART
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)

	var atmosphere := ColorRect.new()
	atmosphere.name = "Atmosphere"
	atmosphere.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	atmosphere.color = Color(0.01, 0.025, 0.04, 0.12)
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
	header.offset_top = 28.0
	header.offset_right = -42.0
	header.offset_bottom = 86.0
	add_child(header)

	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override(&"separation", 16)
	header.add_child(header_row)

	var faction := _label("LUNARIS RELIQUARY", 17, GOLD)
	faction.name = "FactionLabel"
	faction.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(faction)

	var chapter := _label("MOON ARCHIVE // 00", 14, IVORY)
	chapter.name = "ArchiveLabel"
	chapter.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header_row.add_child(chapter)

	var lower_shade := ColorRect.new()
	lower_shade.name = "LowerShade"
	lower_shade.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	lower_shade.offset_top = -194.0
	lower_shade.color = Color(0.015, 0.035, 0.055, 0.88)
	lower_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lower_shade)

	var footer := MarginContainer.new()
	footer.name = "LoadingPanel"
	footer.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_left = 42.0
	footer.offset_top = -174.0
	footer.offset_right = -42.0
	footer.offset_bottom = -30.0
	add_child(footer)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override(&"separation", 9)
	footer.add_child(stack)

	var wordmark := _label("PROTOS", 46, IVORY)
	wordmark.name = "Wordmark"
	wordmark.add_theme_constant_override(&"outline_size", 8)
	wordmark.add_theme_color_override(&"font_outline_color", Color(0.01, 0.02, 0.03, 0.7))
	stack.add_child(wordmark)

	var status_row := HBoxContainer.new()
	status_row.add_theme_constant_override(&"separation", 18)
	stack.add_child(status_row)

	_status = _label("AWAKENING RELIQUARY", 14, MUTED)
	_status.name = "StatusLabel"
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_row.add_child(_status)

	_percentage = _label("00%", 14, MOON_CYAN)
	_percentage.name = "PercentageLabel"
	_percentage.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_row.add_child(_percentage)

	_progress = ProgressBar.new()
	_progress.name = "Progress"
	_progress.custom_minimum_size = Vector2(0.0, 7.0)
	_progress.show_percentage = false
	_progress.value = 0.0
	_progress.add_theme_stylebox_override(&"background", _bar_style(Color(0.22, 0.29, 0.32, 0.62)))
	_progress.add_theme_stylebox_override(&"fill", _bar_style(MOON_CYAN))
	stack.add_child(_progress)

	var detail := _label("CUSTODIANS OF MEMORY, GRAVITY, AND RITUAL GEOMETRY", 11, Color(0.64, 0.72, 0.74))
	detail.name = "DetailLabel"
	detail.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	stack.add_child(detail)

	_veil = ColorRect.new()
	_veil.name = "FadeVeil"
	_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_veil.color = Color(VOID, 0.0)
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_veil)


func _label(text_value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override(&"font_size", size)
	label.add_theme_color_override(&"font_color", color)
	return label


func _bar_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	return style


func _status_for_ratio(ratio: float) -> String:
	if ratio < 0.36:
		return "AWAKENING RELIQUARY"
	if ratio < 0.72:
		return "ALIGNING LUNAR GEOMETRY"
	if ratio < 0.96:
		return "RESTORING OPERATOR RECORDS"
	return "ARCHIVE SYNCHRONIZED"


func _finish_loading() -> void:
	_finishing = true
	_status.text = "ARCHIVE SYNCHRONIZED"
	_percentage.text = "100%"
	_progress.value = 100.0
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_veil, "color:a", 1.0, FADE_SECONDS)
	await tween.finished
	if is_inside_tree():
		Game.open_title()
