extends Control

## Campaign home. Narrative is a presentation-only projection;
## Game remains authoritative.
const SHELL_SCENE := preload("res://scenes/ui/components/aetheria_screen_shell.tscn")
const NARRATIVE_CATALOG := preload("res://data/presentation/narrative/stage_narrative_catalog.tres")
const StageNarrativeDefType := preload("res://data/presentation/narrative/stage_narrative_def.gd")
const StageNarrativeCatalogType := preload(
	"res://data/presentation/narrative/stage_narrative_catalog.gd"
)
const AetheriaButtonType := preload("res://scripts/ui/components/aetheria_button.gd")
const AetheriaLabelType := preload("res://scripts/ui/components/aetheria_label.gd")
const AetheriaScreenShellType := preload("res://scripts/ui/components/aetheria_screen_shell.gd")
const UiCopyType := preload("res://scripts/ui/components/ui_copy.gd")
const TrainingScreenType := preload("res://scripts/ui/training.gd")
const SHELL_SIZE := Vector2(1080.0, 620.0)

var _briefing: GridContainer = null
var _operation_grid: GridContainer = null
var _mission: AetheriaButtonType = null
var _training: AetheriaButtonType = null
var _next_record: StageNarrativeDefType = null
var _next_stage: StageDef = null
var _narrative_missing := false


func _ready() -> void:
	Game.content = self
	_resolve_next_operation()
	_build_screen()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back_to_title()


func _resolve_next_operation() -> void:
	if Game.campaign == null:
		return
	var stars := _stage_stars()
	for stage_id: StringName in Game.campaign_stage_ids():
		if Game.is_stage_unlocked(stage_id) and not stars.has(stage_id):
			_next_stage = load("res://data/stages/%s.tres" % stage_id) as StageDef
			_next_record = (NARRATIVE_CATALOG as StageNarrativeCatalogType).get_record(stage_id)
			_narrative_missing = _next_record == null
			return


func _build_screen() -> void:
	var shell := SHELL_SCENE.instantiate() as AetheriaScreenShellType
	shell.name = "StagingScreenShell"
	shell.preferred_size = SHELL_SIZE
	add_child(shell)
	shell.layout_mode_changed.connect(_on_layout_mode_changed)
	(
		shell.get_node("SafeMargin/Center/ReadingFrame/ReadingPlate") as PanelContainer
	).name = "StagingShell"
	var scroll := ScrollContainer.new()
	scroll.name = "StagingScroll"
	var scroll_content := shell.add_dialog_scroll(scroll)
	var column := VBoxContainer.new()
	column.name = "StagingColumn"
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override(&"separation", 10)
	scroll_content.add_child(column)
	column.add_child(_build_briefing())
	column.add_child(_build_operations())
	_on_layout_mode_changed(shell.layout_mode())


func _build_briefing() -> GridContainer:
	_briefing = GridContainer.new()
	_briefing.name = "BriefingRow"
	_briefing.columns = 2
	_briefing.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_briefing.add_theme_constant_override(&"h_separation", 24)
	_briefing.add_theme_constant_override(&"v_separation", 8)
	var heading := _label(
		"CompanyCommandHeading",
		UiCopyType.text(&"ui.staging.command_heading", "COMPANY 33 COMMAND"),
		&"dense_heading",
	)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_briefing.add_child(heading)
	var summary := _label("CampaignSummary", _campaign_summary_text(), &"dense_body")
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_briefing.add_child(summary)
	var body := _label(
		"CompanyCommandBody",
		UiCopyType.text(
			&"ui.staging.command_body",
			"Commander, the Great Flare was a massive solar flare that corrupted "
			+ "connected systems two centuries ago and caused the Fall. Custodians "
			+ "are still forcing Hearthcross through that unfinished evacuation.",
		),
		&"dense_detail",
	)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.custom_minimum_size.y = 84.0
	_briefing.add_child(body)
	var next_box := VBoxContainer.new()
	next_box.name = "NextOperationCard"
	next_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := _label("NextOperationTitle", _next_operation_title(), &"dense_body")
	var objective := _label("NextOperationObjective", _next_operation_objective(), &"dense_detail")
	next_box.add_child(title)
	next_box.add_child(objective)
	_briefing.add_child(next_box)
	return _briefing


