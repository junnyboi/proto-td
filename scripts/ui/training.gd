class_name TrainingScreen
extends Control

const SHELL_SCENE := preload("res://scenes/ui/components/aetheria_screen_shell.tscn")
const AetheriaButtonType := preload("res://scripts/ui/components/aetheria_button.gd")
const AetheriaLabelType := preload("res://scripts/ui/components/aetheria_label.gd")
const AetheriaPanelType := preload("res://scripts/ui/components/aetheria_panel.gd")
const AetheriaScreenShellType := preload("res://scripts/ui/components/aetheria_screen_shell.gd")
const PromotionPathCardType := preload("res://scripts/ui/components/promotion_path_card.gd")
const TrainingRosterRowType := preload("res://scripts/ui/components/training_roster_row.gd")
const TrainingSupportType := preload("res://scripts/ui/components/training_support.gd")
const UiCopyType := preload("res://scripts/ui/components/ui_copy.gd")
const LunarisOpsType := preload("res://scripts/ui/components/lunaris_ops_style.gd")
const FactionHeraldryType := preload("res://scripts/ui/components/faction_heraldry.gd")
const BACKDROP := preload("res://assets/loading/lunaris_reliquary_loading.png")

const SHELL_SIZE := Vector2(1210.0, 660.0)
const COMPACT_SHELL_SIZE := Vector2(920.0, 680.0)
const PORTRAIT_SHELL_SIZE := Vector2(680.0, 1180.0)
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
	&"dead_hero": &"ui.training.error.dead_hero",
	&"premium_hero_untrainable": &"ui.training.error.premium_hero_untrainable",
	&"locked_class": &"ui.training.error.locked_class",
	&"already_promoted_class": &"ui.training.error.already_promoted_class",
	&"illegal_class_edge": &"ui.training.error.illegal_class_edge",
	&"missing_catalog": &"ui.training.error.missing_catalog",
	&"attempt_pending": &"ui.training.error.attempt_pending",
	&"store_write_failed": &"ui.training.error.store_write_failed",
	&"campaign_inactive": &"ui.training.error.campaign_inactive",
	&"malformed_hero_id": &"ui.training.error.invalid_request",
	&"malformed_command": &"ui.training.error.invalid_request",
	&"invalid_promotion_choice": &"ui.training.error.invalid_request",
	&"invalid_promotion_choices": &"ui.training.error.invalid_request",
	&"duplicate_hero_choice": &"ui.training.error.invalid_request",
	&"command_history_unavailable": &"ui.training.error.integrity",
	&"store_integrity_failure": &"ui.training.error.integrity",
	&"mutation_restore_mismatch": &"ui.training.error.integrity",
	&"duplicate_authority_mismatch": &"ui.training.error.integrity",
	&"invalid_runtime_mutation": &"ui.training.error.integrity",
	&"promotion_retry_pending": &"ui.training.error.save_pending",
	&"no_promotion_retry": &"ui.training.error.invalid_request",
	&"invalid_callsign": &"ui.rename.error.invalid",
	&"duplicate_callsign": &"ui.rename.error.duplicate",
	&"callsign_unchanged": &"ui.rename.error.unchanged",
	&"premium_name_locked": &"ui.rename.error.premium_locked",
	&"invalid_campaign_state": &"ui.training.error.integrity",
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
	&"dead_hero": "Dead recruits cannot train.",
	&"premium_hero_untrainable": "Premium heroes use fixed elite kits and cannot train.",
	&"locked_class": "This training path is not unlocked yet.",
	&"already_promoted_class": "No further training path is available.",
	&"illegal_class_edge": "That class is not a legal next duty.",
	&"missing_catalog": "Training records are incomplete.",
	&"attempt_pending": "Finish the active operation before training.",
	&"store_write_failed": "The campaign could not be saved.",
	&"campaign_inactive": "No active campaign is available.",
	&"command_history_unavailable": "Training records could not be authenticated.",
	&"store_integrity_failure": "The saved campaign could not be authenticated.",
	&"mutation_restore_mismatch": "The saved training result did not match the request.",
	&"duplicate_authority_mismatch": "The saved training receipt could not be authenticated.",
	&"invalid_runtime_mutation": "Training authority is unavailable.",
	&"promotion_retry_pending": "The previous save must be retried before leaving.",
	&"invalid_callsign": "Enter a name from 1 to 20 characters without control characters.",
	&"duplicate_callsign": "Another unit already uses that name.",
	&"callsign_unchanged": "Enter a different name.",
	&"premium_name_locked": "Premium hero names are fixed.",
	&"invalid_campaign_state": "The roster could not be authenticated.",
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
var _last_edited_hero_id := ""
var _draft: Dictionary = {}
var _view_paths: AetheriaButtonType
var _choose_path: AetheriaButtonType
var _review_confirm: AetheriaButtonType
var _review_error: AetheriaLabelType
var _return_mission: AetheriaButtonType
var _rename_row: BoxContainer
var _rename_input: LineEdit
var _rename_action: AetheriaButtonType
var _rename_error: AetheriaLabelType
var _rename_dispatching := false
var _confirmation_consumed := false
var _promotion_dispatch_count := 0


