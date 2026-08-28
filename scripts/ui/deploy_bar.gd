class_name DeployBar
extends Control

const UI_COPY := preload("res://scripts/ui/components/ui_copy.gd")

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
const Style := preload("res://scripts/ui/components/lunaris_ops_style.gd")
const StagingSkinType := preload("res://scripts/ui/components/staging_skin.gd")

const FONT_SIZE := GameTypographyType.DETAIL
const BAR_HEIGHT := 124.0
const SAFE_MARGIN := 16.0
const DECK_PADDING := 24.0
const SLOT_GAP := 12.0
const SLOT_TARGET_WIDTH := 220.0
const SLOT_TARGET_HEIGHT := 76.0
const LANDSCAPE_DECK_MAX_WIDTH := 1360.0
const SHORT_LANDSCAPE_DECK_MAX_WIDTH := 1240.0
const FIRST_SLOT_CONTENT_INSET := 12.0
const VALID_COLOR := Color(0.2, 0.9, 0.4, 0.4)
const INVALID_COLOR := Color(0.9, 0.2, 0.2, 0.5)
const TRAP_VALID_COLOR := Color(0.95, 0.71, 0.2, 0.45)
const HEAL_VALID_COLOR := Color(0.65, 0.94, 0.44, 0.5)
const FACING_BUTTON_SIZE := Vector2(64.0, 64.0)
const FACING_BUTTON_GAP := 12.0
const FACING_SAFE_MARGIN := 12.0
const FACING_SAFE_TOP := 104.0
const FACING_BUTTON_Z := 15
const FACING_ICON_INSET := 6.0
const FACING_BOUNCE_AMPLITUDE := 4.5
const FACING_PULSE_AMPLITUDE := 0.04
const FACING_ANIMATION_PERIOD := 0.9

const FACING_BUTTONS := {
	UnitState.Facing.RIGHT: {"name": "FacingRight", "slot": Vector2i(1, 1)},
	UnitState.Facing.DOWN: {"name": "FacingDown", "slot": Vector2i(0, 1)},
	UnitState.Facing.LEFT: {"name": "FacingLeft", "slot": Vector2i(0, 0)},
	UnitState.Facing.UP: {"name": "FacingUp", "slot": Vector2i(1, 0)},
}

const FACING_DIRECTIONS := {
	UnitState.Facing.RIGHT: Vector2(0.70710678, 0.70710678),
	UnitState.Facing.DOWN: Vector2(-0.70710678, 0.70710678),
	UnitState.Facing.LEFT: Vector2(-0.70710678, -0.70710678),
	UnitState.Facing.UP: Vector2(0.70710678, -0.70710678),
}

const FACING_LOCALIZATION_KEYS := {
	UnitState.Facing.RIGHT: &"ui.battle.facing_southeast",
	UnitState.Facing.DOWN: &"ui.battle.facing_southwest",
	UnitState.Facing.LEFT: &"ui.battle.facing_northwest",
	UnitState.Facing.UP: &"ui.battle.facing_northeast",
}

const FACING_FALLBACKS := {
	UnitState.Facing.RIGHT: "Southeast",
	UnitState.Facing.DOWN: "Southwest",
	UnitState.Facing.LEFT: "Northwest",
	UnitState.Facing.UP: "Northeast",
}

const FACING_PHASES := {
	UnitState.Facing.RIGHT: 0.0,
	UnitState.Facing.DOWN: PI * 0.5,
	UnitState.Facing.LEFT: PI,
	UnitState.Facing.UP: PI * 1.5,
}

