extends Control

const Style := preload("res://scripts/ui/components/lunaris_ops_style.gd")
const ClassDefType := preload("res://data/class_def.gd")
const ResonanceStarType := preload("res://scripts/ui/components/resonance_star.gd")
const CinematicPlayerType := preload("res://scripts/ui/components/gacha_cinematic_player.gd")
const UiCopyType := preload("res://scripts/ui/components/ui_copy.gd")
const LUNARIS_BACKDROP := preload("res://assets/loading/lunaris_reliquary_loading.png")

const HARD_PITY_WINDOW := 10
const FIVE_STAR_RARITY := 5
const CINEMATIC_WATCHDOG_SECONDS := 8.75
const CINEMATIC_WATCHDOG_POLL_SECONDS := 0.5
const REVEAL_NAME_FADE_SECONDS := 0.42
const REVEAL_STAR_GROW_SECONDS := 0.56
const REVEAL_STAR_PULSE_SECONDS := 0.82
const GACHA_FULLSIZE_PORTRAITS := {
	"archive_caster": &"portrait_archive_caster_fullsize",
	"lunaris_vessel": &"portrait_lunaris_vessel_fullsize",
	"reliquary_duelist": &"portrait_reliquary_duelist_fullsize",
}
const CONFIRM_ENTRY_SECONDS := 0.20
const CONFIRM_EXIT_SECONDS := 0.15
const CONFIRM_FRAME_OFFSET := 12.0
const CONFIRM_READABLE_MAX_WIDTH := 1480.0

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
var _marks_label: Label
var _pull_button: Button
var _back_button: Button
var _browse_eyebrow: Label
var _browse_title: Label
var _browse_intro: Label
var _status_label: Label
var _hero_grid: GridContainer
var _header_grid: GridContainer
var _action_grid: GridContainer
var _screen_margin: MarginContainer
var _pity_label: Label
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

var _reveal_layer: Control
var _reveal_shade: ColorRect
var _cinematic_player: GachaCinematicPlayer
var _reveal_burst: Control
var _reveal_title_stack: VBoxContainer
var _reveal_title: Label
var _reveal_stars: HBoxContainer
var _reveal_hint: Label
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
	Style.add_backdrop(self, LUNARIS_BACKDROP)
	_build_screen()
	_build_pull_confirmation()
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
	_kill_reveal_tween()
	_kill_cinematic_watchdog()
	_stop_star_pulses()
	_stop_cinematic()


