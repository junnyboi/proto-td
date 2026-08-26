extends Control

const Style := preload("res://scripts/ui/components/lunaris_ops_style.gd")
const ClassDefType := preload("res://data/class_def.gd")
const ResonanceStarType := preload("res://scripts/ui/components/resonance_star.gd")
const CinematicPlayerType := preload("res://scripts/ui/components/gacha_cinematic_player.gd")
const HistoryDrawerType := preload("res://scripts/ui/components/gacha_history_drawer.gd")
const UiCopyType := preload("res://scripts/ui/components/ui_copy.gd")
const LUNARIS_BACKDROP := preload("res://assets/loading/lunaris_reliquary_loading.png")

const HARD_PITY_WINDOW := 10
const FIVE_STAR_RARITY := 5
const CINEMATIC_WATCHDOG_SECONDS := 8.75
const CINEMATIC_WATCHDOG_POLL_SECONDS := 0.5
const REVEAL_NAME_FADE_SECONDS := 0.42
const REVEAL_STAR_GROW_SECONDS := 0.56
const REVEAL_STAR_PULSE_SECONDS := 0.82
const REVEAL_MUSIC_CROSSFADE_SECONDS := 0.75
const REVEAL_SKIP_CROSSFADE_SECONDS := 0.35
const IDENTITY_REVEAL_SFX := "gacha_identity_reveal"
const STAR_BLOOM_SFX := "gacha_star_bloom"
const RETURN_ICON_ID := &"ui_gacha_return"
const HISTORY_ICON_ID := &"ui_gacha_moon_archive"
const RESERVE_LIFE_ICON_ID := &"ui_gacha_reserve_life"
const GACHA_FULLSIZE_PORTRAITS := {
	"archive_caster": &"portrait_archive_caster_fullsize",
	"lunaris_vessel": &"portrait_lunaris_vessel_fullsize",
	"reliquary_duelist": &"portrait_reliquary_duelist_fullsize",
}
const CONFIRM_ENTRY_SECONDS := 0.20
const CONFIRM_EXIT_SECONDS := 0.15
const CONFIRM_FRAME_OFFSET := 12.0
const CONFIRM_READABLE_MAX_WIDTH := 1480.0
const CONFIRM_ACTION_SIZE := Vector2(280.0, 92.0)
const CONFIRM_ACTION_HORIZONTAL_PADDING := 32.0
const CONFIRM_ACTION_VERTICAL_PADDING := 18.0
const BROWSE_PULL_WIDTH := 800.0
const BROWSE_PULL_HEIGHT := 112.0
const BROWSE_CARD_SIZE := Vector2(480.0, 645.0)
const BROWSE_PORTRAIT_HEIGHT := 420.0
const BROWSE_PORTRAIT_ZOOM := 1.25
const BROWSE_CARD_PADDING := 24.0
const REVEAL_PULL_AGAIN_SIZE := Vector2(780.0, 88.0)
const CONVERSION_FADE_SECONDS := 0.34
const CONVERSION_PULSE_SECONDS := 1.10

enum FlowState {
	BROWSE,
	CONFIRM,
	COMMITTING,
	REVEAL,
}

enum ConfirmationTransition {
	NONE,
	ENTERING,
	OPEN,
	EXITING,
}

@export var reduced_motion := false

var _game: Node
var _flow_state := FlowState.BROWSE
var _browse_backdrop_art: TextureRect
var _marks_label: Label
var _pull_button: Button
var _pull_action_label: Label
var _pull_cost_label: Label
var _pull_hover_tween: Tween
var _pull_pointer_hovered := false
var _pull_focus_hovered := false
var _back_button: Button
var _history_button: Button
var _header_tools: BoxContainer
var _browse_title: Label
var _status_label: Label
var _hero_grid: GridContainer
var _hero_scroll: ScrollContainer
var _hero_stage: CenterContainer
var _header_grid: GridContainer
var _action_grid: GridContainer
var _marks_safe: MarginContainer
var _screen_margin: MarginContainer
var _pity_label: Label
var _pity_layout: BoxContainer
var _pity_segments: HBoxContainer
var _confirmation_projection: Dictionary = {}
var _confirmation_layer: Control
var _confirmation_safe: MarginContainer
var _confirmation_frame: PanelContainer
var _confirmation_stack: VBoxContainer
var _confirmation_header: GridContainer
var _confirmation_title: Label
var _confirmation_header_cancel: Button
var _confirmation_body_scroll: ScrollContainer
var _confirmation_body_center: CenterContainer
var _confirmation_body_grid: GridContainer
var _confirmation_context_eyebrow: Label
var _confirmation_context_label: Label
var _confirmation_review_eyebrow: Label
var _confirmation_review_label: Label
var _confirmation_action_dock: PanelContainer
var _confirmation_status_label: Label
var _confirmation_actions: GridContainer
var _confirmation_cancel: Button
var _confirmation_confirm: Button
var _confirmation_tween: Tween
var _confirmation_transition := ConfirmationTransition.NONE
var _confirmation_transition_token := 0
var _focus_request_token := 0
var _confirmation_return_focus: Control
var _confirmation_exit_status := ""
var _confirmation_exit_live := AccessibilityServer.LIVE_OFF
var _premium_pull_dispatched := false
var _history_drawer: GachaHistoryDrawer
var _history_return_focus: Control

var _reveal_layer: Control
var _reveal_shade: ColorRect
var _cinematic_player: GachaCinematicPlayer
var _reveal_title_stack: VBoxContainer
var _reveal_title: Label
var _reveal_stars: HBoxContainer
var _reveal_hint: Label
var _conversion_panel: PanelContainer
var _conversion_icon: TextureRect
var _conversion_title: Label
var _conversion_outcome: Label
var _conversion_detail: Label
var _conversion_pulse_tween: Tween
var _reveal_pull_again: Button
var _skip_button: Button
var _reveal_tween: Tween
var _cinematic_watchdog: Tween
var _star_pulse_tweens: Array[Tween] = []
var _is_revealing := false
var _reveal_result_ready := false
var _pending_pull: Dictionary = {}


func _ready() -> void:
	_game = get_node_or_null("/root/Game")
	if _game != null:
		_game.set("content", self)
	clip_contents = true
	Style.add_backdrop(self, LUNARIS_BACKDROP)
	_browse_backdrop_art = get_node_or_null("AstralBackdropArt") as TextureRect
	_build_screen()
	_build_history_drawer()
	_build_reveal_layer()
	get_viewport().size_changed.connect(_apply_responsive_layout)
	var i18n := get_node_or_null("/root/I18n")
	if i18n != null and i18n.has_signal("locale_changed"):
		i18n.connect("locale_changed", _on_locale_changed)
	_apply_responsive_layout()
	_refresh()
	_restore_pull_focus()


func _exit_tree() -> void:
	_invalidate_confirmation_transition()
	_confirmation_transition = ConfirmationTransition.NONE
	if _pull_hover_tween != null and _pull_hover_tween.is_valid():
		_pull_hover_tween.kill()
	_kill_reveal_tween()
	_kill_cinematic_watchdog()
	_stop_star_pulses()
	_stop_conversion_pulse()
	_stop_cinematic()
	if _history_drawer != null:
		_history_drawer.force_hide()


