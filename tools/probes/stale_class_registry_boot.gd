extends SceneTree

## Runtime half of the stale-class-registry upgrade probe. This script avoids
## project class_name types deliberately: it must remain loadable from an old
## .godot/global_script_class_cache.cfg while exercising the newly pulled game.
enum Phase {
	TITLE,
	STAGING,
	S1_SQUAD,
	S1_RESULTS,
	S1_GRID,
	S2_GRID,
	S3_GRID,
}

const MAX_PHASE_FRAMES := 180
const TITLE_SCENE_PATH := "res://scenes/title.tscn"
const NARRATIVE_CATALOG_PATH := "res://data/presentation/narrative/stage_narrative_catalog.tres"
const S1_RECORD_PATH := "res://data/presentation/narrative/stages/s1.tres"
const S1_OBJECTIVE := (
	"Hold the Hearthcross water-works line while investigators trace "
	+ "the evacuation order carried by the attackers."
)
const S1_THREAT := "Road-clearing Grunts treat people and barricades as blockages."
const S1_HUMAN_REASON := "The town's pumps feed homes, shelters, and fields."
const S1_CLUE := (
	"Every attacking machine carries a two-hundred-year-old Great Flare " + "evacuation mark."
)
const S1_CLEAR_DEBRIEF := (
	"Holding the line gives investigators time to recover a damaged evacuation seal. "
	+ "The pumps stay in service, and Company 33 confirms that the old order never ended."
)
const S1_DEFEAT_DEBRIEF := (
	"Company 33 evacuates the exposed water works. People survive, but Hearthcross "
	+ "loses service capacity before the order can be traced."
)
const REQUIRED_TITLE_NODES := [
	"TitleShell",
	"TitleLabel",
	"StartButton",
	"LocaleList",
]
const REQUIRED_STAGING_NODES := [
	"StagingShell",
	"StagingScroll",
	"CompanyCommandHeading",
	"CompanyCommandBody",
	"NextOperationTitle",
	"NextOperationObjective",
	"MissionControlButton",
]
const REQUIRED_S1_SQUAD_NODES := [
	"SquadColumn",
	"SquadScroll",
	"BriefingObjective",
	"BriefingThreat",
	"BriefingHumanReason",
	"BriefingClue",
	"TacticalHint",
	"StartBattle",
]
const REQUIRED_S1_RESULTS_NODES := [
	"ResultsColumn",
	"ResultsScroll",
	"ConsequenceHeading",
	"ConsequenceLine",
	"RetryButton",
	"ReturnToStaging",
	"BackToTitle",
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
]
const S1_RECORD_COPY := {
	"objective": S1_OBJECTIVE,
	"threat": S1_THREAT,
	"human_reason": S1_HUMAN_REASON,
	"clue": S1_CLUE,
	"core_service": "Hearthcross water Core",
	"clear_debrief": S1_CLEAR_DEBRIEF,
	"defeat_debrief": S1_DEFEAT_DEBRIEF,
}
const S1_UI_COPY := {
	"BriefingObjective": "Objective — %s" % S1_OBJECTIVE,
	"BriefingThreat": "Threat — %s" % S1_THREAT,
	"BriefingHumanReason": "Why it matters — %s" % S1_HUMAN_REASON,
	"BriefingClue": "Field note — %s" % S1_CLUE,
	"ConsequenceLine": S1_CLEAR_DEBRIEF,
}
const EXPECTED_S2_CHILDREN := 59
const EXPECTED_S2_TILES := 50
const EXPECTED_S2_SHADES := 2
const EXPECTED_S3_CHILDREN := 68
const EXPECTED_S3_TILES := 60
const EXPECTED_S3_SHADES := 1
const EXPECTED_CADENCE := 0
const EXPECTED_ENV_PROPS := 4

var _frames := 0
var _phase := Phase.TITLE
var _phase_started := 0
var _game: Node = null
var _catalog: Resource = null
var _s1_record: Resource = null


func _initialize() -> void:
	process_frame.connect(_on_process_frame)


func _on_process_frame() -> void:
	_frames += 1
	if _frames == 2:
		_start_title()
	elif _frames - _phase_started > MAX_PHASE_FRAMES:
		_fail("phase %s did not become ready within %d frames" % [_phase_name(), MAX_PHASE_FRAMES])
	elif _game != null:
		_try_advance()


