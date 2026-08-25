class_name SlowFieldTutorial
extends Control

signal hold_changed(held: bool)
signal tutorial_finished(skipped: bool)

const UI_COPY := preload("res://scripts/ui/components/ui_copy.gd")
const AETHERIA_THEME := preload("res://scripts/ui/components/aetheria_theme.gd")
const AETHERIA_PANEL := preload("res://scripts/ui/components/aetheria_panel.gd")

const SPELL_ID := &"slow_field"
const CARD_Z := 92
const GUIDE_Z := 88
const LIVE_SECONDS := 7.0
const PORTRAIT_MARGIN := 16.0
const LANDSCAPE_CARD_WIDTH := 470.0
const TARGET_COLOR := Color(0.34, 0.87, 0.91, 0.5)

enum Step { BRIEF, TARGET, LIVE, DONE }

var model: BattleModel = null
var battle_view: Node2D = null
var spell_bar: SpellBar = null

var _step: Step = Step.BRIEF
var _holding := false
var _finished := false
var _feedback := ""
var _target_cell := Vector2i.ZERO

var _card: PanelContainer = null
var _step_label: Label = null
var _icon: TextureRect = null
var _title: Label = null
var _body: Label = null
var _feedback_label: Label = null
var _primary_button: Button = null
var _skip_button: Button = null
var _focus_ring: PanelContainer = null
var _target_marker: Polygon2D = null
var _dismiss_timer: Timer = null


func setup(
	battle_model: BattleModel,
	owner_view: Node2D,
	owner_spell_bar: SpellBar,
) -> void:
	model = battle_model
	battle_view = owner_view
	spell_bar = owner_spell_bar
	_target_cell = _shared_corridor_cell()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2.ZERO
	size = get_viewport().get_visible_rect().size
	z_index = CARD_Z
	theme = AETHERIA_THEME.new()
	_build_guides()
	_build_card()
	_dismiss_timer = Timer.new()
	_dismiss_timer.name = "SlowFieldTutorialDismissTimer"
	_dismiss_timer.one_shot = true
	_dismiss_timer.timeout.connect(_on_dismiss_timeout)
	add_child(_dismiss_timer)
	spell_bar.targeting_started.connect(_on_targeting_started)
	spell_bar.targeting_stopped.connect(_on_targeting_stopped)
	spell_bar.cast_resolved.connect(_on_cast_resolved)
	I18n.locale_changed.connect(_on_locale_changed)
	spell_bar.set_tutorial_spell(SPELL_ID)
	_set_step(Step.BRIEF)
	_set_hold(true)
	relayout()


func is_holding_battle() -> bool:
	return _holding


func current_step_name() -> StringName:
	match _step:
		Step.BRIEF:
			return &"brief"
		Step.TARGET:
			return &"target"
		Step.LIVE:
			return &"live"
		_:
			return &"done"


func recommended_cell() -> Vector2i:
	return _target_cell


func relayout() -> void:
	if _card == null:
		return
	size = get_viewport().get_visible_rect().size
	var portrait := size.y > size.x
	var card_width := (
		minf(size.x - PORTRAIT_MARGIN * 2.0, 620.0)
		if portrait
		else minf(size.x - 40.0, LANDSCAPE_CARD_WIDTH)
	)
	_card.custom_minimum_size = Vector2(card_width, 0.0)
	_card.reset_size()
	_card.size = Vector2(card_width, _card.get_combined_minimum_size().y)
	if portrait:
		_card.position = Vector2(
			(size.x - _card.size.x) * 0.5,
			maxf(112.0, size.y - _card.size.y - 184.0),
		)
	else:
		_card.position = Vector2(20.0, 108.0)
	_icon.custom_minimum_size = Vector2.ONE * (72.0 if portrait else 82.0)
	_relayout_guides()


func _process(_delta: float) -> void:
	if _finished:
		return
	var pulse := 0.72 + sin(float(Time.get_ticks_msec()) / 180.0) * 0.22
	if _focus_ring != null:
		_focus_ring.modulate.a = pulse if _focus_ring.visible else 1.0
	if _target_marker != null:
		_target_marker.modulate.a = pulse if _target_marker.visible else 1.0
	_update_focus_ring()
	_relayout_guides()


func _build_guides() -> void:
	_target_marker = Polygon2D.new()
	_target_marker.name = "SlowFieldTutorialTarget"
	_target_marker.color = TARGET_COLOR
	_target_marker.visible = false
	_target_marker.z_index = GUIDE_Z
	add_child(_target_marker)
	_focus_ring = AETHERIA_PANEL.new()
	_focus_ring.name = "SlowFieldTutorialFocusRing"
	_focus_ring.apply_role(&"focus_ring")
	_focus_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_focus_ring.visible = false
	_focus_ring.z_index = GUIDE_Z + 2
	add_child(_focus_ring)


