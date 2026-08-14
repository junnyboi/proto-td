extends GutTest


func _model() -> BattleModel:
	var stage := StageDef.new()
	stage.id = &"trace_test"
	stage.grid_rows = PackedStringArray(["SGB"])
	stage.paths = [PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(2, 0)])]
	stage.waves = []
	stage.wave_starts = PackedInt32Array([0])
	var config := load("res://data/config/game.tres") as GameConfig
	var vanguard := load("res://data/operators/vanguard_1.tres") as OperatorDef
	var squad: Array[StringName] = [&"vanguard_1"]
	return BattleModel.create(
		stage, squad, 42, config, {}, {&"vanguard_1": vanguard}
	)


func test_accept_reject_hash_equality_and_summary() -> void:
	var model := _model()
	var trace := ActionTrace.new()
	var observation := BattleObservation.from_model(model)
	trace.note_observation(observation.sha256())
	var accepted_action := [&"deploy", &"vanguard_1", Vector2i(1, 0), 0]
	var before := model.state_hash()
	var accepted := model.apply_action(accepted_action)
	var after := model.state_hash()
	trace.record_attempt(
		model.tick, accepted_action, "deploy", observation.sha256(), accepted, before, after
	)
	var rejected_action := [&"deploy", &"vanguard_1", Vector2i(1, 0), 0]
	before = model.state_hash()
	accepted = model.apply_action(rejected_action)
	after = model.state_hash()
	trace.record_attempt(
		model.tick, rejected_action, "duplicate", observation.sha256(), accepted, before, after
	)
	var rows := trace.rows()
	assert_true(rows[0]["accepted"])
	assert_false(rows[1]["accepted"])
	assert_eq(rows[1]["before_model_hash"], rows[1]["after_model_hash"])
	assert_eq(rows[0]["action"][2], {"x": 1, "y": 0})
	var summary := trace.finish(0, "", false, "command_ceiling")
	assert_eq(summary["accepted_count"], 1)
	assert_eq(summary["rejected_count"], 1)
	assert_eq(summary["command_count"], 2)
	assert_true(summary["rejected_hashes_equal"])
	assert_eq(String(summary["trace_sha256"]).length(), 64)
	assert_eq(String(summary["observation_sequence_sha256"]).length(), 64)


func test_signed_hash_bits_are_exact_lowercase_unsigned_hex() -> void:
	var trace := ActionTrace.new()
	trace.record_attempt(0, [&"resign"], "negative_bits", "obs", false, -1, -2)
	var row: Dictionary = trace.rows()[0]
	assert_eq(row["before_model_hash"], "ffffffffffffffff")
	assert_eq(row["after_model_hash"], "fffffffffffffffe")
	assert_eq(String(row["before_model_hash"]).length(), 16)
	assert_true(String(row["before_model_hash"]).is_valid_hex_number(false))
