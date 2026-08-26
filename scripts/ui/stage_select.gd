extends Control

## Campaign stage select. Locked rows remain disabled controls; stage stars,
## sequential unlocks, selection, and routing remain projections of Game.

const SHELL_SCENE := preload("res://scenes/ui/components/aetheria_screen_shell.tscn")
const AetheriaButtonType := preload("res://scripts/ui/components/aetheria_button.gd")
const AetheriaLabelType := preload("res://scripts/ui/components/aetheria_label.gd")
const AetheriaScreenShellType := preload("res://scripts/ui/components/aetheria_screen_shell.gd")
const FactionHeraldryType := preload("res://scripts/ui/components/faction_heraldry.gd")
const UiCopyType := preload("res://scripts/ui/components/ui_copy.gd")
const ResonanceStarType := preload("res://scripts/ui/components/resonance_star.gd")
const Style := preload("res://scripts/ui/components/lunaris_ops_style.gd")
const NARRATIVE_CATALOG := preload("res://data/presentation/narrative/stage_narrative_catalog.tres")
const StageNarrativeDefType := preload("res://data/presentation/narrative/stage_narrative_def.gd")
const StageNarrativeCatalogType := preload("res://data/presentation/narrative/stage_narrative_catalog.gd")
const REWARD_DIRS := {
	&"operator": "res://data/operators",
	&"trap": "res://data/traps",
	&"spell": "res://data/spells",
}

var _rows: GridContainer = null
var _header: GridContainer = null
var _body: GridContainer = null
var _dossier_title: AetheriaLabelType = null
var _dossier_status: AetheriaLabelType = null
var _dossier_facts: AetheriaLabelType = null
var _dossier_objective: AetheriaLabelType = null
var _dossier_threat: AetheriaLabelType = null
var _dossier_reward: AetheriaLabelType = null
var _dossier_hint: AetheriaLabelType = null
var _dossier_stars: HBoxContainer = null
var _shell: AetheriaScreenShellType = null
var _stage_by_id: Dictionary = {}
var _next_stage_id: StringName = &""
var _dossier_stage_id: StringName = &""
var _eyebrow: AetheriaLabelType = null
var _progress: AetheriaLabelType = null
var _route_heading: AetheriaLabelType = null
var _route_note: AetheriaLabelType = null
var _dossier_eyebrow: AetheriaLabelType = null
var _back: AetheriaButtonType = null
var _recruitment_grid: GridContainer = null
var _recruitment_metrics: GridContainer = null
var _hire_title: AetheriaLabelType = null
var _hire_body: AetheriaLabelType = null
var _hire_recruit: AetheriaButtonType = null
var _hire_marks: AetheriaLabelType = null
var _hire_roster: AetheriaLabelType = null
var _hire_status: AetheriaLabelType = null


func _ready() -> void:
	Game.content = self
	_shell = SHELL_SCENE.instantiate() as AetheriaScreenShellType
	_shell.name = "CampaignShell"
	_shell.full_safe_area = true
	add_child(_shell)
	_shell.layout_mode_changed.connect(_on_layout_mode_changed)

	var column := VBoxContainer.new()
	column.name = "CampaignColumn"
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override(&"separation", 14)
	_shell.content_host().add_child(column)

	_build_header(column)
	_build_body(column)
	_populate_route()
	_on_layout_mode_changed(_shell.layout_mode())
	if not I18n.locale_changed.is_connected(_on_locale_changed):
		I18n.locale_changed.connect(_on_locale_changed)


