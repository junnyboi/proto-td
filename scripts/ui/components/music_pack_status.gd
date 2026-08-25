extends PanelContainer

## Compact content-pack transfer status for entry surfaces only. Parent screens decide
## where this control exists; battle and deeper campaign screens never instantiate it.

signal retry_requested(act: int)
signal retry_availability_changed(available: bool)

const StagingSkinType := preload("res://scripts/ui/components/staging_skin.gd")

const GOLD := Color("d8b978")
const BRIGHT_GOLD := Color("f0d89a")
const MOON_CYAN := Color("91eaf1")
const IVORY := Color("f5efe1")
const MUTED := Color("aebfd0")
const VOID := Color("071019")
const PACK_STATE_UNCONFIGURED := &"unconfigured"
const PACK_STATE_LOADING := &"loading"
const PACK_STATE_FAILED := &"failed"

var _act := 0
var _state: StringName = &"unconfigured"
var _initialized := false
var _music: Node = null
var _status_label: Label = null
var _progress: ProgressBar = null
var _retry: Button = null


func _ready() -> void:
	name = "MusicPackStatus"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()
	_music = get_node_or_null("/root/Music")
	if _music == null:
		visible = false
		set_process(false)
		return
	var callback := Callable(self, "_on_pack_state_changed")
	if not _music.is_connected("pack_state_changed", callback):
		_music.connect("pack_state_changed", callback)
	_refresh(true)
	_initialized = true


func _exit_tree() -> void:
	var callback := Callable(self, "_on_pack_state_changed")
	if _music != null and is_instance_valid(_music) and _music.is_connected("pack_state_changed", callback):
		_music.disconnect("pack_state_changed", callback)


func _process(_delta: float) -> void:
	if visible and _state == PACK_STATE_LOADING:
		_refresh_progress()


func set_act(act: int) -> void:
	_act = act if act >= 1 and act <= 3 else 0
	_refresh(true)


func act() -> int:
	return _act


func retry_button() -> Button:
	return _retry


func set_compact(compact: bool) -> void:
	custom_minimum_size = Vector2(270.0 if compact else 360.0, 48.0 if compact else 52.0)
	if _status_label != null:
		StagingSkinType.apply_display_type(_status_label, 11 if compact else 13, IVORY, 560)
	if _progress != null:
		_progress.custom_minimum_size.x = 150.0 if compact else 220.0
	if _retry != null:
		_retry.custom_minimum_size = Vector2(72.0 if compact else 82.0, 32.0 if compact else 34.0)


func _build_ui() -> void:
	custom_minimum_size = Vector2(360.0, 52.0)
	add_theme_stylebox_override(&"panel", _panel_style())

	var margin := MarginContainer.new()
	margin.add_theme_constant_override(&"margin_left", 12)
	margin.add_theme_constant_override(&"margin_top", 7)
	margin.add_theme_constant_override(&"margin_right", 9)
	margin.add_theme_constant_override(&"margin_bottom", 7)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)

	var transfer := VBoxContainer.new()
	transfer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	transfer.add_theme_constant_override(&"separation", 4)
	transfer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(transfer)

	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_status_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	StagingSkinType.apply_display_type(_status_label, 13, IVORY, 560)
	transfer.add_child(_status_label)

	_progress = ProgressBar.new()
	_progress.name = "DownloadProgress"
	_progress.custom_minimum_size = Vector2(220.0, 5.0)
	_progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_progress.show_percentage = false
	_progress.min_value = 0.0
	_progress.max_value = 100.0
	_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_progress.add_theme_stylebox_override(&"background", _bar_style(Color(VOID, 0.84)))
	_progress.add_theme_stylebox_override(&"fill", _bar_style(Color(MOON_CYAN, 0.94)))
	transfer.add_child(_progress)

	_retry = Button.new()
	_retry.name = "RetryButton"
	_retry.text = "RETRY"
	_retry.tooltip_text = "Retry music download. Gameplay remains available without it."
	_retry.custom_minimum_size = Vector2(82.0, 34.0)
	_retry.focus_mode = Control.FOCUS_ALL
	_retry.mouse_filter = Control.MOUSE_FILTER_STOP
	_retry.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	StagingSkinType.apply_display_type(_retry, 12, BRIGHT_GOLD, 620)
	_retry.add_theme_stylebox_override(
		&"normal", StagingSkinType.clean_button_style(Color(VOID, 0.76), Color(GOLD, 0.46)),
	)
	_retry.add_theme_stylebox_override(
		&"hover", StagingSkinType.clean_button_style(Color(GOLD, 0.14), Color(BRIGHT_GOLD, 0.82)),
	)
	_retry.add_theme_stylebox_override(
		&"pressed", StagingSkinType.clean_button_style(Color(GOLD, 0.24), BRIGHT_GOLD),
	)
	_retry.add_theme_stylebox_override(&"focus", StagingSkinType.transparent_focus_style(BRIGHT_GOLD))
	_retry.pressed.connect(_on_retry_pressed)
	row.add_child(_retry)


func _on_pack_state_changed(changed_act: int, _next_state: StringName) -> void:
	if changed_act == _act:
		_refresh(true)


func _refresh(force: bool = false) -> void:
	var next_state := (
		StringName(_music.call("pack_state", _act))
		if _music != null and _act > 0
		else PACK_STATE_UNCONFIGURED
	)
	if not force and next_state == _state:
		return
	_state = next_state
	var should_show := _state in [PACK_STATE_LOADING, PACK_STATE_FAILED]
	var retry_available := _state == PACK_STATE_FAILED
	var retry_changed := _retry != null and _retry.visible != retry_available
	if _retry != null:
		_retry.visible = retry_available
	if _progress != null:
		_progress.visible = _state == PACK_STATE_LOADING
	if visible != should_show:
		visible = should_show
	set_process(should_show and _state == PACK_STATE_LOADING)
	if _status_label == null or _progress == null or _retry == null:
		return
	if retry_changed and _initialized:
		retry_availability_changed.emit(retry_available)
	if not should_show:
		return
	if _state == PACK_STATE_FAILED:
		_status_label.text = "ACT %s MUSIC  //  DOWNLOAD INTERRUPTED" % _roman_act()
		_status_label.add_theme_color_override(&"font_color", MUTED)
	else:
		_status_label.add_theme_color_override(&"font_color", IVORY)
		_refresh_progress()


func _refresh_progress() -> void:
	var percent := clampi(roundi(float(_music.call("pack_download_progress", _act)) * 100.0), 0, 100)
	_progress.value = percent
	_status_label.text = "ACT %s MUSIC  //  DOWNLOADING %d%%" % [_roman_act(), percent]


func _on_retry_pressed() -> void:
	retry_requested.emit(_act)
	if _music != null:
		_music.call("retry_content_pack", _act)


func _roman_act() -> String:
	return ["I", "II", "III"][_act - 1] if _act >= 1 and _act <= 3 else "—"


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.008, 0.025, 0.04, 0.90)
	style.border_color = Color(MOON_CYAN, 0.42)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.shadow_color = Color(VOID, 0.42)
	style.shadow_size = 8
	return style


func _bar_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	return style
