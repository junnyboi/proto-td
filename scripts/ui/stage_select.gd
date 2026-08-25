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
	var eyebrow := AetheriaLabelType.new()
	eyebrow.name = "CampaignEyebrow"
	eyebrow.apply_role(&"dense_detail")
	eyebrow.text = "LUNARIS EXPEDITION ARCHIVE"
	headings.add_child(eyebrow)
	var heading := AetheriaLabelType.new()
	heading.name = "CampaignHeading"
	heading.apply_role(&"title")
	heading.text = UiCopyType.text(&"ui.campaign.heading", "Campaign").to_upper()
	headings.add_child(heading)
	identity.add_child(headings)
	_header.add_child(identity)

	var progress := AetheriaLabelType.new()
	progress.name = "CampaignProgress"
	progress.apply_role(&"dense_heading")
	progress.custom_minimum_size.x = 190.0
	progress.autowrap_mode = TextServer.AUTOWRAP_OFF
	progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var stars: Dictionary = Game.campaign_projection().get("stage_stars", {})
	progress.text = "%d / %d CLEARED" % [stars.size(), Game.campaign_stage_ids().size()]
	_header.add_child(progress)

	var back := AetheriaButtonType.new()
	back.name = "BackToStaging"
	back.custom_minimum_size = Vector2(220.0, 64.0)
	back.apply_role(&"secondary")
	back.text = UiCopyType.text(&"ui.campaign.back_to_staging", "Back to Staging")
	back.set_presentation_text(back.text, UiCopyType.text(&"ui.common.back", "Back").to_upper())
	back.apply_compact_action_layout()
	back.tooltip_text = back.text
	back.pressed.connect(_on_back_to_staging)
	_header.add_child(back)


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
	var route_heading := AetheriaLabelType.new()
	route_heading.name = "RouteHeading"
	route_heading.apply_role(&"heading")
	route_heading.text = "FIRST STAND · OPERATION ROUTE"
	route_stack.add_child(route_heading)
	var route_note := AetheriaLabelType.new()
	route_note.apply_role(&"detail")
	route_note.text = "Select an available operation. Cleared records remain replayable."
	route_stack.add_child(route_note)
	var scroll := ScrollContainer.new()
	scroll.name = "CampaignScroll"
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
	var dossier_eyebrow := AetheriaLabelType.new()
	dossier_eyebrow.apply_role(&"dense_detail")
	dossier_eyebrow.text = "SELECTED OPERATION"
	dossier_stack.add_child(dossier_eyebrow)
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
	var stars := int(Game.campaign_projection().get("stage_stars", {}).get(stage_id, 0))
	var unlocked := Game.is_stage_unlocked(stage_id)
	_dossier_title.text = "%02d · %s" % [stage.campaign_index, UiCopyType.stage_title(stage).to_upper()]
	if not unlocked:
		_dossier_status.text = "SEALED · COMPLETE PRIOR OPERATION"
	elif stars > 0:
		_dossier_status.text = "CLEARED · REPLAY AVAILABLE"
	else:
		_dossier_status.text = "NEXT OPERATION · READY"
	var narrative: StageNarrativeDefType = (NARRATIVE_CATALOG as StageNarrativeCatalogType).get_record(stage_id)
	_dossier_objective.text = UiCopyType.format_text(&"ui.campaign.objective", "OBJECTIVE — {text}", {
		&"text": UiCopyType.stage_narrative_text(narrative, StageNarrativeDefType.Field.OBJECTIVE),
	})
	_dossier_threat.text = UiCopyType.format_text(&"ui.campaign.threat", "THREAT — {text}", {
		&"text": UiCopyType.stage_narrative_text(narrative, StageNarrativeDefType.Field.THREAT),
	})
	_dossier_facts.text = "SQUAD  %d  ·  WAVE WINDOWS  %d\nREWARD RECORDS  %d  ·  LEAK LIMIT  %d" % [
		stage.squad_size,
		stage.wave_starts.size(),
		stage.rewards.size(),
		stage.leak_limit,
	]
	var reward_names: Array[String] = []
	for reward: Dictionary in stage.rewards:
		reward_names.append(_reward_name(reward).to_upper())
	_dossier_reward.text = UiCopyType.format_text(
		&"ui.campaign.first_clear_reward", "FIRST CLEAR — {rewards}",
		{&"rewards": ", ".join(reward_names) if not reward_names.is_empty() else UiCopyType.text(&"ui.campaign.record_only", "RECORD ONLY")},
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
	var stars := int(Game.campaign_projection().get("stage_stars", {}).get(stage.id, 0))
	var suffix := ""
	if not unlocked:
		suffix = UiCopyType.text(&"ui.campaign.locked_suffix", "  LOCKED")
	elif stars > 0:
		suffix = UiCopyType.format_text(&"ui.campaign.cleared_suffix", "  {stars}", {&"stars": "*".repeat(stars)})
	return UiCopyType.format_text(&"ui.campaign.row", "{index}. {title}{status}", {
		&"index": stage.campaign_index,
		&"title": UiCopyType.stage_title(stage),
		&"status": suffix,
	})


func _row_presentation_text(stage: StageDef, unlocked: bool, is_next: bool) -> String:
	var stars := int(Game.campaign_projection().get("stage_stars", {}).get(stage.id, 0))
	var state := "LOCKED" if not unlocked else ("CLEARED" if stars > 0 else ("NEXT" if is_next else "AVAILABLE"))
	return "%02d  %s  ·  %s" % [stage.campaign_index, UiCopyType.stage_title(stage).to_upper(), state]


func _wire_focus(enabled_rows: Array[Button], back: Button) -> void:
	var focusable := enabled_rows.duplicate()
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


func _on_stage_pressed(stage_id: StringName) -> void:
	Sfx.play("ui_click")
	Game.selected_stage_id = stage_id
	Game.open_squad_select()


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
