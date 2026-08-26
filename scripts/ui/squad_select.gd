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
const StagingSkinType := preload("res://scripts/ui/components/staging_skin.gd")
const HeroIdentityScript := preload("res://sim/hero_identity.gd")
const HeroNamesScript := preload("res://sim/hero_names.gd")
const NARRATIVE_CATALOG := preload("res://data/presentation/narrative/stage_narrative_catalog.tres")
const StageNarrativeDefType := preload("res://data/presentation/narrative/stage_narrative_def.gd")
const StageNarrativeCatalogType := preload("res://data/presentation/narrative/stage_narrative_catalog.gd")
const BACKDROP := preload("res://assets/loading/lunaris_reliquary_loading.png")
const ACTION_SAFE_INSET := 12.0
const OPERATOR_INFO_SPLIT := 0.56
const FIELD_TEAM_WIDTH_RATIO := 0.60
const INTEL_WIDTH_RATIO := 0.40
const OPERATOR_CARD_WIDTH := 640.0
const OPERATOR_CARD_HEIGHT := 220.0
const OPERATOR_CARD_TALL_HEIGHT := 280.0
const LOADOUT_TOP_PADDING := 24
const SORT_HORIZONTAL_PADDING := 24.0
const SORT_VERTICAL_PADDING := 12.0
const FIELD_TEAM_FACTION_WIDTH_SCALE := 1.5
const FIELD_TEAM_FACTION_ICON_COUNT_GAP := 6
const ACTION_HORIZONTAL_GAP := 28
const ACTION_VERTICAL_GAP := 24
const DEPLOY_SQUAD_ACTION_WIDTH := 588.0
const DEPLOY_SQUAD_ACTION_HEIGHT := 112.0
const COMPACT_ACTION_STACK_THRESHOLD := 1280.0
const FOOTER_STACK_THRESHOLD := 1800.0
const DEPLOY_READY_PULSE_SCALE := Vector2(1.018, 1.018)
const DEPLOY_READY_PULSE_RISE_SECONDS := 0.82
const DEPLOY_READY_PULSE_FALL_SECONDS := 1.08
const DEPLOY_TEXT_COLOR := Color("fff8e7")
const DEPLOY_TEXT_OUTLINE := Color("09070d")

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
var _launch_status: AetheriaLabelType = null
var _launch_locked := false
var _launch_error_code: StringName = &""
var _training: AetheriaButtonType = null
var _back: AetheriaButtonType = null
var _grid: GridContainer = null
var _body: GridContainer = null
var _command_scroll: ScrollContainer = null
var _roster_scroll: ScrollContainer = null
var _intel_scroll: ScrollContainer = null
var _roster_panel: PanelContainer = null
var _intel_panel: PanelContainer = null
var _footer: BoxContainer = null
var _header: BoxContainer = null
var _header_identity: BoxContainer = null
var _header_status: VBoxContainer = null
var _roster_heading: BoxContainer = null
var _actions: GridContainer = null
var _filter_bar: RosterFilterBarType = null
var _roster_empty: Label = null
var _all_roster_rows: Array[Dictionary] = []
var _filter_status: StringName = RosterFilterType.STATUS_ACTIVE
var _filter_faction: StringName = RosterFilterType.FACTION_ALL
var _recruitment_grid: GridContainer = null
var _hire_title: AetheriaLabelType = null
var _hire_recruit: AetheriaButtonType = null
var _hire_marks: AetheriaLabelType = null
var _hire_status: AetheriaLabelType = null
var _deploy_pulse_tween: Tween = null
var _deploy_ready_pulsing := false


func _ready() -> void:
	Game.content = self
	_stage = load("res://data/stages/%s.tres" % Game.selected_stage_id) as StageDef
	_narrative = (NARRATIVE_CATALOG as StageNarrativeCatalogType).get_record(Game.selected_stage_id)
	_narrative_missing = _narrative == null
	_ready_heroes = _identity_rows(Game.campaign_projection()["ready_heroes"])
	LunarisOpsType.add_backdrop(self, BACKDROP)
	_shell = SHELL_SCENE.instantiate() as AetheriaScreenShellType
	_shell.name = "MissionCommandShell"
	_shell.full_safe_area = true
	add_child(_shell)
	_shell.layout_mode_changed.connect(_on_layout_mode_changed)
	var reading_plate := _shell.reading_plate() as PanelContainer
	reading_plate.name = "MissionFullscreenWorkspace"
	reading_plate.add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())

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
	_command_scroll = scroll
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
	_refresh_recruitment_desk()
	_refresh()
	_on_layout_mode_changed(_shell.layout_mode())
	if not I18n.locale_changed.is_connected(_on_locale_changed):
		I18n.locale_changed.connect(_on_locale_changed)


func _exit_tree() -> void:
	_stop_deploy_ready_pulse()


func _build_header() -> BoxContainer:
	_header = BoxContainer.new()
	_header.name = "MissionHeader"
	_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_header.add_theme_constant_override(&"separation", 18)
	var identity := BoxContainer.new()
	_header_identity = identity
	identity.name = "MissionFactionIdentity"
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override(&"separation", 12)
	var symbol := FactionHeraldryType.make_symbol(FactionHeraldryType.ACTIVE_FACTION, 78.0)
	symbol.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	identity.add_child(symbol)
	var title_block := VBoxContainer.new()
	title_block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_block.add_theme_constant_override(&"separation", 0)
	title_block.add_child(_label(
		"MissionIndex",
		_format_copy(
			&"ui.squad.mission_identity", "Mission {index} / {title}",
			{&"index": "%02d" % _stage.campaign_index, &"title": UiCopyType.stage_title(_stage)},
		),
		&"eyebrow",
	))
	title_block.add_child(_label("MissionTitle", UiCopyType.stage_title(_stage), &"title"))
	identity.add_child(title_block)
	_header.add_child(identity)
	_header_status = VBoxContainer.new()
	_header_status.name = "MissionStatus"
	_header_status.custom_minimum_size.x = 280.0
	_header_status.alignment = BoxContainer.ALIGNMENT_CENTER
	var threat := _label(
		"ThreatLabel", UiCopyType.text(&"ui.squad.briefing.threat", "Threat"), &"eyebrow",
	)
	threat.autowrap_mode = TextServer.AUTOWRAP_OFF
	threat.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_header_status.add_child(threat)
	var limit := _label(
		"SquadLimit",
		_format_copy(&"ui.squad.limit", "Squad limit {limit}", {&"limit": _stage.squad_size}),
		&"metric",
	)
	limit.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_header_status.add_child(limit)
	_header.add_child(_header_status)
	return _header