func _input(event: InputEvent) -> void:
	if not event.is_pressed():
		return
	if (
			_flow_state == FlowState.REVEAL
			and _reveal_result_ready
			and (event is InputEventMouseButton or event is InputEventScreenTouch)
	):
		if _event_hits_reveal_action(event):
			return
		get_viewport().set_input_as_handled()
		_finish_reveal()
		return
	if event is InputEventKey and event.echo:
		get_viewport().set_input_as_handled()
		return
	if (
			_confirmation_transition == ConfirmationTransition.ENTERING
			and event.is_action(&"ui_cancel")
	):
		get_viewport().set_input_as_handled()
		_on_pull_cancelled()
		return
	if (
			_flow_state == FlowState.COMMITTING
			or _confirmation_transition in [
				ConfirmationTransition.ENTERING, ConfirmationTransition.EXITING,
			]
	):
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if _history_drawer != null and _history_drawer.is_open():
		if event.is_action(&"ui_cancel"):
			get_viewport().set_input_as_handled()
			_close_pull_history()
		return
	if (
			_confirmation_transition == ConfirmationTransition.ENTERING
			and event.is_action(&"ui_cancel")
	):
		get_viewport().set_input_as_handled()
		_on_pull_cancelled()
		return
	if (
			_flow_state == FlowState.COMMITTING
			or _confirmation_transition in [
				ConfirmationTransition.ENTERING, ConfirmationTransition.EXITING,
			]
	):
		get_viewport().set_input_as_handled()
		return
	if (
		_flow_state == FlowState.REVEAL
		and _reveal_result_ready
		and (event.is_action(&"ui_accept") or event.is_action(&"ui_cancel"))
	):
		get_viewport().set_input_as_handled()
		if (
				event.is_action(&"ui_accept")
				and get_viewport().gui_get_focus_owner() == _reveal_pull_again
				and not _reveal_pull_again.disabled
		):
			_on_pull_again_pressed()
			return
		_finish_reveal()
		return
	if _flow_state == FlowState.CONFIRM and event.is_action(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_pull_cancelled()
		return
	if _flow_state == FlowState.BROWSE and event.is_action(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back_pressed()


func _on_reveal_gui_input(event: InputEvent) -> void:
	if not _is_revealing or not _reveal_result_ready:
		return
	if event is InputEventMouseButton and event.pressed:
		accept_event()
		_finish_reveal()
	elif event is InputEventScreenTouch and event.pressed:
		accept_event()
		_finish_reveal()


func _build_screen() -> void:
	_screen_margin = MarginContainer.new()
	_screen_margin.name = "PremiumBrowseSafeFrame"
	_screen_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_screen_margin)

	var content := VBoxContainer.new()
	content.name = "PremiumBrowseContent"
	content.add_theme_constant_override(&"separation", 16)
	_screen_margin.add_child(content)

	_header_grid = GridContainer.new()
	_header_grid.name = "PremiumBrowseHeader"
	_header_grid.columns = 3
	_header_grid.add_theme_constant_override(&"h_separation", 16)
	_header_grid.add_theme_constant_override(&"v_separation", 10)
	content.add_child(_header_grid)
	_back_button = Button.new()
	_back_button.name = "BackButton"
	_back_button.text = _copy(&"ui.gacha.back", "RETURN")
	_back_button.icon = Art.texture(RETURN_ICON_ID)
	_back_button.expand_icon = true
	_back_button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_back_button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	_back_button.add_theme_constant_override(&"icon_max_width", 54)
	_back_button.custom_minimum_size = Vector2(300, 76)
	_back_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_back_button.autowrap_mode = TextServer.AUTOWRAP_OFF
	_back_button.clip_text = false
	_back_button.pressed.connect(_on_back_pressed)
	Style.apply_button(_back_button, &"quiet")
	_back_button.add_theme_font_size_override(&"font_size", 36)
	_header_grid.add_child(_back_button)
	var title_box := VBoxContainer.new()
	title_box.name = "PremiumTitleCenter"
	title_box.alignment = BoxContainer.ALIGNMENT_CENTER
	title_box.custom_minimum_size.y = 76.0
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_header_grid.add_child(title_box)
	_browse_title = _label(_copy(&"ui.gacha.title", "Premium Resonance"), &"title")
	_browse_title.name = "PremiumBrowseTitle"
	_browse_title.custom_minimum_size.x = 0
	_browse_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_browse_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_box.add_child(_browse_title)
	_marks_safe = MarginContainer.new()
	_marks_safe.name = "MarksSafeMargin"
	_marks_safe.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_header_grid.add_child(_marks_safe)
	_header_tools = BoxContainer.new()
	_header_tools.name = "PremiumHeaderTools"
	_header_tools.vertical = false
	_header_tools.alignment = BoxContainer.ALIGNMENT_END
	_header_tools.add_theme_constant_override(&"separation", 12)
	_marks_safe.add_child(_header_tools)
	_history_button = Button.new()
	_history_button.name = "PullHistoryButton"
	_history_button.text = _copy(&"ui.gacha.history_action", "HISTORY")
	_history_button.icon = Art.texture(HISTORY_ICON_ID)
	_history_button.expand_icon = true
	_history_button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_history_button.add_theme_constant_override(&"icon_max_width", 42)
	_history_button.custom_minimum_size = Vector2(210, 68)
	_history_button.autowrap_mode = TextServer.AUTOWRAP_OFF
	_history_button.clip_text = false
	_history_button.pressed.connect(_open_pull_history)
	Style.apply_button(_history_button, &"quiet")
	_history_button.add_theme_font_size_override(&"font_size", 27)
	_header_tools.add_child(_history_button)
	_marks_label = _label("0 MARKS", &"metric")
	_marks_label.name = "MarksLabel"
	_marks_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_marks_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_marks_label.add_theme_color_override(&"font_color", Style.GOLD)
	_marks_label.add_theme_font_size_override(&"font_size", 57)
	_header_tools.add_child(_marks_label)

	_pity_layout = BoxContainer.new()
	_pity_layout.name = "GuaranteeTelemetry"
	_pity_layout.add_theme_constant_override(&"separation", 18)
	content.add_child(_pity_layout)
	_pity_label = _label(_copy(&"ui.gacha.guarantee", "5-STAR GUARANTEE"), &"detail")
	_pity_label.name = "PityLabel"
	_pity_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_pity_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_pity_label.add_theme_color_override(&"font_color", Style.GOLD)
	_pity_label.add_theme_font_size_override(&"font_size", 30)
	_pity_layout.add_child(_pity_label)
	_pity_segments = HBoxContainer.new()
	_pity_segments.name = "PitySegments"
	_pity_segments.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_pity_segments.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_pity_segments.add_theme_constant_override(&"separation", 5)
	_pity_layout.add_child(_pity_segments)
	for index: int in HARD_PITY_WINDOW:
		var segment := ColorRect.new()
		segment.name = "Pity_%02d" % (index + 1)
		segment.custom_minimum_size = Vector2(58, 12)
		segment.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		segment.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		segment.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_pity_segments.add_child(segment)

	var scroll := ScrollContainer.new()
	scroll.name = "PremiumHeroScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_hero_scroll = scroll
	content.add_child(scroll)
	var hero_stage := CenterContainer.new()
	hero_stage.name = "PremiumHeroStage"
	hero_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_hero_stage = hero_stage
	scroll.add_child(hero_stage)
	_hero_grid = GridContainer.new()
	_hero_grid.name = "PremiumHeroGrid"
	_hero_grid.columns = 3
	_hero_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_hero_grid.add_theme_constant_override(&"h_separation", 16)
	_hero_grid.add_theme_constant_override(&"v_separation", 16)
	hero_stage.add_child(_hero_grid)

	_action_grid = GridContainer.new()
	_action_grid.name = "PremiumBrowseActions"
	_action_grid.columns = 1
	_action_grid.add_theme_constant_override(&"h_separation", 18)
	_action_grid.add_theme_constant_override(&"v_separation", 10)
	content.add_child(_action_grid)
	_status_label = _label("", &"detail")
	_status_label.name = "PullStatusLabel"
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.visible = false
	_status_label.accessibility_name = _copy(&"ui.gacha.status_name", "Premium resonance status")
	_status_label.accessibility_live = AccessibilityServer.LIVE_OFF
	_action_grid.add_child(_status_label)
	_pull_button = Button.new()
	_pull_button.name = "PremiumPullButton"
	_pull_button.custom_minimum_size = Vector2(BROWSE_PULL_WIDTH, BROWSE_PULL_HEIGHT)
	_pull_button.pressed.connect(_on_pull_pressed)
	_pull_button.mouse_entered.connect(_on_pull_hover_changed.bind(true, false))
	_pull_button.mouse_exited.connect(_on_pull_hover_changed.bind(false, false))
	_pull_button.focus_entered.connect(_on_pull_hover_changed.bind(true, true))
	_pull_button.focus_exited.connect(_on_pull_hover_changed.bind(false, true))
	_pull_button.resized.connect(_refresh_pull_pivot)
	_pull_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_pull_button.autowrap_mode = TextServer.AUTOWRAP_OFF
	_pull_button.clip_text = true
	var transparent := Color(0.0, 0.0, 0.0, 0.0)
	for color_name: StringName in [
		&"font_color", &"font_hover_color", &"font_pressed_color",
		&"font_focus_color", &"font_disabled_color",
	]:
		_pull_button.add_theme_color_override(color_name, transparent)
	var pull_presentation := VBoxContainer.new()
	pull_presentation.name = "PremiumPullPresentation"
	pull_presentation.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pull_presentation.alignment = BoxContainer.ALIGNMENT_CENTER
	pull_presentation.add_theme_constant_override(&"separation", 0)
	pull_presentation.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pull_button.add_child(pull_presentation)
	_pull_action_label = _label(_copy(&"ui.gacha.resonate", "RESONATE"), &"heading")
	_pull_action_label.name = "PremiumPullActionLabel"
	_pull_action_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pull_action_label.add_theme_font_size_override(&"font_size", 48)
	_pull_action_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pull_presentation.add_child(_pull_action_label)
	_pull_cost_label = _label("40 MARKS", &"detail")
	_pull_cost_label.name = "PremiumPullCostLabel"
	_pull_cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pull_cost_label.add_theme_font_size_override(&"font_size", 27)
	_pull_cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pull_presentation.add_child(_pull_cost_label)
	var pull_center := CenterContainer.new()
	pull_center.name = "PremiumPullActionCenter"
	pull_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pull_center.add_child(_pull_button)
	_action_grid.add_child(pull_center)


func _build_history_drawer() -> void:
	_history_drawer = HistoryDrawerType.new()
	_history_drawer.reduced_motion = _motion_reduced()
	_history_drawer.close_requested.connect(_close_pull_history)
	_history_drawer.closed.connect(_on_pull_history_closed)
	add_child(_history_drawer)


func _build_pull_confirmation() -> void:
	_confirmation_layer = Control.new()
	_confirmation_layer.name = "PremiumPullConfirmationLayer"
	_confirmation_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_confirmation_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_confirmation_layer.z_index = 100
	_confirmation_layer.visible = false
	_confirmation_layer.modulate.a = 0.0
	_confirmation_layer.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
	add_child(_confirmation_layer)

	var background := ColorRect.new()
	background.name = "ConfirmationAtmosphere"
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Style.INK_DEEP
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	_confirmation_layer.add_child(background)
	var atmosphere := TextureRect.new()
	atmosphere.name = "ConfirmationAtmosphereArt"
	atmosphere.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	atmosphere.texture = LUNARIS_BACKDROP
	atmosphere.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	atmosphere.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	atmosphere.modulate = Color(0.42, 0.62, 0.72, 0.30)
	atmosphere.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_confirmation_layer.add_child(atmosphere)

	_confirmation_safe = MarginContainer.new()
	_confirmation_safe.name = "ConfirmationSafeFrame"
	_confirmation_safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_confirmation_layer.add_child(_confirmation_safe)
	_confirmation_frame = PanelContainer.new()
	_confirmation_frame.name = "ConfirmationCommandFrame"
	_confirmation_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_confirmation_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_confirmation_frame.offset_transform_position = Vector2(0.0, CONFIRM_FRAME_OFFSET)
	Style.apply_panel(_confirmation_frame, &"screen")
	_confirmation_safe.add_child(_confirmation_frame)

	_confirmation_stack = VBoxContainer.new()
	_confirmation_stack.name = "ConfirmationStateLayout"
	_confirmation_stack.add_theme_constant_override(&"separation", 14)
	_confirmation_frame.add_child(_confirmation_stack)
	_confirmation_header = GridContainer.new()
	_confirmation_header.name = "ConfirmationHeader"
	_confirmation_header.columns = 2
	_confirmation_header.add_theme_constant_override(&"separation", 16)
	_confirmation_stack.add_child(_confirmation_header)
	_confirmation_header_cancel = Button.new()
	_confirmation_header_cancel.name = "CancelPremiumPull"
	_confirmation_header_cancel.custom_minimum_size = Vector2(0, 88)
	_confirmation_header_cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_prepare_confirmation_button(_confirmation_header_cancel)
	_confirmation_header_cancel.pressed.connect(_on_pull_cancelled)
	Style.apply_button(_confirmation_header_cancel, &"quiet")
	_confirmation_header_cancel.add_theme_font_size_override(&"font_size", 54)
	_confirmation_header_cancel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_confirmation_header_cancel.clip_text = false
	_confirmation_header.add_child(_confirmation_header_cancel)
	_confirmation_title = _label("", &"title")
	_confirmation_title.name = "ConfirmationTitle"
	_confirmation_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_confirmation_title.custom_minimum_size.x = 0
	_confirmation_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_confirmation_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_confirmation_title.add_theme_font_size_override(&"font_size", 114)
	_confirmation_header.add_child(_confirmation_title)
	var header_rule := ColorRect.new()
	header_rule.name = "ConfirmationHeaderRule"
	header_rule.custom_minimum_size = Vector2(0, 2)
	header_rule.color = Color(Style.CYAN, 0.66)
	header_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_confirmation_stack.add_child(header_rule)

	_confirmation_body_scroll = ScrollContainer.new()
	_confirmation_body_scroll.name = "ConfirmationBodyScroll"
	_confirmation_body_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_confirmation_body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_confirmation_body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_confirmation_body_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_confirmation_body_scroll.follow_focus = true
	_confirmation_stack.add_child(_confirmation_body_scroll)
	_confirmation_body_center = CenterContainer.new()
	_confirmation_body_center.name = "ConfirmationReadableBody"
	_confirmation_body_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_confirmation_body_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_confirmation_body_scroll.add_child(_confirmation_body_center)
	_confirmation_body_grid = GridContainer.new()
	_confirmation_body_grid.name = "ConfirmationBodyGrid"
	_confirmation_body_grid.columns = 2
	_confirmation_body_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_confirmation_body_grid.add_theme_constant_override(&"h_separation", 22)
	_confirmation_body_grid.add_theme_constant_override(&"v_separation", 14)
	_confirmation_body_center.add_child(_confirmation_body_grid)

	var context_panel := PanelContainer.new()
	context_panel.name = "ConfirmationContextPanel"
	context_panel.custom_minimum_size.y = 196.0
	context_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Style.apply_panel(context_panel, &"quiet")
	var context_style := Style.panel_style(&"quiet")
	context_style.content_margin_left = 28.0
	context_style.content_margin_top = 28.0
	context_style.content_margin_right = 28.0
	context_style.content_margin_bottom = 28.0
	context_panel.add_theme_stylebox_override(&"panel", context_style)
	_confirmation_body_grid.add_child(context_panel)
	var context_stack := VBoxContainer.new()
	context_stack.add_theme_constant_override(&"separation", 10)
	context_panel.add_child(context_stack)
	_confirmation_context_eyebrow = _label(
		_copy(&"ui.gacha.eyebrow", "LUNARIS RELIQUARY"), &"eyebrow",
	)
	_confirmation_context_eyebrow.name = "ConfirmationContextEyebrow"
	_confirmation_context_eyebrow.add_theme_font_size_override(&"font_size", 42)
	context_stack.add_child(_confirmation_context_eyebrow)
	_confirmation_context_label = _label("", &"body")
	_confirmation_context_label.name = "ConfirmationContextCopy"
	_confirmation_context_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_confirmation_context_label.custom_minimum_size.x = 0
	_confirmation_context_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_confirmation_context_label.add_theme_font_size_override(&"font_size", 54)
	context_stack.add_child(_confirmation_context_label)

	var review_panel := PanelContainer.new()
	review_panel.name = "ConfirmationTransactionPanel"
	review_panel.custom_minimum_size.y = 196.0
	review_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Style.apply_panel(review_panel, &"result")
	var review_style := Style.panel_style(&"result")
	review_style.content_margin_left = 28.0
	review_style.content_margin_top = 28.0
	review_style.content_margin_right = 28.0
	review_style.content_margin_bottom = 28.0
	review_panel.add_theme_stylebox_override(&"panel", review_style)
	_confirmation_body_grid.add_child(review_panel)
	var review_stack := VBoxContainer.new()
	review_stack.add_theme_constant_override(&"separation", 10)
	review_panel.add_child(review_stack)
	_confirmation_review_eyebrow = _label(
		_copy(&"ui.gacha.guarantee", "5-STAR GUARANTEE"), &"eyebrow",
	)
	_confirmation_review_eyebrow.name = "ConfirmationReviewEyebrow"
	_confirmation_review_eyebrow.add_theme_font_size_override(&"font_size", 42)
	review_stack.add_child(_confirmation_review_eyebrow)
	_confirmation_review_label = _label("", &"body")
	_confirmation_review_label.name = "ConfirmationTransactionCopy"
	_confirmation_review_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_confirmation_review_label.custom_minimum_size.x = 0
	_confirmation_review_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_confirmation_review_label.add_theme_font_size_override(&"font_size", 54)
	review_stack.add_child(_confirmation_review_label)

	_confirmation_action_dock = PanelContainer.new()
	_confirmation_action_dock.name = "ConfirmationActionDock"
	Style.apply_panel(_confirmation_action_dock, &"quiet")
	_confirmation_stack.add_child(_confirmation_action_dock)
	var dock_stack := VBoxContainer.new()
	dock_stack.name = "ConfirmationDockStack"
	dock_stack.add_theme_constant_override(&"separation", 8)
	_confirmation_action_dock.add_child(dock_stack)
	_confirmation_status_label = _label("", &"detail")
	_confirmation_status_label.name = "ConfirmationStatusLabel"
	_confirmation_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_confirmation_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_confirmation_status_label.accessibility_live = AccessibilityServer.LIVE_POLITE
	_confirmation_status_label.visible = false
	dock_stack.add_child(_confirmation_status_label)
	_confirmation_actions = GridContainer.new()
	_confirmation_actions.name = "ConfirmationActions"
	_confirmation_actions.columns = 2
	_confirmation_actions.size_flags_horizontal = Control.SIZE_SHRINK_END
	_confirmation_actions.add_theme_constant_override(&"h_separation", 16)
	_confirmation_actions.add_theme_constant_override(&"v_separation", 12)
	dock_stack.add_child(_confirmation_actions)
	_confirmation_cancel = Button.new()
	_confirmation_cancel.name = "CancelPremiumPullDock"
	_confirmation_cancel.custom_minimum_size = CONFIRM_ACTION_SIZE
	_confirmation_cancel.size_flags_horizontal = Control.SIZE_SHRINK_END
	_prepare_confirmation_button(_confirmation_cancel)
	_confirmation_cancel.pressed.connect(_on_pull_cancelled)
	Style.apply_button(_confirmation_cancel, &"quiet")
	_apply_confirmation_action_style(_confirmation_cancel, false)
	_confirmation_cancel.add_theme_font_size_override(&"font_size", 54)
	_confirmation_cancel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_confirmation_cancel.clip_text = false
	_confirmation_actions.add_child(_confirmation_cancel)
	_confirmation_confirm = Button.new()
	_confirmation_confirm.name = "ConfirmPremiumPull"
	_confirmation_confirm.custom_minimum_size = CONFIRM_ACTION_SIZE
	_confirmation_confirm.size_flags_horizontal = Control.SIZE_SHRINK_END
	_prepare_confirmation_button(_confirmation_confirm)
	_confirmation_confirm.pressed.connect(_on_confirm_pull)
	Style.apply_button(_confirmation_confirm, &"gold")
	_apply_confirmation_action_style(_confirmation_confirm, true)
	_confirmation_confirm.add_theme_font_size_override(&"font_size", 54)
	_confirmation_confirm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_confirmation_confirm.clip_text = false
	_confirmation_actions.add_child(_confirmation_confirm)
	_bind_confirmation_focus_scope(false)
	_refresh_confirmation_copy()
	_refresh_confirmation_accessibility()


func _apply_confirmation_action_style(button: Button, primary: bool) -> void:
	var normal_background := Color(Style.GOLD, 0.96) if primary else Color(0.035, 0.085, 0.125, 0.98)
	var hover_background := Color("f2dc9b") if primary else Color(0.075, 0.17, 0.22, 0.99)
	var pressed_background := Color("c7a95f") if primary else Color(0.025, 0.055, 0.085, 1.0)
	var normal_border := Style.GOLD if primary else Color(Style.CYAN, 0.72)
	var text_color := Style.INK_DEEP if primary else Style.IVORY
	button.add_theme_stylebox_override(
		&"normal", _confirmation_action_box(normal_background, normal_border, 2),
	)
	button.add_theme_stylebox_override(
		&"hover", _confirmation_action_box(hover_background, Style.CYAN, 2),
	)
	button.add_theme_stylebox_override(
		&"pressed", _confirmation_action_box(pressed_background, Style.GOLD, 2),
	)
	button.add_theme_stylebox_override(
		&"focus", _confirmation_action_box(normal_background, Style.CYAN, 3),
	)
	button.add_theme_stylebox_override(
		&"disabled",
		_confirmation_action_box(Color(0.08, 0.11, 0.14, 0.92), Color(Style.MUTED, 0.30), 1),
	)
	for state: StringName in [
		&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color",
	]:
		button.add_theme_color_override(state, text_color)
	button.add_theme_color_override(&"font_disabled_color", Color(Style.MUTED, 0.76))


func _confirmation_action_box(background: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(4)
	style.content_margin_left = CONFIRM_ACTION_HORIZONTAL_PADDING
	style.content_margin_top = CONFIRM_ACTION_VERTICAL_PADDING
	style.content_margin_right = CONFIRM_ACTION_HORIZONTAL_PADDING
	style.content_margin_bottom = CONFIRM_ACTION_VERTICAL_PADDING
	return style


func _build_reveal_layer() -> void:
	_reveal_layer = Control.new()
	_reveal_layer.name = "PullRevealLayer"
	_reveal_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_reveal_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_reveal_layer.gui_input.connect(_on_reveal_gui_input)
	_reveal_layer.visible = false
	_reveal_layer.modulate.a = 0.0
	add_child(_reveal_layer)

	_reveal_shade = ColorRect.new()
	_reveal_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_reveal_shade.color = Color(0.004, 0.008, 0.016, 1.0)
	_reveal_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reveal_layer.add_child(_reveal_shade)

	_cinematic_player = CinematicPlayerType.new()
	_cinematic_player.name = "GachaCinematicPlayer"
	_cinematic_player.cinematic_started.connect(_on_cinematic_started)
	_cinematic_player.cinematic_finished.connect(_on_cinematic_finished)
	_cinematic_player.cinematic_failed.connect(_on_cinematic_failed)
	_reveal_layer.add_child(_cinematic_player)

	var safe_margin := MarginContainer.new()
	safe_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe_margin.add_theme_constant_override(&"margin_left", 24)
	safe_margin.add_theme_constant_override(&"margin_top", 20)
	safe_margin.add_theme_constant_override(&"margin_right", 24)
	safe_margin.add_theme_constant_override(&"margin_bottom", 42)
	safe_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reveal_layer.add_child(safe_margin)
	var overlay_box := VBoxContainer.new()
	overlay_box.add_theme_constant_override(&"separation", 12)
	overlay_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe_margin.add_child(overlay_box)
	var top_row := HBoxContainer.new()
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_box.add_child(top_row)
	var top_spacer := Control.new()
	top_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_child(top_spacer)
	_skip_button = Button.new()
	_skip_button.name = "SkipRevealButton"
	_skip_button.text = _copy(&"ui.gacha.skip_reveal", "SKIP REVEAL")
	_skip_button.custom_minimum_size = Vector2(340, 92)
	_skip_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_skip_button.clip_text = false
	_skip_button.pressed.connect(_finish_reveal)
	Style.apply_button(_skip_button, &"quiet")
	_skip_button.add_theme_font_size_override(&"font_size", 54)
	for state: StringName in [&"normal", &"hover", &"pressed", &"disabled"]:
		var padded_style := _skip_button.get_theme_stylebox(state).duplicate() as StyleBox
		padded_style.content_margin_left = 42.0
		padded_style.content_margin_top = 22.0
		padded_style.content_margin_right = 42.0
		padded_style.content_margin_bottom = 22.0
		_skip_button.add_theme_stylebox_override(state, padded_style)
	top_row.add_child(_skip_button)
	var vertical_spacer := Control.new()
	vertical_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vertical_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_box.add_child(vertical_spacer)
	_reveal_title_stack = VBoxContainer.new()
	_reveal_title_stack.name = "CinematicIdentityReveal"
	_reveal_title_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	_reveal_title_stack.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_reveal_title_stack.custom_minimum_size.x = 680
	_reveal_title_stack.add_theme_constant_override(&"separation", 8)
	_reveal_title_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reveal_title_stack.visible = false
	overlay_box.add_child(_reveal_title_stack)
	_reveal_title = _label(_copy(&"ui.gacha.unknown_signal", "UNKNOWN SIGNAL"), &"title")
	_reveal_title.name = "RevealTitle"
	_reveal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reveal_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reveal_title.add_theme_font_size_override(&"font_size", 156)
	_reveal_title.modulate.a = 0.0
	_reveal_title_stack.add_child(_reveal_title)
	_reveal_stars = HBoxContainer.new()
	_reveal_stars.name = "RarityStars"
	_reveal_stars.alignment = BoxContainer.ALIGNMENT_CENTER
	_reveal_stars.add_theme_constant_override(&"separation", 12)
	_reveal_stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reveal_title_stack.add_child(_reveal_stars)
	for index: int in FIVE_STAR_RARITY:
		var star := ResonanceStarType.new()
		star.name = "Star_%d" % (index + 1)
		star.custom_minimum_size = Vector2(58, 58)
		star.set_state(Style.GOLD, false)
		star.visible = false
		_reveal_stars.add_child(star)
	_conversion_panel = PanelContainer.new()
	_conversion_panel.name = "DuplicateConversionFeedback"
	_conversion_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_conversion_panel.custom_minimum_size = Vector2(620, 112)
	_conversion_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_conversion_panel.visible = false
	_conversion_panel.modulate.a = 0.0
	_conversion_panel.scale = Vector2(0.88, 0.88)
	Style.apply_panel(_conversion_panel, &"selected")
	var conversion_style := _conversion_panel.get_theme_stylebox(&"panel").duplicate() as StyleBox
	conversion_style.content_margin_left = 18.0
	conversion_style.content_margin_top = 12.0
	conversion_style.content_margin_right = 22.0
	conversion_style.content_margin_bottom = 12.0
	_conversion_panel.add_theme_stylebox_override(&"panel", conversion_style)
	_reveal_title_stack.add_child(_conversion_panel)
	var conversion_row := HBoxContainer.new()
	conversion_row.name = "DuplicateConversionContent"
	conversion_row.add_theme_constant_override(&"separation", 16)
	conversion_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_conversion_panel.add_child(conversion_row)
	_conversion_icon = TextureRect.new()
	_conversion_icon.name = "ReserveLifeSigil"
	_conversion_icon.texture = Art.texture(RESERVE_LIFE_ICON_ID)
	_conversion_icon.custom_minimum_size = Vector2(82, 82)
	_conversion_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_conversion_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_conversion_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	conversion_row.add_child(_conversion_icon)
	var conversion_copy := VBoxContainer.new()
	conversion_copy.name = "DuplicateConversionCopy"
	conversion_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	conversion_copy.alignment = BoxContainer.ALIGNMENT_CENTER
	conversion_copy.add_theme_constant_override(&"separation", 1)
	conversion_copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	conversion_row.add_child(conversion_copy)
	_conversion_title = _label(
		_copy(&"ui.gacha.conversion_title", "DUPLICATE RESONANCE CONVERTED"), &"eyebrow",
	)
	_conversion_title.name = "DuplicateConversionTitle"
	_conversion_title.add_theme_font_size_override(&"font_size", 24)
	_conversion_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	conversion_copy.add_child(_conversion_title)
	_conversion_outcome = _label(
		_copy(&"ui.gacha.conversion_duplicate", "RESERVE LIFE +1"), &"heading",
	)
	_conversion_outcome.name = "DuplicateConversionOutcome"
	_conversion_outcome.add_theme_font_size_override(&"font_size", 30)
	_conversion_outcome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	conversion_copy.add_child(_conversion_outcome)
	_conversion_detail = _label("", &"detail")
	_conversion_detail.name = "DuplicateConversionDetail"
	_conversion_detail.add_theme_font_size_override(&"font_size", 21)
	_conversion_detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	conversion_copy.add_child(_conversion_detail)
	_reveal_hint = _label(_copy(&"ui.gacha.click_anywhere", "CLICK ANYWHERE TO CONTINUE"), &"eyebrow")
	_reveal_hint.name = "RevealContinueHint"
	_reveal_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reveal_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reveal_hint.add_theme_font_size_override(&"font_size", 42)
	_reveal_hint.modulate.a = 0.0
	_reveal_title_stack.add_child(_reveal_hint)
	_reveal_pull_again = Button.new()
	_reveal_pull_again.name = "PullAgainButton"
	_reveal_pull_again.custom_minimum_size = REVEAL_PULL_AGAIN_SIZE
	_reveal_pull_again.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_reveal_pull_again.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reveal_pull_again.clip_text = false
	_reveal_pull_again.disabled = true
	_reveal_pull_again.focus_mode = Control.FOCUS_NONE
	_reveal_pull_again.visible = false
	_reveal_pull_again.modulate.a = 0.0
	_reveal_pull_again.pressed.connect(_on_pull_again_pressed)
	Style.apply_button(_reveal_pull_again, &"gold")
	_apply_confirmation_action_style(_reveal_pull_again, true)
	_reveal_pull_again.add_theme_font_size_override(&"font_size", 54)
	_reveal_title_stack.add_child(_reveal_pull_again)


func _refresh() -> void:
	if _game == null or not bool(_game.get("campaign_active")) or _game.get("campaign") == null:
		_marks_label.text = _copy(&"ui.gacha.campaign_offline", "CAMPAIGN OFFLINE")
		_set_pull_presentation(
			_copy(&"ui.gacha.pull_unavailable", "PULL UNAVAILABLE"),
			_copy(&"ui.gacha.pull_unavailable", "PULL UNAVAILABLE"),
			"",
		)
		_pull_button.disabled = true
		_back_button.disabled = _flow_state != FlowState.BROWSE
		_history_button.disabled = true
		_apply_pull_button_style(true)
		_set_browse_status(
			_copy(&"ui.gacha.campaign_required", "Start or continue a campaign to access premium resonance."),
			AccessibilityServer.LIVE_OFF,
		)
		return
	var projection: Dictionary = _game.get("campaign").runtime_projection()
	if _history_drawer != null:
		_history_drawer.refresh(projection)
	var marks := int(projection["marks"])
	var cost := int(projection["premium_pull_cost"])
	var pity_streak := int(projection.get("premium_pity_streak", 0))
	var guarantee_in := int(projection.get("premium_guarantee_in", HARD_PITY_WINDOW))
	_marks_label.text = _format(&"ui.gacha.marks", "{count} MARKS", {&"count": marks})
	_set_pull_presentation(
		_format(&"ui.gacha.pull_action", "RESONATE\n{cost} MARKS", {&"cost": cost}),
		_copy(&"ui.gacha.resonate", "RESONATE"),
		_format(&"ui.gacha.marks", "{count} MARKS", {&"count": cost}),
	)
	var attempt_pending := bool(projection.get("attempt_pending", false))
	var browse_locked := _flow_state != FlowState.BROWSE
	_pull_button.disabled = marks < cost or attempt_pending or browse_locked
	_back_button.disabled = browse_locked
	_history_button.disabled = browse_locked or (_history_drawer != null and _history_drawer.is_open())
	_apply_pull_button_style(_pull_button.disabled)
	_pity_label.text = _format(&"ui.gacha.guarantee_in", "5-STAR GUARANTEED IN {count} {unit}", {
		&"count": guarantee_in, &"unit": _pull_unit(guarantee_in).to_upper(),
	})
	for index: int in _pity_segments.get_child_count():
		var segment := _pity_segments.get_child(index) as ColorRect
		segment.color = Style.GOLD if index < pity_streak else Color(Style.CYAN.r, Style.CYAN.g, Style.CYAN.b, 0.16)
	if _flow_state in [FlowState.CONFIRM, FlowState.COMMITTING]:
		_refresh_confirmation_copy()
	_set_browse_status("", AccessibilityServer.LIVE_OFF)
	if attempt_pending:
		_set_browse_status(
			_copy(&"ui.gacha.attempt_pending", "Resolve the active operation before using premium resonance."),
			AccessibilityServer.LIVE_OFF,
		)
	elif marks < cost:
		_set_browse_status(
			_format(&"ui.gacha.marks_needed", "Earn {count} more Marks for another resonance pull.", {&"count": cost - marks}),
			AccessibilityServer.LIVE_OFF,
		)
	_rebuild_cards(projection)


func _rebuild_cards(projection: Dictionary) -> void:
	for child: Node in _hero_grid.get_children():
		child.queue_free()
	var owned := {}
	for hero: Dictionary in projection["premium_heroes"]:
		owned[String(hero["premium_id"])] = hero
	var pool: Array = projection["premium_pool"].duplicate(true)
	pool.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("rarity", 4)) > int(b.get("rarity", 4))
	)
	for row: Dictionary in pool:
		_hero_grid.add_child(_hero_card(row, owned.get(String(row["premium_id"]), {})))
	_apply_hero_card_layout(_hero_grid.columns)


