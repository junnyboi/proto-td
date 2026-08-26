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
const StagingSkinType := preload("res://scripts/ui/components/staging_skin.gd")
const NARRATIVE_CATALOG := preload("res://data/presentation/narrative/stage_narrative_catalog.tres")
const StageNarrativeDefType := preload("res://data/presentation/narrative/stage_narrative_def.gd")
const StageNarrativeCatalogType := preload("res://data/presentation/narrative/stage_narrative_catalog.gd")
const LUNARIS_BACKDROP := preload("res://assets/loading/lunaris_reliquary_loading.png")
const RESULT_ACTION_WIDTH := 260.0
const RESULT_ACTION_HEIGHT := 96.0
const RESULT_ACTION_FONT_SIZE := 54
const RESULT_ACTION_HORIZONTAL_PADDING := 28.0
const RESULT_ACTION_VERTICAL_PADDING := 18.0
const RESULT_HEADER_HEIGHT := 132.0

var _actions: GridContainer = null
var _shell: AetheriaScreenShellType = null
var _body_grid: GridContainer = null
var _header_grid: GridContainer = null
var _outcome_plate: PanelContainer = null
var _tally: AetheriaLabelType = null
var _outcome_summary: BoxContainer = null
var _result_meta: BoxContainer = null
var _headline: AetheriaLabelType = null
var _result_stars: HBoxContainer = null
var _rewards_heading: AetheriaLabelType = null
var _consequence_heading: AetheriaLabelType = null
var _rewards_panel: PanelContainer = null
var _consequence_panel: PanelContainer = null
var _cleared_result := false
var _landscape_action_columns := 3


func _ready() -> void:
	Game.content = self
	Style.add_backdrop(self, LUNARIS_BACKDROP)
	var result: Dictionary = Game.last_result
	var cleared := int(result.get("result", 0)) == BattleModel.Result.CLEAR
	_cleared_result = cleared
	_shell = SHELL_SCENE.instantiate() as AetheriaScreenShellType
	_shell.name = "ResultsShell"
	_shell.full_safe_area = true
	var backdrop := _shell.get_node_or_null("Backdrop") as ColorRect
	if backdrop != null:
		backdrop.color = Color(Style.INK_DEEP, 0.84)
	add_child(_shell)
	_shell.layout_mode_changed.connect(_on_layout_mode_changed)
	get_viewport().size_changed.connect(_apply_responsive_layout)

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
	_outcome_plate = PanelContainer.new()
	_outcome_plate.name = "OutcomeCeremony"
	_outcome_plate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_outcome_plate.custom_minimum_size.y = RESULT_HEADER_HEIGHT
	Style.apply_panel(_outcome_plate, &"result" if cleared else &"danger")
	_set_panel_padding(_outcome_plate, 30.0, 22.0, 30.0, 22.0)
	layout.add_child(_outcome_plate)
	_header_grid = GridContainer.new()
	_header_grid.name = "ResultsHeader"
	_header_grid.columns = 1
	_header_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_header_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_header_grid.add_theme_constant_override(&"h_separation", 24)
	_header_grid.add_theme_constant_override(&"v_separation", 12)
	_outcome_plate.add_child(_header_grid)
	_outcome_summary = BoxContainer.new()
	_outcome_summary.name = "OutcomeSummary"
	_outcome_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_outcome_summary.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_outcome_summary.alignment = BoxContainer.ALIGNMENT_BEGIN
	_outcome_summary.add_theme_constant_override(&"separation", 22)
	_header_grid.add_child(_outcome_summary)
	var stage_id := StringName(result.get("stage_id", &""))
	_headline = _label(
		"Headline",
		_result_headline(stage_id, cleared),
		&"title",
	)
	_headline.add_theme_font_size_override(&"font_size", 60)
	_headline.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_headline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_outcome_summary.add_child(_headline)
	_result_meta = BoxContainer.new()
	_result_meta.name = "OutcomeMeta"
	_result_meta.vertical = false
	_result_meta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_result_meta.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_result_meta.add_theme_constant_override(&"separation", 16)
	_outcome_summary.add_child(_result_meta)
	_result_stars = HBoxContainer.new()
	_result_stars.name = "ResultStars"
	_result_stars.alignment = BoxContainer.ALIGNMENT_BEGIN
	_result_stars.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_result_stars.add_theme_constant_override(&"separation", 8)
	for index: int in 3:
		var star := ResonanceStarType.new()
		star.name = "ResultStar_%d" % (index + 1)
		star.custom_minimum_size = Vector2(34, 34)
		star.set_state(Style.GOLD, cleared and index < int(result.get("stars", 0)))
		_result_stars.add_child(star)
	_result_meta.add_child(_result_stars)
	_tally = _label(
		"TallyLine",
		UiCopyType.format_text(&"ui.results.tally", "KILLS {kills}   LEAKS {leaks}", {
			&"kills": int(result.get("kills", 0)),
			&"leaks": int(result.get("leaks", 0)),
		}).to_upper(),
		&"dense_heading",
	)
	_tally.custom_minimum_size.x = 270.0
	_tally.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tally.add_theme_font_size_override(&"font_size", 42)
	_tally.autowrap_mode = TextServer.AUTOWRAP_OFF
	_tally.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_tally.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_result_meta.add_child(_tally)


