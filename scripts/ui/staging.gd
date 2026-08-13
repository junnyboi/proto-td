extends Control

## Campaign home. This view derives summaries and routes through Game; it never
## mutates campaign state.

const SHELL_SCENE := preload("res://scenes/ui/components/aetheria_screen_shell.tscn")
const SHELL_SIZE := Vector2(1080.0, 620.0)
const AetheriaButtonType := preload("res://scripts/ui/components/aetheria_button.gd")
const AetheriaLabelType := preload("res://scripts/ui/components/aetheria_label.gd")
const AetheriaScreenShellType := preload(
	"res://scripts/ui/components/aetheria_screen_shell.gd"
)
const UiCopyType := preload("res://scripts/ui/components/ui_copy.gd")

var _briefing: GridContainer = null
var _operation_grid: GridContainer = null


func _ready() -> void:
	Game.content = self
	_build_screen()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back_to_title()


func _build_screen() -> void:
	var shell := SHELL_SCENE.instantiate() as AetheriaScreenShellType
	shell.name = "StagingScreenShell"
	shell.preferred_size = SHELL_SIZE
	add_child(shell)
	shell.layout_mode_changed.connect(_on_layout_mode_changed)
	(shell.get_node("SafeMargin/Center/ReadingPlate") as PanelContainer).name = "StagingShell"

	var scroll := ScrollContainer.new()
	scroll.name = "StagingScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	shell.content_host().add_child(scroll)

	var column := VBoxContainer.new()
	column.name = "StagingColumn"
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override(&"separation", 10)
	scroll.add_child(column)
	column.add_child(_build_briefing())
	column.add_child(_build_operations())
	_on_layout_mode_changed(shell.layout_mode())


func _build_briefing() -> GridContainer:
	_briefing = GridContainer.new()
	_briefing.name = "BriefingRow"
	_briefing.columns = 3
	_briefing.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_briefing.add_theme_constant_override(&"h_separation", 24)
	_briefing.add_theme_constant_override(&"v_separation", 18)

	var heading := _label(
		"StagingHeading", UiCopyType.text(&"ui.staging.heading", "STAGING"), &"heading",
	)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_briefing.add_child(heading)

	var campaign_summary := _label(
		"CampaignSummary", _campaign_summary_text(), &"body",
	)
	campaign_summary.custom_minimum_size = Vector2(0.0, 92.0)
	campaign_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	campaign_summary.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_briefing.add_child(campaign_summary)

	var next_summary := _label("NextMissionSummary", _next_mission_text(), &"body")
	next_summary.custom_minimum_size = Vector2(0.0, 126.0)
	next_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next_summary.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_briefing.add_child(next_summary)
	return _briefing