func _input(event: InputEvent) -> void:
	if not event.is_pressed():
		return
	if (
		_flow_state == FlowState.REVEAL
		and _reveal_result_ready
		and (event is InputEventMouseButton or event is InputEventScreenTouch)
	):
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
	_screen_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_screen_margin.add_theme_constant_override(&"margin_left", 42)
	_screen_margin.add_theme_constant_override(&"margin_top", 30)
	_screen_margin.add_theme_constant_override(&"margin_right", 42)
	_screen_margin.add_theme_constant_override(&"margin_bottom", 30)
	add_child(_screen_margin)

	var shell := PanelContainer.new()
	Style.apply_panel(shell, &"screen")
	_screen_margin.add_child(shell)

	var content := VBoxContainer.new()
	content.add_theme_constant_override(&"separation", 18)
	shell.add_child(content)

	_header_grid = GridContainer.new()
	_header_grid.columns = 3
	_header_grid.add_theme_constant_override(&"h_separation", 16)
	_header_grid.add_theme_constant_override(&"v_separation", 10)
	content.add_child(_header_grid)
	_back_button = Button.new()
	_back_button.name = "BackButton"
	_back_button.text = _copy(&"ui.gacha.back", "← COMMAND DECK")
	_back_button.pressed.connect(_on_back_pressed)
	Style.apply_button(_back_button, &"quiet")
	_header_grid.add_child(_back_button)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_header_grid.add_child(title_box)
	_browse_eyebrow = _label(_copy(&"ui.gacha.eyebrow", "LUNARIS RELIQUARY"), &"eyebrow")
	title_box.add_child(_browse_eyebrow)
	_browse_title = _label(_copy(&"ui.gacha.title", "Premium Resonance"), &"title")
	title_box.add_child(_browse_title)
	_marks_label = _label("0 MARKS", &"metric")
	_marks_label.name = "MarksLabel"
	_marks_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_header_grid.add_child(_marks_label)

	var intro := PanelContainer.new()
	Style.apply_panel(intro, &"quiet")
	content.add_child(intro)
	var intro_box := VBoxContainer.new()
	intro_box.add_theme_constant_override(&"separation", 10)
	intro.add_child(intro_box)
	_browse_intro = _label(
		_copy(&"ui.gacha.intro", "Every resonance grants one life. Premium heroes keep fixed elite kits and cannot be trained. 5-star base rate: 5% • guaranteed within ten pulls."),
		&"body",
	)
	_browse_intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro_box.add_child(_browse_intro)
	var pity_row := HBoxContainer.new()
	pity_row.add_theme_constant_override(&"separation", 12)
	intro_box.add_child(pity_row)
	_pity_label = _label(_copy(&"ui.gacha.guarantee", "5-STAR GUARANTEE"), &"detail")
	_pity_label.name = "PityLabel"
	_pity_label.custom_minimum_size.x = 210
	pity_row.add_child(_pity_label)
	_pity_segments = HBoxContainer.new()
	_pity_segments.name = "PitySegments"
	_pity_segments.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pity_segments.add_theme_constant_override(&"separation", 5)
	pity_row.add_child(_pity_segments)
	for index: int in HARD_PITY_WINDOW:
		var segment := ColorRect.new()
		segment.name = "Pity_%02d" % (index + 1)
		segment.custom_minimum_size = Vector2(24, 8)
		segment.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		segment.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_pity_segments.add_child(segment)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var hero_stage := CenterContainer.new()
	hero_stage.name = "PremiumHeroStage"
	hero_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(hero_stage)
	_hero_grid = GridContainer.new()
	_hero_grid.name = "PremiumHeroGrid"
	_hero_grid.columns = 3
	_hero_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_hero_grid.add_theme_constant_override(&"h_separation", 16)
	_hero_grid.add_theme_constant_override(&"v_separation", 16)
	hero_stage.add_child(_hero_grid)

	_action_grid = GridContainer.new()
	_action_grid.columns = 2
	_action_grid.add_theme_constant_override(&"h_separation", 18)
	_action_grid.add_theme_constant_override(&"v_separation", 10)
	content.add_child(_action_grid)
	_status_label = _label(_copy(&"ui.gacha.ready", "The pool is ready."), &"detail")
	_status_label.name = "PullStatusLabel"
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.accessibility_name = _copy(&"ui.gacha.status_name", "Premium resonance status")
	_status_label.accessibility_live = AccessibilityServer.LIVE_OFF
	_action_grid.add_child(_status_label)
	_pull_button = Button.new()
	_pull_button.name = "PremiumPullButton"
	_pull_button.custom_minimum_size = Vector2(280, 60)
	_pull_button.pressed.connect(_on_pull_pressed)
	_pull_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_action_grid.add_child(_pull_button)


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
	_confirmation_header_cancel.add_theme_font_size_override(&"font_size", 36)
	_confirmation_header_cancel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_confirmation_header_cancel.clip_text = false
	_confirmation_header.add_child(_confirmation_header_cancel)
	_confirmation_title = _label("", &"title")
	_confirmation_title.name = "ConfirmationTitle"
	_confirmation_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_confirmation_title.custom_minimum_size.x = 0
	_confirmation_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_confirmation_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_confirmation_title.add_theme_font_size_override(&"font_size", 76)
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
	_confirmation_context_eyebrow.add_theme_font_size_override(&"font_size", 28)
	context_stack.add_child(_confirmation_context_eyebrow)
	_confirmation_context_label = _label("", &"body")
	_confirmation_context_label.name = "ConfirmationContextCopy"
	_confirmation_context_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_confirmation_context_label.custom_minimum_size.x = 0
	_confirmation_context_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_confirmation_context_label.add_theme_font_size_override(&"font_size", 36)
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
	_confirmation_review_eyebrow.add_theme_font_size_override(&"font_size", 28)
	review_stack.add_child(_confirmation_review_eyebrow)
	_confirmation_review_label = _label("", &"body")
	_confirmation_review_label.name = "ConfirmationTransactionCopy"
	_confirmation_review_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_confirmation_review_label.custom_minimum_size.x = 0
	_confirmation_review_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_confirmation_review_label.add_theme_font_size_override(&"font_size", 36)
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
	_confirmation_actions.add_theme_constant_override(&"h_separation", 14)
	_confirmation_actions.add_theme_constant_override(&"v_separation", 10)
	dock_stack.add_child(_confirmation_actions)
	_confirmation_cancel = Button.new()
	_confirmation_cancel.name = "CancelPremiumPullDock"
	_confirmation_cancel.custom_minimum_size = Vector2(0, 88)
	_confirmation_cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_prepare_confirmation_button(_confirmation_cancel)
	_confirmation_cancel.pressed.connect(_on_pull_cancelled)
	Style.apply_button(_confirmation_cancel, &"quiet")
	_confirmation_cancel.add_theme_font_size_override(&"font_size", 36)
	_confirmation_cancel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_confirmation_cancel.clip_text = false
	_confirmation_actions.add_child(_confirmation_cancel)
	_confirmation_confirm = Button.new()
	_confirmation_confirm.name = "ConfirmPremiumPull"
	_confirmation_confirm.custom_minimum_size = Vector2(0, 88)
	_confirmation_confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_prepare_confirmation_button(_confirmation_confirm)
	_confirmation_confirm.pressed.connect(_on_confirm_pull)
	Style.apply_button(_confirmation_confirm, &"gold")
	_confirmation_confirm.add_theme_font_size_override(&"font_size", 36)
	_confirmation_confirm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_confirmation_confirm.clip_text = false
	_confirmation_actions.add_child(_confirmation_confirm)
	_bind_confirmation_focus_scope(false)
	_refresh_confirmation_copy()
	_refresh_confirmation_accessibility()


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

	_reveal_burst = Control.new()
	_reveal_burst.name = "SignalFilaments"
	_reveal_burst.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_reveal_burst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reveal_layer.add_child(_reveal_burst)
	for index: int in 12:
		var ray := ColorRect.new()
		ray.set_anchors_preset(Control.PRESET_CENTER)
		ray.offset_left = -360.0
		ray.offset_right = 360.0
		ray.offset_top = -1.0
		ray.offset_bottom = 1.0
		ray.pivot_offset = Vector2(360, 1)
		ray.rotation = deg_to_rad(float(index) * 15.0)
		ray.color = Color(Style.CYAN.r, Style.CYAN.g, Style.CYAN.b, 0.16)
		ray.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_reveal_burst.add_child(ray)

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
	_skip_button.add_theme_font_size_override(&"font_size", 36)
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
	_reveal_title.add_theme_font_size_override(&"font_size", 104)
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
	_reveal_hint = _label(_copy(&"ui.gacha.click_anywhere", "CLICK ANYWHERE TO CONTINUE"), &"eyebrow")
	_reveal_hint.name = "RevealContinueHint"
	_reveal_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reveal_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reveal_hint.add_theme_font_size_override(&"font_size", 28)
	_reveal_hint.modulate.a = 0.0
	_reveal_title_stack.add_child(_reveal_hint)


