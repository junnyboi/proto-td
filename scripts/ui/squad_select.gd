extends Control

## Campaign squad select: toggle up to squad_size unlocked operators and route
## through the existing Game seams. The model accepts the unchanged selected IDs.

const SHELL_SCENE := preload("res://scenes/ui/components/aetheria_screen_shell.tscn")
const AetheriaButtonType := preload("res://scripts/ui/components/aetheria_button.gd")
const AetheriaLabelType := preload("res://scripts/ui/components/aetheria_label.gd")
const AetheriaScreenShellType := preload(
	"res://scripts/ui/components/aetheria_screen_shell.gd"
)
const UiCopyType := preload("res://scripts/ui/components/ui_copy.gd")
const NARRATIVE_CATALOG := preload("res://data/presentation/narrative/stage_narrative_catalog.tres")
const StageNarrativeDefType := preload("res://data/presentation/narrative/stage_narrative_def.gd")
const StageNarrativeCatalogType := preload("res://data/presentation/narrative/stage_narrative_catalog.gd")

var _stage: StageDef = null
var _picked: Array[StringName] = []
var _narrative: StageNarrativeDefType = null
var _narrative_missing := false
var _briefing: GridContainer = null
var _buttons: Dictionary = {}
var _counter: Label = null
var _start: AetheriaButtonType = null
var _back: AetheriaButtonType = null
var _grid: GridContainer = null
var _footer: GridContainer = null
var _header: BoxContainer = null


func _ready() -> void:
	Game.content = self
	_stage = load("res://data/stages/%s.tres" % Game.selected_stage_id) as StageDef
	_narrative = (NARRATIVE_CATALOG as StageNarrativeCatalogType).get_record(Game.selected_stage_id)
	_narrative_missing = _narrative == null
	var shell := SHELL_SCENE.instantiate() as AetheriaScreenShellType
	shell.name = "SquadShell"
	shell.preferred_size = Vector2(1160.0, 640.0)
	add_child(shell)
	shell.layout_mode_changed.connect(_on_layout_mode_changed)

	var scroll := ScrollContainer.new()
	scroll.name = "SquadScroll"
	var scroll_content := shell.add_dialog_scroll(scroll)

	var column := VBoxContainer.new()
	column.name = "SquadColumn"
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override(&"separation", 12)
	scroll_content.add_child(column)
	_header = BoxContainer.new()
	_header.name = "SquadHeader"
	_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_header.add_theme_constant_override(&"separation", 16)
	column.add_child(_header)
	var full_heading := UiCopyType.format_text(
		&"ui.squad.heading", "{stage} — pick your squad",
		{&"stage": UiCopyType.stage_title(_stage)},
	)
	var heading := _label("SquadHeading", UiCopyType.stage_title(_stage), &"heading")
	heading.tooltip_text = full_heading
	heading.custom_minimum_size.x = 320.0
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_header.add_child(heading)
	column.add_child(_build_mission_briefing())

	_grid = GridContainer.new()
	_grid.name = "OperatorGrid"
	_grid.columns = 5
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override(&"h_separation", 10)
	_grid.add_theme_constant_override(&"v_separation", 10)
	column.add_child(_grid)
	for op_id: StringName in Game.loadout_operator_ids():
		var definition := load("res://data/operators/%s.tres" % op_id) as OperatorDef
		var pick := AetheriaButtonType.new()
		pick.name = "Pick_%s" % op_id
		pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pick.toggle_mode = true
		pick.apply_role(&"secondary")
		var card_text := UiCopyType.format_text(
			&"ui.squad.operator_card", "{name}\n{cost} DP",
			{&"name": UiCopyType.operator_name(definition), &"cost": definition.dp_cost},
		)
		var compact_card := "%s\n%d DP" % [
			_compact_operator_name(UiCopyType.operator_name(definition)), definition.dp_cost,
		]
		pick.text = card_text
		pick.tooltip_text = card_text.replace("\n", " — ")
		pick.icon = Art.texture(StringName("portrait_%s" % definition.portrait_id))
		pick.expand_icon = true
		pick.add_theme_constant_override(&"icon_max_width", 80)
		pick.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		pick.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pick.custom_minimum_size = Vector2(170.0, 190.0)
		pick.set_presentation_text(card_text, compact_card)
		var card_label := pick.get_node("PresentationLabel") as Label
		card_label.offset_top = 70.0
		pick.toggled.connect(_on_pick_toggled.bind(op_id))
		_grid.add_child(pick)
		_buttons[op_id] = pick

	_footer = GridContainer.new()
	_footer.name = "SquadFooter"
	_footer.columns = 3
	_footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_footer.add_theme_constant_override(&"h_separation", 16)
	_footer.add_theme_constant_override(&"v_separation", 12)
	column.add_child(_footer)
	_counter = _label("PickCounter", "", &"body")
	_counter.custom_minimum_size = Vector2(180.0, 50.0)
	_footer.add_child(_counter)
	var loadout := _label("LoadoutStrip", _loadout_text(), &"detail")
	loadout.custom_minimum_size = Vector2(300.0, 50.0)
	loadout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_footer.add_child(loadout)

	var actions := HBoxContainer.new()
	actions.name = "ActionRow"
	actions.custom_minimum_size.x = 300.0
	actions.add_theme_constant_override(&"separation", 16)
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	_footer.add_child(actions)
	_back = AetheriaButtonType.new()
	_back.name = "BackButton"
	_back.apply_role(&"secondary")
	_back.text = UiCopyType.text(&"ui.common.back", "Back")
	_back.custom_minimum_size = Vector2(140.0, 100.0)
	_back.set_presentation_text(_back.text, _back.text)
	_back.pressed.connect(_on_back)
	actions.add_child(_back)
	_start = AetheriaButtonType.new()
	_start.name = "StartBattle"
	_start.text = UiCopyType.text(&"ui.squad.start_battle", "Start Battle")
	_start.custom_minimum_size = Vector2(140.0, 100.0)
	_start.set_presentation_text(_start.text, "Start\nBattle")
	_start.pressed.connect(_on_start)
	actions.add_child(_start)
	_prefill()
	_refresh()
	_on_layout_mode_changed(shell.layout_mode())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back()


