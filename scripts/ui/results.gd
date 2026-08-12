extends Control

## Results screen: headline + stars + tallies from Game.last_result, one
## "Unlocked:" line per granted reward (the reveal). The prototype has one
## player flow: Retry -> squad select, Return to Staging for either outcome,
## and Back to Title resets the campaign session.
## The battle's stamp edge owns victory/defeat SFX — this screen only
## clicks (L3).

const FONT_SIZE := 32
const HEADLINE_FONT_SIZE := 64
const KIND_DIRS := {
	&"operator": "res://data/operators",
	&"trap": "res://data/traps",
	&"spell": "res://data/spells",
}


func _ready() -> void:
	Game.content = self
	var result: Dictionary = Game.last_result
	var cleared := int(result.get("result", 0)) == BattleModel.Result.CLEAR
	var column := VBoxContainer.new()
	column.name = "ResultsColumn"
	column.set_anchors_preset(Control.PRESET_CENTER)
	column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	column.grow_vertical = Control.GROW_DIRECTION_BOTH
	column.add_theme_constant_override("separation", 14)
	add_child(column)
	column.add_child(_label("Headline", "CLEAR" if cleared else "DEFEAT", HEADLINE_FONT_SIZE))
	if cleared:
		column.add_child(_label("StarLine", "*".repeat(int(result.get("stars", 0))), HEADLINE_FONT_SIZE))
	column.add_child(_label(
		"TallyLine",
		"kills %d   leaks %d" % [int(result.get("kills", 0)), int(result.get("leaks", 0))],
		FONT_SIZE,
	))
	var granted: Array = result.get("rewards_granted", [])
	for i: int in granted.size():
		var reward: Dictionary = granted[i]
		var def: Resource = load("%s/%s.tres" % [KIND_DIRS[reward["kind"]], reward["id"]])
		column.add_child(_label(
			"Reward%d" % i, "Unlocked: %s" % def.get("display_name"), FONT_SIZE,
		))
	var actions := HBoxContainer.new()
	actions.name = "ActionRow"
	actions.add_theme_constant_override("separation", 16)
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(actions)
	var retry := Button.new()
	retry.name = "RetryButton"
	retry.text = "Retry"
	retry.add_theme_font_size_override("font_size", FONT_SIZE)
	retry.pressed.connect(_on_retry)
	actions.add_child(retry)
	var next := Button.new()
	next.name = "ReturnToStaging"
	next.text = "Return to Staging"
	next.add_theme_font_size_override("font_size", FONT_SIZE)
	next.pressed.connect(_on_return_to_staging)
	actions.add_child(next)
	var title := Button.new()
	title.name = "BackToTitle"
	title.text = "Back to Title"
	title.add_theme_font_size_override("font_size", FONT_SIZE)
	title.pressed.connect(_on_back_to_title)
	actions.add_child(title)


func _on_return_to_staging() -> void:
	Sfx.play("ui_click")
	Game.open_staging()


func _on_retry() -> void:
	Sfx.play("ui_click")
	Game.open_squad_select()


func _on_back_to_title() -> void:
	Sfx.play("ui_click")
	Game.open_title()


func _label(label_name: String, text: String, size_px: int) -> Label:
	var label := Label.new()
	label.name = label_name
	label.text = text
	label.add_theme_font_size_override("font_size", size_px)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label
