class_name TrainingScreen
extends Control

signal rename_confirmation_presentation_changed(state: StringName)
signal rename_confirmation_transition_completed(state: StringName)

const SHELL_SCENE := preload("res://scenes/ui/components/aetheria_screen_shell.tscn")
const AetheriaButtonType := preload("res://scripts/ui/components/aetheria_button.gd")
const AetheriaLabelType := preload("res://scripts/ui/components/aetheria_label.gd")
const AetheriaPanelType := preload("res://scripts/ui/components/aetheria_panel.gd")
const AetheriaScreenShellType := preload("res://scripts/ui/components/aetheria_screen_shell.gd")
const PromotionPathCardType := preload("res://scripts/ui/components/promotion_path_card.gd")
const TrainingRosterRowType := preload("res://scripts/ui/components/training_roster_row.gd")
const PremiumPortraitEntranceType := preload("res://scripts/ui/components/premium_portrait_entrance.gd")
const TrainingSupportType := preload("res://scripts/ui/components/training_support.gd")
const HeroCodecScript := preload("res://sim/campaign_hero_codec.gd")
const UiCopyType := preload("res://scripts/ui/components/ui_copy.gd")
const LunarisOpsType := preload("res://scripts/ui/components/lunaris_ops_style.gd")
const FactionHeraldryType := preload("res://scripts/ui/components/faction_heraldry.gd")
const RosterFilterType := preload("res://scripts/ui/components/roster_filter.gd")
const RosterFilterBarType := preload("res://scripts/ui/components/roster_filter_bar.gd")
const RosterGridLayoutType := preload("res://scripts/ui/components/roster_grid_layout.gd")
const BACKDROP := preload("res://assets/loading/lunaris_reliquary_loading.png")

enum RenameConfirmationState {
	INACTIVE,
	ACTIVE,
	COMMITTING,
}

enum RenamePresentationState {
	IDLE,
	ENTERING,
	ACTIVE,
	EXITING,
}

const SHELL_SIZE := Vector2(1210.0, 660.0)
const COMPACT_SHELL_SIZE := Vector2(920.0, 680.0)
const PORTRAIT_SHELL_SIZE := Vector2(680.0, 1180.0)
const TRAINING_FONT_SIZES := {
	&"eyebrow": 24,
	&"title": 60,
	&"heading": 36,
	&"body": 30,
	&"detail": 26,
	&"metric": 33,
	&"dense_heading": 33,
	&"dense_body": 27,
	&"dense_detail": 24,
}
const RENAME_ENTRY_SECONDS := 0.20
const RENAME_EXIT_SECONDS := 0.16
const RENAME_VERTICAL_OFFSET := 10.0
const PATH_CARD_SIZE := Vector2(680.0, 450.0)
const PATH_CARD_PORTRAIT_SIZE := Vector2(600.0, 450.0)
const PATH_CARD_GAP := 24.0
const PATH_SCREEN_GUTTER := 60
const PATH_SCREEN_GUTTER_PORTRAIT := 24
const PATH_ACTION_SIZE := Vector2(260.0, 84.0)
const PATH_ACTION_PADDING_HORIZONTAL := 24.0
const PATH_ACTION_PADDING_VERTICAL := 12.0
const ROSTER_CARD_WIDTH := 560.0
const ROSTER_GRID_GAP := 16
const ROSTER_SCROLL_EXTRA := 24.0
const ROSTER_MAX_COLUMNS := 2
const ROSTER_INSPECTOR_MIN_WIDTH := 580.0
const ROSTER_LANDSCAPE_SEPARATION := 64.0
const INSPECTOR_GOLD := Color("d9b96e")
const IDENTITY_INPUT_FONT_SIZE := 34
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
	&"invalid_title": &"ui.rename.error.invalid_title",
	&"duplicate_callsign": &"ui.rename.error.duplicate",
	&"callsign_unchanged": &"ui.rename.error.unchanged",
	&"identity_unchanged": &"ui.rename.error.identity_unchanged",
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
	&"invalid_title": "Enter a title up to 24 characters without control characters.",
	&"duplicate_callsign": "Another unit already uses that name.",
	&"callsign_unchanged": "Enter a different name.",
	&"identity_unchanged": "Change the name or title before continuing.",
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
var _content_gutter: MarginContainer
var _workspace: VBoxContainer
var _persistent_header: VBoxContainer
var _action_dock: VBoxContainer
var _mode: StringName = &"roster"
var _layout_mode: StringName = &"regular_landscape"
var _roster_rows: Array[Dictionary] = []
var _roster_buttons: Array[TrainingRosterRowType] = []
var _filter_bar: RosterFilterBarType = null
var _filter_status: StringName = RosterFilterType.STATUS_ACTIVE
var _filter_faction: StringName = RosterFilterType.FACTION_ALL
var _identity_editor_open := false
var _roster_list: GridContainer
var _roster_scroll: ScrollContainer
var _inspector_scroll: ScrollContainer
var _roster_controls: BoxContainer
var _filter_toolbar: BoxContainer
var _filter_input: LineEdit
var _sort_select: OptionButton
var _filter_summary: AetheriaLabelType
var _name_filter := ""
var _name_sort: StringName = &"recruitment"
var _path_cards: Array[PromotionPathCardType] = []
var _path_cards_scroll: ScrollContainer = null
var _selected_hero_id := ""
var _selected_choice_id := ""
var _last_edited_hero_id := ""
var _draft: Dictionary = {}
var _choose_path: AetheriaButtonType
var _review_confirm: AetheriaButtonType
var _review_error: AetheriaLabelType
var _return_mission: AetheriaButtonType
var _rename_row: BoxContainer
var _rename_input: LineEdit
var _rename_title_input: LineEdit
var _rename_action: AetheriaButtonType
var _rename_error: AetheriaLabelType
var _rename_comparison: BoxContainer
var _rename_cancel: AetheriaButtonType
var _rename_confirm: AetheriaButtonType
var _rename_status: AetheriaLabelType
var _identity_edit_draft: Dictionary = {}
var _pending_identity: Dictionary = {}
var _rename_state := RenameConfirmationState.INACTIVE
var _rename_presentation_state := RenamePresentationState.IDLE
var _rename_presentation_tween: Tween = null
var _rename_presentation_generation := 0
var _rename_presentation_origin := Vector2.ZERO
var _rename_exit_reason: StringName = &""
var _rename_exit_error: StringName = &""
var _rename_editor_error: StringName = &""
var _rename_dispatch_count := 0
var _confirmation_consumed := false
var _promotion_dispatch_count := 0
var _viewport_layout_refresh_queued := false


func _ready() -> void:
	_campaign = Game.campaign
	if not supports_campaign(_campaign):
		Game.open_staging()
		return
	Game.content = self
	_build_shell()
	resized.connect(_on_viewport_resized)
	I18n.locale_changed.connect(_on_locale_changed)
	if TextScale != null and not TextScale.scale_changed.is_connected(_on_text_scale_changed):
		TextScale.scale_changed.connect(_on_text_scale_changed)
	_refresh_roster()
	_show_roster(_roster_projection_error())


func _exit_tree() -> void:
	_kill_rename_presentation_transition(false)


func _unhandled_input(event: InputEvent) -> void:
	if _mode == &"rename_confirmation":
		var accept_pressed := event.is_action_pressed("ui_accept")
		var cancel_pressed := event.is_action_pressed("ui_cancel")
		if not accept_pressed and not cancel_pressed:
			return
		if rename_transition_locked() or _rename_state == RenameConfirmationState.COMMITTING:
			# Cancel during entry is deliberately consumed until the modal is ACTIVE.
			# This avoids reversing a tree that is still settling or dispatching a rename.
			get_viewport().set_input_as_handled()
			return
		if cancel_pressed:
			get_viewport().set_input_as_handled()
			_cancel_rename()
		return
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
	_shell.full_safe_area = true
	add_child(_shell)
	_shell.layout_mode_changed.connect(_on_layout_mode_changed)
	(_shell.reading_plate() as PanelContainer).name = "TrainingShell"
	LunarisOpsType.apply_panel(_shell.reading_plate() as PanelContainer, &"screen")
	_page = VBoxContainer.new()
	_page.name = "TrainingPage"
	_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_page.add_theme_constant_override(&"separation", 12)
	_dialog_scroll = ScrollContainer.new()
	_dialog_scroll.name = "TrainingDialogScroll"
	_content_gutter = _shell.add_dialog_scroll(_dialog_scroll)
	_content_gutter.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_gutter.add_theme_constant_override(&"margin_left", 6)
	_content_gutter.add_theme_constant_override(&"margin_top", 4)
	_content_gutter.add_theme_constant_override(&"margin_bottom", 4)
	_content_gutter.add_child(_page)
	var content_host := _shell.content_host()
	content_host.remove_child(_dialog_scroll)
	accessibility_name = _t(&"ui.training.accessibility.name", "Training workspace")
	accessibility_description = _t(
		&"ui.training.accessibility.description",
		"Manage operator identities and advanced training paths.",
	)
	_workspace = VBoxContainer.new()
	_workspace.name = "TrainingWorkspace"
	_workspace.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_workspace.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_workspace.add_theme_constant_override(&"separation", 12)
	_workspace.accessibility_name = _t(
		&"ui.training.accessibility.workspace", "Training content",
	)
	_workspace.accessibility_description = accessibility_description
	content_host.add_child(_workspace)
	_persistent_header = VBoxContainer.new()
	_persistent_header.name = "TrainingPersistentHeader"
	_persistent_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_persistent_header.visible = false
	_persistent_header.accessibility_name = _t(
		&"ui.training.accessibility.header", "Training heading",
	)
	_persistent_header.accessibility_description = _t(
		&"ui.training.accessibility.header_description",
		"Persistent context for the current Training task.",
	)
	_workspace.add_child(_persistent_header)
	_workspace.add_child(_dialog_scroll)
	_action_dock = VBoxContainer.new()
	_action_dock.name = "TrainingActionDock"
	_action_dock.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_action_dock.accessibility_name = _t(
		&"ui.training.accessibility.actions", "Training actions",
	)
	_action_dock.accessibility_description = _t(
		&"ui.training.accessibility.actions_description",
		"Persistent actions for the current Training task.",
	)
	_workspace.add_child(_action_dock)
	_layout_mode = _shell.layout_mode()
	_shell.preferred_size = _shell_size_for(_layout_mode)


func _refresh_roster() -> void:
	_campaign = Game.campaign
	_roster_rows = RosterFilterType.annotate_all(TrainingSupportType.roster(_campaign))
	if _selected_hero_id.is_empty() or _summary_by_id(_selected_hero_id).is_empty():
		_select_first_visible()