func _build_body() -> GridContainer:
	_body = GridContainer.new()
	_body.name = "MissionBody"
	_body.columns = 2
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.custom_minimum_size.y = 0.0
	_body.add_theme_constant_override(&"h_separation", 16)
	_body.add_theme_constant_override(&"v_separation", 16)

	var roster_panel := PanelContainer.new()
	_roster_panel = roster_panel
	roster_panel.name = "FieldTeamPanel"
	roster_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	roster_panel.size_flags_stretch_ratio = 3.0
	roster_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var roster_style := LunarisOpsType.panel_style(&"workspace")
	roster_style.content_margin_left = 8.0
	roster_style.content_margin_top = 8.0
	roster_style.content_margin_right = 8.0
	roster_style.content_margin_bottom = 8.0
	roster_panel.add_theme_stylebox_override(&"panel", roster_style)
	var roster_column := VBoxContainer.new()
	roster_column.add_theme_constant_override(&"separation", 6)
	roster_panel.add_child(roster_column)
	_roster_heading = BoxContainer.new()
	_roster_heading.name = "FieldTeamHeader"
	var roster_title := _label(
		"FieldTeamHeading", UiCopyType.text(&"ui.squad.field_team", "Field Team"), &"heading",
	)
	roster_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_roster_heading.add_child(roster_title)
	_counter = _label("PickCounter", "", &"metric")
	_counter.custom_minimum_size.x = 178.0
	_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_roster_heading.add_child(_counter)
	roster_column.add_child(_roster_heading)
	_all_roster_rows = _campaign_roster_rows()
	_filter_bar = RosterFilterBarType.new()
	_filter_bar.configure(
		_all_roster_rows, true, RosterFilterType.STATUS_ACTIVE, RosterFilterType.FACTION_ALL,
	)
	_filter_bar.set_faction_button_geometry(
		FIELD_TEAM_FACTION_WIDTH_SCALE, FIELD_TEAM_FACTION_ICON_COUNT_GAP,
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
	_roster_scroll.custom_minimum_size.y = 0.0
	_roster_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_roster_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_roster_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	roster_column.add_child(_roster_scroll)
	_grid = GridContainer.new()
	_grid.name = "OperatorGrid"
	_grid.columns = 2
	_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_grid.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_grid.add_theme_constant_override(&"h_separation", 12)
	_grid.add_theme_constant_override(&"v_separation", 10)
	_roster_scroll.add_child(_grid)
	_rebuild_operator_cards()
	_body.add_child(roster_panel)

	var briefing_panel := PanelContainer.new()
	_intel_panel = briefing_panel
	briefing_panel.name = "MissionIntelligencePanel"
	briefing_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	briefing_panel.size_flags_stretch_ratio = 2.0
	briefing_panel.custom_minimum_size.x = 0.0
	briefing_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	LunarisOpsType.apply_panel(briefing_panel, &"workspace")
	_intel_scroll = ScrollContainer.new()
	_intel_scroll.name = "MissionIntelScroll"
	_intel_scroll.custom_minimum_size.y = 0.0
	_intel_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_intel_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_intel_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	briefing_panel.add_child(_intel_scroll)
	var intel := VBoxContainer.new()
	intel.add_theme_constant_override(&"separation", 9)
	intel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_intel_scroll.add_child(intel)
	intel.add_child(_label(
		"MissionIntelHeading",
		UiCopyType.text(&"ui.squad.mission_intelligence", "Mission Intelligence"),
		&"heading",
	))
	_add_intel_item(intel, "OBJECTIVE", &"ui.squad.briefing.objective", "Objective", StageNarrativeDefType.Field.OBJECTIVE)
	_add_intel_item(intel, "THREAT", &"ui.squad.briefing.threat", "Threat", StageNarrativeDefType.Field.THREAT)
	_add_intel_item(intel, "WHYITMATTERS", &"ui.squad.briefing.human_reason", "Why it matters", StageNarrativeDefType.Field.HUMAN_REASON)
	intel.add_child(_label(
		"TacticalHeading",
		UiCopyType.text(&"ui.squad.tactical_asset_heading", "Tactical Asset"),
		&"eyebrow",
	))
	intel.add_child(_label("TacticalHint", UiCopyType.stage_hint(_stage), &"body"))
	var loadout_inset := MarginContainer.new()
	loadout_inset.name = "LoadoutHeadingInset"
	loadout_inset.add_theme_constant_override(&"margin_top", LOADOUT_TOP_PADDING)
	loadout_inset.add_child(_label(
		"LoadoutHeading", UiCopyType.text(&"ui.squad.loadout_heading", "Loadout"), &"heading",
	))
	intel.add_child(loadout_inset)
	intel.add_child(_label("LoadoutStrip", _loadout_text(), &"detail"))
	_selected_line = _label("SelectedSquadLine", "", &"detail")
	intel.add_child(_selected_line)
	_build_recruitment_desk(intel)
	_body.add_child(briefing_panel)
	return _body


func _build_recruitment_desk(parent: VBoxContainer) -> void:
	var panel := PanelContainer.new()
	panel.name = "BasicRecruitDesk"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	LunarisOpsType.apply_panel(panel, &"selected")
	parent.add_child(panel)
	var stack := VBoxContainer.new()
	stack.name = "BasicRecruitStack"
	stack.add_theme_constant_override(&"separation", 10)
	panel.add_child(stack)
	_recruitment_grid = GridContainer.new()
	_recruitment_grid.name = "BasicRecruitGrid"
	_recruitment_grid.columns = 1
	_recruitment_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_recruitment_grid.add_theme_constant_override(&"v_separation", 10)
	stack.add_child(_recruitment_grid)
	_hire_title = AetheriaLabelType.new()
	_hire_title.name = "BasicRecruitTitle"
	_hire_title.apply_role(&"dense_heading")
	_hire_title.add_theme_font_size_override(&"font_size", 24)
	_hire_title.text = UiCopyType.text(
		&"ui.campaign.basic_hire_title", "Company Reinforcements",
	).to_upper()
	_hire_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_recruitment_grid.add_child(_hire_title)
	_hire_marks = AetheriaLabelType.new()
	_hire_marks.name = "BasicRecruitMarks"
	_hire_marks.apply_role(&"cost_badge")
	_hire_marks.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hire_marks.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_recruitment_grid.add_child(_hire_marks)
	_hire_recruit = AetheriaButtonType.new()
	_hire_recruit.name = "HireBasicRecruit"
	_hire_recruit.custom_minimum_size = Vector2(220.0, 72.0)
	_hire_recruit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hire_recruit.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_hire_recruit.apply_role(&"primary")
	_apply_clean_training_style(_hire_recruit)
	_hire_recruit.pressed.connect(_on_hire_basic_recruit)
	_hire_recruit.accessibility_name = UiCopyType.text(
		&"ui.campaign.basic_hire_title", "Company Reinforcements",
	)
	_recruitment_grid.add_child(_hire_recruit)
	_hire_status = AetheriaLabelType.new()
	_hire_status.name = "BasicRecruitStatus"
	_hire_status.apply_role(&"dense_detail")
	_hire_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hire_status.accessibility_name = UiCopyType.text(
		&"ui.campaign.basic_hire_title", "Company Reinforcements",
	)
	_hire_status.accessibility_live = AccessibilityServer.LIVE_OFF
	stack.add_child(_hire_status)


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
		&"ui.identity_filter.placeholder", "Filter operators",
	)
	_filter_input.clear_button_enabled = true
	_filter_input.custom_minimum_size = Vector2(180.0, 54.0)
	_filter_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	LunarisOpsType.apply_line_edit(_filter_input)
	_filter_input.add_theme_font_size_override(&"font_size", 24)
	_filter_input.text_changed.connect(_on_name_filter_changed)
	_filter_toolbar.add_child(_filter_input)
	_sort_select = OptionButton.new()
	_sort_select.name = "DeploymentNameSort"
	_sort_select.custom_minimum_size = Vector2(300.0, 54.0)
	_sort_select.size_flags_horizontal = Control.SIZE_SHRINK_END
	_sort_select.fit_to_longest_item = false
	_sort_select.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	for option: Dictionary in [
		{"id": &"recruitment", "label": UiCopyType.text(&"ui.identity_sort.recruitment", "Recruit order")},
		{"id": &"name_asc", "label": UiCopyType.text(&"ui.identity_sort.name_asc", "Name A–Z")},
		{"id": &"name_desc", "label": UiCopyType.text(&"ui.identity_sort.name_desc", "Name Z–A")},
	]:
		_sort_select.add_item(String(option["label"]))
		var option_index := _sort_select.item_count - 1
		_sort_select.set_item_metadata(option_index, option["id"])
		if option["id"] == _name_sort:
			_sort_select.select(option_index)
	LunarisOpsType.apply_button(_sort_select, &"secondary")
	_apply_control_padding(
		_sort_select, SORT_HORIZONTAL_PADDING, SORT_VERTICAL_PADDING,
		[&"normal", &"hover", &"pressed", &"disabled"],
	)
	_sort_select.add_theme_font_size_override(&"font_size", 24)
	_sort_select.tooltip_text = UiCopyType.text(&"ui.identity_sort.recruitment", "Recruit order")
	_sort_select.item_selected.connect(_on_name_sort_selected)
	_filter_toolbar.add_child(_sort_select)
	_filter_summary = _label("DeploymentFilterSummary", "", &"dense_detail")
	_filter_summary.custom_minimum_size.x = 100.0
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
		_grid.columns = _operator_grid_columns(_shell.layout_mode())
	for hero: Dictionary in visible_rows:
		var hero_id := StringName(hero["hero_id"])
		var op_id := StringName(hero["operator_def_id"])
		var definition := load("res://data/operators/%s.tres" % op_id) as OperatorDef
		var pick := AetheriaButtonType.new()
		pick.name = "Pick_%s" % hero_id
		pick.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		pick.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var fallen := bool(hero.get("fallen", false))
		pick.toggle_mode = not fallen
		var card_text := _operator_card_text(hero, definition)
		pick.set_meta(&"hero", hero)
		pick.set_meta(&"operator_def", definition)
		pick.text = card_text
		pick.tooltip_text = card_text.replace("\n", " — ")
		pick.custom_minimum_size = Vector2(
			_operator_card_width(_shell.layout_mode()), _operator_card_height(hero, _shell.layout_mode()),
		)
		pick.set_presentation_text(card_text, card_text)
		var portrait := TextureRect.new()
		portrait.name = "OperatorPortrait"
		portrait.texture = Art.texture(StringName(hero["portrait_asset_id"]))
		portrait.anchor_left = _operator_info_split(_shell.layout_mode())
		portrait.anchor_top = 0.0
		portrait.anchor_right = 1.0
		portrait.anchor_bottom = 1.0
		portrait.offset_left = 12.0
		portrait.offset_top = 12.0
		portrait.offset_right = -24.0
		portrait.offset_bottom = -12.0
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pick.add_child(portrait)
		pick.disabled = fallen
		pick.focus_mode = Control.FOCUS_NONE if fallen else Control.FOCUS_ALL
		_apply_operator_card_text_style(pick)
		if not fallen:
			pick.set_pressed_no_signal(_picked.has(hero_id))
			pick.toggled.connect(_on_pick_toggled.bind(hero_id))
		_grid.add_child(pick)
		if not fallen:
			pick.focus_entered.connect(_roster_scroll.ensure_control_visible.bind(pick))
		if not fallen:
			_buttons[hero_id] = pick
			_hero_order.append(hero_id)
		else:
			LunarisOpsType.apply_button(pick, &"disabled")
			_apply_operator_card_text_style(pick)


