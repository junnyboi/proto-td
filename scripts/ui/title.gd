extends Control

## Protos entry screen. The campaign is the only player-facing game flow;
## direct battle startup remains a harness/debug seam, never a title action.

const SHELL_SCENE := preload("res://scenes/ui/components/aetheria_screen_shell.tscn")
const LOCALE_SCENE := preload("res://scenes/ui/components/aetheria_locale_selector.tscn")
const AetheriaButtonType := preload("res://scripts/ui/components/aetheria_button.gd")
const AetheriaLabelType := preload("res://scripts/ui/components/aetheria_label.gd")
const AetheriaLocaleSelectorType := preload(
	"res://scripts/ui/components/aetheria_locale_selector.gd"
)
const AetheriaScreenShellType := preload(
	"res://scripts/ui/components/aetheria_screen_shell.gd"
)
const UiCopyType := preload("res://scripts/ui/components/ui_copy.gd")

var _locale_selector: AetheriaLocaleSelectorType = null
var _title_label: AetheriaLabelType = null
var _start_button: AetheriaButtonType = null
var _footer_label: AetheriaLabelType = null


func _ready() -> void:
	var shell := SHELL_SCENE.instantiate() as AetheriaScreenShellType
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

	_title_label = AetheriaLabelType.new()
	_title_label.name = "TitleLabel"
	_title_label.apply_role(&"title")
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_title_label)

	_start_button = AetheriaButtonType.new()
	_start_button.name = "StartButton"
	_start_button.apply_role(&"primary")
	_start_button.pressed.connect(_on_start_pressed)
	vbox.add_child(_start_button)

	_footer_label = AetheriaLabelType.new()
	_footer_label.name = "FooterLabel"
	_footer_label.apply_role(&"detail")
	_footer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_footer_label)

	_locale_selector = LOCALE_SCENE.instantiate() as AetheriaLocaleSelectorType
	_locale_selector.name = "LocaleSelector"
	_locale_selector.alignment = BoxContainer.ALIGNMENT_CENTER
	_locale_selector.locale_selected.connect(_on_locale_selected)
	vbox.add_child(_locale_selector)
	var locale_list := _locale_selector.get_node("LocaleList") as ItemList
	_start_button.focus_neighbor_top = _start_button.get_path_to(locale_list)
	_start_button.focus_previous = _start_button.get_path_to(locale_list)
	_start_button.focus_neighbor_bottom = _start_button.get_path_to(locale_list)
	_start_button.focus_next = _start_button.get_path_to(locale_list)
	locale_list.focus_neighbor_top = locale_list.get_path_to(_start_button)
	locale_list.focus_previous = locale_list.get_path_to(_start_button)
	locale_list.focus_neighbor_bottom = locale_list.get_path_to(_start_button)
	locale_list.focus_next = locale_list.get_path_to(_start_button)
	_start_button.grab_focus.call_deferred()
	_refresh_copy()
	_on_layout_mode_changed(shell.layout_mode())

	Game.content = self


func _on_start_pressed() -> void:
	Sfx.play("ui_click")
	Game.start_campaign()


func _on_locale_selected(_locale_id: StringName) -> void:
	_refresh_copy()


func _refresh_copy() -> void:
	_title_label.text = UiCopyType.text(&"ui.game_title", "Protos")
	_start_button.text = UiCopyType.text(&"ui.title.start", "Start")
	_footer_label.text = UiCopyType.format_text(
		&"ui.title.seed", "seed {seed}", {&"seed": Game.run_seed},
	)


func _on_layout_mode_changed(mode: StringName) -> void:
	if _locale_selector != null:
		_locale_selector.set_vertical_layout(mode == &"portrait")