func _show_roster(error_code: StringName = &"") -> void:
	_mode = &"roster"
	_selected_choice_id = ""
	_clear_page()
	_set_persistent_header(null)
	var roster_header := _header(
		"TrainingTitle", _t(&"ui.training.title", "TRAINING"),
		"",
		)
	_page.add_child(roster_header)
	var roster_error: AetheriaLabelType = null
	if not String(error_code).is_empty():
		roster_error = _label(
			"TrainingRosterError", _error_text(error_code), &"dense_detail",
		)
		roster_error.focus_mode = Control.FOCUS_ALL
		_bind_focus_scroll(roster_error, _dialog_scroll)
		_page.add_child(roster_error)
	_roster_controls = BoxContainer.new()
	_roster_controls.name = "TrainingRosterControls"
	_roster_controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_roster_controls.add_theme_constant_override(&"separation", 12)
	_page.add_child(_roster_controls)
	_filter_bar = RosterFilterBarType.new()
	_filter_bar.configure(
		_roster_rows, true, _filter_status, _filter_faction, true,
	)
	_filter_bar.set_generous_spacing(true)
	_filter_bar.set_compact(_layout_mode != &"portrait")
	_filter_bar.set_inline(false)
	_filter_bar.size_flags_stretch_ratio = 1.22
	_filter_bar.filters_changed.connect(_on_filters_changed)
	_roster_controls.add_child(_filter_bar)
	var identity_toolbar := _build_identity_filter_toolbar()
	_filter_bar.attach_auxiliary_control(identity_toolbar)
	var body := BoxContainer.new()
	body.name = "TrainingRosterBody"
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override(
		&"separation", 16 if _layout_mode == &"portrait" else 64,
	)
	body.resized.connect(_on_roster_body_resized)
	_page.add_child(body)
	body.add_child(_build_roster_list())
	body.add_child(_build_inspector())
	var footer := _footer("RosterActions")
	var back := _button(
		"TrainingBack", _t(&"ui.training.not_now", "Not Now"), true, &"secondary",
	)
	back.pressed.connect(_on_not_now)
	var review := _button(
		"ReviewPlan", _t(&"ui.training.review_plan", "Review Plan"),
		not _draft.is_empty(), &"primary" if not _draft.is_empty() else &"disabled",
	)
	review.pressed.connect(_show_review)
	footer.add_child(back)
	footer.add_child(review)
	_set_action_footer(footer)
	_apply_roster_layout()
	_apply_footer_layouts()
	_reset_outer_scroll()
	_wire_focus(_focusable_controls(), false)
	var focus_generation := _rename_presentation_generation
	if roster_error != null:
		_focus_roster_control_guarded.call_deferred(roster_error, focus_generation)
	else:
		_focus_selected_row_or.call_deferred(back, focus_generation)


func _build_identity_filter_toolbar() -> BoxContainer:
	_filter_toolbar = BoxContainer.new()
	_filter_toolbar.name = "TrainingIdentityToolbar"
	_filter_toolbar.vertical = _layout_mode == &"portrait"
	_filter_toolbar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_filter_toolbar.add_theme_constant_override(&"separation", 10)
	_filter_input = LineEdit.new()
	_filter_input.name = "TrainingNameFilter"
	_filter_input.text = _name_filter
	_filter_input.placeholder_text = _t(
		&"ui.identity_filter.placeholder", "Filter operators",
	)
	_filter_input.clear_button_enabled = true
	_filter_input.custom_minimum_size = Vector2(220.0, 72.0)
	_filter_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	LunarisOpsType.apply_line_edit(_filter_input)
	_filter_input.text_changed.connect(_on_name_filter_changed)
	_filter_toolbar.add_child(_filter_input)
	_sort_select = OptionButton.new()
	_sort_select.name = "TrainingNameSort"
	_sort_select.custom_minimum_size = Vector2(220.0, 96.0)
	_sort_select.size_flags_horizontal = Control.SIZE_SHRINK_END
	_sort_select.fit_to_longest_item = false
	_sort_select.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sort_select.alignment = HORIZONTAL_ALIGNMENT_CENTER
	for option: Dictionary in [
		{"id": &"recruitment", "label": _t(&"ui.identity_sort.recruitment", "Recruit order")},
		{"id": &"name_asc", "label": _t(&"ui.identity_sort.name_asc", "Name A–Z")},
		{"id": &"name_desc", "label": _t(&"ui.identity_sort.name_desc", "Name Z–A")},
	]:
		_sort_select.add_item(String(option["label"]))
		var option_index := _sort_select.item_count - 1
		_sort_select.set_item_metadata(option_index, option["id"])
		if option["id"] == _name_sort:
			_sort_select.select(option_index)
	LunarisOpsType.apply_button(_sort_select, &"secondary")
	_apply_button_insets(_sort_select, 24.0, 12.0)
	_sort_select.item_selected.connect(_on_name_sort_selected)
	_filter_toolbar.add_child(_sort_select)
	_filter_summary = _label("TrainingFilterSummary", "", &"dense_detail")
	_filter_summary.custom_minimum_size.x = 90.0
	_filter_summary.autowrap_mode = TextServer.AUTOWRAP_OFF
	_filter_summary.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	_filter_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_filter_toolbar.add_child(_filter_summary)
	return _filter_toolbar


func _visible_roster_rows() -> Array[Dictionary]:
	var status_rows := RosterFilterType.filter_rows(
		_roster_rows, _filter_status, _filter_faction,
	)
	return TrainingSupportType.filtered_sorted(status_rows, _name_filter, _name_sort)


func _on_name_filter_changed(value: String) -> void:
	_name_filter = value
	_show_roster()
	if _filter_input != null:
		_filter_input.caret_column = _filter_input.text.length()
		_filter_input.grab_focus.call_deferred()


func _on_name_sort_selected(index: int) -> void:
	if _sort_select == null:
		return
	_name_sort = StringName(_sort_select.get_item_metadata(index))
	_show_roster()
	if _sort_select != null:
		_sort_select.grab_focus.call_deferred()


func _build_roster_list() -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.name = "TrainingRosterScroll"
	scroll.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(ROSTER_CARD_WIDTH + ROSTER_SCROLL_EXTRA, 0.0)
	_roster_scroll = scroll
	_roster_list = GridContainer.new()
	_roster_list.name = "TrainingRosterList"
	_roster_list.columns = 1
	_roster_list.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_roster_list.add_theme_constant_override(&"h_separation", ROSTER_GRID_GAP)
	_roster_list.add_theme_constant_override(&"v_separation", 12)
	scroll.add_child(_roster_list)
	_roster_buttons.clear()
	var visible_rows := _visible_roster_rows()
	var selected_visible := false
	for summary: Dictionary in visible_rows:
		if String(summary["hero_id"]) == _selected_hero_id:
			selected_visible = true
			break
	if not selected_visible:
		_selected_hero_id = (
			String(visible_rows[0]["hero_id"]) if not visible_rows.is_empty() else ""
		)
	if _filter_summary != null:
		_filter_summary.text = _fmt(
			&"ui.identity_filter.summary", "{shown} / {total} shown",
			{&"shown": visible_rows.size(), &"total": _roster_rows.size()},
		)
	if visible_rows.is_empty():
		var empty_key := (
			&"ui.identity_filter.empty"
			if not _name_filter.strip_edges().is_empty()
			else &"ui.roster.empty"
		)
		var empty := _label(
			"TrainingRosterEmpty",
			_t(
				empty_key,
				"No units match the name filter."
				if empty_key == &"ui.identity_filter.empty"
				else "No soldiers match the selected roster filters.",
			),
			&"dense_detail",
		)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_roster_list.add_child(empty)
		return scroll
	for visible_index: int in visible_rows.size():
		var summary := visible_rows[visible_index] as Dictionary
		var row := TrainingRosterRowType.new()
		row.name = "Recruit_%s" % summary["hero_id"]
		row.configure(
			summary,
			class_label(String(summary["current_class_id"])),
			_status_text(summary),
			_progress_text(summary),
			_eligibility_text(summary),
			_operator_stats_tooltip(summary),
			visible_index,
		)
		row.set_selected(String(summary["hero_id"]) == _selected_hero_id)
		row.pressed.connect(_on_roster_selected.bind(String(summary["hero_id"])))
		_bind_focus_scroll(row, scroll)
		_roster_list.add_child(row)
		_roster_buttons.append(row)
	return scroll


func _build_inspector() -> AetheriaPanelType:
	var panel := AetheriaPanelType.new()
	panel.name = "TrainingInspector"
	panel.apply_role(&"inspector")
	_apply_transparent_gold_inspector(panel)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio = 1.0
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2.ZERO
	var column := VBoxContainer.new()
	column.name = "InspectorColumn"
	column.add_theme_constant_override(&"separation", 12)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var inspector_scroll := ScrollContainer.new()
	inspector_scroll.name = "TrainingInspectorScroll"
	inspector_scroll.custom_minimum_size.y = 0.0
	inspector_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inspector_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inspector_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_inspector_scroll = inspector_scroll
	panel.add_child(inspector_scroll)
	inspector_scroll.add_child(column)
	var inspector_header := BoxContainer.new()
	inspector_header.name = "SelectedOperatorHeader"
	inspector_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inspector_header.add_theme_constant_override(&"separation", 12)
	var inspector_eyebrow := _label(
		"AtelierEyebrow",
		_t(&"ui.rename.selected_operator", "SELECTED OPERATOR"),
		&"eyebrow",
	)
	inspector_eyebrow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inspector_header.add_child(inspector_eyebrow)
	column.add_child(inspector_header)
	var selected := _summary_by_id(_selected_hero_id)
	if not selected.is_empty():
		panel.tooltip_text = _operator_stats_tooltip(selected)
		var dossier := BoxContainer.new()
		dossier.name = "SelectedOperatorDossier"
		dossier.add_theme_constant_override(&"separation", 8)
		var identity := VBoxContainer.new()
		identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		identity.add_theme_constant_override(&"separation", 6)
		var identity_heading := BoxContainer.new()
		identity_heading.name = "SelectedOperatorIdentity"
		identity_heading.add_theme_constant_override(&"separation", 12)
		identity_heading.alignment = BoxContainer.ALIGNMENT_CENTER
		identity_heading.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		var identity_copy := VBoxContainer.new()
		identity_copy.name = "SelectedOperatorIdentityCopy"
		identity_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		identity_copy.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		identity_copy.add_theme_constant_override(&"separation", 4)
		identity_copy.add_child(_label(
			"SelectedCallsign", String(selected["callsign"]).to_upper(), &"heading",
		))
		var selected_title := String(
			selected.get("custom_title", "")
			if selected.get("custom_title") != null
			else "",
		)
		identity_copy.add_child(_label(
			"SelectedTitleTag",
			selected_title.to_upper()
			if not selected_title.is_empty()
			else _t(&"ui.rename.no_title", "NO TITLE ASSIGNED"),
			&"eyebrow",
		))
		identity_heading.add_child(identity_copy)
		var edit_identity := Button.new()
		edit_identity.name = "EditIdentity"
		edit_identity.text = _t(
			&"ui.rename.close_short" if _identity_editor_open else &"ui.rename.edit_short",
			"Close" if _identity_editor_open else "Edit",
		)
		edit_identity.custom_minimum_size = Vector2(140.0, 84.0)
		edit_identity.size_flags_horizontal = Control.SIZE_SHRINK_END
		edit_identity.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		edit_identity.focus_mode = Control.FOCUS_ALL
		edit_identity.accessibility_name = edit_identity.text
		edit_identity.accessibility_description = _t(
			&"ui.rename.edit_identity_description",
			"Show or hide the selected operator identity editor.",
		)
		LunarisOpsType.apply_button(edit_identity, &"gold")
		_apply_button_insets(edit_identity, 24.0, 12.0)
		var edit_label := Label.new()
		edit_label.name = "EditIdentityLabel"
		edit_label.text = edit_identity.text.to_upper()
		edit_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		edit_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		edit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		edit_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		LunarisOpsType.apply_label(edit_label, &"eyebrow")
		edit_label.add_theme_font_size_override(&"font_size", 30)
		edit_label.offset_left = 24.0
		edit_label.offset_top = 12.0
		edit_label.offset_right = -24.0
		edit_label.offset_bottom = -12.0
		edit_identity.add_child(edit_label)
		var transparent := Color(0.0, 0.0, 0.0, 0.0)
		for color_name: StringName in [
			&"font_color", &"font_hover_color", &"font_pressed_color",
			&"font_focus_color", &"font_disabled_color",
		]:
			edit_identity.add_theme_color_override(color_name, transparent)
		_bind_focus_scroll(edit_identity, _inspector_scroll)
		edit_identity.pressed.connect(_on_edit_identity_requested)
		inspector_header.add_child(edit_identity)
		identity.add_child(identity_heading)
		identity.add_child(_label(
			"SelectedClass", class_label(String(selected["current_class_id"])).to_upper(),
			&"heading",
		))
		identity.add_child(_label(
			"SelectedContinuity",
			_t(&"ui.training.same_recruit_new_job", "Same person. New training and equipment."),
			&"eyebrow",
		))
		if bool(selected.get("is_premium", false)):
			identity.add_child(_label(
				"SelectedPremiumStatus",
				_manifest_fmt(
					&"ui.training.premium_identity",
					"PREMIUM • FIXED ELITE KIT • {count} PREPARED BODIES",
					{&"count": int(selected["premium_lives"])},
				),
				&"metric",
			))
		else:
			var xp_bar := ProgressBar.new()
			xp_bar.name = "SelectedXpBar"
			xp_bar.max_value = int(selected["xp_required"])
			xp_bar.value = mini(int(selected["xp"]), int(selected["xp_required"]))
			xp_bar.show_percentage = false
			xp_bar.custom_minimum_size.y = 10.0
			_apply_gold_progress(xp_bar)
			identity.add_child(xp_bar)
			identity.add_child(_label(
				"SelectedXp",
				_fmt(
					&"ui.training.xp_progress", "XP {current} / {required}",
					{
						&"current": int(selected["xp"]),
						&"required": int(selected["xp_required"]),
					},
				),
					&"metric",
				))
		dossier.add_child(identity)
		var portrait := TextureRect.new()
		portrait.name = "SelectedOperatorPortrait"
		portrait.texture = Art.texture(StringName(selected["portrait_asset_id"]))
		portrait.custom_minimum_size = Vector2(378.0, 480.0)
		portrait.visible = not _identity_editor_open
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		dossier.add_child(portrait)
		PremiumPortraitEntranceType.apply(
			portrait,
			StringName(selected["portrait_asset_id"]),
			0,
			_motion_reduced(),
		)
		column.add_child(dossier)
		column.add_child(_build_rename_panel(selected))
	column.add_child(_label(
		"FieldRecordHeading", _t(&"ui.training.field_record", "FIELD RECORD"), &"heading",
	))
	column.add_child(_label(
		"TrainingExplainer",
		_t(
			&"ui.training.training_explainer",
			"Practice, equipment work, and field duty improve the same person. Training never replaces or rewrites a soul.",
		),
		&"detail",
	))
	if not selected.is_empty():
		column.add_child(_label(
			"SelectedRecruitStatus", _eligibility_text(selected).to_upper(), &"metric",
		))
		if bool(selected.get("can_promote", false)):
			var choose_promotion := _button(
				"ChoosePromotion",
				_t(&"ui.training.choose_promotion", "Choose Promotion"),
				true,
				&"gold",
			)
			choose_promotion.custom_minimum_size = Vector2(360.0, 96.0)
			choose_promotion.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			var promotion_label := choose_promotion.get_node(
				"PresentationLabel",
			) as Label
			promotion_label.name = "ChoosePromotionLabel"
			promotion_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			promotion_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			promotion_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			choose_promotion.accessibility_description = _t(
				&"ui.training.choose_promotion_description",
				"Choose an advanced specialization for the selected operator.",
			)
			_apply_button_insets(choose_promotion, 24.0, 12.0)
			choose_promotion.pressed.connect(_on_choose_promotion)
			column.add_child(choose_promotion)
	column.add_child(_label(
		"PermanenceNote",
		_t(&"ui.training.permanent_warning", "THIS CHOICE IS PERMANENT."),
		&"eyebrow",
	))
	_apply_inspector_typography(panel)
	var promotion_presentation := panel.find_child(
		"ChoosePromotionLabel", true, false,
	) as Label
	if promotion_presentation != null:
		promotion_presentation.add_theme_font_size_override(&"font_size", 30)
	return panel


