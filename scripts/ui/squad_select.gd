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
const SelectedSquadChipType := preload("res://scripts/ui/components/selected_squad_chip.gd")
const PremiumPortraitEntranceType := preload("res://scripts/ui/components/premium_portrait_entrance.gd")
const UiCopyType := preload("res://scripts/ui/components/ui_copy.gd")
const ResonanceCurrencyDisplayType := preload("res://scripts/ui/components/resonance_currency_display.gd")
const StagingSkinType := preload("res://scripts/ui/components/staging_skin.gd")
const ActionHoverFeedbackType := preload("res://scripts/ui/components/action_hover_feedback.gd")
const RosterGridLayoutType := preload("res://scripts/ui/components/roster_grid_layout.gd")
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
const OPERATOR_CARD_WIDTH := 520.0
const OPERATOR_CARD_MIN_WIDTH := 300.0
const OPERATOR_CARD_NARROW_MIN_WIDTH := 240.0
const OPERATOR_GRID_GAP := 12.0
const OPERATOR_RAIL_EDGE_INSET := 8
const OPERATOR_SNAP_IDLE_SECONDS := 0.14
const OPERATOR_SNAP_SECONDS := 0.18
const OPERATOR_CARD_HEIGHT := 252.0
const OPERATOR_CARD_TALL_HEIGHT := 330.0
const LOADOUT_TOP_PADDING := 24
const SORT_HORIZONTAL_PADDING := 24.0
const SORT_VERTICAL_PADDING := 12.0
const FIELD_TEAM_STATUS_WIDTH_SCALE := 2.0
const HIRE_RECRUIT_WIDTH := 300.0
const HIRE_RECRUIT_NARROW_MIN_WIDTH := 220.0
const ACTION_HORIZONTAL_GAP := 28
const ACTION_VERTICAL_GAP := 24
const DEPLOY_SQUAD_ACTION_WIDTH := 588.0
const DEPLOY_SQUAD_ACTION_HEIGHT := 112.0
const COMPACT_ACTION_STACK_THRESHOLD := 1280.0
const DEPLOY_READY_PULSE_SCALE := Vector2(1.018, 1.018)
const DEPLOY_READY_PULSE_RISE_SECONDS := 0.82
const DEPLOY_READY_PULSE_FALL_SECONDS := 1.08
const DEPLOY_TEXT_COLOR := Color("fff8e7")
const DEPLOY_TEXT_OUTLINE := Color("09070d")
const REGULAR_BACK_ACTION_WIDTH := 180.0
const REGULAR_TRAINING_ACTION_WIDTH := 220.0
const REGULAR_DEPLOY_ACTION_WIDTH := 400.0
const OPERATOR_HOVER_SCALE := Vector2(1.018, 1.018)
const OPERATOR_SELECTED_SCALE := Vector2(1.010, 1.010)
const OPERATOR_SELECTION_PEAK_SCALE := Vector2(1.035, 1.035)
const OPERATOR_HOVER_SECONDS := 0.14
const OPERATOR_SELECTION_OUT_SECONDS := 0.10
const OPERATOR_SELECTION_SETTLE_SECONDS := 0.17
const OPERATOR_GLOW_ALPHA := 0.62
const OPERATOR_GLOW_EXPAND := 4.0
const OPERATOR_GLOW_SHADOW_SIZE := 8
const HIRE_RECRUIT_HOVER_SCALE := Vector2(1.022, 1.022)
const HIRE_RECRUIT_FOCUS_SCALE := Vector2(1.012, 1.012)
const HIRE_RECRUIT_HOVER_TINT := Color("fff8df")
const HIRE_RECRUIT_FOCUS_TINT := Color("e9fcff")
const HIRE_RECRUIT_HOVER_SFX := "hire_recruit_hover"
const HIRE_RECRUIT_HOVER_ARMED_META := &"hire_recruit_hover_armed"

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
var _selected_squad_panel: PanelContainer = null
var _selected_squad_scroll: ScrollContainer = null
var _selected_squad_order: HBoxContainer = null
var _selected_squad_empty: AetheriaLabelType = null
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
var _operator_rail_inset: MarginContainer = null
var _operator_snap_timer: Timer = null
var _operator_snap_tween: Tween = null
var _operator_snap_in_progress := false
var _operator_scroll_dragging := false
var _operator_grid_reflow_queued := false
var _operator_grid_reflow_running := false
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
var _hire_recruit: AetheriaButtonType = null
var _hire_tooltip_hotspot: Control = null
var _hire_action_label: Label = null
var _hire_cost_label: Label = null
var _deploy_pulse_tween: Tween = null
var _deploy_ready_pulsing := false
var _operator_feedback_tweens: Dictionary = {}