func _ready() -> void:
	_campaign = Game.campaign
	if not supports_campaign(_campaign):
		Game.open_staging()
		return
	Game.content = self
	_build_shell()
	_refresh_roster()
	_show_roster(_roster_projection_error())


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	get_viewport().set_input_as_handled()
	if _mode == &"review":
		_on_review_back()
	elif _mode == &"paths":
		_show_roster()
	else:
		_on_not_now()


static func supports_campaign(value: Variant) -> bool:
	return TrainingSupportType.supports_campaign(value)


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
	LunarisOpsType.add_backdrop(self, BACKDROP)
	_shell = SHELL_SCENE.instantiate() as AetheriaScreenShellType
	_shell.name = "ReliquaryAtelierShell"
	_shell.preferred_size = SHELL_SIZE
	add_child(_shell)
	_shell.layout_mode_changed.connect(_on_layout_mode_changed)
	(_shell.reading_plate() as PanelContainer).name = "TrainingShell"
	LunarisOpsType.apply_panel(_shell.reading_plate() as PanelContainer, &"screen")
	_page = VBoxContainer.new()
	_page.name = "TrainingPage"
	_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_page.add_theme_constant_override(&"separation", 16)
	_dialog_scroll = ScrollContainer.new()
	_dialog_scroll.name = "TrainingDialogScroll"
	var content_gutter := _shell.add_dialog_scroll(_dialog_scroll)
	content_gutter.add_child(_page)
	_layout_mode = _shell.layout_mode()
	_shell.preferred_size = _shell_size_for(_layout_mode)


func _refresh_roster() -> void:
	_campaign = Game.campaign
	_roster_rows = TrainingSupportType.roster(_campaign)
	if _selected_hero_id.is_empty() or _summary_by_id(_selected_hero_id).is_empty():
		_selected_hero_id = ""
		for summary: Dictionary in _roster_rows:
			if bool(summary["can_promote"]):
				_selected_hero_id = String(summary["hero_id"])
				break
		if _selected_hero_id.is_empty() and not _roster_rows.is_empty():
			_selected_hero_id = String(_roster_rows[0]["hero_id"])


func _show_roster(error_code: StringName = &"") -> void:
	_mode = &"roster"
	_selected_choice_id = ""
	_clear_page()
	_page.add_child(_header(
		"TrainingTitle", _t(&"ui.training.title", "TRAINING"),
			_t(&"ui.training.manage_personnel", "Manage callsigns and training paths."),
		))
	var roster_error: AetheriaLabelType = null
	if not String(error_code).is_empty():
		roster_error = _label(
			"TrainingRosterError", _error_text(error_code), &"dense_detail",
		)
		roster_error.focus_mode = Control.FOCUS_ALL
		_bind_focus_scroll(roster_error, _dialog_scroll)
		_page.add_child(roster_error)
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
		"TrainingBack", _t(&"ui.training.not_now", "Not Now"), true, &"secondary",
	)
	back.pressed.connect(_on_not_now)
	_view_paths = _button(
		"ViewPaths", _t(&"ui.training.view_paths", "View Paths"),
		_selected_can_promote(), &"primary" if _selected_can_promote() else &"disabled",
	)
	_view_paths.pressed.connect(_on_view_paths)
	var review := _button(
		"ReviewPlan", _t(&"ui.training.review_plan", "Review Plan"),
		not _draft.is_empty(), &"primary" if not _draft.is_empty() else &"disabled",
	)
	review.pressed.connect(_show_review)
	footer.add_child(back)
	footer.add_child(_view_paths)
	footer.add_child(review)
	_page.add_child(footer)
	_apply_roster_layout()
	_apply_footer_layouts()
	_reset_outer_scroll()
	_wire_focus(_focusable_controls(), false)
	if roster_error != null:
		roster_error.grab_focus.call_deferred()
	else:
		_focus_selected_row_or(back)