func _build_rename_panel(summary: Dictionary) -> AetheriaPanelType:
	var panel := AetheriaPanelType.new()
	panel.name = "RenameUnitPanel"
	panel.visible = _identity_editor_open
	panel.apply_role(&"hud")
	LunarisOpsType.apply_panel(panel, &"quiet")
	_ensure_panel_padding(panel, 18.0)
	var column := VBoxContainer.new()
	column.name = "RenameUnitColumn"
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override(&"separation", 8)
	column.add_child(_label(
		"RenameUnitHeading", _t(&"ui.rename.heading", "FIELD IDENTITY"), &"heading",
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
		_t(
			&"ui.rename.guidance",
			"Choose a unique 1–20 character name and an optional 24 character title.",
		),
		&"dense_detail",
	))
	_rename_row = BoxContainer.new()
	_rename_row.name = "RenameUnitControls"
	_rename_row.vertical = true
	_rename_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rename_row.add_theme_constant_override(&"separation", 10)
	var callsign_field := VBoxContainer.new()
	callsign_field.name = "CallsignField"
	callsign_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	callsign_field.add_child(_label(
		"CallsignFieldLabel", _t(&"ui.rename.callsign_label", "CALLSIGN"), &"eyebrow",
	))
	_rename_input = LineEdit.new()
	_rename_input.name = "RenameUnitInput"
	_rename_input.text = _identity_draft_callsign(summary)
	_rename_input.placeholder_text = _t(&"ui.rename.placeholder", "Enter callsign")
	_rename_input.max_length = 20
	_rename_input.clear_button_enabled = true
	_rename_input.select_all_on_focus = true
	_rename_input.custom_minimum_size = Vector2(220.0, 58.0)
	_rename_input.accessibility_name = _t(&"ui.rename.callsign_label", "CALLSIGN")
	_rename_input.accessibility_description = _t(
		&"ui.rename.callsign_description", "Unique callsign, 1 to 20 characters.",
	)
	_rename_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rename_input.text_changed.connect(_on_identity_text_changed)
	_rename_input.text_submitted.connect(_on_identity_submitted)
	LunarisOpsType.apply_line_edit(_rename_input)
	_rename_input.add_theme_font_size_override(&"font_size", 30)
	_bind_focus_scroll(_rename_input, _dialog_scroll)
	callsign_field.add_child(_rename_input)
	_rename_row.add_child(callsign_field)
	var title_field := VBoxContainer.new()
	title_field.name = "TitleField"
	title_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_field.add_child(_label(
		"TitleFieldLabel", _t(&"ui.rename.title_label", "TITLE TAG • OPTIONAL"), &"eyebrow",
	))
	_rename_title_input = LineEdit.new()
	_rename_title_input.name = "RenameTitleInput"
	_rename_title_input.text = _identity_draft_title(summary)
	_rename_title_input.placeholder_text = _t(&"ui.rename.title_placeholder", "No title")
	_rename_title_input.max_length = 24
	_rename_title_input.clear_button_enabled = true
	_rename_title_input.custom_minimum_size = Vector2(220.0, 58.0)
	_rename_title_input.accessibility_name = _t(
		&"ui.rename.title_label", "TITLE TAG • OPTIONAL",
	)
	_rename_title_input.accessibility_description = _t(
		&"ui.rename.title_description", "Optional title, up to 24 characters.",
	)
	_rename_title_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rename_title_input.text_changed.connect(_on_identity_text_changed)
	_rename_title_input.text_submitted.connect(_on_identity_submitted)
	LunarisOpsType.apply_line_edit(_rename_title_input)
	_rename_title_input.add_theme_font_size_override(&"font_size", 30)
	_bind_focus_scroll(_rename_title_input, _dialog_scroll)
	title_field.add_child(_rename_title_input)
	_rename_row.add_child(title_field)
	_rename_action = _button(
		"RenameUnitAction", _t(&"ui.rename.review_action", "Review"), false, &"disabled",
	)
	_rename_action.custom_minimum_size = Vector2(160.0, 58.0)
	_rename_action.size_flags_vertical = Control.SIZE_SHRINK_END
	_rename_action.pressed.connect(_request_rename_confirmation)
	_rename_row.add_child(_rename_action)
	column.add_child(_rename_row)
	_rename_error = _label("RenameUnitError", "", &"dense_detail")
	_rename_error.custom_minimum_size.y = 24.0
	_rename_error.accessibility_name = _t(&"ui.common.error", "Error")
	_rename_error.accessibility_live = AccessibilityServer.LIVE_OFF
	if not String(_rename_editor_error).is_empty():
		var error_text := _error_text(_rename_editor_error)
		_rename_error.text = _manifest_fmt(
			&"ui.training.error_message", "Error: {message}",
			{&"message": error_text},
		)
		_rename_error.accessibility_description = error_text
		_rename_error.accessibility_live = AccessibilityServer.LIVE_ASSERTIVE
		_apply_identity_error_style(_rename_editor_error)
	column.add_child(_rename_error)
	panel.add_child(column)
	_sync_identity_action()
	return panel


func _on_identity_text_changed(_value: String) -> void:
	_rename_editor_error = &""
	if _rename_error != null:
		_rename_error.text = ""
		_rename_error.accessibility_description = ""
		_rename_error.accessibility_live = AccessibilityServer.LIVE_OFF
	if _rename_input != null:
		_rename_input.accessibility_description = _t(
			&"ui.rename.callsign_description", "Unique callsign, 1 to 20 characters.",
		)
		LunarisOpsType.apply_line_edit(_rename_input)
		_rename_input.add_theme_font_size_override(&"font_size", IDENTITY_INPUT_FONT_SIZE)
	if _rename_title_input != null:
		_rename_title_input.accessibility_description = _t(
			&"ui.rename.title_description", "Optional title, up to 24 characters.",
		)
		LunarisOpsType.apply_line_edit(_rename_title_input)
		_rename_title_input.add_theme_font_size_override(&"font_size", IDENTITY_INPUT_FONT_SIZE)
	_persist_identity_edit_draft()
	_sync_identity_action()


func _persist_identity_edit_draft() -> void:
	if _rename_input == null or _rename_title_input == null or _selected_hero_id.is_empty():
		return
	_identity_edit_draft = {
		"hero_id": _selected_hero_id,
		"callsign": _rename_input.text,
		"title_text": _rename_title_input.text,
		"title": _title_candidate(),
	}


func _sync_identity_action() -> void:
	var summary := _summary_by_id(_selected_hero_id)
	var candidate := _rename_input.text.strip_edges() if _rename_input != null else ""
	var title: Variant = _title_candidate()
	var current_title: Variant = summary.get("custom_title") if not summary.is_empty() else null
	var enabled: bool = (
		_rename_state == RenameConfirmationState.INACTIVE
		and not summary.is_empty()
		and bool(summary.get("can_rename", false))
		and HeroCodecScript.valid_callsign(candidate)
		and HeroCodecScript.valid_title(title)
		and (candidate != String(summary["callsign"]) or title != current_title)
	)
	if _rename_action != null:
		_rename_action.disabled = not enabled
		_rename_action.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
		LunarisOpsType.apply_button(
			_rename_action, &"primary" if enabled else &"disabled",
		)


func _identity_draft_callsign(summary: Dictionary) -> String:
	if String(_identity_edit_draft.get("hero_id", "")) == _selected_hero_id:
		return String(_identity_edit_draft.get("callsign", summary["callsign"]))
	return String(summary["callsign"])


func _identity_draft_title(summary: Dictionary) -> String:
	if String(_identity_edit_draft.get("hero_id", "")) == _selected_hero_id:
		return String(_identity_edit_draft.get("title_text", ""))
	var title: Variant = summary.get("custom_title")
	return "" if title == null else String(title)


func _on_identity_submitted(_value: String) -> void:
	_request_rename_confirmation()


func _title_candidate() -> Variant:
	if _rename_title_input == null:
		return null
	var title := _rename_title_input.text.strip_edges()
	return null if title.is_empty() else title


