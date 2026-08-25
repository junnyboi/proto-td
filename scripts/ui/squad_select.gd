extends Control

const SHELL_SCENE := preload("res://scenes/ui/components/aetheria_screen_shell.tscn")
const AetheriaButtonType := preload("res://scripts/ui/components/aetheria_button.gd")
const AetheriaLabelType := preload("res://scripts/ui/components/aetheria_label.gd")
const AetheriaScreenShellType := preload("res://scripts/ui/components/aetheria_screen_shell.gd")
const LunarisOpsType := preload("res://scripts/ui/components/lunaris_ops_style.gd")
const TrainingSupportType := preload("res://scripts/ui/components/training_support.gd")
const FactionHeraldryType := preload("res://scripts/ui/components/faction_heraldry.gd")
const RosterFilterType := preload("res://scripts/ui/components/roster_filter.gd")
const RosterFilterBarType := preload("res://scripts/ui/components/roster_filter_bar.gd")
const UiCopyType := preload("res://scripts/ui/components/ui_copy.gd")
const HeroIdentityScript := preload("res://sim/hero_identity.gd")
const HeroNamesScript := preload("res://sim/hero_names.gd")
const NARRATIVE_CATALOG := preload("res://data/presentation/narrative/stage_narrative_catalog.tres")
const StageNarrativeDefType := preload("res://data/presentation/narrative/stage_narrative_def.gd")
const StageNarrativeCatalogType := preload("res://data/presentation/narrative/stage_narrative_catalog.gd")
const BACKDROP := preload("res://assets/loading/lunaris_reliquary_loading.png")
const SHELL_SIZE := Vector2(1210.0, 660.0)
const COMPACT_SHELL_SIZE := Vector2(920.0, 680.0)
const PORTRAIT_SHELL_SIZE := Vector2(680.0, 1180.0)

var _stage: StageDef = null
var _shell: AetheriaScreenShellType = null
var _picked: Array[StringName] = []
var _narrative: StageNarrativeDefType = null
var _narrative_missing := false
var _buttons: Dictionary = {}
var _hero_order: Array[StringName] = []
var _ready_heroes: Array[Dictionary] = []
var _filter_toolbar: BoxContainer
var _filter_input: LineEdit
var _sort_select: OptionButton
var _filter_summary: AetheriaLabelType
var _name_filter := ""
var _name_sort: StringName = &"recruitment"
var _counter: Label = null
var _selected_line: Label = null
var _start: AetheriaButtonType = null
var _training: AetheriaButtonType = null
var _back: AetheriaButtonType = null
var _grid: GridContainer = null
var _body: GridContainer = null
var _roster_scroll: ScrollContainer = null
var _intel_scroll: ScrollContainer = null
var _footer: BoxContainer = null
var _header: BoxContainer = null
var _actions: GridContainer = null
var _filter_bar: RosterFilterBarType = null
var _roster_empty: Label = null
var _all_roster_rows: Array[Dictionary] = []
var _filter_status: StringName = RosterFilterType.STATUS_ACTIVE
var _filter_faction: StringName = RosterFilterType.FACTION_ALL


func _ready() -> void:
	Game.content = self
	_stage = load("res://data/stages/%s.tres" % Game.selected_stage_id) as StageDef
	_narrative = (NARRATIVE_CATALOG as StageNarrativeCatalogType).get_record(Game.selected_stage_id)
	_narrative_missing = _narrative == null
	_ready_heroes = _identity_rows(Game.campaign_projection()["ready_heroes"])
	LunarisOpsType.add_backdrop(self, BACKDROP)
	_shell = SHELL_SCENE.instantiate() as AetheriaScreenShellType
	_shell.name = "MissionCommandShell"
	_shell.preferred_size = SHELL_SIZE
	add_child(_shell)
	_shell.layout_mode_changed.connect(_on_layout_mode_changed)
	LunarisOpsType.apply_panel(_shell.reading_plate() as PanelContainer, &"screen")

	var surface := VBoxContainer.new()
	surface.name = "MissionCommandSurface"
	surface.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	surface.size_flags_vertical = Control.SIZE_EXPAND_FILL
	surface.add_theme_constant_override(&"separation", 12)
	_shell.content_host().add_child(surface)
	var scroll := ScrollContainer.new()
	scroll.name = "MissionCommandScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	surface.add_child(scroll)
	var column := VBoxContainer.new()
	column.name = "MissionCommandColumn"
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override(&"separation", 16)
	scroll.add_child(column)
	column.add_child(_build_header())
	column.add_child(_build_body())
	surface.add_child(_build_footer())

	_prefill()
	_refresh()
	_on_layout_mode_changed(_shell.layout_mode())