func _build_roster_list() -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.name = "TrainingRosterScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_stretch_ratio = 1.7
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(500.0, 250.0)
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
			_status_text(summary),
			_progress_text(summary),
				_eligibility_text(summary),
			)
		row.set_selected(String(summary["hero_id"]) == _selected_hero_id)
		row.pressed.connect(_on_roster_selected.bind(String(summary["hero_id"])))
		_bind_focus_scroll(row, scroll)
		list.add_child(row)
		_roster_buttons.append(row)
	return scroll


func _build_inspector() -> AetheriaPanelType:
	var panel := AetheriaPanelType.new()
	panel.name = "TrainingInspector"
	panel.apply_role(&"inspector")
	LunarisOpsType.apply_panel(panel, &"selected")
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio = 1.0
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.name = "InspectorColumn"
	column.add_theme_constant_override(&"separation", 12)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var inspector_scroll := ScrollContainer.new()
	inspector_scroll.name = "TrainingInspectorScroll"
	inspector_scroll.custom_minimum_size.y = 250.0
	inspector_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inspector_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inspector_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(inspector_scroll)
	inspector_scroll.add_child(column)
	column.add_child(_label("AtelierEyebrow", "SELECTED OPERATOR", &"eyebrow"))
	var selected := _summary_by_id(_selected_hero_id)
	if not selected.is_empty():
		column.add_child(_build_rename_panel(selected))
		var dossier := BoxContainer.new()
		dossier.name = "SelectedOperatorDossier"
		dossier.add_theme_constant_override(&"separation", 16)
		var portrait := TextureRect.new()
		portrait.name = "SelectedOperatorPortrait"
		portrait.texture = Art.texture(StringName(selected["portrait_asset_id"]))
		portrait.custom_minimum_size = Vector2(126.0, 160.0)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		dossier.add_child(portrait)
		var identity := VBoxContainer.new()
		identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		identity.add_theme_constant_override(&"separation", 6)
		identity.add_child(_label(
			"SelectedCallsign", String(selected["callsign"]).to_upper(), &"title",
		))
		identity.add_child(_label(
			"SelectedClass", class_label(String(selected["current_class_id"])).to_upper(),
			&"heading",
		))
		identity.add_child(_label(
			"SelectedContinuity", "SAME PERSON. NEW DUTY.", &"eyebrow",
		))
		if bool(selected.get("is_premium", false)):
			identity.add_child(_label(
				"SelectedPremiumStatus",
				"PREMIUM • FIXED ELITE KIT • %d %s" % [
					int(selected["premium_lives"]),
					"LIFE" if int(selected["premium_lives"]) == 1 else "LIVES",
				],
				&"metric",
			))
		else:
			var xp_bar := ProgressBar.new()
			xp_bar.name = "SelectedXpBar"
			xp_bar.max_value = int(selected["xp_required"])
			xp_bar.value = mini(int(selected["xp"]), int(selected["xp_required"]))
			xp_bar.show_percentage = false
			xp_bar.custom_minimum_size.y = 10.0
			LunarisOpsType.apply_progress(xp_bar)
			identity.add_child(xp_bar)
			identity.add_child(_label(
				"SelectedXp", "XP %d / %d" % [selected["xp"], selected["xp_required"]],
				&"metric",
			))
		dossier.add_child(identity)
		column.add_child(dossier)
	column.add_child(_label(
		"FieldRecordHeading", _t(&"ui.training.field_record", "FIELD RECORD"), &"heading",
	))
	column.add_child(_label(
		"TrainingExplainer",
		_t(
			&"ui.training.training_explainer",
			"Advanced training changes equipment, duties, and field role. It does not replace the person.",
		),
		&"detail",
	))
	if not selected.is_empty():
		column.add_child(_label(
			"SelectedRecruitStatus", _eligibility_text(selected).to_upper(), &"metric",
		))
	column.add_child(_label(
		"PermanenceNote", "PROMOTION CHANGES DUTY, EQUIPMENT, AND FIELD ROLE PERMANENTLY.",
		&"eyebrow",
	))
	return panel


