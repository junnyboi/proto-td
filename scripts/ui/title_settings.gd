class_name TitleSettings
extends Control

signal cancel_requested
signal apply_requested(draft: Dictionary)
signal preview_requested(draft: Dictionary)
signal transition_state_changed(state: StringName)
signal entry_completed
signal close_completed

const StagingSkinType := preload("res://scripts/ui/components/staging_skin.gd")
const UiCopyType := preload("res://scripts/ui/components/ui_copy.gd")
const FRAME_LIMITS := [0, 30, 60, 120]
const TITLE_UI_SCALE := 1.15
const TITLE_FONT_SCALE := 3.0
const IVORY := Color("f5efe1")
const GOLD := Color("d8b978")
const MUTED := Color("aebfd0")
const ERROR_RED := Color("ff9b93")
const ENTRY_SECONDS := 0.22
const EXIT_SECONDS := 0.16
const FRAME_TRAVEL := 12.0
const APPLY_BUTTON_WIDTH := 420.0

enum TransitionState {
	CLOSED,
	ENTERING,
	ACTIVE,
	EXITING,
	COMMITTING,
}

var _draft: Dictionary = {}
var _suppress_callbacks := false
var _layout_mode: StringName = &"wide"
var _committing := false
var _transition_state := TransitionState.CLOSED
var _transition_token := 0
var _transition_tween: Tween = null
var _frame_rest_position := Vector2.ZERO
var _last_valid_focus: Control = null
var _redirect_pending := false