func _build_operations() -> VBoxContainer:
	var operations := VBoxContainer.new()
	operations.name = "OperationsColumn"
	operations.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	operations.add_theme_constant_override(&"separation", 10)

	var status := _label(
		"OperationStatus",
		UiCopyType.text(
			&"ui.staging.operation_status", "OPERATIONS — UNAVAILABLE",
		),
		&"detail",
	)
	operations.add_child(status)

	var mission := _button(
		"MissionControlButton",
		UiCopyType.text(&"ui.staging.mission_control", "Mission Control"),
		"Mission\nControl", true, &"primary",
	)
	mission.pressed.connect(_on_mission_control)

	_operation_grid = GridContainer.new()
	_operation_grid.name = "OperationGrid"
	_operation_grid.columns = 4
	_operation_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_operation_grid.add_theme_constant_override(&"h_separation", 14)
	_operation_grid.add_theme_constant_override(&"v_separation", 10)
	operations.add_child(_operation_grid)
	_operation_grid.add_child(mission)
	var back := _button(
		"BackToTitleButton",
		UiCopyType.text(&"ui.common.back_to_title", "Back to Title"),
		"Back to\nTitle", true, &"secondary",
	)
	back.pressed.connect(_on_back_to_title)
	_operation_grid.add_child(back)

	for specification: Array in [
		[
			"BarracksButton", &"ui.staging.barracks_unavailable",
			"Barracks — Unavailable", "Barracks\nUnavailable",
		],
		[
			"RecruitButton", &"ui.staging.recruit_unavailable",
			"Recruit — Unavailable", "Recruit\nUnavailable",
		],
		[
			"TrainingButton", &"ui.staging.training_unavailable",
			"Training — Unavailable", "Training\nUnavailable",
		],
		[
			"ArmoryButton", &"ui.staging.armory_unavailable",
			"Armory — Unavailable", "Armory\nUnavailable",
		],
		[
			"MemorialButton", &"ui.staging.memorial_unavailable",
			"Memorial — Unavailable", "Memorial\nUnavailable",
		],
	]:
		_operation_grid.add_child(_button(
			String(specification[0]),
			UiCopyType.text(StringName(specification[1]), String(specification[2])),
			String(specification[3]), false, &"disabled",
		))

	mission.focus_neighbor_top = mission.get_path_to(back)
	mission.focus_previous = mission.get_path_to(back)
	mission.focus_neighbor_bottom = mission.get_path_to(back)
	mission.focus_next = mission.get_path_to(back)
	back.focus_neighbor_top = back.get_path_to(mission)
	back.focus_previous = back.get_path_to(mission)
	back.focus_neighbor_bottom = back.get_path_to(mission)
	back.focus_next = back.get_path_to(mission)
	mission.grab_focus.call_deferred()
	return operations


func _campaign_summary_text() -> String:
	var stage_ids: Array[StringName] = Game.campaign_stage_ids()
	var cleared := 0
	if Game.campaign != null:
		for stage_id: StringName in stage_ids:
			if Game.campaign.stage_stars.has(stage_id):
				cleared += 1
	return UiCopyType.format_text(
		&"ui.staging.campaign_summary",
		"{cleared}/{total} CLEARED",
		{&"cleared": cleared, &"total": stage_ids.size()},
	)


func _next_mission_text() -> String:
	if Game.campaign == null:
		return UiCopyType.text(
			&"ui.staging.next_none", "NEXT: No active campaign",
		)
	for stage_id: StringName in Game.campaign_stage_ids():
		if Game.is_stage_unlocked(stage_id) and not Game.campaign.stage_stars.has(stage_id):
			var stage := load("res://data/stages/%s.tres" % stage_id) as StageDef
			return UiCopyType.format_text(
				&"ui.staging.next_detail", "NEXT: {index}. {title}",
				{
					&"index": stage.campaign_index,
					&"title": UiCopyType.stage_title(stage),
				},
			)
	return UiCopyType.text(
		&"ui.staging.next_complete", "NEXT: Campaign complete",
	)


func _on_mission_control() -> void:
	Sfx.play("ui_click")
	Game.open_stage_select()


func _on_back_to_title() -> void:
	Sfx.play("ui_click")
	Game.open_title()


func _on_layout_mode_changed(mode: StringName) -> void:
	if _briefing != null:
		_briefing.columns = 1 if mode == &"portrait" else 3
	if _operation_grid != null:
		_operation_grid.columns = 2 if mode == &"portrait" else 4


func _label(label_name: String, label_text: String, role: StringName) -> AetheriaLabelType:
	var label := AetheriaLabelType.new()
	label.name = label_name
	label.text = label_text
	label.apply_role(role)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _button(
		button_name: String, button_text: String, presentation_text: String,
		enabled: bool, role: StringName,
	) -> AetheriaButtonType:
	var button := AetheriaButtonType.new()
	button.name = button_name
	button.text = button_text
	button.custom_minimum_size = Vector2(44.0, 120.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.disabled = not enabled
	button.apply_role(role)
	button.set_presentation_text(button_text, presentation_text)
	if not enabled:
		button.focus_mode = Control.FOCUS_NONE
	return button