func _build_rename_panel(summary: Dictionary) -> AetheriaPanelType:
	var panel := AetheriaPanelType.new()
	panel.name = "RenameUnitPanel"
	panel.apply_role(&"hud")
	LunarisOpsType.apply_panel(panel, &"quiet")
	var column := VBoxContainer.new()
	column.name = "RenameUnitColumn"
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override(&"separation", 8)
	column.add_child(_label(
		"RenameUnitHeading", _t(&"ui.rename.heading", "FIELD CALLSIGN"), &"heading",
	))
	if not bool(summary.get("can_rename", false)):
		var locked_key := (
			&"ui.rename.premium_locked"
			if bool(summary.get("is_premium", false))
			else &"ui.rename.not_ready"
		)
		var locked_fallback := (
			"Premium hero names are fixed."
			if bool(summary.get("is_premium", false))
			else "Only ready non-premium units can be renamed."
		)
		column.add_child(_label(
			"RenameUnitLocked", _t(locked_key, locked_fallback), &"dense_detail",
		))
		panel.add_child(column)
		return panel
	column.add_child(_label(
		"RenameUnitGuidance",
		_t(&"ui.rename.guidance", "Choose a unique name of 1–20 characters."),
		&"dense_detail",
	))
	_rename_row = BoxContainer.new()
	_rename_row.name = "RenameUnitControls"
	_rename_row.vertical = _layout_mode == &"portrait"
	_rename_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rename_row.add_theme_constant_override(&"separation", 10)
	_rename_input = LineEdit.new()
	_rename_input.name = "RenameUnitInput"
	_rename_input.text = String(summary["callsign"])
	_rename_input.placeholder_text = _t(&"ui.rename.placeholder", "Enter callsign")
	_rename_input.max_length = 20
	_rename_input.clear_button_enabled = true
	_rename_input.select_all_on_focus = true
	_rename_input.custom_minimum_size = Vector2(280.0, 58.0)
	_rename_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rename_input.text_changed.connect(_on_rename_text_changed)
	_rename_input.text_submitted.connect(_on_rename_submitted)
	LunarisOpsType.apply_line_edit(_rename_input)
	_bind_focus_scroll(_rename_input, _dialog_scroll)
	_rename_row.add_child(_rename_input)
	_rename_action = _button(
		"RenameUnitAction", _t(&"ui.rename.action", "Rename"), false, &"disabled",
	)
	_rename_action.custom_minimum_size = Vector2(180.0, 58.0)
	_rename_action.pressed.connect(_submit_rename)
	_rename_row.add_child(_rename_action)
	column.add_child(_rename_row)
	_rename_error = _label("RenameUnitError", "", &"dense_detail")
	_rename_error.custom_minimum_size.y = 24.0
	column.add_child(_rename_error)
	panel.add_child(column)
	return panel


func _on_rename_text_changed(value: String) -> void:
	if _rename_error != null:
		_rename_error.text = ""
	if _rename_input != null:
		LunarisOpsType.apply_line_edit(_rename_input)
	var summary := _summary_by_id(_selected_hero_id)
	var candidate := value.strip_edges()
	var enabled := (
		not _rename_dispatching
		and not summary.is_empty()
		and bool(summary.get("can_rename", false))
		and not candidate.is_empty()
		and candidate.length() <= 20
		and candidate != String(summary["callsign"])
	)
	if _rename_action != null:
		_rename_action.disabled = not enabled
		_rename_action.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
		LunarisOpsType.apply_button(
			_rename_action, &"primary" if enabled else &"disabled",
		)


func _on_rename_submitted(_value: String) -> void:
	_submit_rename()


func _submit_rename() -> void:
	if _rename_dispatching or _rename_input == null or _rename_action == null:
		return
	if _rename_action.disabled:
		return
	_rename_dispatching = true
	_rename_action.disabled = true
	_rename_action.focus_mode = Control.FOCUS_NONE
	LunarisOpsType.apply_button(_rename_action, &"disabled")
	var committed: Dictionary = Game.rename_hero(_selected_hero_id, _rename_input.text)
	_rename_dispatching = false
	if not committed["accepted"]:
		var error_code := StringName(committed.get("error_code", &"invalid_callsign"))
		_rename_error.text = _error_text(error_code)
		LunarisOpsType.apply_line_edit(_rename_input, true)
		_on_rename_text_changed(_rename_input.text)
		_rename_error.text = _error_text(error_code)
		_rename_input.grab_focus.call_deferred()
		return
	_refresh_roster()
	_show_roster()