func _build_mission_briefing() -> GridContainer:
	_briefing = GridContainer.new()
	_briefing.name = "MissionBriefingPanel"
	_briefing.columns = 2
	_briefing.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_briefing.add_theme_constant_override(&"h_separation", 20)
	_briefing.add_theme_constant_override(&"v_separation", 6)
	_add_briefing_value("BriefingObjective", &"ui.squad.briefing.objective", "Objective", StageNarrativeDefType.Field.OBJECTIVE)
	_add_briefing_value("BriefingThreat", &"ui.squad.briefing.threat", "Threat", StageNarrativeDefType.Field.THREAT)
	_add_briefing_value("BriefingHumanReason", &"ui.squad.briefing.human_reason", "Why it matters", StageNarrativeDefType.Field.HUMAN_REASON)
	_add_briefing_value("BriefingClue", &"ui.squad.briefing.clue", "Field note", StageNarrativeDefType.Field.CLUE)
	var hint := _label("TacticalHint", "Tactical hint — %s" % UiCopyType.stage_hint(_stage), &"detail")
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_briefing.add_child(hint)
	return _briefing


func _add_briefing_value(node_name: String, key: StringName, fallback: String, field: StageNarrativeDefType.Field) -> void:
	var heading := UiCopyType.text(key, fallback)
	var value := UiCopyType.text(&"ui.error.missing_stage_narrative", "Mission record unavailable. Return to Mission Control.") if _narrative_missing else UiCopyType.stage_narrative_text(_narrative, field)
	var label := _label(node_name, "%s — %s" % [heading, value], &"detail")
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_briefing.add_child(label)


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
		gear.append(UiCopyType.trap_name(trap))
	for spell_id: StringName in Game.loadout_spell_ids():
		var spell := load("res://data/spells/%s.tres" % spell_id) as SpellDef
		gear.append(UiCopyType.spell_name(spell))
	if gear.is_empty():
		return UiCopyType.text(
			&"ui.squad.loadout_none", "Loadout: nothing unlocked yet",
		)
	return UiCopyType.format_text(
		&"ui.squad.loadout_available", "Loadout (always available): {items}",
		{&"items": ", ".join(gear)},
	)


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
	_counter.text = UiCopyType.format_text(
		&"ui.squad.selected_count", "{selected}/{limit} selected",
		{&"selected": _picked.size(), &"limit": _stage.squad_size},
	)
	for raw_id: Variant in _buttons:
		var op_id := StringName(raw_id)
		(_buttons[op_id] as AetheriaButtonType).apply_role(
			&"selected" if _picked.has(op_id) else &"secondary",
		)
	_start.disabled = _picked.is_empty() or _narrative_missing
	_start.focus_mode = Control.FOCUS_NONE if _start.disabled else Control.FOCUS_ALL
	_start.apply_role(&"disabled" if _start.disabled else &"primary")
	_wire_focus()


func _wire_focus() -> void:
	var focusable: Array[Button] = []
	for op_id: StringName in Game.loadout_operator_ids():
		focusable.append(_buttons[op_id] as Button)
	focusable.append(_back)
	if not _start.disabled:
		focusable.append(_start)
	for index: int in focusable.size():
		var current: Button = focusable[index]
		var previous: Button = focusable[(index - 1 + focusable.size()) % focusable.size()]
		var next: Button = focusable[(index + 1) % focusable.size()]
		current.focus_previous = current.get_path_to(previous)
		current.focus_next = current.get_path_to(next)
	if not focusable.is_empty() and get_viewport().gui_get_focus_owner() == null:
		focusable[0].grab_focus.call_deferred()


func _compact_operator_name(full_name: String) -> String:
	const LIMIT := 4
	if full_name.length() <= LIMIT:
		return full_name
	return full_name.left(LIMIT)


func _on_layout_mode_changed(mode: StringName) -> void:
	if _header != null:
		_header.vertical = mode == &"portrait"
	if _briefing != null:
		_briefing.columns = 1 if mode == &"portrait" or mode == &"compact_landscape" else 2
	if _grid == null:
		return
	_grid.columns = 2 if mode == &"portrait" else 5
	for button: Button in _buttons.values():
		button.custom_minimum_size.x = 150.0 if mode == &"compact_landscape" else 170.0
	if _footer != null:
		_footer.columns = 1 if mode == &"portrait" else 3


func _on_back() -> void:
	Sfx.play("ui_click")
	Game.open_stage_select()


func _on_start() -> void:
	Sfx.play("ui_click")
	Game.start_stage(_stage.id, _picked)


func _label(label_name: String, label_text: String, role: StringName) -> AetheriaLabelType:
	var label := AetheriaLabelType.new()
	label.name = label_name
	label.text = label_text
	label.apply_role(role)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label