func _request_rename_confirmation() -> void:
	if (
		_rename_state != RenameConfirmationState.INACTIVE
		or _rename_presentation_state != RenamePresentationState.IDLE
		or _rename_input == null
		or _rename_action == null
		or _rename_action.disabled
	):
		return
	var summary := _summary_by_id(_selected_hero_id)
	if summary.is_empty():
		return
	_persist_identity_edit_draft()
	_pending_identity = {
		"hero_id": _selected_hero_id,
		"callsign": String(_identity_edit_draft["callsign"]).strip_edges(),
		"title": _identity_edit_draft["title"],
		"current_callsign": String(summary["callsign"]),
		"current_title": summary.get("custom_title"),
		"class_id": String(summary["current_class_id"]),
	}
	_rename_state = RenameConfirmationState.ACTIVE
	_set_rename_presentation_state(RenamePresentationState.ENTERING)
	_release_owned_focus()
	Sfx.play("menu_open")
	_render_rename_confirmation(&"RenameConfirm")
	_start_rename_entry()


func _render_rename_confirmation(focus_name: StringName = &"RenameConfirm") -> void:
	if _pending_identity.is_empty() or _rename_state == RenameConfirmationState.INACTIVE:
		return
	_mode = &"rename_confirmation"
	_clear_page(false)
	_set_persistent_header(_header(
		"RenameConfirmationTitle",
		_t(&"ui.rename.confirm_title", "Confirm identity"),
		_t(
			&"ui.rename.guidance",
			"Choose a unique 1–20 character name and an optional 24 character title.",
		),
	))
	_page.add_child(_build_selected_identity_panel())
	_rename_comparison = BoxContainer.new()
	_rename_comparison.name = "RenameIdentityComparison"
	_rename_comparison.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rename_comparison.add_theme_constant_override(&"separation", 16)
	_rename_comparison.add_child(_build_identity_comparison_panel(
		"CurrentIdentityPanel", _t(&"ui.rename.current_identity", "CURRENT IDENTITY"),
		String(_pending_identity["current_callsign"]), _pending_identity["current_title"],
		&"quiet",
	))
	_rename_comparison.add_child(_build_identity_comparison_panel(
		"NewIdentityPanel", _t(&"ui.rename.new_identity", "NEW IDENTITY"),
		String(_pending_identity["callsign"]), _pending_identity["title"], &"selected",
	))
	_page.add_child(_rename_comparison)
	var note := _label(
		"RenameReversibilityNote",
		_t(
			&"ui.rename.reversible_note",
			"This cosmetic identity can be changed again outside active operations.",
		),
		&"detail",
	)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_page.add_child(note)
	_rename_status = _label("RenameConfirmationStatus", "", &"dense_detail")
	_rename_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rename_status.custom_minimum_size.y = 24.0
	_rename_status.accessibility_name = _t(&"ui.rename.status_label", "Rename status")
	_rename_status.accessibility_description = _t(
		&"ui.rename.status_description", "Status of the pending identity change.",
	)
	_page.add_child(_rename_status)
	var footer := _footer("RenameConfirmationActions")
	_rename_cancel = _button(
		"RenameCancel", _t(&"ui.action.cancel", "Cancel"), false, &"disabled",
	)
	_rename_cancel.accessibility_name = _t(&"ui.action.cancel", "Cancel")
	_rename_cancel.accessibility_description = _t(
		&"ui.rename.cancel_description",
		"Close confirmation without applying the identity change. The draft is kept.",
	)
	_rename_cancel.pressed.connect(_cancel_rename)
	_rename_confirm = _button(
		"RenameConfirm",
		_t(&"ui.rename.committing", "RENAMING…")
		if _rename_state == RenameConfirmationState.COMMITTING
		else _t(&"ui.rename.confirm_action", "Confirm"),
		false, &"disabled",
	)
	_rename_confirm.accessibility_name = _t(&"ui.rename.confirm_action", "Confirm")
	_rename_confirm.accessibility_description = _t(
		&"ui.rename.confirm_description", "Apply the pending callsign and optional title.",
	)
	_rename_confirm.pressed.connect(_confirm_rename)
	footer.add_child(_rename_cancel)
	footer.add_child(_rename_confirm)
	_set_action_footer(footer)
	_apply_rename_confirmation_layout()
	_apply_footer_layouts()
	_reset_outer_scroll()
	_set_confirmation_status()
	if _rename_presentation_state == RenamePresentationState.ACTIVE:
		_set_rename_actions_active()
		_focus_confirmation_control_guarded.call_deferred(
			focus_name, _rename_presentation_generation,
		)
	else:
		_set_rename_actions_locked()


func _start_rename_entry() -> void:
	_kill_rename_presentation_transition()
	_set_rename_presentation_state(RenamePresentationState.ENTERING)
	_set_confirmation_status()
	_set_rename_actions_locked()
	_rename_presentation_origin = _workspace.position
	_workspace.modulate.a = 0.0
	_workspace.position = _rename_presentation_origin + Vector2(0.0, RENAME_VERTICAL_OFFSET)
	var generation := _rename_presentation_generation
	if _motion_reduced():
		_workspace.modulate.a = 1.0
		_workspace.position = _rename_presentation_origin
		_finish_rename_entry(generation)
		return
	_rename_presentation_tween = create_tween()
	_rename_presentation_tween.set_parallel(true)
	_rename_presentation_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_rename_presentation_tween.tween_property(
		_workspace, "modulate:a", 1.0, RENAME_ENTRY_SECONDS,
	)
	_rename_presentation_tween.tween_property(
		_workspace, "position", _rename_presentation_origin, RENAME_ENTRY_SECONDS,
	)
	_rename_presentation_tween.finished.connect(_finish_rename_entry.bind(generation))


func _finish_rename_entry(generation: int) -> void:
	if not _rename_transition_callback_valid(generation, RenamePresentationState.ENTERING):
		return
	_rename_presentation_tween = null
	_workspace.modulate.a = 1.0
	_workspace.position = _rename_presentation_origin
	_set_rename_presentation_state(RenamePresentationState.ACTIVE)
	_set_confirmation_status()
	_set_rename_actions_active()
	_focus_confirmation_control(&"RenameConfirm")
	rename_confirmation_transition_completed.emit(&"active")


func _begin_rename_exit(reason: StringName, error_code: StringName = &"") -> void:
	if _rename_presentation_state != RenamePresentationState.ACTIVE:
		return
	_kill_rename_presentation_transition()
	_rename_exit_reason = reason
	_rename_exit_error = error_code
	_set_rename_presentation_state(RenamePresentationState.EXITING)
	_set_confirmation_status()
	_release_owned_focus()
	_set_rename_actions_locked()
	_rename_presentation_origin = _workspace.position
	var generation := _rename_presentation_generation
	if _motion_reduced():
		_workspace.modulate.a = 0.0
		_workspace.position = _rename_presentation_origin + Vector2(0.0, -RENAME_VERTICAL_OFFSET)
		_finish_rename_exit(generation)
		return
	_rename_presentation_tween = create_tween()
	_rename_presentation_tween.set_parallel(true)
	_rename_presentation_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_rename_presentation_tween.tween_property(
		_workspace, "modulate:a", 0.0, RENAME_EXIT_SECONDS,
	)
	_rename_presentation_tween.tween_property(
		_workspace, "position",
		_rename_presentation_origin + Vector2(0.0, -RENAME_VERTICAL_OFFSET),
		RENAME_EXIT_SECONDS,
	)
	_rename_presentation_tween.finished.connect(_finish_rename_exit.bind(generation))


func _finish_rename_exit(generation: int) -> void:
	if not _rename_transition_callback_valid(generation, RenamePresentationState.EXITING):
		return
	_rename_presentation_tween = null
	var reason := _rename_exit_reason
	var error_code := _rename_exit_error
	_rename_exit_reason = &""
	_rename_exit_error = &""
	_pending_identity.clear()
	_rename_state = RenameConfirmationState.INACTIVE
	_set_rename_presentation_state(RenamePresentationState.IDLE)
	_workspace.modulate.a = 1.0
	_workspace.position = _rename_presentation_origin
	if reason == &"committed":
		_identity_edit_draft.clear()
		_rename_editor_error = &""
		_refresh_roster()
	elif reason == &"error":
		_rename_editor_error = error_code
	_show_roster()
	if reason == &"cancelled":
		_focus_identity_field.call_deferred(&"callsign", generation)
	elif reason == &"error":
		_focus_identity_field.call_deferred(_identity_error_target(error_code), generation)
	rename_confirmation_transition_completed.emit(&"idle")


func _kill_rename_presentation_transition(invalidate: bool = true) -> void:
	if invalidate:
		_rename_presentation_generation += 1
	if _rename_presentation_tween != null and _rename_presentation_tween.is_valid():
		_rename_presentation_tween.kill()
	_rename_presentation_tween = null


func _rename_transition_callback_valid(generation: int, state: int) -> bool:
	return (
		generation == _rename_presentation_generation
		and is_inside_tree()
		and _rename_presentation_state == state
		and _workspace != null
		and is_instance_valid(_workspace)
	)


func _set_rename_presentation_state(state: int) -> void:
	if _rename_presentation_state == state:
		return
	_rename_presentation_state = state
	rename_confirmation_presentation_changed.emit(rename_presentation_state())


func _motion_reduced() -> bool:
	return bool(ProjectSettings.get_setting("accessibility/reduced_motion", false))


func _set_confirmation_status() -> void:
	if _rename_status == null or not is_instance_valid(_rename_status):
		return
	match _rename_presentation_state:
		RenamePresentationState.ENTERING:
			_rename_status.text = _t(&"ui.rename.entering", "Opening identity confirmation…")
		RenamePresentationState.EXITING:
			_rename_status.text = _t(&"ui.rename.closing", "Closing identity confirmation…")
		RenamePresentationState.ACTIVE:
			if _rename_state == RenameConfirmationState.COMMITTING:
				_rename_status.text = _t(&"ui.rename.committing", "RENAMING…")
			else:
				_rename_status.text = _t(&"ui.rename.ready", "Ready to confirm identity.")
		_:
			_rename_status.text = ""
	_rename_status.accessibility_description = _rename_status.text
	_rename_status.accessibility_live = (
		AccessibilityServer.LIVE_POLITE
		if not _rename_status.text.is_empty()
		else AccessibilityServer.LIVE_OFF
	)


func _set_rename_actions_active() -> void:
	for action: AetheriaButtonType in [_rename_cancel, _rename_confirm]:
		if action == null or not is_instance_valid(action):
			continue
		action.disabled = false
		action.focus_mode = Control.FOCUS_ALL
		action.mouse_filter = Control.MOUSE_FILTER_STOP
	LunarisOpsType.apply_button(_rename_cancel, &"secondary")
	LunarisOpsType.apply_button(_rename_confirm, &"primary")
	_wire_confirmation_focus()


func _wire_confirmation_focus() -> void:
	if _rename_cancel == null or _rename_confirm == null:
		return
	_wire_focus([_rename_cancel, _rename_confirm], not _rename_confirmation_stacks())


func _release_owned_focus() -> void:
	var focused := get_viewport().gui_get_focus_owner()
	if focused == null or not is_ancestor_of(focused):
		return
	focused.release_focus()


func _build_selected_identity_panel() -> AetheriaPanelType:
	var panel := AetheriaPanelType.new()
	panel.name = "RenameSelectedOperator"
	panel.apply_role(&"inspector")
	LunarisOpsType.apply_panel(panel, &"screen")
	var content := VBoxContainer.new()
	content.add_theme_constant_override(&"separation", 6)
	content.add_child(_label(
		"RenameSelectedOperatorLabel",
		_t(&"ui.rename.selected_operator", "SELECTED OPERATOR"),
		&"eyebrow",
	))
	content.add_child(_label(
		"RenameSelectedOperatorIdentity",
		_identity_preview(
			String(_pending_identity["current_callsign"]),
			_pending_identity["current_title"],
		),
		&"heading",
	))
	content.add_child(_label(
		"RenameSelectedOperatorClass",
		class_label(String(_pending_identity["class_id"])),
		&"detail",
	))
	panel.add_child(content)
	return panel