func _show_paths() -> void:
	var options: Dictionary = TrainingSupportType.options(_campaign, _selected_hero_id)
	if not bool(options.get("accepted", false)):
		_show_roster(StringName(options.get("error_code", &"missing_catalog")))
		return
	_mode = &"paths"
	_clear_page()
	var summary := _summary_by_id(_selected_hero_id)
	_page.add_child(_header(
		"ChooseTrainingTitle",
			_t(&"ui.training.choose_advanced", "CHOOSE TRAINING PATH"),
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
		card.name = "Path_%s" % choice["to_class_id"]
		card.configure(
			choice,
			_t(StringName(choice["class_name_key"]), String(choice["class_name_fallback"])),
			_t(StringName(choice["role_key"]), String(choice["role_fallback"])),
			_t(
				StringName(choice["description_key"]),
				String(choice["description_fallback"]),
			),
			_skill_text(choice),
			_combat_text(choice),
			_t(&"ui.training.class_kit_placeholder", "CLASS KIT"),
			_t(
				&"ui.training.field_kit",
				"FIELD KIT • EQUIPMENT ISSUED AFTER CONFIRMATION",
			),
		)
		card.pressed.connect(
			_on_path_selected.bind(String(choice["to_class_id"])),
		)
		_bind_focus_scroll(card, scroll, card.focus_visibility_target())
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
		"ChoosePath", _t(&"ui.training.add_to_plan", "Add to Plan"),
		false, &"disabled",
	)
	_choose_path.pressed.connect(_add_selected_choice)
	footer.add_child(back)
	footer.add_child(_choose_path)
	_page.add_child(footer)
	_apply_paths_layout()
	_apply_footer_layouts()
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


func _on_roster_selected(hero_id: String) -> void:
	_selected_hero_id = hero_id
	_show_roster()


func _add_selected_choice() -> void:
	if _selected_hero_id.is_empty() or _selected_choice_id.is_empty():
		return
	_draft[_selected_hero_id] = _selected_choice_id
	_last_edited_hero_id = _selected_hero_id
	_show_roster()


func _show_review(error_code: StringName = &"", removed_rows: Array = []) -> void:
	if _draft.is_empty() and String(error_code).is_empty():
		_show_roster()
		return
	_mode = &"review"
	_clear_page()
	_page.add_child(_header(
		"ReviewTrainingTitle",
		_t(&"ui.training.review_title", "REVIEW TRAINING PLAN"),
		_t(
			&"ui.training.confirm_permanent",
			"These training choices cannot be changed.",
		),
	))
	var list := VBoxContainer.new()
	list.name = "TrainingReviewList"
	list.add_theme_constant_override(&"separation", 10)
	_page.add_child(list)
	for summary: Dictionary in _roster_rows:
		var hero_id := String(summary["hero_id"])
		if not _draft.has(hero_id):
			continue
		var entry := _label(
			"Review_%s" % hero_id,
			_fmt(
				&"ui.training.review_entry", "{callsign} to {class_name}",
				{
					&"callsign": String(summary["callsign"]),
					&"class_name": class_label(String(_draft[hero_id])),
				},
			),
			&"dense_body",
		)
		list.add_child(entry)
	if not removed_rows.is_empty():
		list.add_child(_label(
			"RemovedAssignmentsHeading",
			_t(&"ui.training.removed_heading", "REMOVED AFTER ROSTER REFRESH"),
			&"dense_heading",
		))
		for raw: Variant in removed_rows:
			var removed := raw as Dictionary
			list.add_child(_label(
				"Removed_%s" % removed["hero_id"],
				_fmt(
					&"ui.training.removed_entry",
					"{callsign} to {class_name}: {reason}",
					{
						&"callsign": String(removed["callsign"]),
						&"class_name": class_label(String(removed["to_class_id"])),
						&"reason": _error_text(StringName(removed["error_code"])),
					},
				),
				&"dense_body",
			))
	_review_error = _label("TrainingReviewError", "", &"dense_detail")
	_review_error.focus_mode = Control.FOCUS_ALL
	_bind_focus_scroll(_review_error, _dialog_scroll)
	if not String(error_code).is_empty():
		_review_error.text = _error_text(error_code)
	_page.add_child(_review_error)
	var pending := bool(Game.training_call(&"retry_pending"))
	var footer := _footer("ReviewActions")
	var back := _button(
		"ReviewBack", _t(&"ui.common.back", "Back"), not pending,
		&"secondary" if not pending else &"disabled",
	)
	back.pressed.connect(_on_review_back)
	_review_confirm = _button(
		"ConfirmTraining",
		_t(&"ui.training.confirm_action", "Confirm Training"),
		not _draft.is_empty(),
		&"primary" if not _draft.is_empty() else &"disabled",
	)
	_review_confirm.custom_minimum_size.x = 320.0
	_review_confirm.pressed.connect(_confirm_review)
	footer.add_child(back)
	footer.add_child(_review_confirm)
	_page.add_child(footer)
	_apply_footer_layouts()
	_reset_outer_scroll()
	_wire_focus(_focusable_controls(), false)
	if not String(error_code).is_empty():
		_review_error.grab_focus.call_deferred()
	else:
		_review_confirm.grab_focus.call_deferred()


func _on_review_back() -> void:
	if bool(Game.training_call(&"retry_pending")):
		return
	var hero_id := _last_edited_hero_id
	if hero_id.is_empty() or not _draft.has(hero_id):
		_show_roster()
		return
	_selected_hero_id = hero_id
	var choice_id := String(_draft[hero_id])
	_show_paths()
	_on_path_selected(choice_id)


func _confirm_review() -> void:
	if _confirmation_consumed or _draft.is_empty():
		return
	_confirmation_consumed = true
	_review_confirm.disabled = true
	_review_confirm.focus_mode = Control.FOCUS_NONE
	_promotion_dispatch_count += 1
	var committed: Dictionary = (
		Game.training_call(&"retry")
		if bool(Game.training_call(&"retry_pending"))
		else Game.training_call(&"commit", _draft_choices())
	)
	if not committed["accepted"]:
		_confirmation_consumed = false
		var removed_rows: Array = []
		if not bool(Game.training_call(&"retry_pending")):
			removed_rows = _reconcile_draft()
		_show_review(
			StringName(committed.get("error_code", &"unknown_error")), removed_rows,
		)
		return
	_confirmation_consumed = false
	Game.open_staging()


func _draft_choices() -> Array[Dictionary]:
	var choices: Array[Dictionary] = []
	for hero_id: String in _draft:
		choices.append(
			{
				"hero_id": hero_id,
				"to_class_id": String(_draft[hero_id]),
			}
		)
	choices.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return String(a["hero_id"]) < String(b["hero_id"])
	)
	return choices


