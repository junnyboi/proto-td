extends Control

## Title screen (main scene until the stage-select map lands in Phase 10).
## UI is built in code — programmatic-everything keeps .tscn files trivial.

const FONT_SIZE_TITLE := 64
const FONT_SIZE_BUTTON := 32
const FONT_SIZE_FOOTER := 24


func _ready() -> void:
	var vbox := VBoxContainer.new()
	vbox.name = "TitleBox"
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vbox.grow_vertical = Control.GROW_DIRECTION_BOTH
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 24)
	add_child(vbox)

	var label := Label.new()
	label.name = "TitleLabel"
	label.text = "Prototype TD"
	label.add_theme_font_size_override("font_size", FONT_SIZE_TITLE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)

	var button := Button.new()
	button.name = "StartButton"
	button.text = "Start"
	button.add_theme_font_size_override("font_size", FONT_SIZE_BUTTON)
	button.pressed.connect(_on_start_pressed)
	vbox.add_child(button)

	var footer := Label.new()
	footer.name = "FooterLabel"
	footer.text = "seed %d" % Game.run_seed
	footer.add_theme_font_size_override("font_size", FONT_SIZE_FOOTER)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(footer)

	Game.content = self


func _on_start_pressed() -> void:
	Game.start_battle(Game.default_stage_id)