func _build_identity_comparison_panel(
	node_name: String,
	heading: String,
	callsign: String,
	title: Variant,
	role: StringName,
) -> AetheriaPanelType:
	var panel := AetheriaPanelType.new()
	panel.name = node_name
	panel.apply_role(&"hud")
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio = 1.0
	panel.custom_minimum_size.x = 0.0
	LunarisOpsType.apply_panel(panel, role)
	var content := VBoxContainer.new()
	content.add_theme_constant_override(&"separation", 8)
	content.add_child(_label("Heading", heading, &"eyebrow"))
	content.add_child(_label("Callsign", callsign, &"heading"))
	content.add_child(_label(
		"Title",
		_t(&"ui.rename.title_placeholder", "No title") if title == null else String(title),
		&"detail",
	))
	panel.add_child(content)
	return panel


func _identity_preview(callsign: String, title: Variant) -> String:
	return callsign if title == null else "%s — %s" % [callsign, String(title)]


func _confirm_rename() -> void:
	if (
		_rename_state != RenameConfirmationState.ACTIVE
		or _rename_presentation_state != RenamePresentationState.ACTIVE
		or _pending_identity.is_empty()
	):
		return
	_rename_state = RenameConfirmationState.COMMITTING
	_set_rename_actions_locked()
	_set_confirmation_status()
	Sfx.play("ui_confirm")
	_rename_dispatch_count += 1
	var committed: Dictionary = Game.rename_hero(
		String(_pending_identity["hero_id"]),
		String(_pending_identity["callsign"]),
		_pending_identity["title"],
	)
	if not bool(committed.get("accepted", false)):
		var error_code := StringName(committed.get("error_code", &"invalid_callsign"))
		_begin_rename_exit(&"error", error_code)
		return
	_begin_rename_exit(&"committed")


func _set_rename_actions_locked() -> void:
	for action: AetheriaButtonType in [_rename_cancel, _rename_confirm]:
		if action == null or not is_instance_valid(action):
			continue
		action.disabled = true
		action.focus_mode = Control.FOCUS_NONE
		action.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_clear_focus_paths(action)
		LunarisOpsType.apply_button(action, &"disabled")
	if _rename_confirm != null and _rename_state == RenameConfirmationState.COMMITTING:
		var pending_text := _t(&"ui.rename.committing", "RENAMING…")
		_rename_confirm.set_presentation_text(pending_text, pending_text)


func _cancel_rename() -> void:
	if (
		_rename_state != RenameConfirmationState.ACTIVE
		or _rename_presentation_state != RenamePresentationState.ACTIVE
	):
		return
	Sfx.play("menu_close")
	_begin_rename_exit(&"cancelled")


func _identity_error_target(error_code: StringName) -> StringName:
	return &"title" if error_code == &"invalid_title" else &"callsign"


func _focus_identity_field(target: StringName, generation: int) -> void:
	if generation != _rename_presentation_generation or not is_inside_tree():
		return
	var control: Control = _rename_title_input if target == &"title" else _rename_input
	if control == null or not is_instance_valid(control) or not control.is_visible_in_tree():
		control = _rename_action
	if control != null and is_instance_valid(control):
		control.grab_focus()


func _focus_rename_editor() -> void:
	_focus_identity_field(&"callsign", _rename_presentation_generation)


func _focus_confirmation_control(control_name: StringName) -> void:
	_focus_confirmation_control_guarded(control_name, _rename_presentation_generation)


func _focus_confirmation_control_guarded(control_name: StringName, generation: int) -> void:
	if (
		not is_inside_tree()
		or generation != _rename_presentation_generation
		or _rename_presentation_state != RenamePresentationState.ACTIVE
		or _rename_state != RenameConfirmationState.ACTIVE
	):
		return
	var control := find_child(String(control_name), true, false) as Control
	if control == null or not control.is_visible_in_tree() or control.focus_mode == Control.FOCUS_NONE:
		control = _rename_confirm
	if control != null and is_instance_valid(control):
		control.grab_focus()


func _show_paths() -> void:
	var options: Dictionary = TrainingSupportType.options(_campaign, _selected_hero_id)
	if not bool(options.get("accepted", false)):
		_show_roster(StringName(options.get("error_code", &"missing_catalog")))
		return
	_mode = &"paths"
	_clear_page()
	_apply_path_screen_gutters(true)
	var summary := _summary_by_id(_selected_hero_id)
	_page.add_child(_header(
		"ChooseTrainingTitle",
			_fmt(
				&"ui.training.choose_advanced",
				"CHOOSE A NEW SPECIALIZATION FOR {callsign}",
				{&"callsign": String(summary["callsign"]).to_upper()},
			),
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
	_path_cards_scroll = ScrollContainer.new()
	_path_cards_scroll.name = "PathCardsScroll"
	_path_cards_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_path_cards_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_path_cards_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_path_cards_scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_path_cards_scroll.custom_minimum_size.y = PATH_CARD_SIZE.y + 28.0
	var cards := GridContainer.new()
	cards.name = "PathCards"
	cards.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	cards.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	cards.add_theme_constant_override(&"h_separation", int(PATH_CARD_GAP))
	cards.add_theme_constant_override(&"v_separation", int(PATH_CARD_GAP))
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
					&"ui.training.field_kit_compact",
					"FIELD KIT • AFTER CONFIRMATION",
				),
				_path_stats_tooltip(choice),
			)
		card.pressed.connect(
			_on_path_selected.bind(String(choice["to_class_id"])),
		)
		card.mouse_entered.connect(
			_prefetch_class_pack.bind(String(choice["to_class_id"]), true, true),
		)
		card.focus_entered.connect(
			_prefetch_class_pack.bind(String(choice["to_class_id"]), true, true),
		)
		card.focus_entered.connect(_ensure_path_card_visible.bind(card))
		cards.add_child(card)
		_path_cards.append(card)
	var candidate_classes: Array[String] = []
	for card: PromotionPathCardType in _path_cards:
		candidate_classes.append(card.class_id)
	var content_packs := get_node_or_null("/root/ContentPacks")
	if content_packs != null:
		content_packs.call("prefetch_class_ids", candidate_classes, false)
	_path_cards_scroll.add_child(cards)
	_page.add_child(_path_cards_scroll)
	var action_bar := BoxContainer.new()
	action_bar.name = "PathActionBar"
	action_bar.vertical = _layout_mode == &"portrait"
	action_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_bar.alignment = BoxContainer.ALIGNMENT_END
	action_bar.add_theme_constant_override(&"separation", 16)
	var warning := _label(
		"PermanentWarning",
		_t(&"ui.training.permanent_warning", "THIS CHOICE IS PERMANENT."),
		&"dense_heading",
	)
	warning.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	warning.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	action_bar.add_child(warning)
	var footer := _footer("PathActions")
	footer.size_flags_horizontal = Control.SIZE_SHRINK_END
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
	_apply_path_action_style(back)
	_apply_path_action_style(_choose_path)
	action_bar.add_child(footer)
	var action_safe := MarginContainer.new()
	action_safe.name = "PathActionSafe"
	action_safe.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_safe.add_child(action_bar)
	_set_action_footer(action_safe)
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
	_ensure_panel_padding(panel, 16.0)
	var text := _fmt(
		&"ui.training.same_identity",
		"SAME PERSON • SAME HERO ID • SAME CALLSIGN • SAME HISTORY",
		{},
	)
	var label := _label("IdentityContinuity", text, &"dense_detail")
	label.tooltip_text = "%s — %s" % [summary["callsign"], summary["hero_id"]]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(label)
	return panel


func _on_roster_selected(hero_id: String) -> void:
	if hero_id != _selected_hero_id:
		_persist_identity_edit_draft()
		_identity_editor_open = false
	_selected_hero_id = hero_id
	_show_roster()


func _on_edit_identity_requested() -> void:
	if _identity_editor_open:
		_persist_identity_edit_draft()
	_identity_editor_open = not _identity_editor_open
	_show_roster()
	if _identity_editor_open:
		_focus_identity_field.call_deferred(&"callsign", _rename_presentation_generation)


func _on_filters_changed(status: StringName, faction_id: StringName) -> void:
	_filter_status = status
	_filter_faction = faction_id
	var visible := _visible_roster_rows()
	var selected_visible := false
	for summary: Dictionary in visible:
		if String(summary["hero_id"]) == _selected_hero_id:
			selected_visible = true
			break
	if not selected_visible:
		_persist_identity_edit_draft()
		_identity_editor_open = false
		_selected_hero_id = String(visible[0]["hero_id"]) if not visible.is_empty() else ""
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
			"This training choice cannot be changed.",
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
	_set_action_footer(footer)
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
	Game.open_squad_select()


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


func _on_choose_promotion() -> void:
	if _selected_can_promote():
		_show_paths()


func _on_path_selected(choice_id: String) -> void:
	_selected_choice_id = choice_id
	_prefetch_class_pack(choice_id, true, false)
	for card: PromotionPathCardType in _path_cards:
		card.set_selected(card.class_id == choice_id)
	_choose_path.disabled = false
	_choose_path.focus_mode = Control.FOCUS_ALL
	_apply_path_action_style(_choose_path)
	_wire_focus(_focusable_controls(), _layout_mode != &"portrait")


func _prefetch_class_pack(class_id: String, prioritize: bool, background: bool) -> void:
	var content_packs := get_node_or_null("/root/ContentPacks")
	if content_packs != null:
		content_packs.call("request_class", class_id, prioritize, background)


func _on_layout_mode_changed(value: StringName) -> void:
	_layout_mode = value
	var target_size := _shell_size_for(value)
	if _shell.preferred_size != target_size:
		_shell.preferred_size = target_size
	if _mode == &"paths":
		_apply_path_screen_gutters(true)
		_apply_paths_layout()
	elif _mode == &"roster":
		_apply_roster_layout()
	elif _mode == &"rename_confirmation":
		_apply_rename_confirmation_layout()
	_apply_footer_layouts()
	if _mode != &"rename_confirmation":
		_reset_outer_scroll()


func _on_viewport_resized() -> void:
	if _viewport_layout_refresh_queued or not is_inside_tree():
		return
	_viewport_layout_refresh_queued = true
	_refresh_viewport_layout.call_deferred()


func _refresh_viewport_layout() -> void:
	_viewport_layout_refresh_queued = false
	if _shell == null or not is_instance_valid(_shell):
		return
	_on_layout_mode_changed(_shell.layout_mode())


func _on_roster_body_resized() -> void:
	if _mode == &"roster":
		_on_viewport_resized()


func _on_text_scale_changed(_value: float) -> void:
	_on_viewport_resized()


func _training_roster_available_width(body: Control = null) -> float:
	var roster_body := body
	if roster_body == null and _page != null:
		roster_body = _page.get_node_or_null("TrainingRosterBody") as Control
	var body_width := (
		roster_body.size.x
		if roster_body != null and roster_body.size.x > 0.0
		else get_viewport_rect().size.x - 140.0
	)
	var separation := (
		float((roster_body as BoxContainer).get_theme_constant(&"separation"))
		if roster_body is BoxContainer
		else ROSTER_LANDSCAPE_SEPARATION
	)
	return maxf(0.0, body_width - separation - ROSTER_INSPECTOR_MIN_WIDTH)


func _training_roster_columns(body: Control = null, stacked := false) -> int:
	return RosterGridLayoutType.fitting_columns(
		_training_roster_available_width(body),
		ROSTER_CARD_WIDTH,
		ROSTER_GRID_GAP,
		ROSTER_MAX_COLUMNS,
		_roster_buttons.size(),
		stacked or _layout_mode != &"regular_landscape" or _large_text_layout(),
	)


