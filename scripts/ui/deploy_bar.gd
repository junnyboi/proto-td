class_name DeployBar
extends Control

## Raw-input adapter for the deploy/retreat verbs (architecture rule 3: a thin
## adapter over apply_action, validated once per verb by deploy_flow.gd).
## Interaction (td-phase-2-3.md D21): press a slot -> drag with valid-cell
## highlights -> release on a cell -> facing chooser (4 arrows) -> click one
## -> deploy verb fires. Release on an invalid cell or ui_cancel/right-click
## cancels. Clicking an alive unit opens a chip with a Retreat button.
## Enabled state of every slot reads model.is_deployable (single source of
## truth); highlight queries read model.can_deploy_at (the verb's own
## validation, never a copy).

const FONT_SIZE := 32
const BAR_HEIGHT := 88.0
const CELL_PX := 64.0
const VALID_COLOR := Color(0.2, 0.9, 0.4, 0.4)
const INVALID_COLOR := Color(0.9, 0.2, 0.2, 0.5)

const FACING_BUTTONS := {
	UnitState.Facing.RIGHT: {"name": "FacingRight", "text": ">", "offset": Vector2i(1, 0)},
	UnitState.Facing.DOWN: {"name": "FacingDown", "text": "v", "offset": Vector2i(0, 1)},
	UnitState.Facing.LEFT: {"name": "FacingLeft", "text": "<", "offset": Vector2i(-1, 0)},
	UnitState.Facing.UP: {"name": "FacingUp", "text": "^", "offset": Vector2i(0, -1)},
}

var model: BattleModel = null
var view: Node2D = null

var _slots: Dictionary = {}
var _placement_op: StringName = &""
var _pending_cell := Vector2i(-1, -1)
var _pointer := Vector2.ZERO
var _highlight_root: Control = null
var _cursor_rect: ColorRect = null
var _facing_buttons: Dictionary = {}
var _retreat_chip: Button = null
var _retreat_unit_id: int = -1


## Call after add_child: the bar sizes itself from the viewport (a Control
## under a Node2D parent gets no anchor-based layout).
func setup(battle_model: BattleModel, battle_view: Node2D, op_defs: Dictionary) -> void:
	model = battle_model
	view = battle_view
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2.ZERO
	size = get_viewport().get_visible_rect().size
	_build_slots(op_defs)
	_build_overlays()


func _process(_delta: float) -> void:
	if model == null:
		return
	for op_id: StringName in _slots:
		var slot: Button = _slots[op_id]
		slot.disabled = not model.is_deployable(op_id)


func _input(event: InputEvent) -> void:
	# Placement drag: track the pointer from motion events (injected motion
	# never moves get_mouse_position) and end placement on left release.
	if _placement_op == &"":
		return
	if event is InputEventMouseMotion:
		_pointer = (event as InputEventMouseMotion).position
		_update_placement_hover()
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed and _pending_cell.x < 0:
			_pointer = mb.position
			_end_placement_drag()
		elif mb.button_index == MOUSE_BUTTON_RIGHT and not mb.pressed:
			_cancel_placement()
	elif event.is_action_pressed("ui_cancel"):
		_cancel_placement()


func _unhandled_input(event: InputEvent) -> void:
	# Idle-state grid clicks: select an alive unit -> retreat chip.
	if _placement_op != &"" or model == null:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
			_handle_grid_click(mb.position)


func _build_slots(op_defs: Dictionary) -> void:
	var box := HBoxContainer.new()
	box.name = "SlotBox"
	box.add_theme_constant_override("separation", 16)
	box.position = Vector2(16, size.y - BAR_HEIGHT)
	add_child(box)
	for op_id: StringName in model.squad:
		if not op_defs.has(op_id):
			continue
		var def: OperatorDef = op_defs[op_id]
		var slot := Button.new()
		slot.name = "Slot_%s" % op_id
		slot.text = "%s  %d DP" % [def.display_name, def.dp_cost]
		slot.add_theme_font_size_override("font_size", FONT_SIZE)
		slot.button_down.connect(_start_placement.bind(op_id))
		box.add_child(slot)
		_slots[op_id] = slot


