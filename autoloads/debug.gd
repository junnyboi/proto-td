extends Node

## Debug overlay (Phase 8, td-phase-8.md — architecture rule 5): a UI over
## the same seam-drivable verbs the tests use. Every mutation goes through
## BattleModel.apply_action, Game.start_battle, or the view's
## ticks_per_frame_scale speed seam — the overlay never writes model state
## directly and emits no telemetry. Toggled by F12 or the --debug user arg;
## it lives in this Phase 0 autoload shell so it survives Game's content
## swaps across stage jumps. Scenario seams: toggle/is_open/jump_to_stage/
## grant_all_operators/set_speed — the same handlers the buttons call.

const FONT_SIZE := 32
const PANEL_MARGIN := 12
const OP_GRID_COLUMNS := 5
const SPEED_OPTIONS: Array[float] = [0.0, 1.0, 2.0, 4.0]

var _layer: CanvasLayer = null
var _readout: Label = null
var _battle_rows: Array[Node] = []
var _op_buttons: Dictionary = {}


func _ready() -> void:
	if OS.get_cmdline_user_args().has("--debug"):
		toggle()


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and not key.is_echo() and key.keycode == KEY_F12:
			toggle()


func _process(_delta: float) -> void:
	if not is_open():
		return
	var model := _model()
	_readout.text = _readout_text(model)
	for row: Node in _battle_rows:
		row.set("visible", model != null)
	if model != null:
		for op_id: StringName in _op_buttons:
			var btn: Button = _op_buttons[op_id]
			btn.text = ("- %s" if model.squad.has(op_id) else "+ %s") % op_id


func is_open() -> bool:
	return _layer != null and _layer.visible


func toggle() -> void:
	if _layer == null:
		_build()
	_layer.visible = not _layer.visible


func jump_to_stage(stage_id: StringName) -> void:
	Game.start_battle(stage_id)


func grant_all_operators() -> void:
	var model := _model()
	if model == null:
		return
	for op_id: StringName in operator_ids():
		model.apply_action([&"debug_grant_operator", op_id])


func set_speed(scale_value: float) -> void:
	var view := _battle_view()
	if view != null:
		view.set("ticks_per_frame_scale", scale_value)


## The full operator catalog on disk, sorted (grant buttons + grant-all).
func operator_ids() -> Array[StringName]:
	return _scan_ids("res://data/operators")


## Sorted-as-String id scan (StringName's own ordering is interning-order,
## not text — a same-process-stable but arbitrary button order otherwise).
func _scan_ids(dir_path: String) -> Array[StringName]:
	var names: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return []
	for file: String in dir.get_files():
		# exported builds list "<name>.tres.remap" (text->binary conversion)
		var res_name := file.trim_suffix(".remap")
		if res_name.ends_with(".tres"):
			names.append(res_name.trim_suffix(".tres"))
	names.sort()
	var ids: Array[StringName] = []
	for id_name: String in names:
		ids.append(StringName(id_name))
	return ids


func _model() -> BattleModel:
	return Game.current_battle


## The live battle view iff the swapped-in content is one (title isn't).
func _battle_view() -> Node:
	var content := Game.content
	if content != null and is_instance_valid(content) and "ticks_per_frame_scale" in content:
		return content
	return null


func _readout_text(model: BattleModel) -> String:
	if model == null:
		return "no battle - jump to a stage"
	var s := model.snapshot()
	var result_text: String = ["RUNNING", "CLEAR", "DEFEAT"][int(s["result"])]
	var view := _battle_view()
	var speed: float = view.get("ticks_per_frame_scale") if view != null else 0.0
	return (
		"%s  tick %d  wave %d  %s  seed %d\n" % [
			model.stage.id, model.tick, model.spell_book.wave_index_of(model.tick),
			result_text, model.run_seed,
		]
		+ "base HP %d  DP %d  speed %.1fx\n" % [s["base_hp"], s["dp"], speed]
		+ "spawned %d  alive %d  killed %d  leaked %d  charmed %d" % [
			s["spawned"], s["alive"], s["killed"], s["leaked"], s["charmed"],
		]
	)


