class_name TrainingScreen
extends Control

const SHELL_SCENE := preload("res://scenes/ui/components/aetheria_screen_shell.tscn")
const AetheriaButtonType := preload("res://scripts/ui/components/aetheria_button.gd")
const AetheriaLabelType := preload("res://scripts/ui/components/aetheria_label.gd")
const AetheriaPanelType := preload("res://scripts/ui/components/aetheria_panel.gd")
const AetheriaScreenShellType := preload("res://scripts/ui/components/aetheria_screen_shell.gd")
const PromotionPathCardType := preload("res://scripts/ui/components/promotion_path_card.gd")
const TrainingRosterRowType := preload("res://scripts/ui/components/training_roster_row.gd")
const UiCopyType := preload("res://scripts/ui/components/ui_copy.gd")

const SHELL_SIZE := Vector2(1160.0, 640.0)
const COMPACT_SHELL_SIZE := Vector2(880.0, 640.0)
const PORTRAIT_SHELL_SIZE := Vector2(640.0, 1120.0)
const REQUIRED_CAMPAIGN_METHODS := [
	&"training_roster", &"promotion_options", &"promote_hero", &"campaign_uid",
	&"save_revision", &"strategic_hash",
]
const ERROR_KEYS := {
	&"invalid_argument_type": &"ui.training.error.invalid_request",
	&"unknown_hero": &"ui.training.error.unknown_hero",
	&"hero_not_ready": &"ui.training.error.not_ready",
	&"insufficient_xp": &"ui.training.error.insufficient_xp",
	&"wrong_source_class": &"ui.training.error.no_path",
	&"invalid_choice": &"ui.training.error.invalid_choice",
	&"already_promoted": &"ui.training.error.already_promoted",
	&"stale_revision": &"ui.training.error.stale_state",
	&"command_id_conflict": &"ui.training.error.command_conflict",
	&"xp_overflow": &"ui.training.error.progression_failed",
	&"save_failed": &"ui.save.write_failed",
}
const ERROR_FALLBACKS := {
	&"invalid_argument_type": "Training request was invalid.",
	&"unknown_hero": "That recruit is no longer in the roster.",
	&"hero_not_ready": "This recruit is not ready for training.",
	&"insufficient_xp": "This recruit needs more XP.",
	&"wrong_source_class": "This class has no advanced path here.",
	&"invalid_choice": "That training path is not available.",
	&"already_promoted": "This recruit has already chosen an advanced path.",
	&"stale_revision": "The roster changed. Review the recruit again.",
	&"command_id_conflict": "This training request conflicts with an earlier command.",
	&"xp_overflow": "Training progression could not be applied.",
	&"save_failed": "The campaign could not be saved.",
}
const CLASS_LABELS := {
	"shock_trooper": "Shock Trooper",
	"swordmaster": "Swordmaster",
	"defender": "Defender",
	"gunner": "Gunner",
	"mage_apprentice": "Mage Apprentice",
	"banner_guard": "Banner Guard",
	"sword_saint": "Sword Saint",
	"immovable": "Immovable",
	"sniper": "Sniper",
	"witch_doctor": "Witch Doctor",
	"sorcerer": "Sorcerer",
}

var _campaign: Variant = null
var _shell: AetheriaScreenShellType
var _page: VBoxContainer
var _dialog_scroll: ScrollContainer
var _mode: StringName = &"roster"
var _layout_mode: StringName = &"regular_landscape"
var _roster_rows: Array[Dictionary] = []
var _roster_buttons: Array[TrainingRosterRowType] = []
var _path_cards: Array[PromotionPathCardType] = []
var _selected_hero_id := ""
var _selected_choice_id := ""
var _view_paths: AetheriaButtonType
var _choose_path: AetheriaButtonType
var _modal_layer: Control
var _modal_error: AetheriaLabelType
var _modal_cancel: AetheriaButtonType
var _modal_confirm: AetheriaButtonType
var _modal_background_focus: Array[Dictionary] = []
var _confirmation_consumed := false
var _promotion_dispatch_count := 0
var _success_text := ""