const FACING_ARROW_TEXTURES := {
	UnitState.Facing.RIGHT: {
		"gold": preload("res://assets/ui/facing_arrows/facing_arrow_se_gold.png"),
		"blue": preload("res://assets/ui/facing_arrows/facing_arrow_se_blue.png"),
	},
	UnitState.Facing.DOWN: {
		"gold": preload("res://assets/ui/facing_arrows/facing_arrow_sw_gold.png"),
		"blue": preload("res://assets/ui/facing_arrows/facing_arrow_sw_blue.png"),
	},
	UnitState.Facing.LEFT: {
		"gold": preload("res://assets/ui/facing_arrows/facing_arrow_nw_gold.png"),
		"blue": preload("res://assets/ui/facing_arrows/facing_arrow_nw_blue.png"),
	},
	UnitState.Facing.UP: {
		"gold": preload("res://assets/ui/facing_arrows/facing_arrow_ne_gold.png"),
		"blue": preload("res://assets/ui/facing_arrows/facing_arrow_ne_blue.png"),
	},
}

var model: BattleModel = null
var view: Node2D = null

var _slots: Dictionary = {}
var _trap_slots: Dictionary = {}
var _op_defs: Dictionary = {}
var _trap_defs: Dictionary = {}
var _ticket_rows: Dictionary = {}
var _slot_cooldown_seconds: Dictionary = {}
var _slot_deck: PanelContainer = null
var _slot_scroll: ScrollContainer = null
var _slot_box: GridContainer = null
var _placement_op: StringName = &""
var _placement_trap: StringName = &""
var _pending_cell := Vector2i(-1, -1)
var _pointer := Vector2.ZERO
var _highlight_root: Control = null
var _cursor_rect: Polygon2D = null
var _facing_buttons: Dictionary = {}
var _facing_icons: Dictionary = {}
var _facing_icon_origins: Dictionary = {}
var _facing_emphasis: int = -1
var _retreat_chip: Button = null
var _retreat_unit_id: int = -1
var _heal_source_unit_id: int = -1
var _heal_cursor: Polygon2D = null
var _selected_unit_id: int = -1
var _selection_ring: Node2D = null
var _operator_interaction_enabled := true
var _interaction_enabled := true


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
	if not I18n.locale_changed.is_connected(_on_locale_changed):
		I18n.locale_changed.connect(_on_locale_changed)


func is_mend_targeting() -> bool:
	return _heal_source_unit_id >= 0


func set_operator_interaction_enabled(enabled: bool) -> void:
	_operator_interaction_enabled = enabled


func operator_interaction_enabled() -> bool:
	return _operator_interaction_enabled


func set_interaction_enabled(enabled: bool) -> void:
	_interaction_enabled = enabled
	if not enabled:
		cancel_transient_intent()


func interaction_enabled() -> bool:
	return _interaction_enabled


func transient_intent_active() -> bool:
	return (
		_placement_op != &""
		or _placement_trap != &""
		or _pending_cell.x >= 0
		or _heal_source_unit_id >= 0
		or _retreat_unit_id >= 0
		or _selected_unit_id >= 0
	)


func cancel_transient_intent() -> void:
	if _placement_op != &"" or _placement_trap != &"" or _pending_cell.x >= 0:
		_cancel_placement()
	_cancel_heal_targeting()
	_hide_retreat_chip()
	_select_unit(-1)


func first_deployment_id() -> StringName:
	var ids := _deployment_ids()
	return ids[0] if not ids.is_empty() else &""


func slot_screen_rect(deployment_id: StringName) -> Rect2:
	var slot := _slots.get(deployment_id) as Button
	return slot.get_global_rect() if slot != null else Rect2()


func command_deck_rect() -> Rect2:
	return _slot_deck.get_global_rect() if _slot_deck != null else Rect2()


func is_facing_pending() -> bool:
	return _pending_cell.x >= 0


func facing_button_screen_rect(facing: int) -> Rect2:
	var button := _facing_buttons.get(facing) as Button
	return button.get_global_rect() if button != null and button.visible else Rect2()


func set_facing_emphasis(facing: int = -1) -> void:
	_facing_emphasis = facing
	for raw_facing: UnitState.Facing in _facing_buttons:
		_refresh_facing_icon(raw_facing)


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
	_animate_facing_icons()
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
		_refresh_operator_slot(op_id, slot)
		slot.disabled = not _interaction_enabled or not _operator_interaction_enabled or not model.is_deployable(op_id)
	for trap_id: StringName in _trap_slots:
		var slot: Button = _trap_slots[trap_id]
		slot.disabled = not _interaction_enabled or not _operator_interaction_enabled or not model.is_trap_placeable(trap_id)