func _ready() -> void:
	Game.content = self
	_stage = load("res://data/stages/%s.tres" % Game.selected_stage_id) as StageDef
	_narrative = (NARRATIVE_CATALOG as StageNarrativeCatalogType).get_record(Game.selected_stage_id)
	_narrative_missing = _narrative == null
	_ready_heroes = _identity_rows(Game.campaign_projection()["ready_heroes"])
	var content_packs := get_node_or_null("/root/ContentPacks")
	if content_packs != null:
		content_packs.call("prefetch_roster", _ready_heroes, Game.selected_squad)
	LunarisOpsType.add_backdrop(self, BACKDROP)
	_shell = SHELL_SCENE.instantiate() as AetheriaScreenShellType
	_shell.name = "MissionCommandShell"
	_shell.full_safe_area = true
	add_child(_shell)
	_shell.layout_mode_changed.connect(_on_layout_mode_changed)
	get_viewport().size_changed.connect(_on_viewport_resized)
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
	roster_style.content_margin_left = 24.0
	roster_style.content_margin_top = 24.0
	roster_style.content_margin_right = 24.0
	roster_style.content_margin_bottom = 24.0
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
	_filter_bar.set_show_all_status_tab(true)
	_filter_bar.set_show_faction_filters(false)
	_filter_bar.set_status_button_width_scale(FIELD_TEAM_STATUS_WIDTH_SCALE)
	_filter_bar.filters_changed.connect(_on_filters_changed)
	roster_column.add_child(_filter_bar)
	roster_column.add_child(_build_identity_filter_toolbar())
	roster_column.add_child(_build_selected_squad_order())
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
	_roster_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_roster_scroll.resized.connect(_queue_operator_grid_reflow)
	_roster_scroll.gui_input.connect(_on_operator_rail_input)
	var horizontal_bar := _roster_scroll.get_h_scroll_bar()
	horizontal_bar.value_changed.connect(_on_operator_scroll_value_changed)
	horizontal_bar.gui_input.connect(_on_operator_scrollbar_input)
	roster_column.add_child(_roster_scroll)
	_operator_snap_timer = Timer.new()
	_operator_snap_timer.name = "OperatorSnapTimer"
	_operator_snap_timer.one_shot = true
	_operator_snap_timer.wait_time = OPERATOR_SNAP_IDLE_SECONDS
	_operator_snap_timer.timeout.connect(_snap_operator_rail)
	roster_column.add_child(_operator_snap_timer)
	_operator_rail_inset = MarginContainer.new()
	_operator_rail_inset.name = "OperatorRailInset"
	_operator_rail_inset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_operator_rail_inset.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_roster_scroll.add_child(_operator_rail_inset)
	_grid = GridContainer.new()
	_grid.name = "OperatorGrid"
	_grid.columns = 1
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_grid.add_theme_constant_override(&"h_separation", OPERATOR_GRID_GAP)
	_grid.add_theme_constant_override(&"v_separation", 10)
	_operator_rail_inset.add_child(_grid)
	_rebuild_operator_cards()
	_queue_operator_grid_reflow()
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


func _build_selected_squad_order() -> PanelContainer:
	_selected_squad_panel = PanelContainer.new()
	_selected_squad_panel.name = "SelectedSquadOrderPanel"
	_selected_squad_panel.custom_minimum_size.y = 82.0
	_selected_squad_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	LunarisOpsType.apply_panel(_selected_squad_panel, &"selected")
	var stack := VBoxContainer.new()
	stack.name = "SelectedSquadOrderStack"
	stack.add_theme_constant_override(&"separation", 6)
	_selected_squad_panel.add_child(stack)
	var heading := _label(
		"SelectedSquadOrderHeading",
		UiCopyType.text(&"ui.squad.order_heading", "Deployment Order"),
		&"eyebrow",
	)
	heading.add_theme_font_size_override(&"font_size", 20)
	stack.add_child(heading)
	_selected_squad_scroll = ScrollContainer.new()
	_selected_squad_scroll.name = "SelectedSquadOrderScroll"
	_selected_squad_scroll.custom_minimum_size.y = 62.0
	_selected_squad_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_selected_squad_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_selected_squad_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	stack.add_child(_selected_squad_scroll)
	_selected_squad_order = HBoxContainer.new()
	_selected_squad_order.name = "SelectedSquadOrder"
	_selected_squad_order.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_selected_squad_order.add_theme_constant_override(&"h_separation", 10)
	_selected_squad_scroll.add_child(_selected_squad_order)
	_selected_squad_empty = _selected_squad_empty_label()
	_selected_squad_order.add_child(_selected_squad_empty)
	return _selected_squad_panel


func _selected_squad_empty_label() -> Label:
	var empty := _label(
		"SelectedSquadOrderEmpty",
		UiCopyType.text(
			&"ui.squad.order_empty",
			"Choose operators for the field team, then drag to set deployment order.",
		),
		&"dense_detail",
	)
	empty.custom_minimum_size = Vector2(560.0, 44.0)
	empty.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	empty.autowrap_mode = TextServer.AUTOWRAP_OFF
	empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return empty


func _build_recruitment_desk(parent: VBoxContainer) -> void:
	_hire_recruit = AetheriaButtonType.new()
	_hire_recruit.name = "HireBasicRecruit"
	_hire_recruit.custom_minimum_size = Vector2(HIRE_RECRUIT_WIDTH, 72.0)
	_hire_recruit.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_hire_recruit.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_hire_recruit.apply_role(&"primary")
	_apply_clean_training_style(_hire_recruit)
	ActionHoverFeedbackType.wire(
		self,
		_hire_recruit,
		HIRE_RECRUIT_HOVER_SCALE,
		HIRE_RECRUIT_FOCUS_SCALE,
		HIRE_RECRUIT_HOVER_TINT,
		HIRE_RECRUIT_FOCUS_TINT,
	)
	_hire_recruit.set_meta(HIRE_RECRUIT_HOVER_ARMED_META, true)
	_hire_recruit.mouse_entered.connect(_on_hire_recruit_hovered)
	_hire_recruit.mouse_exited.connect(_on_hire_recruit_hover_exited)
	_hire_recruit.pressed.connect(_on_hire_basic_recruit)
	_hire_recruit.accessibility_live = AccessibilityServer.LIVE_POLITE
	parent.add_child(_hire_recruit)
	var hire_content := HBoxContainer.new()
	hire_content.name = "BasicRecruitActionContent"
	hire_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hire_content.alignment = BoxContainer.ALIGNMENT_CENTER
	hire_content.add_theme_constant_override(&"separation", 4)
	hire_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hire_recruit.add_child(hire_content)
	_hire_action_label = Label.new()
	_hire_action_label.name = "BasicRecruitActionLabel"
	_hire_action_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hire_action_label.add_theme_font_size_override(&"font_size", 33)
	_hire_action_label.add_theme_color_override(&"font_color", LunarisOpsType.IVORY)
	_hire_action_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hire_content.add_child(_hire_action_label)
	var cost_icon := TextureRect.new()
	cost_icon.name = "BasicRecruitCostIcon"
	cost_icon.texture = ResonanceCurrencyDisplayType.ICON_TEXTURE
	cost_icon.custom_minimum_size = Vector2(20.0, 20.0)
	cost_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cost_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cost_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	cost_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hire_content.add_child(cost_icon)
	_hire_cost_label = Label.new()
	_hire_cost_label.name = "BasicRecruitCostLabel"
	_hire_cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hire_cost_label.add_theme_font_size_override(&"font_size", 24)
	_hire_cost_label.add_theme_color_override(&"font_color", LunarisOpsType.GOLD)
	_hire_cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hire_content.add_child(_hire_cost_label)
	_hire_tooltip_hotspot = Control.new()
	_hire_tooltip_hotspot.name = "HireRecruitTooltipHotspot"
	_hire_tooltip_hotspot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hire_tooltip_hotspot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hire_tooltip_hotspot.mouse_force_pass_scroll_events = false
	_hire_recruit.add_child(_hire_tooltip_hotspot)