func _ready() -> void:
	_campaign = Game.campaign
	if not supports_campaign(_campaign):
		Game.open_staging()
		return
	Game.content = self
	_build_shell()
	_refresh_roster()
	_show_roster()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel") or _modal_layer == null:
		return
	get_viewport().set_input_as_handled()
	_close_confirmation()


static func supports_campaign(value: Variant) -> bool:
	if value == null:
		return false
	for method_name: StringName in REQUIRED_CAMPAIGN_METHODS:
		if not value.has_method(method_name):
			return false
	return true


static func build_command(campaign: Variant, hero_id: String, choice_id: String) -> Dictionary:
	if not supports_campaign(campaign) or hero_id.is_empty() or choice_id.is_empty():
		return {}
	var revision := int(campaign.call("save_revision"))
	var campaign_uid := String(campaign.call("campaign_uid"))
	return {
		"version": 1,
		"verb": "promote_hero",
		"command_id": "promote:%s:%d:%s:%s" % [
			campaign_uid, revision, hero_id, choice_id,
		],
		"hero_id": hero_id,
		"advanced_class_id": choice_id,
		"expected_save_revision": revision,
	}


static func error_key(error_code: StringName) -> StringName:
	return ERROR_KEYS.get(error_code, &"ui.error.unknown")


static func class_label(class_id: String) -> String:
	var fallback := String(
		CLASS_LABELS.get(class_id, class_id.replace("_", " ").capitalize()),
	)
	return UiCopyType.text(StringName("ui.training.class.%s" % class_id), fallback)


func mode() -> StringName:
	return _mode


func selected_hero_id() -> String:
	return _selected_hero_id


func selected_choice_id() -> String:
	return _selected_choice_id


func _build_shell() -> void:
	_shell = SHELL_SCENE.instantiate() as AetheriaScreenShellType
	_shell.name = "TrainingScreenShell"
	_shell.preferred_size = SHELL_SIZE
	add_child(_shell)
	_shell.layout_mode_changed.connect(_on_layout_mode_changed)
	(_shell.reading_plate() as PanelContainer).name = "TrainingShell"
	_page = VBoxContainer.new()
	_page.name = "TrainingPage"
	_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_page.add_theme_constant_override(&"separation", 10)
	_dialog_scroll = ScrollContainer.new()
	_dialog_scroll.name = "TrainingDialogScroll"
	var content_gutter := _shell.add_dialog_scroll(_dialog_scroll)
	content_gutter.add_child(_page)
	_layout_mode = _shell.layout_mode()
	_shell.preferred_size = _shell_size_for(_layout_mode)


func _refresh_roster() -> void:
	_roster_rows = _campaign.call("training_roster") as Array[Dictionary]
	if _selected_hero_id.is_empty() or _summary_by_id(_selected_hero_id).is_empty():
		_selected_hero_id = ""
		for summary: Dictionary in _roster_rows:
			if bool(summary["can_promote"]):
				_selected_hero_id = String(summary["hero_id"])
				break
		if _selected_hero_id.is_empty() and not _roster_rows.is_empty():
			_selected_hero_id = String(_roster_rows[0]["hero_id"])