func _apply_operator_card_text_style(button: AetheriaButtonType) -> void:
	var card_label := button.get_node("PresentationLabel") as Label
	card_label.anchor_left = 0.0
	card_label.anchor_top = 0.0
	card_label.anchor_right = _operator_info_split(_shell.layout_mode())
	card_label.anchor_bottom = 1.0
	card_label.offset_left = 24.0
	card_label.offset_top = 12.0
	card_label.offset_right = -12.0
	card_label.offset_bottom = -12.0
	card_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_label.clip_text = false
	card_label.add_theme_font_size_override(&"font_size", 24)
	card_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _build_footer() -> BoxContainer:
	_footer = BoxContainer.new()
	_footer.name = "MissionActionDock"
	_footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_footer.add_theme_constant_override(&"separation", 16)
	var readiness := VBoxContainer.new()
	readiness.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	readiness.size_flags_stretch_ratio = 1.0
	readiness.add_child(_label(
		"ReadinessEyebrow",
		UiCopyType.text(&"ui.squad.predeployment_heading", "Pre-deployment"),
		&"eyebrow",
	))
	_launch_status = _label(
		"ReadinessCopy",
		UiCopyType.text(
			&"ui.squad.predeployment_body", "Train, review, and confirm the field team.",
		),
		&"detail",
	)
	_launch_status.accessibility_name = UiCopyType.text(
		&"ui.squad.predeployment_heading", "Pre-deployment",
	)
	_launch_status.accessibility_live = AccessibilityServer.LIVE_POLITE
	readiness.add_child(_launch_status)
	_footer.add_child(readiness)
	_actions = GridContainer.new()
	_actions.name = "MissionActions"
	_actions.columns = 3
	_actions.size_flags_horizontal = Control.SIZE_SHRINK_END
	_actions.add_theme_constant_override(&"h_separation", ACTION_HORIZONTAL_GAP)
	_actions.add_theme_constant_override(&"v_separation", ACTION_VERTICAL_GAP)
	_footer.add_child(_actions)
	_back = _action("BackButton", UiCopyType.text(&"ui.common.back", "Back"), &"secondary")
	_back.pressed.connect(_on_back)
	_actions.add_child(_back)
	_training = _action(
		"TrainingButton", UiCopyType.text(&"ui.staging.training", "Training"), &"gold",
	)
	_apply_clean_training_style(_training)
	_training.pressed.connect(_on_training)
	_actions.add_child(_training)
	_start = _action(
		"StartBattle", UiCopyType.text(&"ui.squad.start_battle", "Start Battle"), &"primary",
	)
	_start.pressed.connect(_on_start)
	_actions.add_child(_start)
	return _footer


