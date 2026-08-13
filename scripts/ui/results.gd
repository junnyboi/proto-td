extends Control

## Results projection over Game.last_result. Outcome and route semantics remain
## unchanged; this package only upgrades presentation and localization.

const SHELL_SCENE := preload("res://scenes/ui/components/aetheria_screen_shell.tscn")
const KIND_DIRS := {
	&"operator": "res://data/operators",
	&"trap": "res://data/traps",
	&"spell": "res://data/spells",
}
const LANDSCAPE_SIZE := Vector2(900.0, 600.0)
const PORTRAIT_SIZE := Vector2(640.0, 900.0)
const AetheriaButtonType := preload("res://scripts/ui/components/aetheria_button.gd")
const AetheriaLabelType := preload("res://scripts/ui/components/aetheria_label.gd")
const AetheriaScreenShellType := preload(
	"res://scripts/ui/components/aetheria_screen_shell.gd"
)
const UiCopyType := preload("res://scripts/ui/components/ui_copy.gd")
const NARRATIVE_CATALOG := preload("res://data/presentation/narrative/stage_narrative_catalog.tres")
const StageNarrativeDefType := preload("res://data/presentation/narrative/stage_narrative_def.gd")
const StageNarrativeCatalogType := preload("res://data/presentation/narrative/stage_narrative_catalog.gd")

var _actions: GridContainer = null
var _shell: AetheriaScreenShellType = null


func _ready() -> void:
	Game.content = self
	var result: Dictionary = Game.last_result
	var cleared := int(result.get("result", 0)) == BattleModel.Result.CLEAR
	_shell = SHELL_SCENE.instantiate() as AetheriaScreenShellType
	_shell.name = "ResultsShell"
	_shell.preferred_size = LANDSCAPE_SIZE
	add_child(_shell)
	_shell.layout_mode_changed.connect(_on_layout_mode_changed)

	var scroll := ScrollContainer.new()
	scroll.name = "ResultsScroll"
	var scroll_content := _shell.add_dialog_scroll(scroll)

	var column := VBoxContainer.new()
	column.name = "ResultsColumn"
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override(&"separation", 14)
	scroll_content.add_child(column)
	column.add_child(_label(
		"Headline",
		UiCopyType.text(
			&"ui.results.clear" if cleared else &"ui.results.defeat",
			"CLEAR" if cleared else "DEFEAT",
		),
		&"title",
	))
	if cleared:
		column.add_child(_label(
			"StarLine", "*".repeat(int(result.get("stars", 0))), &"title",
		))
	column.add_child(_label(
		"TallyLine",
		UiCopyType.format_text(
			&"ui.results.tally", "kills {kills}   leaks {leaks}",
			{
				&"kills": int(result.get("kills", 0)),
				&"leaks": int(result.get("leaks", 0)),
			},
		),
		&"body",
	))
	var granted: Array = result.get("rewards_granted", [])
	for i: int in granted.size():
		var reward: Dictionary = granted[i]
		var reward_name := _reward_name(reward)
		column.add_child(_label(
			"Reward%d" % i,
			UiCopyType.format_text(
				&"ui.results.reward", "Unlocked: {name}", {&"name": reward_name},
			),
			&"body",
		))

	var stage_id := StringName(result.get("stage_id", &""))
	var record: StageNarrativeDefType = (NARRATIVE_CATALOG as StageNarrativeCatalogType).get_record(stage_id) if not String(stage_id).is_empty() else null
	column.add_child(_label("ConsequenceHeading", UiCopyType.text(&"ui.results.consequence", "Consequence"), &"heading"))
	var consequence := UiCopyType.text(&"ui.error.missing_stage_narrative", "Mission record unavailable. Return to Mission Control.")
	if record != null:
		consequence = UiCopyType.stage_narrative_text(record, StageNarrativeDefType.Field.CLEAR_DEBRIEF if cleared else StageNarrativeDefType.Field.DEFEAT_DEBRIEF)
	var consequence_line := _label("ConsequenceLine", consequence, &"body")
	column.add_child(consequence_line)

	_actions = GridContainer.new()
	_actions.name = "ActionRow"
	_actions.columns = 3
	_actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_actions.add_theme_constant_override(&"h_separation", 16)
	_actions.add_theme_constant_override(&"v_separation", 16)
	column.add_child(_actions)
	var focusable: Array[Button] = []
	var retry: AetheriaButtonType = null
	var next: AetheriaButtonType = null
	if Game.campaign_active and Game.campaign != null:
		retry = _button(
			"RetryButton", UiCopyType.text(&"ui.results.retry", "Retry"), &"secondary",
		)
		retry.pressed.connect(_on_retry)
		_actions.add_child(retry)
		next = _button(
			"ReturnToStaging",
			UiCopyType.text(&"ui.results.return_to_staging", "Return to Staging"), &"primary",
		)
		next.pressed.connect(_on_return_to_staging)
		_actions.add_child(next)
		focusable.append(next)
		focusable.append(retry)
	var title := _button(
		"BackToTitle", UiCopyType.text(&"ui.common.back_to_title", "Back to Title"),
		&"secondary" if not focusable.is_empty() else &"primary",
	)
	title.pressed.connect(_on_back_to_title)
	_actions.add_child(title)
	focusable.append(title)
	_wire_focus(focusable)
	_on_layout_mode_changed(_shell.layout_mode())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back_to_title()


func _on_layout_mode_changed(mode: StringName) -> void:
	if _actions != null:
		_actions.columns = 1 if mode == &"portrait" else 3
	if _shell != null:
		_shell.preferred_size = PORTRAIT_SIZE if mode == &"portrait" else LANDSCAPE_SIZE


func _reward_name(reward: Dictionary) -> String:
	var kind := StringName(reward.get("kind", &""))
	var identifier := StringName(reward.get("id", &""))
	if not KIND_DIRS.has(kind):
		return ""
	var definition: Resource = load("%s/%s.tres" % [KIND_DIRS[kind], identifier])
	if definition is OperatorDef:
		return UiCopyType.operator_name(definition)
	if definition is TrapDef:
		return UiCopyType.trap_name(definition)
	if definition is SpellDef:
		return UiCopyType.spell_name(definition)
	return ""


func _wire_focus(focusable: Array[Button]) -> void:
	for index: int in focusable.size():
		var current: Button = focusable[index]
		var previous: Button = focusable[(index - 1 + focusable.size()) % focusable.size()]
		var next: Button = focusable[(index + 1) % focusable.size()]
		current.focus_previous = current.get_path_to(previous)
		current.focus_next = current.get_path_to(next)
	focusable[0].grab_focus.call_deferred()


func _on_return_to_staging() -> void:
	Sfx.play("ui_click")
	Game.open_staging()


func _on_retry() -> void:
	Sfx.play("ui_click")
	Game.open_squad_select()


func _on_back_to_title() -> void:
	Sfx.play("ui_click")
	Game.open_title()


func _label(label_name: String, label_text: String, role: StringName) -> AetheriaLabelType:
	var label := AetheriaLabelType.new()
	label.name = label_name
	label.text = label_text
	label.apply_role(role)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _button(
		button_name: String, button_text: String, role: StringName,
	) -> AetheriaButtonType:
	var button := AetheriaButtonType.new()
	button.name = button_name
	button.text = button_text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.apply_role(role)
	return button