func _build_header() -> BoxContainer:
	_header = BoxContainer.new()
	_header.name = "MissionHeader"
	_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_header.add_theme_constant_override(&"separation", 18)
	var identity := HBoxContainer.new()
	identity.name = "MissionFactionIdentity"
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override(&"separation", 12)
	var symbol := FactionHeraldryType.make_symbol(FactionHeraldryType.ACTIVE_FACTION, 52.0)
	symbol.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	identity.add_child(symbol)
	var title_block := VBoxContainer.new()
	title_block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_block.add_theme_constant_override(&"separation", 0)
	title_block.add_child(_label("MissionIndex", "MISSION 01 / OLD CUT", &"eyebrow"))
	title_block.add_child(_label("MissionTitle", UiCopyType.stage_title(_stage).to_upper(), &"title"))
	identity.add_child(title_block)
	_header.add_child(identity)
	var status := VBoxContainer.new()
	status.custom_minimum_size.x = 220.0
	status.alignment = BoxContainer.ALIGNMENT_CENTER
	var threat := _label("ThreatLabel", "RELIQUARY THREAT", &"eyebrow")
	threat.autowrap_mode = TextServer.AUTOWRAP_OFF
	threat.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status.add_child(threat)
	var limit := _label("SquadLimit", "SQUAD LIMIT %d" % _stage.squad_size, &"metric")
	limit.autowrap_mode = TextServer.AUTOWRAP_OFF
	limit.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status.add_child(limit)
	_header.add_child(status)
	return _header


func _build_body() -> GridContainer:
	_body = GridContainer.new()
	_body.name = "MissionBody"
	_body.columns = 2
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.custom_minimum_size.y = 300.0
	_body.add_theme_constant_override(&"h_separation", 16)
	_body.add_theme_constant_override(&"v_separation", 16)

	var roster_panel := PanelContainer.new()
	roster_panel.name = "FieldTeamPanel"
	roster_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	roster_panel.size_flags_stretch_ratio = 2.1
	roster_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	LunarisOpsType.apply_panel(roster_panel, &"quiet")
	var roster_column := VBoxContainer.new()
	roster_column.add_theme_constant_override(&"separation", 12)
	roster_panel.add_child(roster_column)
	var roster_heading := HBoxContainer.new()
	var roster_title := _label("FieldTeamHeading", "FIELD TEAM", &"heading")
	roster_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	roster_heading.add_child(roster_title)
	_counter = _label("PickCounter", "", &"metric")
	_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	roster_heading.add_child(_counter)
	roster_column.add_child(roster_heading)
	_all_roster_rows = _campaign_roster_rows()
	_filter_bar = RosterFilterBarType.new()
	_filter_bar.configure(
		_all_roster_rows, true, RosterFilterType.STATUS_ACTIVE, RosterFilterType.FACTION_ALL,
	)
	_filter_bar.filters_changed.connect(_on_filters_changed)
	roster_column.add_child(_filter_bar)
	roster_column.add_child(_build_identity_filter_toolbar())
	_roster_empty = _label(
		"RosterEmptyState",
		UiCopyType.text(&"ui.roster.empty", "No soldiers match the selected roster filters."),
		&"detail",
	)
	_roster_empty.visible = false
	roster_column.add_child(_roster_empty)
	_roster_scroll = ScrollContainer.new()
	_roster_scroll.name = "OperatorRosterScroll"
	_roster_scroll.custom_minimum_size.y = 270.0
	_roster_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_roster_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_roster_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	roster_column.add_child(_roster_scroll)
	_grid = GridContainer.new()
	_grid.name = "OperatorGrid"
	_grid.columns = 3
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override(&"h_separation", 10)
	_grid.add_theme_constant_override(&"v_separation", 10)
	_roster_scroll.add_child(_grid)
	_rebuild_operator_cards()
	_body.add_child(roster_panel)

	var briefing_panel := PanelContainer.new()
	briefing_panel.name = "MissionIntelligencePanel"
	briefing_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	briefing_panel.size_flags_stretch_ratio = 1.0
	briefing_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	LunarisOpsType.apply_panel(briefing_panel, &"quiet")
	_intel_scroll = ScrollContainer.new()
	_intel_scroll.name = "MissionIntelScroll"
	_intel_scroll.custom_minimum_size.y = 270.0
	_intel_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_intel_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_intel_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	briefing_panel.add_child(_intel_scroll)
	var intel := VBoxContainer.new()
	intel.add_theme_constant_override(&"separation", 9)
	intel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_intel_scroll.add_child(intel)
	intel.add_child(_label("MissionIntelHeading", "MISSION INTELLIGENCE", &"heading"))
	_add_intel_item(intel, "OBJECTIVE", StageNarrativeDefType.Field.OBJECTIVE)
	_add_intel_item(intel, "THREAT", StageNarrativeDefType.Field.THREAT)
	_add_intel_item(intel, "WHY IT MATTERS", StageNarrativeDefType.Field.HUMAN_REASON)
	_add_intel_item(intel, "FIELD NOTE", StageNarrativeDefType.Field.CLUE)
	intel.add_child(_label("TacticalHeading", "TACTICAL ASSET", &"eyebrow"))
	intel.add_child(_label("TacticalHint", UiCopyType.stage_hint(_stage), &"body"))
	intel.add_child(_label("LoadoutHeading", "LOADOUT", &"eyebrow"))
	intel.add_child(_label("LoadoutStrip", _loadout_text(), &"detail"))
	_selected_line = _label("SelectedSquadLine", "", &"detail")
	intel.add_child(_selected_line)
	_body.add_child(briefing_panel)
	return _body