func _campaign_roster_rows() -> Array[Dictionary]:
	var projection: Dictionary = Game.campaign_projection()
	var rows: Array = []
	rows.append_array(projection.get("ready_heroes", []))
	rows.append_array(projection.get("fallen_heroes", []))
	var premium_rarities := {}
	for raw: Variant in projection.get("premium_pool", []):
		var premium := raw as Dictionary
		premium_rarities[String(premium.get("premium_id", ""))] = int(
			premium.get("rarity", 0)
		)
	var annotated := _identity_rows(rows)
	for hero: Dictionary in annotated:
		var class_definition := TrainingSupportType.class_definition(
			String(hero.get("current_class_id", "")),
		)
		var operator_definition := TrainingSupportType.operator_definition(
			String(hero.get("operator_def_id", "")),
		)
		hero["level"] = int(class_definition.stage) + 1 if class_definition != null else 1
		hero["rarity"] = int(operator_definition.rarity) if operator_definition != null else 1
		hero["dp_cost"] = int(operator_definition.dp_cost) if operator_definition != null else 0
		if String(hero.get("hero_kind", "recruit")) == "premium":
			hero["rarity"] = int(premium_rarities.get(
				String(hero.get("premium_id", "")), hero["rarity"],
			))
	return RosterFilterType.annotate_all(annotated)


func _identity_rows(raw_rows: Array) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for raw: Variant in raw_rows:
		var hero := (raw as Dictionary).duplicate(true)
		hero["callsign"] = _hero_callsign(hero)
		hero["identity_portrait_asset_id"] = hero.get(
			"identity_portrait_asset_id",
			hero.get("portrait_asset_id", hero.get("identity_portrait_id", "")),
		)
		hero["portrait_asset_id"] = TrainingSupportType.presentation_portrait_asset_id(hero)
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
	for option: Dictionary in _identity_sort_options():
		_sort_select.add_item(UiCopyType.text(option["key"], option["fallback"]))
		var option_index := _sort_select.item_count - 1
		_sort_select.set_item_metadata(option_index, option["id"])
		if option["id"] == _name_sort:
			_sort_select.select(option_index)
	_apply_clean_sort_style(_sort_select)
	_apply_control_padding(
		_sort_select, SORT_HORIZONTAL_PADDING, SORT_VERTICAL_PADDING,
		[&"normal", &"hover", &"pressed", &"disabled"],
	)
	_sort_select.accessibility_name = UiCopyType.text(&"ui.identity_sort.label", "Sort operators")
	_sort_select.accessibility_description = _sort_select.get_item_text(_sort_select.selected)
	_sort_select.tooltip_text = "%s — %s" % [
		_sort_select.accessibility_name, _sort_select.accessibility_description,
	]
	_sort_select.item_selected.connect(_on_name_sort_selected)
	_filter_toolbar.add_child(_sort_select)
	_filter_summary = _label("DeploymentFilterSummary", "", &"dense_detail")
	_filter_summary.custom_minimum_size.x = 100.0
	_filter_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_filter_toolbar.add_child(_filter_summary)
	return _filter_toolbar


func _identity_sort_options() -> Array[Dictionary]:
	return [
		{"id": &"recruitment", "key": &"ui.identity_sort.recruitment", "fallback": "Recruit order"},
		{"id": &"cost_asc", "key": &"ui.identity_sort.cost_asc", "fallback": "Cost low–high"},
		{"id": &"cost_desc", "key": &"ui.identity_sort.cost_desc", "fallback": "Cost high–low"},
		{"id": &"rarity_desc", "key": &"ui.identity_sort.rarity_desc", "fallback": "Rarity high–low"},
		{"id": &"rarity_asc", "key": &"ui.identity_sort.rarity_asc", "fallback": "Rarity low–high"},
		{"id": &"level_desc", "key": &"ui.identity_sort.level_desc", "fallback": "Level high–low"},
		{"id": &"level_asc", "key": &"ui.identity_sort.level_asc", "fallback": "Level low–high"},
		{"id": &"name_asc", "key": &"ui.identity_sort.name_asc", "fallback": "Name A–Z"},
		{"id": &"name_desc", "key": &"ui.identity_sort.name_desc", "fallback": "Name Z–A"},
	]


func _apply_clean_sort_style(button: OptionButton) -> void:
	var normal := StagingSkinType.clean_button_style(
		Color("10202fed"), Color(LunarisOpsType.GOLD, 0.72), 3,
	)
	var hover := StagingSkinType.clean_button_style(
		Color("183448f5"), LunarisOpsType.CYAN, 3,
	)
	var pressed := StagingSkinType.clean_button_style(
		Color("09131df5"), LunarisOpsType.GOLD, 3,
	)
	button.add_theme_stylebox_override(&"normal", normal)
	button.add_theme_stylebox_override(&"hover", hover)
	button.add_theme_stylebox_override(&"pressed", pressed)
	button.add_theme_stylebox_override(
		&"focus", StagingSkinType.transparent_focus_style(LunarisOpsType.CYAN),
	)
	StagingSkinType.apply_display_type(button, 24, LunarisOpsType.IVORY, 560)
	button.add_theme_color_override(&"font_hover_color", Color.WHITE)
	button.add_theme_color_override(&"font_pressed_color", LunarisOpsType.GOLD)


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
	_sort_select.accessibility_description = _sort_select.get_item_text(index)
	_sort_select.tooltip_text = "%s — %s" % [
		_sort_select.accessibility_name, _sort_select.accessibility_description,
	]
	_rebuild_operator_cards()
	_refresh()
	if _sort_select != null:
		_sort_select.grab_focus.call_deferred()


func _build_operator_cards() -> void:
	_rebuild_operator_cards()


