class_name FirstStandTutorial
extends Control

signal hold_changed(held: bool)
signal tutorial_finished(skipped: bool)

const UI_COPY := preload("res://scripts/ui/components/ui_copy.gd")
const AETHERIA_THEME := preload("res://scripts/ui/components/aetheria_theme.gd")
const AETHERIA_PANEL := preload("res://scripts/ui/components/aetheria_panel.gd")

const ROUTE_TEXTURE := preload("res://assets/tutorial/tutorial_route_marker.png")
const DEPLOY_TEXTURE := preload("res://assets/tutorial/tutorial_deploy_gesture.png")
const FACING_TEXTURE := preload("res://assets/tutorial/tutorial_facing_compass.png")
const BLOCK_TEXTURE := preload("res://assets/tutorial/tutorial_block_shield.png")

const RECOMMENDED_CELL := Vector2i(3, 2)
const RECOMMENDED_FACING := UnitState.Facing.LEFT
const CARD_Z := 92
const GUIDE_Z := 88
const LANDSCAPE_CARD_WIDTH := 500.0
const PORTRAIT_MARGIN := 16.0
const LIVE_SECONDS := 6.0

const ROUTE_COLOR := Color(0.36, 0.78, 0.83, 0.26)
const TARGET_COLOR := Color(0.89, 0.70, 0.25, 0.44)

enum Step { ROUTE, DEPLOY, FACING, BLOCK, LIVE, DONE }

var model: BattleModel = null
var battle_view: Node2D = null
var deploy_bar: DeployBar = null

var _step: Step = Step.ROUTE
var _holding := false
var _finished := false
var _feedback := ""
var _deployment_id: StringName = &""
var _target_cell := RECOMMENDED_CELL
var _live_serial := 0

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
var _route_markers: Array[Polygon2D] = []


func setup(
	battle_model: BattleModel,
	owner_view: Node2D,
	owner_deploy_bar: DeployBar,
) -> void:
	model = battle_model
	battle_view = owner_view
	deploy_bar = owner_deploy_bar
	_deployment_id = deploy_bar.first_deployment_id()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2.ZERO
	size = get_viewport().get_visible_rect().size
	z_index = CARD_Z
	theme = AETHERIA_THEME.new()
	_build_guides()
	_build_card()
	deploy_bar.placement_started.connect(_on_placement_started)
	deploy_bar.placement_rejected.connect(_on_placement_rejected)
	deploy_bar.facing_requested.connect(_on_facing_requested)
	deploy_bar.deployment_committed.connect(_on_deployment_committed)
	I18n.locale_changed.connect(_on_locale_changed)
	_set_step(Step.ROUTE)
	_set_hold(true)
	relayout()


func current_step_name() -> StringName:
	match _step:
		Step.ROUTE:
			return &"route"
		Step.DEPLOY:
			return &"deploy"
		Step.FACING:
			return &"facing"
		Step.BLOCK:
			return &"block"
		Step.LIVE:
			return &"live"
		_:
			return &"done"


func is_holding_battle() -> bool:
	return _holding


func relayout() -> void:
	if _card == null or deploy_bar == null:
		return
	size = get_viewport().get_visible_rect().size
	var portrait := size.y > size.x
	var card_width := (
		minf(size.x - PORTRAIT_MARGIN * 2.0, 688.0)
		if portrait
		else minf(size.x - 40.0, LANDSCAPE_CARD_WIDTH)
	)
	_card.custom_minimum_size = Vector2(card_width, 0.0)
	_card.reset_size()
	_card.size = Vector2(card_width, _card.get_combined_minimum_size().y)
	if portrait:
		var slot_top := size.y - 180.0
		var slot_rect := deploy_bar.slot_screen_rect(_deployment_id)
		if slot_rect.size.y > 0.0:
			slot_top = slot_rect.position.y
		_card.position = Vector2(
			(size.x - _card.size.x) * 0.5,
			maxf(112.0, slot_top - _card.size.y - 16.0),
		)
	else:
		_card.position = Vector2(size.x - _card.size.x - 20.0, 116.0)
	_icon.custom_minimum_size = Vector2.ONE * (112.0 if portrait else 128.0)
	_relayout_guides()


