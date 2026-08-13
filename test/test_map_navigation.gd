extends GutTest

## TD-008 paper exactness properties. S1 is 8x5 and no elevated cell touches
## its projected outer edge, so its rendered terrain spans x=[-5*32, 8*32]
## and y=[0, 13*16]. The expected constants below are independent of the
## production helper implementation.

const STAGE_PATHS := [
	"res://data/stages/s1.tres",
	"res://data/stages/s2.tres",
	"res://data/stages/s3.tres",
	"res://data/stages/s4.tres",
	"res://data/stages/s5.tres",
	"res://data/stages/s6.tres",
	"res://data/stages/s7.tres",
	"res://data/stages/s8.tres",
]
const BATTLE_VIEW_PATH := "res://scripts/view/battle_view.gd"
const MAP_NAVIGATOR_PATH := "res://scripts/view/map_navigator.gd"
const BATTLE_VIEW_SCRIPT: GDScript = preload("res://scripts/view/battle_view.gd")
const S1: StageDef = preload("res://data/stages/s1.tres")
const S2: StageDef = preload("res://data/stages/s2.tres")
const S3: StageDef = preload("res://data/stages/s3.tres")
const VIEWPORTS := [Vector2(960.0, 640.0), Vector2(1280.0, 720.0), Vector2(1920.0, 1080.0)]
const PORTRAIT_VIEWPORT := Vector2(720.0, 1280.0)


func test_battle_view_pins_map_navigator_as_an_explicit_resource_dependency() -> void:
	assert_not_null(BATTLE_VIEW_SCRIPT)
	var source := FileAccess.get_file_as_string(BATTLE_VIEW_PATH)
	assert_false(source.is_empty(), BATTLE_VIEW_PATH)
	assert_true(
		source.contains('preload("%s")' % MAP_NAVIGATOR_PATH),
		"BattleView must parse without relying on a pre-populated MapNavigator class cache",
	)


func test_s1_rendered_terrain_box_matches_independent_constants() -> void:
	assert_eq(IsoProjection.terrain_box(S1), Rect2(-160.0, 0.0, 416.0, 208.0))


func test_height_fill_scale_matches_viewport_height_exactly() -> void:
	var expected := 720.0 / 208.0
	assert_almost_eq(IsoProjection.height_fill_scale(S1, Vector2(1280.0, 720.0)), expected, 0.0001)
	for viewport: Vector2 in VIEWPORTS:
		var scale := IsoProjection.height_fill_scale(S1, viewport)
		var screen_height := 208.0 * scale
		assert_almost_eq(screen_height, viewport.y, 0.0001, "viewport %s" % viewport)


func test_every_campaign_stage_has_positive_finite_height_fill() -> void:
	for stage_path: String in STAGE_PATHS:
		var stage := load(stage_path) as StageDef
		assert_not_null(stage, stage_path)
		var box := IsoProjection.terrain_box(stage)
		var scale := IsoProjection.height_fill_scale(stage, Vector2(1280.0, 720.0))
		assert_true(box.size.x > 0.0 and box.size.y > 0.0, stage_path)
		assert_true(scale > 0.0 and not is_inf(scale) and not is_nan(scale), stage_path)
		assert_almost_eq(box.size.y * scale, 720.0, 0.0001, stage_path)


func test_pan_extrema_put_content_edges_on_viewport_edges() -> void:
	var viewport := Vector2(1280.0, 720.0)
	var scale := IsoProjection.height_fill_scale(S1, viewport)
	var bounds := IsoProjection.pan_bounds(S1, viewport, scale)
	assert_true(bounds.size.x > 0.0 and bounds.size.y > 0.0, "bounds %s" % bounds)
	var at_min := IsoProjection.content_screen_rect(S1, viewport, scale, bounds.position)
	var at_max := IsoProjection.content_screen_rect(S1, viewport, scale, bounds.end)
	assert_almost_eq(at_min.end.x, viewport.x, 0.0001)
	assert_almost_eq(at_min.end.y, viewport.y, 0.0001)
	assert_almost_eq(at_max.position.x, 0.0, 0.0001)
	assert_almost_eq(at_max.position.y, 0.0, 0.0001)


