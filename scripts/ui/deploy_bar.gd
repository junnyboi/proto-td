class_name DeployBar
extends Control

signal placement_started(deployment_id: StringName)
signal placement_rejected(deployment_id: StringName, cell: Vector2i)
signal facing_requested(deployment_id: StringName, cell: Vector2i)
signal deployment_committed(deployment_id: StringName, cell: Vector2i, facing: int)

## Raw-input adapter for the deploy/retreat/place_trap/mend verbs (architecture
## rule 3: a thin adapter over apply_action, validated once per verb by
## deploy_flow.gd / trap_flow.gd).
## highlights -> release on a cell -> facing chooser (4 arrows) -> click one
## -> deploy verb fires. Trap slots share the drag but place on release
## directly (traps have no facing) under AMBER highlights, distinct from the
## ui_cancel/right-click cancels. Clicking an alive unit opens a chip with a
## Retreat button. Enabled state of every slot reads model.is_deployable /
## model.is_trap_placeable (single source of truth); highlight queries read
## model.can_deploy_at / model.can_place_trap_at (the verb's own validation,
## never a copy).

const HealingRulesScript := preload("res://sim/healing_rules.gd")
const SELECTION_RING_SCRIPT := preload("res://scripts/view/selection_ring.gd")
const GameTypographyType := preload("res://scripts/ui/game_typography.gd")

const FONT_SIZE := GameTypographyType.BODY
const BAR_HEIGHT := 88.0
const VALID_COLOR := Color(0.2, 0.9, 0.4, 0.4)
const INVALID_COLOR := Color(0.9, 0.2, 0.2, 0.5)
const TRAP_VALID_COLOR := Color(0.95, 0.71, 0.2, 0.45)
const HEAL_VALID_COLOR := Color(0.65, 0.94, 0.44, 0.5)
const FACING_BUTTON_SIZE := Vector2(56.0, 56.0)
const FACING_BUTTON_GAP := 12.0
const FACING_SAFE_MARGIN := 12.0
const FACING_SAFE_TOP := 104.0
const FACING_BUTTON_Z := 15

const FACING_BUTTONS := {
	UnitState.Facing.RIGHT: {"name": "FacingRight", "text": "↘", "slot": Vector2i(1, 1)},
	UnitState.Facing.DOWN: {"name": "FacingDown", "text": "↙", "slot": Vector2i(0, 1)},
	UnitState.Facing.LEFT: {"name": "FacingLeft", "text": "↖", "slot": Vector2i(0, 0)},
	UnitState.Facing.UP: {"name": "FacingUp", "text": "↗", "slot": Vector2i(1, 0)},
}

var model: BattleModel = null
var view: Node2D = null

var _slots: Dictionary = {}
var _trap_slots: Dictionary = {}
var _op_defs: Dictionary = {}
var _trap_defs: Dictionary = {}
var _ticket_rows: Dictionary = {}
var _slot_box: GridContainer = null
var _placement_op: StringName = &""
var _placement_trap: StringName = &""
var _pending_cell := Vector2i(-1, -1)
var _pointer := Vector2.ZERO
var _highlight_root: Control = null
var _cursor_rect: Polygon2D = null
var _facing_buttons: Dictionary = {}
var _retreat_chip: Button = null
var _retreat_unit_id: int = -1
var _heal_source_unit_id: int = -1
var _heal_cursor: Polygon2D = null
var _selected_unit_id: int = -1
var _selection_ring: Node2D = null
var _operator_interaction_enabled := true


## Call after add_child: the bar sizes itself from the viewport (a Control
## under a Node2D parent gets no anchor-based layout).
func setup(
	battle_model: BattleModel,
	battle_view: Node2D,
	op_defs: Dictionary,
	trap_defs: Dictionary = {},
) -> void:
	model = battle_model
	view = battle_view
	_op_defs = op_defs
	_trap_defs = trap_defs
	var ticket: Dictionary = battle_model.snapshot().get("ticket", {})
	for row: Dictionary in ticket.get("squad", []):
		_ticket_rows[StringName(row["battle_id"])] = row.duplicate(true)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2.ZERO
	size = get_viewport().get_visible_rect().size
	_build_slots(_op_defs)
	_build_overlays()


func is_mend_targeting() -> bool:
	return _heal_source_unit_id >= 0


func set_operator_interaction_enabled(enabled: bool) -> void:
	_operator_interaction_enabled = enabled


