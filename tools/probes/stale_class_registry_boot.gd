extends SceneTree

## Runtime half of the stale-class-registry upgrade probe. This script avoids
## project class_name types deliberately: it must remain loadable from an old
## .godot/global_script_class_cache.cfg while exercising the newly pulled game.

const MAX_FRAMES := 240
const REQUIRED_GRID_NODES := [
	"Tile_0_2",
	"Tile_1_1",
	"Tile_3_1",
	"Tile_7_2",
	"BackdropPanorama",
	"SpawnLandmark",
	"CoreLandmark",
]

var _frames := 0
var _game: Node = null


func _initialize() -> void:
	process_frame.connect(_on_process_frame)


func _on_process_frame() -> void:
	_frames += 1
	if _frames == 2:
		_start_s1()
	elif _frames > MAX_FRAMES:
		_fail("S1 map did not become ready within %d frames" % MAX_FRAMES)
	elif _game != null:
		_try_finish()


func _start_s1() -> void:
	_game = root.get_node_or_null("Game")
	if _game == null or not _game.has_method("start_battle"):
		_fail("Game autoload unavailable")
		return
	_game.call("start_battle", &"s1")


func _try_finish() -> void:
	var content := _game.get("content") as Node
	if content == null:
		return
	var grid := content.get_node_or_null("GridRoot") as Node2D
	if grid == null or not _grid_ready(grid):
		return
	var music := root.get_node_or_null("Music")
	if music == null or not music.has_method("reload_catalog"):
		_fail("Music autoload unavailable")
		return
	if not bool(music.call("reload_catalog")):
		_fail("Music catalog failed to load")
		return
	print(
		"[STALE-CLASS-REGISTRY] PASS frames=%d grid_children=%d" % [_frames, grid.get_child_count()]
	)
	quit(0)


func _grid_ready(grid: Node2D) -> bool:
	for node_path: String in REQUIRED_GRID_NODES:
		if grid.get_node_or_null(node_path) == null:
			return false
	return true


func _fail(detail: String) -> void:
	push_error("[STALE-CLASS-REGISTRY] FAIL: %s" % detail)
	quit(1)
