class_name BattleControls
extends Control

const GameTypographyType := preload("res://scripts/ui/game_typography.gd")
const Style := preload("res://scripts/ui/components/lunaris_ops_style.gd")
const DialogType := preload("res://scripts/ui/components/lunaris_dialog_sheet.gd")

## Pause/resume, speed cycle 1x/2x/4x, and resign. Every write remains on
## ticks_per_frame_scale or model.apply_action([&"resign"]); presentation never
## enters deterministic state.

const FONT_SIZE := GameTypographyType.BODY
const SPEED_CYCLE: Array[float] = [1.0, 2.0, 4.0]
const PAUSED_LABEL_MIN_WIDTH := 96.0

var model: BattleModel = null
var view: Node2D = null

var _pause_button: Button = null
var _speed_button: Button = null
var _resign_button: Button = null
var _paused_label: Label = null
var _controls_deck: PanelContainer = null
var _confirm: Control = null
var _confirm_dialog: Dictionary = {}
var _resume_scale: float = 1.0
var _pre_confirm_scale: float = 1.0
var _interaction_enabled := true
var _last_paused := false


func setup(battle_model: BattleModel, battle_view: Node2D) -> void:
	model = battle_model
	view = battle_view
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2.ZERO
	size = get_viewport().get_visible_rect().size
	_build_row()
	_build_confirm()


func set_interaction_enabled(enabled: bool) -> void:
	_interaction_enabled = enabled
	if _pause_button != null:
		_pause_button.disabled = not enabled
	if _speed_button != null:
		_speed_button.disabled = not enabled
	if _resign_button != null:
		_resign_button.disabled = not enabled or model.result != BattleModel.Result.RUNNING


func relayout() -> void:
	size = get_viewport().get_visible_rect().size
	if _controls_deck != null:
		_controls_deck.reset_size()
		var y := 98.0 if size.y > size.x else 64.0
		_controls_deck.position = Vector2(size.x - _controls_deck.get_combined_minimum_size().x - 16.0, y)


func _build_row() -> void:
	_controls_deck = PanelContainer.new()
	_controls_deck.name = "BattleCommandDeck"
	_controls_deck.mouse_filter = Control.MOUSE_FILTER_PASS
	Style.apply_panel(_controls_deck, &"hud")
	add_child(_controls_deck)
	var box := HBoxContainer.new()
	box.name = "ControlsBox"
	box.add_theme_constant_override(&"separation", 10)
	_controls_deck.add_child(box)
	_pause_button = _make_button("PauseButton", "PAUSE", &"secondary")
	_pause_button.pressed.connect(_on_pause_pressed)
	box.add_child(_pause_button)
	_speed_button = _make_button("SpeedButton", "1×", &"secondary")
	_speed_button.pressed.connect(_on_speed_pressed)
	box.add_child(_speed_button)
	_resign_button = _make_button("ResignButton", "RESIGN", &"danger")
	_resign_button.pressed.connect(_on_resign_pressed)
	box.add_child(_resign_button)
	_paused_label = Label.new()
	_paused_label.name = "PausedLabel"
	_paused_label.text = ""
	_paused_label.custom_minimum_size = Vector2(PAUSED_LABEL_MIN_WIDTH, 0)
	_paused_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	Style.apply_label(_paused_label, &"status")
	box.add_child(_paused_label)
	_controls_deck.reset_size()
	relayout()


func _build_confirm() -> void:
	_confirm_dialog = DialogType.create(
		self,
		"ResignConfirmLayer",
		"WITHDRAW FROM OPERATION?",
		"Withdrawal immediately seals this attempt as a defeat. Current deployment progress is not preserved.",
		"CONFIRM DEFEAT",
		"RETURN TO BATTLE",
	)
	_confirm = _confirm_dialog.get(&"overlay") as Control
	var panel := _confirm_dialog.get(&"panel") as PanelContainer
	panel.name = "ResignConfirm"
	var confirm := _confirm_dialog.get(&"confirm") as Button
	var cancel := _confirm_dialog.get(&"cancel") as Button
	confirm.name = "ConfirmResign"
	cancel.name = "CancelResign"
	Style.apply_button(confirm, &"danger")
	Style.apply_button(cancel, &"secondary")
	confirm.pressed.connect(_on_confirm_resign)
	cancel.pressed.connect(_on_cancel_resign)


## Main battle controls stay FOCUS_NONE so Space reaches the pause shortcut.
## Modal actions intentionally retain focus; Space then activates the safe
## focused Cancel action instead of leaking through to pause.
func _make_button(button_name: String, text: String, role: StringName) -> Button:
	var btn := Button.new()
	btn.name = button_name
	btn.text = text
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(76.0, 46.0)
	Style.apply_button(btn, role)
	return btn


func _current_scale() -> float:
	return float(view.get("ticks_per_frame_scale"))


func _set_scale(value: float) -> void:
	view.set("ticks_per_frame_scale", value)


func _process(_delta: float) -> void:
	if view == null or model == null:
		return
	var current := _current_scale()
	if current > 0.0:
		_resume_scale = current
	var paused := current == 0.0
	var running := model.result == BattleModel.Result.RUNNING
	_pause_button.text = "RESUME" if paused else "PAUSE"
	_paused_label.text = "PAUSED" if paused and not _confirm.visible else ""
	_speed_button.text = "%d×" % int(round(_resume_scale))
	_pause_button.disabled = not _interaction_enabled or not running
	_speed_button.disabled = not _interaction_enabled or not running
	_resign_button.disabled = not _interaction_enabled or not running
	if paused != _last_paused:
		Style.apply_button(_pause_button, &"selected" if paused else &"secondary")
		_last_paused = paused
		relayout()


func _unhandled_input(event: InputEvent) -> void:
	if not _interaction_enabled:
		return
	if _confirm.visible and event.is_action_pressed("ui_cancel"):
		_on_cancel_resign()
		get_viewport().set_input_as_handled()
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.is_echo():
		return
	if key.physical_keycode != KEY_SPACE or _confirm.visible:
		return
	_on_pause_pressed()
	get_viewport().set_input_as_handled()


func _on_pause_pressed() -> void:
	if not _interaction_enabled or model.result != BattleModel.Result.RUNNING:
		return
	if _current_scale() == 0.0:
		Sfx.play("menu_close")
		_set_scale(_resume_scale)
	else:
		Sfx.play("menu_open")
		_set_scale(0.0)


func _on_speed_pressed() -> void:
	if not _interaction_enabled:
		return
	Sfx.play("ui_click")
	var base := _current_scale()
	if base == 0.0:
		base = _resume_scale
	var idx := SPEED_CYCLE.find(base)
	var next: float = SPEED_CYCLE[(idx + 1) % SPEED_CYCLE.size()] if idx >= 0 else 1.0
	_set_scale(next)


func _on_resign_pressed() -> void:
	if not _interaction_enabled:
		return
	Sfx.play("menu_open")
	_pre_confirm_scale = _current_scale()
	_set_scale(0.0)
	DialogType.show_dialog(_confirm_dialog, _resign_button)


func _on_cancel_resign() -> void:
	Sfx.play("menu_close")
	DialogType.hide_dialog(_confirm_dialog)
	_set_scale(_pre_confirm_scale)


func _on_confirm_resign() -> void:
	Sfx.play("ui_confirm")
	DialogType.set_pending(_confirm_dialog, true, "WITHDRAWING…")
	model.apply_action([&"resign"])
	DialogType.set_pending(_confirm_dialog, false)
	DialogType.hide_dialog(_confirm_dialog)
	_set_scale(_pre_confirm_scale)