func _wire_roster_grid_focus(columns: int) -> void:
	var safe_columns := maxi(1, columns)
	for index: int in _roster_buttons.size():
		var current := _roster_buttons[index]
		if current == null or not is_instance_valid(current):
			continue
		var self_path := current.get_path_to(current)
		current.focus_neighbor_left = (
			current.get_path_to(_roster_buttons[index - 1])
			if safe_columns > 1 and index % safe_columns > 0
			else self_path
		)
		current.focus_neighbor_right = (
			current.get_path_to(_roster_buttons[index + 1])
			if safe_columns > 1 and index % safe_columns < safe_columns - 1
			and index + 1 < _roster_buttons.size()
			else self_path
		)
		current.focus_neighbor_top = (
			current.get_path_to(_roster_buttons[index - safe_columns])
			if index >= safe_columns
			else self_path
		)
		current.focus_neighbor_bottom = (
			current.get_path_to(_roster_buttons[index + safe_columns])
			if index + safe_columns < _roster_buttons.size()
			else self_path
		)


func _shell_size_for(mode_value: StringName) -> Vector2:
	if mode_value == &"portrait":
		var viewport_size := get_viewport_rect().size
		return Vector2(
			minf(PORTRAIT_SHELL_SIZE.x, maxf(300.0, viewport_size.x - 24.0)),
			minf(PORTRAIT_SHELL_SIZE.y, maxf(540.0, viewport_size.y - 24.0)),
		)
	if mode_value == &"compact_landscape":
		return COMPACT_SHELL_SIZE
	return SHELL_SIZE


func _apply_roster_layout() -> void:
	var body := _page.get_node_or_null("TrainingRosterBody") as BoxContainer
	if body == null:
		return
	var large_text := _large_text_layout()
	var stacked := _layout_mode == &"portrait" or large_text
	body.vertical = stacked
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.custom_minimum_size.y = 0.0
	body.add_theme_constant_override(
		&"separation", 16 if stacked else int(ROSTER_LANDSCAPE_SEPARATION),
	)
	var scroll := body.get_node_or_null("TrainingRosterScroll") as ScrollContainer
	var roster_columns := _training_roster_columns(body, stacked)
	var multi_column_roster := roster_columns > 1
	var roster_width := (
		ROSTER_CARD_WIDTH * float(roster_columns)
		+ ROSTER_GRID_GAP * float(maxi(0, roster_columns - 1))
	)
	if _layout_mode == &"compact_landscape":
		roster_width = 500.0
	elif _layout_mode == &"portrait":
		roster_width = clampf(
			get_viewport_rect().size.x
			- (96.0 if get_viewport_rect().size.x < 500.0 else 48.0),
			280.0,
			560.0,
		)
	elif large_text:
		roster_width = clampf(get_viewport_rect().size.x - 48.0, 560.0, 1080.0)
	if scroll != null:
		scroll.custom_minimum_size = Vector2(
			0.0 if stacked else roster_width + ROSTER_SCROLL_EXTRA,
			220.0 if stacked else 0.0,
		)
		scroll.size_flags_horizontal = (
			Control.SIZE_EXPAND_FILL
			if stacked
			else Control.SIZE_SHRINK_BEGIN
		)
	if _roster_list != null:
		_roster_list.columns = roster_columns
		_roster_list.custom_minimum_size.x = (
			0.0 if stacked else roster_width
		)
	if _inspector_scroll != null:
		_inspector_scroll.custom_minimum_size.y = (
			220.0 if stacked else 0.0
		)
	if _filter_bar != null:
		_filter_bar.set_compact(_layout_mode != &"portrait")
		_filter_bar.set_inline(multi_column_roster)
		_filter_bar.set_auxiliary_stacked(large_text or _layout_mode != &"regular_landscape")
	if _roster_controls != null:
		_roster_controls.vertical = large_text
	for row: TrainingRosterRowType in _roster_buttons:
		row.set_compact(
			large_text or _layout_mode != &"regular_landscape",
			ROSTER_CARD_WIDTH if multi_column_roster else roster_width,
		)
	if _filter_toolbar != null:
		_filter_toolbar.vertical = stacked
		_filter_toolbar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if _sort_select != null:
		_sort_select.custom_minimum_size = Vector2(
			minf(560.0 if large_text else 220.0, maxf(320.0 if large_text else 180.0, get_viewport_rect().size.x - 96.0))
			if stacked
			else 220.0,
			96.0,
		)
		_sort_select.size_flags_horizontal = (
			Control.SIZE_SHRINK_BEGIN
			if stacked
			else Control.SIZE_SHRINK_END
		)
	if _filter_summary != null:
		_filter_summary.visible = stacked
		_filter_summary.horizontal_alignment = (
			HORIZONTAL_ALIGNMENT_LEFT
			if stacked
			else HORIZONTAL_ALIGNMENT_RIGHT
		)
	if _rename_row != null:
		_rename_row.vertical = true
	var narrow_portrait := _layout_mode == &"portrait" and get_viewport_rect().size.x < 500.0
	if _filter_bar != null:
		_filter_bar.set_narrow(narrow_portrait)
	if _content_gutter != null:
		_content_gutter.add_theme_constant_override(
			&"margin_right",
			6 if narrow_portrait else AetheriaScreenShellType.DIALOG_TEXT_GUTTER,
		)
	var header_symbol := _page.find_child(
		"LunarisReliquarySymbol", true, false,
	) as TextureRect
	if header_symbol != null:
		header_symbol.visible = not narrow_portrait
	var dossier := _page.get_node_or_null(
		"TrainingRosterBody/TrainingInspector/TrainingInspectorScroll/InspectorColumn/SelectedOperatorDossier",
	) as BoxContainer
	if dossier != null:
		dossier.vertical = large_text or not multi_column_roster
	var identity_heading := _page.find_child("SelectedOperatorIdentity", true, false) as BoxContainer
	if identity_heading != null:
		identity_heading.vertical = large_text
	var inspector_header := _page.find_child("SelectedOperatorHeader", true, false) as BoxContainer
	if inspector_header != null:
		inspector_header.vertical = large_text
	var edit_identity := _page.find_child("EditIdentity", true, false) as Button
	if edit_identity != null and large_text:
		edit_identity.custom_minimum_size.x = 260.0
		edit_identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var choose_promotion := _page.find_child("ChoosePromotion", true, false) as Button
	if choose_promotion != null:
		choose_promotion.custom_minimum_size.x = 260.0 if stacked else 360.0
	if not _roster_buttons.is_empty():
		_wire_focus(_focusable_controls(), false)
		_wire_roster_grid_focus(roster_columns)


func _apply_paths_layout() -> void:
	var cards := _page.find_child("PathCards", true, false) as GridContainer
	if cards == null:
		return
	var card_size := (
		PATH_CARD_PORTRAIT_SIZE if _layout_mode == &"portrait" else PATH_CARD_SIZE
	)
	# Doubled landscape cards remain on one deliberate horizontal rail. Portrait
	# uses one vertical column and the outer Training document owns overflow.
	cards.columns = 1 if _layout_mode == &"portrait" else maxi(1, _path_cards.size())
	if _path_cards_scroll != null:
		_path_cards_scroll.horizontal_scroll_mode = (
			ScrollContainer.SCROLL_MODE_DISABLED
			if _layout_mode == &"portrait"
			else ScrollContainer.SCROLL_MODE_AUTO
		)
		_path_cards_scroll.custom_minimum_size.y = (
			card_size.y * float(_path_cards.size())
			+ PATH_CARD_GAP * float(maxi(0, _path_cards.size() - 1))
			if _layout_mode == &"portrait"
			else card_size.y + 28.0
		)
	var action_safe := _action_dock.get_node_or_null("PathActionSafe") as MarginContainer
	if action_safe != null:
		var gutter := PATH_SCREEN_GUTTER_PORTRAIT if _layout_mode == &"portrait" else PATH_SCREEN_GUTTER
		action_safe.add_theme_constant_override(&"margin_left", gutter)
		action_safe.add_theme_constant_override(&"margin_right", gutter)
		action_safe.add_theme_constant_override(&"margin_top", PATH_ACTION_PADDING_VERTICAL)
		action_safe.add_theme_constant_override(&"margin_bottom", PATH_ACTION_PADDING_VERTICAL)
	var action_bar := _action_dock.find_child("PathActionBar", true, false) as BoxContainer
	if action_bar != null:
		action_bar.vertical = _layout_mode == &"portrait"
	for card: PromotionPathCardType in _path_cards:
		card.set_compact(_layout_mode == &"portrait")


func _apply_path_screen_gutters(active: bool) -> void:
	if _content_gutter == null:
		return
	var gutter := (
		(PATH_SCREEN_GUTTER_PORTRAIT if _layout_mode == &"portrait" else PATH_SCREEN_GUTTER)
		if active
		else 6
	)
	_content_gutter.add_theme_constant_override(&"margin_left", gutter)
	_content_gutter.add_theme_constant_override(&"margin_right", gutter if active else 0)


func _ensure_path_card_visible(card: PromotionPathCardType) -> void:
	if card == null or not is_instance_valid(card):
		return
	if not _path_cards.is_empty() and card == _path_cards[0] and _dialog_scroll.scroll_vertical == 0:
		return
	_ensure_focus_visible(card)


func _apply_path_action_style(action: AetheriaButtonType) -> void:
	if action == null:
		return
	action.custom_minimum_size = PATH_ACTION_SIZE
	action.size_flags_horizontal = Control.SIZE_SHRINK_END
	action.size_flags_vertical = Control.SIZE_SHRINK_END
	LunarisOpsType.apply_button(action, &"secondary")
	var normal_style := action.get_theme_stylebox(&"normal")
	if normal_style != null:
		action.add_theme_stylebox_override(&"disabled", normal_style.duplicate())
	var presentation := action.get_node_or_null("PresentationLabel") as AetheriaLabelType
	if presentation != null:
		presentation.add_theme_font_size_override(&"font_size", 28)
		presentation.autowrap_mode = TextServer.AUTOWRAP_OFF
		presentation.clip_text = false
	action.fit_presentation(PATH_ACTION_SIZE.x, PATH_ACTION_SIZE.x, PATH_ACTION_SIZE.y)
	if presentation != null:
		presentation.offset_left = PATH_ACTION_PADDING_HORIZONTAL
		presentation.offset_top = PATH_ACTION_PADDING_VERTICAL
		presentation.offset_right = -PATH_ACTION_PADDING_HORIZONTAL
		presentation.offset_bottom = -PATH_ACTION_PADDING_VERTICAL
	for style_name: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed", &"focus", &"disabled"]:
		var style := action.get_theme_stylebox(style_name).duplicate() as StyleBox
		if style == null:
			continue
		style.content_margin_left = PATH_ACTION_PADDING_HORIZONTAL
		style.content_margin_right = PATH_ACTION_PADDING_HORIZONTAL
		style.content_margin_top = PATH_ACTION_PADDING_VERTICAL
		style.content_margin_bottom = PATH_ACTION_PADDING_VERTICAL
		action.add_theme_stylebox_override(style_name, style)
	action.custom_minimum_size = PATH_ACTION_SIZE


func _apply_rename_confirmation_layout() -> void:
	if _rename_comparison == null:
		return
	var focused_name := &""
	var focused := get_viewport().gui_get_focus_owner()
	if focused != null and is_ancestor_of(focused):
		focused_name = focused.name
	_rename_comparison.vertical = _rename_confirmation_stacks()
	if (
		_rename_state == RenameConfirmationState.ACTIVE
		and _rename_presentation_state == RenamePresentationState.ACTIVE
	):
		_wire_confirmation_focus()
	if not String(focused_name).is_empty():
		_focus_confirmation_control_guarded.call_deferred(
			focused_name, _rename_presentation_generation,
		)


