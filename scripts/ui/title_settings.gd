class_name TitleSettings
extends Control

signal cancel_requested
signal apply_requested(draft: Dictionary)
signal preview_requested(draft: Dictionary)

const StagingSkinType := preload("res://scripts/ui/components/staging_skin.gd")
const UiCopyType := preload("res://scripts/ui/components/ui_copy.gd")
const FRAME_LIMITS := [0, 30, 60, 120]
const TITLE_UI_SCALE := 1.15
const TITLE_FONT_SCALE := 2.0
const IVORY := Color("f5efe1")
const GOLD := Color("d8b978")
const MUTED := Color("aebfd0")

var _draft: Dictionary = {}
var _suppress_callbacks := false
var _layout_mode: StringName = &"wide"
var _committing := false

@onready var _safe_frame: MarginContainer = $SafeFrame
@onready var _command_frame: PanelContainer = $SafeFrame/CommandFrame
@onready var _frame_padding: MarginContainer = $SafeFrame/CommandFrame/FramePadding
@onready var _state_layout: VBoxContainer = $SafeFrame/CommandFrame/FramePadding/StateLayout
@onready var _header: HBoxContainer = $SafeFrame/CommandFrame/FramePadding/StateLayout/Header
@onready var _back_button: Button = $SafeFrame/CommandFrame/FramePadding/StateLayout/Header/SettingsBackButton
@onready var _title_label: Label = $SafeFrame/CommandFrame/FramePadding/StateLayout/Header/SettingsTitle
@onready var _header_seal: TextureRect = $SafeFrame/CommandFrame/FramePadding/StateLayout/Header/LunarisSeal
@onready var _body_scroll: ScrollContainer = $SafeFrame/CommandFrame/FramePadding/StateLayout/SettingsScroll
@onready var _columns: GridContainer = $SafeFrame/CommandFrame/FramePadding/StateLayout/SettingsScroll/BodyMargin/SettingsColumns
@onready var _locale_selector: AetheriaLocaleSelector = $SafeFrame/CommandFrame/FramePadding/StateLayout/SettingsScroll/BodyMargin/SettingsColumns/LanguageAudioSection/SectionMargin/LeftSection/LocaleSelector
@onready var _locale_list: ItemList = $SafeFrame/CommandFrame/FramePadding/StateLayout/SettingsScroll/BodyMargin/SettingsColumns/LanguageAudioSection/SectionMargin/LeftSection/LocaleSelector/LocaleList
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
@onready var _error_label: Label = $SafeFrame/CommandFrame/FramePadding/StateLayout/SettingsError
@onready var _action_dock: GridContainer = $SafeFrame/CommandFrame/FramePadding/StateLayout/ActionDock
@onready var _apply_button: Button = $SafeFrame/CommandFrame/FramePadding/StateLayout/ActionDock/SettingsApplyButton


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_body_scroll.follow_focus = true
	_locale_selector.set_draft_mode(true)
	_locale_selector.locale_selected.connect(_on_locale_selected)
	_back_button.pressed.connect(_request_cancel)
	_apply_button.pressed.connect(_request_apply)
	_master_slider.value_changed.connect(_on_volume_changed.bind(&"master_volume"))
	_music_slider.value_changed.connect(_on_volume_changed.bind(&"music_volume"))
	_sfx_slider.value_changed.connect(_on_volume_changed.bind(&"sfx_volume"))
	_music_button.pressed.connect(_toggle_music)
	_frame_option.item_selected.connect(_on_frame_selected)
	_motion_button.pressed.connect(_toggle_motion)
	I18n.locale_changed.connect(_on_locale_changed)
	resized.connect(_apply_responsive_layout)
	_apply_type()
	_refresh_frame_items()
	_refresh_copy()
	_apply_responsive_layout()
	visible = false


func open(snapshot: Dictionary) -> void:
	_draft = snapshot.duplicate(true)
	_draft.erase(&"return_focus")
	_committing = false
	_error_label.visible = false
	visible = true
	_sync_controls()
	_refresh_copy()
	_apply_responsive_layout()
	_rebuild_focus_graph()
	_locale_list.grab_focus.call_deferred()
	_ensure_focus_visible.call_deferred()


func close() -> void:
	visible = false
	_committing = false
	_error_label.visible = false


func set_committing(enabled: bool) -> void:
	_committing = enabled
	for control: Control in _focus_controls():
		if control is BaseButton:
			(control as BaseButton).disabled = enabled
		elif control is Slider:
			(control as Slider).editable = not enabled
		elif control is OptionButton:
			(control as OptionButton).disabled = enabled
	_locale_list.mouse_filter = Control.MOUSE_FILTER_IGNORE if enabled else Control.MOUSE_FILTER_STOP
	_locale_list.focus_mode = Control.FOCUS_NONE if enabled else Control.FOCUS_ALL


