extends Control

## Results projection over Game.last_result. Outcome, rewards, casualties, training
## eligibility, and route semantics remain authoritative; this script only stages them.

const SHELL_SCENE := preload("res://scenes/ui/components/aetheria_screen_shell.tscn")
const KIND_DIRS := {
	&"operator": "res://data/operators",
	&"trap": "res://data/traps",
	&"spell": "res://data/spells",
}
const AetheriaButtonType := preload("res://scripts/ui/components/aetheria_button.gd")
const AetheriaLabelType := preload("res://scripts/ui/components/aetheria_label.gd")
const AetheriaScreenShellType := preload("res://scripts/ui/components/aetheria_screen_shell.gd")
const UiCopyType := preload("res://scripts/ui/components/ui_copy.gd")
const ClassDefType := preload("res://data/class_def.gd")
const ResonanceStarType := preload("res://scripts/ui/components/resonance_star.gd")
const Style := preload("res://scripts/ui/components/lunaris_ops_style.gd")
const NARRATIVE_CATALOG := preload("res://data/presentation/narrative/stage_narrative_catalog.tres")
const StageNarrativeDefType := preload("res://data/presentation/narrative/stage_narrative_def.gd")
const StageNarrativeCatalogType := preload("res://data/presentation/narrative/stage_narrative_catalog.gd")
const LUNARIS_BACKDROP := preload("res://assets/loading/lunaris_reliquary_loading.png")

var _actions: GridContainer = null
var _shell: AetheriaScreenShellType = null
var _body_grid: GridContainer = null
var _landscape_action_columns := 3


func _ready() -> void:
	Game.content = self
	Style.add_backdrop(self, LUNARIS_BACKDROP)
	var result: Dictionary = Game.last_result
	var cleared := int(result.get("result", 0)) == BattleModel.Result.CLEAR
	_shell = SHELL_SCENE.instantiate() as AetheriaScreenShellType
	_shell.name = "ResultsShell"
	_shell.full_safe_area = true
	var backdrop := _shell.get_node_or_null("Backdrop") as ColorRect
	if backdrop != null:
		backdrop.color = Color(Style.INK_DEEP, 0.84)
	add_child(_shell)
	_shell.layout_mode_changed.connect(_on_layout_mode_changed)

	var layout := VBoxContainer.new()
	layout.name = "ResultsLayout"
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override(&"separation", 12)
	_shell.content_host().add_child(layout)
	_build_header(layout, result, cleared)
	_build_body(layout, result, cleared)
	_build_actions(layout)
	_on_layout_mode_changed(_shell.layout_mode())


func _build_header(layout: VBoxContainer, result: Dictionary, cleared: bool) -> void:
	var outcome_plate := PanelContainer.new()
	outcome_plate.name = "OutcomeCeremony"
	outcome_plate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outcome_plate.custom_minimum_size.y = 112.0
	Style.apply_panel(outcome_plate, &"result" if cleared else &"danger")
	layout.add_child(outcome_plate)
	var header := GridContainer.new()
	header.name = "ResultsHeader"
	header.columns = 3
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_constant_override(&"h_separation", 16)
	outcome_plate.add_child(header)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var eyebrow := _label("OutcomeEyebrow", UiCopyType.text(&"ui.results.eyebrow", "AFTER-ACTION RELIQUARY"), &"dense_detail")
	identity.add_child(eyebrow)
	var headline := _label(
		"Headline",
		UiCopyType.text(&"ui.results.clear" if cleared else &"ui.results.defeat", "VICTORY" if cleared else "DEFEAT").to_upper(),
		&"title",
	)
	headline.add_theme_font_size_override(&"font_size", 40)
	identity.add_child(headline)
	header.add_child(identity)
	var stage_id := StringName(result.get("stage_id", &""))
	var stage_title := String(stage_id).to_upper()
	var stage_path := "res://data/stages/%s.tres" % stage_id
	if ResourceLoader.exists(stage_path):
		stage_title = UiCopyType.stage_title(load(stage_path) as StageDef).to_upper()
	var stage_block := VBoxContainer.new()
	stage_block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var stage_label := _label("StageTitle", stage_title, &"heading")
	stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_block.add_child(stage_label)
	var stars := HBoxContainer.new()
	stars.name = "ResultStars"
	stars.alignment = BoxContainer.ALIGNMENT_CENTER
	stars.add_theme_constant_override(&"separation", 8)
	for index: int in 3:
		var star := ResonanceStarType.new()
		star.name = "ResultStar_%d" % (index + 1)
		star.set_state(Style.GOLD, cleared and index < int(result.get("stars", 0)))
		stars.add_child(star)
	stage_block.add_child(stars)
	header.add_child(stage_block)
	var tally := _label(
		"TallyLine",
		UiCopyType.format_text(&"ui.results.tally", "KILLS {kills}   LEAKS {leaks}", {
			&"kills": int(result.get("kills", 0)),
			&"leaks": int(result.get("leaks", 0)),
		}).to_upper(),
		&"dense_heading",
	)
	tally.custom_minimum_size.x = 230.0
	tally.autowrap_mode = TextServer.AUTOWRAP_OFF
	tally.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tally.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(tally)