@onready var _safe_frame: MarginContainer = $SafeFrame
@onready var _command_frame: PanelContainer = $SafeFrame/CommandFrame
@onready var _frame_padding: MarginContainer = $SafeFrame/CommandFrame/FramePadding
@onready var _state_layout: VBoxContainer = $SafeFrame/CommandFrame/FramePadding/StateLayout
@onready var _header: HBoxContainer = $SafeFrame/CommandFrame/FramePadding/StateLayout/Header
@onready var _back_button: Button = $SafeFrame/CommandFrame/FramePadding/StateLayout/Header/SettingsBackButton
@onready var _title_label: Label = $SafeFrame/CommandFrame/FramePadding/StateLayout/Header/SettingsTitle
@onready var _header_seal: TextureRect = $SafeFrame/CommandFrame/FramePadding/StateLayout/Header/LunarisSeal
@onready var _body_scroll: ScrollContainer = $SafeFrame/CommandFrame/FramePadding/StateLayout/SettingsScroll
@onready var _body_margin: MarginContainer = $SafeFrame/CommandFrame/FramePadding/StateLayout/SettingsScroll/BodyMargin
@onready var _columns: GridContainer = $SafeFrame/CommandFrame/FramePadding/StateLayout/SettingsScroll/BodyMargin/SettingsColumns
@onready var _locale_selector: AetheriaLocaleSelector = $SafeFrame/CommandFrame/FramePadding/StateLayout/SettingsScroll/BodyMargin/SettingsColumns/LanguageAudioSection/SectionMargin/LeftSection/LocaleSelector
@onready var _locale_list: ItemList = $SafeFrame/CommandFrame/FramePadding/StateLayout/SettingsScroll/BodyMargin/SettingsColumns/LanguageAudioSection/SectionMargin/LeftSection/LocaleSelector/LocaleList
@onready var _locale_label: Label = $SafeFrame/CommandFrame/FramePadding/StateLayout/SettingsScroll/BodyMargin/SettingsColumns/LanguageAudioSection/SectionMargin/LeftSection/LocaleSelector/LocaleLabel
@onready var _audio_heading: Label = $SafeFrame/CommandFrame/FramePadding/StateLayout/SettingsScroll/BodyMargin/SettingsColumns/LanguageAudioSection/SectionMargin/LeftSection/AudioHeading
@onready var _master_label: Label = $SafeFrame/CommandFrame/FramePadding/StateLayout/SettingsScroll/BodyMargin/SettingsColumns/LanguageAudioSection/SectionMargin/LeftSection/MasterVolumeRow/MasterVolumeLabel
@onready var _master_slider: HSlider = $SafeFrame/CommandFrame/FramePadding/StateLayout/SettingsScroll/BodyMargin/SettingsColumns/LanguageAudioSection/SectionMargin/LeftSection/MasterVolumeRow/MasterVolumeSlider
@onready var _music_label: Label = $SafeFrame/CommandFrame/FramePadding/StateLayout/SettingsScroll/BodyMargin/SettingsColumns/LanguageAudioSection/SectionMargin/LeftSection/MusicVolumeRow/MusicVolumeLabel
@onready var _music_slider: HSlider = $SafeFrame/CommandFrame/FramePadding/StateLayout/SettingsScroll/BodyMargin/SettingsColumns/LanguageAudioSection/SectionMargin/LeftSection/MusicVolumeRow/MusicVolumeSlider
@onready var _sfx_label: Label = $SafeFrame/CommandFrame/FramePadding/StateLayout/SettingsScroll/BodyMargin/SettingsColumns/LanguageAudioSection/SectionMargin/LeftSection/SfxVolumeRow/SfxVolumeLabel
@onready var _sfx_slider: HSlider = $SafeFrame/CommandFrame/FramePadding/StateLayout/SettingsScroll/BodyMargin/SettingsColumns/LanguageAudioSection/SectionMargin/LeftSection/SfxVolumeRow/SfxVolumeSlider
@onready var _music_button: Button = $SafeFrame/CommandFrame/FramePadding/StateLayout/SettingsScroll/BodyMargin/SettingsColumns/LanguageAudioSection/SectionMargin/LeftSection/MusicButton
@onready var _graphics_heading: Label = $SafeFrame/CommandFrame/FramePadding/StateLayout/SettingsScroll/BodyMargin/SettingsColumns/GraphicsAccessibilitySection/SectionMargin/RightSection/GraphicsHeading
@onready var _frame_row: BoxContainer = $SafeFrame/CommandFrame/FramePadding/StateLayout/SettingsScroll/BodyMargin/SettingsColumns/GraphicsAccessibilitySection/SectionMargin/RightSection/FrameLimitRow
@onready var _frame_label: Label = $SafeFrame/CommandFrame/FramePadding/StateLayout/SettingsScroll/BodyMargin/SettingsColumns/GraphicsAccessibilitySection/SectionMargin/RightSection/FrameLimitRow/FrameLimitLabel
@onready var _frame_option: OptionButton = $SafeFrame/CommandFrame/FramePadding/StateLayout/SettingsScroll/BodyMargin/SettingsColumns/GraphicsAccessibilitySection/SectionMargin/RightSection/FrameLimitRow/FrameLimitOption
@onready var _motion_button: Button = $SafeFrame/CommandFrame/FramePadding/StateLayout/SettingsScroll/BodyMargin/SettingsColumns/GraphicsAccessibilitySection/SectionMargin/RightSection/MotionButton
@onready var _accessibility_heading: Label = $SafeFrame/CommandFrame/FramePadding/StateLayout/SettingsScroll/BodyMargin/SettingsColumns/GraphicsAccessibilitySection/SectionMargin/RightSection/AccessibilityHeading
@onready var _text_scale_label: Label = $SafeFrame/CommandFrame/FramePadding/StateLayout/SettingsScroll/BodyMargin/SettingsColumns/GraphicsAccessibilitySection/SectionMargin/RightSection/TextScaleRow/TextScaleLabel
@onready var _text_scale_slider: HSlider = $SafeFrame/CommandFrame/FramePadding/StateLayout/SettingsScroll/BodyMargin/SettingsColumns/GraphicsAccessibilitySection/SectionMargin/RightSection/TextScaleRow/TextScaleSlider
@onready var _error_label: Label = $SafeFrame/CommandFrame/FramePadding/StateLayout/SettingsError
@onready var _action_dock: GridContainer = $SafeFrame/CommandFrame/FramePadding/StateLayout/ActionDock
@onready var _apply_button: Button = $SafeFrame/CommandFrame/FramePadding/StateLayout/ActionDock/SettingsApplyButton


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	_body_scroll.follow_focus = false
	_locale_selector.set_draft_mode(true)
	_locale_selector.locale_selected.connect(_on_locale_selected)
	_back_button.pressed.connect(_request_cancel)
	_apply_button.pressed.connect(_request_apply)
	_master_slider.value_changed.connect(_on_volume_changed.bind(&"master_volume"))
	_music_slider.value_changed.connect(_on_volume_changed.bind(&"music_volume"))
	_sfx_slider.value_changed.connect(_on_volume_changed.bind(&"sfx_volume"))
	_music_button.pressed.connect(_toggle_music)
	_frame_option.item_selected.connect(_on_frame_selected)
	_frame_option.fit_to_longest_item = false
	_motion_button.pressed.connect(_toggle_motion)
	_text_scale_slider.value_changed.connect(_on_text_scale_changed)
	_locale_selector.alignment = BoxContainer.ALIGNMENT_CENTER
	_apply_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for color_name: StringName in [
		&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color",
	]:
		_apply_button.add_theme_color_override(color_name, Color.WHITE)
	I18n.locale_changed.connect(_on_locale_changed)
	resized.connect(_apply_responsive_layout)
	get_viewport().gui_focus_changed.connect(_on_gui_focus_changed)
	_apply_type()
	_configure_accessibility_relationships()
	_configure_readable_actions()
	_refresh_frame_items()
	_refresh_copy()
	_apply_responsive_layout()
	_set_interaction_enabled(false)
	visible = false


func _exit_tree() -> void:
	_kill_transition()
	var viewport := get_viewport()
	if viewport != null and viewport.gui_focus_changed.is_connected(_on_gui_focus_changed):
		viewport.gui_focus_changed.disconnect(_on_gui_focus_changed)