func _reconcile_draft() -> Array:
	var previous_rows := {}
	for summary: Dictionary in _roster_rows:
		previous_rows[String(summary["hero_id"])] = summary.duplicate(true)
	_refresh_roster()
	var retained := {}
	var removed: Array[Dictionary] = []
	for hero_id: String in _draft:
		var options := TrainingSupportType.options(_campaign, hero_id)
		var retained_choice := false
		for choice: Dictionary in options["choices"]:
			if String(choice["to_class_id"]) == String(_draft[hero_id]):
				retained[hero_id] = _draft[hero_id]
				retained_choice = true
		if retained_choice:
			continue
		var summary: Dictionary = previous_rows.get(hero_id, {})
		var removal_error := StringName(options.get("error_code", &"invalid_choice"))
		if String(removal_error).is_empty():
			removal_error = &"invalid_choice"
		removed.append({
			"hero_id": hero_id,
			"callsign": String(summary.get("callsign", hero_id)),
			"to_class_id": String(_draft[hero_id]),
			"error_code": removal_error,
		})
	_draft = retained
	return removed


func _on_not_now() -> void:
	if bool(Game.training_call(&"retry_pending")):
		return
	Sfx.play("ui_click")
	Game.training_call(&"leave")


func _on_view_paths() -> void:
	if _selected_can_promote():
		_show_paths()


func _on_path_selected(choice_id: String) -> void:
	_selected_choice_id = choice_id
	for card: PromotionPathCardType in _path_cards:
		card.set_selected(card.class_id == choice_id)
	_choose_path.disabled = false
	_choose_path.focus_mode = Control.FOCUS_ALL
	_choose_path.apply_role(&"primary")
	_wire_focus(_focusable_controls(), _layout_mode != &"portrait")


func _on_layout_mode_changed(value: StringName) -> void:
	_layout_mode = value
	var target_size := _shell_size_for(value)
	if _shell.preferred_size != target_size:
		_shell.preferred_size = target_size
	if _mode == &"paths":
		_apply_paths_layout()
	elif _mode == &"roster":
		_apply_roster_layout()
	_apply_footer_layouts()
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
	var scroll := body.get_node_or_null("TrainingRosterScroll") as ScrollContainer
	if scroll != null:
		scroll.custom_minimum_size.y = 300.0 if _layout_mode == &"portrait" else 250.0
	for row: TrainingRosterRowType in _roster_buttons:
		row.set_compact(_layout_mode != &"regular_landscape")
	if _rename_row != null:
		_rename_row.vertical = _layout_mode == &"portrait"


func _apply_paths_layout() -> void:
	var cards := _page.get_node_or_null("PathCardsScroll/PathCards") as BoxContainer
	if cards == null:
		return
	var scroll := cards.get_parent() as ScrollContainer
	cards.vertical = _layout_mode != &"regular_landscape" or _path_cards.size() > 2
	scroll.custom_minimum_size.y = (
		580.0 if _layout_mode == &"portrait" else 540.0
	)
	for card: PromotionPathCardType in _path_cards:
		card.set_compact(_layout_mode == &"portrait")
		card.fit_to_content()


func _reset_outer_scroll() -> void:
	if _dialog_scroll == null:
		return
	_dialog_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_dialog_scroll.scroll_vertical = 0