func first_deployment_id() -> StringName:
	var ids := _deployment_ids()
	return ids[0] if not ids.is_empty() else &""


func slot_screen_rect(deployment_id: StringName) -> Rect2:
	var slot := _slots.get(deployment_id) as Button
	return slot.get_global_rect() if slot != null else Rect2()


func is_facing_pending() -> bool:
	return _pending_cell.x >= 0


func facing_button_screen_rect(facing: int) -> Rect2:
	var button := _facing_buttons.get(facing) as Button
	return button.get_global_rect() if button != null and button.visible else Rect2()


## Dynamic canvas fit: CALLED BY battle_view._relayout() after the grid
## scale recomputes (P14 — a self-owned size_changed listener raced the
## view's recompute and re-derived footprints from the STALE scale).
## Mid-placement overlays re-derive from the live grid scale.
func relayout() -> void:
	size = get_viewport().get_visible_rect().size
	if _slot_box != null:
		_layout_slot_box()
	if _cursor_rect != null:
		_cursor_rect.polygon = IsoProjection.face_polygon(view.call("grid_scale"))
		if _cursor_rect.visible:
			_update_placement_hover()
	if _heal_cursor != null:
		_heal_cursor.polygon = IsoProjection.face_polygon(view.call("grid_scale"))
		if _heal_cursor.visible:
			_update_heal_hover()
	if _placement_op != &"" or _placement_trap != &"":
		for child: Node in _highlight_root.get_children():
			child.queue_free()
		_show_valid_highlights()
	if _pending_cell.x >= 0:
		_layout_facing_buttons(_pending_cell)
	if _heal_source_unit_id >= 0:
		_show_heal_highlights()
	_update_selection_ring()


func _process(_delta: float) -> void:
	if model == null:
		return
	if Input.is_action_just_pressed("ui_cancel"):
		if is_mend_targeting():
			_cancel_heal_targeting()
		elif _placement_op != &"" or _placement_trap != &"":
			_cancel_placement()
	# changes so granted operators get slots
	if _slots.size() != _deployment_ids().size():
		_rebuild_slots()
	_update_selection_ring()
	for op_id: StringName in _slots:
		var slot: Button = _slots[op_id]
		slot.disabled = not _operator_interaction_enabled or not model.is_deployable(op_id)
	for trap_id: StringName in _trap_slots:
		var slot: Button = _trap_slots[trap_id]
		slot.disabled = not _operator_interaction_enabled or not model.is_trap_placeable(trap_id)


func _input(event: InputEvent) -> void:
	if _heal_source_unit_id >= 0:
		if event is InputEventMouseMotion:
			_pointer = (event as InputEventMouseMotion).position
			_update_heal_hover()
		elif event is InputEventMouseButton:
			var heal_button := event as InputEventMouseButton
			if heal_button.button_index == MOUSE_BUTTON_RIGHT and not heal_button.pressed:
				_cancel_heal_targeting()
		elif event.is_action_pressed("ui_cancel"):
			_cancel_heal_targeting()
		return
	# Placement drag: track the pointer from motion events (injected motion
	# never moves get_mouse_position) and end placement on left release.
	if _placement_op == &"" and _placement_trap == &"":
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
	if _placement_op != &"" or _placement_trap != &"" or model == null:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
			if bool(view.call("consume_map_primary_click_suppression")):
				return
			_handle_grid_click(mb.position)


func _rebuild_slots() -> void:
	if _slot_box != null:
		_slot_box.queue_free()
	_slots.clear()
	_trap_slots.clear()
	_build_slots(_op_defs)