func open(snapshot: Dictionary) -> void:
	_transition_token += 1
	var token := _transition_token
	_kill_transition()
	_draft = snapshot.duplicate(true)
	_draft.erase(&"return_focus")
	_committing = false
	_last_valid_focus = _locale_list
	_clear_error()
	visible = true
	_sync_controls()
	_refresh_copy()
	_apply_responsive_layout()
	_rebuild_focus_graph()
	_set_transition_state(TransitionState.ENTERING)
	_set_interaction_enabled(false)
	_frame_rest_position = _command_frame.position
	_command_frame.modulate.a = 0.0
	_command_frame.position = _frame_rest_position + Vector2(0.0, FRAME_TRAVEL)
	if _motion_reduced():
		_finish_entry(token)
		return
	_transition_tween = create_tween().set_parallel(true)
	_transition_tween.tween_property(_command_frame, "modulate:a", 1.0, ENTRY_SECONDS).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	_transition_tween.tween_property(_command_frame, "position", _frame_rest_position, ENTRY_SECONDS).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	_transition_tween.finished.connect(_finish_entry.bind(token), CONNECT_ONE_SHOT)


func close() -> bool:
	if _transition_state in [TransitionState.CLOSED, TransitionState.EXITING]:
		return false
	_transition_token += 1
	var token := _transition_token
	_kill_transition()
	_committing = false
	_set_transition_state(TransitionState.EXITING)
	_set_interaction_enabled(false)
	var focused := get_viewport().gui_get_focus_owner()
	if focused != null and is_ancestor_of(focused):
		focused.release_focus()
	_frame_rest_position = _command_frame.position
	if _motion_reduced():
		_finish_close(token)
		return true
	_transition_tween = create_tween().set_parallel(true)
	_transition_tween.tween_property(_command_frame, "modulate:a", 0.0, EXIT_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_transition_tween.tween_property(_command_frame, "position", _frame_rest_position + Vector2(0.0, FRAME_TRAVEL), EXIT_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_transition_tween.finished.connect(_finish_close.bind(token), CONNECT_ONE_SHOT)
	return true


func set_reduced_motion(enabled: bool) -> void:
	if enabled and _transition_state == TransitionState.ENTERING:
		_finish_entry(_transition_token)
	elif enabled and _transition_state == TransitionState.EXITING:
		_finish_close(_transition_token)


func set_committing(enabled: bool) -> void:
	if enabled:
		if _transition_state != TransitionState.ACTIVE:
			return
		_committing = true
		_set_transition_state(TransitionState.COMMITTING)
		_set_interaction_enabled(false)
		return
	_committing = false
	if _transition_state == TransitionState.COMMITTING:
		_set_transition_state(TransitionState.ACTIVE)
		_set_interaction_enabled(true)


func show_save_failure() -> void:
	set_committing(false)
	_error_label.text = UiCopyType.text(
		&"ui.title.settings_save_failed",
		"Settings could not be saved. Review the draft and try again.",
	)
	_error_label.accessibility_description = _error_label.text
	_error_label.visible = true
	_last_valid_focus = _apply_button
	_apply_button.grab_focus.call_deferred()


func draft() -> Dictionary:
	return _draft.duplicate(true)


func layout_mode() -> StringName:
	return _layout_mode


func body_scroll() -> ScrollContainer:
	return _body_scroll


func transition_state_name() -> StringName:
	match _transition_state:
		TransitionState.ENTERING:
			return &"ENTERING"
		TransitionState.ACTIVE:
			return &"ACTIVE"
		TransitionState.EXITING:
			return &"EXITING"
		TransitionState.COMMITTING:
			return &"COMMITTING"
		_:
			return &"CLOSED"


func transition_active() -> bool:
	return _transition_state in [TransitionState.ENTERING, TransitionState.EXITING]


func entry_duration() -> float:
	return ENTRY_SECONDS


func exit_duration() -> float:
	return EXIT_SECONDS


func _unhandled_input(event: InputEvent) -> void:
	if _transition_state != TransitionState.ACTIVE:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_request_cancel()


func _request_cancel() -> void:
	if _transition_state == TransitionState.ACTIVE:
		cancel_requested.emit()


func _request_apply() -> void:
	if _transition_state == TransitionState.ACTIVE:
		_clear_error()
		apply_requested.emit(_draft.duplicate(true))


func _on_locale_selected(locale_id: StringName) -> void:
	if _suppress_callbacks or _transition_state != TransitionState.ACTIVE:
		return
	_clear_error()
	_draft[&"locale"] = locale_id
	if I18n.locale() != locale_id:
		I18n.set_locale(locale_id)
	preview_requested.emit(_draft.duplicate(true))


func _on_volume_changed(value: float, key: StringName) -> void:
	if _suppress_callbacks or _transition_state != TransitionState.ACTIVE:
		return
	_clear_error()
	_draft[key] = value / 100.0
	preview_requested.emit(_draft.duplicate(true))
	_refresh_copy()


func _toggle_music() -> void:
	if _transition_state != TransitionState.ACTIVE:
		return
	_clear_error()
	_draft[&"title_music_enabled"] = not bool(_draft.get(&"title_music_enabled", true))
	preview_requested.emit(_draft.duplicate(true))
	Sfx.play("ui_click")
	_refresh_copy()


func _on_frame_selected(index: int) -> void:
	if _suppress_callbacks or _transition_state != TransitionState.ACTIVE or index < 0 or index >= FRAME_LIMITS.size():
		return
	_clear_error()
	_draft[&"frame_limit"] = FRAME_LIMITS[index]
	preview_requested.emit(_draft.duplicate(true))
	Sfx.play("ui_click")
	_refresh_accessibility()


func _toggle_motion() -> void:
	if _transition_state != TransitionState.ACTIVE:
		return
	_clear_error()
	_draft[&"reduced_motion"] = not bool(_draft.get(&"reduced_motion", false))
	preview_requested.emit(_draft.duplicate(true))
	Sfx.play("ui_click")
	_refresh_copy()


func _on_text_scale_changed(value: float) -> void:
	if _suppress_callbacks or _transition_state != TransitionState.ACTIVE:
		return
	_clear_error()
	_draft[&"text_scale"] = value / 100.0
	preview_requested.emit(_draft.duplicate(true))
	_refresh_copy()
	_apply_responsive_layout.call_deferred()


func _on_locale_changed(_locale_id: StringName) -> void:
	var focus_owner := get_viewport().gui_get_focus_owner()
	_refresh_copy()
	_locale_selector.set_selected_locale(StringName(_draft.get(&"locale", I18n.locale())))
	_apply_responsive_layout()
	if _transition_state == TransitionState.ACTIVE and _is_valid_settings_focus(focus_owner):
		_last_valid_focus = focus_owner
		focus_owner.grab_focus.call_deferred()
		_ensure_focus_visible.call_deferred()


func _sync_controls() -> void:
	_suppress_callbacks = true
	_locale_selector.set_selected_locale(StringName(_draft.get(&"locale", I18n.locale())))
	_master_slider.value = float(_draft.get(&"master_volume", 1.0)) * 100.0
	_music_slider.value = float(_draft.get(&"music_volume", 1.0)) * 100.0
	_sfx_slider.value = float(_draft.get(&"sfx_volume", 1.0)) * 100.0
	_text_scale_slider.value = float(_draft.get(&"text_scale", 1.0)) * 100.0
	_frame_option.select(maxi(FRAME_LIMITS.find(int(_draft.get(&"frame_limit", 0))), 0))
	_suppress_callbacks = false


func _refresh_copy() -> void:
	if not is_node_ready():
		return
	_title_label.text = UiCopyType.text(&"ui.title.settings", "Settings").to_upper()
	_audio_heading.text = UiCopyType.text(&"ui.title.audio", "Audio").to_upper()
	_graphics_heading.text = UiCopyType.text(&"ui.title.graphics", "Graphics").to_upper()
	_accessibility_heading.text = UiCopyType.text(&"ui.title.accessibility", "Accessibility").to_upper()
	_master_label.text = UiCopyType.format_text(
		&"ui.title.master_volume", "MASTER VOLUME  //  {value}%",
		{&"value": roundi(float(_draft.get(&"master_volume", 1.0)) * 100.0)},
	).to_upper()
	_music_label.text = UiCopyType.format_text(
		&"ui.title.music_volume", "MUSIC VOLUME  //  {value}%",
		{&"value": roundi(float(_draft.get(&"music_volume", 1.0)) * 100.0)},
	).to_upper()
	_sfx_label.text = UiCopyType.format_text(
		&"ui.title.sfx_volume", "SFX VOLUME  //  {value}%",
		{&"value": roundi(float(_draft.get(&"sfx_volume", 1.0)) * 100.0)},
	).to_upper()
	_text_scale_label.text = UiCopyType.format_text(
		&"ui.title.text_scale", "TEXT SCALE  //  {value}%",
		{&"value": roundi(float(_draft.get(&"text_scale", 1.0)) * 100.0)},
	).to_upper()
	var music_enabled := bool(_draft.get(&"title_music_enabled", true))
	_music_button.text = UiCopyType.format_text(
		&"ui.title.music_state", "MUSIC  //  {state}",
		{&"state": UiCopyType.text(&"ui.common.on" if music_enabled else &"ui.common.off", "On" if music_enabled else "Off")},
	).to_upper()
	_frame_label.text = UiCopyType.text(&"ui.title.frame_limit", "Frame Limit").to_upper()
	var reduced := bool(_draft.get(&"reduced_motion", false))
	_motion_button.text = UiCopyType.format_text(
		&"ui.title.motion_state", "ANIMATED BACKGROUND  //  {state}",
		{&"state": UiCopyType.text(&"ui.common.off" if reduced else &"ui.common.on", "Off" if reduced else "On")},
	).to_upper()
	_back_button.text = UiCopyType.text(&"ui.common.back", "Back").to_upper()
	_apply_button.text = UiCopyType.text(&"ui.common.apply", "Apply").to_upper()
	_refresh_frame_items()
	_locale_selector.refresh()
	_refresh_accessibility()


func _refresh_frame_items() -> void:
	if not is_node_ready():
		return
	var labels := [
		UiCopyType.text(&"ui.title.frame_unlimited", "Unlimited"),
		UiCopyType.format_text(&"ui.title.frame_value", "{value} FPS", {&"value": 30}),
		UiCopyType.format_text(&"ui.title.frame_value", "{value} FPS", {&"value": 60}),
		UiCopyType.format_text(&"ui.title.frame_value", "{value} FPS", {&"value": 120}),
	]
	_suppress_callbacks = true
	if _frame_option.item_count != labels.size():
		_frame_option.clear()
		for text: String in labels:
			_frame_option.add_item(text.to_upper())
	else:
		for index: int in labels.size():
			_frame_option.set_item_text(index, String(labels[index]).to_upper())
	_frame_option.select(maxi(FRAME_LIMITS.find(int(_draft.get(&"frame_limit", 0))), 0))
	_suppress_callbacks = false


func _apply_type() -> void:
	StagingSkinType.apply_display_type(_title_label, _title_font_size(36), IVORY, 620)
	for heading: Label in [_audio_heading, _graphics_heading, _accessibility_heading]:
		StagingSkinType.apply_display_type(heading, _title_font_size(18), GOLD, 620)
	for label: Label in [_master_label, _music_label, _sfx_label, _frame_label, _text_scale_label]:
		StagingSkinType.apply_display_type(label, _title_font_size(15), MUTED, 560)
	for action: Button in [_back_button, _music_button, _motion_button, _apply_button]:
		StagingSkinType.apply_display_type(action, _title_font_size(17), IVORY, 560)
	for color_name: StringName in [
		&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color",
	]:
		_apply_button.add_theme_color_override(color_name, Color.WHITE)
	StagingSkinType.apply_display_type(_frame_option, _title_font_size(16), IVORY, 560)
	StagingSkinType.apply_display_type(_locale_label, _title_font_size(14), GOLD, 560)
	StagingSkinType.apply_display_type(_locale_list, _title_font_size(13), IVORY, 560)
	StagingSkinType.apply_display_type(_error_label, _title_font_size(15), ERROR_RED, 620)
	_error_label.add_theme_color_override(&"font_outline_color", Color("3b0d14"))
	_error_label.add_theme_constant_override(&"outline_size", 4)


func _configure_readable_actions() -> void:
	for action: Button in [_back_button, _music_button, _motion_button, _apply_button]:
		action.clip_text = false
		action.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		action.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING


func _configure_accessibility_relationships() -> void:
	_error_label.accessibility_live = AccessibilityServer.LIVE_ASSERTIVE
	_locale_list.accessibility_labeled_by_nodes = [_locale_list.get_path_to(_locale_label)]
	_locale_label.accessibility_controls_nodes = [_locale_label.get_path_to(_locale_list)]
	for pair: Array in [
		[_master_label, _master_slider],
		[_music_label, _music_slider],
		[_sfx_label, _sfx_slider],
		[_frame_label, _frame_option],
		[_text_scale_label, _text_scale_slider],
	]:
		var label := pair[0] as Label
		var control := pair[1] as Control
		control.accessibility_labeled_by_nodes = [control.get_path_to(label)]
		label.accessibility_controls_nodes = [label.get_path_to(control)]


func _refresh_accessibility() -> void:
	if not is_node_ready():
		return
	accessibility_name = UiCopyType.text(&"ui.title.settings", "Settings")
	accessibility_description = _copy(
		&"ui.title.a11y.root_description",
		"Adjust language, audio, graphics, motion, and text-size preferences.",
	)
	_back_button.accessibility_name = UiCopyType.text(&"ui.common.back", "Back")
	_back_button.accessibility_description = _copy(
		&"ui.title.a11y.back_description",
		"Discard draft changes and return to the title screen.",
	)
	_locale_list.accessibility_name = _locale_label.text
	_locale_list.accessibility_description = _copy(
		&"ui.title.a11y.locale_description",
		"Choose the interface language.",
	)
	_set_slider_accessibility(_master_slider, UiCopyType.text(&"ui.title.a11y.master_name", "Master volume"))
	_set_slider_accessibility(_music_slider, UiCopyType.text(&"ui.title.a11y.music_volume_name", "Music volume"))
	_set_slider_accessibility(_sfx_slider, UiCopyType.text(&"ui.title.a11y.sfx_name", "Sound effects volume"))
	_set_slider_accessibility(_text_scale_slider, UiCopyType.text(&"ui.title.a11y.text_scale_name", "Text scale"))
	_text_scale_slider.accessibility_description = _copy(
		&"ui.title.a11y.text_scale_description",
		"Adjust all interface text from 80 to 150 percent. Changes preview immediately.",
	)
	_music_button.accessibility_name = _music_button.text
	_music_button.accessibility_description = _copy(
		&"ui.title.a11y.music_description",
		"Toggle music on the title screen.",
	)
	_frame_option.accessibility_name = "%s: %s" % [_frame_label.text, _frame_option.get_item_text(_frame_option.selected)]
	_frame_option.accessibility_description = _copy(
		&"ui.title.a11y.frame_description",
		"Choose the maximum rendered frames per second.",
	)
	_motion_button.accessibility_name = _motion_button.text
	_motion_button.accessibility_description = _copy(
		&"ui.title.a11y.motion_description",
		"Toggle animated backgrounds. Turning animation off also reduces interface motion.",
	)
	_apply_button.accessibility_name = UiCopyType.text(&"ui.common.apply", "Apply")
	_apply_button.accessibility_description = _copy(
		&"ui.title.a11y.apply_description",
		"Save the current settings and return to the title screen.",
	)
	_error_label.accessibility_name = _copy(&"ui.title.a11y.error_name", "Settings error")


func _set_slider_accessibility(slider: HSlider, label: String) -> void:
	var percentage := roundi(slider.value)
	slider.accessibility_name = UiCopyType.text(
		&"ui.title.a11y.slider_name", "{label}, {value} percent",
	).replace("{label}", label).replace("{value}", str(percentage))
	slider.accessibility_description = _copy(
		&"ui.title.a11y.slider_description",
		"Current value: {value}%. Use left and right to adjust.",
	).replace("{value}", str(percentage))


func _apply_responsive_layout() -> void:
	if not is_node_ready():
		return
	var focus_owner := get_viewport().gui_get_focus_owner()
	var viewport := size
	if viewport.x <= 0.0 or viewport.y <= 0.0:
		viewport = get_viewport_rect().size
	var narrow := viewport.x <= 720.0
	var portrait := viewport.x / maxf(viewport.y, 1.0) <= 1.2
	var short := viewport.y <= 560.0
	var wide := viewport.x >= 1200.0 and not portrait and not narrow
	var current_text_scale := maxf(float(TextScale.value()), 0.01)
	var two_columns := viewport.x >= 840.0 and not portrait and not narrow and not short and current_text_scale <= 1.20
	_layout_mode = &"wide" if wide else (&"narrow" if narrow else (&"portrait" if portrait else &"regular"))
	if short:
		_layout_mode = StringName("%s_short" % _layout_mode)
	var horizontal_gutter := clampi(roundi(viewport.x * 0.033), 10, 42)
	var vertical_gutter := clampi(roundi(viewport.y * 0.028), 10 if short else 12, 32)
	_set_margins(_safe_frame, horizontal_gutter, vertical_gutter)
	var frame_style := StagingSkinType.command_deck_style()
	var frame_content_margin := 4.0 if narrow or short else 28.0
	frame_style.content_margin_left = frame_content_margin
	frame_style.content_margin_top = frame_content_margin
	frame_style.content_margin_right = frame_content_margin
	frame_style.content_margin_bottom = frame_content_margin
	_command_frame.add_theme_stylebox_override(&"panel", frame_style)
	var padding := 0 if narrow or short else 22
	_set_margins(_frame_padding, padding, padding)
	_set_margins(_body_margin, 10 if narrow else 18, 10 if narrow else 14)
	_state_layout.add_theme_constant_override(&"separation", 6 if short else 12)
	_header.add_theme_constant_override(&"separation", 6 if narrow else 14)
	_header_seal.visible = not narrow
	_header.custom_minimum_size.y = 72.0 if narrow or short else 96.0
	_columns.columns = 2 if two_columns else 1
	_columns.add_theme_constant_override(&"h_separation", 20 if wide else 0)
	_columns.add_theme_constant_override(&"v_separation", 12)
	_locale_selector.set_vertical_layout(true)
	_locale_selector.set_compact_mode(narrow or short)
	_frame_row.vertical = true
	for section_name: String in ["LanguageAudioSection", "GraphicsAccessibilitySection"]:
		var section := _columns.get_node_or_null(section_name) as PanelContainer
		if section != null:
			var section_style := section.get_theme_stylebox(&"panel").duplicate() as StyleBox
			section_style.content_margin_left = 18.0
			section_style.content_margin_top = 14.0
			section_style.content_margin_right = 18.0
			section.add_theme_stylebox_override(&"panel", section_style)
			var section_margin := section.get_node_or_null("SectionMargin") as MarginContainer
			if section_margin != null:
				_set_margins(section_margin, 14 if narrow else 26, 12 if narrow else 22)
	_frame_option.custom_minimum_size.x = 0.0 if narrow or portrait else 180.0
	if narrow:
		for index: int in _frame_option.item_count:
			_frame_option.set_item_text(index, "∞" if FRAME_LIMITS[index] == 0 else str(FRAME_LIMITS[index]))
	else:
		_refresh_frame_items()
	_action_dock.columns = 1
	var available_apply_width := maxf(180.0, viewport.x - float(horizontal_gutter * 2 + padding * 2 + 24))
	var apply_width := minf(_title_size(APPLY_BUTTON_WIDTH), available_apply_width)
	_action_dock.custom_minimum_size.x = apply_width
	_action_dock.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_apply_button.custom_minimum_size = Vector2(
		apply_width,
		76.0 if short else _title_size(76.0),
	)
	_apply_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_back_button.text = UiCopyType.text(&"ui.common.back", "Back").to_upper()
	_back_button.custom_minimum_size = Vector2(92.0 if narrow else 190.0, 72.0 if short else _title_size(76.0))
	_frame_option.custom_minimum_size.y = 72.0
	_music_button.custom_minimum_size.y = 82.0
	_motion_button.custom_minimum_size.y = 92.0 if narrow else 82.0
	for slider: HSlider in [_master_slider, _music_slider, _sfx_slider, _text_scale_slider]:
		slider.custom_minimum_size.y = 48.0
	_title_label.add_theme_font_size_override(
		&"font_size",
		_scaled_base_for_cap(_title_font_size(12 if narrow else (30 if portrait else 36)), 1.0),
	)
	var locale_heading := UiCopyType.text(&"ui.locale.label", "Language").to_upper()
	_locale_label.text = locale_heading
	_locale_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER if narrow else HORIZONTAL_ALIGNMENT_LEFT
	)
	_locale_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_locale_label.add_theme_font_size_override(&"font_size", _title_font_size(8 if narrow else 14))
	_locale_list.add_theme_font_size_override(&"font_size", _title_font_size(8 if narrow else 10))
	for heading: Label in [_audio_heading, _graphics_heading, _accessibility_heading]:
		heading.add_theme_font_size_override(&"font_size", _scaled_base_for_cap(_title_font_size(18), 1.20))
		heading.autowrap_mode = (
			TextServer.AUTOWRAP_ARBITRARY if narrow else TextServer.AUTOWRAP_WORD_SMART
		)
	_back_button.add_theme_font_size_override(&"font_size", _scaled_base_for_cap(_title_font_size(9 if narrow else 17), 1.15))
	_music_button.add_theme_font_size_override(&"font_size", _title_font_size(13 if narrow else 17))
	_motion_button.add_theme_font_size_override(&"font_size", _title_font_size(10 if narrow else 17))
	_apply_button.add_theme_font_size_override(&"font_size", _scaled_base_for_cap(_title_font_size(15 if narrow else 17), 1.15))
	for action: Button in [_back_button, _music_button, _motion_button, _apply_button]:
		action.autowrap_mode = (
			TextServer.AUTOWRAP_ARBITRARY if narrow else TextServer.AUTOWRAP_WORD_SMART
		)
		action.clip_text = false
	_back_button.autowrap_mode = TextServer.AUTOWRAP_OFF
	_rebuild_focus_graph()
	if _transition_state == TransitionState.ACTIVE and _is_valid_settings_focus(focus_owner):
		_last_valid_focus = focus_owner
		focus_owner.grab_focus.call_deferred()
		_ensure_focus_visible.call_deferred()


func _rebuild_focus_graph() -> void:
	var controls := _focus_controls()
	if controls.is_empty():
		return
	for index: int in controls.size():
		var current := controls[index]
		var previous := controls[(index - 1 + controls.size()) % controls.size()]
		var following := controls[(index + 1) % controls.size()]
		current.focus_previous = current.get_path_to(previous)
		current.focus_next = current.get_path_to(following)
		current.focus_neighbor_top = current.get_path_to(previous)
		current.focus_neighbor_bottom = current.get_path_to(following)
		current.focus_neighbor_left = current.get_path_to(current)
		current.focus_neighbor_right = current.get_path_to(current)
	if _columns.columns != 2:
		return
	var left_chain: Array[Control] = [
		_back_button,
		_locale_list,
		_master_slider,
		_music_slider,
		_sfx_slider,
		_music_button,
		_apply_button,
	]
	for index: int in left_chain.size():
		var current := left_chain[index]
		current.focus_neighbor_top = current.get_path_to(left_chain[(index - 1 + left_chain.size()) % left_chain.size()])
		current.focus_neighbor_bottom = current.get_path_to(left_chain[(index + 1) % left_chain.size()])
	_frame_option.focus_neighbor_top = _frame_option.get_path_to(_back_button)
	_frame_option.focus_neighbor_bottom = _frame_option.get_path_to(_motion_button)
	_motion_button.focus_neighbor_top = _motion_button.get_path_to(_frame_option)
	_motion_button.focus_neighbor_bottom = _motion_button.get_path_to(_text_scale_slider)
	_text_scale_slider.focus_neighbor_top = _text_scale_slider.get_path_to(_motion_button)
	_text_scale_slider.focus_neighbor_bottom = _text_scale_slider.get_path_to(_apply_button)
	_locale_list.focus_neighbor_right = _locale_list.get_path_to(_frame_option)
	_master_slider.focus_neighbor_right = _master_slider.get_path_to(_frame_option)
	_music_slider.focus_neighbor_right = _music_slider.get_path_to(_motion_button)
	_sfx_slider.focus_neighbor_right = _sfx_slider.get_path_to(_text_scale_slider)
	_music_button.focus_neighbor_right = _music_button.get_path_to(_text_scale_slider)
	_frame_option.focus_neighbor_left = _frame_option.get_path_to(_locale_list)
	_motion_button.focus_neighbor_left = _motion_button.get_path_to(_music_button)
	_text_scale_slider.focus_neighbor_left = _text_scale_slider.get_path_to(_music_button)


func _focus_controls() -> Array[Control]:
	return [
		_back_button,
		_locale_list,
		_master_slider,
		_music_slider,
		_sfx_slider,
		_music_button,
		_frame_option,
		_motion_button,
		_text_scale_slider,
		_apply_button,
	]


func _set_interaction_enabled(enabled: bool) -> void:
	for control: Control in _focus_controls():
		control.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
		if control is BaseButton:
			(control as BaseButton).disabled = not enabled
		elif control is Slider:
			(control as Slider).editable = enabled
	_locale_list.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE


func _on_gui_focus_changed(focused: Control) -> void:
	if _transition_state != TransitionState.ACTIVE:
		return
	if _option_popup_active():
		return
	if _is_valid_settings_focus(focused):
		_last_valid_focus = focused
		_ensure_focus_visible.call_deferred()
		return
	_queue_focus_redirect()


func _queue_focus_redirect() -> void:
	if _redirect_pending:
		return
	_redirect_pending = true
	_redirect_focus.call_deferred(_transition_token)


func _redirect_focus(token: int) -> void:
	_redirect_pending = false
	if token != _transition_token or _transition_state != TransitionState.ACTIVE or _option_popup_active():
		return
	var target := _last_valid_focus
	if not _is_valid_settings_focus(target):
		target = _locale_list
	_last_valid_focus = target
	target.grab_focus()
	_ensure_focus_visible.call_deferred()


func _is_valid_settings_focus(control: Control) -> bool:
	return control != null and is_instance_valid(control) and control.is_visible_in_tree() and control.focus_mode != Control.FOCUS_NONE and (control in _focus_controls())


func _option_popup_active() -> bool:
	var popup := _frame_option.get_popup()
	return popup != null and popup.visible


func _ensure_focus_visible() -> void:
	if _transition_state != TransitionState.ACTIVE:
		return
	var focused := get_viewport().gui_get_focus_owner()
	if focused != null and _body_scroll.is_ancestor_of(focused):
		if focused == _locale_list:
			_body_scroll.scroll_vertical = 0
		else:
			_body_scroll.ensure_control_visible(focused)


func _finish_entry(token: int) -> void:
	if token != _transition_token or _transition_state != TransitionState.ENTERING:
		return
	_kill_transition()
	_command_frame.modulate.a = 1.0
	_command_frame.position = _frame_rest_position
	_set_transition_state(TransitionState.ACTIVE)
	_set_interaction_enabled(true)
	_last_valid_focus = _locale_list
	_locale_list.grab_focus()
	_ensure_focus_visible.call_deferred()
	entry_completed.emit()


func _finish_close(token: int) -> void:
	if token != _transition_token or _transition_state != TransitionState.EXITING:
		return
	_kill_transition()
	_command_frame.modulate.a = 1.0
	_command_frame.position = _frame_rest_position
	_clear_error()
	visible = false
	_last_valid_focus = null
	_set_transition_state(TransitionState.CLOSED)
	close_completed.emit()


func _set_transition_state(state: TransitionState) -> void:
	if _transition_state == state:
		return
	_transition_state = state
	transition_state_changed.emit(transition_state_name())


func _kill_transition() -> void:
	if _transition_tween != null and _transition_tween.is_valid():
		_transition_tween.kill()
	_transition_tween = null


func _clear_error() -> void:
	_error_label.visible = false
	_error_label.text = ""
	_error_label.accessibility_description = ""


func _motion_reduced() -> bool:
	return bool(_draft.get(&"reduced_motion", ProjectSettings.get_setting("accessibility/reduced_motion", false)))


func _copy(key: StringName, fallback: String) -> String:
	return UiCopyType.text(key, fallback)


func _set_margins(container: MarginContainer, horizontal: int, vertical: int) -> void:
	container.add_theme_constant_override(&"margin_left", horizontal)
	container.add_theme_constant_override(&"margin_right", horizontal)
	container.add_theme_constant_override(&"margin_top", vertical)
	container.add_theme_constant_override(&"margin_bottom", vertical)


func _title_size(value: float) -> float:
	return value * TITLE_UI_SCALE


func _title_font_size(value: int) -> int:
	return roundi(float(value) * TITLE_UI_SCALE * TITLE_FONT_SCALE)


func _scaled_base_for_cap(base_size: int, maximum_visual_scale: float) -> int:
	var current_scale := maxf(float(TextScale.value()), 0.01)
	var visual_scale := minf(current_scale, maximum_visual_scale)
	return maxi(1, roundi(float(base_size) * visual_scale / current_scale))