func _process(_delta: float) -> void:
	if _finished or battle_view == null or deploy_bar == null:
		return
	if _step == Step.FACING and not deploy_bar.is_facing_pending() and model.units.is_empty():
		_set_step(Step.DEPLOY)
		_feedback = _copy(
			&"ui.tutorial.deploy.cancelled",
			"Placement cancelled. Drag a Recruit onto a green path tile when ready.",
		)
		_refresh_copy()
	var pulse := 0.72 + sin(float(Time.get_ticks_msec()) / 180.0) * 0.22
	_focus_ring.modulate.a = pulse if _focus_ring.visible else 1.0
	_target_marker.modulate.a = pulse if _target_marker.visible else 1.0
	for marker: Polygon2D in _route_markers:
		marker.modulate.a = pulse if marker.visible else 1.0
	_update_focus_ring()


func _build_guides() -> void:
	for cell: Vector2i in model.stage.path_cells(0):
		var marker := Polygon2D.new()
		marker.name = "Route_%d_%d" % [cell.x, cell.y]
		marker.color = ROUTE_COLOR
		marker.polygon = IsoProjection.face_polygon(battle_view.call("grid_scale"))
		marker.position = battle_view.call("cell_center", cell)
		marker.visible = false
		marker.z_index = GUIDE_Z
		add_child(marker)
		_route_markers.append(marker)
	_target_marker = Polygon2D.new()
	_target_marker.name = "RecommendedCell"
	_target_marker.color = TARGET_COLOR
	_target_marker.polygon = IsoProjection.face_polygon(battle_view.call("grid_scale"))
	_target_marker.visible = false
	_target_marker.z_index = GUIDE_Z + 1
	add_child(_target_marker)
	_focus_ring = AETHERIA_PANEL.new()
	_focus_ring.name = "TutorialFocusRing"
	_focus_ring.apply_role(&"focus_ring")
	_focus_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_focus_ring.visible = false
	_focus_ring.z_index = GUIDE_Z + 2
	add_child(_focus_ring)


func _build_card() -> void:
	_card = AETHERIA_PANEL.new()
	_card.name = "TutorialCard"
	_card.apply_role(&"modal")
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	_card.z_index = CARD_Z
	add_child(_card)
	var column := VBoxContainer.new()
	column.name = "TutorialColumn"
	column.add_theme_constant_override("separation", 10)
	_card.add_child(column)
	_step_label = Label.new()
	_step_label.name = "StepLabel"
	_step_label.theme_type_variation = &"AuiDenseDetailLabel"
	_step_label.add_theme_font_size_override("font_size", 20)
	column.add_child(_step_label)
	var content := HBoxContainer.new()
	content.name = "TutorialContent"
	content.add_theme_constant_override("separation", 16)
	column.add_child(content)
	_icon = TextureRect.new()
	_icon.name = "TutorialArt"
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.custom_minimum_size = Vector2.ONE * 128.0
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(_icon)
	var copy_column := VBoxContainer.new()
	copy_column.name = "CopyColumn"
	copy_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy_column.add_theme_constant_override("separation", 8)
	content.add_child(copy_column)
	_title = Label.new()
	_title.name = "TutorialTitle"
	_title.theme_type_variation = &"AuiDenseHeadingLabel"
	_title.add_theme_font_size_override("font_size", 30)
	copy_column.add_child(_title)
	_body = Label.new()
	_body.name = "TutorialBody"
	_body.theme_type_variation = &"AuiDenseBodyLabel"
	_body.add_theme_font_size_override("font_size", 22)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy_column.add_child(_body)
	_feedback_label = Label.new()
	_feedback_label.name = "TutorialFeedback"
	_feedback_label.theme_type_variation = &"AuiDenseDetailLabel"
	_feedback_label.add_theme_font_size_override("font_size", 20)
	_feedback_label.add_theme_color_override("font_color", Color("f0cf65"))
	_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy_column.add_child(_feedback_label)
	var actions := HBoxContainer.new()
	actions.name = "TutorialActions"
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 12)
	column.add_child(actions)
	_skip_button = _make_button("SkipTutorial", &"AuiSecondaryButton")
	_skip_button.pressed.connect(_on_skip_pressed)
	actions.add_child(_skip_button)
	_primary_button = _make_button("TutorialPrimary", &"AuiPrimaryButton")
	_primary_button.pressed.connect(_on_primary_pressed)
	actions.add_child(_primary_button)