func _rebuild_operator_cards() -> void:
	if _grid == null:
		return
	for tween: Tween in _operator_feedback_tweens.values():
		if tween != null and tween.is_valid():
			tween.kill()
	_operator_feedback_tweens.clear()
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
		_queue_operator_grid_reflow()
		return
	_grid.columns = 1
	for visible_index: int in visible_rows.size():
		var hero := visible_rows[visible_index] as Dictionary
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
		pick.set_meta(&"operator_feedback_enabled", true)
		pick.set_meta(&"operator_hover_seconds", OPERATOR_HOVER_SECONDS)
		pick.set_meta(&"operator_selection_seconds", OPERATOR_SELECTION_SETTLE_SECONDS)
		pick.text = card_text
		pick.tooltip_text = card_text.replace("\n", " — ")
		pick.custom_minimum_size = Vector2(
			_operator_card_width(_shell.layout_mode()), _operator_card_height(hero, _shell.layout_mode()),
		)
		pick.set_presentation_text(card_text, card_text)
		var hover_glow := _build_operator_hover_glow()
		pick.add_child(hover_glow)
		pick.set_meta(&"operator_hover_glow_enabled", true)
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
		PremiumPortraitEntranceType.apply(
			portrait,
			StringName(hero["portrait_asset_id"]),
			visible_index,
			_reduced_motion(),
		)
		pick.disabled = fallen
		pick.focus_mode = Control.FOCUS_NONE if fallen else Control.FOCUS_ALL
		_apply_operator_card_text_style(pick)
		pick.mouse_entered.connect(_on_operator_feedback_changed.bind(pick))
		pick.mouse_exited.connect(_on_operator_feedback_changed.bind(pick))
		pick.resized.connect(_center_operator_card_pivot.bind(pick))
		if not fallen:
			pick.set_pressed_no_signal(_picked.has(hero_id))
			pick.toggled.connect(_on_pick_toggled.bind(hero_id))
			pick.mouse_entered.connect(_prefetch_hero_pack.bind(hero_id, true, true))
			pick.focus_entered.connect(_prefetch_hero_pack.bind(hero_id, true, true))
			pick.focus_entered.connect(_on_operator_feedback_changed.bind(pick))
			pick.focus_exited.connect(_on_operator_feedback_changed.bind(pick))
		_grid.add_child(pick)
		_center_operator_card_pivot(pick)
		if not fallen:
			pick.focus_entered.connect(_roster_scroll.ensure_control_visible.bind(pick))
		if not fallen:
			_buttons[hero_id] = pick
			_hero_order.append(hero_id)
		else:
			LunarisOpsType.apply_button(pick, &"disabled")
			_apply_operator_card_text_style(pick)
	_queue_operator_grid_reflow()


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
	var mode := _shell.layout_mode()
	var info_pane_width := _operator_card_width(mode) * _operator_info_split(mode) - 36.0
	var narrow_card := info_pane_width < 280.0
	card_label.clip_text = narrow_card
	card_label.text_overrun_behavior = (
		TextServer.OVERRUN_TRIM_ELLIPSIS if narrow_card else TextServer.OVERRUN_NO_TRIMMING
	)
	card_label.add_theme_font_size_override(&"font_size", 24)
	card_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _apply_operator_card_role(button: AetheriaButtonType, selected: bool) -> void:
	LunarisOpsType.apply_button(button, &"selected" if selected else &"secondary")
	var resting_style := button.get_theme_stylebox(&"normal").duplicate() as StyleBox
	button.add_theme_stylebox_override(&"hover", resting_style)
	button.add_theme_stylebox_override(&"hover_pressed", resting_style)


