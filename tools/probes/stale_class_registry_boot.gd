extends SceneTree

## Runtime half of the stale-class-registry upgrade probe. This script avoids
## project class_name types deliberately: it must remain loadable from an old
## .godot/global_script_class_cache.cfg while exercising the newly pulled game.
const MAX_PHASE_FRAMES := 180
const TITLE_SCENE_PATH := "res://scenes/title.tscn"
const NARRATIVE_CATALOG_PATH := "res://data/presentation/narrative/stage_narrative_catalog.tres"
const S1_RECORD_PATH := "res://data/presentation/narrative/stages/s1.tres"
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
]
const S1_RECORD_COPY := {
	"objective": "Hold the Hearthcross water-works line while investigators trace the evacuation order carried by the attackers.",
	"threat": "Road-clearing Grunts treat people and barricades as blockages.",
	"human_reason": "The town's pumps feed homes, shelters, and fields.",
	"clue": "Every attacking machine carries a two-hundred-year-old Great Flare evacuation mark.",
	"core_service": "Hearthcross water Core",
	"clear_debrief": "Holding the line gives investigators time to recover a damaged evacuation seal. The pumps stay in service, and Company 33 confirms that the old order never ended.",
	"defeat_debrief": "Company 33 evacuates the exposed water works. People survive, but Hearthcross loses service capacity before the order can be traced.",
}
const S1_UI_COPY := {
	"BriefingObjective": "Objective — Hold the Hearthcross water-works line while investigators trace the evacuation order carried by the attackers.",
	"BriefingThreat": "Threat — Road-clearing Grunts treat people and barricades as blockages.",
	"BriefingHumanReason": "Why it matters — The town's pumps feed homes, shelters, and fields.",
	"BriefingClue": "Field note — Every attacking machine carries a two-hundred-year-old Great Flare evacuation mark.",
	"ConsequenceLine": "Holding the line gives investigators time to recover a damaged evacuation seal. The pumps stay in service, and Company 33 confirms that the old order never ended.",
}
const EXPECTED_S2_TILES := 50
const EXPECTED_S2_BACKDROPS := 700

enum Phase {
	TITLE,
	STAGING,
	S1_SQUAD,
	S1_RESULTS,
	S1_GRID,
	S2_GRID,
}

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
	if _game == null or not _game.has_method("start_campaign") or not _game.has_method("start_battle"):
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
	if not _assert_text(
		content,
		"NextOperationObjective",
		String(S1_RECORD_COPY["objective"]),
	):
		return
	_set_phase(Phase.S1_SQUAD)
	_game.set("selected_stage_id", &"s1")
	_game.call("open_squad_select")


func _try_s1_squad() -> void:
	var content := _content_with_nodes(REQUIRED_S1_SQUAD_NODES)
	if content == null:
		return
	for node_name: String in [
		"BriefingObjective", "BriefingThreat", "BriefingHumanReason", "BriefingClue",
	]:
		if not _assert_text(content, node_name, String(S1_UI_COPY[node_name])):
			return
	_set_phase(Phase.S1_RESULTS)
	_game.set("last_result", {
		"stage_id": &"s1",
		"result": 1,
		"stars": 3,
		"leaks": 0,
		"kills": 12,
		"rewards_granted": [],
	})
	_game.call("open_results")


func _try_s1_results() -> void:
	var content := _content_with_nodes(REQUIRED_S1_RESULTS_NODES)
	if content == null:
		return
	if not _assert_text(content, "ConsequenceHeading", "Consequence"):
		return
	if not _assert_text(content, "ConsequenceLine", String(S1_UI_COPY["ConsequenceLine"])):
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
		"[STALE-CLASS-REGISTRY] PASS title=ready staging=ready "
		+ "s1_squad=ready s1_results=ready s1=ready "
		+ "s2_tiles=%d s2_backdrops=%d frames=%d"
		% [tile_count, backdrop_count, _frames]
	)
	quit(0)


func _assert_s1_record_identity() -> bool:
	if _catalog == null or not _catalog.has_method("validate_contract") or not _catalog.has_method("get_record"):
		_fail("narrative catalog methods unavailable")
		return false
	var errors: Variant = _catalog.call("validate_contract")
	if not errors.is_empty():
		_fail("narrative catalog invalid: %s" % [errors])
		return false
	var catalog_record := _catalog.call("get_record", &"s1") as Resource
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
			"%s copy mismatch: expected=%s actual=%s"
			% [node_name, expected, String(node.get("text"))]
		)
		return false
	return true


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