func _campaign_roster_rows() -> Array[Dictionary]:
	var projection: Dictionary = Game.campaign_projection()
	var rows: Array = []
	rows.append_array(projection.get("ready_heroes", []))
	rows.append_array(projection.get("fallen_heroes", []))
	return RosterFilterType.annotate_all(_identity_rows(rows))


func _identity_rows(raw_rows: Array) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for raw: Variant in raw_rows:
		var hero := (raw as Dictionary).duplicate(true)
		hero["callsign"] = _hero_callsign(hero)
		if not hero.has("custom_title"):
			hero["custom_title"] = null
		rows.append(hero)
	return rows


func _build_identity_filter_toolbar() -> BoxContainer:
	_filter_toolbar = BoxContainer.new()
	_filter_toolbar.name = "DeploymentIdentityToolbar"
	_filter_toolbar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_filter_toolbar.add_theme_constant_override(&"separation", 8)
	_filter_input = LineEdit.new()
	_filter_input.name = "DeploymentNameFilter"
	_filter_input.text = _name_filter
	_filter_input.placeholder_text = UiCopyType.text(
		&"ui.identity_filter.placeholder", "Filter by name or title",
	)
	_filter_input.clear_button_enabled = true
	_filter_input.custom_minimum_size = Vector2(240.0, 50.0)
	_filter_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	LunarisOpsType.apply_line_edit(_filter_input)
	_filter_input.text_changed.connect(_on_name_filter_changed)
	_filter_toolbar.add_child(_filter_input)
	_sort_select = OptionButton.new()
	_sort_select.name = "DeploymentNameSort"
	_sort_select.custom_minimum_size = Vector2(200.0, 50.0)
	_sort_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for option: Dictionary in [
		{"id": &"recruitment", "label": UiCopyType.text(&"ui.identity_sort.recruitment", "Recruitment order")},
		{"id": &"name_asc", "label": UiCopyType.text(&"ui.identity_sort.name_asc", "Name A–Z")},
		{"id": &"name_desc", "label": UiCopyType.text(&"ui.identity_sort.name_desc", "Name Z–A")},
	]:
		_sort_select.add_item(String(option["label"]))
		var option_index := _sort_select.item_count - 1
		_sort_select.set_item_metadata(option_index, option["id"])
		if option["id"] == _name_sort:
			_sort_select.select(option_index)
	LunarisOpsType.apply_button(_sort_select, &"secondary")
	_sort_select.item_selected.connect(_on_name_sort_selected)
	_filter_toolbar.add_child(_sort_select)
	_filter_summary = _label("DeploymentFilterSummary", "", &"dense_detail")
	_filter_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_filter_toolbar.add_child(_filter_summary)
	return _filter_toolbar