func _hero_card(catalog: Dictionary, hero: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.name = "Premium_%s" % catalog["premium_id"]
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.custom_minimum_size = BROWSE_CARD_SIZE
	Style.apply_panel(panel, &"danger" if not hero.is_empty() and hero["life_status"] == "dead" else &"result")
	var card_style := panel.get_theme_stylebox(&"panel").duplicate() as StyleBox
	card_style.content_margin_left = BROWSE_CARD_PADDING
	card_style.content_margin_top = BROWSE_CARD_PADDING
	card_style.content_margin_right = BROWSE_CARD_PADDING
	card_style.content_margin_bottom = BROWSE_CARD_PADDING
	panel.add_theme_stylebox_override(&"panel", card_style)
	var box := VBoxContainer.new()
	box.name = "PremiumCardContent"
	box.add_theme_constant_override(&"separation", 12)
	panel.add_child(box)
	var portrait_frame := Control.new()
	portrait_frame.name = "PortraitFrame"
	portrait_frame.custom_minimum_size = Vector2(BROWSE_CARD_SIZE.x - BROWSE_CARD_PADDING * 2.0, BROWSE_PORTRAIT_HEIGHT)
	portrait_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	portrait_frame.clip_contents = true
	portrait_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(portrait_frame)
	var portrait := TextureRect.new()
	portrait.name = "Portrait"
	portrait.texture = Art.texture(_gacha_portrait_asset_id(String(catalog["premium_id"])))
	portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_frame.add_child(portrait)
	portrait_frame.resized.connect(_fit_hero_portrait_zoom.bind(portrait_frame, portrait))
	_fit_hero_portrait_zoom(portrait_frame, portrait)
	var name := _label(String(catalog["callsign"]), &"heading")
	name.name = "HeroName"
	name.custom_minimum_size.x = 0.0
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.add_theme_font_size_override(&"font_size", 48)
	box.add_child(name)
	var display_class := _class_name(String(catalog["class_id"]))
	var role := _label(display_class.to_upper(), &"detail")
	role.name = "HeroClass"
	role.custom_minimum_size.x = 0.0
	role.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	role.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	role.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	role.add_theme_font_size_override(&"font_size", 30)
	box.add_child(role)
	var status := _copy(&"ui.gacha.unacquired", "UNACQUIRED")
	if not hero.is_empty():
		var lives := int(hero["premium_lives"])
		status = _format(&"ui.gacha.lives", "{count} {unit}", {&"count": lives, &"unit": _life_unit(lives)})
		if lives == 0:
			status = _copy(&"ui.gacha.locked_lives", "LOCKED • 0 LIVES")
	var status_label := _label(status, &"metric")
	status_label.name = "OwnershipMetric"
	status_label.custom_minimum_size.x = 0.0
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override(&"font_size", 36)
	status_label.add_theme_color_override(
		&"font_color", Style.DANGER if status.begins_with("LOCKED") else Style.CYAN,
	)
	box.add_child(status_label)
	return panel


func _fit_hero_portrait_zoom(frame: Control, portrait: TextureRect) -> void:
	if frame == null or portrait == null:
		return
	portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait.pivot_offset = Vector2(frame.size.x * 0.5, 0.0)
	portrait.scale = Vector2.ONE * BROWSE_PORTRAIT_ZOOM


func _apply_responsive_layout() -> void:
	_fit_browse_backdrop()
	if _hero_grid == null or _header_grid == null or _action_grid == null:
		return
	var viewport_size := get_viewport_rect().size
	var portrait := viewport_size.x < 900.0 or viewport_size.y > viewport_size.x * 1.15
	var compact_landscape := not portrait and viewport_size.x < 1600.0
	_hero_grid.columns = 1 if portrait else (2 if compact_landscape else 3)
	_header_grid.columns = 1 if portrait else 3
	_action_grid.columns = 1
	_header_tools.vertical = portrait
	_header_tools.alignment = (
		BoxContainer.ALIGNMENT_CENTER if portrait else BoxContainer.ALIGNMENT_END
	)
	_marks_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER if portrait else HORIZONTAL_ALIGNMENT_RIGHT
	)
	_marks_label.add_theme_font_size_override(&"font_size", 45 if portrait else 57)
	_history_button.custom_minimum_size = Vector2(
		minf(250.0, viewport_size.x - 48.0) if portrait else 210.0,
		62.0 if portrait else 68.0,
	)
	_history_button.add_theme_font_size_override(&"font_size", 24 if portrait else 27)
	_marks_safe.add_theme_constant_override(&"margin_left", 0)
	_marks_safe.add_theme_constant_override(&"margin_right", 0)
	var side_margin := 24 if portrait else (40 if compact_landscape else 64)
	var vertical_margin := 14 if portrait else 22
	_screen_margin.add_theme_constant_override(&"margin_left", side_margin)
	_screen_margin.add_theme_constant_override(&"margin_top", vertical_margin)
	_screen_margin.add_theme_constant_override(&"margin_right", side_margin)
	_screen_margin.add_theme_constant_override(&"margin_bottom", vertical_margin)
	_back_button.custom_minimum_size.x = minf(300.0, viewport_size.x - float(side_margin * 2))
	_pull_button.custom_minimum_size.x = minf(BROWSE_PULL_WIDTH, viewport_size.x - float(side_margin * 2))
	_pity_layout.vertical = portrait
	_pity_label.custom_minimum_size.x = 0.0 if portrait else 460.0
	_pity_label.add_theme_font_size_override(&"font_size", 18 if portrait else 30)
	for child: Node in _pity_segments.get_children():
		(child as Control).custom_minimum_size = Vector2(
			26.0 if portrait else (42.0 if compact_landscape else 58.0),
			12.0,
		)
	_apply_hero_card_layout(_hero_grid.columns)
	_refresh_pull_pivot()
	_apply_confirmation_layout(viewport_size)
	if _reveal_title_stack != null:
		_reveal_title_stack.custom_minimum_size.x = maxf(280.0, viewport_size.x - 48.0)
	if _reveal_title != null:
		var portrait_title_size := clampi(int(viewport_size.x * 0.165), 66, 108)
		_reveal_title.autowrap_mode = (
			TextServer.AUTOWRAP_WORD_SMART if portrait else TextServer.AUTOWRAP_OFF
		)
		_reveal_title.add_theme_font_size_override(
			&"font_size", portrait_title_size if portrait else 156,
		)
	if _reveal_hint != null:
		_reveal_hint.add_theme_font_size_override(&"font_size", 42)
	if _reveal_pull_again != null:
		_reveal_pull_again.custom_minimum_size = Vector2(600, 84) if portrait else REVEAL_PULL_AGAIN_SIZE
		_reveal_pull_again.add_theme_font_size_override(&"font_size", 45 if portrait else 54)
	if _conversion_panel != null:
		_conversion_panel.custom_minimum_size = Vector2(
			minf(620.0, viewport_size.x - 48.0), 102.0 if portrait else 112.0,
		)
		_conversion_icon.custom_minimum_size = Vector2(64, 64) if portrait else Vector2(82, 82)
		_conversion_title.add_theme_font_size_override(&"font_size", 18 if portrait else 24)
		_conversion_outcome.add_theme_font_size_override(&"font_size", 24 if portrait else 30)
		_conversion_detail.add_theme_font_size_override(&"font_size", 18 if portrait else 21)
	if _skip_button != null:
		_skip_button.custom_minimum_size = Vector2(300 if portrait else 340, 92)
		_skip_button.add_theme_font_size_override(&"font_size", 54)
	if _reveal_stars != null:
		for child: Node in _reveal_stars.get_children():
			var star := child as ResonanceStar
			star.custom_minimum_size = Vector2(46, 46) if portrait else Vector2(58, 58)