func _make_button(button_name: String, variation: StringName) -> Button:
	var button := Button.new()
	button.name = button_name
	button.theme_type_variation = variation
	button.custom_minimum_size = Vector2(150.0, 48.0)
	button.add_theme_font_size_override("font_size", 22)
	return button


func _set_step(next: Step) -> void:
	_step = next
	_feedback = ""
	deploy_bar.set_facing_emphasis(-1)
	match _step:
		Step.ROUTE:
			deploy_bar.set_operator_interaction_enabled(false)
		Step.DEPLOY:
			deploy_bar.set_operator_interaction_enabled(true)
		Step.FACING:
			deploy_bar.set_operator_interaction_enabled(true)
			deploy_bar.set_facing_emphasis(int(RECOMMENDED_FACING))
		Step.BLOCK:
			deploy_bar.set_operator_interaction_enabled(false)
		Step.LIVE, Step.DONE:
			deploy_bar.set_operator_interaction_enabled(true)
	_refresh_copy()
	_update_guides()
	call_deferred("relayout")


func _refresh_copy() -> void:
	if _card == null:
		return
	_skip_button.visible = true
	_primary_button.visible = false
	match _step:
		Step.ROUTE:
			_step_label.text = _copy(&"ui.tutorial.route.step", "1 / 4  ROUTE")
			_title.text = _copy(&"ui.tutorial.route.title", "Read the route")
			_body.text = _copy(
				&"ui.tutorial.route.body",
				"Enemies enter at red and follow the lit path to your blue base. First Stand allows 3 leaks; the 4th ends the mission.",
			)
			_icon.texture = ROUTE_TEXTURE
			_primary_button.text = _copy(&"ui.tutorial.route.action", "Show deployment")
			_primary_button.visible = true
			_skip_button.text = _copy(&"ui.tutorial.skip", "Skip tutorial")
		Step.DEPLOY:
			_step_label.text = _copy(&"ui.tutorial.deploy.step", "2 / 4  DEPLOY")
			_title.text = _copy(&"ui.tutorial.deploy.title", "Deploy a Recruit")
			_body.text = _copy(
				&"ui.tutorial.deploy.body",
				"DP pays for units. Drag a Recruit card onto any green path tile; the gold marker is a safe starting position.",
			)
			_icon.texture = DEPLOY_TEXTURE
			_skip_button.text = _copy(&"ui.tutorial.skip", "Skip tutorial")
		Step.FACING:
			_step_label.text = _copy(&"ui.tutorial.facing.step", "3 / 4  FACING")
			_title.text = _copy(&"ui.tutorial.facing.title", "Choose facing")
			_body.text = _copy(
				&"ui.tutorial.facing.body",
				"Facing rotates attack coverage. Aim toward the incoming route; any arrow deploys the unit.",
			)
			_icon.texture = FACING_TEXTURE
			_skip_button.text = _copy(&"ui.tutorial.skip", "Skip tutorial")
		Step.BLOCK:
			_step_label.text = _copy(&"ui.tutorial.block.step", "4 / 4  BLOCK")
			_title.text = _copy(&"ui.tutorial.block.title", "Hold the line")
			_body.text = _copy(
				&"ui.tutorial.block.body",
				"A Recruit blocks 1 ground enemy and loses HP while fighting. Deploy another when DP refills.",
			)
			_icon.texture = BLOCK_TEXTURE
			_primary_button.text = _copy(&"ui.tutorial.block.action", "Start battle")
			_primary_button.visible = true
			_skip_button.text = _copy(&"ui.tutorial.skip", "Skip tutorial")
		Step.LIVE:
			_step_label.text = _copy(&"ui.tutorial.live.step", "FIELD REMINDER")
			_title.text = _copy(&"ui.tutorial.live.title", "Defend the base")
			_body.text = _copy(
				&"ui.tutorial.live.body",
				"Spend refilling DP, reinforce the route, and stop the 4th leak.",
			)
			_icon.texture = BLOCK_TEXTURE
			_skip_button.text = _copy(&"ui.tutorial.dismiss", "Dismiss")
		_:
			return
	_feedback_label.text = _feedback
	_feedback_label.visible = not _feedback.is_empty()
	_card.reset_size()


