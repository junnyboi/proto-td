extends Control

## Campaign stage select. Locked rows remain disabled controls; stage stars,
## sequential unlocks, selection, and routing remain projections of Game.

const SHELL_SCENE := preload("res://scenes/ui/components/aetheria_screen_shell.tscn")
const AetheriaButtonType := preload("res://scripts/ui/components/aetheria_button.gd")
const AetheriaLabelType := preload("res://scripts/ui/components/aetheria_label.gd")
const AetheriaScreenShellType := preload("res://scripts/ui/components/aetheria_screen_shell.gd")
const GameTypographyType := preload("res://scripts/ui/game_typography.gd")
const ActionHoverFeedbackType := preload("res://scripts/ui/components/action_hover_feedback.gd")
const FactionHeraldryType := preload("res://scripts/ui/components/faction_heraldry.gd")
const UiCopyType := preload("res://scripts/ui/components/ui_copy.gd")
const ResonanceStarType := preload("res://scripts/ui/components/resonance_star.gd")
const ResonanceCurrencyDisplayType := preload("res://scripts/ui/components/resonance_currency_display.gd")
const StagingSkinType := preload("res://scripts/ui/components/staging_skin.gd")
const Style := preload("res://scripts/ui/components/lunaris_ops_style.gd")
const NARRATIVE_CATALOG := preload("res://data/presentation/narrative/stage_narrative_catalog.tres")
const StageNarrativeDefType := preload("res://data/presentation/narrative/stage_narrative_def.gd")
const StageNarrativeCatalogType := preload("res://data/presentation/narrative/stage_narrative_catalog.gd")
const CampaignNextSparklesType := preload("res://scripts/ui/components/campaign_next_sparkles.gd")
const CampaignReadyShimmerType := preload("res://scripts/ui/components/campaign_ready_shimmer.gd")
const MissionCinematicPlayerType := preload("res://scripts/ui/components/mission_cinematic_player.gd")
const ROUTE_PANEL_ANNOTATED_WIDTH := 832.0
const ROUTE_PANEL_STANDARD_WIDTH := 480.0
const ROUTE_PANEL_COMPACT_WIDTH := 360.0
const ROUTE_PANEL_ANNOTATED_MIN_VIEWPORT_WIDTH := 1600.0
const ROUTE_CONTENT_INSET := 36
const DOSSIER_HORIZONTAL_INSET := 80
const DOSSIER_VERTICAL_INSET := 36
const STAGE_ROW_PADDING := 24.0
const STAGE_ROW_MIN_HEIGHT := 104.0
const STAGE_ROW_STAR_SIZE := 24.0
const STAGE_ROW_STAR_SEPARATION := 2
const READY_STATUS_GOLD := Color("8c6a1f")
const READY_STATUS_EDGE := Color("f0d89a")
const START_MISSION_TEXT_COLOR := Color("fff8e7")
const START_MISSION_TEXT_OUTLINE := Color("09070d")
const START_MISSION_TEXT_SIZE := 22
const ROUTE_HOVER_BACKGROUND := Color("2f7f9188")
const ROUTE_FOCUS_BACKGROUND := Color("22455355")
const ROUTE_HOVER_SCALE := Vector2(1.025, 1.025)
const ROUTE_FOCUS_SCALE := Vector2(1.01, 1.01)
const ROUTE_HOVER_SECONDS := 0.16
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
var _dossier_status_shimmer: CampaignReadyShimmerType = null
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
var _start_mission: AetheriaButtonType = null
var _enabled_rows: Array[Button] = []
var _cinematic_overlay: MissionCinematicPlayerType = null
var _cinematic_stage_id: StringName = &""
var _cinematic_gate_locked := false
var _cinematic_route_committed := false


func _ready() -> void:
	Game.content = self
	_shell = SHELL_SCENE.instantiate() as AetheriaScreenShellType
	_shell.name = "CampaignShell"
	_shell.full_safe_area = true
	add_child(_shell)
	_shell.layout_mode_changed.connect(_on_layout_mode_changed)
	resized.connect(_on_viewport_size_changed)

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