func _build_overlays() -> void:
	_highlight_root = Control.new()
	_highlight_root.name = "Highlights"
	_highlight_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_highlight_root)
	_cursor_rect = _make_overlay_rect(INVALID_COLOR)
	_cursor_rect.name = "CursorRect"
	add_child(_cursor_rect)
	for facing: UnitState.Facing in FACING_BUTTONS:
		var spec: Dictionary = FACING_BUTTONS[facing]
		var btn := Button.new()
		btn.name = spec["name"]
		btn.text = spec["text"]
		btn.add_theme_font_size_override("font_size", FONT_SIZE)
		btn.visible = false
		btn.pressed.connect(_confirm_deploy.bind(facing))
		add_child(btn)
		_facing_buttons[facing] = btn
	_retreat_chip = Button.new()
	_retreat_chip.name = "RetreatChip"
	_retreat_chip.text = "Retreat"
	_retreat_chip.add_theme_font_size_override("font_size", FONT_SIZE)
	_retreat_chip.visible = false
	_retreat_chip.pressed.connect(_confirm_retreat)
	add_child(_retreat_chip)


func _make_overlay_rect(color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.color = color
	rect.size = Vector2.ONE * CELL_PX
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.visible = false
	return rect


func _start_placement(op_id: StringName) -> void:
	_hide_retreat_chip()
	_placement_op = op_id
	_pending_cell = Vector2i(-1, -1)
	var grid_size: Vector2i = model.stage.grid_size()
	for y: int in grid_size.y:
		for x: int in grid_size.x:
			var cell := Vector2i(x, y)
			if model.can_deploy_at(op_id, cell):
				var rect := _make_overlay_rect(VALID_COLOR)
				rect.visible = true
				rect.position = view.call("cell_center", cell) - rect.size * 0.5
				_highlight_root.add_child(rect)


func _update_placement_hover() -> void:
	if _pending_cell.x >= 0:
		return
	var cell: Vector2i = view.call("cell_at", _pointer)
	var valid: bool = model.can_deploy_at(_placement_op, cell)
	_cursor_rect.color = VALID_COLOR if valid else INVALID_COLOR
	_cursor_rect.position = view.call("cell_center", cell) - _cursor_rect.size * 0.5
	_cursor_rect.visible = true


func _end_placement_drag() -> void:
	var cell: Vector2i = view.call("cell_at", _pointer)
	if not model.can_deploy_at(_placement_op, cell):
		_cancel_placement()
		return
	_pending_cell = cell
	_cursor_rect.visible = false
	for facing: UnitState.Facing in _facing_buttons:
		var spec: Dictionary = FACING_BUTTONS[facing]
		var btn: Button = _facing_buttons[facing]
		var center: Vector2 = view.call("cell_center", cell + (spec["offset"] as Vector2i))
		btn.position = center - btn.get_combined_minimum_size() * 0.5
		btn.visible = true


func _confirm_deploy(facing: UnitState.Facing) -> void:
	if _pending_cell.x >= 0:
		model.apply_action([&"deploy", _placement_op, _pending_cell, int(facing)])
	_cancel_placement()


func _cancel_placement() -> void:
	_placement_op = &""
	_pending_cell = Vector2i(-1, -1)
	_cursor_rect.visible = false
	for facing: UnitState.Facing in _facing_buttons:
		(_facing_buttons[facing] as Button).visible = false
	for child: Node in _highlight_root.get_children():
		child.queue_free()


func _handle_grid_click(screen_pos: Vector2) -> void:
	var cell: Vector2i = view.call("cell_at", screen_pos)
	var unit: UnitState = model.alive_unit_at(cell)
	if unit == null:
		_hide_retreat_chip()
		return
	# Skill-trigger adapter (Phase 5): clicking a unit whose SP is full fires
	# its skill; the retreat chip only opens while the skill is not ready.
	if unit.sp_cost > 0 and unit.sp == unit.sp_cost:
		model.apply_action([&"trigger_skill", unit.id])
		_hide_retreat_chip()
		return
	_retreat_unit_id = unit.id
	var center: Vector2 = view.call("cell_center", cell)
	_retreat_chip.position = center + Vector2(-_retreat_chip.get_combined_minimum_size().x * 0.5, -96)
	_retreat_chip.visible = true


func _confirm_retreat() -> void:
	if _retreat_unit_id >= 0:
		model.apply_action([&"retreat", _retreat_unit_id])
	_hide_retreat_chip()


func _hide_retreat_chip() -> void:
	_retreat_unit_id = -1
	_retreat_chip.visible = false