func _refresh() -> void:
	if _game == null or not bool(_game.get("campaign_active")) or _game.get("campaign") == null:
		_marks_label.text = _copy(&"ui.gacha.campaign_offline", "CAMPAIGN OFFLINE")
		_pull_button.text = _copy(&"ui.gacha.pull_unavailable", "PULL UNAVAILABLE")
		_pull_button.disabled = true
		_back_button.disabled = _flow_state != FlowState.BROWSE
		Style.apply_button(_pull_button, &"disabled")
		_status_label.text = _copy(&"ui.gacha.campaign_required", "Start or continue a campaign to access premium resonance.")
		return
	var projection: Dictionary = _game.get("campaign").runtime_projection()
	var marks := int(projection["marks"])
	var cost := int(projection["premium_pull_cost"])
	var pity_streak := int(projection.get("premium_pity_streak", 0))
	var guarantee_in := int(projection.get("premium_guarantee_in", HARD_PITY_WINDOW))
	_marks_label.text = _format(&"ui.gacha.marks", "{count} MARKS", {&"count": marks})
	_pull_button.text = _format(&"ui.gacha.pull_action", "RESONATE • {cost} MARKS", {&"cost": cost})
	var attempt_pending := bool(projection.get("attempt_pending", false))
	var browse_locked := _flow_state != FlowState.BROWSE
	_pull_button.disabled = marks < cost or attempt_pending or browse_locked
	_back_button.disabled = browse_locked
	Style.apply_button(_pull_button, &"disabled" if _pull_button.disabled else &"gold")
	_pity_label.text = _format(&"ui.gacha.guarantee_in", "5-STAR GUARANTEED IN {count} {unit}", {
		&"count": guarantee_in, &"unit": _pull_unit(guarantee_in).to_upper(),
	})
	for index: int in _pity_segments.get_child_count():
		var segment := _pity_segments.get_child(index) as ColorRect
		segment.color = Style.GOLD if index < pity_streak else Color(Style.CYAN.r, Style.CYAN.g, Style.CYAN.b, 0.16)
	if _flow_state in [FlowState.CONFIRM, FlowState.COMMITTING]:
		_refresh_confirmation_copy()
	if attempt_pending:
		_status_label.text = _copy(&"ui.gacha.attempt_pending", "Resolve the active operation before using premium resonance.")
	elif marks < cost:
		_status_label.text = _format(&"ui.gacha.marks_needed", "Earn {count} more Marks for another resonance pull.", {&"count": cost - marks})
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