func _input(event: InputEvent) -> void:
	if not _interaction_enabled:
		return
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
	if not _interaction_enabled:
		return
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
	if _slot_deck != null:
		_slot_deck.queue_free()
	_slot_deck = null
	_slot_scroll = null
	_slot_box = null
	_slots.clear()
	_slot_cooldown_seconds.clear()
	_trap_slots.clear()
	_build_slots(_op_defs)


func _build_slots(op_defs: Dictionary) -> void:
	var deck := PanelContainer.new()
	deck.name = "DeploymentCommandDeck"
	deck.mouse_filter = Control.MOUSE_FILTER_PASS
	var deck_style := Style.panel_style(&"hud").duplicate() as StyleBox
	deck_style.content_margin_left = DECK_PADDING
	deck_style.content_margin_top = DECK_PADDING
	deck_style.content_margin_right = DECK_PADDING
	deck_style.content_margin_bottom = DECK_PADDING
	deck.add_theme_stylebox_override(&"panel", deck_style)
	add_child(deck)
	_slot_deck = deck
	var scroll := ScrollContainer.new()
	scroll.name = "DeploymentRosterScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	deck.add_child(scroll)
	_slot_scroll = scroll
	var center := CenterContainer.new()
	center.name = "DeploymentRosterCenter"
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var box := GridContainer.new()
	box.name = "SlotBox"
	box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_theme_constant_override("h_separation", SLOT_GAP)
	box.add_theme_constant_override("v_separation", SLOT_GAP)
	center.add_child(box)
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
		slot.text = _operator_card_text(def, identity_suffix, dp_cost)
		slot.custom_minimum_size = Vector2(SLOT_TARGET_WIDTH, SLOT_TARGET_HEIGHT)
		slot.icon = Art.texture(sprite_id, 0)
		slot.expand_icon = true
		slot.add_theme_constant_override(&"icon_max_width", 52)
		Style.apply_compact_rounded_button(slot, &"secondary", 12.0, 12)
		slot.add_theme_font_size_override(&"font_size", FONT_SIZE)
		if _slots.is_empty():
			_add_first_slot_content_inset(slot)
		slot.tooltip_text = slot.text.replace("\n", " — ")
		slot.focus_mode = Control.FOCUS_ALL
		slot.focus_entered.connect(_reveal_slot.bind(slot))
		slot.button_down.connect(_start_placement.bind(deployment_id))
		box.add_child(slot)
		_slots[deployment_id] = slot
		_slot_cooldown_seconds[deployment_id] = -1
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
		slot.text = _trap_card_text(def)
		slot.custom_minimum_size = Vector2(SLOT_TARGET_WIDTH, SLOT_TARGET_HEIGHT)
		slot.icon = Art.texture(
			&"trap_tar" if def.trigger == TrapDef.Trigger.CELL_AURA else &"trap_spike_armed"
		)
		slot.expand_icon = true
		slot.add_theme_constant_override(&"icon_max_width", 52)
		Style.apply_compact_rounded_button(slot, &"gold", 12.0, 12)
		slot.add_theme_font_size_override(&"font_size", FONT_SIZE)
		slot.tooltip_text = slot.text.replace("\n", " — ")
		slot.focus_mode = Control.FOCUS_ALL
		slot.focus_entered.connect(_reveal_slot.bind(slot))
		slot.button_down.connect(_start_trap_placement.bind(trap_id))
		box.add_child(slot)
		_trap_slots[trap_id] = slot
	_layout_slot_box()


func _deployment_ids() -> Array[StringName]:
	if not model.battle_squad.is_empty():
		return model.battle_squad.duplicate()
	return model.squad.duplicate()