func show_save_failure() -> void:
	set_committing(false)
	_error_label.text = UiCopyType.text(
		&"ui.title.settings_save_failed",
		"Settings could not be saved. Review the draft and try again.",
	)
	_error_label.visible = true
	_apply_button.grab_focus.call_deferred()


func draft() -> Dictionary:
	return _draft.duplicate(true)


func layout_mode() -> StringName:
	return _layout_mode


func body_scroll() -> ScrollContainer:
	return _body_scroll


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _committing:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_request_cancel()


func _request_cancel() -> void:
	if visible and not _committing:
		cancel_requested.emit()


func _request_apply() -> void:
	if visible and not _committing:
		apply_requested.emit(_draft.duplicate(true))


func _on_locale_selected(locale_id: StringName) -> void:
	if _suppress_callbacks or _committing:
		return
	_draft[&"locale"] = locale_id
	if I18n.locale() != locale_id:
		I18n.set_locale(locale_id)
	preview_requested.emit(_draft.duplicate(true))


func _on_volume_changed(value: float, key: StringName) -> void:
	if _suppress_callbacks or _committing:
		return
	_draft[key] = value / 100.0
	preview_requested.emit(_draft.duplicate(true))
	_refresh_copy()


func _toggle_music() -> void:
	if _committing:
		return
	_draft[&"title_music_enabled"] = not bool(_draft.get(&"title_music_enabled", true))
	preview_requested.emit(_draft.duplicate(true))
	Sfx.play("ui_click")
	_refresh_copy()


func _on_frame_selected(index: int) -> void:
	if _suppress_callbacks or _committing or index < 0 or index >= FRAME_LIMITS.size():
		return
	_draft[&"frame_limit"] = FRAME_LIMITS[index]
	preview_requested.emit(_draft.duplicate(true))
	Sfx.play("ui_click")


func _toggle_motion() -> void:
	if _committing:
		return
	_draft[&"reduced_motion"] = not bool(_draft.get(&"reduced_motion", false))
	preview_requested.emit(_draft.duplicate(true))
	Sfx.play("ui_click")
	_refresh_copy()


func _on_locale_changed(_locale_id: StringName) -> void:
	_refresh_copy()
	_locale_selector.set_selected_locale(StringName(_draft.get(&"locale", I18n.locale())))
	var focus_owner := get_viewport().gui_get_focus_owner()
	_apply_responsive_layout()
	if focus_owner != null and is_ancestor_of(focus_owner):
		focus_owner.grab_focus.call_deferred()
		_ensure_focus_visible.call_deferred()


func _sync_controls() -> void:
	_suppress_callbacks = true
	_locale_selector.set_selected_locale(StringName(_draft.get(&"locale", I18n.locale())))
	_master_slider.value = float(_draft.get(&"master_volume", 1.0)) * 100.0
	_music_slider.value = float(_draft.get(&"music_volume", 1.0)) * 100.0
	_sfx_slider.value = float(_draft.get(&"sfx_volume", 1.0)) * 100.0
	_frame_option.select(maxi(FRAME_LIMITS.find(int(_draft.get(&"frame_limit", 0))), 0))
	_suppress_callbacks = false


func _refresh_copy() -> void:
	if not is_node_ready():
		return
	_title_label.text = UiCopyType.text(&"ui.title.settings", "Settings").to_upper()
	_audio_heading.text = UiCopyType.text(&"ui.title.audio", "Audio").to_upper()
	_graphics_heading.text = UiCopyType.text(&"ui.title.graphics", "Graphics").to_upper()
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
	for heading: Label in [_audio_heading, _graphics_heading]:
		StagingSkinType.apply_display_type(heading, _title_font_size(18), GOLD, 620)
	for label: Label in [_master_label, _music_label, _sfx_label, _frame_label]:
		StagingSkinType.apply_display_type(label, _title_font_size(15), MUTED, 560)
	for action: Button in [_back_button, _music_button, _motion_button, _apply_button]:
		StagingSkinType.apply_display_type(action, _title_font_size(17), IVORY, 560)
	StagingSkinType.apply_display_type(_frame_option, _title_font_size(16), IVORY, 560)
	var locale_label := _locale_selector.get_node("LocaleLabel") as Label
	StagingSkinType.apply_display_type(locale_label, _title_font_size(17), GOLD, 560)
	StagingSkinType.apply_display_type(_locale_list, _title_font_size(20), IVORY, 560)