func _action(node_name: String, text_value: String, role: StringName) -> AetheriaButtonType:
	var button := AetheriaButtonType.new()
	button.name = node_name
	button.text = text_value
	var rendered_text := _action_presentation_text(node_name, text_value)
	button.custom_minimum_size = Vector2(
		_wide_action_width(node_name), DEPLOY_SQUAD_ACTION_HEIGHT,
	)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.set_presentation_text(text_value, rendered_text)
	LunarisOpsType.apply_button(button, role)
	var presentation := button.get_node("PresentationLabel") as Label
	presentation.offset_left = ACTION_SAFE_INSET
	presentation.offset_top = 8.0
	presentation.offset_right = -ACTION_SAFE_INSET
	presentation.offset_bottom = -8.0
	presentation.autowrap_mode = TextServer.AUTOWRAP_OFF
	presentation.clip_text = false
	presentation.add_theme_font_size_override(&"font_size", 26)
	if node_name == "StartBattle":
		_apply_deploy_text_contrast(button)
	return button


func _apply_deploy_text_contrast(button: AetheriaButtonType = _start) -> void:
	if button == null:
		return
	var presentation := button.get_node_or_null("PresentationLabel") as Label
	if presentation == null:
		return
	StagingSkinType.apply_display_type(presentation, 28, DEPLOY_TEXT_COLOR, 650)
	presentation.add_theme_color_override(&"font_color", DEPLOY_TEXT_COLOR)
	presentation.add_theme_color_override(&"font_outline_color", DEPLOY_TEXT_OUTLINE)
	presentation.add_theme_constant_override(&"outline_size", 5)
	presentation.add_theme_constant_override(&"shadow_offset_x", 0)
	presentation.add_theme_constant_override(&"shadow_offset_y", 2)
	presentation.add_theme_color_override(&"font_shadow_color", Color(0.0, 0.0, 0.0, 0.72))


func _action_presentation_text(node_name: String, text_value: String) -> String:
	if I18n.locale() == &"zh-CN":
		return text_value
	if node_name == "TrainingButton":
		return "TRAIN\nOPERATORS"
	if node_name == "StartBattle":
		return "DEPLOY SQUAD"
	return text_value


func _wide_action_width(node_name: String) -> float:
	match node_name:
		"TrainingButton":
			return 336.0
		"StartBattle":
			return DEPLOY_SQUAD_ACTION_WIDTH
		_:
			return 238.0


func _operator_grid_columns(mode: StringName) -> int:
	return 1


func _operator_card_width(mode: StringName) -> float:
	if mode == &"portrait":
		return minf(OPERATOR_CARD_WIDTH, maxf(240.0, get_viewport_rect().size.x - 96.0))
	var available_field_width := get_viewport_rect().size.x * FIELD_TEAM_WIDTH_RATIO - 72.0
	return minf(OPERATOR_CARD_WIDTH, maxf(320.0, available_field_width))


func _operator_info_split(mode: StringName) -> float:
	return 0.54 if mode == &"portrait" else OPERATOR_INFO_SPLIT


func _operator_card_height(hero: Dictionary, mode: StringName) -> float:
	var custom_title := String(hero.get("custom_title", "") if hero.get("custom_title") != null else "")
	return (
		OPERATOR_CARD_TALL_HEIGHT
		if mode == &"portrait" or hero.get("hero_kind", "recruit") == "premium" or not custom_title.is_empty()
		else OPERATOR_CARD_HEIGHT
	)


func _apply_control_padding(
		control: Button,
		horizontal: float,
		vertical: float,
		states: Array[StringName],
	) -> void:
	for state: StringName in states:
		var base := control.get_theme_stylebox(state)
		if base == null:
			continue
		var padded := base.duplicate() as StyleBox
		padded.content_margin_left = horizontal
		padded.content_margin_top = vertical
		padded.content_margin_right = horizontal
		padded.content_margin_bottom = vertical
		control.add_theme_stylebox_override(state, padded)


func _apply_clean_training_style(button: AetheriaButtonType) -> void:
	var normal := StagingSkinType.clean_button_style(
		Color("10202fed"), Color(LunarisOpsType.GOLD, 0.72), 4,
	)
	var hover := StagingSkinType.clean_button_style(
		Color("183448f5"), LunarisOpsType.CYAN, 4,
	)
	var pressed := StagingSkinType.clean_button_style(
		Color("09131df5"), LunarisOpsType.GOLD, 4,
	)
	button.add_theme_stylebox_override(&"normal", normal)
	button.add_theme_stylebox_override(&"hover", hover)
	button.add_theme_stylebox_override(&"pressed", pressed)
	button.add_theme_stylebox_override(
		&"focus", StagingSkinType.transparent_focus_style(LunarisOpsType.CYAN),
	)