func test_pan_clamp_rejects_beyond_edge_void() -> void:
	var viewport := Vector2(1280.0, 720.0)
	var scale := IsoProjection.height_fill_scale(S1, viewport)
	var bounds := IsoProjection.pan_bounds(S1, viewport, scale)
	assert_eq(IsoProjection.clamp_pan(Vector2(-100000.0, -100000.0), bounds), bounds.position)
	assert_eq(IsoProjection.clamp_pan(Vector2(100000.0, 100000.0), bounds), bounds.end)


func test_initial_framing_keeps_right_edge_visible_and_y_centered() -> void:
	var navigator := MapNavigator.new()
	navigator.relayout(S1, Vector2(1280.0, 720.0))
	assert_eq(navigator.pan.x, navigator.bounds.position.x)
	assert_eq(navigator.pan.y, 0.0)
	assert_almost_eq(navigator.content_screen_rect().end.x, 1280.0, 0.0001)


func test_act2_target_viewports_fit_complete_content_inside_persistent_ui() -> void:
	var cases: Array = [
		[Vector2(1920.0, 1080.0), Rect2(16.0, 104.0, 1888.0, 822.0)],
		[Vector2(1280.0, 720.0), Rect2(16.0, 104.0, 1248.0, 462.0)],
		[Vector2(960.0, 720.0), Rect2(16.0, 104.0, 928.0, 398.0)],
		[PORTRAIT_VIEWPORT, Rect2(16.0, 104.0, 688.0, 802.0)],
	]
	for spec: Array in cases:
		var viewport: Vector2 = spec[0]
		var safe: Rect2 = spec[1]
		for stage: StageDef in [S2, S3]:
			var navigator := MapNavigator.new()
			navigator.relayout(stage, viewport)
			assert_eq(
				navigator.scale,
				IsoProjection.fit_scale(stage.grid_size(), safe.size),
			)
			assert_eq(navigator.pan, Vector2.ZERO)
			assert_eq(navigator.bounds, Rect2())
			assert_true(safe.encloses(navigator.content_screen_rect()))


func test_resize_preserves_pixel_pan_then_clamps_exactly() -> void:
	var navigator := MapNavigator.new()
	navigator.relayout(S1, Vector2(1280.0, 720.0))
	navigator.pan = Vector2(12.0, 180.0)
	var old_pan := navigator.pan
	navigator.relayout(S1, Vector2(960.0, 640.0))
	assert_eq(navigator.pan, IsoProjection.clamp_pan(old_pan, navigator.bounds))


func test_missed_release_clears_latched_middle_drag_on_motion() -> void:
	var navigator := MapNavigator.new()
	navigator.relayout(S1, Vector2(1280.0, 720.0))
	assert_true(navigator.handle_input(_mouse_button(MOUSE_BUTTON_MIDDLE, true)))
	assert_true(navigator.is_dragging())
	var before := navigator.pan
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(100.0, 100.0)
	motion.button_mask = 0
	assert_false(navigator.handle_input(motion))
	assert_false(navigator.is_dragging())
	assert_eq(navigator.pan, before)


func test_native_horizontal_wheel_moves_only_x() -> void:
	var navigator := MapNavigator.new()
	navigator.relayout(S1, Vector2(1280.0, 720.0))
	navigator.pan = navigator.bounds.position
	var before := navigator.pan
	assert_true(navigator.handle_input(_mouse_button(MOUSE_BUTTON_WHEEL_LEFT, true)))
	assert_true(navigator.pan.x > before.x)
	assert_eq(navigator.pan.y, before.y)


func test_ensure_visible_reveals_a_clipped_unit_rect() -> void:
	var navigator := MapNavigator.new()
	navigator.relayout(S1, Vector2(1280.0, 720.0))
	var local_rect := Rect2(-32.0, -66.0, 64.0, 80.0)
	assert_true(navigator.ensure_local_rect_visible(local_rect))
	var screen_top := navigator.root_position().y + local_rect.position.y * navigator.scale
	assert_almost_eq(screen_top, 0.0, 0.0001)


func test_axis_with_content_smaller_than_viewport_cannot_pan() -> void:
	var viewport := Vector2(4000.0, 720.0)
	var scale := IsoProjection.height_fill_scale(S1, viewport)
	var bounds := IsoProjection.pan_bounds(S1, viewport, scale)
	assert_eq(bounds.position.x, 0.0)
	assert_eq(bounds.size.x, 0.0)
	assert_true(bounds.size.y > 0.0)


func _mouse_button(index: MouseButton, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = index
	event.pressed = pressed
	return event