func _exit_tree() -> void:
	_cinematic_route_committed = true
	_cinematic_gate_locked = false
	if (
		_cinematic_overlay != null
		and is_instance_valid(_cinematic_overlay)
		and _cinematic_overlay.terminal.is_connected(_on_mission_cinematic_terminal)
	):
		_cinematic_overlay.terminal.disconnect(_on_mission_cinematic_terminal)


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
	route_panel.custom_minimum_size.x = _route_panel_width(_shell.layout_mode())
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
	_route_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	route_header.add_child(_route_heading)
	_route_note = AetheriaLabelType.new()
	_route_note.name = "RouteNote"
	_route_note.apply_role(&"detail")
	_route_note.text = UiCopyType.text(
		&"ui.campaign.route_note",
		"Select an available operation, or replay a cleared one.",
	)
	_route_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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
	var dossier_inset := MarginContainer.new()
	dossier_inset.name = "MissionDossierInset"
	dossier_inset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side: StringName in [&"margin_left", &"margin_right"]:
		dossier_inset.add_theme_constant_override(side, DOSSIER_HORIZONTAL_INSET)
	for side: StringName in [&"margin_top", &"margin_bottom"]:
		dossier_inset.add_theme_constant_override(side, DOSSIER_VERTICAL_INSET)
	dossier_scroll.add_child(dossier_inset)
	var dossier_stack := VBoxContainer.new()
	dossier_stack.name = "DossierContent"
	dossier_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dossier_stack.add_theme_constant_override(&"separation", 8)
	dossier_inset.add_child(dossier_stack)
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
	_dossier_status_shimmer = CampaignReadyShimmerType.new()
	_dossier_status_shimmer.name = "DossierReadyShimmer"
	_dossier_status_shimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dossier_status.add_child(_dossier_status_shimmer)
	_dossier_status_shimmer.set_active(false)
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
	ResonanceCurrencyDisplayType.apply_tooltip(_dossier_reward_icon, "", &"marks")
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
	_start_mission = AetheriaButtonType.new()
	_start_mission.name = "StartMission"
	_start_mission.custom_minimum_size = Vector2(280.0, 68.0)
	_start_mission.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_start_mission.set_presentation_text(
		UiCopyType.text(&"ui.campaign.start_mission", "Start Mission"),
		UiCopyType.text(&"ui.campaign.start_mission", "Start Mission").to_upper(),
	)
	Style.apply_button(_start_mission, &"gold")
	_apply_start_mission_ornate_style()
	ActionHoverFeedbackType.wire(self, _start_mission)
	_start_mission.pressed.connect(_on_start_mission_pressed)
	dossier_stack.add_child(_start_mission)
	dossier_stack.move_child(_start_mission, _dossier_status.get_index() + 1)

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
		row.custom_minimum_size = Vector2(44.0, STAGE_ROW_MIN_HEIGHT)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.disabled = not unlocked
		var is_next := unlocked and not stage_stars.has(stage_id) and _next_stage_id == stage_id
		row.apply_role(&"selected" if is_next else (&"secondary" if unlocked else &"disabled"))
		_apply_route_row_presentation(row, stage, unlocked, is_next)
		row.apply_compact_action_layout()
		var presentation := row.get_node("PresentationLabel") as Label
		presentation.offset_left = STAGE_ROW_PADDING
		presentation.offset_top = STAGE_ROW_PADDING
		presentation.offset_right = -STAGE_ROW_PADDING
		presentation.offset_bottom = -STAGE_ROW_PADDING
		presentation.clip_text = false
		presentation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		presentation.add_theme_font_size_override(&"font_size", GameTypographyType.STATUS)
		if not unlocked:
			var locked_gray := Color(Style.MUTED, 0.64)
			presentation.add_theme_color_override(&"font_color", locked_gray)
			presentation.add_theme_color_override(&"font_disabled_color", locked_gray)
		if is_next:
			var sparkles := CampaignNextSparklesType.new()
			sparkles.name = "NextOperationSparkles"
			row.add_child(sparkles)
			sparkles.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.custom_minimum_size.y = maxf(row.custom_minimum_size.y, STAGE_ROW_MIN_HEIGHT)
		row.tooltip_text = row.text
		row.accessibility_name = row.text
		if is_next:
			row.accessibility_description = UiCopyType.text(
				&"ui.campaign.next_highlight_description",
				"Recommended next operation, highlighted with a glow and sparkles.",
			)
		if not unlocked:
			row.focus_mode = Control.FOCUS_NONE
		else:
			enabled_rows.append(row)
			_wire_route_card_feedback(row)
			row.focus_entered.connect(_show_dossier.bind(stage_id))
			row.mouse_entered.connect(_show_dossier.bind(stage_id))
			row.pressed.connect(_on_route_stage_selected.bind(stage_id))
		_rows.add_child(row)

	_enabled_rows = enabled_rows
	_refresh_focus_chain(true)
	var dossier_id := _next_stage_id
	if dossier_id.is_empty() and not Game.campaign_stage_ids().is_empty():
		dossier_id = Game.campaign_stage_ids()[-1]
	_show_dossier(dossier_id)