func _build_body(layout: VBoxContainer, result: Dictionary, cleared: bool) -> void:
	_body_grid = GridContainer.new()
	_body_grid.name = "ResultsBody"
	_body_grid.columns = 2
	_body_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body_grid.add_theme_constant_override(&"h_separation", 14)
	_body_grid.add_theme_constant_override(&"v_separation", 12)
	layout.add_child(_body_grid)

	_rewards_panel = PanelContainer.new()
	_rewards_panel.name = "RewardsPanel"
	_rewards_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rewards_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	Style.apply_panel(_rewards_panel, &"result" if cleared else &"quiet")
	_ensure_panel_padding(_rewards_panel, 30.0, 26.0, 28.0, 20.0)
	_body_grid.add_child(_rewards_panel)
	var rewards_scroll := ScrollContainer.new()
	rewards_scroll.name = "RewardsScroll"
	rewards_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rewards_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rewards_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_rewards_panel.add_child(rewards_scroll)
	var rewards := VBoxContainer.new()
	rewards.name = "RewardsColumn"
	rewards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rewards.add_theme_constant_override(&"separation", 16)
	rewards_scroll.add_child(rewards)
	_rewards_heading = _label("RewardsHeading", UiCopyType.text(&"ui.results.yield", "MISSION YIELD"), &"heading")
	_rewards_heading.add_theme_font_size_override(&"font_size", 45)
	rewards.add_child(_rewards_heading)
	var granted: Array = result.get("rewards_granted", [])
	if granted.is_empty():
		rewards.add_child(_result_card("RewardNone", UiCopyType.text(&"ui.results.no_rewards", "NO NEW MATERIAL REWARDS"), UiCopyType.text(&"ui.results.record_preserved", "Operation record preserved."), false, true))
	for i: int in granted.size():
		var reward: Dictionary = granted[i]
		if reward.get("kind") == "currency" and reward.get("id") == "marks":
			rewards.add_child(_result_card("Reward%d" % i, UiCopyType.format_text(&"ui.results.marks_reward", "+{count} MARKS", {&"count": int(reward.get("amount", 0))}), UiCopyType.text(&"ui.results.premium_fund", "Premium Resonance fund"), false, true))
		else:
			rewards.add_child(_result_card("Reward%d" % i, _reward_name(reward).to_upper(), UiCopyType.format_text(&"ui.results.unlocked_kind", "UNLOCKED · {kind}", {&"kind": String(reward.get("kind", "record")).to_upper()}), false, true))
	var entitlements: Array = result.get("class_entitlements_granted", [])
	for i: int in entitlements.size():
		rewards.add_child(_result_card("Entitlement%d" % i, _class_name(String(entitlements[i])).to_upper(), UiCopyType.text(&"ui.results.training_path_unlocked", "ADVANCED TRAINING PATH UNLOCKED"), false, true))
	var xp_awards: Array = result.get("xp_awards", [])
	for i: int in xp_awards.size():
		var award: Dictionary = xp_awards[i]
		rewards.add_child(_result_card("XpAward%d" % i, _hero_name(String(award.get("hero_id", ""))).to_upper(), UiCopyType.format_text(&"ui.results.xp_reward", "+{count} XP", {&"count": int(award.get("xp", award.get("amount", 0)))}), false, true))

	_consequence_panel = PanelContainer.new()
	_consequence_panel.name = "ConsequencePanel"
	_consequence_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_consequence_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	Style.apply_panel(_consequence_panel, &"danger" if not cleared else &"quiet")
	_ensure_panel_padding(_consequence_panel, 30.0, 26.0, 30.0, 20.0)
	_body_grid.add_child(_consequence_panel)
	var consequence_scroll := ScrollContainer.new()
	consequence_scroll.name = "ConsequenceScroll"
	consequence_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	consequence_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	consequence_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_consequence_panel.add_child(consequence_scroll)
	var consequences := VBoxContainer.new()
	consequences.name = "ConsequenceColumn"
	consequences.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	consequences.add_theme_constant_override(&"separation", 16)
	consequence_scroll.add_child(consequences)
	_consequence_heading = _label("ConsequenceHeading", UiCopyType.text(&"ui.results.consequence", "Consequence").to_upper(), &"heading")
	_consequence_heading.add_theme_font_size_override(&"font_size", 45)
	consequences.add_child(_consequence_heading)
	var narrative := _consequence_copy(result, cleared)
	var consequence_line := _label("ConsequenceLine", narrative, &"body")
	consequence_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	consequence_line.add_theme_font_size_override(&"font_size", 30)
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
	var action_center := CenterContainer.new()
	action_center.name = "ActionDock"
	action_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_center.custom_minimum_size.y = RESULT_ACTION_HEIGHT
	layout.add_child(action_center)
	_actions = GridContainer.new()
	_actions.name = "ActionRow"
	_actions.columns = 3
	_actions.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_actions.add_theme_constant_override(&"h_separation", 18)
	_actions.add_theme_constant_override(&"v_separation", 10)
	action_center.add_child(_actions)
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
	_apply_responsive_layout()