func _fit_browse_backdrop() -> void:
	if _browse_backdrop_art == null or _browse_backdrop_art.texture == null:
		return
	var viewport_size := get_viewport_rect().size
	var texture_size := _browse_backdrop_art.texture.get_size()
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0 or texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	var source_aspect := texture_size.x / texture_size.y
	var viewport_aspect := viewport_size.x / viewport_size.y
	var fitted_size: Vector2
	if viewport_aspect > source_aspect:
		fitted_size = Vector2(viewport_size.x, viewport_size.x / source_aspect)
	else:
		fitted_size = Vector2(viewport_size.y * source_aspect, viewport_size.y)
	_browse_backdrop_art.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_browse_backdrop_art.position = Vector2((viewport_size.x - fitted_size.x) * 0.5, 0.0)
	_browse_backdrop_art.size = fitted_size
	_browse_backdrop_art.pivot_offset = Vector2(fitted_size.x * 0.5, 0.0)
	_browse_backdrop_art.stretch_mode = TextureRect.STRETCH_SCALE


func _apply_hero_card_layout(columns: int) -> void:
	if _hero_grid == null:
		return
	var viewport_width := get_viewport_rect().size.x
	var side_margin := 24.0 if columns == 1 else (40.0 if columns == 2 else 64.0)
	var available_width := maxf(0.0, viewport_width - side_margin * 2.0 - 20.0)
	var card_width := BROWSE_CARD_SIZE.x
	if columns > 1:
		card_width = minf(
			BROWSE_CARD_SIZE.x,
			(available_width - float(_hero_grid.get_theme_constant(&"h_separation") * (columns - 1))) / float(columns),
		)
	else:
		card_width = minf(BROWSE_CARD_SIZE.x, available_width)
	_hero_grid.size_flags_horizontal = (
		Control.SIZE_SHRINK_CENTER if columns == 3 else Control.SIZE_EXPAND_FILL
	)
	for child: Node in _hero_grid.get_children():
		var panel := child as PanelContainer
		panel.size_flags_horizontal = (
			Control.SIZE_SHRINK_CENTER if columns == 3 else Control.SIZE_EXPAND_FILL
		)
		panel.custom_minimum_size = Vector2(card_width if columns == 3 else 0.0, BROWSE_CARD_SIZE.y)
		var portrait_frame := panel.find_child("PortraitFrame", true, false) as Control
		var portrait := panel.find_child("Portrait", true, false) as TextureRect
		if portrait_frame != null:
			portrait_frame.custom_minimum_size = Vector2(
				maxf(0.0, card_width - BROWSE_CARD_PADDING * 2.0), BROWSE_PORTRAIT_HEIGHT,
			)
			_fit_hero_portrait_zoom(portrait_frame, portrait)


