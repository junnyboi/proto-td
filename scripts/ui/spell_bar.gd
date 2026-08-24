class_name SpellBar
extends Control

const GameTypographyType := preload("res://scripts/ui/game_typography.gd")

## Raw-input adapter for the cast verb (architecture rule 3: a thin adapter
## over apply_action, validated once per spell kind by charm_runback.gd).
## Interaction: click a spell button -> targeting mode (a Chebyshev-sized
## square cursor follows the pointer) -> the NEXT left press casts at that
## cell (CELL spells) or at the lowest-id alive enemy on that cell (ENEMY
## spells); right-click / ui_cancel exits. Button enabled state reads
## model.is_castable, the cursor validity reads model.cast_target_valid
## (the verb's own validation, never a copy). The cooldown sweep is a fill
## rect proportional to max(0, ready_at - tick) / cooldown; ONCE_PER_WAVE
## spells show a "1/wave" label and dim while used.

const FONT_SIZE := GameTypographyType.BODY
const SWEEP_HEIGHT := 8.0
const SWEEP_COLOR := Color(0.96, 0.71, 0.2, 0.85)
const CURSOR_VALID := Color(0.55, 0.75, 1.0, 0.4)
const CURSOR_INVALID := Color(0.9, 0.2, 0.2, 0.4)

var model: BattleModel = null
var view: Node2D = null

var _allowed: Array[StringName] = []
var _buttons: Dictionary = {}
var _sweeps: Dictionary = {}
var _targeting: StringName = &""
var _pointer := Vector2.ZERO
var _cursor_rect: Polygon2D = null


## Call after add_child: sized from the viewport (a Control under a Node2D
## parent gets no anchor-based layout). spell_ids is the caller's loadout
## catalog-validated): an empty loadout means an empty bar. There is no
## show-everything sentinel — the campaign's starting spell set is
## legitimately empty, and a fail-open default let Bolt/Charm be cast from
## S1 (P10 audit finding F1).
func setup(
	battle_model: BattleModel,
	battle_view: Node2D,
	spell_ids: Array[StringName],
) -> void:
	model = battle_model
	view = battle_view
	_allowed = spell_ids
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2.ZERO
	size = get_viewport().get_visible_rect().size
	_build_buttons()
	_cursor_rect = Polygon2D.new()
	_cursor_rect.name = "SpellCursor"
	_cursor_rect.visible = false
	add_child(_cursor_rect)


func _build_buttons() -> void:
	var box := HBoxContainer.new()
	box.name = "SpellBox"
	box.add_theme_constant_override("separation", 16)
	add_child(box)
	for spell_id: StringName in model.spell_book.ids:
		if not _allowed.has(spell_id):
			continue
		var def := model.spell_book.def_of(spell_id)
		var slot := Button.new()
		slot.name = "Spell_%s" % spell_id
		slot.text = _label_for(def)
		slot.custom_minimum_size.y = 52.0
		slot.icon = Art.texture(StringName("icon_%s" % spell_id))
		slot.add_theme_font_size_override("font_size", FONT_SIZE)
		slot.button_down.connect(_start_targeting.bind(spell_id))
		box.add_child(slot)
		_buttons[spell_id] = slot
		var sweep := ColorRect.new()
		sweep.name = "CooldownSweep"
		sweep.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sweep.color = SWEEP_COLOR
		sweep.size = Vector2(0, SWEEP_HEIGHT)
		slot.add_child(sweep)
		_sweeps[spell_id] = sweep
	# top-right strip; the box knows its width only after buttons exist
	box.reset_size()
	box.position = Vector2(size.x - box.get_combined_minimum_size().x - 16.0, 8.0)


## battle_view._relayout() after the grid recompute (P14 ordering).
func relayout() -> void:
	size = get_viewport().get_visible_rect().size
	var box := get_node_or_null("SpellBox") as HBoxContainer
	if box != null:
		box.position = Vector2(size.x - box.get_combined_minimum_size().x - 16.0, 8.0)


func _label_for(def: SpellDef) -> String:
	if def.availability == SpellDef.Availability.ONCE_PER_WAVE:
		return "%s 1/wave" % def.display_name
	return def.display_name


func _process(_delta: float) -> void:
	if model == null:
		return
	for spell_id: StringName in _buttons:
		var slot: Button = _buttons[spell_id]
		slot.disabled = not model.is_castable(spell_id)
		var def := model.spell_book.def_of(spell_id)
		var sweep: ColorRect = _sweeps[spell_id]
		if def.cooldown_ticks > 0:
			var remaining := maxi(0, model.spell_book.ready_at(spell_id) - model.tick)
			sweep.size = Vector2(
				slot.size.x * float(remaining) / float(def.cooldown_ticks), SWEEP_HEIGHT
			)
			sweep.position = Vector2(0, slot.size.y - SWEEP_HEIGHT)
		else:
			sweep.size = Vector2.ZERO


func _input(event: InputEvent) -> void:
	if _targeting == &"":
		return
	if event is InputEventMouseMotion:
		_pointer = (event as InputEventMouseMotion).position
		_update_cursor()
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_pointer = mb.position
			_cast_at_pointer()
			get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_RIGHT and not mb.pressed:
			_stop_targeting()
	elif event.is_action_pressed("ui_cancel"):
		_stop_targeting()


func _start_targeting(spell_id: StringName) -> void:
	_targeting = spell_id
	_update_cursor()


func _stop_targeting() -> void:
	_targeting = &""
	_cursor_rect.visible = false


func _cast_at_pointer() -> void:
	var cell: Vector2i = view.call("cell_at", _pointer)
	var target: Variant = _target_for(_targeting, cell)
	model.apply_action([&"cast", _targeting, target])
	_stop_targeting()


## ENEMY spells resolve the clicked cell to the lowest-id alive eligible
## enemy standing on it; CELL spells pass the cell through.
func _target_for(spell_id: StringName, cell: Vector2i) -> Variant:
	var def := model.spell_book.def_of(spell_id)
	if def.target_kind == SpellDef.TargetKind.CELL:
		return cell
	for e: EnemyState in model.enemies:
		if not model.cast_target_valid(spell_id, e.id):
			continue
		if Pathing.cell_of(model.path_for(e.path_idx), e.progress_units) == cell:
			return e.id
	return -1


func _update_cursor() -> void:
	var cell: Vector2i = view.call("cell_at", _pointer)
	var def := model.spell_book.def_of(_targeting)
	var span := 1
	if def.target_kind == SpellDef.TargetKind.CELL:
		span = def.radius * 2 + 1
	var valid := model.cast_target_valid(_targeting, _target_for(_targeting, cell))
	_cursor_rect.color = CURSOR_VALID if valid else CURSOR_INVALID
	# the Chebyshev (2r+1)^2 block IS a diamond footprint of span x the face
	# (P12.2), sized by the live grid scale (dynamic canvas fit)
	var s: float = view.call("grid_scale")
	_cursor_rect.polygon = IsoProjection.face_polygon(s * span)
	_cursor_rect.position = Vector2(view.call("cell_center", cell))
	_cursor_rect.visible = true