func _layout_slot_box() -> void:
	if _slot_box == null or _slot_deck == null or _slot_scroll == null:
		return
	var short_landscape := size.x > size.y and size.y < 480.0
	var deck_width := (
		minf(size.x - SAFE_MARGIN * 2.0, SHORT_LANDSCAPE_DECK_MAX_WIDTH)
		if short_landscape
		else size.x - SAFE_MARGIN * 2.0
		if size.y > size.x
		else minf(size.x - SAFE_MARGIN * 2.0, LANDSCAPE_DECK_MAX_WIDTH)
	)
	deck_width = maxf(deck_width, 328.0)
	var inner_width := maxf(SLOT_TARGET_WIDTH, deck_width - DECK_PADDING * 2.0)
	_slot_box.columns = clampi(
		floori((inner_width + SLOT_GAP) / (SLOT_TARGET_WIDTH + SLOT_GAP)), 1, 4,
	)
	for child: Node in _slot_box.get_children():
		(child as Control).custom_minimum_size.x = SLOT_TARGET_WIDTH
	_slot_box.reset_size()
	var content_height := _slot_box.get_combined_minimum_size().y + DECK_PADDING * 2.0
	# The global 1.5× type scale increases each two-line slot's rendered
	# minimum height. Standard landscape must expose both rows without relying
	# on clipping; short landscape retains local scrolling by design.
	var height_ratio := 0.46 if short_landscape else 0.56
	var deck_height := minf(content_height, maxf(BAR_HEIGHT, size.y * height_ratio))
	_slot_deck.position = Vector2(SAFE_MARGIN, size.y - deck_height - SAFE_MARGIN)
	_slot_deck.size = Vector2(deck_width, deck_height)


func _add_first_slot_content_inset(slot: Button) -> void:
	for state: StringName in [&"normal", &"hover", &"pressed", &"disabled"]:
		var style := slot.get_theme_stylebox(state)
		if style == null:
			continue
		var inset_style := style.duplicate() as StyleBox
		inset_style.content_margin_left += FIRST_SLOT_CONTENT_INSET
		slot.add_theme_stylebox_override(state, inset_style)


func _reveal_slot(slot: Control) -> void:
	if _slot_scroll != null and slot != null:
		_slot_scroll.ensure_control_visible(slot)


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
		btn.text = ""
		btn.custom_minimum_size = FACING_BUTTON_SIZE
		btn.z_index = FACING_BUTTON_Z
		_apply_facing_button_styles(btn)
		_apply_facing_accessibility(btn, facing)
		btn.visible = false
		btn.pressed.connect(_confirm_deploy.bind(facing))
		btn.mouse_entered.connect(_refresh_facing_icon.bind(facing))
		btn.mouse_exited.connect(_refresh_facing_icon.bind(facing))
		btn.focus_entered.connect(_refresh_facing_icon.bind(facing))
		btn.focus_exited.connect(_refresh_facing_icon.bind(facing))
		add_child(btn)
		_facing_buttons[facing] = btn
		var icon := TextureRect.new()
		icon.name = "ArrowIcon"
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		btn.add_child(icon)
		_facing_icons[facing] = icon
		_layout_facing_icon(facing, FACING_BUTTON_SIZE)
		_refresh_facing_icon(facing)
	_retreat_chip = Button.new()
	_retreat_chip.name = "RetreatChip"
	_retreat_chip.text = UI_COPY.text(&"ui.battle.retreat", "Retreat")
	_retreat_chip.custom_minimum_size = Vector2(88.0, 52.0)
	Style.apply_button(_retreat_chip, &"danger")
	_retreat_chip.visible = false
	_retreat_chip.pressed.connect(_confirm_retreat)
	add_child(_retreat_chip)
	_selection_ring = SELECTION_RING_SCRIPT.new()
	_selection_ring.name = "SelectionRing"
	_selection_ring.visible = false
	_selection_ring.z_index = -1
	add_child(_selection_ring)