func _rename_confirmation_stacks() -> bool:
	return _layout_mode == &"portrait" or get_viewport_rect().size.x <= 620.0


func _reset_outer_scroll() -> void:
	if _dialog_scroll == null:
		return
	_dialog_scroll.vertical_scroll_mode = (
		ScrollContainer.SCROLL_MODE_DISABLED
		if _mode == &"roster" and _roster_uses_fixed_workspace()
		else ScrollContainer.SCROLL_MODE_AUTO
	)
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
	title_block.add_child(_label(
		"%sEyebrow" % node_name,
		_t(&"ui.training.atelier", "RELIQUARY ATELIER"),
		&"eyebrow",
	))
	title_block.add_child(_label("%sHeading" % node_name, title.to_upper(), &"title"))
	identity.add_child(title_block)
	top.add_child(identity)
	if Game.training_return_path == &"mission" and _mode != &"rename_confirmation":
		_return_mission = _button(
			"ReturnToMission",
			_t(&"ui.training.return_to_mission", "RETURN TO MISSION"),
			true,
			&"gold",
		)
		_return_mission.custom_minimum_size = Vector2(230.0, 58.0)
		_apply_button_insets(_return_mission, 24.0, 12.0)
		_return_mission.pressed.connect(_on_not_now)
		top.add_child(_return_mission)
	header.add_child(top)
	if not subtitle.strip_edges().is_empty():
		header.add_child(_label("%sSubtitle" % node_name, subtitle, &"detail"))
	return header


func _footer(node_name: String) -> BoxContainer:
	var footer := BoxContainer.new()
	footer.name = node_name
	footer.vertical = (
		_layout_mode == &"portrait"
		or (node_name == "RenameConfirmationActions" and _rename_confirmation_stacks())
	)
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.add_theme_constant_override(&"separation", 16)
	return footer


func _button(
	node_name: String, button_text: String, enabled: bool, role: StringName,
) -> AetheriaButtonType:
	var button := AetheriaButtonType.new()
	button.name = node_name
	button.text = button_text
	button.custom_minimum_size = Vector2(260.0, 84.0)
	button.size_flags_horizontal = Control.SIZE_SHRINK_END
	button.disabled = not enabled
	button.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
	button.set_presentation_text(button_text, button_text)
	LunarisOpsType.apply_button(button, role)
	_apply_button_insets(button, 24.0, 12.0)
	_bind_focus_scroll(button, _dialog_scroll)
	var presentation := button.get_node("PresentationLabel") as AetheriaLabelType
	LunarisOpsType.apply_label(presentation, &"body")
	presentation.add_theme_font_size_override(&"font_size", 30)
	presentation.offset_left = 24.0
	presentation.offset_top = 12.0
	presentation.offset_right = -24.0
	presentation.offset_bottom = -12.0
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
	if TRAINING_FONT_SIZES.has(role):
		label.add_theme_font_size_override(&"font_size", int(TRAINING_FONT_SIZES[role]))
	label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	return label


func _clear_page(kill_transition: bool = true) -> void:
	_apply_path_screen_gutters(false)
	if kill_transition and _rename_presentation_state != RenamePresentationState.IDLE:
		_kill_rename_presentation_transition()
	for child: Node in _page.get_children():
		_page.remove_child(child)
		child.queue_free()
	if _action_dock != null:
		for child: Node in _action_dock.get_children():
			_action_dock.remove_child(child)
			child.queue_free()
	_roster_buttons.clear()
	_path_cards.clear()
	_path_cards_scroll = null
	_choose_path = null
	_review_confirm = null
	_review_error = null
	_return_mission = null
	_filter_bar = null
	_roster_list = null
	_roster_scroll = null
	_inspector_scroll = null
	_roster_controls = null
	_filter_toolbar = null
	_filter_input = null
	_sort_select = null
	_filter_summary = null
	_rename_row = null
	_rename_input = null
	_rename_title_input = null
	_rename_action = null
	_rename_error = null
	_rename_comparison = null
	_rename_cancel = null
	_rename_confirm = null
	_rename_status = null


func _summary_by_id(hero_id: String) -> Dictionary:
	for summary: Dictionary in _roster_rows:
		if summary["hero_id"] == hero_id:
			return summary
	return {}


func _select_first_visible() -> void:
	_selected_hero_id = ""
	var visible := _visible_roster_rows()
	for summary: Dictionary in visible:
		if bool(summary["can_promote"]):
			_selected_hero_id = String(summary["hero_id"])
			return
	if not visible.is_empty():
		_selected_hero_id = String(visible[0]["hero_id"])


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
		return _t(
			&"ui.training.status.premium_ready", "PREMIUM READY",
		) if life_status == "ready" else _t(
			&"ui.training.status.premium_locked", "PREMIUM LOCKED",
		)
	if life_status == "ready":
		return _t(&"ui.training.status.ready", "READY")
	return _t(&"ui.training.status.dead", "DEAD")


func _progress_text(summary: Dictionary) -> String:
	if bool(summary.get("is_premium", false)):
		return _manifest_fmt(
			&"ui.training.premium_progress", "FIXED KIT • {count} PREPARED BODIES",
			{&"count": int(summary["premium_lives"])},
		)
	return _fmt(
		&"ui.training.xp_progress", "XP {current} / {required}",
		{&"current": int(summary["xp"]), &"required": int(summary["xp_required"])},
	)


func _operator_stats_tooltip(summary: Dictionary) -> String:
	var definition := TrainingSupportType.operator_definition(
		String(summary.get("operator_def_id", "")),
	)
	var unknown := _t(&"ui.training.tooltip.unknown_operator", "UNKNOWN OPERATOR")
	if definition == null:
		return "%s\n%s\n%s" % [
			String(summary.get("callsign", unknown)).to_upper(),
			class_label(String(summary.get("current_class_id", ""))),
			_progress_text(summary),
		]
	var placement := (
		_t(&"ui.training.placement.elevated", "Elevated")
		if int(definition.placement) == OperatorDef.Placement.ELEVATED
		else _t(&"ui.training.placement.ground", "Ground")
	)
	var title := String(
		summary.get("custom_title", "") if summary.get("custom_title") != null else "",
	)
	var identity := String(summary.get("callsign", unknown)).to_upper()
	if not title.is_empty():
		identity += " — %s" % title.to_upper()
	return "\n".join(PackedStringArray([
		identity,
		_tooltip_identity_status(
			class_label(String(summary.get("current_class_id", ""))),
			_status_text(summary),
		),
		_tooltip_core_stats(definition),
		_tooltip_deployment(definition, placement),
		_tooltip_attack(definition),
		_tooltip_value(
			&"ui.training.tooltip.skill", "Skill: {skill}",
			&"skill", _operator_skill_name(definition),
		),
		_tooltip_value(
			&"ui.training.tooltip.progress", "Training: {progress}",
			&"progress", _progress_text(summary),
		),
		_tooltip_value(
			&"ui.training.tooltip.eligibility", "Eligibility: {eligibility}",
			&"eligibility", _eligibility_text(summary),
		),
	]))


func _path_stats_tooltip(choice: Dictionary) -> String:
	var definition := TrainingSupportType.operator_definition(
		String(choice.get("operator_def_id", "")),
	)
	var path_fallback := String(choice.get(
		"class_name_fallback",
		choice.get("to_class_id", _t(&"ui.training.tooltip.path", "Training Path")),
	))
	var path_name := _t(
		StringName(choice.get("class_name_key", &"")), path_fallback,
	).to_upper()
	if definition == null:
		return "%s\n%s\n%s" % [path_name, _skill_text(choice), _combat_text(choice)]
	var placement := (
		_t(&"ui.training.placement.elevated", "Elevated")
		if int(definition.placement) == OperatorDef.Placement.ELEVATED
		else _t(&"ui.training.placement.ground", "Ground")
	)
	return "\n".join(PackedStringArray([
		path_name,
		_t(
			StringName(choice.get("role_key", &"")),
			String(choice.get(
				"role_fallback",
				_t(&"ui.training.tooltip.advanced_duty", "Advanced duty"),
			)),
		),
		_tooltip_core_stats(definition),
		_tooltip_deployment(definition, placement),
		_tooltip_attack(definition),
		_tooltip_value(
			&"ui.training.tooltip.skill", "Skill: {skill}",
			&"skill", _operator_skill_name(definition),
		),
		_t(
			&"ui.training.tooltip.permanence",
			"Permanent advanced-class assignment.",
		),
	]))


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
		"{cost} DP • {placement} • Block {block} • Range {range} cells • Attack interval {cadence} ticks",
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
		{&"skill": _choice_skill_name(choice)},
	)


func _choice_skill_name(choice: Dictionary) -> String:
	return _t(
		StringName(choice.get("skill_name_key", &"ui.training.skill.none")),
		String(choice.get("skill_name_fallback", "None")),
	)


func _operator_skill_name(definition: OperatorDef) -> String:
	if definition == null or definition.skill == null:
		return _t(&"ui.training.skill.none", "None")
	var skill_id := String(definition.skill.id)
	if skill_id.is_empty():
		return _t(&"ui.training.skill.none", "None")
	return _t(
		StringName("ui.training.skill_name.%s" % skill_id),
		TrainingSupportType.skill_name_fallback(skill_id),
	)


func _tooltip_identity_status(class_label_text: String, status: String) -> String:
	return _manifest_fmt(
		&"ui.training.tooltip.identity_status", "{class_name} • {status}",
		{&"class_name": class_label_text, &"status": status},
	)


func _tooltip_core_stats(definition: OperatorDef) -> String:
	return _manifest_fmt(
		&"ui.training.tooltip.core_stats",
		"HP {hp} • ATK {attack} • DEF {defense} • RES {resistance}%",
		{
			&"hp": int(definition.hp),
			&"attack": int(definition.atk),
			&"defense": int(definition.defense),
			&"resistance": "%.1f" % (float(definition.resistance_permille) / 10.0),
		},
	)


func _tooltip_deployment(definition: OperatorDef, placement: String) -> String:
	return _manifest_fmt(
		&"ui.training.tooltip.deployment",
		"{cost} DP • {placement} • Block {block} • Rarity {rarity}",
		{
			&"cost": int(definition.dp_cost),
			&"placement": placement,
			&"block": int(definition.block),
			&"rarity": int(definition.rarity),
		},
	)


func _tooltip_attack(definition: OperatorDef) -> String:
	return _manifest_fmt(
		&"ui.training.tooltip.attack",
		"Coverage {range} cells • Attack every {cadence} ticks",
		{
			&"range": definition.range_offsets.size(),
			&"cadence": int(definition.atk_interval_ticks),
		},
	)


func _tooltip_value(
	key: StringName, fallback: String, placeholder: StringName, value: String,
) -> String:
	return _manifest_fmt(key, fallback, {placeholder: value})


func _manifest_fmt(key: StringName, fallback: String, args: Dictionary) -> String:
	return TrainingSupportType.format_manifest_text(key, fallback, args)


func _apply_footer_layouts() -> void:
	var footer_root: Node = _action_dock if _action_dock != null else _page
	var large_text := _large_text_layout()
	for node: Node in _all_nodes(footer_root):
		if node is BoxContainer and String(node.name).ends_with("Actions"):
			var footer := node as BoxContainer
			footer.vertical = (
				_layout_mode == &"portrait"
				or large_text
				or (footer.name == "RenameConfirmationActions" and _rename_confirmation_stacks())
			)
			var actions: Array[Control] = []
			for child: Node in footer.get_children():
				if child is AetheriaButtonType:
					actions.append(child as Control)
			if footer.name == "PathActions":
				for action: Control in actions:
					action.size_flags_horizontal = Control.SIZE_SHRINK_END
					_apply_path_action_style(action as AetheriaButtonType)
				continue
			var available := minf(
				520.0 if large_text else 260.0,
				maxf(300.0 if large_text else 180.0, get_viewport_rect().size.x - 64.0),
			)
			for action: Control in actions:
				action.size_flags_horizontal = Control.SIZE_EXPAND_FILL if large_text else Control.SIZE_SHRINK_END
				(action as AetheriaButtonType).fit_presentation(
					available, available if large_text else minf(260.0, available), 84.0,
				)