func _on_name_filter_changed(value: String) -> void:
	_name_filter = value
	_rebuild_operator_cards()
	_refresh()
	if _filter_input != null:
		_filter_input.caret_column = _filter_input.text.length()
		_filter_input.grab_focus.call_deferred()


func _on_name_sort_selected(index: int) -> void:
	if _sort_select == null:
		return
	_name_sort = StringName(_sort_select.get_item_metadata(index))
	_rebuild_operator_cards()
	_refresh()
	if _sort_select != null:
		_sort_select.grab_focus.call_deferred()


func _build_operator_cards() -> void:
	_rebuild_operator_cards()


func _rebuild_operator_cards() -> void:
	if _grid == null:
		return
	for child: Node in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	_buttons.clear()
	_hero_order.clear()
	var status_rows := RosterFilterType.filter_rows(
		_all_roster_rows, _filter_status, _filter_faction,
	)
	var visible_rows := TrainingSupportType.filtered_sorted(
		status_rows, _name_filter, _name_sort,
	)
	if _filter_summary != null:
		_filter_summary.text = UiCopyType.format_text(
			&"ui.identity_filter.summary", "{shown} / {total} shown",
			{&"shown": visible_rows.size(), &"total": status_rows.size()},
		)
	if _roster_empty != null:
		_roster_empty.visible = visible_rows.is_empty()
	if visible_rows.is_empty():
		_grid.columns = 1
		return
	_grid.columns = 1 if _shell.layout_mode() == &"portrait" else (
		2 if _shell.layout_mode() == &"compact_landscape" else 3
	)
	for hero: Dictionary in visible_rows:
		var hero_id := StringName(hero["hero_id"])
		var op_id := StringName(hero["operator_def_id"])
		var definition := load("res://data/operators/%s.tres" % op_id) as OperatorDef
		var pick := AetheriaButtonType.new()
		pick.name = "Pick_%s" % hero_id
		pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pick.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var fallen := bool(hero.get("fallen", false))
		pick.toggle_mode = not fallen
		var card_text := "%s\n%d DP • READY" % [_hero_label(hero), definition.dp_cost]
		if hero.get("hero_kind", "recruit") == "premium":
			var lives := int(hero.get("premium_lives", 0))
			card_text = "%s\n%d DP • PREMIUM • %d %s" % [
				_hero_label(hero), definition.dp_cost, lives,
				"LIFE" if lives == 1 else "LIVES",
			]
		if fallen:
			card_text = "%s\nFALLEN • VAHALLA" % _hero_label(hero)
		pick.text = card_text
		pick.tooltip_text = card_text.replace("\n", " — ")
		pick.icon = Art.texture(StringName(hero["portrait_asset_id"]))
		pick.expand_icon = true
		pick.add_theme_constant_override(&"icon_max_width", 112)
		pick.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		pick.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pick.custom_minimum_size = Vector2(190.0, 220.0)
		pick.set_presentation_text(card_text, card_text)
		pick.disabled = fallen
		pick.focus_mode = Control.FOCUS_NONE if fallen else Control.FOCUS_ALL
		var card_label := pick.get_node("PresentationLabel") as Label
		card_label.offset_top = 106.0
		card_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		card_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		if not fallen:
			pick.set_pressed_no_signal(_picked.has(hero_id))
			pick.toggled.connect(_on_pick_toggled.bind(hero_id))
		_grid.add_child(pick)
		if not fallen:
			_buttons[hero_id] = pick
			_hero_order.append(hero_id)
		else:
			LunarisOpsType.apply_button(pick, &"disabled")


