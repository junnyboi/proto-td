extends Control

## Campaign squad select (Phase 10, td-phase-10.md §2.6): toggle up to
## squad_size of the UNLOCKED operators (class-colored text — portraits are
## Lane A), read-only loadout strip for unlocked traps/spells (global verbs,
## always available in battle), the stage's intro_hint, StartBattle gated on
## >= 1 pick. squad_size is enforced HERE only — the model accepts any
## squad (K6 pin). Pre-fills the previous selection ∩ unlocked.

const FONT_SIZE := 32
const HINT_FONT_SIZE := 24
const GRID_COLUMNS := 5

var _stage: StageDef = null
var _picked: Array[StringName] = []
var _buttons: Dictionary = {}
var _counter: Label = null
var _start: Button = null


func _ready() -> void:
	Game.content = self
	_stage = load("res://data/stages/%s.tres" % Game.selected_stage_id) as StageDef
	var column := VBoxContainer.new()
	column.name = "SquadColumn"
	column.set_anchors_preset(Control.PRESET_CENTER)
	column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	column.grow_vertical = Control.GROW_DIRECTION_BOTH
	column.add_theme_constant_override("separation", 12)
	add_child(column)
	column.add_child(_label("SquadHeading", "%s — pick your squad" % _stage.title, FONT_SIZE))
	column.add_child(_label("IntroHint", _stage.intro_hint, HINT_FONT_SIZE))
	var grid := GridContainer.new()
	grid.name = "OperatorGrid"
	grid.columns = GRID_COLUMNS
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	column.add_child(grid)
	for op_id: StringName in Game.loadout_operator_ids():
		var def := load("res://data/operators/%s.tres" % op_id) as OperatorDef
		var pick := Button.new()
		pick.name = "Pick_%s" % op_id
		pick.toggle_mode = true
		pick.text = "%s\n%d DP" % [def.display_name, def.dp_cost]
		pick.add_theme_font_size_override("font_size", HINT_FONT_SIZE)
		pick.toggled.connect(_on_pick_toggled.bind(op_id))
		grid.add_child(pick)
		_buttons[op_id] = pick
	_counter = _label("PickCounter", "", FONT_SIZE)
	column.add_child(_counter)
	column.add_child(_label("LoadoutStrip", _loadout_text(), HINT_FONT_SIZE))
	var actions := HBoxContainer.new()
	actions.name = "ActionRow"
	actions.add_theme_constant_override("separation", 16)
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(actions)
	var back := Button.new()
	back.name = "BackButton"
	back.text = "Back"
	back.add_theme_font_size_override("font_size", FONT_SIZE)
	back.pressed.connect(_on_back)
	actions.add_child(back)
	_start = Button.new()
	_start.name = "StartBattle"
	_start.text = "Start Battle"
	_start.add_theme_font_size_override("font_size", FONT_SIZE)
	_start.pressed.connect(_on_start)
	actions.add_child(_start)
	_prefill()
	_refresh()


## previous selection ∩ unlocked, truncated to squad_size (§2.3.4 QoL)
func _prefill() -> void:
	for op_id: StringName in Game.selected_squad:
		if _picked.size() >= _stage.squad_size:
			break
		if _buttons.has(op_id):
			_picked.append(op_id)
			(_buttons[op_id] as Button).set_pressed_no_signal(true)


func _loadout_text() -> String:
	var gear: Array[String] = []
	for trap_id: StringName in Game.loadout_trap_ids():
		var trap := load("res://data/traps/%s.tres" % trap_id) as TrapDef
		gear.append(trap.display_name)
	for spell_id: StringName in Game.loadout_spell_ids():
		var spell := load("res://data/spells/%s.tres" % spell_id) as SpellDef
		gear.append(spell.display_name)
	if gear.is_empty():
		return "Loadout: nothing unlocked yet"
	return "Loadout (always available): " + ", ".join(gear)


func _on_pick_toggled(pressed: bool, op_id: StringName) -> void:
	if pressed:
		if _picked.size() >= _stage.squad_size:
			(_buttons[op_id] as Button).set_pressed_no_signal(false)
			return
		_picked.append(op_id)
	else:
		_picked.erase(op_id)
	_refresh()


func _refresh() -> void:
	_counter.text = "%d/%d selected" % [_picked.size(), _stage.squad_size]
	_start.disabled = _picked.is_empty()


func _on_back() -> void:
	Sfx.play("ui_click")
	Game.open_stage_select()


func _on_start() -> void:
	Sfx.play("ui_click")
	Game.start_stage(_stage.id, _picked)


func _label(label_name: String, text: String, size_px: int) -> Label:
	var label := Label.new()
	label.name = label_name
	label.text = text
	label.add_theme_font_size_override("font_size", size_px)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label
