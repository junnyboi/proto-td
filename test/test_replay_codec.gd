extends GutTest

const REPLAY_DIR := "res://playtests/replays/v1"


func test_fixtures_match_all_current_stage_bots() -> void:
	var context := _context()
	for index: int in range(1, 9):
		var stage_id := "s%d" % index
		var replay := ReplayCodec.load_file("%s/%s.json" % [REPLAY_DIR, stage_id], context)
		assert_true(replay["accepted"], stage_id)
		var bot := _bot("bot_stage_0%d" % index)
		assert_eq(replay["stage_id"], bot.stage_id(), stage_id)
		assert_eq(replay["squad"], bot.squad(), stage_id)
		assert_eq(replay["timeline"], bot.timeline(), stage_id)
		var stage := load("res://data/stages/%s.tres" % stage_id) as StageDef
		assert_eq(stage.recovery_roster, bot.squad(), "%s recovery roster" % stage_id)
		assert_lte(stage.recovery_roster.size(), stage.squad_size, stage_id)


func test_round_trip_keeps_authored_same_tick_order() -> void:
	var context := _context()
	var timeline: Array = []
	for index: int in 24:
		timeline.append([10, &"debug_set_dp", index])
	var squad: Array[StringName] = [&"vanguard_1"]
	var encoded := ReplayCodec.encode_document(&"test_lane", squad, 42, timeline, context)
	assert_true(encoded["accepted"])
	var decoded := ReplayCodec.decode_document(encoded["value"], context)
	assert_true(decoded["accepted"])
	assert_eq(decoded["timeline"], timeline)


func test_schema_rejections_are_strict_and_partial_free() -> void:
	var context := _context()
	var source: Dictionary = _fixture("s1")
	var cases: Array[Dictionary] = []
	var future := source.duplicate(true)
	future["version"] = 2
	cases.append(future)
	var extra := source.duplicate(true)
	extra["extra"] = true
	cases.append(extra)
	var fraction := source.duplicate(true)
	fraction["actions"][0]["tick"] = 6.5
	cases.append(fraction)
	var unknown := source.duplicate(true)
	unknown["actions"][0]["verb"] = "teleport"
	cases.append(unknown)
	var bad_cell := source.duplicate(true)
	bad_cell["actions"][0]["args"]["cell"] = [3]
	cases.append(bad_cell)
	var unknown_stage := source.duplicate(true)
	unknown_stage["stage_id"] = "missing_stage"
	cases.append(unknown_stage)
	var unknown_operator := source.duplicate(true)
	unknown_operator["squad"][0] = "missing_operator"
	cases.append(unknown_operator)
	var over_capacity := source.duplicate(true)
	over_capacity["squad"].append("guard_2")
	cases.append(over_capacity)
	var duplicate_squad := source.duplicate(true)
	duplicate_squad["squad"][1] = duplicate_squad["squad"][0]
	cases.append(duplicate_squad)
	var wrong_operator_tile := source.duplicate(true)
	wrong_operator_tile["actions"][0]["args"]["cell"] = [3, 1]
	cases.append(wrong_operator_tile)
	var unknown_trap := source.duplicate(true)
	unknown_trap["actions"][0] = {
		"tick": 6,
		"verb": "place_trap",
		"args": {"trap_id": "missing_trap", "cell": [3, 2]},
	}
	cases.append(unknown_trap)
	var trap_off_path := source.duplicate(true)
	trap_off_path["actions"][0] = {
		"tick": 6,
		"verb": "place_trap",
		"args": {"trap_id": "spike_plate", "cell": [0, 0]},
	}
	cases.append(trap_off_path)
	var cell_spell_with_enemy := source.duplicate(true)
	cell_spell_with_enemy["actions"][0] = {
		"tick": 6,
		"verb": "cast",
		"args": {"spell_id": "bolt", "target": {"kind": "enemy", "enemy_id": 0}},
	}
	cases.append(cell_spell_with_enemy)
	var enemy_spell_with_cell := source.duplicate(true)
	enemy_spell_with_cell["actions"][0] = {
		"tick": 6,
		"verb": "cast",
		"args": {"spell_id": "charm", "target": {"kind": "cell", "cell": [1, 1]}},
	}
	cases.append(enemy_spell_with_cell)
	var dp_over_cap := source.duplicate(true)
	dp_over_cap["actions"][0] = {
		"tick": 6,
		"verb": "debug_set_dp",
		"args": {"value": 100},
	}
	cases.append(dp_over_cap)
	var negative_hp := source.duplicate(true)
	negative_hp["actions"][0] = {
		"tick": 6,
		"verb": "debug_set_base_hp",
		"args": {"value": -1},
	}
	cases.append(negative_hp)
	for invalid: Dictionary in cases:
		var decoded := ReplayCodec.decode_document(invalid, context)
		assert_false(decoded["accepted"], str(decoded.get("error_code", &"")))
		assert_false(decoded.has("timeline"), "rejection exposes no partial timeline")