func _show_roster() -> void:
	_mode = &"roster"
	_selected_choice_id = ""
	_clear_page()
	_page.add_child(_header(
		"TrainingTitle", _t(&"ui.training.title", "TRAINING"),
		_t(&"ui.training.choose_recruit", "Choose a recruit to train."),
	))
	var ready_count := 0
	for summary: Dictionary in _roster_rows:
		if bool(summary["can_promote"]):
			ready_count += 1
	var ready := _label(
		"PromotionReadyCount",
		_fmt(
			&"ui.training.promotion_ready_count", "{count} PROMOTION READY",
			{&"count": ready_count},
		),
		&"dense_heading",
	)
	ready.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_page.add_child(ready)
	var body := BoxContainer.new()
	body.name = "TrainingRosterBody"
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override(&"separation", 16)
	_page.add_child(body)
	body.add_child(_build_roster_list())
	body.add_child(_build_inspector())
	var footer := _footer("RosterActions")
	var back := _button(
		"TrainingBack", _t(&"ui.common.back", "Back"), true, &"secondary",
	)
	back.pressed.connect(_on_back_to_staging)
	_view_paths = _button(
		"ViewPaths", _t(&"ui.training.view_paths", "View Paths"),
		_selected_can_promote(), &"primary" if _selected_can_promote() else &"disabled",
	)
	_view_paths.pressed.connect(_on_view_paths)
	footer.add_child(back)
	footer.add_child(_view_paths)
	_page.add_child(footer)
	_apply_roster_layout()
	_reset_outer_scroll()
	_wire_focus(_focusable_controls(), false)
	_focus_selected_row_or(back)


func _build_roster_list() -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.name = "TrainingRosterScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_stretch_ratio = 1.7
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var list := VBoxContainer.new()
	list.name = "TrainingRosterList"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override(&"separation", 8)
	scroll.add_child(list)
	_roster_buttons.clear()
	for summary: Dictionary in _roster_rows:
		var row := TrainingRosterRowType.new()
		row.name = "Recruit_%s" % summary["hero_id"]
		row.configure(
			summary,
			class_label(String(summary["current_class_id"])),
			_status_text(String(summary["life_status"])),
			_fmt(
				&"ui.training.xp_progress", "XP {current} / {required}",
				{
					&"current": int(summary["xp"]),
					&"required": int(summary["xp_required"]),
				},
			),
			_eligibility_text(summary),
		)
		row.set_selected(String(summary["hero_id"]) == _selected_hero_id)
		row.pressed.connect(_on_roster_selected.bind(String(summary["hero_id"])))
		list.add_child(row)
		_roster_buttons.append(row)
	return scroll


func _build_inspector() -> AetheriaPanelType:
	var panel := AetheriaPanelType.new()
	panel.name = "TrainingInspector"
	panel.apply_role(&"inspector")
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio = 1.0
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.name = "InspectorColumn"
	column.add_theme_constant_override(&"separation", 12)
	panel.add_child(column)
	column.add_child(_label(
		"FieldRecordHeading", _t(&"ui.training.field_record", "FIELD RECORD"),
		&"dense_heading",
	))
	column.add_child(_label(
		"SameRecruitNewJob",
		_t(&"ui.training.same_recruit_new_job", "Same recruit. New job."),
		&"dense_body",
	))
	column.add_child(_label(
		"TrainingExplainer",
		_t(
			&"ui.training.training_explainer",
			"Advanced training changes equipment, duties, and field role. It does not replace the person.",
		),
		&"dense_detail",
	))
	var selected := _summary_by_id(_selected_hero_id)
	if not selected.is_empty():
		column.add_child(_label(
			"SelectedRecruitStatus", _eligibility_text(selected), &"dense_body",
		))
	if not _success_text.is_empty():
		column.add_child(_label("TrainingSuccess", _success_text, &"dense_heading"))
	return panel