func _build_body(layout: VBoxContainer, result: Dictionary, cleared: bool) -> void:
	_body_grid = GridContainer.new()
	_body_grid.name = "ResultsBody"
	_body_grid.columns = 2
	_body_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body_grid.add_theme_constant_override(&"h_separation", 14)
	_body_grid.add_theme_constant_override(&"v_separation", 12)
	layout.add_child(_body_grid)

	var rewards_panel := PanelContainer.new()
	rewards_panel.name = "RewardsPanel"
	rewards_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rewards_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	Style.apply_panel(rewards_panel, &"result" if cleared else &"quiet")
	_body_grid.add_child(rewards_panel)
	var rewards_scroll := ScrollContainer.new()
	rewards_scroll.name = "RewardsScroll"
	rewards_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rewards_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rewards_panel.add_child(rewards_scroll)
	var rewards := VBoxContainer.new()
	rewards.name = "RewardsColumn"
	rewards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rewards.add_theme_constant_override(&"separation", 10)
	rewards_scroll.add_child(rewards)
	rewards.add_child(_label("RewardsHeading", UiCopyType.text(&"ui.results.yield", "MISSION YIELD"), &"heading"))
	var granted: Array = result.get("rewards_granted", [])
	if granted.is_empty():
		rewards.add_child(_result_card("RewardNone", UiCopyType.text(&"ui.results.no_rewards", "NO NEW MATERIAL REWARDS"), UiCopyType.text(&"ui.results.record_preserved", "Operation record preserved.")))
	for i: int in granted.size():
		var reward: Dictionary = granted[i]
		if reward.get("kind") == "currency" and reward.get("id") == "marks":
			rewards.add_child(_result_card("Reward%d" % i, UiCopyType.format_text(&"ui.results.marks_reward", "+{count} MARKS", {&"count": int(reward.get("amount", 0))}), UiCopyType.text(&"ui.results.premium_fund", "Premium Resonance fund")))
		else:
			rewards.add_child(_result_card("Reward%d" % i, _reward_name(reward).to_upper(), UiCopyType.format_text(&"ui.results.unlocked_kind", "UNLOCKED · {kind}", {&"kind": String(reward.get("kind", "record")).to_upper()})))
	var entitlements: Array = result.get("class_entitlements_granted", [])
	for i: int in entitlements.size():
		rewards.add_child(_result_card("Entitlement%d" % i, _class_name(String(entitlements[i])).to_upper(), UiCopyType.text(&"ui.results.training_path_unlocked", "ADVANCED TRAINING PATH UNLOCKED")))
	var xp_awards: Array = result.get("xp_awards", [])
	for i: int in xp_awards.size():
		var award: Dictionary = xp_awards[i]
		rewards.add_child(_result_card("XpAward%d" % i, _hero_name(String(award.get("hero_id", ""))).to_upper(), UiCopyType.format_text(&"ui.results.xp_reward", "+{count} XP", {&"count": int(award.get("xp", award.get("amount", 0)))})))

	var consequence_panel := PanelContainer.new()
	consequence_panel.name = "ConsequencePanel"
	consequence_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	consequence_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	Style.apply_panel(consequence_panel, &"danger" if not cleared else &"quiet")
	_body_grid.add_child(consequence_panel)
	var consequence_scroll := ScrollContainer.new()
	consequence_scroll.name = "ConsequenceScroll"
	consequence_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	consequence_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	consequence_panel.add_child(consequence_scroll)
	var consequences := VBoxContainer.new()
	consequences.name = "ConsequenceColumn"
	consequences.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	consequences.add_theme_constant_override(&"separation", 10)
	consequence_scroll.add_child(consequences)
	consequences.add_child(_label("ConsequenceHeading", UiCopyType.text(&"ui.results.consequence", "Consequence").to_upper(), &"heading"))
	var narrative := _consequence_copy(result, cleared)
	var consequence_line := _label("ConsequenceLine", narrative, &"body")
	consequence_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	consequences.add_child(consequence_line)
	if cleared:
		var record := _narrative_record(result)
		if record != null:
			consequences.add_child(_transmission_card(record))
	var dead_ids: Array = result.get("dead_hero_ids", [])
	for i: int in dead_ids.size():
		consequences.add_child(_result_card("FallenHero%d" % i, _hero_name(String(dead_ids[i])).to_upper(), UiCopyType.text(&"ui.results.fallen_record", "FALLEN · MEMORIAL RECORD SEALED"), true))
	var premium_losses: Array = result.get("premium_life_losses", [])
	for i: int in premium_losses.size():
		var loss: Dictionary = premium_losses[i]
		var callsign := _premium_name(String(loss["premium_id"]))
		var detail := UiCopyType.format_text(&"ui.results.reserve_life_spent", "1 RESERVE LIFE SPENT · {count} REMAINING", {&"count": int(loss["lives_after"])})
		if bool(loss["locked_out"]):
			detail = UiCopyType.text(&"ui.results.final_life_spent", "FINAL LIFE SPENT · LOCKED UNTIL SAME IDENTITY IS PULLED AGAIN")
		consequences.add_child(_result_card("PremiumLifeLoss%d" % i, callsign.to_upper(), detail, bool(loss["locked_out"])))
	if dead_ids.is_empty() and premium_losses.is_empty():
		consequences.add_child(_result_card("NoCasualties", UiCopyType.text(&"ui.results.company_intact", "COMPANY INTACT"), UiCopyType.text(&"ui.results.no_losses", "No terminal losses recorded.")))