func _build_slots(op_defs: Dictionary) -> void:
	var box := GridContainer.new()
	box.name = "SlotBox"
	box.add_theme_constant_override("h_separation", 16)
	box.add_theme_constant_override("v_separation", 8)
	add_child(box)
	_slot_box = box
	for deployment_id: StringName in _deployment_ids():
		var row: Dictionary = _ticket_rows.get(deployment_id, {})
		var op_id := StringName(row.get("operator_def_id", deployment_id))
		if not op_defs.has(op_id):
			continue
		var def: OperatorDef = op_defs[op_id]
		var slot := Button.new()
		slot.name = "Slot_%s" % deployment_id
		var dp_cost := def.dp_cost
		var sprite_id := def.sprite_id
		var identity_suffix := ""
		if not row.is_empty():
			dp_cost = int(row["combat_spec"]["dp_cost"])
			sprite_id = StringName(row["visual_spec"]["sprite_id"])
			identity_suffix = " %d" % (int(row["slot_index"]) + 1)
		slot.text = "%s%s  %d DP" % [def.display_name, identity_suffix, dp_cost]
		slot.custom_minimum_size.y = 52.0
		slot.icon = Art.texture(sprite_id, 0)
		slot.add_theme_font_size_override("font_size", FONT_SIZE)
		slot.button_down.connect(_start_placement.bind(deployment_id))
		box.add_child(slot)
		_slots[deployment_id] = slot
	# String-copy sort (P14): StringName sort is interning-ordered — slot
	# order would vary across launches
	var trap_names: Array = []
	for key: StringName in _trap_defs:
		trap_names.append(String(key))
	trap_names.sort()
	for trap_name: String in trap_names:
		var trap_id := StringName(trap_name)
		var def: TrapDef = _trap_defs[trap_id]
		var slot := Button.new()
		slot.name = "Slot_%s" % trap_id
		slot.text = "%s  %d DP" % [def.display_name, def.dp_cost]
		slot.custom_minimum_size.y = 52.0
		slot.icon = Art.texture(
			&"trap_tar" if def.trigger == TrapDef.Trigger.CELL_AURA else &"trap_spike_armed"
		)
		slot.add_theme_font_size_override("font_size", FONT_SIZE)
		slot.button_down.connect(_start_trap_placement.bind(trap_id))
		box.add_child(slot)
		_trap_slots[trap_id] = slot
	_layout_slot_box()


func _deployment_ids() -> Array[StringName]:
	if not model.battle_squad.is_empty():
		return model.battle_squad.duplicate()
	return model.squad.duplicate()


func _layout_slot_box() -> void:
	if _slot_box == null:
		return
	if size.x < size.y:
		_slot_box.columns = 1
	elif size.x < 1200.0:
		_slot_box.columns = 2
	elif size.x < 1600.0:
		_slot_box.columns = 3
	else:
		_slot_box.columns = 4
	_slot_box.reset_size()
	var y := size.y - _slot_box.get_combined_minimum_size().y - 8.0
	_slot_box.position = Vector2(16.0, y)


func _build_overlays() -> void:
	_highlight_root = Control.new()
	_highlight_root.name = "Highlights"
	_highlight_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_highlight_root)
	_cursor_rect = _make_overlay_rect(INVALID_COLOR)
	_cursor_rect.name = "CursorRect"
	add_child(_cursor_rect)
	_heal_cursor = _make_overlay_rect(HEAL_VALID_COLOR)
	_heal_cursor.name = "HealTargetCursor"
	add_child(_heal_cursor)
	for facing: UnitState.Facing in FACING_BUTTONS:
		var spec: Dictionary = FACING_BUTTONS[facing]
		var btn := Button.new()
		btn.name = spec["name"]
		btn.text = spec["text"]
		btn.custom_minimum_size = FACING_BUTTON_SIZE
		btn.add_theme_font_size_override("font_size", FONT_SIZE)
		btn.z_index = FACING_BUTTON_Z
		btn.visible = false
		btn.pressed.connect(_confirm_deploy.bind(facing))
		add_child(btn)
		_facing_buttons[facing] = btn
	_retreat_chip = Button.new()
	_retreat_chip.name = "RetreatChip"
	_retreat_chip.text = "Retreat"
	_retreat_chip.custom_minimum_size = Vector2(88.0, 52.0)
	_retreat_chip.add_theme_font_size_override("font_size", FONT_SIZE)
	_retreat_chip.visible = false
	_retreat_chip.pressed.connect(_confirm_retreat)
	add_child(_retreat_chip)
	_selection_ring = SELECTION_RING_SCRIPT.new()
	_selection_ring.name = "SelectionRing"
	_selection_ring.visible = false
	_selection_ring.z_index = -1
	add_child(_selection_ring)


## Footprints are origin-centered face diamonds (P12.2) sized by the live
## grid scale (dynamic canvas fit); position them at cell_center directly.
func _make_overlay_rect(color: Color) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.color = color
	poly.polygon = IsoProjection.face_polygon(view.call("grid_scale"))
	poly.visible = false
	return poly


func _start_placement(op_id: StringName) -> void:
	_cancel_heal_targeting()
	_hide_retreat_chip()
	_placement_op = op_id
	_pending_cell = Vector2i(-1, -1)
	Sfx.play("operator_select")
	_show_valid_highlights()
	view.call("deploy_drag_started")
	placement_started.emit(op_id)