func _hero_card(catalog: Dictionary, hero: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.name = "Premium_%s" % catalog["premium_id"]
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var rarity := int(catalog.get("rarity", 4))
	panel.custom_minimum_size = Vector2(460 if rarity == FIVE_STAR_RARITY else 250, 430 if rarity == FIVE_STAR_RARITY else 350)
	Style.apply_panel(panel, &"danger" if not hero.is_empty() and hero["life_status"] == "dead" else (&"result" if rarity == FIVE_STAR_RARITY else &"quiet"))
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 9)
	panel.add_child(box)
	var rarity_label := _label(_format(&"ui.gacha.rarity", "{rarity}-STAR PREMIUM", {&"rarity": rarity}), &"eyebrow")
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.add_theme_color_override(&"font_color", Style.GOLD if rarity == FIVE_STAR_RARITY else Style.CYAN)
	box.add_child(rarity_label)
	var portrait := TextureRect.new()
	portrait.name = "Portrait"
	portrait.texture = Art.texture(_gacha_portrait_asset_id(String(catalog["premium_id"])))
	portrait.custom_minimum_size = Vector2(
		340 if rarity == FIVE_STAR_RARITY else 190,
		270 if rarity == FIVE_STAR_RARITY else 220,
	)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	box.add_child(portrait)
	var name := _label(String(catalog["callsign"]), &"heading")
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(name)
	var display_class := _class_name(String(catalog["class_id"]))
	var role := _label(display_class.to_upper(), &"detail")
	role.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(role)
	var status := _copy(&"ui.gacha.unacquired", "UNACQUIRED")
	var detail := _copy(&"ui.gacha.pull_to_recruit", "Pull to recruit • Fixed elite kit")
	if not hero.is_empty():
		var lives := int(hero["premium_lives"])
		status = _format(&"ui.gacha.lives", "{count} {unit}", {&"count": lives, &"unit": _life_unit(lives)})
		detail = _format(&"ui.gacha.total_copies", "{count} total copies • Fixed elite kit", {&"count": int(hero["premium_pull_count"])})
		if lives == 0:
			status = _copy(&"ui.gacha.locked_lives", "LOCKED • 0 LIVES")
			detail = _copy(&"ui.gacha.restore_hint", "Pull this hero again to restore deployment")
	var status_label := _label(status, &"metric")
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_color_override(
		&"font_color", Style.DANGER if status.begins_with("LOCKED") else Style.CYAN,
	)
	box.add_child(status_label)
	var detail_label := _label(detail, &"detail")
	detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(detail_label)
	return panel


