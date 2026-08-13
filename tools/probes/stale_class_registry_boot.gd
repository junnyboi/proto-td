extends SceneTree

## Runtime half of the stale-class-registry upgrade probe. This script avoids
## project class_name types deliberately: it must remain loadable from an old
## .godot/global_script_class_cache.cfg while exercising the newly pulled game.
const MAX_FRAMES := 360
const TITLE_SCENE_PATH := "res://scenes/title.tscn"
const REQUIRED_TITLE_NODES := [
	"TitleShell",
	"TitleBox/TitleLabel",
	"TitleBox/StartButton",
	"TitleBox/LocaleSelector/LocaleList",
]
const REQUIRED_S1_GRID_NODES := [
	"Tile_0_2",
	"Tile_1_1",
	"Tile_3_1",
	"Tile_7_2",
	"BackdropPanorama",
	"SpawnLandmark",
	"CoreLandmark",
]
const REQUIRED_S2_GRID_NODES := [
	"Tile_0_2",
	"Tile_9_2",
	"Tile_3_1",
	"Tile_3_3",
	"BackdropPanorama",
	"SpawnLandmark",
	"CoreLandmark",
	"Cadence_2_2",
	"Cadence_4_2",
	"Cadence_6_2",
	"Cadence_8_2",
]
const REQUIRED_S3_GRID_NODES := [
	"Tile_0_2",
	"Tile_9_4",
	"Tile_2_3",
	"Tile_5_2",
	"Tile_5_3",
	"BackdropPanorama",
	"SpawnLandmark",
	"CoreLandmark",
	"Cadence_2_2",
	"Cadence_4_2",
	"Cadence_4_4",
	"Cadence_7_4",
]
const EXPECTED_S2_CHILDREN := 59
const EXPECTED_S2_TILES := 50
const EXPECTED_S2_SHADES := 2
const EXPECTED_S3_CHILDREN := 68
const EXPECTED_S3_TILES := 60
const EXPECTED_S3_SHADES := 1
const EXPECTED_CADENCE := 4

var _frames := 0
var _phase := 0
var _game: Node = null


func _initialize() -> void:
	process_frame.connect(_on_process_frame)


func _on_process_frame() -> void:
	_frames += 1
	if _frames == 2:
		_start_title()
	elif _frames > MAX_FRAMES:
		_fail("title/S1/S2/S3 did not become ready within %d frames" % MAX_FRAMES)
	elif _game != null:
		_try_advance()


func _start_title() -> void:
	_game = root.get_node_or_null("Game")
	var i18n := root.get_node_or_null("I18n")
	if _game == null or not _game.has_method("start_battle"):
		_fail("Game autoload unavailable")
		return
	if i18n == null or not i18n.has_method("supported_locales"):
		_fail("I18n autoload unavailable")
		return
	if i18n.call("supported_locales") != PackedStringArray(["en-US"]):
		_fail("en-US locale unavailable")
		return
	var packed := load(TITLE_SCENE_PATH) as PackedScene
	if packed == null:
		_fail("title scene failed to load")
		return
	root.add_child(packed.instantiate())


func _try_advance() -> void:
	if _phase == 0:
		_try_title()
	elif _phase == 1:
		_try_s1()
	elif _phase == 2:
		_try_s2()
	else:
		_try_s3()


func _try_title() -> void:
	var content := _game.get("content") as Node
	if content == null:
		return
	for node_path: String in REQUIRED_TITLE_NODES:
		if content.find_child(node_path.get_file(), true, false) == null:
			return
	var music := root.get_node_or_null("Music")
	if music == null or not music.has_method("reload_catalog"):
		_fail("Music autoload unavailable")
		return
	if not bool(music.call("reload_catalog")):
		_fail("Music catalog failed to load")
		return
	_phase = 1
	_game.call("start_battle", &"s1")


func _try_s1() -> void:
	var grid := _expected_stage_grid(&"s1")
	if grid == null or not _grid_has(grid, REQUIRED_S1_GRID_NODES):
		return
	_phase = 2
	_game.call("start_battle", &"s2")


func _try_s2() -> void:
	var grid := _expected_stage_grid(&"s2")
	if grid == null or not _grid_has(grid, REQUIRED_S2_GRID_NODES):
		return
	var counts := _grid_counts(grid)
	if not _counts_match(
		counts, EXPECTED_S2_CHILDREN, EXPECTED_S2_TILES, EXPECTED_S2_SHADES
	):
		_fail("S2 grid count mismatch: %s" % counts)
		return
	_phase = 3
	_game.call("start_battle", &"s3")


func _try_s3() -> void:
	var grid := _expected_stage_grid(&"s3")
	if grid == null or not _grid_has(grid, REQUIRED_S3_GRID_NODES):
		return
	var counts := _grid_counts(grid)
	if not _counts_match(
		counts, EXPECTED_S3_CHILDREN, EXPECTED_S3_TILES, EXPECTED_S3_SHADES
	):
		_fail("S3 grid count mismatch: %s" % counts)
		return
	print(
		"[STALE-CLASS-REGISTRY] PASS title=ready s1=ready "
		+ "s2_children=%d s3_children=%d s2_backdrops=0 s3_backdrops=0 frames=%d"
		% [EXPECTED_S2_CHILDREN, EXPECTED_S3_CHILDREN, _frames]
	)
	quit(0)


func _grid_counts(grid: Node2D) -> Dictionary:
	var counts := {
		"children": grid.get_child_count(),
		"tiles": 0,
		"shades": 0,
		"panoramas": 0,
		"cadence": 0,
		"landmarks": 0,
		"backdrops": 0,
	}
	for child: Node in grid.get_children():
		if child.name.begins_with("Tile_"):
			counts["tiles"] += 1
		elif child.name.begins_with("Backdrop_"):
			counts["backdrops"] += 1
		elif child.name == "BackdropPanorama":
			counts["panoramas"] += 1
		elif child.name.begins_with("Cadence_"):
			counts["cadence"] += 1
		elif child.name in [&"SpawnLandmark", &"CoreLandmark"]:
			counts["landmarks"] += 1
		elif child is Polygon2D:
			counts["shades"] += 1
	return counts


func _counts_match(
	counts: Dictionary, expected_children: int, expected_tiles: int, expected_shades: int
) -> bool:
	return (
		int(counts["children"]) == expected_children
		and int(counts["tiles"]) == expected_tiles
		and int(counts["shades"]) == expected_shades
		and int(counts["panoramas"]) == 1
		and int(counts["cadence"]) == EXPECTED_CADENCE
		and int(counts["landmarks"]) == 2
		and int(counts["backdrops"]) == 0
	)


func _expected_stage_grid(stage_id: StringName) -> Node2D:
	var model := _game.get("current_battle") as RefCounted
	var content := _game.get("content") as Node
	if model == null or content == null:
		return null
	var stage := model.get("stage") as Resource
	if stage == null or stage.get("id") != stage_id:
		return null
	return content.get_node_or_null("GridRoot") as Node2D


func _grid_has(grid: Node2D, required_nodes: Array) -> bool:
	for node_path: String in required_nodes:
		if grid.get_node_or_null(node_path) == null:
			return false
	return true


func _fail(detail: String) -> void:
	push_error("[STALE-CLASS-REGISTRY] FAIL: %s" % detail)
	quit(1)