func _build_footer() -> BoxContainer:
	_footer = BoxContainer.new()
	_footer.name = "MissionActionDock"
	_footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_footer.add_theme_constant_override(&"separation", 16)
	var readiness := VBoxContainer.new()
	readiness.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	readiness.add_child(_label("ReadinessEyebrow", "PRE-DEPLOYMENT", &"eyebrow"))
	readiness.add_child(_label("ReadinessCopy", "Train, review, then commit the field team.", &"detail"))
	_footer.add_child(readiness)
	_actions = GridContainer.new()
	_actions.name = "MissionActions"
	_actions.columns = 3
	_actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_actions.add_theme_constant_override(&"h_separation", 10)
	_actions.add_theme_constant_override(&"v_separation", 10)
	_footer.add_child(_actions)
	_back = _action("BackButton", "BACK", &"secondary")
	_back.pressed.connect(_on_back)
	_actions.add_child(_back)
	_training = _action("TrainingButton", "TRAIN OPERATORS", &"gold")
	_training.pressed.connect(_on_training)
	_actions.add_child(_training)
	_start = _action("StartBattle", "DEPLOY SQUAD", &"primary")
	_start.pressed.connect(_on_start)
	_actions.add_child(_start)
	return _footer


func _action(node_name: String, text_value: String, role: StringName) -> AetheriaButtonType:
	var button := AetheriaButtonType.new()
	button.name = node_name
	button.text = text_value
	button.custom_minimum_size = Vector2(170.0, 62.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.set_presentation_text(text_value, text_value)
	LunarisOpsType.apply_button(button, role)
	var presentation := button.get_node("PresentationLabel") as Label
	presentation.add_theme_font_size_override(&"font_size", 18)
	return button


func _add_intel_item(parent: VBoxContainer, heading: String, field: StageNarrativeDefType.Field) -> void:
	parent.add_child(_label("%sLabel" % heading.replace(" ", ""), heading, &"eyebrow"))
	var value := (
		"Mission record unavailable. Return to Mission Control."
		if _narrative_missing
		else UiCopyType.stage_narrative_text(_narrative, field)
	)
	parent.add_child(_label("%sValue" % heading.replace(" ", ""), value, &"detail"))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back()


func _prefill() -> void:
	for hero_id: StringName in Game.selected_squad:
		if _picked.size() >= _stage.squad_size:
			break
		if _buttons.has(hero_id):
			_picked.append(hero_id)
			(_buttons[hero_id] as Button).set_pressed_no_signal(true)


func _loadout_text() -> String:
	var gear: Array[String] = []
	for trap_id: StringName in Game.loadout_trap_ids():
		var trap := load("res://data/traps/%s.tres" % trap_id) as TrapDef
		gear.append(UiCopyType.trap_name(trap))
	for spell_id: StringName in Game.loadout_spell_ids():
		var spell := load("res://data/spells/%s.tres" % spell_id) as SpellDef
		gear.append(UiCopyType.spell_name(spell))
	return "NOTHING UNLOCKED" if gear.is_empty() else " • ".join(gear).to_upper()


func _on_pick_toggled(pressed: bool, hero_id: StringName) -> void:
	if pressed:
		if _picked.size() >= _stage.squad_size:
			(_buttons[hero_id] as Button).set_pressed_no_signal(false)
			return
		_picked.append(hero_id)
	else:
		_picked.erase(hero_id)
	_refresh()


func _refresh() -> void:
	_counter.text = "%d / %d SELECTED" % [_picked.size(), _stage.squad_size]
	for raw_id: Variant in _buttons:
		var hero_id := StringName(raw_id)
		var button := _buttons[hero_id] as AetheriaButtonType
		LunarisOpsType.apply_button(button, &"selected" if _picked.has(hero_id) else &"secondary")
	var selected_names: Array[String] = []
	for hero_id: StringName in _picked:
		var hero := _hero_by_id(hero_id)
		if not hero.is_empty():
			selected_names.append(_hero_callsign(hero))
	_selected_line.text = "FIELD TEAM // %s" % (
		"AWAITING SELECTION" if selected_names.is_empty() else " • ".join(selected_names)
	)
	_start.disabled = _picked.is_empty() or _narrative_missing
	_start.focus_mode = Control.FOCUS_NONE if _start.disabled else Control.FOCUS_ALL
	LunarisOpsType.apply_button(_start, &"disabled" if _start.disabled else &"primary")
	_wire_focus()


func _on_filters_changed(status: StringName, faction_id: StringName) -> void:
	_filter_status = status
	_filter_faction = faction_id
	_rebuild_operator_cards()
	_refresh()


func _hero_by_id(hero_id: StringName) -> Dictionary:
	for hero: Dictionary in _all_roster_rows:
		if StringName(hero["hero_id"]) == hero_id:
			return hero
	return {}


func _wire_focus() -> void:
	var focusable: Array[Control] = []
	if _filter_input != null:
		focusable.append(_filter_input)
	if _sort_select != null:
		focusable.append(_sort_select)
	for hero_id: StringName in _hero_order:
		focusable.append(_buttons[hero_id] as Button)
	focusable.append(_back)
	focusable.append(_training)
	if not _start.disabled:
		focusable.append(_start)
	for index: int in focusable.size():
		var current: Control = focusable[index]
		var previous: Control = focusable[(index - 1 + focusable.size()) % focusable.size()]
		var next: Control = focusable[(index + 1) % focusable.size()]
		current.focus_previous = current.get_path_to(previous)
		current.focus_next = current.get_path_to(next)
	if not focusable.is_empty() and get_viewport().gui_get_focus_owner() == null:
		focusable[0].grab_focus.call_deferred()


func _hero_callsign(hero: Dictionary) -> String:
	var callsign := String(hero.get("callsign", ""))
	if callsign.is_empty() and hero.get("custom_callsign") != null:
		callsign = String(hero["custom_callsign"])
	if callsign.is_empty():
		var parsed := HeroIdentityScript.parse_u64_hex(String(hero["hero_id"]))
		if parsed["accepted"]:
			callsign = String(HeroNamesScript.default_name(
				int(parsed["bits"]), int(hero["name_version"]),
			).get("value", hero["hero_id"]))
	if callsign.is_empty():
		callsign = UiCopyType.operator_name(
			load("res://data/operators/%s.tres" % hero["operator_def_id"]) as OperatorDef,
		)
	return callsign


func _hero_label(hero: Dictionary) -> String:
	var class_id := String(hero["current_class_id"])
	var class_label := UiCopyType.text(
		StringName("ui.training.class.%s" % class_id), class_id.replace("_", " ").capitalize(),
	)
	var identity := "%s #%d" % [
		_hero_callsign(hero).to_upper(), int(hero["recruitment_index"]) + 1,
	]
	var title := String(
		hero.get("custom_title", "") if hero.get("custom_title") != null else "",
	)
	if not title.is_empty():
		identity += "\n%s" % title.to_upper()
	return "%s\n%s" % [identity, class_label.to_upper()]


func _on_layout_mode_changed(mode: StringName) -> void:
	if _shell != null:
		var target_size := SHELL_SIZE
		if mode == &"portrait":
			target_size = PORTRAIT_SHELL_SIZE
		elif mode == &"compact_landscape":
			target_size = COMPACT_SHELL_SIZE
		if _shell.preferred_size != target_size:
			_shell.preferred_size = target_size
	if _header != null:
		_header.vertical = mode == &"portrait"
	if _filter_toolbar != null:
		_filter_toolbar.vertical = mode == &"portrait"
	if _filter_summary != null:
		_filter_summary.horizontal_alignment = (
			HORIZONTAL_ALIGNMENT_LEFT
			if mode == &"portrait"
			else HORIZONTAL_ALIGNMENT_RIGHT
		)
	if _body != null:
		_body.columns = 1 if mode == &"portrait" else 2
	if _roster_scroll != null:
		_roster_scroll.custom_minimum_size.y = 270.0
	if _intel_scroll != null:
		_intel_scroll.custom_minimum_size.y = 170.0 if mode == &"portrait" else 270.0
	if _grid != null:
		_grid.columns = 1 if mode == &"portrait" else (2 if mode == &"compact_landscape" else 3)
	if _filter_bar != null:
		_filter_bar.set_compact(mode != &"regular_landscape")
	for button: Button in _buttons.values():
		button.custom_minimum_size = Vector2(
			180.0, 190.0 if mode == &"portrait" else 220.0,
		)
	if _footer != null:
		_footer.vertical = mode == &"portrait"
	if _actions != null:
		_actions.columns = 1 if mode == &"portrait" else 3


func _on_training() -> void:
	Sfx.play("ui_click")
	Game.training_call(&"open", &"mission")


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
	label.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART if role in [&"body", &"detail"]
		else TextServer.AUTOWRAP_OFF
	)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	LunarisOpsType.apply_label(label, role)
	return label