func _build_header(column: VBoxContainer) -> void:
	_header = GridContainer.new()
	_header.name = "CampaignHeader"
	_header.columns = 3
	_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_header.add_theme_constant_override(&"h_separation", 16)
	_header.add_theme_constant_override(&"v_separation", 10)
	column.add_child(_header)

	var identity := HBoxContainer.new()
	identity.name = "CampaignIdentity"
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override(&"separation", 12)
	identity.add_child(FactionHeraldryType.make_symbol(FactionHeraldryType.ACTIVE_FACTION, 48.0))
	var headings := VBoxContainer.new()
	headings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_eyebrow = AetheriaLabelType.new()
	_eyebrow.name = "CampaignEyebrow"
	_eyebrow.apply_role(&"dense_detail")
	_eyebrow.text = UiCopyType.text(&"ui.campaign.eyebrow", "Lunaris Expedition Archive")
	headings.add_child(_eyebrow)
	var heading := AetheriaLabelType.new()
	heading.name = "CampaignHeading"
	heading.apply_role(&"title")
	heading.text = UiCopyType.text(&"ui.campaign.heading", "Campaign").to_upper()
	headings.add_child(heading)
	identity.add_child(headings)
	_header.add_child(identity)

	_progress = AetheriaLabelType.new()
	_progress.name = "CampaignProgress"
	_progress.apply_role(&"dense_heading")
	_progress.custom_minimum_size.x = 190.0
	_progress.autowrap_mode = TextServer.AUTOWRAP_OFF
	_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_header.add_child(_progress)

	_back = AetheriaButtonType.new()
	_back.name = "BackToStaging"
	_back.custom_minimum_size = Vector2(220.0, 64.0)
	_back.apply_role(&"secondary")
	_back.apply_compact_action_layout()
	_back.pressed.connect(_on_back_to_staging)
	_header.add_child(_back)
	_refresh_header_copy()


func _build_body(column: VBoxContainer) -> void:
	var rule := ColorRect.new()
	rule.name = "CampaignRule"
	rule.custom_minimum_size = Vector2(0, 2)
	rule.color = Color(Style.CYAN, 0.52)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(rule)

	_body = GridContainer.new()
	_body.name = "CampaignBody"
	_body.columns = 2
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override(&"h_separation", 16)
	_body.add_theme_constant_override(&"v_separation", 12)
	column.add_child(_body)

	var route_panel := PanelContainer.new()
	route_panel.name = "CampaignRoutePanel"
	route_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	route_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	route_panel.custom_minimum_size.x = 520
	Style.apply_panel(route_panel, &"quiet")
	_body.add_child(route_panel)
	var route_stack := VBoxContainer.new()
	route_stack.add_theme_constant_override(&"separation", 10)
	route_panel.add_child(route_stack)
	_route_heading = AetheriaLabelType.new()
	_route_heading.name = "RouteHeading"
	_route_heading.apply_role(&"heading")
	route_stack.add_child(_route_heading)
	_route_note = AetheriaLabelType.new()
	_route_note.name = "RouteNote"
	_route_note.apply_role(&"detail")
	_route_note.text = UiCopyType.text(
		&"ui.campaign.route_note",
		"Select an available operation. Cleared operations remain replayable.",
	)
	route_stack.add_child(_route_note)
	_build_recruitment_desk(route_stack)
	var scroll := ScrollContainer.new()
	scroll.name = "CampaignScroll"
	scroll.custom_minimum_size.y = 112.0
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	route_stack.add_child(scroll)
	_rows = GridContainer.new()
	_rows.name = "StageRows"
	_rows.columns = 1
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows.add_theme_constant_override(&"h_separation", 8)
	_rows.add_theme_constant_override(&"v_separation", 7)
	scroll.add_child(_rows)

	var dossier := PanelContainer.new()
	dossier.name = "MissionDossier"
	dossier.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dossier.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dossier.custom_minimum_size.x = 420
	Style.apply_panel(dossier, &"result")
	_body.add_child(dossier)
	var dossier_scroll := ScrollContainer.new()
	dossier_scroll.name = "MissionDossierScroll"
	dossier_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dossier_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dossier_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dossier.add_child(dossier_scroll)
	var dossier_stack := VBoxContainer.new()
	dossier_stack.name = "DossierContent"
	dossier_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dossier_stack.add_theme_constant_override(&"separation", 8)
	dossier_scroll.add_child(dossier_stack)
	_dossier_eyebrow = AetheriaLabelType.new()
	_dossier_eyebrow.name = "DossierEyebrow"
	_dossier_eyebrow.apply_role(&"dense_detail")
	_dossier_eyebrow.text = UiCopyType.text(&"ui.campaign.selected_operation", "Selected Operation")
	dossier_stack.add_child(_dossier_eyebrow)
	_dossier_title = AetheriaLabelType.new()
	_dossier_title.name = "DossierTitle"
	_dossier_title.apply_role(&"title")
	dossier_stack.add_child(_dossier_title)
	_dossier_status = AetheriaLabelType.new()
	_dossier_status.name = "DossierStatus"
	_dossier_status.apply_role(&"completed_badge")
	dossier_stack.add_child(_dossier_status)
	_dossier_stars = HBoxContainer.new()
	_dossier_stars.name = "DossierStars"
	_dossier_stars.add_theme_constant_override(&"separation", 8)
	dossier_stack.add_child(_dossier_stars)
	_dossier_objective = AetheriaLabelType.new()
	_dossier_objective.name = "DossierObjective"
	_dossier_objective.apply_role(&"body")
	_dossier_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dossier_stack.add_child(_dossier_objective)
	_dossier_threat = AetheriaLabelType.new()
	_dossier_threat.name = "DossierThreat"
	_dossier_threat.apply_role(&"detail")
	_dossier_threat.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dossier_stack.add_child(_dossier_threat)
	_dossier_facts = AetheriaLabelType.new()
	_dossier_facts.name = "DossierFacts"
	_dossier_facts.apply_role(&"body")
	_dossier_facts.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dossier_stack.add_child(_dossier_facts)
	_dossier_reward = AetheriaLabelType.new()
	_dossier_reward.name = "DossierReward"
	_dossier_reward.apply_role(&"dense_heading")
	_dossier_reward.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dossier_stack.add_child(_dossier_reward)
	dossier_stack.move_child(_dossier_reward, _dossier_facts.get_index())
	_dossier_hint = AetheriaLabelType.new()
	_dossier_hint.name = "DossierHint"
	_dossier_hint.apply_role(&"detail")
	_dossier_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dossier_stack.add_child(_dossier_hint)


