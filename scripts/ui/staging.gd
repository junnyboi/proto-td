extends Control

## P15 campaign home: a plain strategic shell over the existing session model.
## The view derives summaries and routes through Game; it never mutates campaign state.

const HEADING_SIZE := 48
const OPERATION_SIZE := 32
const DETAIL_SIZE := 24
const SHELL_SIZE := Vector2(1080.0, 620.0)
const BACKDROP_COLOR := Color("11131f")
const PANEL_COLOR := Color("1a1c2c")
const TEXT_COLOR := Color("f4f4f4")
const ACCENT_COLOR := Color("f4b41b")


func _ready() -> void:
	Game.content = self
	_build_screen()


func _build_screen() -> void:
	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.color = BACKDROP_COLOR
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)

	var center := CenterContainer.new()
	center.name = "StagingCenter"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var shell := PanelContainer.new()
	shell.name = "StagingShell"
	shell.custom_minimum_size = SHELL_SIZE
	shell.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(shell)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_bottom", 28)
	shell.add_child(margin)

	var column := VBoxContainer.new()
	column.name = "StagingColumn"
	column.add_theme_constant_override("separation", 18)
	margin.add_child(column)

	var heading := _label("StagingHeading", "STAGING AREA", HEADING_SIZE)
	heading.add_theme_color_override("font_color", ACCENT_COLOR)
	column.add_child(heading)

	column.add_child(_build_briefing())
	column.add_child(_build_operations())


func _build_briefing() -> HBoxContainer:
	var briefing := HBoxContainer.new()
	briefing.name = "BriefingRow"
	briefing.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	briefing.add_theme_constant_override("separation", 24)

	var campaign_summary := _label(
		"CampaignSummary", _campaign_summary_text(), DETAIL_SIZE,
	)
	campaign_summary.custom_minimum_size = Vector2(480.0, 92.0)
	campaign_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	campaign_summary.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	campaign_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	briefing.add_child(campaign_summary)

	var next_summary := _label(
		"NextMissionSummary", _next_mission_text(), DETAIL_SIZE,
	)
	next_summary.custom_minimum_size = Vector2(480.0, 92.0)
	next_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	next_summary.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	briefing.add_child(next_summary)
	return briefing


func _build_operations() -> VBoxContainer:
	var operations := VBoxContainer.new()
	operations.name = "OperationsColumn"
	operations.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	operations.size_flags_vertical = Control.SIZE_EXPAND_FILL
	operations.add_theme_constant_override("separation", 10)

	var status := _label(
		"OperationStatus", "FUTURE PERSONNEL OPERATIONS — UNAVAILABLE", DETAIL_SIZE,
	)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	operations.add_child(status)
	var grid := GridContainer.new()
	grid.name = "OperationGrid"
	grid.columns = 2
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 8)
	operations.add_child(grid)

	var mission := _button("MissionControlButton", "Mission Control", true)
	mission.pressed.connect(_on_mission_control)
	grid.add_child(mission)

	for spec: Array in [
		["BarracksButton", "Barracks — Unavailable"],
		["RecruitButton", "Recruit — Unavailable"],
		["TrainingButton", "Training — Unavailable"],
		["ArmoryButton", "Armory — Unavailable"],
		["MemorialButton", "Memorial — Unavailable"],
	]:
		grid.add_child(_button(String(spec[0]), String(spec[1]), false))

	var back := _button("BackToTitleButton", "Back to Title", true)
	back.pressed.connect(_on_back_to_title)
	operations.add_child(back)
	mission.focus_neighbor_bottom = mission.get_path_to(back)
	mission.focus_next = mission.get_path_to(back)
	back.focus_neighbor_top = back.get_path_to(mission)
	back.focus_previous = back.get_path_to(mission)
	mission.grab_focus.call_deferred()
	return operations


func _campaign_summary_text() -> String:
	var stage_ids: Array[StringName] = Game.campaign_stage_ids()
	var cleared := 0
	if Game.campaign != null:
		for stage_id: StringName in stage_ids:
			if Game.campaign.stage_stars.has(stage_id):
				cleared += 1
	return "CAMPAIGN SUMMARY\n%d/%d missions cleared" % [cleared, stage_ids.size()]


func _next_mission_text() -> String:
	if Game.campaign == null:
		return "NEXT MISSION\nNo active campaign"
	for stage_id: StringName in Game.campaign_stage_ids():
		if Game.is_stage_unlocked(stage_id) and not Game.campaign.stage_stars.has(stage_id):
			var stage := load("res://data/stages/%s.tres" % stage_id) as StageDef
			return "NEXT MISSION\n%d. %s\n%s" % [
				stage.campaign_index, stage.title, stage.intro_hint,
			]
	return "NEXT MISSION\nCampaign complete"


func _on_mission_control() -> void:
	Sfx.play("ui_click")
	Game.open_stage_select()


func _on_back_to_title() -> void:
	Sfx.play("ui_click")
	Game.open_title()


func _label(label_name: String, text: String, size_px: int) -> Label:
	var label := Label.new()
	label.name = label_name
	label.text = text
	label.add_theme_font_size_override("font_size", size_px)
	label.add_theme_color_override("font_color", TEXT_COLOR)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _button(button_name: String, text: String, enabled: bool) -> Button:
	var button := Button.new()
	button.name = button_name
	button.text = text
	button.custom_minimum_size = Vector2(0.0, 48.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", OPERATION_SIZE)
	button.disabled = not enabled
	if not enabled:
		button.focus_mode = Control.FOCUS_NONE
	return button


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.border_color = ACCENT_COLOR.darkened(0.35)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	return style
