extends Control

## Protos entry screen. The campaign is the only player-facing game flow;
## direct battle startup remains a harness/debug seam, never a title action.

const SHELL_SCENE := preload("res://scenes/ui/components/aetheria_screen_shell.tscn")
const LOCALE_SCENE := preload("res://scenes/ui/components/aetheria_locale_selector.tscn")

var _locale_selector: AetheriaLocaleSelector = null


func _ready() -> void:
	var shell := SHELL_SCENE.instantiate() as AetheriaScreenShell
	shell.name = "TitleShell"
	shell.preferred_size = Vector2(720.0, 520.0)
	add_child(shell)
	shell.layout_mode_changed.connect(_on_layout_mode_changed)

	var vbox := VBoxContainer.new()
	vbox.name = "TitleBox"
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override(&"separation", 24)
	shell.content_host().add_child(vbox)

	var label := AetheriaLabel.new()
	label.name = "TitleLabel"
	label.apply_role(&"title")
	label.text = UiCopy.text(&"ui.game_title", "Protos")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)

	var start := AetheriaButton.new()
	start.name = "StartButton"
	start.apply_role(&"primary")
	start.text = UiCopy.text(&"ui.title.start", "Start")
	start.pressed.connect(_on_start_pressed)
	vbox.add_child(start)

	var footer := AetheriaLabel.new()
	footer.name = "FooterLabel"
	footer.apply_role(&"detail")
	footer.text = UiCopy.format_text(
		&"ui.title.seed", "seed {seed}", {&"seed": Game.run_seed},
	)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(footer)

	_locale_selector = LOCALE_SCENE.instantiate() as AetheriaLocaleSelector
	_locale_selector.name = "LocaleSelector"
	_locale_selector.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(_locale_selector)
	var locale_list := _locale_selector.get_node("LocaleList") as ItemList
	start.focus_neighbor_top = start.get_path_to(locale_list)
	start.focus_previous = start.get_path_to(locale_list)
	start.focus_neighbor_bottom = start.get_path_to(locale_list)
	start.focus_next = start.get_path_to(locale_list)
	locale_list.focus_neighbor_top = locale_list.get_path_to(start)
	locale_list.focus_previous = locale_list.get_path_to(start)
	locale_list.focus_neighbor_bottom = locale_list.get_path_to(start)
	locale_list.focus_next = locale_list.get_path_to(start)
	start.grab_focus.call_deferred()
	_on_layout_mode_changed(shell.layout_mode())

	Game.content = self


func _on_start_pressed() -> void:
	Sfx.play("ui_click")
	Game.start_campaign()


func _on_layout_mode_changed(mode: StringName) -> void:
	if _locale_selector != null:
		_locale_selector.set_vertical_layout(mode == &"portrait")