func _apply_responsive_layout() -> void:
	if not is_node_ready():
		return
	var viewport := size
	if viewport.x <= 0.0 or viewport.y <= 0.0:
		viewport = get_viewport_rect().size
	var narrow := viewport.x <= 720.0
	var portrait := viewport.x / maxf(viewport.y, 1.0) <= 1.2
	var short := viewport.y <= 560.0
	var wide := viewport.x >= 1200.0 and not portrait and not narrow
	var two_columns := viewport.x >= 840.0 and not portrait and not narrow
	_layout_mode = &"wide" if wide else (&"narrow" if narrow else (&"portrait" if portrait else &"regular"))
	if short:
		_layout_mode = StringName("%s_short" % _layout_mode)
	var horizontal_gutter := clampi(roundi(viewport.x * 0.033), 10, 42)
	var vertical_gutter := clampi(roundi(viewport.y * 0.028), 10 if short else 12, 32)
	_set_margins(_safe_frame, horizontal_gutter, vertical_gutter)
	var frame_style := StagingSkinType.command_deck_style()
	var frame_content_margin := 4.0 if narrow else 28.0
	frame_style.content_margin_left = frame_content_margin
	frame_style.content_margin_top = frame_content_margin
	frame_style.content_margin_right = frame_content_margin
	frame_style.content_margin_bottom = frame_content_margin
	_command_frame.add_theme_stylebox_override(&"panel", frame_style)
	var padding := 0 if narrow else (10 if short else 22)
	_set_margins(_frame_padding, padding, padding)
	_state_layout.add_theme_constant_override(&"separation", 6 if short else 12)
	_header.add_theme_constant_override(&"separation", 6 if narrow else 14)
	_header_seal.visible = not narrow
	_header.custom_minimum_size.y = 72.0 if narrow or short else 96.0
	_columns.columns = 2 if two_columns else 1
	_columns.add_theme_constant_override(&"h_separation", 20 if wide else 0)
	_columns.add_theme_constant_override(&"v_separation", 12)
	_locale_selector.set_vertical_layout(narrow or portrait)
	_locale_selector.set_compact_mode(narrow or short)
	_frame_row.vertical = narrow or portrait
	_frame_option.custom_minimum_size.x = 0.0 if narrow or portrait else 180.0
	_action_dock.columns = 1
	_apply_button.custom_minimum_size.y = 76.0 if short else _title_size(76.0)
	_back_button.text = "←" if narrow else UiCopyType.text(&"ui.common.back", "Back").to_upper()
	_back_button.custom_minimum_size = Vector2(48.0 if narrow else 190.0, 72.0 if short else _title_size(76.0))
	_frame_option.custom_minimum_size.y = 72.0
	_music_button.custom_minimum_size.y = 82.0
	_motion_button.custom_minimum_size.y = 92.0 if narrow else 82.0
	_title_label.add_theme_font_size_override(&"font_size", _title_font_size(16 if narrow else (30 if portrait else 36)))
	_back_button.add_theme_font_size_override(&"font_size", _title_font_size(13 if narrow else 17))
	_music_button.add_theme_font_size_override(&"font_size", _title_font_size(13 if narrow else 17))
	_motion_button.add_theme_font_size_override(&"font_size", _title_font_size(11 if narrow else 17))
	_apply_button.add_theme_font_size_override(&"font_size", _title_font_size(15 if narrow else 17))
	for action: Button in [_back_button, _music_button, _motion_button, _apply_button]:
		action.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		action.clip_text = false
	_rebuild_focus_graph()
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
		current.focus_neighbor_top = current.get_path_to(previous)
		current.focus_next = current.get_path_to(following)
		current.focus_neighbor_bottom = current.get_path_to(following)
		current.focus_neighbor_left = current.get_path_to(previous)
		current.focus_neighbor_right = current.get_path_to(following)


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
		_apply_button,
	]


func _ensure_focus_visible() -> void:
	if not visible:
		return
	var focused := get_viewport().gui_get_focus_owner()
	if focused != null and _body_scroll.is_ancestor_of(focused):
		_body_scroll.ensure_control_visible(focused)


func _set_margins(container: MarginContainer, horizontal: int, vertical: int) -> void:
	container.add_theme_constant_override(&"margin_left", horizontal)
	container.add_theme_constant_override(&"margin_right", horizontal)
	container.add_theme_constant_override(&"margin_top", vertical)
	container.add_theme_constant_override(&"margin_bottom", vertical)


func _title_size(value: float) -> float:
	return value * TITLE_UI_SCALE


func _title_font_size(value: int) -> int:
	return roundi(float(value) * TITLE_UI_SCALE * TITLE_FONT_SCALE)