func _on_pull_pressed() -> void:
	if (
			_flow_state != FlowState.BROWSE
			or _premium_pull_dispatched
			or _pull_button.disabled
			or (_history_drawer != null and _history_drawer.is_open())
	):
		return
	if _game == null or not bool(_game.get("campaign_active")):
		_refresh()
		return
	var campaign: Variant = _game.get("campaign")
	if campaign == null or _game.get("campaign_store") == null:
		_refresh()
		return
	var projection: Dictionary = campaign.runtime_projection()
	var marks := int(projection.get("marks", 0))
	var cost := int(projection.get("premium_pull_cost", 0))
	if cost <= 0 or marks < cost or bool(projection.get("attempt_pending", false)):
		_refresh()
		return
	var focused := get_viewport().gui_get_focus_owner()
	_confirmation_return_focus = focused if _is_focus_candidate(focused) else _pull_button
	_premium_pull_dispatched = true
	_flow_state = FlowState.COMMITTING
	_suppress_browse_focus()
	_pull_button.disabled = true
	_back_button.disabled = true
	var pending_copy := _copy(&"ui.gacha.aligning", "Aligning the reliquary signal…")
	_set_browse_status(pending_copy, AccessibilityServer.LIVE_POLITE)
	Sfx.play("ui_confirm")
	_commit_direct_premium_pull.call_deferred()


func _commit_direct_premium_pull() -> void:
	if _flow_state != FlowState.COMMITTING or not _premium_pull_dispatched:
		return
	var committed: Dictionary = _game.call("pull_premium_hero")
	if not committed.get("accepted", false):
		var error_code := StringName(committed.get("error_code", &"unknown_error"))
		var error_text := _error_copy(error_code)
		_premium_pull_dispatched = false
		_flow_state = FlowState.BROWSE
		_screen_margin.visible = true
		_screen_margin.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_ENABLED
		_refresh()
		_set_browse_status(error_text, AccessibilityServer.LIVE_ASSERTIVE)
		_restore_confirmation_return_focus(_confirmation_transition_token)
		return
	var result: Dictionary = committed.get("result", {})
	var pull: Dictionary = result.get("premium_pull", {})
	_premium_pull_dispatched = false
	_begin_reveal(pull)


func _on_pull_cancelled() -> void:
	if (
			_flow_state != FlowState.CONFIRM
			or _confirmation_transition not in [
				ConfirmationTransition.ENTERING, ConfirmationTransition.OPEN,
			]
	):
		return
	Sfx.play("ui_back")
	_start_confirmation_exit(
		_copy(&"ui.gacha.ready", "The pool is ready."), AccessibilityServer.LIVE_OFF,
	)


func _on_confirm_pull() -> void:
	if (
			_flow_state != FlowState.CONFIRM
			or _confirmation_transition != ConfirmationTransition.OPEN
			or _premium_pull_dispatched
	):
		return
	_flow_state = FlowState.COMMITTING
	_premium_pull_dispatched = true
	Sfx.play("ui_confirm")
	_set_confirmation_pending(true)
	_pull_button.disabled = true
	var pending_copy := _copy(&"ui.gacha.aligning", "Aligning the reliquary signal…")
	_set_confirmation_status(pending_copy, AccessibilityServer.LIVE_POLITE)
	_status_label.text = pending_copy
	_status_label.accessibility_live = AccessibilityServer.LIVE_POLITE
	var commit_token := _confirmation_transition_token
	_commit_premium_pull.bind(commit_token).call_deferred()


func _commit_premium_pull(token: int) -> void:
	if (
			token != _confirmation_transition_token
			or _flow_state != FlowState.COMMITTING
			or _confirmation_transition != ConfirmationTransition.OPEN
			or not _premium_pull_dispatched
	):
		return
	var committed: Dictionary = _game.call("pull_premium_hero")
	if not committed.get("accepted", false):
		var error_code := StringName(committed.get("error_code", &"unknown_error"))
		var error_text := _error_copy(error_code)
		_set_confirmation_status(error_text, AccessibilityServer.LIVE_ASSERTIVE)
		_start_confirmation_exit(error_text, AccessibilityServer.LIVE_ASSERTIVE)
		return
	var result: Dictionary = committed.get("result", {})
	var pull: Dictionary = result.get("premium_pull", {})
	_handoff_confirmation_to_reveal(pull)


func _begin_reveal(pull: Dictionary) -> void:
	if _confirmation_return_focus == null:
		var focused := get_viewport().gui_get_focus_owner()
		_confirmation_return_focus = focused if _is_focus_candidate(focused) else _pull_button
	_suppress_browse_focus()
	_flow_state = FlowState.REVEAL
	_pending_pull = pull.duplicate(true)
	_is_revealing = true
	_reveal_result_ready = false
	_pull_button.disabled = true
	_back_button.disabled = true
	_skip_button.text = _copy(&"ui.gacha.skip_reveal", "SKIP REVEAL")
	_skip_button.visible = true
	var premium_id := String(pull.get("premium_id", ""))
	var row := _pool_row(premium_id)
	var callsign := String(row.get("callsign", pull.get("premium_id", "Unknown Signal")))
	var rarity := int(pull.get("rarity", row.get("rarity", 4)))
	var accent := _reveal_accent(pull)
	_reveal_layer.visible = true
	_reveal_layer.modulate.a = 0.0
	_reveal_shade.color = Color(0.035, 0.025, 0.01, 0.96) if rarity == FIVE_STAR_RARITY else Color(0.01, 0.025, 0.05, 0.94)
	_reveal_title_stack.visible = false
	_reveal_title.text = callsign.to_upper()
	_reveal_title.add_theme_color_override(&"font_color", accent)
	_reveal_title.modulate.a = 0.0
	_reveal_title.scale = Vector2(0.96, 0.96)
	_reveal_hint.visible = bool(pull.get("new_hero", false))
	_reveal_hint.modulate.a = 0.0
	_reset_reveal_pull_again()
	_reset_conversion_feedback()
	for index: int in _reveal_stars.get_child_count():
		var star := _reveal_stars.get_child(index) as ResonanceStar
		star.set_state(accent, false)
		star.visible = false
		star.modulate.a = 0.0
		star.scale = Vector2(0.18, 0.18)
		star.rotation = -TAU * 1.25
	_kill_reveal_tween()
	_kill_cinematic_watchdog()
	_stop_star_pulses()
	_stop_cinematic()
	var motion_reduced := _motion_reduced()
	_cinematic_player.play_cinematic(premium_id, motion_reduced)
	if motion_reduced:
		_reveal_layer.modulate.a = 1.0
		_cinematic_player.show_final_plate()
		_reveal_result_ready = true
		_reveal_identity_immediately(rarity, accent)
		return
	_reveal_tween = create_tween()
	_reveal_tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	_reveal_tween.tween_property(_reveal_layer, "modulate:a", 1.0, 0.18)


func _on_cinematic_started(cue_id: StringName) -> void:
	if not _is_revealing or cue_id.is_empty():
		return
	Music.play_cue(cue_id)
	_kill_cinematic_watchdog()
	_cinematic_watchdog = create_tween()
	_cinematic_watchdog.tween_interval(CINEMATIC_WATCHDOG_SECONDS)
	_cinematic_watchdog.tween_callback(_on_cinematic_watchdog_timeout)


func _on_cinematic_finished() -> void:
	if not _is_revealing:
		return
	_kill_cinematic_watchdog()
	_begin_identity_reveal()


func _on_cinematic_failed(_stream_key: StringName, _reason: String) -> void:
	if _is_revealing:
		call_deferred("_begin_identity_reveal")


func _on_cinematic_watchdog_timeout() -> void:
	_cinematic_watchdog = null
	if not _is_revealing:
		return
	var video := _cinematic_player.video_player()
	if video != null and video.is_playing():
		# Looping films stay active behind the deterministic result UI. If the
		# first-cycle timer ever misses, the watchdog still reveals at 8.75 s.
		_begin_identity_reveal()
		return
	_cinematic_player.show_final_plate()
	_begin_identity_reveal()


func _begin_identity_reveal() -> void:
	if not _is_revealing or _reveal_title_stack.visible:
		return
	_reveal_result_ready = true
	_skip_button.visible = false
	_kill_cinematic_watchdog()
	var video := _cinematic_player.video_player()
	if video == null or not video.is_playing():
		_cinematic_player.show_final_plate()
	var rarity := int(_pending_pull.get("rarity", 4))
	var accent := _reveal_accent(_pending_pull)
	_begin_identity_audio()
	_reveal_title_stack.visible = true
	_reveal_title.modulate.a = 0.0
	_reveal_title.scale = Vector2(0.96, 0.96)
	_reveal_title.pivot_offset = _reveal_title.size * 0.5
	_kill_reveal_tween()
	_reveal_tween = create_tween()
	_reveal_tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	_reveal_tween.tween_property(_reveal_title, "modulate:a", 1.0, REVEAL_NAME_FADE_SECONDS)
	_reveal_tween.parallel().tween_property(_reveal_title, "scale", Vector2.ONE, REVEAL_NAME_FADE_SECONDS)
	for index: int in rarity:
		var star := _reveal_stars.get_child(index) as ResonanceStar
		_reveal_tween.tween_callback(_prepare_reveal_star.bind(star, accent))
		_reveal_tween.tween_property(star, "modulate:a", 1.0, REVEAL_STAR_GROW_SECONDS)
		_reveal_tween.parallel().tween_property(
			star, "scale", Vector2.ONE, REVEAL_STAR_GROW_SECONDS,
		).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_reveal_tween.parallel().tween_property(
			star, "rotation", 0.0, REVEAL_STAR_GROW_SECONDS,
		).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
		_reveal_tween.tween_callback(_start_star_pulse.bind(star))
		_reveal_tween.tween_interval(0.08)
	if not bool(_pending_pull.get("new_hero", false)):
		_reveal_tween.tween_callback(_prepare_conversion_feedback)
		_reveal_tween.tween_property(
			_conversion_panel, "modulate:a", 1.0, CONVERSION_FADE_SECONDS,
		)
		_reveal_tween.parallel().tween_property(
			_conversion_panel, "scale", Vector2.ONE, CONVERSION_FADE_SECONDS,
		).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_reveal_tween.tween_callback(_start_conversion_pulse)
	_reveal_tween.tween_property(_reveal_hint, "modulate:a", 0.78, 0.28)
	_reveal_tween.parallel().tween_property(_reveal_pull_again, "modulate:a", 1.0, 0.28)
	_reveal_tween.tween_callback(_arm_reveal_pull_again)


func _prepare_reveal_star(star: ResonanceStar, accent: Color) -> void:
	star.visible = true
	star.modulate.a = 0.0
	star.scale = Vector2(0.18, 0.18)
	star.rotation = -TAU * 1.25
	star.pivot_offset = star.size * 0.5
	star.set_state(accent, true)


func _start_star_pulse(star: ResonanceStar) -> void:
	if not _is_revealing:
		return
	Sfx.play(STAR_BLOOM_SFX)
	var pulse := create_tween().set_loops()
	pulse.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(star, "scale", Vector2(1.06, 1.06), REVEAL_STAR_PULSE_SECONDS * 0.5)
	pulse.tween_property(star, "scale", Vector2.ONE, REVEAL_STAR_PULSE_SECONDS * 0.5)
	_star_pulse_tweens.append(pulse)


func _prepare_conversion_feedback() -> void:
	if bool(_pending_pull.get("new_hero", false)):
		return
	_refresh_conversion_copy()
	_conversion_panel.visible = true
	_conversion_panel.modulate.a = 0.0
	_conversion_panel.scale = Vector2(0.88, 0.88)
	_conversion_panel.pivot_offset = _conversion_panel.size * 0.5
	_conversion_icon.scale = Vector2.ONE
	_conversion_icon.modulate = Color.WHITE
	_conversion_icon.pivot_offset = _conversion_icon.size * 0.5


func _refresh_conversion_copy() -> void:
	if _conversion_panel == null:
		return
	var revived := bool(_pending_pull.get("revived", false))
	_conversion_title.text = _copy(
		&"ui.gacha.conversion_title", "DUPLICATE RESONANCE CONVERTED",
	)
	_conversion_outcome.text = (
		_copy(&"ui.gacha.conversion_revival", "REVIVAL PROTOCOL • LIFE +1")
		if revived
		else _copy(&"ui.gacha.conversion_duplicate", "RESERVE LIFE +1")
	)
	_conversion_detail.text = _format(
		&"ui.gacha.conversion_detail", "LIVES {before} → {after}",
		{
			&"before": int(_pending_pull.get("lives_before", 0)),
			&"after": int(_pending_pull.get("lives_after", 0)),
		},
	)
	_conversion_panel.accessibility_name = _conversion_title.text
	_conversion_panel.accessibility_description = "%s. %s" % [
		_conversion_outcome.text, _conversion_detail.text,
	]