func _start_title() -> void:
	_game = root.get_node_or_null("Game")
	var i18n := root.get_node_or_null("I18n")
	if (
		_game == null
		or not _game.has_method("start_campaign")
		or not _game.has_method("start_battle")
	):
		_fail("Game autoload unavailable")
		return
	if i18n == null or not i18n.has_method("supported_locales"):
		_fail("I18n autoload unavailable")
		return
	if i18n.call("supported_locales") != PackedStringArray(["en-US"]):
		_fail("en-US locale unavailable")
		return
	_catalog = load(NARRATIVE_CATALOG_PATH) as Resource
	_s1_record = load(S1_RECORD_PATH) as Resource
	if not _assert_s1_record_identity():
		return
	var packed := load(TITLE_SCENE_PATH) as PackedScene
	if packed == null:
		_fail("title scene failed to load")
		return
	root.add_child(packed.instantiate())
	_phase_started = _frames


func _try_advance() -> void:
	match _phase:
		Phase.TITLE:
			_try_title()
		Phase.STAGING:
			_try_staging()
		Phase.S1_SQUAD:
			_try_s1_squad()
		Phase.S1_RESULTS:
			_try_s1_results()
		Phase.S1_GRID:
			_try_s1_grid()
		Phase.S2_GRID:
			_try_s2_grid()
		Phase.S3_GRID:
			_try_s3_grid()


func _try_title() -> void:
	var content := _content_with_nodes(REQUIRED_TITLE_NODES)
	if content == null:
		return
	var music := root.get_node_or_null("Music")
	if music == null or not music.has_method("reload_catalog"):
		_fail("Music autoload unavailable")
		return
	if not bool(music.call("reload_catalog")):
		_fail("Music catalog failed to load")
		return
	_set_phase(Phase.STAGING)
	_game.call("start_campaign")


func _try_staging() -> void:
	var content := _content_with_nodes(REQUIRED_STAGING_NODES)
	if content == null:
		return
	if not _assert_text(content, "CompanyCommandHeading", "COMPANY 33 COMMAND"):
		return
	if not _assert_text(content, "NextOperationTitle", "NEXT 1: First Stand"):
		return
	if not _assert_text(content, "NextOperationObjective", S1_OBJECTIVE):
		return
	_set_phase(Phase.S1_SQUAD)
	_game.set("selected_stage_id", &"s1")
	_game.call("open_squad_select")


func _try_s1_squad() -> void:
	var content := _content_with_nodes(REQUIRED_S1_SQUAD_NODES)
	if content == null:
		return
	for node_name: String in [
		"BriefingObjective",
		"BriefingThreat",
		"BriefingHumanReason",
		"BriefingClue",
	]:
		if not _assert_text(content, node_name, String(S1_UI_COPY[node_name])):
			return
	_set_phase(Phase.S1_RESULTS)
	(
		_game
		. set(
			"last_result",
			{
				"stage_id": &"s1",
				"result": 1,
				"stars": 3,
				"leaks": 0,
				"kills": 12,
				"rewards_granted": [],
			}
		)
	)
	_game.call("open_results")


func _try_s1_results() -> void:
	var content := _content_with_nodes(REQUIRED_S1_RESULTS_NODES)
	if content == null:
		return
	if not _assert_text(content, "ConsequenceHeading", "Consequence"):
		return
	if not _assert_text(content, "ConsequenceLine", S1_CLEAR_DEBRIEF):
		return
	_set_phase(Phase.S1_GRID)
	_game.call("start_battle", &"s1")


func _try_s1_grid() -> void:
	var grid := _expected_stage_grid(&"s1")
	if grid == null or not _grid_has(grid, REQUIRED_S1_GRID_NODES):
		return
	_set_phase(Phase.S2_GRID)
	_game.call("start_battle", &"s2")


func _try_s2_grid() -> void:
	var grid := _expected_stage_grid(&"s2")
	if grid == null or not _grid_has(grid, REQUIRED_S2_GRID_NODES):
		return
	var counts := _grid_counts(grid)
	if not _counts_match(counts, EXPECTED_S2_CHILDREN, EXPECTED_S2_TILES, EXPECTED_S2_SHADES):
		_fail("S2 grid count mismatch: %s" % counts)
		return
	_set_phase(Phase.S3_GRID)
	_game.call("start_battle", &"s3")


