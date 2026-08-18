class_name MemorialScreen
extends Control

const SHELL_SCENE := preload("res://scenes/ui/components/aetheria_screen_shell.tscn")
const AetheriaButtonType := preload("res://scripts/ui/components/aetheria_button.gd")
const AetheriaLabelType := preload("res://scripts/ui/components/aetheria_label.gd")
const AetheriaPanelType := preload("res://scripts/ui/components/aetheria_panel.gd")
const AetheriaScreenShellType := preload("res://scripts/ui/components/aetheria_screen_shell.gd")
const MemorialSupportType := preload("res://scripts/ui/components/memorial_support.gd")
const TrainingScreenType := preload("res://scripts/ui/training.gd")
const UiCopyType := preload("res://scripts/ui/components/ui_copy.gd")

const SHELL_SIZE := Vector2(1160.0, 640.0)
const COMPACT_SHELL_SIZE := Vector2(880.0, 640.0)
const PORTRAIT_SHELL_SIZE := Vector2(640.0, 1120.0)
const TERMINAL_REASON_KEYS := {
	"base_defeat": &"ui.memorial.terminal.base_defeat",
	"clear": &"ui.memorial.terminal.clear",
	"leak_defeat": &"ui.memorial.terminal.leak_defeat",
	"resign": &"ui.memorial.terminal.resign",
}

var _shell: AetheriaScreenShellType
var _page: VBoxContainer
var _dialog_scroll: ScrollContainer
var _layout_mode: StringName = &"regular_landscape"
var _cards: Array[BoxContainer] = []
var _portraits: Array[TextureRect] = []
var _footer: BoxContainer


func _ready() -> void:
	var rows := MemorialSupportType.rows(Game.campaign)
	if rows.is_empty():
		Game.open_staging()
		return
	Game.content = self
	_build_shell(rows)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back()


func _build_shell(rows: Array[Dictionary]) -> void:
	_shell = SHELL_SCENE.instantiate() as AetheriaScreenShellType
	_shell.name = "MemorialScreenShell"
	_shell.preferred_size = SHELL_SIZE
	add_child(_shell)
	_shell.layout_mode_changed.connect(_on_layout_mode_changed)
	(_shell.reading_plate() as PanelContainer).name = "MemorialShell"
	_dialog_scroll = ScrollContainer.new()
	_dialog_scroll.name = "MemorialDialogScroll"
	var content_gutter := _shell.add_dialog_scroll(_dialog_scroll)
	_page = VBoxContainer.new()
	_page.name = "MemorialPage"
	_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_page.add_theme_constant_override(&"separation", 12)
	content_gutter.add_child(_page)
	_page.add_child(_header())
	for row: Dictionary in rows:
		_page.add_child(_memorial_card(row))
	_footer = BoxContainer.new()
	_footer.name = "MemorialActions"
	_footer.alignment = BoxContainer.ALIGNMENT_END
	_footer.add_theme_constant_override(&"separation", 16)
	var back := _button(
		"MemorialBack",
		UiCopyType.text(&"ui.memorial.back", "Back to Staging"),
	)
	back.pressed.connect(_on_back)
	_footer.add_child(back)
	_page.add_child(_footer)
	_dialog_scroll.focus_mode = Control.FOCUS_ALL
	_dialog_scroll.focus_next = _dialog_scroll.get_path_to(back)
	_dialog_scroll.focus_previous = _dialog_scroll.get_path_to(back)
	back.focus_next = back.get_path_to(_dialog_scroll)
	back.focus_previous = back.get_path_to(_dialog_scroll)
	back.focus_entered.connect(_on_back_focused.bind(back))
	_layout_mode = _shell.layout_mode()
	_apply_layout()
	_dialog_scroll.grab_focus.call_deferred()


func _header() -> VBoxContainer:
	var header := VBoxContainer.new()
	header.name = "MemorialHeader"
	header.add_theme_constant_override(&"separation", 2)
	(
		header
		. add_child(
			_label(
				"MemorialTitle",
				UiCopyType.text(&"ui.memorial.title", "MEMORIAL"),
				&"dense_heading",
			)
		)
	)
	(
		header
		. add_child(
			_label(
				"MemorialMotto",
				(
					UiCopyType
					. text(
						&"ui.memorial.motto",
						"Company 33 protects the living. We remember the dead.",
					)
				),
				&"dense_body",
			)
		)
	)
	(
		header
		. add_child(
			_label(
				"MemorialDoctrine",
				(
					UiCopyType
					. text(
						&"ui.memorial.doctrine",
						"Their records remain here. They do not return to service.",
					)
				),
				&"dense_detail",
			)
		)
	)
	return header