func _apply_responsive_layout() -> void:
	if _shell == null:
		return
	var mode := _shell.layout_mode()
	if _actions != null:
		_actions.columns = (
			1 if mode == &"portrait"
			else (2 if mode == &"compact_landscape" else _landscape_action_columns)
		)
	if _body_grid != null:
		_body_grid.columns = 1 if mode == &"portrait" else 2
	if _header_grid != null:
		_header_grid.columns = 1
	if _outcome_plate != null:
		_outcome_plate.custom_minimum_size.y = 180.0 if mode == &"portrait" else RESULT_HEADER_HEIGHT
		if mode == &"portrait":
			_set_panel_padding(_outcome_plate, 18.0, 14.0, 18.0, 14.0)
		else:
			_set_panel_padding(_outcome_plate, 30.0, 22.0, 30.0, 22.0)
	if _outcome_summary != null:
		_outcome_summary.vertical = mode == &"portrait"
		_outcome_summary.alignment = BoxContainer.ALIGNMENT_BEGIN
		_outcome_summary.add_theme_constant_override(&"separation", 12 if mode == &"portrait" else 22)
	if _result_meta != null:
		_result_meta.vertical = mode == &"portrait"
		_result_meta.add_theme_constant_override(&"separation", 12 if mode == &"portrait" else 16)
	if _rewards_heading != null:
		_rewards_heading.add_theme_font_size_override(&"font_size", 36 if mode == &"portrait" else 45)
	if _consequence_heading != null:
		_consequence_heading.add_theme_font_size_override(&"font_size", 36 if mode == &"portrait" else 45)
	if _rewards_panel != null:
		if mode == &"portrait":
			_apply_portrait_information_panel(_rewards_panel)
		else:
			Style.apply_panel(_rewards_panel, &"result" if _cleared_result else &"quiet")
			_set_panel_padding(_rewards_panel, 30.0, 26.0, 28.0, 20.0)
	if _consequence_panel != null:
		if mode == &"portrait":
			_apply_portrait_information_panel(_consequence_panel)
		else:
			Style.apply_panel(_consequence_panel, &"quiet" if _cleared_result else &"danger")
			_set_panel_padding(_consequence_panel, 30.0, 26.0, 30.0, 20.0)
	if _headline != null:
		var headline_size := 45 if mode == &"portrait" else 60
		_headline.add_theme_font_size_override(&"font_size", headline_size)
		_headline.size_flags_horizontal = Control.SIZE_EXPAND_FILL if mode == &"portrait" else Control.SIZE_SHRINK_BEGIN
		_headline.custom_minimum_size.x = 0.0 if mode == &"portrait" else minf(
			520.0,
			ceilf(_headline.get_theme_font(&"font").get_string_size(
				_headline.text,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1.0,
				headline_size,
			).x) + 4.0,
		)
	if _result_stars != null:
		for child: Node in _result_stars.get_children():
			(child as Control).custom_minimum_size = Vector2(26, 26) if mode == &"portrait" else Vector2(34, 34)
	if _tally != null:
		_tally.custom_minimum_size.x = 0.0 if mode == &"portrait" else 270.0
		_tally.add_theme_font_size_override(&"font_size", 33 if mode == &"portrait" else 42)
		_tally.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if mode == &"portrait" else TextServer.AUTOWRAP_OFF
		_tally.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_relayout_shell.call_deferred()