func _build_recruitment_desk(parent: VBoxContainer) -> void:
	var panel := PanelContainer.new()
	panel.name = "BasicRecruitDesk"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Style.apply_panel(panel, &"selected")
	parent.add_child(panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override(&"separation", 8)
	panel.add_child(stack)
	_recruitment_grid = GridContainer.new()
	_recruitment_grid.name = "BasicRecruitGrid"
	_recruitment_grid.columns = 2
	_recruitment_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_recruitment_grid.add_theme_constant_override(&"h_separation", 16)
	_recruitment_grid.add_theme_constant_override(&"v_separation", 8)
	stack.add_child(_recruitment_grid)
	var briefing := VBoxContainer.new()
	briefing.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	briefing.add_theme_constant_override(&"separation", 4)
	_recruitment_grid.add_child(briefing)
	_hire_title = AetheriaLabelType.new()
	_hire_title.name = "BasicRecruitTitle"
	_hire_title.apply_role(&"heading")
	_hire_title.text = UiCopyType.text(
		&"ui.campaign.basic_hire_title", "Company Reinforcements",
	).to_upper()
	briefing.add_child(_hire_title)
	_hire_body = AetheriaLabelType.new()
	_hire_body.name = "BasicRecruitBody"
	_hire_body.apply_role(&"detail")
	_hire_body.text = UiCopyType.text(
		&"ui.campaign.basic_hire_body",
		"Hire one persistent basic Recruit. Training can specialize them later.",
	)
	_hire_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	briefing.add_child(_hire_body)
	_recruitment_metrics = GridContainer.new()
	_recruitment_metrics.name = "BasicRecruitMetrics"
	_recruitment_metrics.columns = 2
	_recruitment_metrics.add_theme_constant_override(&"h_separation", 14)
	_recruitment_metrics.add_theme_constant_override(&"v_separation", 4)
	briefing.add_child(_recruitment_metrics)
	_hire_marks = AetheriaLabelType.new()
	_hire_marks.name = "BasicRecruitMarks"
	_hire_marks.apply_role(&"cost_badge")
	_hire_marks.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hire_marks.autowrap_mode = TextServer.AUTOWRAP_OFF
	_recruitment_metrics.add_child(_hire_marks)
	_hire_roster = AetheriaLabelType.new()
	_hire_roster.name = "BasicRecruitRoster"
	_hire_roster.apply_role(&"dense_detail")
	_hire_roster.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hire_roster.autowrap_mode = TextServer.AUTOWRAP_OFF
	_recruitment_metrics.add_child(_hire_roster)
	_hire_recruit = AetheriaButtonType.new()
	_hire_recruit.name = "HireBasicRecruit"
	_hire_recruit.custom_minimum_size = Vector2(280.0, 72.0)
	_hire_recruit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hire_recruit.apply_role(&"primary")
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
	_refresh_recruitment_desk()


func _populate_route() -> void:
	var stage_stars: Dictionary = Game.campaign_projection().get("stage_stars", {})
	var enabled_rows: Array[Button] = []
	for stage_id: StringName in Game.campaign_stage_ids():
		var stage := load("res://data/stages/%s.tres" % stage_id) as StageDef
		_stage_by_id[stage_id] = stage
		var unlocked: bool = Game.is_stage_unlocked(stage_id)
		if unlocked and not stage_stars.has(stage_id) and _next_stage_id.is_empty():
			_next_stage_id = stage_id
		var row := AetheriaButtonType.new()
		row.name = "Stage_%s" % stage_id
		row.text = _row_text(stage, unlocked)
		row.custom_minimum_size = Vector2(44.0, 58.0)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.disabled = not unlocked
		var is_next := unlocked and not stage_stars.has(stage_id) and _next_stage_id == stage_id
		row.apply_role(&"selected" if is_next else (&"secondary" if unlocked else &"disabled"))
		row.set_presentation_text(row.text, _row_presentation_text(stage, unlocked, is_next))
		row.apply_compact_action_layout()
		row.tooltip_text = row.text
		if not unlocked:
			row.focus_mode = Control.FOCUS_NONE
		else:
			enabled_rows.append(row)
			row.focus_entered.connect(_show_dossier.bind(stage_id))
			row.mouse_entered.connect(_show_dossier.bind(stage_id))
		row.pressed.connect(_on_stage_pressed.bind(stage_id))
		_rows.add_child(row)

	var back := _header.get_node("BackToStaging") as Button
	_wire_focus(enabled_rows, back)
	var dossier_id := _next_stage_id
	if dossier_id.is_empty() and not Game.campaign_stage_ids().is_empty():
		dossier_id = Game.campaign_stage_ids()[-1]
	_show_dossier(dossier_id)


func _show_dossier(stage_id: StringName) -> void:
	if not _stage_by_id.has(stage_id):
		return
	var stage: StageDef = _stage_by_id[stage_id]
	_dossier_stage_id = stage_id
	var stars := int(Game.campaign_projection().get("stage_stars", {}).get(stage_id, 0))
	var unlocked := Game.is_stage_unlocked(stage_id)
	var localized_title := UiCopyType.stage_title(stage)
	_dossier_title.text = "%02d · %s" % [stage.campaign_index, localized_title]
	_route_heading.text = _format_copy(
		&"ui.campaign.route_heading", "{stage} · Operation Route", {&"stage": localized_title},
	)
	if not unlocked:
		_dossier_status.text = UiCopyType.text(
			&"ui.campaign.status_sealed", "Sealed · Complete the prior operation",
		)
	elif stars > 0:
		_dossier_status.text = UiCopyType.text(
			&"ui.campaign.status_cleared", "Cleared · Replay available",
		)
	else:
		_dossier_status.text = UiCopyType.text(
			&"ui.campaign.status_next", "Next operation · Ready",
		)
	var narrative: StageNarrativeDefType = (NARRATIVE_CATALOG as StageNarrativeCatalogType).get_record(stage_id)
	_dossier_objective.text = UiCopyType.format_text(&"ui.campaign.objective", "OBJECTIVE — {text}", {
		&"text": UiCopyType.stage_narrative_text(narrative, StageNarrativeDefType.Field.OBJECTIVE),
	})
	_dossier_threat.text = UiCopyType.format_text(&"ui.campaign.threat", "THREAT — {text}", {
		&"text": UiCopyType.stage_narrative_text(narrative, StageNarrativeDefType.Field.THREAT),
	})
	_dossier_facts.text = _format_copy(
		&"ui.campaign.facts",
		"Squad {squad} · Wave windows {waves}\nReward records {rewards} · Leak limit {leak_limit}",
		{
			&"squad": stage.squad_size,
			&"waves": stage.wave_starts.size(),
			&"rewards": stage.rewards.size(),
			&"leak_limit": stage.leak_limit,
		},
	)
	var reward_names: Array[String] = []
	for reward: Dictionary in stage.rewards:
		reward_names.append(_reward_name(reward))
	_dossier_reward.text = UiCopyType.format_text(
		&"ui.campaign.first_clear_reward", "FIRST CLEAR — {rewards}",
		{&"rewards": _localized_list(reward_names) if not reward_names.is_empty() else UiCopyType.text(&"ui.campaign.record_only", "RECORD ONLY")},
	)
	_dossier_hint.text = UiCopyType.stage_hint(stage)
	for child: Node in _dossier_stars.get_children():
		child.queue_free()
	for index: int in 3:
		var star := ResonanceStarType.new()
		star.name = "DossierStar_%d" % (index + 1)
		star.set_state(Style.GOLD, index < stars)
		_dossier_stars.add_child(star)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back_to_staging()


func _row_text(stage: StageDef, unlocked: bool) -> String:
	var is_next := unlocked and int(Game.campaign_projection().get("stage_stars", {}).get(stage.id, 0)) == 0 and _next_stage_id == stage.id
	return _row_presentation_text(stage, unlocked, is_next)


func _row_presentation_text(stage: StageDef, unlocked: bool, is_next: bool) -> String:
	var stars := int(Game.campaign_projection().get("stage_stars", {}).get(stage.id, 0))
	var state := UiCopyType.text(&"ui.campaign.row_locked", "Locked")
	if unlocked:
		state = UiCopyType.text(
			&"ui.campaign.row_cleared" if stars > 0 else (
				&"ui.campaign.row_next" if is_next else &"ui.campaign.row_available"
			),
			"Cleared" if stars > 0 else ("Next" if is_next else "Available"),
		)
	return "%02d  %s  ·  %s" % [stage.campaign_index, UiCopyType.stage_title(stage), state]


func _wire_focus(enabled_rows: Array[Button], back: Button) -> void:
	var focusable := enabled_rows.duplicate()
	if _hire_recruit != null and not _hire_recruit.disabled:
		focusable.append(_hire_recruit)
	focusable.append(back)
	for index: int in focusable.size():
		var current: Button = focusable[index]
		var previous: Button = focusable[(index - 1 + focusable.size()) % focusable.size()]
		var next: Button = focusable[(index + 1) % focusable.size()]
		current.focus_neighbor_top = current.get_path_to(previous)
		current.focus_previous = current.get_path_to(previous)
		current.focus_neighbor_bottom = current.get_path_to(next)
		current.focus_next = current.get_path_to(next)
	if not enabled_rows.is_empty():
		enabled_rows[0].grab_focus.call_deferred()
	else:
		back.grab_focus.call_deferred()


func _refresh_focus_chain() -> void:
	if _rows == null or _header == null:
		return
	var enabled_rows: Array[Button] = []
	for child: Node in _rows.get_children():
		if child is Button and not (child as Button).disabled:
			enabled_rows.append(child as Button)
	var back := _header.get_node_or_null("BackToStaging") as Button
	if back != null:
		_wire_focus(enabled_rows, back)


func _on_stage_pressed(stage_id: StringName) -> void:
	Sfx.play("ui_click")
	Game.selected_stage_id = stage_id
	Game.open_squad_select()


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
	_refresh_recruitment_desk(
		UiCopyType.format_text(
			&"ui.campaign.basic_hire_success",
			"{callsign} • JOINED COMPANY 33 • {remaining} MARKS REMAIN",
			{&"callsign": callsign, &"remaining": int(projection.get("marks", 0))},
		),
		false,
	)
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
	_hire_roster.text = UiCopyType.format_text(
		&"ui.campaign.basic_hire_roster", "{count} PERSONNEL READY",
		{&"count": (projection.get("ready_heroes", []) as Array).size()},
	)
	var action_text := UiCopyType.format_text(
		&"ui.campaign.basic_hire_action", "HIRE • {cost} MARKS", {&"cost": cost},
	)
	_hire_recruit.set_presentation_text(action_text, action_text)
	_hire_recruit.tooltip_text = action_text
	_hire_recruit.accessibility_description = action_text
	var unavailable := projection.is_empty() or marks < cost or bool(projection.get("attempt_pending", false)) or roster_count >= 1024
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
			message = UiCopyType.format_text(
				&"ui.campaign.basic_hire_insufficient",
				"Earn {count} more Marks to hire another Recruit.",
				{&"count": cost - marks},
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
	_hire_status.add_theme_color_override(&"font_color", Style.DANGER if error else Style.CYAN)
	_refresh_focus_chain()


func _hire_error_text(code: StringName) -> String:
	match code:
		&"insufficient_marks":
			var projection := Game.campaign_projection()
			var deficit := maxi(
				1,
				int(projection.get("basic_recruit_cost", 5)) - int(projection.get("marks", 0)),
			)
			return UiCopyType.format_text(
				&"ui.campaign.basic_hire_insufficient",
				"Earn {count} more Marks to hire another Recruit.",
				{&"count": deficit},
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


func _on_layout_mode_changed(mode: StringName) -> void:
	if _header != null:
		_header.columns = 1 if mode == &"portrait" else 3
	if _body != null:
		_body.columns = 1 if mode == &"portrait" else 2
		var route_panel := _body.get_node_or_null("CampaignRoutePanel") as Control
		var dossier := _body.get_node_or_null("MissionDossier") as Control
		if route_panel != null:
			route_panel.custom_minimum_size = Vector2(0 if mode == &"portrait" else 520, 420 if mode == &"portrait" else 0)
		if dossier != null:
			dossier.custom_minimum_size = Vector2(0 if mode == &"portrait" else 420, 300 if mode == &"portrait" else 0)
	if _recruitment_grid != null:
		_recruitment_grid.columns = 1 if mode == &"portrait" else 2
	if _recruitment_metrics != null:
		_recruitment_metrics.columns = 2
	if _hire_body != null:
		_hire_body.visible = mode != &"portrait"
	if _hire_recruit != null:
		_hire_recruit.custom_minimum_size.x = 0.0 if mode == &"portrait" else 280.0
		_hire_recruit.custom_minimum_size.y = 56.0 if mode == &"portrait" else 72.0
	# A full-safe-area shell computes its available plate before this callback.
	# Refit once after descendant column minima settle so landscape widths cannot
	# survive a live rotation into portrait.
	if _shell != null:
		_shell.relayout.call_deferred(Vector2i(get_viewport_rect().size))


func _on_locale_changed(_locale_id: StringName) -> void:
	_refresh_header_copy()
	if _hire_title != null:
		_hire_title.text = UiCopyType.text(
			&"ui.campaign.basic_hire_title", "Company Reinforcements",
		).to_upper()
	if _hire_body != null:
		_hire_body.text = UiCopyType.text(
			&"ui.campaign.basic_hire_body",
			"Hire one persistent basic Recruit. Training can specialize them later.",
		)
	if _hire_recruit != null:
		_hire_recruit.accessibility_name = UiCopyType.text(
			&"ui.campaign.basic_hire_title", "Company Reinforcements",
		)
	if _hire_status != null:
		_hire_status.accessibility_name = UiCopyType.text(
			&"ui.campaign.basic_hire_title", "Company Reinforcements",
		)
		_refresh_recruitment_desk()
	if _route_note != null:
		_route_note.text = UiCopyType.text(
			&"ui.campaign.route_note",
			"Select an available operation. Cleared operations remain replayable.",
		)
	if _dossier_eyebrow != null:
		_dossier_eyebrow.text = UiCopyType.text(
			&"ui.campaign.selected_operation", "Selected Operation",
		)
	for stage_id: StringName in _stage_by_id:
		var stage: StageDef = _stage_by_id[stage_id]
		var row := _rows.get_node_or_null("Stage_%s" % stage_id) as AetheriaButtonType
		if row == null:
			continue
		var unlocked := Game.is_stage_unlocked(stage_id)
		var is_next := unlocked and _next_stage_id == stage_id
		row.text = _row_text(stage, unlocked)
		row.set_presentation_text(row.text, _row_presentation_text(stage, unlocked, is_next))
		row.tooltip_text = row.text
	if not _dossier_stage_id.is_empty():
		_show_dossier(_dossier_stage_id)


func _refresh_header_copy() -> void:
	if _eyebrow != null:
		_eyebrow.text = UiCopyType.text(&"ui.campaign.eyebrow", "Lunaris Expedition Archive")
	if _progress != null:
		var stars: Dictionary = Game.campaign_projection().get("stage_stars", {})
		_progress.text = _format_copy(
			&"ui.campaign.progress", "{cleared} / {total} cleared",
			{&"cleared": stars.size(), &"total": Game.campaign_stage_ids().size()},
		)
	if _back != null:
		_back.text = UiCopyType.text(&"ui.campaign.back_to_staging", "Back to Staging")
		_back.set_presentation_text(_back.text, UiCopyType.text(&"ui.common.back", "Back"))
		_back.tooltip_text = _back.text


func _format_copy(key: StringName, fallback: String, args: Dictionary) -> String:
	var value := UiCopyType.text(key, fallback)
	for name: StringName in args:
		value = value.replace("{%s}" % name, str(args[name]))
	return value


func _localized_list(values: Array[String]) -> String:
	return ("、" if I18n.locale() == &"zh-CN" else ", ").join(values)


func _on_back_to_staging() -> void:
	Sfx.play("ui_back")
	Game.open_staging()


func _reward_name(reward: Dictionary) -> String:
	var kind := StringName(reward.get("kind", &""))
	var identifier := StringName(reward.get("id", &""))
	if not REWARD_DIRS.has(kind):
		return String(identifier).replace("_", " ").capitalize()
	var definition: Resource = load("%s/%s.tres" % [REWARD_DIRS[kind], identifier])
	if definition is OperatorDef:
		return UiCopyType.operator_name(definition)
	if definition is TrapDef:
		return UiCopyType.trap_name(definition)
	if definition is SpellDef:
		return UiCopyType.spell_name(definition)
	return String(identifier).replace("_", " ").capitalize()