func test_file_loader_rejects_noncanonical_bytes() -> void:
	var source_path := "%s/s1.json" % REPLAY_DIR
	var source_file := FileAccess.open(source_path, FileAccess.READ)
	assert_not_null(source_file)
	var source := source_file.get_as_text()
	source_file.close()
	var path := "user://p16_noncanonical_replay.json"
	var output := FileAccess.open(path, FileAccess.WRITE)
	assert_not_null(output)
	output.store_string(source.trim_suffix("\n") + " \n")
	output.close()
	var rejected := ReplayCodec.load_file(path, _context())
	assert_false(rejected["accepted"])
	assert_eq(DirAccess.remove_absolute(ProjectSettings.globalize_path(path)), OK)


func test_file_seed_integer_lexemes_are_exact_signed_i64() -> void:
	var context := _context()
	var source := ReplayCodec.load_file("%s/s1.json" % REPLAY_DIR, context)
	for seed_value: int in [9_007_199_254_740_991, 9_007_199_254_740_992,
		9_007_199_254_740_993, 9_223_372_036_854_775_807, -9_223_372_036_854_775_808]:
		var encoded := ReplayCodec.encode_document(
			source["stage_id"], source["squad"], seed_value, source["timeline"], context,
		)
		assert_true(encoded["accepted"], str(seed_value))
		var path := "user://p16_replay_seed_%s.json" % seed_value
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_string(encoded["text"])
		file.close()
		var decoded := ReplayCodec.load_file(path, context)
		assert_true(decoded["accepted"], str(seed_value))
		assert_eq(decoded["seed"], seed_value, str(seed_value))
		assert_eq(DirAccess.remove_absolute(ProjectSettings.globalize_path(path)), OK)


func _bot(bot_name: String) -> StageBot:
	return (load("res://playtests/bots/%s.gd" % bot_name) as GDScript).new()


func _fixture(stage_id: String) -> Dictionary:
	var context := _context()
	var loaded := ReplayCodec.load_file("%s/%s.json" % [REPLAY_DIR, stage_id], context)
	assert_true(loaded["accepted"])
	return ReplayCodec.encode_document(
		loaded["stage_id"], loaded["squad"], loaded["seed"], loaded["timeline"], context,
	)["value"]


func _context() -> Dictionary:
	return ReplayCodec.build_context(
		_catalog("res://data/operators"),
		_catalog("res://data/traps"),
		_catalog("res://data/spells"),
		_catalog("res://data/stages"),
		load("res://data/config/game.tres") as GameConfig,
	)


func _catalog(path: String) -> Dictionary:
	var result := {}
	for filename: String in DirAccess.open(path).get_files():
		var source := filename.trim_suffix(".remap")
		if source.ends_with(".tres"):
			var resource: Resource = load("%s/%s" % [path, source])
			result[resource.get("id")] = resource
	return result