func _relayout_shell() -> void:
	if _shell != null and is_instance_valid(_shell):
		_shell.relayout(Vector2i(get_viewport_rect().size))


func _consequence_copy(result: Dictionary, cleared: bool) -> String:
	var record := _narrative_record(result)
	if record == null:
		return UiCopyType.text(&"ui.error.missing_stage_narrative", "Mission record unavailable. Return to Mission Control.")
	var field: int = StageNarrativeDefType.Field.CLEAR_DEBRIEF if cleared else StageNarrativeDefType.Field.DEFEAT_DEBRIEF
	return UiCopyType.stage_narrative_text(record, field)


func _result_headline(stage_id: StringName, cleared: bool) -> String:
	var stage_token := String(stage_id).to_upper()
	if stage_token.begins_with("S") and stage_token.substr(1).is_valid_int():
		stage_token = stage_token.substr(1)
	if stage_token.is_empty():
		stage_token = "—"
	return UiCopyType.format_text(
		&"ui.results.stage_cleared" if cleared else &"ui.results.stage_defeated",
		"STAGE {stage} CLEARED" if cleared else "STAGE {stage} DEFEATED",
		{&"stage": stage_token},
	).to_upper()


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
	_ensure_panel_padding(card, 22.0, 18.0, 22.0, 18.0)
	var stack := VBoxContainer.new()
	stack.name = "TransmissionContent"
	stack.add_theme_constant_override(&"separation", 5)
	card.add_child(stack)
	var transmission_heading := _label(
		"TransmissionHeading",
		UiCopyType.text(&"ui.results.transmission", "CLEAR TRANSMISSION"),
		&"dense_detail",
	)
	transmission_heading.add_theme_font_size_override(&"font_size", 27)
	stack.add_child(transmission_heading)
	var speaker := _label(
		"TransmissionSpeaker",
		UiCopyType.stage_narrative_text(record, StageNarrativeDefType.Field.TRANSMISSION_SPEAKER),
		&"dense_heading",
	)
	speaker.add_theme_font_size_override(&"font_size", 36)
	stack.add_child(speaker)
	var body := _label(
		"TransmissionBody",
		UiCopyType.stage_narrative_text(record, StageNarrativeDefType.Field.TRANSMISSION),
		&"dense_body",
	)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override(&"font_size", 30)
	stack.add_child(body)
	return card