func _on_locale_changed(_locale_id: StringName) -> void:
	for deployment_id: StringName in _slots:
		var slot := _slots[deployment_id] as Button
		_slot_cooldown_seconds[deployment_id] = -1
		_refresh_operator_slot(deployment_id, slot)
	for trap_id: StringName in _trap_slots:
		var definition := _trap_defs.get(trap_id) as TrapDef
		var slot := _trap_slots[trap_id] as Button
		if definition == null or slot == null:
			continue
		slot.text = _trap_card_text(definition)
		slot.tooltip_text = slot.text.replace("\n", " — ")
	if _retreat_chip != null:
		_retreat_chip.text = UI_COPY.text(&"ui.battle.retreat", "Retreat")
	for facing: UnitState.Facing in _facing_buttons:
		_apply_facing_accessibility(_facing_buttons[facing] as Button, facing)


func _operator_card_text(definition: OperatorDef, identity_suffix: String, cost: int) -> String:
	return UI_COPY.format_text(
		&"ui.battle.deploy_operator_card",
		"{name}{slot}\n{cost} DP",
		{&"name": UI_COPY.operator_name(definition), &"slot": identity_suffix, &"cost": cost},
	)


func _operator_cooldown_card_text(
	definition: OperatorDef,
	identity_suffix: String,
	seconds: int,
) -> String:
	return UI_COPY.format_text(
		&"ui.battle.deploy_operator_cooldown",
		"{name}{slot}\nCOOLDOWN {seconds}s",
		{
			&"name": UI_COPY.operator_name(definition),
			&"slot": identity_suffix,
			&"seconds": seconds,
		},
	)


func _refresh_operator_slot(deployment_id: StringName, slot: Button) -> void:
	if slot == null or model == null:
		return
	var seconds := model.redeploy_cooldown_seconds_remaining(deployment_id)
	if int(_slot_cooldown_seconds.get(deployment_id, -1)) == seconds:
		return
	_slot_cooldown_seconds[deployment_id] = seconds
	var row: Dictionary = _ticket_rows.get(deployment_id, {})
	var operator_id := StringName(row.get("operator_def_id", deployment_id))
	var definition := _op_defs.get(operator_id) as OperatorDef
	if definition == null:
		return
	var dp_cost := definition.dp_cost
	var identity_suffix := ""
	if not row.is_empty():
		dp_cost = int(row["combat_spec"]["dp_cost"])
		identity_suffix = " %d" % (int(row["slot_index"]) + 1)
	slot.text = (
		_operator_cooldown_card_text(definition, identity_suffix, seconds)
		if seconds > 0
		else _operator_card_text(definition, identity_suffix, dp_cost)
	)
	slot.tooltip_text = slot.text.replace("\n", " — ")
	slot.accessibility_description = slot.tooltip_text


func _trap_card_text(definition: TrapDef) -> String:
	return UI_COPY.format_text(
		&"ui.battle.deploy_trap_card",
		"{name}\n{cost} DP",
		{&"name": UI_COPY.trap_name(definition), &"cost": definition.dp_cost},
	)


func _apply_facing_accessibility(button: Button, facing: UnitState.Facing) -> void:
	if button == null:
		return
	var direction := UI_COPY.text(
		StringName(FACING_LOCALIZATION_KEYS[facing]),
		String(FACING_FALLBACKS[facing]),
	)
	button.accessibility_name = direction
	button.accessibility_description = UI_COPY.format_text(
		&"ui.battle.facing_description",
		"Deploy facing {direction}",
		{&"direction": direction},
	)


func _apply_facing_button_styles(button: Button) -> void:
	var transparent := StyleBoxEmpty.new()
	for state: StringName in [&"normal", &"hover", &"pressed", &"disabled"]:
		button.add_theme_stylebox_override(state, transparent)
	button.add_theme_stylebox_override(
		&"focus", StagingSkinType.golden_focus_tint_style(10),
	)


## Footprints are origin-centered face diamonds (P12.2) sized by the live
## grid scale (dynamic canvas fit); position them at cell_center directly.
func _make_overlay_rect(color: Color) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.color = color
	poly.polygon = IsoProjection.face_polygon(view.call("grid_scale"))
	poly.visible = false
	return poly


