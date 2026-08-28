class_name SpellBar
extends Control

signal targeting_started(spell_id: StringName)
signal targeting_stopped(spell_id: StringName)
signal cast_resolved(spell_id: StringName, target: Variant, accepted: bool)

const GameTypographyType := preload("res://scripts/ui/game_typography.gd")
const Style := preload("res://scripts/ui/components/lunaris_ops_style.gd")
const UI_COPY := preload("res://scripts/ui/components/ui_copy.gd")

## Raw-input adapter for the cast verb (architecture rule 3: a thin adapter
## over apply_action, validated once per spell kind by charm_runback.gd).
## Interaction: click a spell button -> targeting mode (a Chebyshev-sized
## square cursor follows the pointer) -> the NEXT left press casts at that
## cell (CELL spells) or at the lowest-id alive enemy on that cell (ENEMY
## spells); right-click / ui_cancel exits. Button enabled state reads
## model.is_castable, the cursor validity reads model.cast_target_valid
## (the verb's own validation, never a copy). Cooldown and persistent-area
## duration indicators are read-only projections of model ticks.

const FONT_SIZE := GameTypographyType.BODY
const SLOT_SIZE := Vector2(168.0, 70.0)
const COMPACT_SLOT_SIZE := Vector2(54.0, 50.0)
const COMPACT_BREAKPOINT := 1000.0
const SWEEP_HEIGHT := 6.0
const COOLDOWN_COLOR := Color(0.96, 0.71, 0.2, 0.9)
const DURATION_COLOR := Color(0.34, 0.87, 0.91, 0.95)
const STATUS_READY_COLOR := Color("dceef2")
const STATUS_COOLDOWN_COLOR := Color("f2c75c")
const STATUS_DURATION_COLOR := Color("72e3e8")
const CURSOR_VALID := Color(0.55, 0.75, 1.0, 0.4)
const CURSOR_INVALID := Color(0.9, 0.2, 0.2, 0.4)

var model: BattleModel = null
var view: Node2D = null

var _allowed: Array[StringName] = []
var _buttons: Dictionary = {}
var _cooldown_sweeps: Dictionary = {}
var _duration_sweeps: Dictionary = {}
var _cooldown_labels: Dictionary = {}
var _duration_labels: Dictionary = {}
var _deck: PanelContainer = null
var _targeting: StringName = &""
var _tutorial_spell: StringName = &""
var _pointer := Vector2.ZERO
var _cursor_rect: Polygon2D = null
var _interaction_enabled := true


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
	if not I18n.locale_changed.is_connected(_on_locale_changed):
		I18n.locale_changed.connect(_on_locale_changed)
	_cursor_rect = Polygon2D.new()
	_cursor_rect.name = "SpellCursor"
	_cursor_rect.visible = false
	add_child(_cursor_rect)


func _build_buttons() -> void:
	_deck = PanelContainer.new()
	_deck.name = "SpellCommandDeck"
	_deck.mouse_filter = Control.MOUSE_FILTER_PASS
	Style.apply_panel(_deck, &"hud")
	add_child(_deck)
	var box := GridContainer.new()
	box.name = "SpellBox"
	box.columns = maxi(1, _allowed.size())
	box.add_theme_constant_override("h_separation", 10)
	box.add_theme_constant_override("v_separation", 10)
	_deck.add_child(box)
	for spell_id: StringName in model.spell_book.ids:
		if not _allowed.has(spell_id):
			continue
		var def := model.spell_book.def_of(spell_id)
		var slot := Button.new()
		slot.name = "Spell_%s" % spell_id
		slot.text = UI_COPY.spell_name(def)
		slot.tooltip_text = _tooltip_for(def)
		slot.accessibility_name = UI_COPY.spell_name(def)
		slot.accessibility_description = slot.tooltip_text
		slot.custom_minimum_size = SLOT_SIZE
		slot.icon = Art.texture(StringName("icon_%s" % spell_id))
		slot.expand_icon = true
		slot.add_theme_constant_override(&"icon_max_width", 42)
		slot.add_theme_font_size_override("font_size", FONT_SIZE)
		Style.apply_button(slot, &"gold")
		slot.button_down.connect(_start_targeting.bind(spell_id))
		box.add_child(slot)
		_buttons[spell_id] = slot

		var duration_label := _make_status_label("DurationLabel_%s" % spell_id)
		duration_label.add_theme_color_override("font_color", STATUS_DURATION_COLOR)
		duration_label.visible = false
		slot.add_child(duration_label)
		_duration_labels[spell_id] = duration_label

		var cooldown_label := _make_status_label("CooldownLabel_%s" % spell_id)
		cooldown_label.add_theme_color_override("font_color", STATUS_READY_COLOR)
		slot.add_child(cooldown_label)
		_cooldown_labels[spell_id] = cooldown_label

		var duration_sweep := ColorRect.new()
		duration_sweep.name = "DurationSweep_%s" % spell_id
		duration_sweep.mouse_filter = Control.MOUSE_FILTER_IGNORE
		duration_sweep.color = DURATION_COLOR
		duration_sweep.size = Vector2.ZERO
		slot.add_child(duration_sweep)
		_duration_sweeps[spell_id] = duration_sweep

		var cooldown_sweep := ColorRect.new()
		cooldown_sweep.name = "CooldownSweep_%s" % spell_id
		cooldown_sweep.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cooldown_sweep.color = COOLDOWN_COLOR
		cooldown_sweep.size = Vector2.ZERO
		slot.add_child(cooldown_sweep)
		_cooldown_sweeps[spell_id] = cooldown_sweep
	_deck.visible = box.get_child_count() > 0
	relayout()