func _start_conversion_pulse() -> void:
	if not _is_revealing or _motion_reduced() or not _conversion_panel.visible:
		return
	_stop_conversion_pulse()
	_conversion_pulse_tween = create_tween().set_loops()
	_conversion_pulse_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_conversion_pulse_tween.tween_property(
		_conversion_icon, "scale", Vector2(1.045, 1.045), CONVERSION_PULSE_SECONDS * 0.5,
	)
	_conversion_pulse_tween.parallel().tween_property(
		_conversion_icon, "modulate", Color(1.10, 1.07, 1.0, 1.0), CONVERSION_PULSE_SECONDS * 0.5,
	)
	_conversion_pulse_tween.tween_property(
		_conversion_icon, "scale", Vector2.ONE, CONVERSION_PULSE_SECONDS * 0.5,
	)
	_conversion_pulse_tween.parallel().tween_property(
		_conversion_icon, "modulate", Color.WHITE, CONVERSION_PULSE_SECONDS * 0.5,
	)


func _stop_conversion_pulse() -> void:
	if _conversion_pulse_tween != null and _conversion_pulse_tween.is_valid():
		_conversion_pulse_tween.kill()
	_conversion_pulse_tween = null
	if _conversion_icon != null:
		_conversion_icon.scale = Vector2.ONE
		_conversion_icon.modulate = Color.WHITE


func _reset_conversion_feedback() -> void:
	_stop_conversion_pulse()
	if _conversion_panel == null:
		return
	_conversion_panel.visible = false
	_conversion_panel.modulate.a = 0.0
	_conversion_panel.scale = Vector2(0.88, 0.88)


func _reveal_identity_immediately(rarity: int, accent: Color) -> void:
	_begin_identity_audio()
	_skip_button.visible = false
	_reveal_title_stack.visible = true
	_reveal_title.modulate.a = 1.0
	_reveal_title.scale = Vector2.ONE
	_reveal_hint.modulate.a = 0.78
	_reveal_pull_again.visible = true
	_reveal_pull_again.modulate.a = 1.0
	for index: int in _reveal_stars.get_child_count():
		var star := _reveal_stars.get_child(index) as ResonanceStar
		var lit := index < rarity
		star.visible = lit
		star.modulate.a = 1.0 if lit else 0.0
		star.scale = Vector2.ONE
		star.rotation = 0.0
		star.set_state(accent, lit)
	Sfx.play(STAR_BLOOM_SFX)
	if not bool(_pending_pull.get("new_hero", false)):
		_prepare_conversion_feedback()
		_conversion_panel.modulate.a = 1.0
		_conversion_panel.scale = Vector2.ONE
	_arm_reveal_pull_again()


func _begin_identity_audio() -> void:
	Sfx.play(IDENTITY_REVEAL_SFX)
	Music.transition_to_staging(&"lunaris", REVEAL_MUSIC_CROSSFADE_SECONDS)


func _on_pull_again_pressed() -> void:
	if not _is_revealing or not _reveal_result_ready or not _can_pull_again():
		_refresh_reveal_pull_again()
		return
	_finish_reveal(false)
	_confirmation_return_focus = _pull_button
	_on_pull_pressed.call_deferred()


func _can_pull_again() -> bool:
	if (
			_game == null
			or not bool(_game.get("campaign_active"))
			or _game.get("campaign") == null
			or _game.get("campaign_store") == null
	):
		return false
	var projection: Dictionary = _game.get("campaign").runtime_projection()
	var cost := int(projection.get("premium_pull_cost", 0))
	return (
		cost > 0
		and int(projection.get("marks", 0)) >= cost
		and not bool(projection.get("attempt_pending", false))
		and not _premium_pull_dispatched
	)


func _refresh_reveal_pull_again() -> void:
	if _reveal_pull_again == null:
		return
	var cost := 0
	if _game != null and _game.get("campaign") != null:
		cost = int(_game.get("campaign").runtime_projection().get("premium_pull_cost", 0))
	_reveal_pull_again.text = _format(
		&"ui.gacha.pull_again", "PULL AGAIN • {cost} MARKS", {&"cost": cost},
	)
	_reveal_pull_again.disabled = not _can_pull_again()
	_reveal_pull_again.focus_mode = (
		Control.FOCUS_ALL if not _reveal_pull_again.disabled else Control.FOCUS_NONE
	)
	_reveal_pull_again.accessibility_name = _reveal_pull_again.text


func _arm_reveal_pull_again() -> void:
	if not _is_revealing or not _reveal_result_ready:
		return
	_reveal_pull_again.visible = true
	_refresh_reveal_pull_again()
	var focus_target: Control = _reveal_pull_again if not _reveal_pull_again.disabled else _skip_button
	if _is_focus_candidate(focus_target):
		focus_target.grab_focus()


func _reset_reveal_pull_again() -> void:
	if _reveal_pull_again == null:
		return
	_reveal_pull_again.visible = false
	_reveal_pull_again.modulate.a = 0.0
	_reveal_pull_again.disabled = true
	_reveal_pull_again.focus_mode = Control.FOCUS_NONE


func _event_hits_reveal_action(event: InputEvent) -> bool:
	if _reveal_pull_again == null or not _reveal_pull_again.is_visible_in_tree():
		return false
	var pointer_position := Vector2.ZERO
	if event is InputEventMouseButton:
		pointer_position = (event as InputEventMouseButton).position
	elif event is InputEventScreenTouch:
		pointer_position = (event as InputEventScreenTouch).position
	else:
		return false
	return _reveal_pull_again.get_global_rect().has_point(pointer_position)


func _finish_reveal(restore_focus: bool = true) -> void:
	if not _is_revealing:
		return
	_kill_reveal_tween()
	_kill_cinematic_watchdog()
	_stop_star_pulses()
	_reset_conversion_feedback()
	_stop_cinematic()
	var final_copy := _result_copy(_pending_pull)
	_is_revealing = false
	_reveal_result_ready = false
	_flow_state = FlowState.BROWSE
	_reveal_layer.visible = false
	_reveal_layer.modulate.a = 0.0
	_reveal_title_stack.visible = false
	_reset_reveal_pull_again()
	_pending_pull = {}
	_screen_margin.visible = true
	_screen_margin.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_ENABLED
	_refresh()
	if restore_focus:
		_set_browse_status(final_copy, AccessibilityServer.LIVE_POLITE)
		_restore_confirmation_return_focus(_confirmation_transition_token)
	else:
		_confirmation_return_focus = null


func _kill_reveal_tween() -> void:
	if _reveal_tween != null and _reveal_tween.is_valid():
		_reveal_tween.kill()
	_reveal_tween = null


func _kill_cinematic_watchdog() -> void:
	if _cinematic_watchdog != null and _cinematic_watchdog.is_valid():
		_cinematic_watchdog.kill()
	_cinematic_watchdog = null


func _stop_star_pulses() -> void:
	for pulse: Tween in _star_pulse_tweens:
		if pulse != null and pulse.is_valid():
			pulse.kill()
	_star_pulse_tweens.clear()


func _stop_cinematic() -> void:
	if _cinematic_player != null:
		_cinematic_player.stop()
	if String(Music.current_id()).begins_with("gacha_"):
		Music.transition_to_staging(&"lunaris", REVEAL_SKIP_CROSSFADE_SECONDS)


func _result_kind(pull: Dictionary) -> String:
	if bool(pull.get("new_hero", false)):
		return _copy(&"ui.gacha.result_new", "NEW HERO")
	if bool(pull.get("revived", false)):
		return _copy(&"ui.gacha.result_revived", "REVIVED")
	return _copy(&"ui.gacha.result_life", "LIFE +1")


func _result_copy(pull: Dictionary) -> String:
	var callsign := _callsign_for(String(pull.get("premium_id", "")))
	var rarity := int(pull.get("rarity", 4))
	var guarantee := int(pull.get("guarantee_in_after", HARD_PITY_WINDOW))
	var prefix := _format(&"ui.gacha.rarity_short", "{rarity}-STAR", {&"rarity": rarity})
	if bool(pull.get("new_hero", false)):
		return _format(&"ui.gacha.receipt_new", "{rarity} SIGNAL — {callsign} joins with 1 life. Next 5-star in {guarantee} pulls.", {&"rarity": prefix, &"callsign": callsign, &"guarantee": guarantee})
	if bool(pull.get("revived", false)):
		return _format(&"ui.gacha.receipt_restored", "{rarity} RESTORED — {callsign} returns with 1 life. Next 5-star in {guarantee} pulls.", {&"rarity": prefix, &"callsign": callsign, &"guarantee": guarantee})
	return _format(&"ui.gacha.receipt_duplicate", "{rarity} DUPLICATE — {callsign} gains +1 life ({lives} total). Next 5-star in {guarantee} pulls.", {&"rarity": prefix, &"callsign": callsign, &"lives": int(pull.get("lives_after", 0)), &"guarantee": guarantee})


func _pool_row(premium_id: String) -> Dictionary:
	if _game == null or _game.get("campaign") == null:
		return {}
	for row: Dictionary in _game.get("campaign").runtime_projection()["premium_pool"]:
		if row["premium_id"] == premium_id:
			return row
	return {}


func _callsign_for(premium_id: String) -> String:
	return String(_pool_row(premium_id).get("callsign", premium_id))


func _reveal_accent(_pull: Dictionary) -> Color:
	return Style.GOLD


func _class_name(class_id: String) -> String:
	var path := "res://data/classes/%s.tres" % class_id
	var definition := load(path) as ClassDefType if ResourceLoader.exists(path) else null
	return definition.name if definition != null else class_id.replace("_", " ").capitalize()


func _gacha_portrait_asset_id(premium_id: String) -> StringName:
	return StringName(GACHA_FULLSIZE_PORTRAITS.get(premium_id, &""))


func _error_copy(code: StringName) -> String:
	match code:
		&"insufficient_marks": return _copy(&"ui.gacha.error.insufficient_marks", "Not enough Marks for another resonance pull.")
		&"attempt_pending": return _copy(&"ui.gacha.error.attempt_pending", "Resolve the active operation before using the reliquary.")
		&"premium_life_cap": return _copy(&"ui.gacha.error.life_cap", "This hero has reached the maximum stored-life count.")
		&"campaign_inactive": return _copy(&"ui.gacha.error.campaign_inactive", "No active campaign is available.")
		_: return _format(&"ui.gacha.error.unknown", "The resonance failed safely ({code}). Please try again.", {&"code": String(code)})


func _pull_unit(count: int) -> String:
	return _copy(&"ui.gacha.pull_singular", "pull") if count == 1 else _copy(&"ui.gacha.pull_plural", "pulls")


func _life_unit(count: int) -> String:
	return _copy(&"ui.gacha.life_singular", "LIFE") if count == 1 else _copy(&"ui.gacha.life_plural", "LIVES")


func _copy(key: StringName, fallback: String) -> String:
	return UiCopyType.text(key, fallback)


func _format(key: StringName, fallback: String, args: Dictionary) -> String:
	return UiCopyType.format_text(key, fallback, args)


func _open_pull_history() -> void:
	if (
			_flow_state != FlowState.BROWSE
			or _history_drawer == null
			or _history_drawer.is_open()
			or _game == null
			or not bool(_game.get("campaign_active"))
			or _game.get("campaign") == null
	):
		return
	var focused := get_viewport().gui_get_focus_owner()
	_history_return_focus = focused if _is_focus_candidate(focused) else _history_button
	_focus_request_token += 1
	_screen_margin.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
	_pull_button.disabled = true
	_back_button.disabled = true
	_history_button.disabled = true
	_history_drawer.reduced_motion = _motion_reduced()
	_history_drawer.present(_game.get("campaign").runtime_projection())
	Sfx.play("ui_confirm")


func _close_pull_history() -> void:
	if _history_drawer == null or not _history_drawer.is_open():
		return
	Sfx.play("ui_back")
	_history_drawer.dismiss()


func _on_pull_history_closed() -> void:
	_screen_margin.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_ENABLED
	_refresh()
	var target := _history_return_focus
	if not _is_focus_candidate(target):
		target = _fallback_browse_focus()
	_history_return_focus = null
	_queue_guarded_focus(
		target,
		FlowState.BROWSE,
		ConfirmationTransition.NONE,
		_confirmation_transition_token,
	)


func _on_back_pressed() -> void:
	if _flow_state != FlowState.BROWSE or (_history_drawer != null and _history_drawer.is_open()):
		return
	if _game != null and _game.has_method("open_staging"):
		_game.call("open_staging")