func _start_placement(op_id: StringName) -> void:
	if not _interaction_enabled or not _operator_interaction_enabled:
		return
	_cancel_heal_targeting()
	_hide_retreat_chip()
	_placement_op = op_id
	_pending_cell = Vector2i(-1, -1)
	Sfx.play("operator_select")
	_show_valid_highlights()
	view.call("deploy_drag_started")
	placement_started.emit(op_id)


func _start_trap_placement(trap_id: StringName) -> void:
	if not _interaction_enabled or not _operator_interaction_enabled:
		return
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
	var deck_height := BAR_HEIGHT
	if _slot_deck != null:
		deck_height = maxf(deck_height, _slot_deck.get_combined_minimum_size().y)
	var safe_max := Vector2(
		maxf(safe_min.x, size.x - FACING_SAFE_MARGIN - cluster_size.x),
		maxf(safe_min.y, size.y - deck_height - FACING_SAFE_MARGIN - cluster_size.y),
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
		_layout_facing_icon(facing, button_size)


func _layout_facing_icon(facing: UnitState.Facing, button_size: Vector2) -> void:
	var icon := _facing_icons.get(facing) as TextureRect
	if icon == null:
		return
	icon.size = button_size - Vector2.ONE * FACING_ICON_INSET * 2.0
	icon.pivot_offset = icon.size * 0.5
	var origin := (button_size - icon.size) * 0.5
	_facing_icon_origins[facing] = origin
	icon.position = origin


func _refresh_facing_icon(facing: UnitState.Facing) -> void:
	var button := _facing_buttons.get(facing) as Button
	var icon := _facing_icons.get(facing) as TextureRect
	if button == null or icon == null:
		return
	var use_blue := int(facing) == _facing_emphasis or button.is_hovered()
	var textures := FACING_ARROW_TEXTURES[facing] as Dictionary
	icon.texture = textures["blue" if use_blue else "gold"] as Texture2D


func _animate_facing_icons() -> void:
	var animation_seconds := fmod(
		float(Time.get_ticks_msec()) / 1000.0, FACING_ANIMATION_PERIOD
	)
	for facing: UnitState.Facing in _facing_icons:
		var button := _facing_buttons[facing] as Button
		var icon := _facing_icons[facing] as TextureRect
		if button == null or icon == null:
			continue
		var origin: Vector2 = _facing_icon_origins.get(facing, icon.position)
		if not button.visible:
			icon.position = origin
			icon.scale = Vector2.ONE
			continue
		var phase := float(FACING_PHASES[facing])
		var angle := TAU * animation_seconds / FACING_ANIMATION_PERIOD + phase
		var direction: Vector2 = FACING_DIRECTIONS[facing]
		icon.position = origin + direction * sin(angle) * FACING_BOUNCE_AMPLITUDE
		var pulse := 1.0 + sin(angle + PI * 0.5) * FACING_PULSE_AMPLITUDE
		icon.scale = Vector2.ONE * pulse


func _confirm_deploy(facing: UnitState.Facing) -> void:
	if not _interaction_enabled:
		return
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
	set_facing_emphasis(-1)
	for facing: UnitState.Facing in _facing_buttons:
		var button := _facing_buttons[facing] as Button
		var icon := _facing_icons[facing] as TextureRect
		button.visible = false
		button.release_focus()
		icon.position = _facing_icon_origins.get(facing, icon.position)
		icon.scale = Vector2.ONE
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
	if not _interaction_enabled:
		return
	if _retreat_unit_id >= 0:
		model.apply_action([&"retreat", _retreat_unit_id])
		_select_unit(-1)
	_hide_retreat_chip()


func _select_unit(unit_id: int) -> void:
	if _selected_unit_id == unit_id:
		return
	_selected_unit_id = unit_id
	if view != null and view.has_method("operator_selection_changed"):
		view.call("operator_selection_changed", unit_id >= 0)
	_update_selection_ring()


func _update_selection_ring() -> void:
	if _selection_ring == null or model == null or view == null:
		return
	if _selected_unit_id < 0:
		_selection_ring.visible = false
		return
	var unit := model.unit_by_id(_selected_unit_id)
	if unit == null or not unit.alive:
		_select_unit(-1)
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