func _build_operator_hover_glow() -> Panel:
	var glow := Panel.new()
	glow.name = "OperatorHoverGlow"
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.offset_left = -OPERATOR_GLOW_EXPAND
	glow.offset_top = -OPERATOR_GLOW_EXPAND
	glow.offset_right = OPERATOR_GLOW_EXPAND
	glow.offset_bottom = OPERATOR_GLOW_EXPAND
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.show_behind_parent = true
	glow.z_index = -1
	glow.self_modulate = Color(1.0, 1.0, 1.0, 0.0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = Color(LunarisOpsType.CYAN, OPERATOR_GLOW_ALPHA)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.shadow_color = Color(LunarisOpsType.CYAN, 0.32)
	style.shadow_size = OPERATOR_GLOW_SHADOW_SIZE
	glow.add_theme_stylebox_override(&"panel", style)
	return glow


func _operator_hover_glow(button: Control) -> Panel:
	return button.get_node_or_null("OperatorHoverGlow") as Panel


func _set_operator_hover_glow(button: Control, highlighted: bool) -> void:
	var glow := _operator_hover_glow(button)
	if glow != null:
		glow.self_modulate = Color(1.0, 1.0, 1.0, 1.0 if highlighted else 0.0)


func _center_operator_card_pivot(button: Control) -> void:
	if button == null or not is_instance_valid(button):
		return
	button.pivot_offset = button.size * 0.5


func _on_operator_feedback_changed(button: AetheriaButtonType) -> void:
	if button == null or not is_instance_valid(button):
		return
	var highlighted := button.is_hovered() or button.has_focus()
	var glow_visible := button.is_hovered()
	var target := OPERATOR_SELECTED_SCALE if button.button_pressed else Vector2.ONE
	if highlighted:
		target = OPERATOR_HOVER_SCALE
	button.z_index = 2 if highlighted else 1 if button.button_pressed else 0
	_animate_operator_card_scale(button, target, OPERATOR_HOVER_SECONDS, glow_visible)


func _animate_operator_selection(button: AetheriaButtonType, selected: bool) -> void:
	if button == null or not is_instance_valid(button):
		return
	_kill_operator_feedback_tween(button)
	var highlighted := button.is_hovered() or button.has_focus()
	button.z_index = 2 if highlighted else 1 if selected else 0
	if _reduced_motion():
		button.scale = (
			OPERATOR_HOVER_SCALE
			if highlighted
			else OPERATOR_SELECTED_SCALE
			if selected
			else Vector2.ONE
		)
		_set_operator_hover_glow(button, button.is_hovered())
		return
	var peak := OPERATOR_SELECTION_PEAK_SCALE if selected else Vector2(0.985, 0.985)
	var resting := (
		OPERATOR_HOVER_SCALE
		if highlighted
		else OPERATOR_SELECTED_SCALE
		if selected
		else Vector2.ONE
	)
	var tween := create_tween()
	_operator_feedback_tweens[button.get_instance_id()] = tween
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", peak, OPERATOR_SELECTION_OUT_SECONDS)
	var glow := _operator_hover_glow(button)
	if glow != null:
		tween.parallel().tween_property(
			glow, "self_modulate",
			Color(1.0, 1.0, 1.0, 1.0 if button.is_hovered() else 0.0),
			OPERATOR_SELECTION_OUT_SECONDS,
		)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", resting, OPERATOR_SELECTION_SETTLE_SECONDS)
	tween.finished.connect(_clear_operator_feedback_tween.bind(button.get_instance_id()))


func _animate_operator_card_scale(
		button: AetheriaButtonType, target: Vector2, duration: float, glow_visible: bool,
	) -> void:
	_kill_operator_feedback_tween(button)
	if _reduced_motion():
		button.scale = target
		_set_operator_hover_glow(button, glow_visible)
		return
	var tween := create_tween()
	_operator_feedback_tweens[button.get_instance_id()] = tween
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", target, duration)
	var glow := _operator_hover_glow(button)
	if glow != null:
		tween.parallel().tween_property(
			glow, "self_modulate",
			Color(1.0, 1.0, 1.0, 1.0 if glow_visible else 0.0), duration,
		)
	tween.finished.connect(_clear_operator_feedback_tween.bind(button.get_instance_id()))


func _kill_operator_feedback_tween(button: Control) -> void:
	var instance_id := button.get_instance_id()
	var tween := _operator_feedback_tweens.get(instance_id) as Tween
	if tween != null and tween.is_valid():
		tween.kill()
	_operator_feedback_tweens.erase(instance_id)


func _clear_operator_feedback_tween(instance_id: int) -> void:
	_operator_feedback_tweens.erase(instance_id)


func _reduced_motion() -> bool:
	return bool(ProjectSettings.get_setting("accessibility/reduced_motion", false))


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
			&"ui.squad.predeployment_body", "Review the mission, choose the field team, and confirm deployment.",
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
	if node_name == "TrainingButton":
		return UiCopyType.text(&"ui.squad.training_presentation", "TRAIN\nOPERATORS")
	if node_name == "StartBattle":
		return UiCopyType.text(&"ui.squad.deploy_presentation", "DEPLOY SQUAD")
	return text_value


func _wide_action_width(node_name: String) -> float:
	match node_name:
		"TrainingButton":
			return 336.0
		"StartBattle":
			return DEPLOY_SQUAD_ACTION_WIDTH
		_:
			return 238.0


func _operator_grid_available_width(mode: StringName) -> float:
	var viewport_width := get_viewport_rect().size.x
	var viewport_capacity := (
		minf(640.0, maxf(OPERATOR_CARD_NARROW_MIN_WIDTH, viewport_width - 144.0))
		if mode == &"portrait"
		else maxf(OPERATOR_CARD_MIN_WIDTH, viewport_width * FIELD_TEAM_WIDTH_RATIO - 144.0)
	)
	if _roster_scroll == null or _roster_scroll.size.x <= 1.0:
		return viewport_capacity
	var measured := maxf(
		OPERATOR_CARD_NARROW_MIN_WIDTH,
		_roster_scroll.size.x - float(OPERATOR_RAIL_EDGE_INSET * 2),
	)
	return minf(viewport_capacity, measured)


func _operator_grid_columns(mode: StringName) -> int:
	return RosterGridLayoutType.fitting_columns(
		_operator_grid_available_width(mode),
		OPERATOR_CARD_MIN_WIDTH,
		OPERATOR_GRID_GAP,
		0,
		_grid.get_child_count() if _grid != null else 0,
		mode == &"portrait",
	)


func _operator_card_width(mode: StringName) -> float:
	var minimum_width := (
		OPERATOR_CARD_NARROW_MIN_WIDTH if mode == &"portrait" else OPERATOR_CARD_MIN_WIDTH
	)
	return RosterGridLayoutType.fitted_item_width(
		_operator_grid_available_width(mode),
		_operator_grid_columns(mode),
		OPERATOR_GRID_GAP,
		minimum_width,
		OPERATOR_CARD_WIDTH,
	)


func _queue_operator_grid_reflow() -> void:
	if _operator_grid_reflow_queued:
		return
	_operator_grid_reflow_queued = true
	_apply_operator_grid_reflow.call_deferred()


func _apply_operator_grid_reflow() -> void:
	_operator_grid_reflow_queued = false
	if _operator_grid_reflow_running or _shell == null or _grid == null:
		return
	_operator_grid_reflow_running = true
	var mode := _shell.layout_mode()
	_grid.columns = _operator_grid_columns(mode)
	var card_width := _operator_card_width(mode)
	for child: Node in _grid.get_children():
		if child is not Button:
			continue
		var button := child as Button
		var hero: Dictionary = button.get_meta(&"hero", {})
		button.custom_minimum_size = Vector2(card_width, _operator_card_height(hero, mode))
		var portrait := button.get_node_or_null("OperatorPortrait") as TextureRect
		if portrait != null:
			portrait.anchor_left = _operator_info_split(mode)
			portrait.offset_left = 6.0 if mode == &"portrait" else 12.0
			portrait.offset_right = -6.0 if mode == &"portrait" else -24.0
		_apply_operator_card_text_style(button as AetheriaButtonType)
	_update_operator_rail_insets()
	_operator_grid_reflow_running = false


func _operator_snap_stride() -> float:
	return OPERATOR_CARD_WIDTH + OPERATOR_GRID_GAP


func _update_operator_rail_insets() -> void:
	if _operator_rail_inset == null or _roster_scroll == null:
		return
	_operator_rail_inset.add_theme_constant_override(&"margin_left", OPERATOR_RAIL_EDGE_INSET)
	_operator_rail_inset.add_theme_constant_override(&"margin_right", OPERATOR_RAIL_EDGE_INSET)
	_operator_rail_inset.set_meta(&"operator_snap_edge_inset", float(OPERATOR_RAIL_EDGE_INSET))
	_roster_scroll.set_meta(&"operator_snap_enabled", false)
	_roster_scroll.set_meta(&"operator_snap_stride", _operator_snap_stride())


func _operator_snap_enabled() -> bool:
	return _roster_scroll != null and bool(_roster_scroll.get_meta(&"operator_snap_enabled", false))


func _on_operator_rail_input(event: InputEvent) -> void:
	if not _operator_snap_enabled():
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index in [
			MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN,
			MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_RIGHT,
		]:
			_cancel_operator_snap()
			_schedule_operator_snap.call_deferred()
	elif event is InputEventPanGesture:
		_cancel_operator_snap()
		_schedule_operator_snap.call_deferred()


func _on_operator_scroll_value_changed(_value: float) -> void:
	if not _operator_snap_enabled():
		return
	if not _operator_snap_in_progress and not _operator_scroll_dragging:
		_schedule_operator_snap()


func _on_operator_scrollbar_input(event: InputEvent) -> void:
	if not _operator_snap_enabled():
		return
	if event is not InputEventMouseButton:
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	_operator_scroll_dragging = mouse_event.pressed
	if _operator_scroll_dragging:
		_cancel_operator_snap()
	else:
		_schedule_operator_snap()


func _schedule_operator_snap() -> void:
	if not _operator_snap_enabled():
		return
	if _operator_snap_timer == null or _operator_snap_in_progress:
		return
	_operator_snap_timer.start(OPERATOR_SNAP_IDLE_SECONDS)


func _cancel_operator_snap() -> void:
	if not _operator_snap_enabled():
		return
	if _operator_snap_tween != null and _operator_snap_tween.is_valid():
		_operator_snap_tween.kill()
	_operator_snap_tween = null
	_operator_snap_in_progress = false


func _snap_operator_rail() -> void:
	if not _operator_snap_enabled():
		return
	if _grid == null or _grid.get_child_count() <= 0:
		return
	if _operator_snap_timer != null:
		_operator_snap_timer.stop()
	if _operator_snap_tween != null and _operator_snap_tween.is_valid():
		_operator_snap_tween.kill()
	var stride := _operator_snap_stride()
	var target_index := clampi(
		int(round(float(_roster_scroll.scroll_horizontal) / stride)),
		0,
		_grid.get_child_count() - 1,
	)
	var target := int(round(float(target_index) * stride))
	var bar := _roster_scroll.get_h_scroll_bar()
	var maximum := maxi(0, int(floorf(bar.max_value - bar.page)))
	target = mini(target, maximum)
	_roster_scroll.set_meta(&"operator_snap_target_index", target_index)
	_roster_scroll.set_meta(&"operator_snap_target", target)
	if target == _roster_scroll.scroll_horizontal:
		return
	_operator_snap_in_progress = true
	if _reduced_motion():
		_roster_scroll.scroll_horizontal = target
		_operator_snap_in_progress = false
		return
	_operator_snap_tween = create_tween()
	_operator_snap_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_operator_snap_tween.tween_method(
		_set_operator_scroll_position,
		float(_roster_scroll.scroll_horizontal),
		float(target),
		OPERATOR_SNAP_SECONDS,
	)
	_operator_snap_tween.finished.connect(_on_operator_snap_finished)


func _set_operator_scroll_position(value: float) -> void:
	if _roster_scroll != null:
		_roster_scroll.scroll_horizontal = int(round(value))


func _on_operator_snap_finished() -> void:
	_operator_snap_in_progress = false
	_operator_snap_tween = null


func _hire_recruit_width(mode: StringName) -> float:
	if mode == &"portrait":
		return minf(
			HIRE_RECRUIT_WIDTH,
			maxf(HIRE_RECRUIT_NARROW_MIN_WIDTH, get_viewport_rect().size.x - 128.0),
		)
	return HIRE_RECRUIT_WIDTH


func _operator_info_split(mode: StringName) -> float:
	if mode == &"portrait":
		return 0.54
	return OPERATOR_INFO_SPLIT


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


func _exit_tree() -> void:
	_stop_deploy_ready_pulse()
	_cancel_operator_snap()
	for tween: Tween in _operator_feedback_tweens.values():
		if tween != null and tween.is_valid():
			tween.kill()
	_operator_feedback_tweens.clear()


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


func _on_hire_recruit_hovered() -> void:
	if _hire_recruit == null or _hire_recruit.disabled:
		return
	if not bool(_hire_recruit.get_meta(HIRE_RECRUIT_HOVER_ARMED_META, true)):
		return
	_hire_recruit.set_meta(HIRE_RECRUIT_HOVER_ARMED_META, false)
	Sfx.play(HIRE_RECRUIT_HOVER_SFX)


func _on_hire_recruit_hover_exited() -> void:
	if _hire_recruit != null:
		_hire_recruit.set_meta(HIRE_RECRUIT_HOVER_ARMED_META, true)


func _on_hire_basic_recruit() -> void:
	if _hire_recruit == null or _hire_recruit.disabled:
		return
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
			"{callsign} • JOINED COMPANY MANUS • {remaining} MARKS REMAIN",
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
	var action_text := UiCopyType.text(
		&"ui.campaign.basic_hire_title", "Hire Recruit",
	).to_upper()
	_hire_action_label.text = action_text
	_hire_cost_label.text = str(cost)
	_hire_recruit.text = ""
	_hire_recruit.icon = null
	_hire_recruit.accessibility_name = "%s, %s %s" % [
		action_text, cost,
		ResonanceCurrencyDisplayType.currency_name_for(&"marks"),
	]
	var unavailable := (
		projection.is_empty()
		or marks < cost
		or bool(projection.get("attempt_pending", false))
		or roster_count >= 1024
	)
	var insufficient_funds := not projection.is_empty() and marks < cost
	_hire_recruit.disabled = unavailable
	_hire_recruit.focus_mode = Control.FOCUS_NONE if unavailable else Control.FOCUS_ALL
	_hire_recruit.apply_role(&"disabled" if unavailable else &"primary")
	if not unavailable:
		_apply_clean_training_style(_hire_recruit)
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
				&"ui.campaign.basic_hire_insufficient", "INSUFFICIENT BALANCE",
			)
		else:
			message = UiCopyType.text(
				&"ui.campaign.basic_hire_ready", "BASIC RECRUIT CONTRACT AVAILABLE",
			)
	_hire_recruit.accessibility_live = (
		AccessibilityServer.LIVE_ASSERTIVE if error else AccessibilityServer.LIVE_POLITE
	)
	var compact_insufficient_tooltip := UiCopyType.text(
		&"ui.campaign.basic_hire_insufficient_tooltip",
		"Insufficient funds — 5 Marks required.",
	)
	if insufficient_funds:
		_hire_recruit.tooltip_text = compact_insufficient_tooltip
	elif unavailable:
		_hire_recruit.tooltip_text = message
	else:
		ResonanceCurrencyDisplayType.apply_tooltip(_hire_recruit, message, &"marks")
	_hire_recruit.accessibility_description = message
	if _hire_tooltip_hotspot != null:
		_hire_tooltip_hotspot.visible = insufficient_funds
		_hire_tooltip_hotspot.mouse_filter = (
			Control.MOUSE_FILTER_STOP if insufficient_funds else Control.MOUSE_FILTER_IGNORE
		)
		_hire_tooltip_hotspot.tooltip_text = compact_insufficient_tooltip if insufficient_funds else ""
		_hire_tooltip_hotspot.accessibility_name = (
			compact_insufficient_tooltip if insufficient_funds else ""
		)
	var label_color := LunarisOpsType.MUTED if unavailable else LunarisOpsType.IVORY
	var cost_color := LunarisOpsType.MUTED if unavailable else LunarisOpsType.GOLD
	_hire_action_label.add_theme_color_override(&"font_color", label_color)
	_hire_cost_label.add_theme_color_override(&"font_color", cost_color)
	var cost_icon := _hire_recruit.get_node_or_null(
		"BasicRecruitActionContent/BasicRecruitCostIcon",
	) as TextureRect
	if cost_icon != null:
		cost_icon.self_modulate = Color(0.52, 0.55, 0.58, 0.72) if unavailable else Color.WHITE