func _add_intel_item(
		parent: VBoxContainer,
		node_stem: String,
		heading_key: StringName,
		heading_fallback: String,
		field: StageNarrativeDefType.Field,
	) -> void:
	parent.add_child(_label(
		"%sLabel" % node_stem, UiCopyType.text(heading_key, heading_fallback), &"eyebrow",
	))
	var value := (
		UiCopyType.text(
			&"ui.error.missing_stage_narrative",
			"Mission record unavailable. Return to Mission Control.",
		)
		if _narrative_missing
		else UiCopyType.stage_narrative_text(_narrative, field)
	)
	parent.add_child(_label("%sValue" % node_stem, value, &"detail"))


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
	return (
		UiCopyType.text(&"ui.squad.loadout_none", "Loadout: nothing unlocked yet")
		if gear.is_empty()
		else _format_copy(
			&"ui.squad.loadout_available", "Loadout (always available): {items}",
			{&"items": " • ".join(gear)},
		)
	)


func _on_hire_basic_recruit() -> void:
	if _hire_recruit == null or _hire_recruit.disabled:
		return
	Sfx.play("ui_click")
	_hire_recruit.disabled = true
	var committed: Dictionary = Game.hire_basic_recruit()
	if not committed.get("accepted", false):
		_refresh_recruitment_desk(
			_hire_error_text(StringName(committed.get("error_code", &"unknown"))),
			true,
		)
		if not _hire_recruit.disabled:
			_hire_recruit.grab_focus.call_deferred()
		return
	var projection := Game.campaign_projection()
	var receipt: Dictionary = committed.get("result", {}).get("recruitment", {})
	var recruited: Dictionary = receipt.get("hero", {})
	var callsign := String(recruited.get("hero_id", "Recruit"))
	for hero: Dictionary in projection.get("ready_heroes", []):
		if hero.get("hero_id") == recruited.get("hero_id"):
			callsign = String(hero.get("callsign", callsign))
			break
	_ready_heroes = _identity_rows(projection.get("ready_heroes", []))
	_all_roster_rows = _campaign_roster_rows()
	if _filter_bar != null:
		_filter_bar.set_rows(_all_roster_rows)
	_rebuild_operator_cards()
	_refresh_recruitment_desk(
		UiCopyType.format_text(
			&"ui.campaign.basic_hire_success",
			"{callsign} • JOINED COMPANY 33 • {remaining} MARKS REMAIN",
			{&"callsign": callsign, &"remaining": int(projection.get("marks", 0))},
		),
		false,
	)
	_refresh()
	_hire_recruit.grab_focus.call_deferred()


func _refresh_recruitment_desk(message: String = "", error: bool = false) -> void:
	if _hire_recruit == null:
		return
	var projection := Game.campaign_projection()
	var marks := int(projection.get("marks", 0))
	var cost := int(projection.get("basic_recruit_cost", 5))
	var roster_count := (
		(projection.get("ready_heroes", []) as Array).size()
		+ (projection.get("fallen_heroes", []) as Array).size()
	)
	_hire_marks.text = UiCopyType.format_text(
		&"ui.campaign.basic_hire_marks", "{count} MARKS AVAILABLE", {&"count": marks},
	)
	var action_text := UiCopyType.format_text(
		&"ui.campaign.basic_hire_action", "HIRE • {cost} MARKS", {&"cost": cost},
	)
	_hire_recruit.set_presentation_text(action_text, action_text)
	var presentation := _hire_recruit.get_node("PresentationLabel") as Label
	presentation.offset_left = 12.0
	presentation.offset_top = 12.0
	presentation.offset_right = -12.0
	presentation.offset_bottom = -12.0
	presentation.clip_text = false
	presentation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hire_recruit.tooltip_text = action_text
	_hire_recruit.accessibility_description = action_text
	var unavailable := (
		projection.is_empty()
		or marks < cost
		or bool(projection.get("attempt_pending", false))
		or roster_count >= 1024
	)
	_hire_recruit.disabled = unavailable
	_hire_recruit.apply_role(&"disabled" if unavailable else &"primary")
	if message.is_empty():
		if projection.is_empty():
			message = UiCopyType.text(
				&"ui.campaign.basic_hire_campaign_inactive", "No active campaign is available.",
			)
		elif bool(projection.get("attempt_pending", false)):
			message = UiCopyType.text(
				&"ui.campaign.basic_hire_attempt_pending",
				"Resolve the active operation before hiring personnel.",
			)
		elif roster_count >= 1024:
			message = UiCopyType.text(
				&"ui.campaign.basic_hire_roster_limit",
				"The personnel registry has reached capacity.",
			)
		elif marks < cost:
			message = UiCopyType.text(
				&"ui.campaign.basic_hire_insufficient", "INSUFFICIENT MARKS",
			)
		else:
			message = UiCopyType.text(
				&"ui.campaign.basic_hire_ready", "BASIC RECRUIT CONTRACT AVAILABLE",
			)
	_hire_status.text = message
	_hire_status.accessibility_description = message
	_hire_status.accessibility_live = (
		AccessibilityServer.LIVE_ASSERTIVE if error else AccessibilityServer.LIVE_POLITE
	)
	_hire_status.add_theme_color_override(
		&"font_color", LunarisOpsType.DANGER if error else LunarisOpsType.CYAN,
	)


func _hire_error_text(code: StringName) -> String:
	match code:
		&"insufficient_marks":
			return UiCopyType.text(
				&"ui.campaign.basic_hire_insufficient", "INSUFFICIENT MARKS",
			)
		&"attempt_pending":
			return UiCopyType.text(
				&"ui.campaign.basic_hire_attempt_pending",
				"Resolve the active operation before hiring personnel.",
			)
		&"roster_limit":
			return UiCopyType.text(
				&"ui.campaign.basic_hire_roster_limit",
				"The personnel registry has reached capacity.",
			)
		&"campaign_inactive":
			return UiCopyType.text(
				&"ui.campaign.basic_hire_campaign_inactive", "No active campaign is available.",
			)
		&"strategic_mutation_pending":
			return UiCopyType.text(
				&"ui.campaign.basic_hire_command_pending",
				"Resolve the pending Company command before hiring personnel.",
			)
		&"store_write_failed", &"store_restore_failed", &"store_integrity_failure":
			return UiCopyType.text(
				&"ui.campaign.basic_hire_save_failed",
				"The hire could not be saved. Activate again to retry the exact contract.",
			)
	return UiCopyType.format_text(
		&"ui.campaign.basic_hire_unknown",
		"Hiring failed safely ({code}). Review Mission Control and try again.",
		{&"code": String(code)},
	)