func _show_dossier(stage_id: StringName) -> void:
	if not _stage_by_id.has(stage_id):
		return
	ResonanceCurrencyDisplayType.apply_tooltip(_dossier_reward_icon, "", &"marks")
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
	_apply_dossier_status_presentation(unlocked and stars == 0)
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
	_update_start_mission_state()
	for child: Node in _dossier_stars.get_children():
		child.queue_free()
	for index: int in 3:
		var star := ResonanceStarType.new()
		star.name = "DossierStar_%d" % (index + 1)
		star.set_state(Style.GOLD, index < stars)
		_dossier_stars.add_child(star)


func _apply_dossier_status_presentation(ready: bool) -> void:
	if _dossier_status == null:
		return
	if not ready:
		_dossier_status.remove_theme_stylebox_override(&"normal")
		_dossier_status.remove_theme_color_override(&"font_color")
		if _dossier_status_shimmer != null:
			_dossier_status_shimmer.set_active(false)
		return
	var ready_style := StyleBoxFlat.new()
	ready_style.bg_color = READY_STATUS_GOLD
	ready_style.border_color = READY_STATUS_EDGE
	ready_style.set_border_width_all(1)
	ready_style.set_corner_radius_all(2)
	ready_style.content_margin_left = 9.0
	ready_style.content_margin_top = 5.0
	ready_style.content_margin_right = 9.0
	ready_style.content_margin_bottom = 5.0
	_dossier_status.add_theme_stylebox_override(&"normal", ready_style)
	_dossier_status.add_theme_color_override(&"font_color", Color.WHITE)
	if _dossier_status_shimmer != null:
		_dossier_status_shimmer.set_active(true)


func _unhandled_input(event: InputEvent) -> void:
	if _cinematic_gate_locked:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back_to_staging()


func _row_text(stage: StageDef, unlocked: bool) -> String:
	var is_next := unlocked and int(Game.campaign_projection().get("stage_stars", {}).get(stage.id, 0)) == 0 and _next_stage_id == stage.id
	return _row_presentation_text(stage, unlocked, is_next)


func _row_presentation_text(stage: StageDef, unlocked: bool, is_next: bool) -> String:
	var stars := int(Game.campaign_projection().get("stage_stars", {}).get(stage.id, 0))
	var state := UiCopyType.text(&"ui.campaign.row_locked", "Locked")
	if stars > 0:
		state = UiCopyType.format_text(
			&"ui.campaign.row_star" if stars == 1 else &"ui.campaign.row_stars",
			"{count} star" if stars == 1 else "{count} stars",
			{&"count": stars},
		)
	elif unlocked:
		state = UiCopyType.text(
			&"ui.campaign.row_next" if is_next else &"ui.campaign.row_available",
			"Next" if is_next else "Available",
		)
	return "%s  %02d  %s  ·  %s" % [
		_act_short(stage), stage.campaign_index, UiCopyType.stage_title(stage), state,
	]


func _row_identity_text(stage: StageDef) -> String:
	return "%s  %02d  %s" % [
		_act_short(stage), stage.campaign_index, UiCopyType.stage_title(stage),
	]