func _hire_error_text(code: StringName) -> String:
	match code:
		&"insufficient_marks":
			return UiCopyType.text(
				&"ui.campaign.basic_hire_insufficient", "INSUFFICIENT BALANCE",
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
		_prefetch_hero_pack(hero_id, true, false)
	else:
		_picked.erase(hero_id)
	_refresh()
	_animate_operator_selection(_buttons.get(hero_id) as AetheriaButtonType, pressed)


func _prefetch_hero_pack(hero_id: StringName, prioritize: bool, background: bool) -> void:
	var hero := _hero_by_id(hero_id)
	if hero.is_empty():
		return
	var content_packs := get_node_or_null("/root/ContentPacks")
	if content_packs != null:
		content_packs.call(
			"request_class", String(hero.get("current_class_id", "")), prioritize, background,
		)


func selected_squad_order() -> Array[StringName]:
	return _picked.duplicate()


func reorder_selected_squad(source_hero_id: StringName, target_hero_id: StringName) -> bool:
	var source_index := _picked.find(source_hero_id)
	var target_index := _picked.find(target_hero_id)
	if source_index < 0 or target_index < 0 or source_index == target_index:
		return false
	_picked.remove_at(source_index)
	_picked.insert(target_index, source_hero_id)
	_refresh()
	Sfx.play("ui_click")
	_focus_selected_chip.call_deferred(source_hero_id)
	return true


func move_selected_squad_operator(hero_id: StringName, direction: int) -> bool:
	var source_index := _picked.find(hero_id)
	var target_index := source_index + clampi(direction, -1, 1)
	if source_index < 0 or target_index < 0 or target_index >= _picked.size():
		return false
	var target_hero_id := _picked[target_index]
	return reorder_selected_squad(hero_id, target_hero_id)


func _focus_selected_chip(hero_id: StringName) -> void:
	if _selected_squad_order == null:
		return
	var chip := _selected_squad_order.get_node_or_null(
		"SelectedSquad_%s" % hero_id,
	) as Control
	if chip != null:
		chip.grab_focus()


func _refresh_selected_squad_order() -> void:
	if _selected_squad_order == null:
		return
	for child: Node in _selected_squad_order.get_children():
		_selected_squad_order.remove_child(child)
		child.queue_free()
	if _picked.is_empty():
		_selected_squad_empty = _selected_squad_empty_label()
		_selected_squad_order.add_child(_selected_squad_empty)
		return
	_selected_squad_empty = null
	var drag_hint := UiCopyType.text(
		&"ui.squad.order_drag_hint",
		"Drag to reorder. Keyboard: Alt plus arrow keys.",
	)
	for index: int in _picked.size():
		var hero_id := _picked[index]
		var hero := _hero_by_id(hero_id)
		var chip := SelectedSquadChipType.new()
		chip.configure(hero_id, _hero_callsign(hero), index, drag_hint)
		chip.reorder_requested.connect(reorder_selected_squad)
		chip.move_requested.connect(move_selected_squad_operator)
		chip.pressed.connect(_focus_operator_card.bind(hero_id))
		_selected_squad_order.add_child(chip)


func _focus_operator_card(hero_id: StringName) -> void:
	var button := _buttons.get(hero_id) as Control
	if button == null:
		return
	button.grab_focus()
	if _roster_scroll != null:
		_roster_scroll.ensure_control_visible(button)


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
		_apply_operator_card_role(button, _picked.has(hero_id))
		_apply_operator_card_text_style(button)
	_refresh_selected_squad_order()
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
		&"ui.squad.predeployment_body", "Review the mission, choose the field team, and confirm deployment.",
	)
	var action_text := UiCopyType.text(&"ui.squad.start_battle", "Start Battle")
	var is_error := false
	if _launch_locked:
		status_text = UiCopyType.text(
			&"ui.squad.launch_committing", "Saving the field-team assignment…",
		)
		action_text = UiCopyType.text(&"ui.squad.launch_committing_action", "Deploying…")
	elif Game.mission_launch_retry_pending():
		status_text = UiCopyType.text(
			&"ui.squad.launch_retryable_error",
			"The field-team assignment was not saved. Retry the exact same order.",
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
	if _launch_locked:
		return action_text
	if Game.mission_launch_retry_pending():
		return UiCopyType.text(&"ui.squad.retry_presentation", "RETRY\nDEPLOYMENT")
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
				"The field-team assignment was not saved. Retry the exact same order.",
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
		&"rarity": int(hero.get("rarity", definition.rarity)),
		&"level": int(hero.get("level", 1)),
	}
	if bool(hero.get("fallen", false)):
		return _format_copy(
			&"ui.squad.card_fallen", "{name}\n{rarity}★ · LV {level}\nFallen · Vahalla", args,
		)
	if hero.get("hero_kind", "recruit") == "premium":
		return _format_copy(
			&"ui.squad.card_premium", "{name}\n{rarity}★ · LV {level}\n{cost} DP · Premium hero · {lives} prepared bodies", args,
		)
	return _format_copy(
		&"ui.squad.card_ready", "{name}\n{rarity}★ · LV {level}\n{cost} DP · Ready", args,
	)