func _build_actions(layout: VBoxContainer) -> void:
	_actions = GridContainer.new()
	_actions.name = "ActionRow"
	_actions.columns = 3
	_actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_actions.add_theme_constant_override(&"h_separation", 12)
	_actions.add_theme_constant_override(&"v_separation", 10)
	layout.add_child(_actions)
	var focusable: Array[Button] = []
	if Game.campaign_active and Game.campaign != null:
		var eligible_count := int(Game.training_call(&"eligible_count"))
		var training_available := eligible_count > 0
		if training_available:
			var training := _button("TrainRecruits", UiCopyType.text(&"ui.results.train_recruits", "Train Recruits"), UiCopyType.text(&"ui.results.train_short", "Train"), &"primary")
			training.pressed.connect(_on_train_recruits)
			training.tooltip_text = UiCopyType.format_text(&"ui.results.training_available", "{count} recruits ready for training.", {&"count": eligible_count})
			_actions.add_child(training)
			focusable.append(training)
			_landscape_action_columns = 4
		var retry := _button("RetryButton", UiCopyType.text(&"ui.results.retry", "Retry Mission"), "Retry", &"secondary")
		retry.pressed.connect(_on_retry)
		_actions.add_child(retry)
		focusable.append(retry)
		var next := _button("ReturnToStaging", UiCopyType.text(&"ui.results.return_to_staging", "Return to Company Command"), "Command", &"primary" if not training_available else &"secondary")
		next.pressed.connect(_on_return_to_staging)
		_actions.add_child(next)
		focusable.append(next)
	var title := _button("BackToTitle", UiCopyType.text(&"ui.common.back_to_title", "Back to Title"), UiCopyType.text(&"ui.common.back", "Title"), &"secondary" if not focusable.is_empty() else &"primary")
	title.pressed.connect(_on_back_to_title)
	_actions.add_child(title)
	focusable.append(title)
	_wire_focus(focusable)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if Game.campaign_active and Game.campaign != null:
			_on_return_to_staging()
		else:
			_on_back_to_title()


func _on_layout_mode_changed(mode: StringName) -> void:
	if _actions != null:
		_actions.columns = 1 if mode == &"portrait" else _landscape_action_columns
	if _body_grid != null:
		_body_grid.columns = 1 if mode == &"portrait" else 2
	var header := find_child("ResultsHeader", true, false) as GridContainer
	if header != null:
		header.columns = 1 if mode == &"portrait" else 3


func _consequence_copy(result: Dictionary, cleared: bool) -> String:
	var record := _narrative_record(result)
	if record == null:
		return UiCopyType.text(&"ui.error.missing_stage_narrative", "Mission record unavailable. Return to Mission Control.")
	var field: int = StageNarrativeDefType.Field.CLEAR_DEBRIEF if cleared else StageNarrativeDefType.Field.DEFEAT_DEBRIEF
	return UiCopyType.stage_narrative_text(record, field)