func _roster_uses_fixed_workspace() -> bool:
	return _layout_mode == &"regular_landscape" and not _large_text_layout()


func _large_text_layout() -> bool:
	return TextScale != null and float(TextScale.value()) > 1.20


func _ensure_panel_padding(panel: PanelContainer, padding: float) -> void:
	if panel == null:
		return
	var style := panel.get_theme_stylebox(&"panel").duplicate() as StyleBox
	style.content_margin_left = maxf(style.content_margin_left, padding)
	style.content_margin_top = maxf(style.content_margin_top, padding)
	style.content_margin_right = maxf(style.content_margin_right, padding)
	style.content_margin_bottom = maxf(style.content_margin_bottom, padding)
	panel.add_theme_stylebox_override(&"panel", style)


func _apply_transparent_gold_inspector(panel: PanelContainer) -> void:
	if panel == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	style.border_color = INSPECTOR_GOLD
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.content_margin_left = 24.0
	style.content_margin_top = 24.0
	style.content_margin_right = 24.0
	style.content_margin_bottom = 24.0
	panel.add_theme_stylebox_override(&"panel", style)


func _apply_gold_progress(progress: ProgressBar) -> void:
	if progress == null:
		return
	var background := StyleBoxFlat.new()
	background.bg_color = Color(INSPECTOR_GOLD.r, INSPECTOR_GOLD.g, INSPECTOR_GOLD.b, 0.18)
	background.set_corner_radius_all(1)
	var fill := StyleBoxFlat.new()
	fill.bg_color = INSPECTOR_GOLD
	fill.set_corner_radius_all(1)
	progress.add_theme_stylebox_override(&"background", background)
	progress.add_theme_stylebox_override(&"fill", fill)


func _apply_inspector_typography(panel: Control) -> void:
	if panel == null:
		return
	for node: Node in _all_nodes(panel):
		if node is Label:
			var label := node as Label
			var current_size := label.get_theme_font_size(&"font_size")
			label.add_theme_font_size_override(
				&"font_size", current_size + (4 if label.name == &"SelectedCallsign" else 6),
			)
			label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			if label.name in [&"SelectedXp", &"SelectedRecruitStatus"]:
				label.add_theme_color_override(&"font_color", INSPECTOR_GOLD)
		elif node is LineEdit:
			var field := node as LineEdit
			field.add_theme_font_size_override(
				&"font_size", field.get_theme_font_size(&"font_size") + 4,
			)


func _apply_button_insets(button: Button, horizontal: float, vertical: float) -> void:
	if button == null:
		return
	for style_name: StringName in [
		&"normal", &"hover", &"pressed", &"hover_pressed", &"focus", &"disabled",
	]:
		var source := button.get_theme_stylebox(style_name)
		if source == null:
			continue
		var style := source.duplicate() as StyleBox
		style.content_margin_left = maxf(style.content_margin_left, horizontal)
		style.content_margin_right = maxf(style.content_margin_right, horizontal)
		style.content_margin_top = maxf(style.content_margin_top, vertical)
		style.content_margin_bottom = maxf(style.content_margin_bottom, vertical)
		button.add_theme_stylebox_override(style_name, style)


func _error_text(error_code: StringName) -> String:
	var fallback := String(ERROR_FALLBACKS.get(
		error_code, "Training failed. Review the roster and try again.",
	))
	return _t(error_key(error_code), fallback)


func _focus_roster_control_guarded(control: Control, generation: int) -> void:
	if (
			not is_inside_tree()
			or generation != _rename_presentation_generation
			or _mode != &"roster"
			or control == null
			or not is_instance_valid(control)
			or not control.is_visible_in_tree()
	):
		return
	control.grab_focus()


func _focus_selected_row_or(fallback: Control, generation: int) -> void:
	if generation != _rename_presentation_generation or _mode != &"roster":
		return
	for row: TrainingRosterRowType in _roster_buttons:
		if row.hero_id == _selected_hero_id:
			_focus_roster_control_guarded(row, generation)
			return
	_focus_roster_control_guarded(fallback, generation)


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
	for control: Control in controls:
		_clear_focus_paths(control)
	for index: int in controls.size():
		var current := controls[index]
		var previous := controls[(index - 1 + controls.size()) % controls.size()]
		var following := controls[(index + 1) % controls.size()]
		var self_path := current.get_path_to(current)
		current.focus_previous = current.get_path_to(previous)
		current.focus_next = current.get_path_to(following)
		if horizontal:
			current.focus_neighbor_left = current.get_path_to(previous)
			current.focus_neighbor_right = current.get_path_to(following)
			current.focus_neighbor_top = self_path
			current.focus_neighbor_bottom = self_path
		else:
			current.focus_neighbor_left = self_path
			current.focus_neighbor_right = self_path
			current.focus_neighbor_top = current.get_path_to(previous)
			current.focus_neighbor_bottom = current.get_path_to(following)


func _clear_focus_paths(control: Control) -> void:
	if control == null or not is_instance_valid(control):
		return
	control.focus_previous = NodePath()
	control.focus_next = NodePath()
	control.focus_neighbor_left = NodePath()
	control.focus_neighbor_top = NodePath()
	control.focus_neighbor_right = NodePath()
	control.focus_neighbor_bottom = NodePath()


func _bind_focus_scroll(
	control: Control, scroll: ScrollContainer, visibility_target: Control = null,
) -> void:
	if control == null or scroll == null:
		return
	var target := visibility_target if visibility_target != null else control
	control.focus_entered.connect(_ensure_focus_visible.bind(target))


func _ensure_focus_visible(control: Control) -> void:
	_ensure_focus_visible_pass(control, 2)


func _ensure_focus_visible_pass(control: Control, remaining_passes: int) -> void:
	if control == null or not is_instance_valid(control) or not control.is_inside_tree():
		return
	var scroll_ancestors: Array[ScrollContainer] = []
	var ancestor := control.get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer:
			scroll_ancestors.append(ancestor as ScrollContainer)
		ancestor = ancestor.get_parent()
	for scroll: ScrollContainer in scroll_ancestors:
		if is_instance_valid(scroll) and scroll.is_ancestor_of(control):
			scroll.ensure_control_visible(control)
	if remaining_passes > 0:
		_ensure_focus_visible_pass.call_deferred(control, remaining_passes - 1)


func _set_action_footer(footer: Control) -> void:
	if _action_dock == null or footer == null:
		return
	for child: Node in _action_dock.get_children():
		_action_dock.remove_child(child)
		child.queue_free()
	_action_dock.add_child(footer)


func _set_persistent_header(header: VBoxContainer) -> void:
	if _persistent_header == null:
		return
	for child: Node in _persistent_header.get_children():
		_persistent_header.remove_child(child)
		child.queue_free()
	_persistent_header.visible = header != null
	if header != null:
		_persistent_header.add_child(header)


func _on_locale_changed(_locale_id: StringName) -> void:
	_refresh_accessibility_metadata()
	var focused_name := &""
	var focused := get_viewport().gui_get_focus_owner()
	if focused != null and is_ancestor_of(focused):
		focused_name = focused.name
	if _mode == &"rename_confirmation":
		_render_rename_confirmation(focused_name)
	elif _mode == &"paths":
		_show_paths()
	elif _mode == &"review":
		_show_review()
	else:
		_show_roster()
	if _mode != &"rename_confirmation" and not String(focused_name).is_empty():
		_restore_named_focus.call_deferred(
			focused_name, _rename_presentation_generation, _mode,
		)


func _restore_named_focus(
	control_name: StringName, generation: int, expected_mode: StringName,
) -> void:
	if (
		not is_inside_tree()
		or generation != _rename_presentation_generation
		or _mode != expected_mode
	):
		return
	var control := find_child(String(control_name), true, false) as Control
	if (
		control != null
		and control.is_visible_in_tree()
		and control.focus_mode != Control.FOCUS_NONE
	):
		control.grab_focus()
		_ensure_focus_visible(control)


func _refresh_accessibility_metadata() -> void:
	accessibility_name = _t(&"ui.training.accessibility.name", "Training workspace")
	accessibility_description = _t(
		&"ui.training.accessibility.description",
		"Manage operator identities and advanced training paths.",
	)
	if _workspace != null:
		_workspace.accessibility_name = _t(
			&"ui.training.accessibility.workspace", "Training content",
		)
		_workspace.accessibility_description = accessibility_description
	if _persistent_header != null:
		_persistent_header.accessibility_name = _t(
			&"ui.training.accessibility.header", "Training heading",
		)
		_persistent_header.accessibility_description = _t(
			&"ui.training.accessibility.header_description",
			"Persistent context for the current Training task.",
		)
	if _action_dock != null:
		_action_dock.accessibility_name = _t(
			&"ui.training.accessibility.actions", "Training actions",
		)
		_action_dock.accessibility_description = _t(
			&"ui.training.accessibility.actions_description",
			"Persistent actions for the current Training task.",
		)


func _apply_identity_error_style(error_code: StringName) -> void:
	var error_text := _error_text(error_code)
	if _rename_input != null:
		LunarisOpsType.apply_line_edit(_rename_input, error_code != &"invalid_title")
		_rename_input.add_theme_font_size_override(&"font_size", IDENTITY_INPUT_FONT_SIZE)
		if error_code != &"invalid_title":
			_rename_input.accessibility_description = error_text
	if _rename_title_input != null:
		LunarisOpsType.apply_line_edit(_rename_title_input, error_code == &"invalid_title")
		_rename_title_input.add_theme_font_size_override(&"font_size", IDENTITY_INPUT_FONT_SIZE)
		if error_code == &"invalid_title":
			_rename_title_input.accessibility_description = error_text


func rename_presentation_state() -> StringName:
	match _rename_presentation_state:
		RenamePresentationState.ENTERING:
			return &"entering"
		RenamePresentationState.ACTIVE:
			return &"active"
		RenamePresentationState.EXITING:
			return &"exiting"
		_:
			return &"idle"


func rename_domain_state() -> StringName:
	match _rename_state:
		RenameConfirmationState.ACTIVE:
			return &"active"
		RenameConfirmationState.COMMITTING:
			return &"committing"
		_:
			return &"inactive"


func rename_transition_locked() -> bool:
	return _rename_presentation_state in [
		RenamePresentationState.ENTERING, RenamePresentationState.EXITING,
	]


func rename_transition_generation() -> int:
	return _rename_presentation_generation


func rename_transition_timing() -> Dictionary:
	return {
		"entry_seconds": RENAME_ENTRY_SECONDS,
		"exit_seconds": RENAME_EXIT_SECONDS,
		"vertical_offset": RENAME_VERTICAL_OFFSET,
		"reduced_motion": _motion_reduced(),
	}


func rename_dispatch_count() -> int:
	return _rename_dispatch_count


func pending_identity_snapshot() -> Dictionary:
	return _pending_identity.duplicate(true)


func identity_edit_draft() -> Dictionary:
	return _identity_edit_draft.duplicate(true)


func _all_nodes(root: Node) -> Array[Node]:
	var nodes: Array[Node] = [root]
	for child: Node in root.get_children():
		nodes.append_array(_all_nodes(child))
	return nodes


func _t(key: StringName, fallback: String) -> String:
	return UiCopyType.text(key, fallback)


func _fmt(key: StringName, fallback: String, args: Dictionary) -> String:
	return UiCopyType.format_text(key, fallback, args)