func _build_card() -> void:
	_card = AETHERIA_PANEL.new()
	_card.name = "SlowFieldTutorialCard"
	_card.apply_role(&"modal")
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	_card.z_index = CARD_Z
	add_child(_card)
	var safe_area := MarginContainer.new()
	safe_area.name = "TutorialSafeArea"
	safe_area.add_theme_constant_override("margin_left", 12)
	safe_area.add_theme_constant_override("margin_top", 10)
	safe_area.add_theme_constant_override("margin_right", 12)
	safe_area.add_theme_constant_override("margin_bottom", 14)
	_card.add_child(safe_area)
	var column := VBoxContainer.new()
	column.name = "TutorialColumn"
	column.add_theme_constant_override("separation", 10)
	safe_area.add_child(column)
	_step_label = Label.new()
	_step_label.name = "SlowFieldTutorialStep"
	_step_label.theme_type_variation = &"AuiDenseDetailLabel"
	_step_label.add_theme_font_size_override("font_size", 18)
	column.add_child(_step_label)
	var content := HBoxContainer.new()
	content.name = "TutorialContent"
	content.add_theme_constant_override("separation", 14)
	column.add_child(content)
	_icon = TextureRect.new()
	_icon.name = "SlowFieldTutorialArt"
	_icon.texture = Art.texture(&"icon_slow_field")
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.custom_minimum_size = Vector2.ONE * 82.0
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(_icon)
	var copy_column := VBoxContainer.new()
	copy_column.name = "CopyColumn"
	copy_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy_column.add_theme_constant_override("separation", 7)
	content.add_child(copy_column)
	_title = Label.new()
	_title.name = "SlowFieldTutorialTitle"
	_title.theme_type_variation = &"AuiDenseHeadingLabel"
	_title.add_theme_font_size_override("font_size", 28)
	copy_column.add_child(_title)
	_body = Label.new()
	_body.name = "SlowFieldTutorialBody"
	_body.theme_type_variation = &"AuiDenseBodyLabel"
	_body.add_theme_font_size_override("font_size", 20)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy_column.add_child(_body)
	_feedback_label = Label.new()
	_feedback_label.name = "SlowFieldTutorialFeedback"
	_feedback_label.theme_type_variation = &"AuiDenseDetailLabel"
	_feedback_label.add_theme_font_size_override("font_size", 18)
	_feedback_label.add_theme_color_override("font_color", Color("72e3e8"))
	_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy_column.add_child(_feedback_label)
	var actions := HBoxContainer.new()
	actions.name = "TutorialActions"
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 12)
	column.add_child(actions)
	_skip_button = _make_button("SkipSlowFieldTutorial", &"AuiSecondaryButton")
	_skip_button.pressed.connect(_on_skip_pressed)
	actions.add_child(_skip_button)
	_primary_button = _make_button("SlowFieldTutorialPrimary", &"AuiPrimaryButton")
	_primary_button.pressed.connect(_on_primary_pressed)
	actions.add_child(_primary_button)


func _make_button(button_name: String, variation: StringName) -> Button:
	var button := Button.new()
	button.name = button_name
	button.theme_type_variation = variation
	button.custom_minimum_size = Vector2(150.0, 48.0)
	button.add_theme_font_size_override("font_size", 20)
	return button


func _set_step(next: Step) -> void:
	_step = next
	_feedback = ""
	_refresh_copy()
	_update_guides()
	call_deferred("relayout")


func _refresh_copy() -> void:
	if _card == null:
		return
	_skip_button.visible = true
	_primary_button.visible = false
	match _step:
		Step.BRIEF:
			_step_label.text = _copy(&"ui.tutorial.slow_field.brief.step", "1 / 2  SLOW FIELD")
			_title.text = _copy(&"ui.tutorial.slow_field.brief.title", "Control the convergence")
			_body.text = _copy(
				&"ui.tutorial.slow_field.brief.body",
				"Slow Field covers a 3×3 ground area, halves ground movement for 8 seconds, and recharges in 20 seconds. Air units ignore it.",
			)
			_primary_button.text = _copy(&"ui.tutorial.slow_field.brief.action", "Select Slow Field")
			_primary_button.visible = true
			_skip_button.text = _copy(&"ui.tutorial.skip", "Skip tutorial")
		Step.TARGET:
			_step_label.text = _copy(&"ui.tutorial.slow_field.target.step", "2 / 2  CAST")
			_title.text = _copy(&"ui.tutorial.slow_field.target.title", "Cast on the shared lane")
			_body.text = _copy(
				&"ui.tutorial.slow_field.target.body",
				"Cast on the cyan marker where all three routes converge. Duration and cooldown timers will remain on the spell card.",
			)
			_skip_button.text = _copy(&"ui.tutorial.skip", "Skip tutorial")
		Step.LIVE:
			_step_label.text = _copy(&"ui.tutorial.slow_field.live.step", "FIELD ACTIVE")
			_title.text = _copy(&"ui.tutorial.slow_field.live.title", "Watch both timers")
			_body.text = _copy(
				&"ui.tutorial.slow_field.live.body",
				"Cyan tracks remaining field duration. Gold tracks the 20-second cooldown. The spell can be cast again when READY returns.",
			)
			_skip_button.text = _copy(&"ui.tutorial.dismiss", "Dismiss")
		_:
			return
	_feedback_label.text = _feedback
	_feedback_label.visible = not _feedback.is_empty()
	_card.reset_size()


