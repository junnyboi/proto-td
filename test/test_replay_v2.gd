extends GutTest

const FIXTURE := "res://playtests/replays/v2/s1_recruits.json"
const S1 := preload("res://data/stages/s1.tres")
const CONFIG := preload("res://data/config/game.tres")
const GRUNT := preload("res://data/enemies/grunt.tres")
const REPLAY_SHA256 := "fef34b5901cdc5d6eb00cc98e101d2a8bd71516392ea760de2f529b0fb697531"
const TICKET_HASH := "a4dd3dd15efe297c1dd8bff779cd45b09cb3e62023ecffe44ae256a21612f736"
const TERMINAL_HASH := "14b6302bf57674e7"
const OUTCOME_HASH := "185140c95ce217d3bbdf8ef1df720e935f3b9c29990832c3cdacba1fbda7a189"


func test_v2_fixture_is_canonical_and_pins_three_distinct_recruit_identities() -> void:
	var replay := ReplayCodec.load_file(FIXTURE, _context())
	assert_true(replay["accepted"], str(replay.get("error_code", &"")))
	assert_eq(replay["version"], ReplayCodec.VERSION_2)
	assert_eq(replay["sha256"], REPLAY_SHA256)
	assert_eq(replay["ticket"]["ticket_hash"], TICKET_HASH)
	assert_eq(replay["squad"].size(), 3)
	assert_ne(replay["squad"][0], replay["squad"][1])
	assert_ne(replay["squad"][0], replay["squad"][2])
	assert_ne(replay["squad"][1], replay["squad"][2])
	assert_eq(
		replay["ticket"]["squad"].map(
			func(row: Dictionary) -> String: return row["operator_def_id"]
		),
		["recruit", "recruit", "recruit"],
	)
	var encoded := (
		ReplayCodec
		. encode_document_v2(
			replay["ticket"],
			replay["timeline"],
			_context(),
		)
	)
	assert_true(encoded["accepted"])
	assert_eq(encoded["text"], replay["text"])
	assert_eq(encoded["sha256"], REPLAY_SHA256)


func test_v2_decode_never_requires_live_operator_resources() -> void:
	var replay := ReplayCodec.load_file(FIXTURE, _context({}))
	assert_true(replay["accepted"], str(replay.get("error_code", &"")))
	var recruit := load("res://data/operators/recruit.tres") as OperatorDef
	var original_hp := recruit.hp
	recruit.hp = 999
	var again := ReplayCodec.load_file(FIXTURE, _context({}))
	assert_true(again["accepted"])
	assert_eq(again["ticket"], replay["ticket"])
	recruit.hp = original_hp


func test_v2_schema_and_identity_rejections_expose_no_partial_timeline() -> void:
	var replay := ReplayCodec.load_file(FIXTURE, _context())
	var source: Dictionary = (
		ReplayCodec
		. encode_document_v2(
			replay["ticket"],
			replay["timeline"],
			_context(),
		)["value"]
	)
	var cases: Array[Dictionary] = []
	var extra := source.duplicate(true)
	extra["extra"] = true
	cases.append(extra)
	var forged_ticket := source.duplicate(true)
	forged_ticket["ticket"]["squad"][0]["combat_spec"]["atk"] += 1
	cases.append(forged_ticket)
	var legacy_identity := source.duplicate(true)
	var legacy_args: Dictionary = legacy_identity["actions"][0]["args"]
	var battle_id: String = legacy_args["battle_id"]
	legacy_args.erase("battle_id")
	legacy_args["operator_id"] = battle_id
	cases.append(legacy_identity)
	var unknown_identity := source.duplicate(true)
	unknown_identity["actions"][0]["args"]["battle_id"] = "0000000000000000"
	cases.append(unknown_identity)
	var debug_action := source.duplicate(true)
	debug_action["actions"][0] = {
		"tick": 0,
		"verb": "debug_set_dp",
		"args": {"value": 50},
	}
	cases.append(debug_action)
	for invalid: Dictionary in cases:
		var decoded := ReplayCodec.decode_document(invalid, _context())
		assert_false(decoded["accepted"], str(decoded.get("error_code", &"")))
		assert_false(decoded.has("timeline"))
	assert_false(
		(
			ReplayCodec
			. encode_document_v2(
				replay["ticket"],
				[[0, &"debug_set_dp", 50]],
				_context(),
			)["accepted"]
		)
	)