func _apply_route_row_presentation(
	row: AetheriaButtonType,
	stage: StageDef,
	unlocked: bool,
	is_next: bool,
) -> void:
	if row == null or stage == null:
		return
	var stars := int(Game.campaign_projection().get("stage_stars", {}).get(stage.id, 0))
	var logical_text := _row_presentation_text(stage, unlocked, is_next)
	var identity_text := _row_identity_text(stage)
	row.set_presentation_text(
		logical_text,
		identity_text if stars > 0 else logical_text,
	)
	row.tooltip_text = logical_text
	row.accessibility_name = logical_text
	var presentation := row.get_node_or_null("PresentationLabel") as Label
	var content := row.get_node_or_null("StageRowContent") as HBoxContainer
	if stars <= 0:
		if presentation != null:
			presentation.visible = true
		if content != null:
			row.remove_child(content)
			content.queue_free()
		return
	if presentation != null:
		presentation.visible = false
	if content == null:
		content = HBoxContainer.new()
		content.name = "StageRowContent"
		content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		content.offset_left = STAGE_ROW_PADDING
		content.offset_top = STAGE_ROW_PADDING
		content.offset_right = -STAGE_ROW_PADDING
		content.offset_bottom = -STAGE_ROW_PADDING
		content.alignment = BoxContainer.ALIGNMENT_CENTER
		content.add_theme_constant_override(&"separation", 8)
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(content)
		var identity := AetheriaLabelType.new()
		identity.name = "StageRowIdentity"
		identity.apply_role(&"body")
		identity.autowrap_mode = TextServer.AUTOWRAP_OFF
		identity.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		identity.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		identity.add_theme_font_size_override(&"font_size", GameTypographyType.STATUS)
		content.add_child(identity)
		var star_row := HBoxContainer.new()
		star_row.name = "StageRowStars"
		star_row.alignment = BoxContainer.ALIGNMENT_CENTER
		star_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		star_row.add_theme_constant_override(&"separation", STAGE_ROW_STAR_SEPARATION)
		star_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(star_row)
	var identity_label := content.get_node_or_null("StageRowIdentity") as Label
	if identity_label != null:
		identity_label.text = "%s  ·" % identity_text
	var star_row := content.get_node_or_null("StageRowStars") as HBoxContainer
	if star_row == null:
		return
	for child: Node in star_row.get_children():
		star_row.remove_child(child)
		child.queue_free()
	for index: int in stars:
		var star := ResonanceStarType.new()
		star.name = "StageRowStar_%d" % (index + 1)
		star.custom_minimum_size = Vector2.ONE * STAGE_ROW_STAR_SIZE
		star.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		star.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		star.set_state(Style.GOLD, true)
		star_row.add_child(star)


func _act_short(stage: StageDef) -> String:
	return UiCopyType.text(
		&"ui.campaign.act_2_short" if stage.campaign_index >= 9 else &"ui.campaign.act_1_short",
		"ACT II" if stage.campaign_index >= 9 else "ACT I",
	)


func _wire_focus(enabled_rows: Array[Button], back: Button, grab_initial := false) -> void:
	var focusable := enabled_rows.duplicate()
	if _start_mission != null and not _start_mission.disabled:
		focusable.append(_start_mission)
	focusable.append(back)
	for index: int in focusable.size():
		var current: Button = focusable[index]
		var previous: Button = focusable[(index - 1 + focusable.size()) % focusable.size()]
		var next: Button = focusable[(index + 1) % focusable.size()]
		current.focus_neighbor_top = current.get_path_to(previous)
		current.focus_previous = current.get_path_to(previous)
		current.focus_neighbor_bottom = current.get_path_to(next)
		current.focus_next = current.get_path_to(next)
	if grab_initial and not enabled_rows.is_empty():
		enabled_rows[0].grab_focus.call_deferred()
	elif grab_initial:
		back.grab_focus.call_deferred()


func _refresh_focus_chain(grab_initial := false) -> void:
	if _back != null:
		_wire_focus(_enabled_rows, _back, grab_initial)


func _on_stage_pressed(stage_id: StringName) -> void:
	if _cinematic_gate_locked or not Game.is_stage_unlocked(stage_id):
		return
	Sfx.play("ui_click")
	_cinematic_gate_locked = true
	_cinematic_route_committed = false
	_cinematic_stage_id = stage_id
	_set_route_input_enabled(false)
	_cinematic_overlay = MissionCinematicPlayerType.new()
	_cinematic_overlay.name = "MissionCinematicOverlay"
	_cinematic_overlay.terminal.connect(_on_mission_cinematic_terminal)
	add_child(_cinematic_overlay)
	move_child(_cinematic_overlay, get_child_count() - 1)
	_cinematic_overlay.present(stage_id)


func _on_route_stage_selected(stage_id: StringName) -> void:
	if _cinematic_gate_locked or not Game.is_stage_unlocked(stage_id):
		return
	_show_dossier(stage_id)
	if _start_mission != null and not _start_mission.disabled:
		_start_mission.grab_focus.call_deferred()


func _on_start_mission_pressed() -> void:
	if _dossier_stage_id.is_empty():
		return
	_on_stage_pressed(_dossier_stage_id)