func _show_paths() -> void:
	var options: Dictionary = _campaign.call("promotion_options", _selected_hero_id)
	if not bool(options.get("accepted", false)):
		_show_roster()
		return
	_mode = &"paths"
	_clear_page()
	var summary := _summary_by_id(_selected_hero_id)
	_page.add_child(_header(
		"ChooseTrainingTitle",
		_t(&"ui.training.choose_advanced", "CHOOSE ADVANCED TRAINING"),
		_fmt(
			&"ui.training.hero_progress", "{callsign} — {class_name} — XP {current} / {required}",
			{
				&"callsign": String(summary["callsign"]),
				&"class_name": class_label(String(summary["current_class_id"])),
				&"current": int(summary["xp"]),
				&"required": int(summary["xp_required"]),
			},
		),
	))
	_page.add_child(_identity_strip(summary))
	var scroll := ScrollContainer.new()
	scroll.name = "PathCardsScroll"
	scroll.custom_minimum_size.y = 540.0
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var cards := BoxContainer.new()
	cards.name = "PathCards"
	cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards.add_theme_constant_override(&"separation", 16)
	scroll.add_child(cards)
	_path_cards.clear()
	for raw_choice: Variant in options["choices"]:
		var choice := raw_choice as Dictionary
		var card := PromotionPathCardType.new()
		card.name = "Path_%s" % choice["advanced_class_id"]
		card.configure(
			choice, class_label(String(choice["advanced_class_id"])),
			_role_text(String(choice["role"])), _skill_text(choice),
			_fmt(
				&"ui.training.format.dp", "{value} DP",
				{&"value": int(choice["dp_cost"])},
			),
			_t(&"ui.training.class_kit_placeholder", "CLASS KIT\nTEMP ART"),
			_kit_text(String(choice["advanced_class_id"])),
		)
		card.pressed.connect(
			_on_path_selected.bind(String(choice["advanced_class_id"])),
		)
		cards.add_child(card)
		_path_cards.append(card)
	_page.add_child(scroll)
	_page.add_child(_label(
		"PermanentWarning",
		_t(&"ui.training.permanent_warning", "THIS CHOICE IS PERMANENT."),
		&"dense_heading",
	))
	var footer := _footer("PathActions")
	var back := _button(
		"PathBack", _t(&"ui.common.back", "Back"), true, &"secondary",
	)
	back.pressed.connect(_show_roster)
	_choose_path = _button(
		"ChoosePath", _t(&"ui.training.choose_path", "Choose Path"),
		false, &"disabled",
	)
	_choose_path.pressed.connect(_open_confirmation)
	footer.add_child(back)
	footer.add_child(_choose_path)
	_page.add_child(footer)
	_apply_paths_layout()
	_reset_outer_scroll()
	_wire_focus(_focusable_controls(), _layout_mode != &"portrait")
	if not _path_cards.is_empty():
		_path_cards[0].grab_focus.call_deferred()


func _identity_strip(summary: Dictionary) -> AetheriaPanelType:
	var panel := AetheriaPanelType.new()
	panel.name = "IdentityContinuityStrip"
	panel.apply_role(&"hud")
	var text := _fmt(
		&"ui.training.same_identity",
		"SAME RECRUIT • SAME HERO ID • SAME CALLSIGN • SAME HISTORY",
		{},
	)
	var label := _label("IdentityContinuity", text, &"dense_detail")
	label.tooltip_text = "%s — %s" % [summary["callsign"], summary["hero_id"]]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(label)
	return panel