func _apply_responsive_layout() -> void:
	if _hero_grid == null or _header_grid == null or _action_grid == null:
		return
	var viewport_size := get_viewport_rect().size
	var portrait := viewport_size.x < 900.0
	_hero_grid.columns = 1 if portrait else 3
	_header_grid.columns = 1 if portrait else 3
	_action_grid.columns = 1 if portrait else 2
	_marks_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if portrait else HORIZONTAL_ALIGNMENT_RIGHT
	var side_margin := 18 if portrait else 42
	_screen_margin.add_theme_constant_override(&"margin_left", side_margin)
	_screen_margin.add_theme_constant_override(&"margin_right", side_margin)
	_pull_button.custom_minimum_size.x = 0 if portrait else 280
	_apply_confirmation_layout(viewport_size)
	if _reveal_title_stack != null:
		_reveal_title_stack.custom_minimum_size.x = (
			maxf(280.0, viewport_size.x - 48.0) if portrait else 1120.0
		)
	if _reveal_title != null:
		var portrait_title_size := clampi(int(viewport_size.x * 0.11), 44, 72)
		_reveal_title.add_theme_font_size_override(
			&"font_size", portrait_title_size if portrait else 104,
		)
	if _reveal_hint != null:
		_reveal_hint.add_theme_font_size_override(&"font_size", 28)
	if _skip_button != null:
		_skip_button.custom_minimum_size = Vector2(300 if portrait else 340, 92)
		_skip_button.add_theme_font_size_override(&"font_size", 36)
	if _reveal_stars != null:
		for child: Node in _reveal_stars.get_children():
			var star := child as ResonanceStar
			star.custom_minimum_size = Vector2(46, 46) if portrait else Vector2(58, 58)