func _make_status_label(label_name: String) -> Label:
	var label := Label.new()
	label.name = label_name
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	Style.apply_label(label, &"detail")
	label.add_theme_font_size_override("font_size", 21)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.08, 0.95))
	label.add_theme_constant_override("outline_size", 3)
	return label


## battle_view._relayout() after the grid recompute (P14 ordering).
func relayout() -> void:
	size = get_viewport().get_visible_rect().size
	var box := _deck.get_node_or_null("SpellBox") as GridContainer if _deck != null else null
	if box != null:
		var compact := size.x < COMPACT_BREAKPOINT
		set_meta(&"compact_layout_active", compact)
		box.columns = maxi(1, box.get_child_count()) if compact else maxi(1, box.get_child_count())
		for spell_id: StringName in _buttons:
			var slot := _buttons[spell_id] as Button
			var definition := model.spell_book.def_of(spell_id)
			slot.custom_minimum_size = COMPACT_SLOT_SIZE if compact else SLOT_SIZE
			slot.text = "" if compact else UI_COPY.spell_name(definition)
			slot.add_theme_constant_override(&"icon_max_width", 36 if compact else 42)
		box.reset_size()
	if _deck != null:
		_deck.reset_size()
		var deck_size := _deck.get_combined_minimum_size()
		var deck_y := maxf(96.0, size.y - deck_size.y - 18.0) if size.x >= size.y else 18.0
		_deck.position = Vector2(
			size.x - deck_size.x - 16.0,
			deck_y,
		)


func avoid_rect(blocked_rect: Rect2, gap := 16.0) -> bool:
	return avoid_rects([blocked_rect] as Array[Rect2], gap)


func avoid_rects(blocked_rects: Array[Rect2], gap := 16.0) -> bool:
	if _deck == null or not _deck.visible:
		return true
	var blockers: Array[Rect2] = []
	for blocked_rect: Rect2 in blocked_rects:
		if blocked_rect.has_area():
			blockers.append(blocked_rect)
	var own_rect := _deck.get_global_rect()
	if not _intersects_any(own_rect, blockers):
		return true
	var safe_rect := Rect2(Vector2.ONE * 16.0, get_viewport_rect().size - Vector2.ONE * 32.0)
	var x_candidates: Array[float] = [own_rect.position.x, safe_rect.position.x, safe_rect.end.x - _deck.size.x]
	var y_candidates: Array[float] = [own_rect.position.y, safe_rect.position.y, safe_rect.end.y - _deck.size.y]
	for blocked_rect: Rect2 in blockers:
		x_candidates.append(blocked_rect.position.x - _deck.size.x - gap)
		x_candidates.append(blocked_rect.end.x + gap)
		y_candidates.append(blocked_rect.position.y - _deck.size.y - gap)
		y_candidates.append(blocked_rect.end.y + gap)
	var candidates: Array[Vector2] = []
	for candidate_x: float in x_candidates:
		for candidate_y: float in y_candidates:
			candidates.append(Vector2(candidate_x, candidate_y))
	candidates.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.distance_squared_to(own_rect.position) < b.distance_squared_to(own_rect.position))
	for candidate: Vector2 in candidates:
		var candidate_rect := Rect2(candidate, _deck.size)
		if safe_rect.encloses(candidate_rect) and not _intersects_any(candidate_rect, blockers):
			_deck.global_position = candidate
			return true
	return false


