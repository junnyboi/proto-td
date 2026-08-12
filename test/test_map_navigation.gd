extends GutTest

## TD-006 paper exactness properties. The default S1 stage is 8x5, so its
## projected terrain spans x=[-5*32, 8*32] and y=[-16, 13*16]. Height-fill
## uses the terrain box only; pan bounds use the larger visual-content box.

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
const S1_SIZE := Vector2i(8, 5)
const VIEWPORTS := [Vector2(960.0, 640.0), Vector2(1280.0, 720.0), Vector2(1920.0, 1080.0)]


func test_s1_terrain_box_matches_paper_constants() -> void:
	assert_eq(IsoProjection.terrain_box(S1_SIZE), Rect2(-160.0, -16.0, 416.0, 224.0))


func test_height_fill_scale_matches_viewport_height_exactly() -> void:
	var expected := 720.0 / 224.0
	assert_almost_eq(
		IsoProjection.height_fill_scale(S1_SIZE, Vector2(1280.0, 720.0)), expected, 0.0001
	)
	for viewport: Vector2 in VIEWPORTS:
		var scale := IsoProjection.height_fill_scale(S1_SIZE, viewport)
		var screen_height := IsoProjection.terrain_box(S1_SIZE).size.y * scale
		assert_almost_eq(screen_height, viewport.y, 0.0001, "viewport %s" % viewport)


func test_every_campaign_stage_has_positive_finite_height_fill() -> void:
	for stage_path: String in STAGE_PATHS:
		var stage := load(stage_path) as StageDef
		assert_not_null(stage, stage_path)
		var scale := IsoProjection.height_fill_scale(stage.grid_size(), Vector2(1280.0, 720.0))
		assert_true(scale > 0.0 and not is_inf(scale) and not is_nan(scale), stage_path)
		assert_almost_eq(
			IsoProjection.terrain_box(stage.grid_size()).size.y * scale,
			720.0,
			0.0001,
			stage_path,
		)


func test_pan_extrema_put_content_edges_on_viewport_edges() -> void:
	var viewport := Vector2(1280.0, 720.0)
	var scale := IsoProjection.height_fill_scale(S1_SIZE, viewport)
	var bounds := IsoProjection.pan_bounds(S1_SIZE, viewport, scale)
	assert_true(bounds.size.x > 0.0 and bounds.size.y > 0.0, "bounds %s" % bounds)
	var at_min := IsoProjection.content_screen_rect(S1_SIZE, viewport, scale, bounds.position)
	var at_max := IsoProjection.content_screen_rect(S1_SIZE, viewport, scale, bounds.end)
	assert_almost_eq(at_min.end.x, viewport.x, 0.0001)
	assert_almost_eq(at_min.end.y, viewport.y, 0.0001)
	assert_almost_eq(at_max.position.x, 0.0, 0.0001)
	assert_almost_eq(at_max.position.y, 0.0, 0.0001)


func test_pan_clamp_rejects_beyond_edge_void() -> void:
	var viewport := Vector2(1280.0, 720.0)
	var scale := IsoProjection.height_fill_scale(S1_SIZE, viewport)
	var bounds := IsoProjection.pan_bounds(S1_SIZE, viewport, scale)
	assert_eq(IsoProjection.clamp_pan(Vector2(-100000.0, -100000.0), bounds), bounds.position)
	assert_eq(IsoProjection.clamp_pan(Vector2(100000.0, 100000.0), bounds), bounds.end)


func test_initial_framing_keeps_right_edge_visible_and_y_centered() -> void:
	var navigator := MapNavigator.new()
	navigator.relayout(S1_SIZE, Vector2(1280.0, 720.0))
	assert_eq(navigator.pan.x, navigator.bounds.position.x)
	assert_eq(navigator.pan.y, 0.0)
	assert_almost_eq(navigator.content_screen_rect().end.x, 1280.0, 0.0001)


func test_axis_with_content_smaller_than_viewport_cannot_pan() -> void:
	var viewport := Vector2(4000.0, 720.0)
	var scale := IsoProjection.height_fill_scale(S1_SIZE, viewport)
	var bounds := IsoProjection.pan_bounds(S1_SIZE, viewport, scale)
	assert_eq(bounds.position.x, 0.0)
	assert_eq(bounds.size.x, 0.0)
	assert_true(bounds.size.y > 0.0)