func _on_pull_pressed() -> void:
	if (
			_flow_state != FlowState.BROWSE
			or _confirmation_transition != ConfirmationTransition.NONE
			or _pull_button.disabled
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
	_confirmation_projection = projection.duplicate(true)
	_confirmation_exit_status = ""
	_confirmation_exit_live = AccessibilityServer.LIVE_OFF
	_premium_pull_dispatched = false
	_flow_state = FlowState.CONFIRM
	_suppress_browse_focus()
	_confirmation_layer.modulate.a = 0.0
	_confirmation_frame.offset_transform_position = Vector2(0.0, CONFIRM_FRAME_OFFSET)
	_confirmation_layer.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
	_confirmation_layer.visible = true
	_set_confirmation_status("", AccessibilityServer.LIVE_POLITE)
	_set_confirmation_pending(false)
	_refresh_confirmation_copy()
	_apply_responsive_layout()
	Sfx.play("ui_click")
	_play_confirmation_entry()


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
	_reveal_hint.modulate.a = 0.0
	for index: int in _reveal_stars.get_child_count():
		var star := _reveal_stars.get_child(index) as ResonanceStar
		star.set_state(accent, false)
		star.visible = false
		star.modulate.a = 0.0
		star.scale = Vector2(0.18, 0.18)
		star.rotation = -TAU * 1.25
	_reveal_burst.modulate = Color(accent.r, accent.g, accent.b, 0.8)
	_reveal_burst.rotation = -0.08
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
		_skip_button.grab_focus()
		return
	_reveal_tween = create_tween()
	_reveal_tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	_reveal_tween.tween_property(_reveal_layer, "modulate:a", 1.0, 0.18)
	_reveal_tween.parallel().tween_property(_reveal_burst, "rotation", 0.08, 0.56)


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
	_kill_cinematic_watchdog()
	var video := _cinematic_player.video_player()
	if video == null or not video.is_playing():
		_cinematic_player.show_final_plate()
	var rarity := int(_pending_pull.get("rarity", 4))
	var accent := _reveal_accent(_pending_pull)
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
	_reveal_tween.tween_property(_reveal_hint, "modulate:a", 0.78, 0.28)


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
	var pulse := create_tween().set_loops()
	pulse.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(star, "scale", Vector2(1.06, 1.06), REVEAL_STAR_PULSE_SECONDS * 0.5)
	pulse.tween_property(star, "scale", Vector2.ONE, REVEAL_STAR_PULSE_SECONDS * 0.5)
	_star_pulse_tweens.append(pulse)


func _reveal_identity_immediately(rarity: int, accent: Color) -> void:
	_reveal_title_stack.visible = true
	_reveal_title.modulate.a = 1.0
	_reveal_title.scale = Vector2.ONE
	_reveal_hint.modulate.a = 0.78
	for index: int in _reveal_stars.get_child_count():
		var star := _reveal_stars.get_child(index) as ResonanceStar
		var lit := index < rarity
		star.visible = lit
		star.modulate.a = 1.0 if lit else 0.0
		star.scale = Vector2.ONE
		star.rotation = 0.0
		star.set_state(accent, lit)


func _finish_reveal() -> void:
	if not _is_revealing:
		return
	_kill_reveal_tween()
	_kill_cinematic_watchdog()
	_stop_star_pulses()
	_stop_cinematic()
	var final_copy := _result_copy(_pending_pull)
	_is_revealing = false
	_reveal_result_ready = false
	_flow_state = FlowState.BROWSE
	_reveal_layer.visible = false
	_reveal_layer.modulate.a = 0.0
	_reveal_title_stack.visible = false
	_pending_pull = {}
	_screen_margin.visible = true
	_screen_margin.focus_behavior_recursive = Control.FOCUS_BEHAVIOR_ENABLED
	_refresh()
	_status_label.text = final_copy
	_status_label.accessibility_live = AccessibilityServer.LIVE_POLITE
	_restore_confirmation_return_focus(_confirmation_transition_token)


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
		Music.stop()
		Music.play_staging(&"lunaris")


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


func _reveal_accent(pull: Dictionary) -> Color:
	if String(pull.get("premium_id", "")) == "archive_caster":
		return Style.GOLD
	return Style.GOLD if int(pull.get("rarity", 4)) == FIVE_STAR_RARITY else Style.CYAN


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


func _on_back_pressed() -> void:
	if _flow_state != FlowState.BROWSE:
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
	_confirmation_title.add_theme_font_size_override(&"font_size", 44 if narrow else (64 if short else 76))
	_confirmation_body_grid.columns = 2 if wide else 1
	_confirmation_context_eyebrow.visible = not narrow
	_confirmation_review_eyebrow.visible = not narrow
	_confirmation_actions.columns = 1 if narrow or portrait else 2
	var action_height := 72.0 if short else 88.0
	_confirmation_cancel.custom_minimum_size = Vector2(0, action_height)
	_confirmation_confirm.custom_minimum_size = Vector2(0, action_height)
	_confirmation_header_cancel.custom_minimum_size.y = action_height
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
	_back_button.text = _copy(&"ui.gacha.back", "← COMMAND DECK")
	_browse_eyebrow.text = _copy(&"ui.gacha.eyebrow", "LUNARIS RELIQUARY")
	_browse_title.text = _copy(&"ui.gacha.title", "Premium Resonance")
	_browse_intro.text = _copy(
		&"ui.gacha.intro",
		"Every resonance grants one life. Premium heroes keep fixed elite kits and cannot be trained. 5-star base rate: 5% • guaranteed within ten pulls.",
	)
	_skip_button.text = _copy(&"ui.gacha.skip_reveal", "SKIP REVEAL")
	_reveal_hint.text = _copy(&"ui.gacha.click_anywhere", "CLICK ANYWHERE TO CONTINUE")
	if _flow_state == FlowState.REVEAL and not _pending_pull.is_empty():
		_reveal_title.text = _callsign_for(
			String(_pending_pull.get("premium_id", "")),
		).to_upper()


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