func _intersects_any(candidate_rect: Rect2, blocked_rects: Array[Rect2]) -> bool:
	for blocked_rect: Rect2 in blocked_rects:
		if candidate_rect.intersects(blocked_rect):
			return true
	return false


func set_tutorial_spell(spell_id: StringName) -> void:
	_tutorial_spell = spell_id
	_refresh_buttons()


func targeting_spell() -> StringName:
	return _targeting


func set_interaction_enabled(enabled: bool) -> void:
	_interaction_enabled = enabled
	if not enabled:
		stop_targeting()
	_refresh_buttons()


func interaction_enabled() -> bool:
	return _interaction_enabled


func request_targeting(spell_id: StringName) -> bool:
	if not _interaction_enabled or not _buttons.has(spell_id):
		return false
	var slot: Button = _buttons[spell_id]
	if slot.disabled:
		return false
	_start_targeting(spell_id)
	return true


func stop_targeting() -> void:
	_stop_targeting()


func slot_screen_rect(spell_id: StringName) -> Rect2:
	if not _buttons.has(spell_id):
		return Rect2()
	return (_buttons[spell_id] as Button).get_global_rect()


func remaining_duration_ticks(spell_id: StringName) -> int:
	if model == null:
		return 0
	var remaining := 0
	for field: SlowFieldState in model.slow_fields:
		if field.spell_id == spell_id:
			remaining = maxi(remaining, field.expires_tick - model.tick)
	return remaining


func remaining_cooldown_ticks(spell_id: StringName) -> int:
	if model == null or not model.spell_book.has_spell(spell_id):
		return 0
	return maxi(0, model.spell_book.ready_at(spell_id) - model.tick)


func _process(_delta: float) -> void:
	if model == null:
		return
	_refresh_buttons()


func _refresh_buttons() -> void:
	var compact := size.x < COMPACT_BREAKPOINT
	for spell_id: StringName in _buttons:
		var slot: Button = _buttons[spell_id]
		var tutorial_blocked := not _tutorial_spell.is_empty() and spell_id != _tutorial_spell
		slot.disabled = not _interaction_enabled or tutorial_blocked or not model.is_castable(spell_id)
		var def := model.spell_book.def_of(spell_id)
		var cooldown_remaining := remaining_cooldown_ticks(spell_id)
		var duration_remaining := remaining_duration_ticks(spell_id)
		var cooldown_sweep: ColorRect = _cooldown_sweeps[spell_id]
		var duration_sweep: ColorRect = _duration_sweeps[spell_id]
		var cooldown_label: Label = _cooldown_labels[spell_id]
		var duration_label: Label = _duration_labels[spell_id]

		if def.cooldown_ticks > 0 and cooldown_remaining > 0:
			cooldown_sweep.size = Vector2(
				slot.size.x * float(cooldown_remaining) / float(def.cooldown_ticks),
				SWEEP_HEIGHT,
			)
			cooldown_label.text = UI_COPY.format_text(
				&"ui.spell.cooldown",
				"CD {seconds}s",
				{&"seconds": _seconds_text(cooldown_remaining)},
			)
			cooldown_label.add_theme_color_override("font_color", STATUS_COOLDOWN_COLOR)
		else:
			cooldown_sweep.size = Vector2.ZERO
			cooldown_label.text = (
				_copy(&"ui.spell.wave", "1 / WAVE")
				if def.availability == SpellDef.Availability.ONCE_PER_WAVE
				else _copy(&"ui.spell.ready", "READY")
			)
			cooldown_label.add_theme_color_override("font_color", STATUS_READY_COLOR)

		if def.duration_ticks > 0 and duration_remaining > 0:
			duration_sweep.size = Vector2(
				slot.size.x * float(duration_remaining) / float(def.duration_ticks),
				SWEEP_HEIGHT,
			)
			duration_label.text = UI_COPY.format_text(
				&"ui.spell.field_duration",
				"FIELD {seconds}s",
				{&"seconds": _seconds_text(duration_remaining)},
			)
			duration_label.visible = true
		else:
			duration_sweep.size = Vector2.ZERO
			duration_label.visible = false

		duration_sweep.position = Vector2(0.0, slot.size.y - SWEEP_HEIGHT * 2.0)
		cooldown_sweep.position = Vector2(0.0, slot.size.y - SWEEP_HEIGHT)
		cooldown_label.visible = true
		if compact:
			if duration_remaining > 0:
				duration_label.text = "F%s" % _seconds_text(duration_remaining)
			if cooldown_remaining > 0:
				cooldown_label.text = "CD%s" % _seconds_text(cooldown_remaining)
			duration_label.add_theme_font_size_override(&"font_size", 11)
			cooldown_label.add_theme_font_size_override(&"font_size", 11)
			duration_label.position = Vector2(2.0, 2.0)
			duration_label.size = Vector2(maxf(0.0, slot.size.x - 4.0), 16.0)
			cooldown_label.position = Vector2(2.0, slot.size.y - 22.0)
			cooldown_label.size = Vector2(maxf(0.0, slot.size.x - 4.0), 16.0)
		else:
			duration_label.add_theme_font_size_override(&"font_size", 21)
			cooldown_label.add_theme_font_size_override(&"font_size", 21)
			duration_label.position = Vector2(52.0, 4.0)
			duration_label.size = Vector2(maxf(0.0, slot.size.x - 60.0), 20.0)
			cooldown_label.position = Vector2(52.0, slot.size.y - 32.0)
			cooldown_label.size = Vector2(maxf(0.0, slot.size.x - 60.0), 20.0)
		var final_accessibility_status: PackedStringArray = []
		if duration_remaining > 0:
			final_accessibility_status.append(UI_COPY.format_text(
				&"ui.spell.field_duration",
				"FIELD {seconds}s",
				{&"seconds": _seconds_text(duration_remaining)},
			))
		final_accessibility_status.append(
			UI_COPY.format_text(
				&"ui.spell.cooldown",
				"CD {seconds}s",
				{&"seconds": _seconds_text(cooldown_remaining)},
			)
			if cooldown_remaining > 0
			else cooldown_label.text
		)
		var final_accessibility_copy := "%s  %s" % [
			_tooltip_for(def), " | ".join(final_accessibility_status),
		]
		slot.tooltip_text = final_accessibility_copy
		slot.accessibility_description = final_accessibility_copy