func _narrative_record(result: Dictionary) -> StageNarrativeDefType:
	var stage_id := StringName(result.get("stage_id", &""))
	return (
		(NARRATIVE_CATALOG as StageNarrativeCatalogType).get_record(stage_id)
		if not String(stage_id).is_empty()
		else null
	)


func _transmission_card(record: StageNarrativeDefType) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "ClearTransmission"
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Style.apply_panel(card, &"selected")
	var stack := VBoxContainer.new()
	stack.name = "TransmissionContent"
	stack.add_theme_constant_override(&"separation", 5)
	card.add_child(stack)
	stack.add_child(_label(
		"TransmissionHeading",
		UiCopyType.text(&"ui.results.transmission", "CLEAR TRANSMISSION"),
		&"dense_detail",
	))
	var speaker := _label(
		"TransmissionSpeaker",
		UiCopyType.stage_narrative_text(record, StageNarrativeDefType.Field.TRANSMISSION_SPEAKER),
		&"dense_heading",
	)
	stack.add_child(speaker)
	var body := _label(
		"TransmissionBody",
		UiCopyType.stage_narrative_text(record, StageNarrativeDefType.Field.TRANSMISSION),
		&"dense_body",
	)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override(&"font_size", 14)
	stack.add_child(body)
	return card


func _result_card(node_name: String, title_text: String, detail_text: String, danger := false) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = node_name
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Style.apply_panel(card, &"danger" if danger else &"quiet")
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override(&"separation", 4)
	card.add_child(stack)
	stack.add_child(_label("Title", title_text, &"dense_heading"))
	var detail := _label("Detail", detail_text, &"dense_detail")
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(detail)
	return card


func _reward_name(reward: Dictionary) -> String:
	var kind := StringName(reward.get("kind", &""))
	var identifier := StringName(reward.get("id", &""))
	if not KIND_DIRS.has(kind):
		return String(identifier).replace("_", " ").capitalize()
	var definition: Resource = load("%s/%s.tres" % [KIND_DIRS[kind], identifier])
	if definition is OperatorDef:
		return UiCopyType.operator_name(definition)
	if definition is TrapDef:
		return UiCopyType.trap_name(definition)
	if definition is SpellDef:
		return UiCopyType.spell_name(definition)
	return String(identifier).replace("_", " ").capitalize()


func _hero_name(hero_id: String) -> String:
	var projection := Game.campaign_projection()
	for key: String in ["ready_heroes", "fallen_heroes", "premium_heroes"]:
		for row: Dictionary in projection.get(key, []):
			if String(row.get("hero_id", "")) == hero_id:
				return String(row.get("callsign", row.get("premium_id", hero_id)))
	return hero_id.replace("_", " ").capitalize()


func _premium_name(premium_id: String) -> String:
	var projection := Game.campaign_projection()
	for row: Dictionary in projection.get("premium_pool", []):
		if String(row.get("premium_id", "")) == premium_id:
			return String(row.get("callsign", premium_id))
	return premium_id.replace("_", " ").capitalize()


func _class_name(class_id: String) -> String:
	var definition := load("res://data/classes/%s.tres" % class_id) as ClassDefType
	return UiCopyType.text(definition.name_key, definition.name) if definition != null else class_id


func _wire_focus(focusable: Array[Button]) -> void:
	for index: int in focusable.size():
		var current: Button = focusable[index]
		var previous: Button = focusable[(index - 1 + focusable.size()) % focusable.size()]
		var next: Button = focusable[(index + 1) % focusable.size()]
		current.focus_previous = current.get_path_to(previous)
		current.focus_next = current.get_path_to(next)
	if not focusable.is_empty():
		focusable[0].grab_focus.call_deferred()


func _on_return_to_staging() -> void:
	Sfx.play("ui_click")
	Game.open_staging()


func _on_train_recruits() -> void:
	Sfx.play("ui_click")
	Game.training_call(&"open", &"results")


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
	return label


func _button(button_name: String, button_text: String, presentation_text: String, role: StringName) -> AetheriaButtonType:
	var button := AetheriaButtonType.new()
	button.name = button_name
	button.text = button_text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.apply_role(role)
	button.set_presentation_text(button_text, presentation_text)
	button.tooltip_text = button_text
	button.apply_compact_action_layout()
	return button