func _try_s3_grid() -> void:
	var grid := _expected_stage_grid(&"s3")
	if grid == null or not _grid_has(grid, REQUIRED_S3_GRID_NODES):
		return
	var counts := _grid_counts(grid)
	if not _counts_match(counts, EXPECTED_S3_CHILDREN, EXPECTED_S3_TILES, EXPECTED_S3_SHADES):
		_fail("S3 grid count mismatch: %s" % counts)
		return
	print(
		(
			"[STALE-CLASS-REGISTRY] PASS title=ready staging=ready "
			+ "s1_squad=ready s1_results=ready s1=ready "
			+ (
				"s2_children=%d s3_children=%d s2_backdrops=0 s3_backdrops=0 frames=%d"
				% [EXPECTED_S2_CHILDREN, EXPECTED_S3_CHILDREN, _frames]
			)
		)
	)
	quit(0)


func _assert_s1_record_identity() -> bool:
	if (
		_catalog == null
		or not _catalog.has_method("validate_contract")
		or not _catalog.has_method("get_record")
	):
		_fail("narrative catalog methods unavailable")
		return false
	var errors: Variant = _catalog.call("validate_contract")
	if not errors.is_empty():
		_fail("narrative catalog invalid: %s" % [errors])
		return false
	var catalog_record := _catalog.call("get_record", &"s1") as Resource
	if not _validate_s1_resource(catalog_record):
		return false
	return _validate_s1_copy(catalog_record)


func _validate_s1_resource(catalog_record: Resource) -> bool:
	if catalog_record == null or _s1_record == null:
		_fail("S1 narrative record unavailable")
		return false
	if catalog_record != _s1_record:
		_fail("S1 narrative catalog record identity mismatch")
		return false
	if catalog_record.get("id") != &"s1":
		_fail("S1 narrative record id mismatch")
		return false
	if not catalog_record.has_method("validate_contract"):
		_fail("S1 narrative record methods unavailable")
		return false
	var record_errors: Variant = catalog_record.call("validate_contract")
	if not record_errors.is_empty():
		_fail("S1 narrative record invalid: %s" % [record_errors])
		return false
	return true


func _validate_s1_copy(catalog_record: Resource) -> bool:
	var i18n := root.get_node_or_null("I18n")
	if i18n == null or not i18n.has_method("t"):
		_fail("I18n localized-copy method unavailable")
		return false
	for property_name: String in S1_RECORD_COPY:
		var expected := String(S1_RECORD_COPY[property_name])
		if String(catalog_record.get(property_name)) != expected:
			_fail("S1 narrative %s copy mismatch" % property_name)
			return false
		var key := StringName("data.stage.s1.narrative.%s" % property_name)
		if String(i18n.call("t", key, "deliberately-wrong-fallback")) != expected:
			_fail("S1 localized narrative %s copy mismatch" % property_name)
			return false
	return true


func _content_with_nodes(required_nodes: Array) -> Node:
	var content := _game.get("content") as Node
	if content == null or not is_instance_valid(content):
		return null
	for node_name: String in required_nodes:
		if content.find_child(node_name, true, false) == null:
			return null
	return content


func _assert_text(content: Node, node_name: String, expected: String) -> bool:
	var node := content.find_child(node_name, true, false) as Node
	if node == null:
		_fail("required narrative node missing: %s" % node_name)
		return false
	if String(node.get("text")) != expected:
		_fail(
			(
				"%s copy mismatch: expected=%s actual=%s"
				% [node_name, expected, String(node.get("text"))]
			)
		)
		return false
	return true


func _grid_counts(grid: Node2D) -> Dictionary:
	var counts := {
		"children": grid.get_child_count(),
		"tiles": 0,
		"shades": 0,
		"panoramas": 0,
		"cadence": 0,
		"env_props": 0,
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
		elif child.name.begins_with("EnvProp_"):
			counts["env_props"] += 1
		elif child.name in [&"SpawnLandmark", &"CoreLandmark"]:
			counts["landmarks"] += 1
		elif child is Polygon2D:
			counts["shades"] += 1
	return counts


func _counts_match(
	counts: Dictionary,
	expected_children: int,
	expected_tiles: int,
	expected_shades: int,
) -> bool:
	return (
		int(counts["children"]) == expected_children
		and int(counts["tiles"]) == expected_tiles
		and int(counts["shades"]) == expected_shades
		and int(counts["panoramas"]) == 1
		and int(counts["cadence"]) == EXPECTED_CADENCE
		and int(counts["env_props"]) == EXPECTED_ENV_PROPS
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


func _set_phase(next_phase: Phase) -> void:
	_phase = next_phase
	_phase_started = _frames


func _phase_name() -> String:
	return Phase.keys()[_phase]


func _fail(detail: String) -> void:
	push_error("[STALE-CLASS-REGISTRY] FAIL: %s" % detail)
	quit(1)