func _update_guides() -> void:
	var show_route := _step == Step.ROUTE
	for marker: Polygon2D in _route_markers:
		marker.visible = show_route
	_target_marker.visible = _step == Step.DEPLOY
	_focus_ring.visible = _step == Step.DEPLOY or _step == Step.FACING
	_relayout_guides()


func _relayout_guides() -> void:
	if battle_view == null or _target_marker == null:
		return
	var face_polygon: PackedVector2Array = IsoProjection.face_polygon(
		battle_view.call("grid_scale")
	)
	var path: Array[Vector2i] = model.stage.path_cells(0)
	for index: int in mini(path.size(), _route_markers.size()):
		var marker := _route_markers[index]
		marker.polygon = face_polygon
		marker.position = battle_view.call("cell_center", path[index])
	_target_marker.polygon = face_polygon
	_target_marker.position = battle_view.call("cell_center", _target_cell)
	_update_focus_ring()


func _update_focus_ring() -> void:
	if _focus_ring == null or deploy_bar == null:
		return
	if _step != Step.DEPLOY and _step != Step.FACING:
		_focus_ring.visible = false
		return
	var rect := Rect2()
	if _step == Step.DEPLOY:
		rect = deploy_bar.slot_screen_rect(_deployment_id)
	elif _step == Step.FACING:
		rect = deploy_bar.facing_button_screen_rect(int(RECOMMENDED_FACING))
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		_focus_ring.visible = false
		return
	_focus_ring.visible = true
	_focus_ring.position = rect.position - Vector2.ONE * 6.0
	_focus_ring.size = rect.size + Vector2.ONE * 12.0


func _on_primary_pressed() -> void:
	Sfx.play("ui_click")
	if _step == Step.ROUTE:
		_set_step(Step.DEPLOY)
	elif _step == Step.BLOCK:
		_begin_live_reminder()


func _on_skip_pressed() -> void:
	Sfx.play("ui_click")
	_finish(_step != Step.LIVE)


func _on_placement_started(_deployment: StringName) -> void:
	if _step != Step.DEPLOY:
		return
	_feedback = _copy(
		&"ui.tutorial.deploy.dragging",
		"Green tiles are valid. Release on the gold marker or any green path tile.",
	)
	_refresh_copy()


func _on_placement_rejected(_deployment: StringName, _cell: Vector2i) -> void:
	if _step != Step.DEPLOY and _step != Step.FACING:
		return
	_set_step(Step.DEPLOY)
	_feedback = _copy(
		&"ui.tutorial.deploy.invalid",
		"That cell cannot hold this Recruit. Use a green path tile.",
	)
	_refresh_copy()


func _on_facing_requested(_deployment: StringName, cell: Vector2i) -> void:
	if _step != Step.DEPLOY:
		return
	_target_cell = cell
	_set_step(Step.FACING)


func _on_deployment_committed(
	_deployment: StringName,
	cell: Vector2i,
	_facing: int,
) -> void:
	if _step != Step.DEPLOY and _step != Step.FACING:
		return
	_target_cell = cell
	_set_step(Step.BLOCK)


func _begin_live_reminder() -> void:
	_set_step(Step.LIVE)
	_set_hold(false)
	_live_serial += 1
	var serial := _live_serial
	_dismiss_after_delay(serial)


func _dismiss_after_delay(serial: int) -> void:
	await get_tree().create_timer(LIVE_SECONDS).timeout
	if serial == _live_serial and _step == Step.LIVE and not _finished:
		_finish(false)


func _finish(skipped: bool) -> void:
	if _finished:
		return
	_finished = true
	_step = Step.DONE
	_live_serial += 1
	deploy_bar.set_operator_interaction_enabled(true)
	deploy_bar.set_facing_emphasis(-1)
	for marker: Polygon2D in _route_markers:
		marker.visible = false
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


func _copy(key: StringName, fallback: String) -> String:
	return UI_COPY.text(key, fallback)


func _on_locale_changed(_locale_id: StringName) -> void:
	_refresh_copy()
	call_deferred("relayout")