func _open_confirmation() -> void:
	if _selected_choice_id.is_empty() or _modal_layer != null:
		return
	var summary := _summary_by_id(_selected_hero_id)
	var choice := _selected_choice()
	if summary.is_empty() or choice.is_empty():
		return
	_confirmation_consumed = false
	_suspend_background_focus()
	_modal_layer = Control.new()
	_modal_layer.name = "PromotionConfirmationLayer"
	_modal_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal_layer.theme = _shell.theme
	add_child(_modal_layer)
	var dim := ColorRect.new()
	dim.name = "ModalDim"
	dim.color = Color(0.02, 0.04, 0.08, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_modal_layer.add_child(dim)
	var center := CenterContainer.new()
	center.name = "ModalCenter"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal_layer.add_child(center)
	var panel := AetheriaPanelType.new()
	panel.name = "PromotionConfirmation"
	panel.apply_role(&"modal")
	panel.custom_minimum_size = (
		Vector2(640.0, 1120.0)
		if _layout_mode == &"portrait" else Vector2(1120.0, 660.0)
	)
	center.add_child(panel)
	var modal_scroll := ScrollContainer.new()
	modal_scroll.name = "ConfirmationScroll"
	modal_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modal_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	modal_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(modal_scroll)
	var modal_gutter := MarginContainer.new()
	modal_gutter.name = "ConfirmationGutter"
	modal_gutter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side: StringName in [
		&"margin_left", &"margin_top", &"margin_right", &"margin_bottom",
	]:
		modal_gutter.add_theme_constant_override(side, 20)
	modal_scroll.add_child(modal_gutter)
	var column := VBoxContainer.new()
	column.name = "ConfirmationColumn"
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override(&"separation", 10)
	modal_gutter.add_child(column)
	column.add_child(_label(
		"ConfirmationTitle",
		_fmt(
			&"ui.training.confirm_title", "CONFIRM {class_name} TRAINING?",
			{&"class_name": class_label(_selected_choice_id).to_upper()},
		),
		&"dense_heading",
	))
	var hero_line := _label("ConfirmationCallsign", String(summary["callsign"]), &"dense_body")
	hero_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(hero_line)
	column.add_child(_label(
		"ClassTransition",
		"%s → %s" % [
			class_label(String(summary["current_class_id"])),
			class_label(_selected_choice_id),
		],
		&"dense_body",
	))
	column.add_child(_identity_strip(summary))
	column.add_child(_confirmation_identity_row(summary, choice))
	column.add_child(_label(
		"ConfirmationFacts",
		"%s • %s • %d DP" % [
			_role_text(String(choice["role"])), _skill_text(choice),
			int(choice["dp_cost"]),
		],
		&"dense_body",
	))
	column.add_child(_label(
		"ConfirmationPermanent",
		_t(
			&"ui.training.confirm_permanent",
			"This training choice cannot be changed.",
		),
		&"dense_heading",
	))
	if _selected_choice_id == "witch_doctor":
		column.add_child(_label(
			"NoReviveWarning",
			_t(
				&"ui.training.no_revive_warning",
				"Death remains permanent. Mend cannot revive the dead.",
			),
			&"dense_detail",
		))
	_modal_error = _label("ConfirmationError", "", &"dense_detail")
	column.add_child(_modal_error)
	var actions := _footer("ConfirmationActions")
	_modal_cancel = _button(
		"CancelTraining", _t(&"ui.training.cancel", "Cancel"), true, &"secondary",
	)
	_modal_confirm = _button(
		"ConfirmTraining", _t(&"ui.training.confirm_action", "Confirm Training"),
		true, &"primary",
	)
	_modal_cancel.pressed.connect(_close_confirmation)
	_modal_confirm.pressed.connect(_confirm_training)
	actions.add_child(_modal_cancel)
	actions.add_child(_modal_confirm)
	column.add_child(actions)
	var boundary := _label(
		"StateBoundary",
		_t(
			&"ui.training.state_after_confirmation",
			"State changes only after confirmation.",
		),
		&"dense_detail",
	)
	boundary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(boundary)
	_wire_modal_focus()
	_modal_cancel.grab_focus.call_deferred()


func _confirmation_identity_row(
	summary: Dictionary, choice: Dictionary,
) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "ConfirmationIdentityRow"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", 18)
	row.add_child(_identity_card(
		"CurrentIdentity", summary,
		class_label(String(summary["current_class_id"])),
	))
	row.add_child(_label(
		"TrainingAssignment",
		_t(
			&"ui.training.assignment",
			"COMPANY 33\nTRAINING ASSIGNMENT\nNEW FIELD KIT",
		),
		&"dense_detail",
	))
	row.add_child(_identity_card(
		"NewDutyIdentity", summary,
		class_label(String(choice["advanced_class_id"])),
	))
	return row


func _identity_card(
	node_name: String, summary: Dictionary, duty: String,
) -> AetheriaPanelType:
	var panel := AetheriaPanelType.new()
	panel.name = node_name
	panel.apply_role(&"card")
	panel.custom_minimum_size = Vector2(250.0, 176.0)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(column)
	var portrait := TextureRect.new()
	portrait.name = "%sPortrait" % node_name
	portrait.texture = Art.texture(
		StringName("portrait_%s" % summary["identity_portrait_id"]),
	)
	portrait.custom_minimum_size = Vector2(140.0, 110.0)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.tooltip_text = _fmt(
		&"ui.training.identity_portrait_alt", "Identity portrait for {callsign}",
		{&"callsign": String(summary["callsign"])},
	)
	column.add_child(portrait)
	var label := _label("%sDuty" % node_name, duty.to_upper(), &"dense_detail")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(label)
	return panel


func _suspend_background_focus() -> void:
	_modal_background_focus.clear()
	for control: Control in _focusable_controls():
		_modal_background_focus.append({
			"control": control,
			"focus_mode": int(control.focus_mode),
		})
		control.focus_mode = Control.FOCUS_NONE


func _restore_background_focus() -> void:
	for entry: Dictionary in _modal_background_focus:
		var control := entry["control"] as Control
		if control != null and is_instance_valid(control):
			control.focus_mode = int(entry["focus_mode"])
	_modal_background_focus.clear()


func _wire_modal_focus() -> void:
	for current: Control in [_modal_cancel, _modal_confirm]:
		var other := _modal_confirm if current == _modal_cancel else _modal_cancel
		var path := current.get_path_to(other)
		current.focus_previous = path
		current.focus_next = path
		current.focus_neighbor_left = path
		current.focus_neighbor_right = path
		current.focus_neighbor_top = path
		current.focus_neighbor_bottom = path


func _set_modal_actions_enabled(enabled: bool) -> void:
	for control: AetheriaButtonType in [_modal_cancel, _modal_confirm]:
		if control == null:
			continue
		control.disabled = not enabled
		control.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE


func _release_confirmation_retry(error_code: StringName) -> void:
	if _modal_error != null:
		_modal_error.text = _error_text(error_code)
	_confirmation_consumed = false
	_set_modal_actions_enabled(true)
	_wire_modal_focus()
	_modal_confirm.grab_focus.call_deferred()


func _close_confirmation() -> void:
	if _modal_layer == null:
		return
	_modal_layer.queue_free()
	_modal_layer = null
	_modal_error = null
	_modal_cancel = null
	_modal_confirm = null
	_confirmation_consumed = false
	_restore_background_focus()
	if _choose_path != null:
		_choose_path.grab_focus.call_deferred()


func _confirm_training() -> void:
	if _confirmation_consumed or _modal_layer == null:
		return
	_confirmation_consumed = true
	_set_modal_actions_enabled(false)
	var command := build_command(_campaign, _selected_hero_id, _selected_choice_id)
	if command.is_empty():
		_release_confirmation_retry(&"invalid_argument_type")
		return
	_promotion_dispatch_count += 1
	var result: Dictionary = _campaign.call("promote_hero", command)
	if not bool(result.get("accepted", false)):
		_release_confirmation_retry(StringName(result.get("error_code", &"")))
		return
	var summary := _summary_by_id(_selected_hero_id)
	_success_text = _fmt(
		&"ui.training.success", "{callsign} is now a {class_name}.",
		{
			&"callsign": String(summary.get("callsign", _selected_hero_id)),
			&"class_name": class_label(_selected_choice_id),
		},
	)
	_modal_layer.queue_free()
	_modal_layer = null
	_modal_error = null
	_modal_cancel = null
	_modal_confirm = null
	_restore_background_focus()
	_refresh_roster()
	_show_roster()


func _on_roster_selected(hero_id: String) -> void:
	_selected_hero_id = hero_id
	_success_text = ""
	_show_roster()


func _on_view_paths() -> void:
	if _selected_can_promote():
		_show_paths()


func _on_path_selected(choice_id: String) -> void:
	_selected_choice_id = choice_id
	for card: PromotionPathCardType in _path_cards:
		card.set_selected(card.advanced_class_id == choice_id)
	_choose_path.disabled = false
	_choose_path.focus_mode = Control.FOCUS_ALL
	_choose_path.apply_role(&"primary")
	_wire_focus(_focusable_controls(), _layout_mode != &"portrait")


func _on_back_to_staging() -> void:
	Sfx.play("ui_click")
	Game.open_staging()


func _on_layout_mode_changed(value: StringName) -> void:
	_layout_mode = value
	var target_size := _shell_size_for(value)
	if _shell.preferred_size != target_size:
		_shell.preferred_size = target_size
	if _mode == &"paths":
		_apply_paths_layout()
	else:
		_apply_roster_layout()
	_reset_outer_scroll()


func _shell_size_for(mode_value: StringName) -> Vector2:
	if mode_value == &"portrait":
		return PORTRAIT_SHELL_SIZE
	if mode_value == &"compact_landscape":
		return COMPACT_SHELL_SIZE
	return SHELL_SIZE


func _apply_roster_layout() -> void:
	var body := _page.get_node_or_null("TrainingRosterBody") as BoxContainer
	if body == null:
		return
	body.vertical = _layout_mode == &"portrait"
	for row: TrainingRosterRowType in _roster_buttons:
		row.set_compact(_layout_mode != &"regular_landscape")


func _apply_paths_layout() -> void:
	var cards := _page.get_node_or_null("PathCardsScroll/PathCards") as BoxContainer
	if cards == null:
		return
	var scroll := cards.get_parent() as ScrollContainer
	cards.vertical = _layout_mode != &"regular_landscape"
	scroll.custom_minimum_size.y = (
		580.0 if _layout_mode == &"portrait" else 540.0
	)
	for card: PromotionPathCardType in _path_cards:
		card.set_compact(_layout_mode == &"portrait")


func _reset_outer_scroll() -> void:
	if _dialog_scroll == null:
		return
	_dialog_scroll.vertical_scroll_mode = (
		ScrollContainer.SCROLL_MODE_DISABLED
		if _mode == &"paths" and _layout_mode == &"portrait"
		else ScrollContainer.SCROLL_MODE_AUTO
	)
	_dialog_scroll.scroll_vertical = 0


func _header(node_name: String, title: String, subtitle: String) -> VBoxContainer:
	var header := VBoxContainer.new()
	header.name = node_name
	header.add_theme_constant_override(&"separation", 0)
	header.add_child(_label("%sHeading" % node_name, title, &"dense_heading"))
	header.add_child(_label("%sSubtitle" % node_name, subtitle, &"dense_detail"))
	return header


func _footer(node_name: String) -> HBoxContainer:
	var footer := HBoxContainer.new()
	footer.name = node_name
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.add_theme_constant_override(&"separation", 16)
	return footer


func _button(
	node_name: String, button_text: String, enabled: bool, role: StringName,
) -> AetheriaButtonType:
	var button := AetheriaButtonType.new()
	button.name = node_name
	button.text = button_text
	button.custom_minimum_size = Vector2(240.0, 64.0)
	button.disabled = not enabled
	button.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
	button.apply_role(role)
	button.set_presentation_text(button_text, button_text)
	var presentation := button.get_node("PresentationLabel") as AetheriaLabelType
	presentation.apply_role(&"dense_body")
	return button


func _label(
	node_name: String, label_text: String, role: StringName,
) -> AetheriaLabelType:
	var label := AetheriaLabelType.new()
	label.name = node_name
	label.text = label_text
	label.apply_role(role)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


func _clear_page() -> void:
	for child: Node in _page.get_children():
		_page.remove_child(child)
		child.queue_free()
	_roster_buttons.clear()
	_path_cards.clear()
	_view_paths = null
	_choose_path = null


func _summary_by_id(hero_id: String) -> Dictionary:
	for summary: Dictionary in _roster_rows:
		if summary["hero_id"] == hero_id:
			return summary
	return {}


func _selected_can_promote() -> bool:
	var summary := _summary_by_id(_selected_hero_id)
	return not summary.is_empty() and bool(summary["can_promote"])


func _selected_choice() -> Dictionary:
	var options: Dictionary = _campaign.call("promotion_options", _selected_hero_id)
	if not bool(options.get("accepted", false)):
		return {}
	for choice: Dictionary in options["choices"]:
		if choice["advanced_class_id"] == _selected_choice_id:
			return choice
	return {}


func _eligibility_text(summary: Dictionary) -> String:
	if bool(summary["can_promote"]):
		return _t(&"ui.training.promotion_ready", "Promotion ready.")
	var code := StringName(summary["eligibility_error"])
	match code:
		&"hero_not_ready":
			return _t(&"ui.training.reason.dead", "Dead. Training unavailable.")
		&"insufficient_xp":
			return _fmt(
				&"ui.training.xp_needed", "Needs {remaining} XP.",
				{&"remaining": maxi(0, int(summary["xp_required"]) - int(summary["xp"]))},
			)
		&"wrong_source_class":
			return _t(&"ui.training.reason.no_path", "No advanced class path.")
		&"already_promoted":
			return _t(&"ui.training.reason.already_promoted", "Advanced training complete.")
	return _error_text(code)


func _role_text(role_id: String) -> String:
	if role_id == "healer_support":
		return _t(&"ui.training.role.healer_support", "Healer / Support")
	return _t(&"ui.training.role.damage_control", "Damage / Control")


func _status_text(life_status: String) -> String:
	if life_status == "ready":
		return _t(&"ui.training.status.ready", "READY")
	return _t(&"ui.training.status.dead", "DEAD")


func _skill_text(choice: Dictionary) -> String:
	var operator := load(
		"res://data/operators/%s.tres" % choice["operator_def_id"],
	) as OperatorDef
	if operator == null or operator.skill == null:
		return String(choice["skill_id"]).capitalize()
	if choice["skill_id"] == "mend":
		return _fmt(
			&"ui.training.skill.mend", "Mend — Heal one living ally for {amount} HP",
			{&"amount": int(operator.skill.params["amount"])},
		)
	return _t(
		&"ui.training.skill.tempest", "Tempest — Wide-range pressure attack",
	)


func _kit_text(choice_id: String) -> String:
	if choice_id == "witch_doctor":
		return _t(
			&"ui.training.kit.witch_doctor",
			"Kit: medicine, charge, repair tools.",
		)
	return _t(
		&"ui.training.kit.sorcerer",
		"Kit: conductors, weather rods, control marks.",
	)


func _error_text(error_code: StringName) -> String:
	var fallback := String(ERROR_FALLBACKS.get(
		error_code, "Training failed. Review the roster and try again.",
	))
	return _t(error_key(error_code), fallback)


func _focus_selected_row_or(fallback: Control) -> void:
	for row: TrainingRosterRowType in _roster_buttons:
		if row.hero_id == _selected_hero_id:
			row.grab_focus.call_deferred()
			return
	fallback.grab_focus.call_deferred()


func _focusable_controls() -> Array[Control]:
	var controls: Array[Control] = []
	for node: Node in _all_nodes(_page):
		if node is BaseButton:
			var button := node as BaseButton
			if button.visible and not button.disabled and button.focus_mode != Control.FOCUS_NONE:
				controls.append(button)
	return controls


func _wire_focus(controls: Array[Control], horizontal: bool) -> void:
	if controls.is_empty():
		return
	for index: int in controls.size():
		var current := controls[index]
		var previous := controls[(index - 1 + controls.size()) % controls.size()]
		var following := controls[(index + 1) % controls.size()]
		current.focus_previous = current.get_path_to(previous)
		current.focus_next = current.get_path_to(following)
		if horizontal:
			current.focus_neighbor_left = current.get_path_to(previous)
			current.focus_neighbor_right = current.get_path_to(following)
		else:
			current.focus_neighbor_top = current.get_path_to(previous)
			current.focus_neighbor_bottom = current.get_path_to(following)


func _all_nodes(root: Node) -> Array[Node]:
	var nodes: Array[Node] = [root]
	for child: Node in root.get_children():
		nodes.append_array(_all_nodes(child))
	return nodes


func _t(key: StringName, fallback: String) -> String:
	return UiCopyType.text(key, fallback)


func _fmt(key: StringName, fallback: String, args: Dictionary) -> String:
	return UiCopyType.format_text(key, fallback, args)