func _header(node_name: String, title: String, subtitle: String) -> VBoxContainer:
	var header := VBoxContainer.new()
	header.name = node_name
	header.add_theme_constant_override(&"separation", 8)
	var top := BoxContainer.new()
	top.name = "%sTop" % node_name
	top.add_theme_constant_override(&"separation", 16)
	var identity := HBoxContainer.new()
	identity.name = "%sFactionIdentity" % node_name
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override(&"separation", 12)
	var symbol := FactionHeraldryType.make_symbol(FactionHeraldryType.ACTIVE_FACTION, 48.0)
	symbol.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	identity.add_child(symbol)
	var title_block := VBoxContainer.new()
	title_block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_block.add_theme_constant_override(&"separation", 0)
	title_block.add_child(_label("%sEyebrow" % node_name, "RELIQUARY ATELIER", &"eyebrow"))
	title_block.add_child(_label("%sHeading" % node_name, title.to_upper(), &"title"))
	identity.add_child(title_block)
	top.add_child(identity)
	if Game.training_return_path == &"mission":
		_return_mission = _button(
			"ReturnToMission", "<- RETURN TO MISSION", true, &"gold",
		)
		_return_mission.custom_minimum_size = Vector2(230.0, 58.0)
		_return_mission.pressed.connect(_on_not_now)
		top.add_child(_return_mission)
	header.add_child(top)
	header.add_child(_label("%sSubtitle" % node_name, subtitle, &"detail"))
	return header


func _footer(node_name: String) -> BoxContainer:
	var footer := BoxContainer.new()
	footer.name = node_name
	footer.vertical = _layout_mode == &"portrait"
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
	button.set_presentation_text(button_text, button_text)
	LunarisOpsType.apply_button(button, role)
	_bind_focus_scroll(button, _dialog_scroll)
	var presentation := button.get_node("PresentationLabel") as AetheriaLabelType
	LunarisOpsType.apply_label(presentation, &"body")
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
	match role:
		&"dense_heading":
			LunarisOpsType.apply_label(label, &"heading")
		&"dense_body":
			LunarisOpsType.apply_label(label, &"body")
		&"dense_detail":
			LunarisOpsType.apply_label(label, &"detail")
		_:
			LunarisOpsType.apply_label(label, role)
	return label


func _clear_page() -> void:
	for child: Node in _page.get_children():
		_page.remove_child(child)
		child.queue_free()
	_roster_buttons.clear()
	_path_cards.clear()
	_view_paths = null
	_choose_path = null
	_review_confirm = null
	_review_error = null
	_return_mission = null
	_rename_row = null
	_rename_input = null
	_rename_action = null
	_rename_error = null
	_rename_dispatching = false


func _summary_by_id(hero_id: String) -> Dictionary:
	for summary: Dictionary in _roster_rows:
		if summary["hero_id"] == hero_id:
			return summary
	return {}


func _selected_can_promote() -> bool:
	var summary := _summary_by_id(_selected_hero_id)
	return not summary.is_empty() and bool(summary["can_promote"])


func _roster_projection_error() -> StringName:
	for summary: Dictionary in _roster_rows:
		if bool(summary.get("model_can_promote", false)) and not bool(summary["can_promote"]):
			return StringName(summary.get("eligibility_error", &"missing_catalog"))
	return &""


func _selected_choice() -> Dictionary:
	var options: Dictionary = TrainingSupportType.options(_campaign, _selected_hero_id)
	if not bool(options.get("accepted", false)):
		return {}
	for choice: Dictionary in options["choices"]:
		if choice["to_class_id"] == _selected_choice_id:
			return choice
	return {}


func _eligibility_text(summary: Dictionary) -> String:
	var hero_id := String(summary["hero_id"])
	if _draft.has(hero_id):
		return _fmt(
			&"ui.training.draft_choice", "Planned: {class_name}",
			{&"class_name": class_label(String(_draft[hero_id]))},
		)
	if bool(summary["can_promote"]):
		return _t(&"ui.training.promotion_ready", "Promotion ready.")
	var code := StringName(summary["eligibility_error"])
	var result := ""
	match code:
		&"hero_not_ready":
			result = _t(&"ui.training.reason.dead", "Dead. Training unavailable.")
		&"insufficient_xp":
			result = _fmt(
				&"ui.training.xp_needed", "Needs {remaining} XP.",
				{&"remaining": maxi(0, int(summary["xp_required"]) - int(summary["xp"]))},
			)
		&"wrong_source_class":
			result = _t(&"ui.training.reason.no_path", "No advanced class path.")
		&"already_promoted":
			result = _t(
				&"ui.training.reason.already_promoted", "Advanced training complete.",
			)
		&"dead_hero":
			result = _t(&"ui.training.reason.dead", "Dead. Training unavailable.")
		&"premium_hero_untrainable":
			result = _t(
				&"ui.training.reason.premium",
				"Premium hero. Fixed elite kit; training unavailable.",
			)
		&"locked_class":
			result = _t(
				&"ui.training.error.locked_class", "This training path is not unlocked yet.",
			)
		&"already_promoted_class":
			result = _t(
				&"ui.training.error.already_promoted_class",
				"No further training path is available.",
			)
		_:
			result = _error_text(code)
	return result