func _start_trap_placement(trap_id: StringName) -> void:
	_cancel_heal_targeting()
	_hide_retreat_chip()
	_placement_trap = trap_id
	_pending_cell = Vector2i(-1, -1)
	_show_valid_highlights()
	view.call("deploy_drag_started")


## One highlight pass for both placement modes; the query is the verb's own
## validation (can_deploy_at / can_place_trap_at), never a copy.
func _show_valid_highlights() -> void:
	var grid_size: Vector2i = model.stage.grid_size()
	for y: int in grid_size.y:
		for x: int in grid_size.x:
			var cell := Vector2i(x, y)
			if _placement_valid_at(cell):
				var rect := _make_overlay_rect(_valid_color())
				rect.visible = true
				rect.position = view.call("cell_center", cell)
				_highlight_root.add_child(rect)


func _placement_valid_at(cell: Vector2i) -> bool:
	if _placement_trap != &"":
		return model.can_place_trap_at(_placement_trap, cell)
	return model.can_deploy_at(_placement_op, cell)


func _valid_color() -> Color:
	return TRAP_VALID_COLOR if _placement_trap != &"" else VALID_COLOR


func _update_placement_hover() -> void:
	if _pending_cell.x >= 0:
		return
	var cell: Vector2i = view.call("cell_at", _pointer)
	_cursor_rect.color = _valid_color() if _placement_valid_at(cell) else INVALID_COLOR
	_cursor_rect.position = view.call("cell_center", cell)
	_cursor_rect.visible = true


func _end_placement_drag() -> void:
	var cell: Vector2i = view.call("cell_at", _pointer)
	if not _placement_valid_at(cell):
		Sfx.play("action_reject")
		if _placement_op != &"":
			placement_rejected.emit(_placement_op, cell)
		_cancel_placement()
		return
	if _placement_trap != &"":
		# traps have no facing: the release IS the placement
		if not model.apply_action([&"place_trap", _placement_trap, cell]):
			Sfx.play("action_reject")
		_cancel_placement()
		return
	_pending_cell = cell
	_cursor_rect.visible = false
	Sfx.play("placement_ready")
	facing_requested.emit(_placement_op, cell)
	# the slowdown HOLDS through the facing chooser (L7 verdict 2026-08-11:
	# full-speed enemies charging while the player aims felt punishing);
	# _confirm_deploy / _cancel_placement restore normal speed
	_layout_facing_buttons(cell)
	for facing: UnitState.Facing in _facing_buttons:
		var btn: Button = _facing_buttons[facing]
		btn.visible = true


## Model cardinal facings project to screen diagonals. Keep all four controls
## in one fixed-size screen-space cluster instead of scattering them across
## full neighboring cells (which scales with camera zoom and collides with
## overlays). Edge cells translate the cluster as one rigid unit.
func _layout_facing_buttons(cell: Vector2i) -> void:
	var button_size := FACING_BUTTON_SIZE
	for facing: UnitState.Facing in _facing_buttons:
		var minimum: Vector2 = (_facing_buttons[facing] as Button).get_combined_minimum_size()
		button_size.x = maxf(button_size.x, minimum.x)
		button_size.y = maxf(button_size.y, minimum.y)
	var cluster_size := button_size * 2.0 + Vector2.ONE * FACING_BUTTON_GAP
	var desired_origin: Vector2 = view.call("cell_center", cell) - cluster_size * 0.5
	var safe_min := Vector2(FACING_SAFE_MARGIN, FACING_SAFE_TOP)
	var safe_max := Vector2(
		maxf(safe_min.x, size.x - FACING_SAFE_MARGIN - cluster_size.x),
		maxf(safe_min.y, size.y - BAR_HEIGHT - FACING_SAFE_MARGIN - cluster_size.y),
	)
	var cluster_origin := Vector2(
		clampf(desired_origin.x, safe_min.x, safe_max.x),
		clampf(desired_origin.y, safe_min.y, safe_max.y),
	)
	for facing: UnitState.Facing in _facing_buttons:
		var spec: Dictionary = FACING_BUTTONS[facing]
		var btn: Button = _facing_buttons[facing]
		var slot: Vector2i = spec["slot"]
		btn.size = button_size
		btn.position = (
			cluster_origin + Vector2(slot) * (button_size + Vector2.ONE * FACING_BUTTON_GAP)
		)