func _on_pick_toggled(pressed: bool, hero_id: StringName) -> void:
	if _launch_locked or Game.mission_launch_retry_pending():
		(_buttons[hero_id] as Button).set_pressed_no_signal(_picked.has(hero_id))
		return
	if pressed:
		if _picked.size() >= _stage.squad_size:
			(_buttons[hero_id] as Button).set_pressed_no_signal(false)
			return
		_picked.append(hero_id)
	else:
		_picked.erase(hero_id)
	_refresh()


func _refresh() -> void:
	_counter.text = _format_copy(
		&"ui.squad.selected_count", "{selected}/{limit} selected",
		{&"selected": _picked.size(), &"limit": _stage.squad_size},
	)
	for raw_id: Variant in _buttons:
		var hero_id := StringName(raw_id)
		var button := _buttons[hero_id] as AetheriaButtonType
		button.disabled = _launch_locked or Game.mission_launch_retry_pending()
		button.focus_mode = Control.FOCUS_NONE if button.disabled else Control.FOCUS_ALL
		LunarisOpsType.apply_button(button, &"selected" if _picked.has(hero_id) else &"secondary")
		_apply_operator_card_text_style(button)
	var selected_names: Array[String] = []
	for hero_id: StringName in _picked:
		var hero := _hero_by_id(hero_id)
		if not hero.is_empty():
			selected_names.append(_hero_callsign(hero))
	_selected_line.text = (
		UiCopyType.text(&"ui.squad.awaiting_selection", "Field Team: Awaiting selection")
		if selected_names.is_empty()
		else "%s: %s" % [
			UiCopyType.text(&"ui.squad.field_team", "Field Team"), " • ".join(selected_names),
		]
	)
	var retry_pending := Game.mission_launch_retry_pending()
	_start.disabled = _launch_locked or (not retry_pending and (_picked.is_empty() or _narrative_missing))
	_start.focus_mode = Control.FOCUS_NONE if _start.disabled else Control.FOCUS_ALL
	LunarisOpsType.apply_button(_start, &"disabled" if _start.disabled else &"primary")
	_training.disabled = _launch_locked or retry_pending
	_training.focus_mode = Control.FOCUS_NONE if _training.disabled else Control.FOCUS_ALL
	LunarisOpsType.apply_button(_training, &"disabled" if _training.disabled else &"gold")
	if not _training.disabled:
		_apply_clean_training_style(_training)
	_refresh_launch_status()
	_apply_deploy_text_contrast()
	_sync_deploy_ready_pulse()
	_wire_focus()


func _deploy_is_fully_ready() -> bool:
	return (
		_start != null
		and not _start.disabled
		and not _launch_locked
		and not Game.mission_launch_retry_pending()
		and _launch_error_code.is_empty()
		and not _narrative_missing
		and _picked.size() == _stage.squad_size
		and not _motion_reduced()
	)