func _memorial_card(row: Dictionary) -> AetheriaPanelType:
	var panel := AetheriaPanelType.new()
	panel.name = "Memorial_%s" % row["hero_id"]
	panel.apply_role(&"inspector")
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var body := BoxContainer.new()
	body.name = "MemorialCardBody_%s" % row["hero_id"]
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override(&"separation", 18)
	panel.add_child(body)
	_cards.append(body)
	var portrait := TextureRect.new()
	portrait.name = "Portrait_%s" % row["hero_id"]
	portrait.custom_minimum_size = Vector2(144.0, 144.0)
	portrait.texture = Art.texture(StringName(row["portrait_asset_id"]))
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.tooltip_text = (
		UiCopyType
		. format_text(
			&"ui.memorial.portrait_alt",
			"Identity portrait for {callsign}",
			{&"callsign": String(row["callsign"])},
		)
	)
	body.add_child(portrait)
	_portraits.append(portrait)
	var details := VBoxContainer.new()
	details.name = "Record_%s" % row["hero_id"]
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override(&"separation", 4)
	body.add_child(details)
	(
		details
		. add_child(
			_label(
				"Person_%s" % row["hero_id"],
				String(row["callsign"]),
				&"dense_heading",
			)
		)
	)
	(
		details
		. add_child(
			_label(
				"Service_%s" % row["hero_id"],
				(
					UiCopyType
					. format_text(
						&"ui.memorial.service",
						"Company 33 service record {number}",
						{&"number": int(row["service_number"])},
					)
				),
				&"dense_detail",
			)
		)
	)
	(
		details
		. add_child(
			_label(
				"Class_%s" % row["hero_id"],
				(
					UiCopyType
					. format_text(
						&"ui.memorial.class_at_death",
						"Class at death: {class_name}",
						{&"class_name": TrainingScreenType.class_label(String(row["class_id"]))},
					)
				),
				&"dense_body",
			)
		)
	)
	(
		details
		. add_child(
			_label(
				"Deeds_%s" % row["hero_id"],
				_deeds_text(row),
				&"dense_detail",
			)
		)
	)
	(
		details
		. add_child(
			_label(
				"DeathContext_%s" % row["hero_id"],
				_death_text(row),
				&"dense_detail",
			)
		)
	)
	return panel


func _deeds_text(row: Dictionary) -> String:
	var deeds := row["deeds"] as Dictionary
	return (
		UiCopyType
		. format_text(
			&"ui.memorial.deeds",
			(
				"Operations {operations} • deployments {deployments} • "
				+ "clears {clears} • retreats {retreats} • XP {xp}"
			),
			{
				&"operations": int(deeds["operations_deployed"]),
				&"deployments": int(deeds["deployments"]),
				&"clears": int(deeds["successful_operations"]),
				&"retreats": int(deeds["retreats"]),
				&"xp": int(row["xp"]),
			},
		)
	)


func _death_text(row: Dictionary) -> String:
	var death := row["death"] as Dictionary
	var stage_id := String(death.get("stage_id", ""))
	var terminal_reason := String(death.get("terminal_reason", ""))
	var stage_path := "res://data/stages/%s.tres" % stage_id
	if not ResourceLoader.exists(stage_path) or not TERMINAL_REASON_KEYS.has(terminal_reason):
		return _record_unavailable()
	var stage := load(stage_path) as StageDef
	if stage == null:
		return _record_unavailable()
	var stage_title := UiCopyType.stage_title(stage)
	var reason := _terminal_reason(terminal_reason)
	return (
		UiCopyType
		. format_text(
			&"ui.memorial.death_context",
			"Fell during {stage} • {reason} • tick {tick} • attempt {attempt}",
			{
				&"stage": stage_title,
				&"reason": reason,
				&"tick": int(death.get("terminal_tick", 0)),
				&"attempt": int(death.get("attempt_id", 0)),
			},
		)
	)


func _terminal_reason(value: String) -> String:
	if not TERMINAL_REASON_KEYS.has(value):
		return _record_unavailable()
	return UiCopyType.text(TERMINAL_REASON_KEYS[value], _record_unavailable())


func _record_unavailable() -> String:
	return UiCopyType.text(
		&"ui.memorial.record_unavailable",
		"Memorial record unavailable",
	)


func _on_layout_mode_changed(value: StringName) -> void:
	_layout_mode = value
	_apply_layout()


func _apply_layout() -> void:
	if _shell == null:
		return
	_shell.preferred_size = (
		PORTRAIT_SHELL_SIZE
		if _layout_mode == &"portrait"
		else COMPACT_SHELL_SIZE if _layout_mode == &"compact_landscape" else SHELL_SIZE
	)
	for card: BoxContainer in _cards:
		card.vertical = _layout_mode == &"portrait"
	for portrait: TextureRect in _portraits:
		portrait.custom_minimum_size = (
			Vector2(192.0, 192.0) if _layout_mode == &"portrait" else Vector2(144.0, 144.0)
		)
	if _footer != null:
		_footer.vertical = _layout_mode == &"portrait"


func _on_back() -> void:
	Sfx.play("ui_click")
	Game.open_staging()


func _on_back_focused(back: Control) -> void:
	_dialog_scroll.ensure_control_visible(back)


func _label(
	node_name: String,
	label_text: String,
	role: StringName,
) -> AetheriaLabelType:
	var label := AetheriaLabelType.new()
	label.name = node_name
	label.text = label_text
	label.apply_role(role)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


func _button(node_name: String, button_text: String) -> AetheriaButtonType:
	var button := AetheriaButtonType.new()
	button.name = node_name
	button.text = button_text
	button.custom_minimum_size = Vector2(400.0, 64.0)
	button.apply_role(&"secondary")
	button.set_presentation_text(button_text, button_text)
	return button