func _build() -> void:
	_layer = CanvasLayer.new()
	_layer.name = "DebugLayer"
	_layer.layer = 100
	# born hidden: toggle() flips it, so the first toggle must land on true
	_layer.visible = false
	add_child(_layer)
	var panel := PanelContainer.new()
	panel.name = "DebugPanel"
	panel.position = Vector2(8, 8)
	_layer.add_child(panel)
	var margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, PANEL_MARGIN)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)
	_readout = _make_label("")
	_readout.name = "Readout"
	column.add_child(_readout)
	column.add_child(_build_stage_row())
	_battle_rows = [
		_build_op_grid(),
		_build_dp_hp_row(),
		_build_spell_row(),
		_build_speed_row(),
	]
	for row: Node in _battle_rows:
		column.add_child(row)


func _build_stage_row() -> HFlowContainer:
	var row := _make_row("StageRow")
	row.add_child(_make_label("stage"))
	for stage_id: StringName in Game.stage_ids():
		var btn := _make_button("Jump_%s" % stage_id, String(stage_id))
		btn.pressed.connect(jump_to_stage.bind(stage_id))
		row.add_child(btn)
	return row


func _build_op_grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.name = "OpGrid"
	grid.columns = OP_GRID_COLUMNS
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for op_id: StringName in operator_ids():
		var btn := _make_button("Op_%s" % op_id, String(op_id))
		btn.pressed.connect(_on_op_pressed.bind(op_id))
		grid.add_child(btn)
		_op_buttons[op_id] = btn
	return grid


func _build_dp_hp_row() -> HFlowContainer:
	var row := _make_row("DpHpRow")
	var specs: Array[Dictionary] = [
		{"name": "DpPlus", "text": "DP +10"},
		{"name": "DpMax", "text": "DP max"},
		{"name": "HpMinus", "text": "HP -5"},
		{"name": "HpPlus", "text": "HP +5"},
	]
	for spec: Dictionary in specs:
		var btn := _make_button(spec["name"], spec["text"])
		btn.pressed.connect(_on_dp_hp_pressed.bind(spec["name"] as String))
		row.add_child(btn)
	# the P8 "session-unlock strip" pointer lands here (td-phase-10.md §2.3.5)
	var unlock := _make_button("UnlockAll", "Unlock all")
	unlock.pressed.connect(func() -> void: Game._debug_unlock_all())
	row.add_child(unlock)
	return row


func _build_spell_row() -> HFlowContainer:
	var row := _make_row("SpellRow")
	row.add_child(_make_label("reset"))
	for spell_id: StringName in _scan_ids("res://data/spells"):
		var btn := _make_button("Reset_%s" % spell_id, String(spell_id))
		btn.pressed.connect(_on_spell_reset.bind(spell_id))
		row.add_child(btn)
	return row


func _build_speed_row() -> HFlowContainer:
	var row := _make_row("SpeedRow")
	row.add_child(_make_label("speed"))
	for option: float in SPEED_OPTIONS:
		var btn := _make_button("Speed_%d" % int(option), "%dx" % int(option))
		btn.pressed.connect(set_speed.bind(option))
		row.add_child(btn)
	return row


func _on_op_pressed(op_id: StringName) -> void:
	var model := _model()
	if model == null:
		return
	if model.squad.has(op_id):
		model.apply_action([&"debug_remove_operator", op_id])
	else:
		model.apply_action([&"debug_grant_operator", op_id])


func _on_dp_hp_pressed(button_name: String) -> void:
	var model := _model()
	if model == null:
		return
	match button_name:
		"DpPlus":
			model.apply_action([&"debug_set_dp", mini(model.dp + 10, model.config.dp_cap)])
		"DpMax":
			model.apply_action([&"debug_set_dp", model.config.dp_cap])
		"HpMinus":
			model.apply_action([&"debug_set_base_hp", maxi(model.base_hp - 5, 0)])
		"HpPlus":
			model.apply_action([&"debug_set_base_hp", model.base_hp + 5])


func _on_spell_reset(spell_id: StringName) -> void:
	var model := _model()
	if model != null:
		model.apply_action([&"debug_reset_spell", spell_id])


## Flow container so 11 stage buttons wrap instead of running off 1280 px
## (Phase 10, K14 — a layout edit, never a check weakening).
func _make_row(row_name: String) -> HFlowContainer:
	var row := HFlowContainer.new()
	row.name = row_name
	row.custom_minimum_size = Vector2(980, 0)
	row.add_theme_constant_override("h_separation", 8)
	return row


func _make_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	return label


func _make_button(button_name: String, text: String) -> Button:
	var btn := Button.new()
	btn.name = button_name
	btn.text = text
	btn.add_theme_font_size_override("font_size", FONT_SIZE)
	return btn
