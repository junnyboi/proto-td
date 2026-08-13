class_name BattleControls
extends Control

## Phase 13b (td-phase-13.md §4): always-visible in-battle QoL controls —
## pause/resume, speed cycle 1x/2x/4x, resign behind a code-built confirm
## panel (never a native ConfirmationDialog: subwindows are a harness trap).
## UI over the verbs (rule 5): every write goes through the view's
## ticks_per_frame_scale seam or model.apply_action([&"resign"]) — the same
## seams the debug overlay, scenarios, and bots drive. Button labels
## re-derive from the LIVE scale each frame, so direct seam writes (debug
## overlay, scenarios) never desync the display. Space toggles pause by
## physical keycode, the debug.gd F12 precedent — the registered
## battle_pause action does not match synthetic device-4242 keys (probed,
## deviation D1).

const FONT_SIZE := 24
const REPORT_FONT_SIZE := 32
const REPORT_MAX_WIDTH := 720.0
const REPORT_SIDE_MARGIN := 16.0
const REPORT_TOP := 116.0
const SPEED_CYCLE: Array[float] = [1.0, 2.0, 4.0]
const PAUSED_LABEL_MIN_WIDTH := 130.0  # fixed slot: no row re-layout on toggle

var model: BattleModel = null
var view: Node2D = null

var _pause_button: Button = null
var _speed_button: Button = null
var _resign_button: Button = null
var _paused_label: Label = null
var _readiness_report: Label = null
var _confirm: PanelContainer = null
var _resume_scale: float = 1.0
var _pre_confirm_scale: float = 1.0


func setup(battle_model: BattleModel, battle_view: Node2D) -> void:
	model = battle_model
	view = battle_view
	# Control under a Node2D: no anchor layout — explicit viewport sizing
	# (CLAUDE.md ban list), same pattern as the deploy/spell bars
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2.ZERO
	size = get_viewport().get_visible_rect().size
	_build_row()
	_build_readiness_report()
	_build_confirm()


## Dynamic canvas fit (P14): keep the strip pinned top-right and the
## confirm panel centered; called by battle_view._relayout() (one resize
## owner — self-owned listeners raced the grid recompute).
func relayout() -> void:
	size = get_viewport().get_visible_rect().size
	var box := get_node_or_null("ControlsBox") as HBoxContainer
	if box != null:
		box.position = Vector2(size.x - box.get_combined_minimum_size().x - 16.0, 64.0)
	if _readiness_report != null:
		_layout_readiness_report()
	if _confirm != null and _confirm.visible:
		_confirm.position = (size - _confirm.size) * 0.5


func _build_row() -> void:
	var box := HBoxContainer.new()
	box.name = "ControlsBox"
	box.add_theme_constant_override("separation", 12)
	add_child(box)
	_pause_button = _make_button("PauseButton", "II")
	_pause_button.pressed.connect(_on_pause_pressed)
	box.add_child(_pause_button)
	_speed_button = _make_button("SpeedButton", "1x")
	_speed_button.pressed.connect(_on_speed_pressed)
	box.add_child(_speed_button)
	_resign_button = _make_button("ResignButton", "Resign")
	_resign_button.pressed.connect(_on_resign_pressed)
	box.add_child(_resign_button)
	_paused_label = Label.new()
	_paused_label.name = "PausedLabel"
	_paused_label.text = ""
	_paused_label.custom_minimum_size = Vector2(PAUSED_LABEL_MIN_WIDTH, 0)
	_paused_label.add_theme_font_size_override("font_size", FONT_SIZE)
	_paused_label.add_theme_color_override("font_color", Color("f4b41b"))
	box.add_child(_paused_label)
	# right-aligned strip BELOW the spell bar (as-built D5: top-center is NOT
	# free — the HUD status line reaches past center-x once tick/result text
	# grows, and the R4b shot caught the overlap); the box knows its width
	# only after buttons exist
	box.reset_size()
	box.position = Vector2(size.x - box.get_combined_minimum_size().x - 16.0, 64.0)


func _build_readiness_report() -> void:
	_readiness_report = Label.new()
	_readiness_report.name = "SkillReadinessReport"
	_readiness_report.text = ""
	_readiness_report.add_theme_font_size_override("font_size", REPORT_FONT_SIZE)
	_readiness_report.add_theme_color_override("font_color", Color("5dc8d3"))
	_readiness_report.add_theme_color_override("font_shadow_color", Color("111827"))
	_readiness_report.add_theme_constant_override("shadow_offset_x", 2)
	_readiness_report.add_theme_constant_override("shadow_offset_y", 2)
	_readiness_report.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_readiness_report.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_readiness_report)
	_layout_readiness_report()