func cinematic_gate_active() -> bool:
	return _cinematic_gate_locked


func _set_route_input_enabled(enabled: bool) -> void:
	for row: Button in _enabled_rows:
		row.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
		row.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	if _back != null:
		_back.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
		_back.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	_update_start_mission_state(enabled)


func _on_mission_cinematic_terminal(stage_id: StringName, reason: StringName) -> void:
	if not _cinematic_gate_locked or _cinematic_route_committed or stage_id != _cinematic_stage_id:
		return
	if reason == &"scene_exit":
		_cinematic_gate_locked = false
		_cinematic_overlay = null
		if is_inside_tree():
			_set_route_input_enabled(true)
		return
	_cinematic_route_committed = true
	_cinematic_gate_locked = false
	if _cinematic_overlay != null and is_instance_valid(_cinematic_overlay):
		_cinematic_overlay.queue_free()
	_cinematic_overlay = null
	Game.open_field_team_for_stage(stage_id)


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
				_route_panel_width(mode),
				420.0 if mode == &"portrait" else 0.0,
			)
		if dossier != null:
			dossier.custom_minimum_size = Vector2(0 if mode == &"portrait" else 420, 300 if mode == &"portrait" else 0)
	# A full-safe-area shell computes its available plate before this callback.
	# Refit once after descendant column minima settle so landscape widths cannot
	# survive a live rotation into portrait.
	if _shell != null:
		_shell.relayout.call_deferred(Vector2i(get_viewport_rect().size))


func _on_viewport_size_changed() -> void:
	if _shell == null or not is_instance_valid(_shell) or _body == null:
		return
	var route_panel := _body.get_node_or_null("CampaignRoutePanel") as Control
	if route_panel != null:
		route_panel.custom_minimum_size.x = _route_panel_width(_shell.layout_mode())


func _route_panel_width(mode: StringName) -> float:
	if mode == &"portrait":
		return 0.0
	if mode == &"compact_landscape":
		return ROUTE_PANEL_COMPACT_WIDTH
	if get_viewport_rect().size.x >= ROUTE_PANEL_ANNOTATED_MIN_VIEWPORT_WIDTH:
		return ROUTE_PANEL_ANNOTATED_WIDTH
	return ROUTE_PANEL_STANDARD_WIDTH


func _on_locale_changed(_locale_id: StringName) -> void:
	_refresh_header_copy()
	if _route_note != null:
		_route_note.text = UiCopyType.text(
			&"ui.campaign.route_note",
			"Select an available operation, or replay a cleared one.",
		)
	if _dossier_eyebrow != null:
		_dossier_eyebrow.text = UiCopyType.text(
			&"ui.campaign.selected_operation", "Selected Operation",
		)
	_refresh_start_mission_copy()
	for stage_id: StringName in _stage_by_id:
		var stage: StageDef = _stage_by_id[stage_id]
		var row := _rows.get_node_or_null("Stage_%s" % stage_id) as AetheriaButtonType
		if row == null:
			continue
		var unlocked := Game.is_stage_unlocked(stage_id)
		var is_next := unlocked and _next_stage_id == stage_id
		_apply_route_row_presentation(row, stage, unlocked, is_next)
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


func _refresh_start_mission_copy() -> void:
	if _start_mission == null:
		return
	var copy := UiCopyType.text(&"ui.campaign.start_mission", "Start Mission")
	_start_mission.set_presentation_text(copy, copy.to_upper())
	_start_mission.tooltip_text = copy
	_start_mission.accessibility_name = copy
	_start_mission.accessibility_description = copy


func _apply_start_mission_ornate_style() -> void:
	if _start_mission == null:
		return
	_start_mission.add_theme_stylebox_override(
		&"normal", StagingSkinType.ornate_primary_button_style(),
	)
	_start_mission.add_theme_stylebox_override(
		&"hover", StagingSkinType.ornate_primary_button_style(Color("fff8df")),
	)
	_start_mission.add_theme_stylebox_override(
		&"pressed", StagingSkinType.ornate_primary_button_style(Color("d9b96e")),
	)
	_start_mission.add_theme_stylebox_override(
		&"disabled",
		StagingSkinType.ornate_primary_button_style(Color(0.42, 0.48, 0.55, 0.56)),
	)
	var presentation := _start_mission.get_node_or_null("PresentationLabel") as Label
	if presentation == null:
		return
	StagingSkinType.apply_display_type(
		presentation, START_MISSION_TEXT_SIZE, START_MISSION_TEXT_COLOR, 650,
	)
	presentation.add_theme_color_override(&"font_color", START_MISSION_TEXT_COLOR)
	presentation.add_theme_color_override(&"font_outline_color", START_MISSION_TEXT_OUTLINE)
	presentation.add_theme_constant_override(&"outline_size", 5)
	presentation.add_theme_constant_override(&"shadow_offset_x", 0)
	presentation.add_theme_constant_override(&"shadow_offset_y", 2)
	presentation.add_theme_color_override(
		&"font_shadow_color", Color(0.0, 0.0, 0.0, 0.72),
	)


