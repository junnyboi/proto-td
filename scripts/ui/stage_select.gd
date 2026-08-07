extends Control

## Campaign stage select (Phase 10, td-phase-10.md §2.6): a vertical list of
## the eight campaign stages — honest floor, not a map. Locked rows are
## disabled Buttons (dimmed by the theme, click = no-op); cleared rows show
## their best stars as asterisks. Buttons named Stage_<id> for click_view.
## Rects + labels at the 2x font floor; art is Lane A's.

const FONT_SIZE := 32
const TITLE_FONT_SIZE := 48
const HINT_FONT_SIZE := 24


func _ready() -> void:
	Game.content = self
	var column := VBoxContainer.new()
	column.name = "StageColumn"
	column.set_anchors_preset(Control.PRESET_CENTER)
	column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	column.grow_vertical = Control.GROW_DIRECTION_BOTH
	column.add_theme_constant_override("separation", 10)
	add_child(column)
	var heading := Label.new()
	heading.name = "CampaignHeading"
	heading.text = "Campaign"
	heading.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(heading)
	var next_hint := ""
	for stage_id: StringName in Game.campaign_stage_ids():
		var stage := load("res://data/stages/%s.tres" % stage_id) as StageDef
		var unlocked: bool = Game.is_stage_unlocked(stage_id)
		var row := Button.new()
		row.name = "Stage_%s" % stage_id
		row.text = _row_text(stage, unlocked)
		row.disabled = not unlocked
		row.add_theme_font_size_override("font_size", FONT_SIZE)
		row.pressed.connect(_on_stage_pressed.bind(stage_id))
		column.add_child(row)
		if unlocked and not Game.campaign.stage_stars.has(stage_id):
			next_hint = stage.intro_hint
	if not next_hint.is_empty():
		var hint := Label.new()
		hint.name = "NextHint"
		hint.text = next_hint
		hint.add_theme_font_size_override("font_size", HINT_FONT_SIZE)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(hint)


func _row_text(stage: StageDef, unlocked: bool) -> String:
	var stars := int(Game.campaign.stage_stars.get(stage.id, 0))
	var suffix := ""
	if not unlocked:
		suffix = "  LOCKED"
	elif stars > 0:
		suffix = "  " + "*".repeat(stars)
	return "%d. %s%s" % [stage.campaign_index, stage.title, suffix]


func _on_stage_pressed(stage_id: StringName) -> void:
	Sfx.play("ui_click")
	Game.selected_stage_id = stage_id
	Game.open_squad_select()
