extends Control

## Proto Defense entry screen. The campaign is the only player-facing game flow;
## direct battle startup remains a harness/debug seam, never a title action.

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
	label.text = I18n.t(&"ui.game_title", "Proto Defense")
	label.add_theme_font_size_override("font_size", FONT_SIZE_TITLE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)

	var start := Button.new()
	start.name = "StartButton"
	start.text = "Start"
	start.add_theme_font_size_override("font_size", FONT_SIZE_BUTTON)
	start.pressed.connect(_on_start_pressed)
	vbox.add_child(start)

	var footer := Label.new()
	footer.name = "FooterLabel"
	footer.text = "seed %d" % Game.run_seed
	footer.add_theme_font_size_override("font_size", FONT_SIZE_FOOTER)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(footer)

	Game.content = self


func _on_start_pressed() -> void:
	Sfx.play("ui_click")
	Game.start_campaign()