func _update_start_mission_state(route_input_enabled := true) -> void:
	if _start_mission == null:
		return
	var can_start := (
		route_input_enabled
		and not _cinematic_gate_locked
		and not _dossier_stage_id.is_empty()
		and Game.is_stage_unlocked(_dossier_stage_id)
	)
	_start_mission.disabled = not can_start
	_start_mission.focus_mode = Control.FOCUS_ALL if can_start else Control.FOCUS_NONE
	_start_mission.mouse_filter = Control.MOUSE_FILTER_STOP if can_start else Control.MOUSE_FILTER_IGNORE
	_refresh_start_mission_copy()
	_refresh_focus_chain()


func _wire_route_card_feedback(row: Button) -> void:
	var background := ColorRect.new()
	background.name = "RouteHoverBackground"
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.offset_left = 10.0
	background.offset_top = 7.0
	background.offset_right = -10.0
	background.offset_bottom = -7.0
	background.color = Color.TRANSPARENT
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(background)
	row.move_child(background, 0)
	row.set_meta(&"route_hovered", false)
	row.set_meta(&"route_focused", row.has_focus())
	row.resized.connect(_center_route_card_pivot.bind(row))
	row.mouse_entered.connect(_set_route_card_hovered.bind(row, background, true))
	row.mouse_exited.connect(_set_route_card_hovered.bind(row, background, false))
	row.focus_entered.connect(_set_route_card_focused.bind(row, background, true))
	row.focus_exited.connect(_set_route_card_focused.bind(row, background, false))
	_center_route_card_pivot.call_deferred(row)


func _center_route_card_pivot(row: Button) -> void:
	if row != null and is_instance_valid(row):
		row.pivot_offset = row.size * 0.5


func _set_route_card_hovered(row: Button, background: ColorRect, highlighted: bool) -> void:
	if row == null or not is_instance_valid(row):
		return
	row.set_meta(&"route_hovered", highlighted)
	_refresh_route_card_feedback(row, background)


func _set_route_card_focused(row: Button, background: ColorRect, highlighted: bool) -> void:
	if row == null or not is_instance_valid(row):
		return
	row.set_meta(&"route_focused", highlighted)
	_refresh_route_card_feedback(row, background)


func _refresh_route_card_feedback(row: Button, background: ColorRect) -> void:
	if row == null or background == null or not is_instance_valid(row) or not is_instance_valid(background):
		return
	var hovered := bool(row.get_meta(&"route_hovered", false))
	var focused := bool(row.get_meta(&"route_focused", false))
	var target_scale := ROUTE_HOVER_SCALE if hovered else (ROUTE_FOCUS_SCALE if focused else Vector2.ONE)
	var target_color := ROUTE_HOVER_BACKGROUND if hovered else (ROUTE_FOCUS_BACKGROUND if focused else Color.TRANSPARENT)
	if bool(ProjectSettings.get_setting("accessibility/reduced_motion", false)):
		target_scale = Vector2.ONE
	if row.has_meta(&"route_hover_tween"):
		var tween_value: Variant = row.get_meta(&"route_hover_tween")
		if tween_value is Tween and (tween_value as Tween).is_valid():
			(tween_value as Tween).kill()
		row.remove_meta(&"route_hover_tween")
	if not row.is_inside_tree() or bool(ProjectSettings.get_setting("accessibility/reduced_motion", false)):
		row.scale = target_scale
		background.color = target_color
		return
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(row, "scale", target_scale, ROUTE_HOVER_SECONDS)
	tween.tween_property(background, "color", target_color, ROUTE_HOVER_SECONDS)
	row.set_meta(&"route_hover_tween", tween)


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
