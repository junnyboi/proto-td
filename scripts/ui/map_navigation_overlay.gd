class_name MapNavigationOverlay
extends Control

signal recenter_requested

const AETHERIA_THEME := preload("res://scripts/ui/components/aetheria_theme.gd")
const AETHERIA_PANEL := preload("res://scripts/ui/components/aetheria_panel.gd")
const LUNARIS_STYLE := preload("res://scripts/ui/components/lunaris_ops_style.gd")
const VIEW_PREFERENCES := preload("res://scripts/view/view_preferences.gd")

const HINT_LIVE_SECONDS := 7.0
const HINT_PULSE_PERIOD_SECONDS := 1.6
const PORTRAIT_MARGIN := 16.0
const CONTROL_TOP := 104.0
const OVERLAY_Z := 78

var _preferences_path := VIEW_PREFERENCES.DEFAULT_PATH
var _hint_complete := false
var _hint_expired := false
var _hint_elapsed := 0.0
var _portrait := false
var _can_pan := false
var _hint_allowed := false
var _centered := true
var _interaction_enabled := true

var _hint_panel: PanelContainer = null
var _hint_direction: Label = null
var _recenter_button: Button = null


func setup(preferences_path: String = VIEW_PREFERENCES.DEFAULT_PATH) -> void:
	_preferences_path = preferences_path
	_hint_complete = VIEW_PREFERENCES.has_seen_pan_hint(_preferences_path)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2.ZERO
	size = get_viewport().get_visible_rect().size
	z_index = OVERLAY_Z
	theme = AETHERIA_THEME.new()
	_build_hint()
	_build_recenter_button()
	_refresh_visibility()
	relayout()


func set_context(
	portrait: bool,
	can_pan: bool,
	hint_allowed: bool,
	centered: bool,
	interaction_enabled: bool,
) -> void:
	_portrait = portrait
	_can_pan = can_pan
	_hint_allowed = hint_allowed
	_centered = centered
	_interaction_enabled = interaction_enabled
	_refresh_visibility()


func relayout() -> void:
	size = get_viewport().get_visible_rect().size
	if _recenter_button != null:
		_recenter_button.reset_size()
		_recenter_button.position = Vector2(PORTRAIT_MARGIN, CONTROL_TOP)
	if _hint_panel != null:
		var width := minf(size.x - PORTRAIT_MARGIN * 2.0, 340.0)
		var height := 126.0
		_hint_panel.custom_minimum_size = Vector2(width, height)
		_hint_panel.reset_size()
		_hint_panel.position = Vector2(
			(size.x - width) * 0.5,
			maxf(CONTROL_TOP + 64.0, size.y - height - 320.0),
		)
		_hint_panel.size = Vector2(width, height)
		_hint_panel.set_deferred(&"size", Vector2(width, height))


func notify_pan_used() -> void:
	if _hint_complete:
		return
	_hint_complete = true
	_hint_expired = true
	if not VIEW_PREFERENCES.mark_pan_hint_seen(_preferences_path):
		push_warning("MapNavigationOverlay: could not persist pan hint completion")
	_refresh_visibility()


func hint_visible() -> bool:
	return _hint_panel != null and _hint_panel.visible


func recenter_enabled() -> bool:
	return _recenter_button != null and _recenter_button.visible and not _recenter_button.disabled


func _process(delta: float) -> void:
	if _hint_panel == null or not _hint_panel.visible:
		return
	_enforce_hint_rect()
	_hint_elapsed += maxf(delta, 0.0)
	if _hint_elapsed >= HINT_LIVE_SECONDS:
		_hint_expired = true
		_refresh_visibility()
		return
	var phase := fmod(_hint_elapsed, HINT_PULSE_PERIOD_SECONDS) / HINT_PULSE_PERIOD_SECONDS
	var pulse := 0.78 + sin(phase * TAU) * 0.16
	_hint_direction.modulate.a = pulse


func _enforce_hint_rect() -> void:
	var width := minf(size.x - PORTRAIT_MARGIN * 2.0, 340.0)
	var height := 126.0
	_hint_panel.position = Vector2(
		(size.x - width) * 0.5,
		maxf(CONTROL_TOP + 64.0, size.y - height - 320.0),
	)
	_hint_panel.size = Vector2(width, height)


func _build_hint() -> void:
	_hint_panel = AETHERIA_PANEL.new()
	_hint_panel.name = "MapPanHint"
	_hint_panel.apply_role(&"hud")
	LUNARIS_STYLE.apply_panel(_hint_panel, &"selected")
	_hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hint_panel)
	var row := HBoxContainer.new()
	row.name = "HintRow"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 14)
	_hint_panel.add_child(row)
	_hint_direction = Label.new()
	_hint_direction.name = "PanDirections"
	_hint_direction.text = "↔  ↕"
	_hint_direction.theme_type_variation = &"AuiHeadingLabel"
	_hint_direction.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_hint_direction)
	var copy_column := VBoxContainer.new()
	copy_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy_column.custom_minimum_size.x = 230.0
	copy_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy_column.add_theme_constant_override("separation", 2)
	row.add_child(copy_column)
	var title := Label.new()
	title.name = "HintTitle"
	title.text = _copy(&"ui.map_navigation.hint_title", "DRAG TO PAN")
	title.theme_type_variation = &"AuiDenseHeadingLabel"
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy_column.add_child(title)
	var detail := Label.new()
	detail.name = "HintDetail"
	detail.text = _copy(
		&"ui.map_navigation.hint_body",
		"Explore the full battlefield on every open axis.",
	)
	detail.theme_type_variation = &"AuiDenseDetailLabel"
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy_column.add_child(detail)


func _build_recenter_button() -> void:
	_recenter_button = Button.new()
	_recenter_button.name = "RecenterMap"
	_recenter_button.text = _copy(&"ui.map_navigation.recenter", "CENTER")
	_recenter_button.tooltip_text = _copy(
		&"ui.map_navigation.recenter_tooltip",
		"Reset the battlefield view (R)",
	)
	_recenter_button.theme_type_variation = &"AuiSecondaryButton"
	_recenter_button.focus_mode = Control.FOCUS_NONE
	_recenter_button.custom_minimum_size = Vector2(112.0, 46.0)
	_recenter_button.pressed.connect(_on_recenter_pressed)
	add_child(_recenter_button)


func _refresh_visibility() -> void:
	if _hint_panel != null:
		_hint_panel.visible = (
			_portrait
			and _can_pan
			and _hint_allowed
			and not _hint_complete
			and not _hint_expired
		)
	if _recenter_button != null:
		_recenter_button.visible = _can_pan
		_recenter_button.disabled = not _interaction_enabled or _centered


func _on_recenter_pressed() -> void:
	if not recenter_enabled():
		return
	recenter_requested.emit()


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.is_echo():
		return
	if key.physical_keycode != KEY_R or not recenter_enabled():
		return
	_on_recenter_pressed()
	get_viewport().set_input_as_handled()


func _copy(key: StringName, fallback: String) -> String:
	var service := get_node_or_null("/root/I18n")
	if service != null and service.has_method("t"):
		return String(service.call("t", key, fallback))
	return fallback