func _status_text(summary: Dictionary) -> String:
	var life_status := String(summary["life_status"])
	if bool(summary.get("is_premium", false)):
		return "PREMIUM READY" if life_status == "ready" else "PREMIUM LOCKED"
	if life_status == "ready":
		return _t(&"ui.training.status.ready", "READY")
	return _t(&"ui.training.status.dead", "DEAD")


func _progress_text(summary: Dictionary) -> String:
	if bool(summary.get("is_premium", false)):
		var lives := int(summary["premium_lives"])
		return "FIXED KIT • %d %s" % [lives, "LIFE" if lives == 1 else "LIVES"]
	return _fmt(
		&"ui.training.xp_progress", "XP {current} / {required}",
		{&"current": int(summary["xp"]), &"required": int(summary["xp_required"])},
	)


func _combat_text(choice: Dictionary) -> String:
	var placement := _t(
		&"ui.training.placement.elevated",
		"Elevated",
	) if int(choice["placement"]) == OperatorDef.Placement.ELEVATED else _t(
		&"ui.training.placement.ground",
		"Ground",
	)
	return _fmt(
		&"ui.training.combat_facts",
		"{cost} DP • {placement} • Block {block} • Range {range} • ATK {cadence}T",
		{
			&"cost": int(choice["dp_cost"]),
			&"placement": placement,
			&"block": int(choice["block"]),
			&"range": int(choice["range_cells"]),
			&"cadence": int(choice["attack_interval_ticks"]),
		},
	)


func _skill_text(choice: Dictionary) -> String:
	return _fmt(
		&"ui.training.skill_facts", "Skill: {skill}",
		{&"skill": String(choice.get("skill_name", "None"))},
	)


func _apply_footer_layouts() -> void:
	for node: Node in _all_nodes(_page):
		if node is BoxContainer and String(node.name).ends_with("Actions"):
			var footer := node as BoxContainer
			footer.vertical = _layout_mode == &"portrait"
			var actions: Array[Control] = []
			for child: Node in footer.get_children():
				if child is AetheriaButtonType:
					actions.append(child as Control)
			var available := maxf(
				44.0, maxf(_page.size.x, _shell.preferred_size.x - 64.0),
			)
			var visible_width := get_viewport_rect().size.x - _page.global_position.x - 8.0
			if visible_width >= 44.0:
				available = minf(available, visible_width)
			if not footer.vertical and not actions.is_empty():
				available = maxf(
					44.0,
					(available - footer.get_theme_constant(&"separation")
					* (actions.size() - 1)) / actions.size(),
				)
			for action: Control in actions:
				action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				(action as AetheriaButtonType).fit_presentation(
					available, 240.0, 64.0,
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
		elif node is LineEdit:
			var field := node as LineEdit
			if field.visible and field.editable and field.focus_mode != Control.FOCUS_NONE:
				controls.append(field)
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


func _bind_focus_scroll(
	control: Control, scroll: ScrollContainer, visibility_target: Control = null,
) -> void:
	if control == null or scroll == null:
		return
	var target := visibility_target if visibility_target != null else control
	control.focus_entered.connect(
		_ensure_focus_visible.bind(scroll, _dialog_scroll, target),
	)


func _ensure_focus_visible(
	scroll: ScrollContainer, outer_scroll: ScrollContainer, control: Control,
) -> void:
	if not is_instance_valid(scroll) or not is_instance_valid(control):
		return
	scroll.ensure_control_visible(control)
	if scroll != outer_scroll and is_instance_valid(outer_scroll):
		outer_scroll.call_deferred("ensure_control_visible", control)


func _all_nodes(root: Node) -> Array[Node]:
	var nodes: Array[Node] = [root]
	for child: Node in root.get_children():
		nodes.append_array(_all_nodes(child))
	return nodes


func _t(key: StringName, fallback: String) -> String:
	return UiCopyType.text(key, fallback)


func _fmt(key: StringName, fallback: String, args: Dictionary) -> String:
	return UiCopyType.format_text(key, fallback, args)