func _update_guides() -> void:
	_focus_ring.visible = _step == Step.BRIEF
	_target_marker.visible = _step == Step.TARGET
	_relayout_guides()


func _relayout_guides() -> void:
	if battle_view == null or _target_marker == null:
		return
	_target_marker.polygon = IsoProjection.face_polygon(battle_view.call("grid_scale") * 3.0)
	_target_marker.position = battle_view.call("cell_center", _target_cell)
	_update_focus_ring()


func _update_focus_ring() -> void:
	if _focus_ring == null or spell_bar == null or _step != Step.BRIEF:
		if _focus_ring != null:
			_focus_ring.visible = false
		return
	var rect := spell_bar.slot_screen_rect(SPELL_ID)
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		_focus_ring.visible = false
		return
	_focus_ring.visible = true
	_focus_ring.position = rect.position - Vector2.ONE * 6.0
	_focus_ring.size = rect.size + Vector2.ONE * 12.0


func _on_primary_pressed() -> void:
	Sfx.play("ui_click")
	if _step != Step.BRIEF:
		return
	if spell_bar.request_targeting(SPELL_ID):
		_set_step(Step.TARGET)
	else:
		_feedback = _copy(
			&"ui.tutorial.slow_field.unavailable",
			"Slow Field is not ready yet.",
		)
		_refresh_copy()


func _on_skip_pressed() -> void:
	Sfx.play("ui_click")
	_finish(_step != Step.LIVE)


func _on_targeting_started(spell_id: StringName) -> void:
	if spell_id == SPELL_ID and _step == Step.BRIEF:
		_set_step(Step.TARGET)


func _on_targeting_stopped(spell_id: StringName) -> void:
	if spell_id != SPELL_ID or _step != Step.TARGET:
		return
	_feedback = _copy(
		&"ui.tutorial.slow_field.cancelled",
		"Targeting cancelled. Select Slow Field and cast on the shared lane.",
	)
	_set_step(Step.BRIEF)
	_refresh_copy()


func _on_cast_resolved(spell_id: StringName, target: Variant, accepted: bool) -> void:
	if spell_id != SPELL_ID or _step != Step.TARGET:
		return
	if not accepted:
		_feedback = _copy(
			&"ui.tutorial.slow_field.invalid",
			"That cast was rejected. Aim inside the battlefield.",
		)
		_refresh_copy()
		return
	if typeof(target) == TYPE_VECTOR2I:
		_target_cell = target
	spell_bar.set_tutorial_spell(&"")
	_set_step(Step.LIVE)
	_set_hold(false)
	_dismiss_timer.start(LIVE_SECONDS)


func _on_dismiss_timeout() -> void:
	if _step == Step.LIVE and not _finished:
		_finish(false)


func _finish(skipped: bool) -> void:
	if _finished:
		return
	_finished = true
	_step = Step.DONE
	if _dismiss_timer != null:
		_dismiss_timer.stop()
	spell_bar.set_tutorial_spell(&"")
	spell_bar.stop_targeting()
	_target_marker.visible = false
	_focus_ring.visible = false
	_card.visible = false
	_set_hold(false)
	tutorial_finished.emit(skipped)
	queue_free()


func _set_hold(held: bool) -> void:
	if _holding == held:
		return
	_holding = held
	hold_changed.emit(held)


func _shared_corridor_cell() -> Vector2i:
	var owners: Dictionary = {}
	for path_index: int in model.stage.paths.size():
		for cell: Vector2i in model.stage.path_cells(path_index):
			owners[cell] = int(owners.get(cell, 0)) + 1
	var shared: Array[Vector2i] = []
	for cell: Vector2i in owners:
		if int(owners[cell]) > 1:
			shared.append(cell)
	shared.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.y < b.y or (a.y == b.y and a.x < b.x))
	if shared.is_empty():
		return model.stage.path_cells(0)[0]
	return shared[shared.size() / 2]


func _copy(key: StringName, fallback: String) -> String:
	return UI_COPY.text(key, fallback)


func _on_locale_changed(_locale_id: StringName) -> void:
	_refresh_copy()
	call_deferred("relayout")
