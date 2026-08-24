extends Control

## Campaign stage select. Locked rows remain disabled controls; stars and routes
## remain projections of the existing campaign state.

const SHELL_SCENE := preload("res://scenes/ui/components/aetheria_screen_shell.tscn")
const AetheriaButtonType := preload("res://scripts/ui/components/aetheria_button.gd")
const AetheriaLabelType := preload("res://scripts/ui/components/aetheria_label.gd")
const AetheriaScreenShellType := preload(
	"res://scripts/ui/components/aetheria_screen_shell.gd"
)
const FactionHeraldryType := preload("res://scripts/ui/components/faction_heraldry.gd")
const UiCopyType := preload("res://scripts/ui/components/ui_copy.gd")

var _rows: GridContainer = null
var _header: GridContainer = null


func _ready() -> void:
	Game.content = self
	var shell := SHELL_SCENE.instantiate() as AetheriaScreenShellType
	shell.name = "CampaignShell"
	shell.preferred_size = Vector2(900.0, 620.0)
	add_child(shell)
	shell.layout_mode_changed.connect(_on_layout_mode_changed)

	var scroll := ScrollContainer.new()
	scroll.name = "CampaignScroll"
	var scroll_content := shell.add_dialog_scroll(scroll)

	var column := VBoxContainer.new()
	column.name = "StageColumn"
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override(&"separation", 8)
	scroll_content.add_child(column)

	_header = GridContainer.new()
	_header.name = "CampaignHeader"
	_header.columns = 3
	_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_header.add_theme_constant_override(&"h_separation", 16)
	_header.add_theme_constant_override(&"v_separation", 12)
	column.add_child(_header)
	var identity := HBoxContainer.new()
	identity.name = "CampaignIdentity"
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override(&"separation", 10)
	identity.add_child(FactionHeraldryType.make_symbol(
		FactionHeraldryType.ACTIVE_FACTION, 44.0,
	))
	var heading := AetheriaLabelType.new()
	heading.name = "CampaignHeading"
	heading.apply_role(&"heading")
	heading.text = UiCopyType.text(&"ui.campaign.heading", "Campaign")
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	identity.add_child(heading)
	_header.add_child(identity)
	var hint := AetheriaLabelType.new()
	hint.name = "NextHint"
	hint.apply_role(&"detail")
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_header.add_child(hint)

	_rows = GridContainer.new()
	_rows.name = "StageRows"
	_rows.columns = 2
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows.add_theme_constant_override(&"h_separation", 8)
	_rows.add_theme_constant_override(&"v_separation", 8)
	var rows_margin := MarginContainer.new()
	rows_margin.name = "StageRowsMargin"
	rows_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows_margin.add_theme_constant_override(
		&"margin_top", AetheriaButtonType.COMPACT_ACTION_ROW_TOP_PADDING,
	)
	rows_margin.add_child(_rows)
	column.add_child(rows_margin)

	var next_hint := ""
	var next_hint_tooltip := ""
	var stage_stars: Dictionary = Game.campaign_projection()["stage_stars"]
	var enabled_rows: Array[Button] = []
	for stage_id: StringName in Game.campaign_stage_ids():
		var stage := load("res://data/stages/%s.tres" % stage_id) as StageDef
		var unlocked: bool = Game.is_stage_unlocked(stage_id)
		var row := AetheriaButtonType.new()
		row.name = "Stage_%s" % stage_id
		row.text = _row_text(stage, unlocked)
		row.custom_minimum_size = Vector2(44.0, 52.0)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.disabled = not unlocked
		row.apply_role(&"primary" if unlocked else &"disabled")
		row.set_presentation_text(row.text, _row_presentation_text(stage))
		row.apply_compact_action_layout()
		row.tooltip_text = row.text
		if not unlocked:
			row.focus_mode = Control.FOCUS_NONE
		else:
			enabled_rows.append(row)
		row.pressed.connect(_on_stage_pressed.bind(stage_id))
		_rows.add_child(row)
		if unlocked and not stage_stars.has(stage_id):
			next_hint = UiCopyType.stage_title(stage)
			next_hint_tooltip = UiCopyType.stage_hint(stage)

	if next_hint.is_empty():
		next_hint = UiCopyType.text(&"ui.staging.next_complete", "Campaign complete")
	hint.text = next_hint
	hint.tooltip_text = next_hint_tooltip

	var back := AetheriaButtonType.new()
	back.name = "BackToStaging"
	back.custom_minimum_size = Vector2(220.0, 81.0)
	back.apply_role(&"secondary")
	back.text = UiCopyType.text(&"ui.campaign.back_to_staging", "Back to Staging")
	back.set_presentation_text(back.text, UiCopyType.text(&"ui.common.back", "Back"))
	back.apply_compact_action_layout()
	back.tooltip_text = back.text
	back.pressed.connect(_on_back_to_staging)
	_header.add_child(back)
	_wire_focus(enabled_rows, back)
	_on_layout_mode_changed(shell.layout_mode())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back_to_staging()


func _row_text(stage: StageDef, unlocked: bool) -> String:
	var stars := int(Game.campaign_projection()["stage_stars"].get(stage.id, 0))
	var suffix := ""
	if not unlocked:
		suffix = UiCopyType.text(&"ui.campaign.locked_suffix", "  LOCKED")
	elif stars > 0:
		suffix = UiCopyType.format_text(
			&"ui.campaign.cleared_suffix", "  {stars}",
			{&"stars": "*".repeat(stars)},
		)
	return UiCopyType.format_text(
		&"ui.campaign.row", "{index}. {title}{status}",
		{
			&"index": stage.campaign_index,
			&"title": UiCopyType.stage_title(stage),
			&"status": suffix,
		},
	)


func _row_presentation_text(stage: StageDef) -> String:
	var stars := int(Game.campaign_projection()["stage_stars"].get(stage.id, 0))
	var suffix := ""
	if stars > 0:
		suffix = " " + "*".repeat(stars)
	var title := UiCopyType.stage_title(stage)
	if title.begins_with("The "):
		title = title.trim_prefix("The ")
	return "%d. %s%s" % [stage.campaign_index, title, suffix]


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
	if not focusable.is_empty():
		focusable[0].grab_focus.call_deferred()


func _on_stage_pressed(stage_id: StringName) -> void:
	Sfx.play("ui_click")
	Game.selected_stage_id = stage_id
	Game.open_squad_select()


func _on_layout_mode_changed(mode: StringName) -> void:
	if _header != null:
		_header.columns = 1 if mode == &"portrait" else 3
	if _rows != null:
		_rows.columns = 1 if mode == &"portrait" else 2


func _on_back_to_staging() -> void:
	Sfx.play("ui_click")
	Game.open_staging()