func _tooltip_for(def: SpellDef) -> String:
	if def.effect == SpellDef.Effect.SLOW_FIELD:
		return UI_COPY.text(
			&"ui.spell.slow_field.tooltip",
			"Create a gravity field that slows ground robots. It does not touch anima or souls.",
		)
	if def.effect == SpellDef.Effect.CHARM:
		return UI_COPY.text(
			&"ui.spell.charm.tooltip",
			"Break a PROTOS command link and force one eligible robot to attack its own side temporarily.",
		)
	return UI_COPY.spell_name(def)


func _on_locale_changed(_locale_id: StringName) -> void:
	for spell_id: StringName in _buttons:
		var slot := _buttons[spell_id] as Button
		var definition := model.spell_book.def_of(spell_id)
		slot.text = UI_COPY.spell_name(definition)
		slot.tooltip_text = _tooltip_for(definition)
		slot.accessibility_name = UI_COPY.spell_name(definition)
		slot.accessibility_description = slot.tooltip_text
	relayout()
	_refresh_buttons()


func _seconds_text(ticks: int) -> String:
	var ticks_per_second := maxi(1, model.config.ticks_per_second)
	var tenths := ceili(float(ticks) * 10.0 / float(ticks_per_second))
	return "%.1f" % (float(tenths) / 10.0)


func _input(event: InputEvent) -> void:
	if not _interaction_enabled or _targeting == &"":
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
	if not _interaction_enabled or _targeting == spell_id:
		return
	if not _targeting.is_empty():
		_stop_targeting()
	_targeting = spell_id
	_update_cursor()
	targeting_started.emit(spell_id)


func _stop_targeting() -> void:
	if _targeting.is_empty():
		return
	var prior := _targeting
	_targeting = &""
	_cursor_rect.visible = false
	targeting_stopped.emit(prior)


func _cast_at_pointer() -> void:
	if not _interaction_enabled or _targeting.is_empty():
		return
	var spell_id := _targeting
	var cell: Vector2i = view.call("cell_at", _pointer)
	var target: Variant = _target_for(spell_id, cell)
	var accepted := model.apply_action([&"cast", spell_id, target])
	cast_resolved.emit(spell_id, target, accepted)
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
	if _targeting.is_empty() or view == null:
		return
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


func _copy(key: StringName, fallback: String) -> String:
	return UI_COPY.text(key, fallback)
