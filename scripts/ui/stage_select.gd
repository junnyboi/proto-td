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
const ResonanceCurrencyDisplayType := preload("res://scripts/ui/components/resonance_currency_display.gd")
const Style := preload("res://scripts/ui/components/lunaris_ops_style.gd")
const NARRATIVE_CATALOG := preload("res://data/presentation/narrative/stage_narrative_catalog.tres")
const StageNarrativeDefType := preload("res://data/presentation/narrative/stage_narrative_def.gd")
const StageNarrativeCatalogType := preload("res://data/presentation/narrative/stage_narrative_catalog.gd")
const ROUTE_PANEL_WIDE_WIDTH := 480.0
const ROUTE_CONTENT_INSET := 24
const STAGE_ROW_VERTICAL_PADDING := 12.0
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
var _dossier_reward_icon: TextureRect = null
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
var _enabled_rows: Array[Button] = []


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
	route_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	route_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	route_panel.custom_minimum_size.x = ROUTE_PANEL_WIDE_WIDTH
	Style.apply_panel(route_panel, &"quiet")
	_body.add_child(route_panel)
	var route_content_inset := MarginContainer.new()
	route_content_inset.name = "RouteContentInset"
	for side: StringName in [&"margin_left", &"margin_top", &"margin_right", &"margin_bottom"]:
		route_content_inset.add_theme_constant_override(side, ROUTE_CONTENT_INSET)
	route_content_inset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	route_content_inset.size_flags_vertical = Control.SIZE_EXPAND_FILL
	route_panel.add_child(route_content_inset)
	var route_stack := VBoxContainer.new()
	route_stack.name = "RouteContent"
	route_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	route_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	route_stack.add_theme_constant_override(&"separation", 10)
	route_content_inset.add_child(route_stack)
	var route_header := VBoxContainer.new()
	route_header.name = "RouteHeader"
	route_header.add_theme_constant_override(&"separation", 10)
	route_stack.add_child(route_header)
	_route_heading = AetheriaLabelType.new()
	_route_heading.name = "RouteHeading"
	_route_heading.apply_role(&"heading")
	route_header.add_child(_route_heading)
	_route_note = AetheriaLabelType.new()
	_route_note.name = "RouteNote"
	_route_note.apply_role(&"detail")
	_route_note.text = UiCopyType.text(
		&"ui.campaign.route_note",
		"Select an available operation. Cleared operations remain replayable.",
	)
	route_header.add_child(_route_note)
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
	var reward_row := HBoxContainer.new()
	reward_row.name = "DossierRewardRow"
	reward_row.add_theme_constant_override(&"separation", 8)
	_dossier_reward_icon = TextureRect.new()
	_dossier_reward_icon.name = "DossierResonanceShard"
	_dossier_reward_icon.texture = ResonanceCurrencyDisplayType.ICON_TEXTURE
	_dossier_reward_icon.custom_minimum_size = Vector2(30, 30)
	_dossier_reward_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_dossier_reward_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_dossier_reward_icon.mouse_filter = Control.MOUSE_FILTER_STOP
	ResonanceCurrencyDisplayType.apply_tooltip(_dossier_reward_icon)
	reward_row.add_child(_dossier_reward_icon)
	_dossier_reward = AetheriaLabelType.new()
	_dossier_reward.name = "DossierReward"
	_dossier_reward.apply_role(&"dense_heading")
	_dossier_reward.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dossier_reward.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward_row.add_child(_dossier_reward)
	dossier_stack.add_child(reward_row)
	dossier_stack.move_child(reward_row, _dossier_facts.get_index())
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
		var presentation := row.get_node("PresentationLabel") as Label
		presentation.offset_left = 16.0
		presentation.offset_top = STAGE_ROW_VERTICAL_PADDING
		presentation.offset_right = -16.0
		presentation.offset_bottom = -STAGE_ROW_VERTICAL_PADDING
		presentation.clip_text = false
		presentation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.custom_minimum_size.y = maxf(row.custom_minimum_size.y, 76.0)
		row.tooltip_text = row.text
		if not unlocked:
			row.focus_mode = Control.FOCUS_NONE
		else:
			enabled_rows.append(row)
			row.focus_entered.connect(_show_dossier.bind(stage_id))
			row.mouse_entered.connect(_show_dossier.bind(stage_id))
		row.pressed.connect(_on_stage_pressed.bind(stage_id))
		_rows.add_child(row)

	_enabled_rows = enabled_rows
	_refresh_focus_chain()
	var dossier_id := _next_stage_id
	if dossier_id.is_empty() and not Game.campaign_stage_ids().is_empty():
		dossier_id = Game.campaign_stage_ids()[-1]
	_show_dossier(dossier_id)


func _show_dossier(stage_id: StringName) -> void:
	if not _stage_by_id.has(stage_id):
		return
	ResonanceCurrencyDisplayType.apply_tooltip(_dossier_reward_icon)
	var stage: StageDef = _stage_by_id[stage_id]
	_dossier_stage_id = stage_id
	var stars := int(Game.campaign_projection().get("stage_stars", {}).get(stage_id, 0))
	var unlocked := Game.is_stage_unlocked(stage_id)
	var localized_title := UiCopyType.stage_title(stage)
	_dossier_title.text = "%s · %02d · %s" % [
		_act_short(stage), stage.campaign_index, localized_title,
	]
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
	var has_shard_reward := false
	for reward: Dictionary in stage.rewards:
		has_shard_reward = has_shard_reward or (
			reward.get("kind") == "currency" and reward.get("id") == "marks"
		)
		reward_names.append(_reward_name(reward))
	_dossier_reward_icon.visible = has_shard_reward
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
	return "%s  %02d  %s  ·  %s" % [
		_act_short(stage), stage.campaign_index, UiCopyType.stage_title(stage), state,
	]


func _act_short(stage: StageDef) -> String:
	return UiCopyType.text(
		&"ui.campaign.act_2_short" if stage.campaign_index >= 9 else &"ui.campaign.act_1_short",
		"ACT II" if stage.campaign_index >= 9 else "ACT I",
	)


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


func _refresh_focus_chain() -> void:
	if _back != null:
		_wire_focus(_enabled_rows, _back)


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
			route_panel.size_flags_horizontal = (
				Control.SIZE_EXPAND_FILL if mode == &"portrait" else Control.SIZE_SHRINK_BEGIN
			)
			route_panel.custom_minimum_size = Vector2(
				0.0 if mode == &"portrait" else ROUTE_PANEL_WIDE_WIDTH,
				420.0 if mode == &"portrait" else 0.0,
			)
		if dossier != null:
			dossier.custom_minimum_size = Vector2(0 if mode == &"portrait" else 420, 300 if mode == &"portrait" else 0)
	# A full-safe-area shell computes its available plate before this callback.
	# Refit once after descendant column minima settle so landscape widths cannot
	# survive a live rotation into portrait.
	if _shell != null:
		_shell.relayout.call_deferred(Vector2i(get_viewport_rect().size))


func _on_locale_changed(_locale_id: StringName) -> void:
	_refresh_header_copy()
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
	if kind == &"currency" and identifier == &"marks":
		return str(int(reward.get("amount", 0)))
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