func test_v2_rejects_resealed_content_and_identity_forgery() -> void:
	var replay := ReplayCodec.load_file(FIXTURE, _context())
	var forged_content: Dictionary = replay["ticket"].duplicate(true)
	forged_content["squad"][0]["combat_spec"]["atk"] = 4_000
	_reseal(forged_content)
	var content_result := ReplayCodec.encode_document_v2(
		forged_content, replay["timeline"], _context()
	)
	assert_false(content_result["accepted"])
	assert_eq(content_result["error_code"], &"untrusted_ticket_hash")
	assert_null(
		(
			BattleModel
			. create(
				S1 as StageDef,
				forged_content,
				0,
				CONFIG as GameConfig,
				{&"grunt": GRUNT as EnemyDef},
				{},
				_catalog("res://data/traps"),
				_catalog("res://data/spells"),
				[TICKET_HASH],
			)
		)
	)

	var partial_identity: Dictionary = replay["ticket"].duplicate(true)
	partial_identity["squad"][0]["hero_id"] = "0000000000000001"
	_reseal(partial_identity)
	var partial_result := ReplayCodec.encode_document_v2(
		partial_identity, replay["timeline"], _context()
	)
	assert_false(partial_result["accepted"])
	assert_eq(partial_result["error_code"], &"battle_id_mismatch")

	var resealed_identity: Dictionary = partial_identity.duplicate(true)
	resealed_identity["squad"][0]["battle_id"] = _battle_id(resealed_identity, 0)
	_reseal(resealed_identity)
	var identity_result := ReplayCodec.encode_document_v2(resealed_identity, [], _context())
	assert_false(identity_result["accepted"])
	assert_eq(identity_result["error_code"], &"untrusted_ticket_hash")


func test_v1_fixture_decoder_and_bytes_remain_immutable() -> void:
	var replay := ReplayCodec.load_file("res://playtests/replays/v1/s1.json", _context())
	assert_true(replay["accepted"], str(replay.get("error_code", &"")))
	assert_eq(replay["version"], ReplayCodec.VERSION)
	var encoded := (
		ReplayCodec
		. encode_document(
			replay["stage_id"],
			replay["squad"],
			replay["seed"],
			replay["timeline"],
			_context(),
		)
	)
	assert_true(encoded["accepted"])
	assert_eq(encoded["text"], replay["text"])


func test_model_run_matches_pinned_v2_terminal_and_outcome_hashes() -> void:
	var replay := ReplayCodec.load_file(FIXTURE, _context())
	var model := (
		BattleModel
		. create(
			S1 as StageDef,
			replay["ticket"],
			0,
			CONFIG as GameConfig,
			{&"grunt": GRUNT as EnemyDef},
			{},
			_catalog("res://data/traps"),
			_catalog("res://data/spells"),
			[TICKET_HASH],
		)
	)
	model.run_timeline(replay["timeline"], 2_400)
	assert_eq(model.result, BattleModel.Result.CLEAR)
	assert_eq(HeroIdentity.format_u64_hex(model.state_hash()), TERMINAL_HASH)
	var outcome: Dictionary = model.snapshot()["outcome"]
	assert_eq(outcome["outcome_hash"], OUTCOME_HASH)
	assert_eq(BattleOutcomeV3.normalize(outcome, replay["ticket"])["value"], outcome)


func _context(operators: Variant = null) -> Dictionary:
	return (
		ReplayCodec
		. build_context(
			_catalog("res://data/operators") if operators == null else operators,
			_catalog("res://data/traps"),
			_catalog("res://data/spells"),
			_catalog("res://data/stages"),
			CONFIG as GameConfig,
			[TICKET_HASH],
		)
	)


func _catalog(path: String) -> Dictionary:
	var result := {}
	for filename: String in DirAccess.open(path).get_files():
		var source := filename.trim_suffix(".remap")
		if source.ends_with(".tres"):
			var resource: Resource = load("%s/%s" % [path, source])
			result[resource.get("id")] = resource
	return result


func _battle_id(ticket: Dictionary, slot_index: int) -> String:
	return (
		CanonicalJson
		. sha256_hex(
			[
				ticket["campaign_uid"],
				ticket["attempt_id"],
				slot_index,
				ticket["squad"][slot_index]["hero_id"],
			]
		)
		. substr(0, 16)
	)


func _reseal(ticket: Dictionary) -> void:
	ticket.erase("ticket_hash")
	ticket["ticket_hash"] = CanonicalJson.sha256_hex(ticket)