func _result_card(
		node_name: String,
		title_text: String,
		detail_text: String,
		danger := false,
		unstyled := false,
	) -> Control:
	var card: Control
	if unstyled:
		var margin := MarginContainer.new()
		margin.add_theme_constant_override(&"margin_left", 6)
		margin.add_theme_constant_override(&"margin_top", 4)
		margin.add_theme_constant_override(&"margin_right", 6)
		margin.add_theme_constant_override(&"margin_bottom", 4)
		card = margin
	else:
		var panel := PanelContainer.new()
		Style.apply_panel(panel, &"danger" if danger else &"quiet")
		_ensure_panel_padding(panel, 20.0, 16.0, 20.0, 16.0)
		card = panel
	card.name = node_name
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override(&"separation", 6)
	card.add_child(stack)
	var title := _label("Title", title_text, &"dense_heading")
	title.add_theme_font_size_override(&"font_size", 36)
	stack.add_child(title)
	var detail := _label("Detail", detail_text, &"detail")
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_theme_font_size_override(&"font_size", 30)
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
	button.custom_minimum_size = Vector2(RESULT_ACTION_WIDTH, RESULT_ACTION_HEIGHT)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.apply_role(role)
	button.set_presentation_text(button_text, presentation_text)
	button.tooltip_text = button_text
	_apply_result_action_style(button, role == &"primary")
	return button


func _apply_result_action_style(button: AetheriaButtonType, primary: bool) -> void:
	var normal_fill := Color("30291af5") if primary else Color("09131ef2")
	var hover_fill := Color("493a1dfa") if primary else Color("102735f7")
	var pressed_fill := Color("1b160dfd") if primary else Color("061019fc")
	var normal_edge := Color(Style.GOLD, 0.82) if primary else Color(Style.CYAN, 0.54)
	button.add_theme_stylebox_override(&"normal", _result_action_box(normal_fill, normal_edge, 1))
	button.add_theme_stylebox_override(&"hover", _result_action_box(hover_fill, Style.GOLD if primary else Style.CYAN, 2))
	button.add_theme_stylebox_override(&"pressed", _result_action_box(pressed_fill, Style.GOLD, 2))
	button.add_theme_stylebox_override(&"disabled", _result_action_box(Color("111923e6"), Color(Style.MUTED, 0.26), 1))
	button.add_theme_stylebox_override(&"focus", StagingSkinType.transparent_focus_style(Style.CYAN))
	button.add_theme_font_size_override(&"font_size", RESULT_ACTION_FONT_SIZE)
	var presentation := button.get_node_or_null("PresentationLabel") as AetheriaLabelType
	if presentation != null:
		presentation.clip_text = false
		presentation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		StagingSkinType.apply_display_type(
			presentation,
			RESULT_ACTION_FONT_SIZE,
			Style.IVORY,
			620,
		)
	button.set_meta(&"result_action_fixed", true)


func _result_action_box(fill: Color, edge: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(4)
	style.content_margin_left = RESULT_ACTION_HORIZONTAL_PADDING
	style.content_margin_top = RESULT_ACTION_VERTICAL_PADDING
	style.content_margin_right = RESULT_ACTION_HORIZONTAL_PADDING
	style.content_margin_bottom = RESULT_ACTION_VERTICAL_PADDING
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.34)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0.0, 2.0)
	return style


func _set_panel_padding(
		panel: PanelContainer,
		left: float,
		top: float,
		right: float,
		bottom: float,
	) -> void:
	var style := panel.get_theme_stylebox(&"panel").duplicate() as StyleBox
	style.content_margin_left = left
	style.content_margin_top = top
	style.content_margin_right = right
	style.content_margin_bottom = bottom
	panel.add_theme_stylebox_override(&"panel", style)


func _apply_portrait_information_panel(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(Style.INK, 0.72)
	style.border_color = Color(Style.GOLD, 0.28)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 12.0
	style.content_margin_top = 8.0
	style.content_margin_right = 12.0
	style.content_margin_bottom = 8.0
	panel.add_theme_stylebox_override(&"panel", style)


func _ensure_panel_padding(
		panel: PanelContainer,
		left: float,
		top: float = -1.0,
		right: float = -1.0,
		bottom: float = -1.0,
	) -> void:
	var style := panel.get_theme_stylebox(&"panel").duplicate() as StyleBox
	var resolved_top := left if top < 0.0 else top
	var resolved_right := left if right < 0.0 else right
	var resolved_bottom := left if bottom < 0.0 else bottom
	style.content_margin_left = maxf(style.content_margin_left, left)
	style.content_margin_top = maxf(style.content_margin_top, resolved_top)
	style.content_margin_right = maxf(style.content_margin_right, resolved_right)
	style.content_margin_bottom = maxf(style.content_margin_bottom, resolved_bottom)
	panel.add_theme_stylebox_override(&"panel", style)