func _confirm_deploy(facing: UnitState.Facing) -> void:
	if _pending_cell.x >= 0:
		var deployment_id := _placement_op
		var cell := _pending_cell
		if model.apply_action([&"deploy", deployment_id, cell, int(facing)]):
			deployment_committed.emit(deployment_id, cell, int(facing))
		else:
			Sfx.play("action_reject")
			placement_rejected.emit(deployment_id, cell)
	_cancel_placement()


func _cancel_placement() -> void:
	view.call("deploy_drag_ended")
	_placement_op = &""
	_placement_trap = &""
	_pending_cell = Vector2i(-1, -1)
	_cursor_rect.visible = false
	for facing: UnitState.Facing in _facing_buttons:
		(_facing_buttons[facing] as Button).visible = false
	for child: Node in _highlight_root.get_children():
		child.queue_free()


func _handle_grid_click(screen_pos: Vector2) -> void:
	var cell: Vector2i = view.call("cell_at", screen_pos)
	var unit: UnitState = model.alive_unit_at(cell)
	if _heal_source_unit_id >= 0:
		if unit == null or not HealingRulesScript.is_valid(model, _heal_source_unit_id, unit.id):
			return
		model.apply_action([&"mend", _heal_source_unit_id, unit.id])
		_cancel_heal_targeting()
		_hide_retreat_chip()
		return
	if unit == null:
		_select_unit(-1)
		_hide_retreat_chip()
		return
	_select_unit(unit.id)
	# its skill; the retreat chip only opens while the skill is not ready.
	# Readiness comes from the verb's own validator (rule 7, P14).
	if unit.is_skill_ready():
		if unit.skill_effect == SkillDef.Effect.HEAL_TARGET:
			_begin_heal_targeting(unit)
		else:
			model.apply_action([&"trigger_skill", unit.id])
		_hide_retreat_chip()
		return
	_retreat_unit_id = unit.id
	var center: Vector2 = view.call("cell_center", cell)
	_retreat_chip.position = (
		center + Vector2(-_retreat_chip.get_combined_minimum_size().x * 0.5, -96)
	)
	_retreat_chip.visible = true


func _confirm_retreat() -> void:
	if _retreat_unit_id >= 0:
		model.apply_action([&"retreat", _retreat_unit_id])
		_select_unit(-1)
	_hide_retreat_chip()


func _select_unit(unit_id: int) -> void:
	_selected_unit_id = unit_id
	_update_selection_ring()


func _update_selection_ring() -> void:
	if _selection_ring == null or model == null or view == null:
		return
	if _selected_unit_id < 0:
		_selection_ring.visible = false
		return
	var unit := model.unit_by_id(_selected_unit_id)
	if unit == null or not unit.alive:
		_selected_unit_id = -1
		_selection_ring.visible = false
		return
	_selection_ring.position = view.call("cell_center", unit.cell)
	_selection_ring.scale = Vector2.ONE * float(view.call("grid_scale"))
	_selection_ring.visible = true


func _hide_retreat_chip() -> void:
	_retreat_unit_id = -1
	_retreat_chip.visible = false


func _begin_heal_targeting(healer: UnitState) -> void:
	_heal_source_unit_id = healer.id
	_pointer = view.call("cell_center", healer.cell)
	_heal_cursor.position = _pointer
	_heal_cursor.color = HEAL_VALID_COLOR
	_heal_cursor.visible = true
	_show_heal_highlights()


func _show_heal_highlights() -> void:
	for child: Node in _highlight_root.get_children():
		child.queue_free()
	for target: UnitState in model.units:
		if not HealingRulesScript.is_valid(model, _heal_source_unit_id, target.id):
			continue
		var rect := _make_overlay_rect(HEAL_VALID_COLOR)
		rect.name = "HealTarget_%d" % target.id
		rect.visible = true
		rect.position = view.call("cell_center", target.cell)
		_highlight_root.add_child(rect)


func _update_heal_hover() -> void:
	var cell: Vector2i = view.call("cell_at", _pointer)
	var target := model.alive_unit_at(cell)
	var valid := (
		target != null and HealingRulesScript.is_valid(model, _heal_source_unit_id, target.id)
	)
	_heal_cursor.color = HEAL_VALID_COLOR if valid else INVALID_COLOR
	_heal_cursor.position = view.call("cell_center", cell)


func _cancel_heal_targeting() -> void:
	if _heal_source_unit_id < 0:
		return
	_heal_source_unit_id = -1
	if _heal_cursor != null:
		_heal_cursor.visible = false
	for child: Node in _highlight_root.get_children():
		child.queue_free()