func _build_operations() -> VBoxContainer:
	var operations := VBoxContainer.new()
	operations.name = "OperationsColumn"
	operations.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	operations.add_theme_constant_override(&"separation", 10)
	operations.add_child(_label(
		"OperationStatus",
		UiCopyType.text(&"ui.staging.operation_status", "OPERATIONS — UNAVAILABLE"),
		&"dense_detail",
	))
	_mission = _button(
		"MissionControlButton",
		UiCopyType.text(&"ui.staging.mission_control", "Mission Control"),
		UiCopyType.text(&"ui.staging.mission_control_short", "Mission"),
		not _narrative_missing,
		&"primary" if not _narrative_missing else &"disabled",
	)
	_mission.pressed.connect(_on_mission_control)
	_operation_grid = GridContainer.new()
	_operation_grid.name = "OperationGrid"
	_operation_grid.columns = 4
	_operation_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_operation_grid.add_theme_constant_override(&"h_separation", 14)
	_operation_grid.add_theme_constant_override(&"v_separation", 10)
	var grid_margin := MarginContainer.new()
	grid_margin.name = "OperationGridMargin"
	grid_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_margin.add_theme_constant_override(
		&"margin_top", AetheriaButtonType.COMPACT_ACTION_ROW_TOP_PADDING,
	)
	grid_margin.add_child(_operation_grid)
	operations.add_child(grid_margin)
	_operation_grid.add_child(_mission)
	var back := _button(
		"BackToTitleButton",
		UiCopyType.text(&"ui.common.back_to_title", "Back to Title"),
		UiCopyType.text(&"ui.common.back", "Back"), true, &"secondary",
	)
	back.pressed.connect(_on_back_to_title)
	_operation_grid.add_child(back)
	var training_available := _training_available()
	for specification: Array in [
		[
			"BarracksButton", &"ui.staging.barracks_unavailable", "Barracks — Unavailable",
			&"ui.staging.barracks_short", "Barracks",
		],
		[
			"RecruitButton", &"ui.staging.recruit_unavailable", "Recruit — Unavailable",
			&"ui.staging.recruit_short", "Recruit",
		],
		[
			"ArmoryButton", &"ui.staging.armory_unavailable", "Armory — Unavailable",
			&"ui.staging.armory_short", "Armory",
		],
		[
			"MemorialButton", &"ui.staging.memorial_unavailable", "Memorial — Unavailable",
			&"ui.staging.memorial_short", "Memorial",
		],
	]:
		_operation_grid.add_child(_button(
			String(specification[0]), UiCopyType.text(
				StringName(specification[1]), String(specification[2]),
			), UiCopyType.text(
				StringName(specification[3]), String(specification[4]),
			), false, &"disabled",
		))
	_training = _button(
		"TrainingButton",
		UiCopyType.text(
			&"ui.staging.training" if training_available else &"ui.staging.training_unavailable",
			"Training" if training_available else "Training — Unavailable",
		),
		UiCopyType.text(&"ui.staging.training_short", "Training"),
		training_available,
		&"primary" if training_available else &"disabled",
	)
	_training.pressed.connect(_on_training)
	_operation_grid.add_child(_training)
	var focus_actions: Array[Control] = [_mission]
	if training_available:
		focus_actions.append(_training)
	focus_actions.append(back)
	for index: int in focus_actions.size():
		var current := focus_actions[index]
		var previous := focus_actions[
			(index - 1 + focus_actions.size()) % focus_actions.size()
		]
		var following := focus_actions[(index + 1) % focus_actions.size()]
		current.focus_previous = current.get_path_to(previous)
		current.focus_next = current.get_path_to(following)
		current.focus_neighbor_top = current.get_path_to(previous)
		current.focus_neighbor_left = current.get_path_to(previous)
		current.focus_neighbor_bottom = current.get_path_to(following)
		current.focus_neighbor_right = current.get_path_to(following)
	(back if _mission.disabled else _mission).grab_focus.call_deferred()
	return operations


func _campaign_summary_text() -> String:
	var stage_ids: Array[StringName] = Game.campaign_stage_ids()
	var cleared := 0
	if Game.campaign != null:
		var stars := _stage_stars()
		for stage_id: StringName in stage_ids:
			if stars.has(stage_id):
				cleared += 1
	return UiCopyType.format_text(
		&"ui.staging.campaign_summary", "{cleared}/{total} CLEARED",
		{&"cleared": cleared, &"total": stage_ids.size()},
	)


func _next_operation_title() -> String:
	if Game.campaign == null:
		return UiCopyType.text(&"ui.staging.next_none", "NEXT: No active campaign")
	if _next_stage == null:
		return UiCopyType.text(&"ui.staging.next_complete", "NEXT: Campaign complete")
	return UiCopyType.format_text(
		&"ui.staging.next_operation_title", "NEXT {index}: {title}",
		{
			&"index": _next_stage.campaign_index,
			&"title": UiCopyType.stage_title(_next_stage),
		},
	)


func _next_operation_objective() -> String:
	if _narrative_missing:
		return UiCopyType.text(
			&"ui.error.missing_stage_narrative",
			"Mission record unavailable. Return to Mission Control.",
		)
	if _next_record == null:
		return ""
	return UiCopyType.stage_narrative_text(_next_record, StageNarrativeDefType.Field.OBJECTIVE)


func _on_mission_control() -> void:
	if _narrative_missing:
		return
	Sfx.play("ui_click")
	Game.open_stage_select()


func _on_training() -> void:
	if not _training_available():
		return
	Sfx.play("ui_click")
	Game.open_training()


func _on_back_to_title() -> void:
	Sfx.play("ui_click")
	Game.open_title()


func _training_available() -> bool:
	return TrainingScreenType.supports_campaign(Game.campaign)


func _stage_stars() -> Dictionary:
	if Game.campaign == null:
		return {}
	if Game.campaign.has_method("compatibility_projection"):
		return Game.campaign.compatibility_projection()["stage_stars"]
	return Game.campaign.stage_stars


func _on_layout_mode_changed(mode: StringName) -> void:
	if _briefing != null:
		_briefing.columns = 1 if mode == &"portrait" else 2
	if _operation_grid != null:
		_operation_grid.columns = 2 if mode == &"portrait" else 4


func _label(label_name: String, label_text: String, role: StringName) -> AetheriaLabelType:
	var label := AetheriaLabelType.new()
	label.name = label_name
	label.text = label_text
	label.apply_role(role)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	return label


func _button(
	button_name: String,
	button_text: String,
	presentation_text: String,
	enabled: bool,
	role: StringName,
) -> AetheriaButtonType:
	var button := AetheriaButtonType.new()
	button.name = button_name
	button.text = button_text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.disabled = not enabled
	button.apply_role(role)
	button.set_presentation_text(button_text, presentation_text)
	button.tooltip_text = button_text
	button.apply_compact_action_layout()
	if not enabled:
		button.focus_mode = Control.FOCUS_NONE
	return button