func _prepare_confirmation_button(button: Button) -> void:
	button.focus_mode = Control.FOCUS_ALL
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.clip_text = false


func _set_confirmation_pending(pending: bool) -> void:
	_confirmation_header_cancel.disabled = pending
	_confirmation_cancel.disabled = pending
	_confirmation_confirm.disabled = pending
	_confirmation_confirm.text = (
		_copy(&"ui.gacha.aligning_short", "ALIGNING…")
		if pending
		else _copy(&"ui.gacha.resonate", "RESONATE")
	)


func _set_confirmation_status(text: String, live_mode: int) -> void:
	_confirmation_status_label.accessibility_live = live_mode
	_confirmation_status_label.text = text
	_confirmation_status_label.visible = not text.is_empty()


func _start_confirmation_exit(status_text: String, live_mode: int) -> void:
	if (
			_flow_state not in [FlowState.CONFIRM, FlowState.COMMITTING]
			or _confirmation_transition not in [
				ConfirmationTransition.ENTERING, ConfirmationTransition.OPEN,
			]
	):
		return
	_confirmation_exit_status = status_text
	_confirmation_exit_live = live_mode
	if live_mode == AccessibilityServer.LIVE_ASSERTIVE:
		_set_confirmation_status(status_text, live_mode)
	var token := _begin_confirmation_transition(ConfirmationTransition.EXITING)
	if _motion_reduced():
		_finish_confirmation_exit(token)
		return
	_confirmation_tween = create_tween()
	_confirmation_tween.tween_property(
		_confirmation_layer, "modulate:a", 0.0, CONFIRM_EXIT_SECONDS,
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_confirmation_tween.parallel().tween_property(
		_confirmation_frame,
		"offset_transform_position:y",
		CONFIRM_FRAME_OFFSET,
		CONFIRM_EXIT_SECONDS,
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_confirmation_tween.finished.connect(_finish_confirmation_exit.bind(token), CONNECT_ONE_SHOT)


func _finish_confirmation_exit(token: int) -> void:
	if (
			token != _confirmation_transition_token
			or _confirmation_transition != ConfirmationTransition.EXITING
			or _flow_state not in [FlowState.CONFIRM, FlowState.COMMITTING]
	):
		return
	_confirmation_tween = null
	_confirmation_layer.visible = false
	_confirmation_layer.modulate.a = 0.0
	_confirmation_frame.offset_transform_position = Vector2(0.0, CONFIRM_FRAME_OFFSET)
	_confirmation_layer.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
	_confirmation_transition = ConfirmationTransition.NONE
	_confirmation_projection = {}
	_premium_pull_dispatched = false
	_flow_state = FlowState.BROWSE
	_screen_margin.visible = true
	_screen_margin.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_ENABLED
	_set_confirmation_pending(false)
	_refresh()
	_status_label.text = _confirmation_exit_status
	_status_label.accessibility_live = _confirmation_exit_live
	_restore_confirmation_return_focus(token)
	_confirmation_exit_status = ""
	_confirmation_exit_live = AccessibilityServer.LIVE_OFF


func _handoff_confirmation_to_reveal(pull: Dictionary) -> void:
	_invalidate_confirmation_transition()
	_confirmation_transition = ConfirmationTransition.NONE
	_confirmation_layer.visible = false
	_confirmation_layer.modulate.a = 0.0
	_confirmation_frame.offset_transform_position = Vector2(0.0, CONFIRM_FRAME_OFFSET)
	_confirmation_layer.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
	_confirmation_projection = {}
	_premium_pull_dispatched = false
	_set_confirmation_pending(false)
	_begin_reveal(pull)


func _suppress_browse_focus() -> void:
	_focus_request_token += 1
	_screen_margin.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
	var focused := get_viewport().gui_get_focus_owner()
	if focused != null and (focused == _screen_margin or _screen_margin.is_ancestor_of(focused)):
		focused.release_focus()
	_screen_margin.visible = false


func _restore_confirmation_return_focus(transition_token: int) -> void:
	var target := _confirmation_return_focus
	if not _is_focus_candidate(target):
		target = _fallback_browse_focus()
	_confirmation_return_focus = null
	_queue_guarded_focus(
		target,
		FlowState.BROWSE,
		ConfirmationTransition.NONE,
		transition_token,
	)


func _restore_pull_focus() -> void:
	_queue_guarded_focus(
		_fallback_browse_focus(),
		FlowState.BROWSE,
		ConfirmationTransition.NONE,
		_confirmation_transition_token,
	)


func _fallback_browse_focus() -> Control:
	if _is_focus_candidate(_pull_button):
		return _pull_button
	if _is_focus_candidate(_back_button):
		return _back_button
	return null


func _is_focus_candidate(candidate: Control) -> bool:
	return (
		candidate != null
		and is_instance_valid(candidate)
		and candidate.is_inside_tree()
		and candidate.is_visible_in_tree()
		and candidate.focus_mode != Control.FOCUS_NONE
		and not (candidate is BaseButton and (candidate as BaseButton).disabled)
	)


func _queue_guarded_focus(
		target: Control,
		expected_flow: int,
		expected_transition: int,
		transition_token: int,
	) -> void:
	if target == null:
		return
	_focus_request_token += 1
	var focus_token := _focus_request_token
	_apply_guarded_focus.bind(
		target, focus_token, transition_token, expected_flow, expected_transition,
	).call_deferred()


func _apply_guarded_focus(
		target: Control,
		focus_token: int,
		transition_token: int,
		expected_flow: int,
		expected_transition: int,
	) -> void:
	if (
		focus_token != _focus_request_token
		or transition_token != _confirmation_transition_token
		or _flow_state != expected_flow
		or _confirmation_transition != expected_transition
		or not _is_focus_candidate(target)
	):
		return
	target.grab_focus()


func _refresh_confirmation_copy() -> void:
	if _confirmation_title == null:
		return
	_confirmation_title.text = _copy(&"ui.gacha.confirm_title", "CONFIRM RESONANCE")
	_confirmation_context_eyebrow.text = _copy(&"ui.gacha.eyebrow", "LUNARIS RELIQUARY")
	_confirmation_review_eyebrow.text = _copy(&"ui.gacha.guarantee", "5-STAR GUARANTEE")
	_confirmation_header_cancel.text = _copy(&"ui.common.cancel", "CANCEL")
	_confirmation_cancel.text = _copy(&"ui.common.cancel", "CANCEL")
	_confirmation_context_label.text = _copy(
		&"ui.gacha.confirm_intro",
		"Align one signal through the random premium pool.",
	)
	if not _confirmation_projection.is_empty():
		var marks := int(_confirmation_projection.get("marks", 0))
		var cost := int(_confirmation_projection.get("premium_pull_cost", 0))
		var guarantee_in := int(_confirmation_projection.get(
			"premium_guarantee_in", HARD_PITY_WINDOW,
		))
		_confirmation_review_label.text = _format(
			&"ui.gacha.confirm_body",
			"One random signal • {cost} Marks\nBalance  {before} → {after} Marks\n5-star guarantee in {count} {unit}. Every accepted resonance grants exactly one life.",
			{
				&"cost": cost,
				&"before": marks,
				&"after": maxi(0, marks - cost),
				&"count": guarantee_in,
				&"unit": _pull_unit(guarantee_in),
			},
		)
	_set_confirmation_pending(_flow_state == FlowState.COMMITTING)
	_refresh_confirmation_accessibility()


func _refresh_confirmation_accessibility() -> void:
	if _confirmation_layer == null:
		return
	var title_text := _confirmation_title.text
	var description := "%s %s" % [
		_confirmation_context_label.text,
		_confirmation_review_label.text.replace("\n", " "),
	]
	_confirmation_layer.accessibility_name = title_text
	_confirmation_layer.accessibility_description = description
	_confirmation_frame.accessibility_name = title_text
	_confirmation_frame.accessibility_description = description
	_confirmation_title.accessibility_name = title_text
	_confirmation_title.accessibility_description = _copy(
		&"ui.gacha.confirm_title_description", "Premium resonance transaction confirmation",
	)
	_confirmation_body_grid.accessibility_name = _copy(
		&"ui.gacha.confirm_body_name", "Resonance transaction details",
	)
	_confirmation_body_grid.accessibility_description = description
	_confirmation_action_dock.accessibility_name = _copy(
		&"ui.gacha.confirm_actions_name", "Resonance confirmation actions",
	)
	_confirmation_action_dock.accessibility_description = description
	_confirmation_header_cancel.accessibility_name = _copy(
		&"ui.gacha.confirm_header_cancel_name", "Cancel resonance, header",
	)
	_confirmation_header_cancel.accessibility_description = _copy(
		&"ui.gacha.confirm_cancel_description", "Close without spending Marks or changing the guarantee.",
	)
	_confirmation_cancel.accessibility_name = _copy(
		&"ui.gacha.confirm_dock_cancel_name", "Cancel resonance, action dock",
	)
	_confirmation_cancel.accessibility_description = _confirmation_header_cancel.accessibility_description
	_confirmation_confirm.accessibility_name = _copy(
		&"ui.gacha.confirm_action_name", "Confirm premium resonance",
	)
	_confirmation_confirm.accessibility_description = description
	_confirmation_status_label.accessibility_name = _copy(
		&"ui.gacha.confirm_status_name", "Resonance confirmation status",
	)
	_confirmation_layer.accessibility_labeled_by_nodes = [
		_confirmation_layer.get_path_to(_confirmation_title),
	]
	_confirmation_layer.accessibility_described_by_nodes = [
		_confirmation_layer.get_path_to(_confirmation_context_label),
		_confirmation_layer.get_path_to(_confirmation_review_label),
		_confirmation_layer.get_path_to(_confirmation_status_label),
	]
	_confirmation_frame.accessibility_labeled_by_nodes = [
		_confirmation_frame.get_path_to(_confirmation_title),
	]
	_confirmation_frame.accessibility_described_by_nodes = [
		_confirmation_frame.get_path_to(_confirmation_context_label),
		_confirmation_frame.get_path_to(_confirmation_review_label),
		_confirmation_frame.get_path_to(_confirmation_status_label),
	]
	_confirmation_title.accessibility_controls_nodes = [
		_confirmation_title.get_path_to(_confirmation_body_grid),
		_confirmation_title.get_path_to(_confirmation_action_dock),
	]
	_confirmation_body_grid.accessibility_labeled_by_nodes = [
		_confirmation_body_grid.get_path_to(_confirmation_title),
	]
	_confirmation_action_dock.accessibility_labeled_by_nodes = [
		_confirmation_action_dock.get_path_to(_confirmation_title),
	]
	_confirmation_confirm.accessibility_described_by_nodes = [
		_confirmation_confirm.get_path_to(_confirmation_review_label),
		_confirmation_confirm.get_path_to(_confirmation_status_label),
	]


func _bind_confirmation_focus_scope(stacked: bool) -> void:
	var actions: Array[Control] = [
		_confirmation_cancel,
		_confirmation_confirm,
	]
	for index: int in actions.size():
		var current := actions[index]
		var previous := actions[(index - 1 + actions.size()) % actions.size()]
		var following := actions[(index + 1) % actions.size()]
		current.focus_previous = current.get_path_to(previous)
		current.focus_next = current.get_path_to(following)
	if stacked:
		for index: int in actions.size():
			var current := actions[index]
			var previous := actions[(index - 1 + actions.size()) % actions.size()]
			var following := actions[(index + 1) % actions.size()]
			current.focus_neighbor_left = current.get_path_to(current)
			current.focus_neighbor_right = current.get_path_to(current)
			current.focus_neighbor_top = current.get_path_to(previous)
			current.focus_neighbor_bottom = current.get_path_to(following)
		return
	_confirmation_cancel.focus_neighbor_left = _confirmation_cancel.get_path_to(
		_confirmation_confirm,
	)
	_confirmation_cancel.focus_neighbor_right = _confirmation_cancel.get_path_to(
		_confirmation_confirm,
	)
	_confirmation_cancel.focus_neighbor_top = _confirmation_cancel.get_path_to(
		_confirmation_cancel,
	)
	_confirmation_cancel.focus_neighbor_bottom = _confirmation_cancel.get_path_to(
		_confirmation_cancel,
	)
	_confirmation_confirm.focus_neighbor_left = _confirmation_confirm.get_path_to(
		_confirmation_cancel,
	)
	_confirmation_confirm.focus_neighbor_right = _confirmation_confirm.get_path_to(
		_confirmation_cancel,
	)
	_confirmation_confirm.focus_neighbor_top = _confirmation_confirm.get_path_to(
		_confirmation_confirm,
	)
	_confirmation_confirm.focus_neighbor_bottom = _confirmation_confirm.get_path_to(
		_confirmation_confirm,
	)


func _apply_confirmation_layout(viewport_size: Vector2) -> void:
	if _confirmation_layer == null or viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var focused := get_viewport().gui_get_focus_owner()
	var focus_in_scope := focused in [
		_confirmation_header_cancel, _confirmation_cancel, _confirmation_confirm,
	]
	var aspect := viewport_size.x / viewport_size.y
	var narrow := viewport_size.x <= 720.0
	var portrait := aspect <= 1.2 and viewport_size.y > 560.0
	var short := viewport_size.y <= 560.0
	var wide := viewport_size.x >= 1200.0 and aspect > 1.2 and not short
	var frame_style := Style.panel_style(&"screen")
	var frame_content_margin := 4.0 if narrow else 22.0
	frame_style.content_margin_left = frame_content_margin
	frame_style.content_margin_top = frame_content_margin
	frame_style.content_margin_right = frame_content_margin
	frame_style.content_margin_bottom = frame_content_margin
	_confirmation_frame.add_theme_stylebox_override(&"panel", frame_style)
	var safe_insets := _display_safe_insets(viewport_size)
	var horizontal_gutter := 4 if narrow else clampi(roundi(viewport_size.x * 0.033), 12, 42)
	var vertical_gutter := clampi(roundi(viewport_size.y * 0.028), 12, 32)
	_confirmation_safe.add_theme_constant_override(
		&"margin_left", maxi(horizontal_gutter, roundi(safe_insets.x)),
	)
	_confirmation_safe.add_theme_constant_override(
		&"margin_top", maxi(vertical_gutter, roundi(safe_insets.y)),
	)
	_confirmation_safe.add_theme_constant_override(
		&"margin_right", maxi(horizontal_gutter, roundi(safe_insets.z)),
	)
	_confirmation_safe.add_theme_constant_override(
		&"margin_bottom", maxi(vertical_gutter, roundi(safe_insets.w)),
	)
	_confirmation_stack.add_theme_constant_override(&"separation", 8 if short else 14)
	_confirmation_header.add_theme_constant_override(&"separation", 8 if narrow else 16)
	_confirmation_header_cancel.visible = false
	_confirmation_header_cancel.focus_mode = Control.FOCUS_NONE
	_confirmation_header.columns = 1
	_confirmation_header_cancel.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL if narrow else Control.SIZE_SHRINK_BEGIN
	)
	_confirmation_header_cancel.custom_minimum_size.x = 0.0 if narrow else 280.0
	_confirmation_title.add_theme_font_size_override(&"font_size", 66 if narrow else (96 if short else 114))
	_confirmation_body_grid.columns = 2 if wide else 1
	_confirmation_context_eyebrow.visible = not narrow
	_confirmation_review_eyebrow.visible = not narrow
	_confirmation_actions.columns = 1 if narrow or portrait else 2
	_confirmation_actions.size_flags_horizontal = Control.SIZE_SHRINK_END
	_confirmation_cancel.custom_minimum_size = CONFIRM_ACTION_SIZE
	_confirmation_confirm.custom_minimum_size = CONFIRM_ACTION_SIZE
	_confirmation_header_cancel.custom_minimum_size.y = CONFIRM_ACTION_SIZE.y
	var content_width := minf(
		CONFIRM_READABLE_MAX_WIDTH,
		maxf(0.0, viewport_size.x - float(horizontal_gutter * 2 + 44)),
	)
	_confirmation_body_center.custom_minimum_size.x = content_width
	_confirmation_body_grid.custom_minimum_size.x = content_width
	_confirmation_body_scroll.custom_minimum_size.y = 0
	var stacked_actions := _confirmation_actions.columns == 1
	_bind_confirmation_focus_scope(stacked_actions)
	if focus_in_scope and _is_focus_candidate(focused):
		_queue_guarded_focus(
			focused,
			_flow_state,
			_confirmation_transition,
			_confirmation_transition_token,
		)


func _display_safe_insets(viewport_size: Vector2) -> Vector4:
	var safe_rect := DisplayServer.get_display_safe_area()
	var window_size := DisplayServer.window_get_size()
	if safe_rect.size.x <= 0 or safe_rect.size.y <= 0 or window_size.x <= 0 or window_size.y <= 0:
		return Vector4.ZERO
	var scale := Vector2(
		viewport_size.x / float(window_size.x),
		viewport_size.y / float(window_size.y),
	)
	var left := maxf(0.0, float(safe_rect.position.x) * scale.x)
	var top := maxf(0.0, float(safe_rect.position.y) * scale.y)
	var right := maxf(0.0, float(window_size.x - safe_rect.end.x) * scale.x)
	var bottom := maxf(0.0, float(window_size.y - safe_rect.end.y) * scale.y)
	if left + right > viewport_size.x * 0.25 or top + bottom > viewport_size.y * 0.25:
		return Vector4.ZERO
	return Vector4(left, top, right, bottom)


func _play_confirmation_entry() -> void:
	var token := _begin_confirmation_transition(ConfirmationTransition.ENTERING)
	if _motion_reduced():
		_finish_confirmation_entry(token)
		return
	_confirmation_tween = create_tween()
	_confirmation_tween.tween_property(
		_confirmation_layer, "modulate:a", 1.0, CONFIRM_ENTRY_SECONDS,
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	_confirmation_tween.parallel().tween_property(
		_confirmation_frame,
		"offset_transform_position:y",
		0.0,
		CONFIRM_ENTRY_SECONDS,
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_confirmation_tween.finished.connect(_finish_confirmation_entry.bind(token), CONNECT_ONE_SHOT)


func _finish_confirmation_entry(token: int) -> void:
	if (
			token != _confirmation_transition_token
			or _confirmation_transition != ConfirmationTransition.ENTERING
			or _flow_state != FlowState.CONFIRM
	):
		return
	_confirmation_tween = null
	_confirmation_layer.modulate.a = 1.0
	_confirmation_frame.offset_transform_position = Vector2.ZERO
	_confirmation_layer.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_ENABLED
	_confirmation_transition = ConfirmationTransition.OPEN
	_queue_guarded_focus(
		_confirmation_cancel,
		FlowState.CONFIRM,
		ConfirmationTransition.OPEN,
		token,
	)


func _begin_confirmation_transition(next_state: int) -> int:
	_invalidate_confirmation_transition()
	_confirmation_transition = next_state
	return _confirmation_transition_token


func _invalidate_confirmation_transition() -> void:
	_confirmation_transition_token += 1
	_focus_request_token += 1
	_kill_confirmation_tween()


func _kill_confirmation_tween() -> void:
	if _confirmation_tween != null and _confirmation_tween.is_valid():
		_confirmation_tween.kill()
	_confirmation_tween = null


func _motion_reduced() -> bool:
	return reduced_motion or bool(ProjectSettings.get_setting(
		"accessibility/reduced_motion", false,
	))


func _on_locale_changed(_locale_id: StringName) -> void:
	var focused := get_viewport().gui_get_focus_owner()
	_refresh_static_copy()
	_refresh()
	_refresh_confirmation_copy()
	_apply_responsive_layout()
	if _is_focus_candidate(focused):
		_queue_guarded_focus(
			focused,
			_flow_state,
			_confirmation_transition,
			_confirmation_transition_token,
		)


func _refresh_static_copy() -> void:
	_back_button.text = _copy(&"ui.gacha.back", "RETURN")
	_history_button.text = _copy(&"ui.gacha.history_action", "HISTORY")
	_browse_title.text = _copy(&"ui.gacha.title", "Premium Resonance")
	_skip_button.text = _copy(&"ui.gacha.skip_reveal", "SKIP REVEAL")
	_reveal_hint.text = _copy(&"ui.gacha.click_anywhere", "CLICK ANYWHERE TO CONTINUE")
	if _history_drawer != null:
		_history_drawer.refresh_copy()
	_refresh_reveal_pull_again()
	if _flow_state == FlowState.REVEAL and not _pending_pull.is_empty():
		_reveal_title.text = _callsign_for(
			String(_pending_pull.get("premium_id", "")),
		).to_upper()
		_refresh_conversion_copy()


func flow_state_name() -> StringName:
	match _flow_state:
		FlowState.CONFIRM: return &"CONFIRM"
		FlowState.COMMITTING: return &"COMMITTING"
		FlowState.REVEAL: return &"REVEAL"
		_: return &"BROWSE"


func transition_state_name() -> StringName:
	match _confirmation_transition:
		ConfirmationTransition.ENTERING: return &"ENTERING"
		ConfirmationTransition.OPEN: return &"OPEN"
		ConfirmationTransition.EXITING: return &"EXITING"
		_: return &"NONE"


func transition_active() -> bool:
	return _confirmation_transition in [
		ConfirmationTransition.ENTERING, ConfirmationTransition.EXITING,
	]


func confirmation_projection_snapshot() -> Dictionary:
	return _confirmation_projection.duplicate(true)


func reveal_result_ready() -> bool:
	return _reveal_result_ready


func _label(text: String, role: StringName) -> Label:
	var label := Label.new()
	label.text = text
	Style.apply_label(label, role)
	return label


func _set_browse_status(text: String, live_mode: int) -> void:
	_status_label.text = text
	_status_label.accessibility_live = live_mode
	_status_label.visible = not text.is_empty()


func _set_pull_presentation(logical_text: String, action_text: String, cost_text: String) -> void:
	_pull_button.text = logical_text
	_pull_button.accessibility_name = logical_text.replace("\n", ", ")
	_pull_action_label.text = action_text
	_pull_cost_label.text = cost_text
	_pull_cost_label.visible = not cost_text.is_empty()


func _apply_pull_button_style(disabled: bool) -> void:
	Style.apply_button(_pull_button, &"disabled" if disabled else &"quiet")
	var transparent := Color(0.0, 0.0, 0.0, 0.0)
	for color_name: StringName in [
		&"font_color", &"font_hover_color", &"font_pressed_color",
		&"font_focus_color", &"font_disabled_color",
	]:
		_pull_button.add_theme_color_override(color_name, transparent)
	_pull_action_label.add_theme_color_override(
		&"font_color", Color(Style.MUTED, 0.64) if disabled else Style.GOLD,
	)
	_pull_cost_label.add_theme_color_override(
		&"font_color", Color(Style.MUTED, 0.54) if disabled else Style.CYAN,
	)
	_pull_button.add_theme_stylebox_override(
		&"normal", _pull_button_box(Color("091827f2"), Color(Style.GOLD, 0.72), 2),
	)
	_pull_button.add_theme_stylebox_override(
		&"hover", _pull_button_box(Color("173447fa"), Style.CYAN, 3),
	)
	_pull_button.add_theme_stylebox_override(
		&"pressed", _pull_button_box(Color("06111cff"), Style.GOLD, 3),
	)
	_pull_button.add_theme_stylebox_override(
		&"focus", _pull_button_box(Color("102a3afa"), Style.CYAN, 3),
	)
	_pull_button.add_theme_stylebox_override(
		&"disabled", _pull_button_box(Color("0b1219db"), Color(Style.MUTED, 0.24)),
	)
	_refresh_pull_hover()


func _on_pull_hover_changed(active: bool, focus_event: bool) -> void:
	if focus_event:
		_pull_focus_hovered = active
	else:
		_pull_pointer_hovered = active
	_refresh_pull_hover()


func _refresh_pull_pivot() -> void:
	if _pull_button != null:
		_pull_button.pivot_offset = _pull_button.size * 0.5


func _refresh_pull_hover() -> void:
	if _pull_button == null:
		return
	if _pull_hover_tween != null and _pull_hover_tween.is_valid():
		_pull_hover_tween.kill()
	_pull_hover_tween = null
	var highlighted := not _pull_button.disabled and (_pull_pointer_hovered or _pull_focus_hovered)
	_pull_action_label.add_theme_color_override(
		&"font_color",
		Color(Style.MUTED, 0.64) if _pull_button.disabled else (Style.IVORY if highlighted else Style.GOLD),
	)
	_pull_cost_label.add_theme_color_override(
		&"font_color",
		Color(Style.MUTED, 0.54) if _pull_button.disabled else (Color("c9fbff") if highlighted else Style.CYAN),
	)
	var target_scale := Vector2(1.025, 1.025) if highlighted and not _motion_reduced() else Vector2.ONE
	var target_modulate := Color(1.08, 1.05, 0.95, 1.0) if highlighted else Color.WHITE
	if _motion_reduced():
		_pull_button.scale = target_scale
		_pull_button.modulate = target_modulate
	else:
		_pull_hover_tween = create_tween().set_parallel(true)
		_pull_hover_tween.tween_property(
			_pull_button, "scale", target_scale, 0.16,
		).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		_pull_hover_tween.tween_property(
			_pull_button, "modulate", target_modulate, 0.16,
		).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)


func _pull_button_box(fill: Color, edge: Color, width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(width)
	style.set_corner_radius_all(4)
	style.content_margin_left = 28.0
	style.content_margin_top = 14.0
	style.content_margin_right = 28.0
	style.content_margin_bottom = 14.0
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.32)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0.0, 2.0)
	return style
