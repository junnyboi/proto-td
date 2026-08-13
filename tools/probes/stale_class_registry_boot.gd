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
]
const EXPECTED_S2_TILES := 50
const EXPECTED_S2_BACKDROPS := 700

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
		_fail("title/S1/S2 did not become ready within %d frames" % MAX_FRAMES)
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
	else:
		_try_s2()


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
	var tile_count := 0
	var backdrop_count := 0
	for child: Node in grid.get_children():
		if child.name.begins_with("Tile_"):
			tile_count += 1
		elif child.name.begins_with("Backdrop_"):
			backdrop_count += 1
	if tile_count != EXPECTED_S2_TILES or backdrop_count != EXPECTED_S2_BACKDROPS:
		_fail(
			"S2 grid count mismatch: tiles=%d backdrops=%d" % [tile_count, backdrop_count]
		)
		return
	if grid.get_node_or_null("BackdropPanorama") != null:
		_fail("S2 unexpectedly inherited the S1 panorama")
		return
	print(
		"[STALE-CLASS-REGISTRY] PASS title=ready s1=ready "
		+ "s2_tiles=%d s2_backdrops=%d frames=%d"
		% [tile_count, backdrop_count, _frames]
	)
	quit(0)


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