func _layout_readiness_report() -> void:
	var report_width := minf(REPORT_MAX_WIDTH, maxf(0.0, size.x - REPORT_SIDE_MARGIN * 2.0))
	_readiness_report.size = Vector2(report_width, 44.0)
	_readiness_report.position = Vector2(
		size.x - REPORT_SIDE_MARGIN - report_width,
		REPORT_TOP,
	)


func _build_confirm() -> void:
	_confirm = PanelContainer.new()
	_confirm.name = "ResignConfirm"
	_confirm.visible = false
	add_child(_confirm)
	var margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 24)
	_confirm.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)
	var question := Label.new()
	question.name = "ResignQuestion"
	question.text = "Resign this battle?"
	question.add_theme_font_size_override("font_size", 32)
	question.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(question)
	var note := Label.new()
	note.text = "Counts as a defeat."
	note.add_theme_font_size_override("font_size", FONT_SIZE)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(note)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(row)
	var confirm := _make_button("ConfirmResign", "Resign")
	confirm.pressed.connect(_on_confirm_resign)
	row.add_child(confirm)
	var cancel := _make_button("CancelResign", "Cancel")
	cancel.pressed.connect(_on_cancel_resign)
	row.add_child(cancel)


## FOCUS_NONE on every button (incl. the confirm pair): Space activates the
## focused Control as GUI input before _unhandled_input ever sees it.
func _make_button(button_name: String, text: String) -> Button:
	var btn := Button.new()
	btn.name = button_name
	btn.text = text
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(44.0, 44.0)
	btn.add_theme_font_size_override("font_size", FONT_SIZE)
	return btn


func _current_scale() -> float:
	return float(view.get("ticks_per_frame_scale"))


func _set_scale(value: float) -> void:
	view.set("ticks_per_frame_scale", value)


## Display derives from the live seam value every frame — never written back.
func _process(_delta: float) -> void:
	if view == null or model == null:
		return
	var current := _current_scale()
	if current > 0.0:
		_resume_scale = current
	var paused := current == 0.0
	_pause_button.text = ">" if paused else "II"
	_paused_label.text = "PAUSED" if paused and not _confirm.visible else ""
	_speed_button.text = "%dx" % int(round(_resume_scale))
	_resign_button.disabled = model.result != BattleModel.Result.RUNNING
	_refresh_readiness_report()


func _refresh_readiness_report() -> void:
	if _readiness_report == null or model.stage.id != &"s1":
		return
	var ready_name := ""
	for unit: UnitState in model.units:
		if not unit.is_skill_ready():
			continue
		var definition := load("res://data/operators/%s.tres" % unit.op_id) as OperatorDef
		ready_name = definition.display_name if definition != null else String(unit.op_id)
		break
	_readiness_report.text = "%s — SKILL READY" % ready_name if not ready_name.is_empty() else ""


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.is_echo():
		return
	if key.physical_keycode != KEY_SPACE:
		return
	if _confirm.visible:
		return
	_on_pause_pressed()
	get_viewport().set_input_as_handled()


func _on_pause_pressed() -> void:
	Sfx.play("ui_click")
	if _current_scale() == 0.0:
		_set_scale(_resume_scale)
	else:
		_set_scale(0.0)


## Cycles 1x -> 2x -> 4x -> 1x; while paused it sets the new speed AND
## unpauses (one less stuck state). A seam-written off-cycle value (e.g. a
## scenario's 8x) cycles back to 1x.
func _on_speed_pressed() -> void:
	Sfx.play("ui_click")
	var base := _current_scale()
	if base == 0.0:
		base = _resume_scale
	var idx := SPEED_CYCLE.find(base)
	var next: float = SPEED_CYCLE[(idx + 1) % SPEED_CYCLE.size()] if idx >= 0 else 1.0
	_set_scale(next)


## Opening the confirm forces pause; Cancel restores the prior scale.
func _on_resign_pressed() -> void:
	Sfx.play("ui_click")
	_pre_confirm_scale = _current_scale()
	_set_scale(0.0)
	_confirm.visible = true
	_confirm.reset_size()
	_confirm.position = (size - _confirm.size) * 0.5


func _on_cancel_resign() -> void:
	Sfx.play("ui_click")
	_confirm.visible = false
	_set_scale(_pre_confirm_scale)


func _on_confirm_resign() -> void:
	Sfx.play("ui_click")
	_confirm.visible = false
	model.apply_action([&"resign"])
	_set_scale(_pre_confirm_scale)