func _on_locale_changed(_locale_id: StringName) -> void:
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
		"ReadinessCopy": UiCopyType.text(&"ui.squad.predeployment_body", "Review the mission, choose the field team, and confirm deployment."),
	}
	for node_name: String in copy_by_node:
		var label := find_child(node_name, true, false) as Label
		if label != null:
			label.text = copy_by_node[node_name]
	if _filter_input != null:
		_filter_input.placeholder_text = UiCopyType.text(&"ui.identity_filter.placeholder", "Filter operators")
	if _sort_select != null:
		var sort_options := _identity_sort_options()
		for index: int in mini(_sort_select.item_count, sort_options.size()):
			var option: Dictionary = sort_options[index]
			_sort_select.set_item_text(index, UiCopyType.text(option["key"], option["fallback"]))
		_sort_select.accessibility_name = UiCopyType.text(&"ui.identity_sort.label", "Sort operators")
		_sort_select.accessibility_description = _sort_select.get_item_text(_sort_select.selected)
		_sort_select.tooltip_text = "%s — %s" % [
			_sort_select.accessibility_name, _sort_select.accessibility_description,
		]
	var order_heading := find_child("SelectedSquadOrderHeading", true, false) as Label
	if order_heading != null:
		order_heading.text = UiCopyType.text(&"ui.squad.order_heading", "Deployment Order")
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
	if _selected_squad_order != null:
		for child: Node in _selected_squad_order.get_children():
			if child is SelectedSquadChipType:
				focusable.append(child as Control)
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
	if _sort_select != null:
		_sort_select.custom_minimum_size.x = (
			minf(300.0, maxf(220.0, get_viewport_rect().size.x - 128.0))
			if mode == &"portrait"
			else 300.0
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
		_roster_scroll.custom_minimum_size.y = 240.0 if mode == &"portrait" else 260.0
		_queue_operator_grid_reflow()
	if _intel_scroll != null:
		_intel_scroll.custom_minimum_size.y = 170.0 if mode == &"portrait" else 0.0
	if _filter_bar != null:
		_filter_bar.set_compact(true)
		_filter_bar.set_roomy(false)
		var status_width_scale := FIELD_TEAM_STATUS_WIDTH_SCALE
		if mode == &"portrait":
			status_width_scale = minf(
				FIELD_TEAM_STATUS_WIDTH_SCALE,
				maxf(1.0, (get_viewport_rect().size.x - 128.0) / 176.0),
			)
		elif get_viewport_rect().size.x >= 1500.0:
			var body_width := maxf(760.0, get_viewport_rect().size.x - 112.0)
			var field_content_width := (body_width - 16.0) * FIELD_TEAM_WIDTH_RATIO - 48.0
			status_width_scale = minf(
				FIELD_TEAM_STATUS_WIDTH_SCALE,
				maxf(1.0, (field_content_width - 16.0) / (176.0 * 3.0)),
			)
		_filter_bar.set_status_button_width_scale(status_width_scale)
		_filter_bar.set_dense_inline(mode == &"regular_landscape" and get_viewport_rect().size.x < 1500.0)
		_filter_bar.set_inline(mode == &"regular_landscape" and get_viewport_rect().size.x >= 1500.0)
	if _hire_recruit != null:
		_hire_recruit.custom_minimum_size = Vector2(_hire_recruit_width(mode), 72.0)
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
		_footer.vertical = mode != &"regular_landscape"
	var readiness_copy := find_child("ReadinessCopy", true, false) as Label
	if readiness_copy != null:
		readiness_copy.add_theme_font_size_override(
			&"font_size",
			18 if mode == &"regular_landscape" and get_viewport_rect().size.x < 1500.0 else 24,
		)
	if _actions != null:
		_actions.columns = (
			1
			if mode == &"portrait" or get_viewport_rect().size.x < COMPACT_ACTION_STACK_THRESHOLD
			else 3
		)
		_actions.size_flags_horizontal = (
			Control.SIZE_EXPAND_FILL if mode != &"regular_landscape" else Control.SIZE_SHRINK_END
		)
		for action: Node in _actions.get_children():
			if action is Button:
				var target_width := _wide_action_width(action.name)
				if mode == &"regular_landscape" and get_viewport_rect().size.x <= COMPACT_ACTION_STACK_THRESHOLD:
					match action.name:
						"BackButton":
							target_width = REGULAR_BACK_ACTION_WIDTH
						"TrainingButton":
							target_width = REGULAR_TRAINING_ACTION_WIDTH
						"StartBattle":
							target_width = REGULAR_DEPLOY_ACTION_WIDTH
				if mode == &"portrait":
					target_width = minf(target_width, maxf(220.0, get_viewport_rect().size.x - 96.0))
				(action as Button).custom_minimum_size.x = target_width
	_update_deploy_pivot.call_deferred()


func _on_viewport_resized() -> void:
	if _shell != null:
		_on_layout_mode_changed.call_deferred(_shell.layout_mode())
		_queue_operator_grid_reflow()


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