func _sync_deploy_ready_pulse() -> void:
	if not _deploy_is_fully_ready():
		_stop_deploy_ready_pulse()
		return
	if _deploy_ready_pulsing or _start == null:
		return
	_deploy_ready_pulsing = true
	_start.set_meta(&"ready_pulse_active", true)
	_update_deploy_pivot()
	_deploy_pulse_tween = create_tween().set_loops()
	_deploy_pulse_tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	_deploy_pulse_tween.tween_property(
		_start, "scale", DEPLOY_READY_PULSE_SCALE, DEPLOY_READY_PULSE_RISE_SECONDS,
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_deploy_pulse_tween.parallel().tween_property(
		_start, "self_modulate", Color("fff6d8"), DEPLOY_READY_PULSE_RISE_SECONDS,
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_deploy_pulse_tween.tween_property(
		_start, "scale", Vector2.ONE, DEPLOY_READY_PULSE_FALL_SECONDS,
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_deploy_pulse_tween.parallel().tween_property(
		_start, "self_modulate", Color.WHITE, DEPLOY_READY_PULSE_FALL_SECONDS,
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _stop_deploy_ready_pulse() -> void:
	if _deploy_pulse_tween != null and _deploy_pulse_tween.is_valid():
		_deploy_pulse_tween.kill()
	_deploy_pulse_tween = null
	_deploy_ready_pulsing = false
	if _start != null:
		_start.set_meta(&"ready_pulse_active", false)
		_start.scale = Vector2.ONE
		_start.self_modulate = Color.WHITE
		_update_deploy_pivot()


func _update_deploy_pivot() -> void:
	if _start != null:
		_start.pivot_offset = _start.size * 0.5


func deploy_ready_pulse_active() -> bool:
	return _deploy_ready_pulsing


func _motion_reduced() -> bool:
	return bool(ProjectSettings.get_setting("accessibility/reduced_motion", false))


func _refresh_launch_status() -> void:
	if _launch_status == null or _start == null:
		return
	var status_text := UiCopyType.text(
		&"ui.squad.predeployment_body", "Train, review, and confirm the field team.",
	)
	var action_text := UiCopyType.text(&"ui.squad.start_battle", "Start Battle")
	var is_error := false
	if _launch_locked:
		status_text = UiCopyType.text(
			&"ui.squad.launch_committing", "Authenticating deployment record…",
		)
		action_text = UiCopyType.text(&"ui.squad.launch_committing_action", "Deploying…")
	elif Game.mission_launch_retry_pending():
		status_text = UiCopyType.text(
			&"ui.squad.launch_retryable_error",
			"Deployment was not saved. Retry the exact field-team order.",
		)
		action_text = UiCopyType.text(&"ui.squad.launch_retry_action", "Retry Deployment")
		is_error = true
	elif not _launch_error_code.is_empty():
		status_text = _launch_error_text(_launch_error_code)
		is_error = true
	_launch_status.text = status_text
	_launch_status.accessibility_description = status_text
	_launch_status.accessibility_live = (
		AccessibilityServer.LIVE_ASSERTIVE if is_error else AccessibilityServer.LIVE_POLITE
	)
	_launch_status.add_theme_color_override(
		&"font_color", LunarisOpsType.DANGER if is_error else LunarisOpsType.MUTED,
	)
	_start.text = action_text
	_start.set_presentation_text(action_text, _start_action_presentation(action_text))
	_start.tooltip_text = action_text
	_start.accessibility_name = action_text


func _start_action_presentation(action_text: String) -> String:
	if I18n.locale() == &"zh-CN" or _launch_locked:
		return action_text
	if Game.mission_launch_retry_pending():
		return "RETRY\nDEPLOYMENT"
	return _action_presentation_text("StartBattle", action_text)


func _launch_error_text(code: StringName) -> String:
	match code:
		&"attempt_pending", &"strategic_mutation_pending":
			return UiCopyType.text(
				&"ui.squad.launch_pending_error",
				"Another Company command is still pending. Return to Mission Control and resume it.",
			)
		&"unknown_hero", &"dead_hero", &"premium_hero_out_of_lives", &"missing_catalog", &"squad_too_large":
			return UiCopyType.text(
				&"ui.squad.launch_roster_error",
				"The field team changed before deployment. Review the selected operators and try again.",
			)
		&"stage_locked", &"unknown_campaign_stage":
			return UiCopyType.text(
				&"ui.squad.launch_stage_error",
				"This operation is not currently authorized. Return to Mission Control.",
			)
		&"campaign_inactive":
			return UiCopyType.text(
				&"ui.squad.launch_campaign_error",
				"The active campaign record is unavailable. Return to the Title screen and resume the campaign.",
			)
		&"store_write_failed", &"store_restore_failed":
			return UiCopyType.text(
				&"ui.squad.launch_retryable_error",
				"Deployment was not saved. Retry the exact field-team order.",
			)
		&"store_integrity_failure", &"invalid_campaign_state":
			return UiCopyType.text(
				&"ui.squad.launch_integrity_error",
				"Campaign records could not be authenticated. Return to Mission Control before retrying.",
			)
	return UiCopyType.text(
		&"ui.squad.launch_unknown_error",
		"Deployment was rejected safely. Review Mission Control and try again.",
	)


func _operator_card_text(hero: Dictionary, definition: OperatorDef) -> String:
	var args := {
		&"name": _hero_label(hero),
		&"cost": definition.dp_cost,
		&"lives": int(hero.get("premium_lives", 0)),
	}
	if bool(hero.get("fallen", false)):
		return _format_copy(
			&"ui.squad.card_fallen", "{name}\nFallen · Vahalla", args,
		)
	if hero.get("hero_kind", "recruit") == "premium":
		return _format_copy(
			&"ui.squad.card_premium", "{name}\n{cost} DP · Premium hero · {lives} lives", args,
		)
	return _format_copy(
		&"ui.squad.card_ready", "{name}\n{cost} DP · Ready", args,
	)


func _on_locale_changed(_locale_id: StringName) -> void:
	if _hire_title != null:
		_hire_title.text = UiCopyType.text(
			&"ui.campaign.basic_hire_title", "Company Reinforcements",
		).to_upper()
	if _hire_recruit != null:
		_hire_recruit.accessibility_name = UiCopyType.text(
			&"ui.campaign.basic_hire_title", "Company Reinforcements",
		)
	if _hire_status != null:
		_hire_status.accessibility_name = UiCopyType.text(
			&"ui.campaign.basic_hire_title", "Company Reinforcements",
		)
	var copy_by_node := {
		"MissionIndex": _format_copy(
			&"ui.squad.mission_identity", "Mission {index} / {title}",
			{&"index": "%02d" % _stage.campaign_index, &"title": UiCopyType.stage_title(_stage)},
		),
		"MissionTitle": UiCopyType.stage_title(_stage),
		"ThreatLabel": UiCopyType.text(&"ui.squad.briefing.threat", "Threat"),
		"SquadLimit": _format_copy(&"ui.squad.limit", "Squad limit {limit}", {&"limit": _stage.squad_size}),
		"FieldTeamHeading": UiCopyType.text(&"ui.squad.field_team", "Field Team"),
		"MissionIntelHeading": UiCopyType.text(&"ui.squad.mission_intelligence", "Mission Intelligence"),
		"OBJECTIVELabel": UiCopyType.text(&"ui.squad.briefing.objective", "Objective"),
		"THREATLabel": UiCopyType.text(&"ui.squad.briefing.threat", "Threat"),
		"WHYITMATTERSLabel": UiCopyType.text(&"ui.squad.briefing.human_reason", "Why it matters"),
		"TacticalHeading": UiCopyType.text(&"ui.squad.tactical_asset_heading", "Tactical Asset"),
		"TacticalHint": UiCopyType.stage_hint(_stage),
		"LoadoutHeading": UiCopyType.text(&"ui.squad.loadout_heading", "Loadout"),
		"LoadoutStrip": _loadout_text(),
		"ReadinessEyebrow": UiCopyType.text(&"ui.squad.predeployment_heading", "Pre-deployment"),
		"ReadinessCopy": UiCopyType.text(&"ui.squad.predeployment_body", "Train, review, and confirm the field team."),
	}
	for node_name: String in copy_by_node:
		var label := find_child(node_name, true, false) as Label
		if label != null:
			label.text = copy_by_node[node_name]
	if _filter_input != null:
		_filter_input.placeholder_text = UiCopyType.text(&"ui.identity_filter.placeholder", "Filter operators")
	if _sort_select != null:
		var sort_keys := [&"ui.identity_sort.recruitment", &"ui.identity_sort.name_asc", &"ui.identity_sort.name_desc"]
		var sort_fallbacks := ["Recruit order", "Name ascending", "Name descending"]
		for index: int in mini(_sort_select.item_count, sort_keys.size()):
			_sort_select.set_item_text(index, UiCopyType.text(sort_keys[index], sort_fallbacks[index]))
	for button: AetheriaButtonType in _buttons.values():
		var hero: Dictionary = button.get_meta(&"hero", {})
		var definition := button.get_meta(&"operator_def") as OperatorDef
		if definition == null:
			continue
		var card_text := _operator_card_text(hero, definition)
		button.text = card_text
		button.set_presentation_text(card_text, card_text)
		button.tooltip_text = card_text.replace("\n", " — ")
	_back.text = UiCopyType.text(&"ui.common.back", "Back")
	_back.set_presentation_text(_back.text, _action_presentation_text(_back.name, _back.text))
	_training.text = UiCopyType.text(&"ui.staging.training", "Training")
	_training.set_presentation_text(
		_training.text, _action_presentation_text(_training.name, _training.text),
	)
	_start.text = UiCopyType.text(&"ui.squad.start_battle", "Start Battle")
	_start.set_presentation_text(_start.text, _action_presentation_text(_start.name, _start.text))
	_refresh_recruitment_desk()
	_refresh()


func _format_copy(key: StringName, fallback: String, args: Dictionary) -> String:
	var value := UiCopyType.text(key, fallback)
	for name: StringName in args:
		value = value.replace("{%s}" % name, str(args[name]))
	return value


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
	if _hire_recruit != null and not _hire_recruit.disabled:
		focusable.append(_hire_recruit)
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
	if _header != null:
		_header.vertical = mode == &"portrait"
	if _header_identity != null:
		_header_identity.vertical = mode == &"portrait"
	if _header_status != null:
		_header_status.custom_minimum_size.x = 0.0 if mode == &"portrait" else 280.0
		for child: Node in _header_status.get_children():
			if child is Label:
				(child as Label).horizontal_alignment = (
					HORIZONTAL_ALIGNMENT_LEFT
					if mode == &"portrait"
					else HORIZONTAL_ALIGNMENT_RIGHT
				)
	if _roster_heading != null:
		_roster_heading.vertical = mode != &"regular_landscape"
	if _counter != null:
		_counter.custom_minimum_size.x = 0.0 if mode != &"regular_landscape" else 178.0
		_counter.horizontal_alignment = (
			HORIZONTAL_ALIGNMENT_LEFT
			if mode != &"regular_landscape"
			else HORIZONTAL_ALIGNMENT_RIGHT
		)
	if _filter_toolbar != null:
		_filter_toolbar.vertical = mode == &"portrait"
	if _filter_summary != null:
		_filter_summary.visible = mode == &"portrait"
		_filter_summary.horizontal_alignment = (
			HORIZONTAL_ALIGNMENT_LEFT
			if mode == &"portrait"
			else HORIZONTAL_ALIGNMENT_RIGHT
		)
	if _body != null:
		_body.columns = 1 if mode == &"portrait" else 2
		_body.custom_minimum_size.y = 0.0
	if _roster_panel != null and _intel_panel != null:
		if mode == &"portrait":
			_roster_panel.custom_minimum_size.x = 0.0
			_intel_panel.custom_minimum_size.x = 0.0
		else:
			var body_width := maxf(760.0, get_viewport_rect().size.x - 112.0)
			var usable_width := body_width - 16.0
			var intel_width := usable_width * INTEL_WIDTH_RATIO
			_intel_panel.custom_minimum_size.x = intel_width
			_roster_panel.custom_minimum_size.x = usable_width * FIELD_TEAM_WIDTH_RATIO
	if _command_scroll != null:
		_command_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	if _roster_scroll != null:
		_roster_scroll.custom_minimum_size.y = 220.0 if mode == &"portrait" else 0.0
	if _intel_scroll != null:
		_intel_scroll.custom_minimum_size.y = 170.0 if mode == &"portrait" else 0.0
	if _grid != null:
		_grid.columns = _operator_grid_columns(mode)
	if _filter_bar != null:
		_filter_bar.set_compact(true)
		_filter_bar.set_roomy(false)
		_filter_bar.set_dense_inline(mode == &"regular_landscape" and get_viewport_rect().size.x < 1500.0)
		_filter_bar.set_inline(mode == &"regular_landscape" and get_viewport_rect().size.x >= 1500.0)
	if _recruitment_grid != null:
		_recruitment_grid.columns = 1
	if _hire_recruit != null:
		_hire_recruit.custom_minimum_size = Vector2(
			220.0 if mode == &"regular_landscape" else 0.0,
			72.0,
		)
	for button: Button in _buttons.values():
		var hero: Dictionary = button.get_meta(&"hero", {})
		button.custom_minimum_size = Vector2(
			_operator_card_width(mode),
			_operator_card_height(hero, mode),
		)
		var portrait := button.get_node_or_null("OperatorPortrait") as TextureRect
		if portrait != null:
			portrait.anchor_left = _operator_info_split(mode)
		_apply_operator_card_text_style(button as AetheriaButtonType)
	if _footer != null:
		_footer.vertical = (
			mode != &"regular_landscape"
			or get_viewport_rect().size.x < FOOTER_STACK_THRESHOLD
		)
	var readiness_copy := find_child("ReadinessCopy", true, false) as Label
	if readiness_copy != null:
		readiness_copy.add_theme_font_size_override(
			&"font_size",
			18 if mode == &"regular_landscape" and get_viewport_rect().size.x < 1500.0 else 24,
		)
	if _actions != null:
		_actions.columns = (
			1
			if mode == &"portrait" or get_viewport_rect().size.x <= COMPACT_ACTION_STACK_THRESHOLD
			else 3
		)
		_actions.size_flags_horizontal = (
			Control.SIZE_EXPAND_FILL if mode != &"regular_landscape" else Control.SIZE_SHRINK_END
		)
		for action: Node in _actions.get_children():
			if action is Button:
				var target_width := _wide_action_width(action.name)
				if mode == &"portrait":
					target_width = minf(target_width, maxf(220.0, get_viewport_rect().size.x - 96.0))
				(action as Button).custom_minimum_size.x = target_width
	_update_deploy_pivot.call_deferred()


func _on_training() -> void:
	if _launch_locked or Game.mission_launch_retry_pending():
		return
	Sfx.play("ui_click")
	Game.training_call(&"open", &"mission")


func _on_back() -> void:
	Game.cancel_mission_launch_retry()
	Sfx.play("ui_back")
	Game.open_stage_select()


func _on_start() -> void:
	if _launch_locked or _start == null or _start.disabled:
		return
	Sfx.play("ui_confirm")
	_launch_locked = true
	_launch_error_code = &""
	_refresh()
	var committed: Dictionary = Game.start_stage(_stage.id, _picked)
	if committed.get("accepted", false):
		return
	_launch_locked = false
	_launch_error_code = StringName(committed.get("error_code", &"unknown"))
	_refresh()
	if not _start.disabled:
		_start.grab_focus.call_deferred()


func _label(label_name: String, label_text: String, role: StringName) -> AetheriaLabelType:
	var label := AetheriaLabelType.new()
	label.name = label_name
	label.text = label_text
	var wraps := role in [&"title", &"heading", &"body", &"detail", &"metric", &"dense_detail"]
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wraps else TextServer.AUTOWRAP_OFF
	label.clip_text = not wraps
	label.text_overrun_behavior = (
		TextServer.OVERRUN_NO_TRIMMING
		if wraps
		else TextServer.OVERRUN_TRIM_ELLIPSIS
	)
	label.custom_minimum_size.x = 0.0
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	LunarisOpsType.apply_label(label, role)
	return label
