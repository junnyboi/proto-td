extends GutTest

const MemorialSupportType := preload("res://scripts/ui/components/memorial_support.gd")
const MemorialScreenType := preload("res://scripts/ui/memorial.gd")


func test_projection_is_read_only_sorted_and_uses_committed_identity_at_death() -> void:
	var data := _fixture()
	var before: Dictionary = data.duplicate(true)
	var rows := MemorialSupportType.rows_from_data(data)
	assert_eq(data, before)
	assert_eq(rows.size(), 2)
	assert_eq(rows[0]["hero_id"], "bbbbbbbbbbbbbbbb")
	assert_eq(rows[1]["hero_id"], "aaaaaaaaaaaaaaaa")
	assert_eq(rows[1]["callsign"], "Ash")
	assert_eq(rows[1]["service_number"], 1)
	assert_eq(rows[1]["portrait_instance_id"], "portrait:aaaaaaaaaaaaaaaa")
	assert_eq(rows[1]["portrait_asset_id"], "portrait_recruit_00")
	assert_eq(rows[1]["class_id"], "defender")
	assert_eq(rows[1]["xp"], 100)
	assert_eq(
		rows[1]["deeds"],
		{
			"operations_deployed": 2,
			"deployments": 3,
			"successful_operations": 1,
			"retreats": 1,
		},
	)


func test_zero_deployment_and_exact_retry_do_not_inflate_deeds() -> void:
	var data := _fixture()
	var duplicate: Dictionary = (data["command_receipts"] as Array)[0].duplicate(true)
	(data["command_receipts"] as Array).append(duplicate)
	((data["command_receipts"] as Array)[0]["payload"]["outcome"]["rows"] as Array).append(
		_row("aaaaaaaaaaaaaaaa", 9, 9)
	)
	(data["command_receipts"] as Array).reverse()
	var rows := MemorialSupportType.rows_from_data(data)
	assert_eq(rows[0]["deeds"]["operations_deployed"], 0)
	assert_eq(rows[1]["deeds"]["operations_deployed"], 2)
	assert_eq(rows[1]["deeds"]["deployments"], 3)
	assert_eq(rows[1]["deeds"]["successful_operations"], 1)


func test_malformed_or_orphaned_rows_fail_closed() -> void:
	assert_eq(MemorialSupportType.rows_from_data({}), [])
	var data := _fixture()
	(data["heroes"] as Array).clear()
	assert_eq(MemorialSupportType.rows_from_data(data), [])


func test_missing_death_presentation_never_exposes_internal_ids() -> void:
	var screen := MemorialScreenType.new()
	var internal_ids: Array[String] = [
		"internal_stage_template",
		"internal_terminal_reason",
		"internal_class_id",
		"portrait_internal_asset",
		"internal_hero_id",
	]
	var row := {
		"hero_id": internal_ids[4],
		"portrait_asset_id": internal_ids[3],
		"class_id": internal_ids[2],
		"death": {
			"stage_id": internal_ids[0],
			"terminal_reason": internal_ids[1],
			"terminal_tick": 7,
			"attempt_id": 9,
		},
	}
	var text := String(screen.call("_death_text", row))
	assert_eq(text, "Memorial record unavailable")
	for internal_id: String in internal_ids:
		assert_false(text.contains(internal_id), internal_id)
	row["death"]["stage_id"] = "s1"
	text = String(screen.call("_death_text", row))
	assert_eq(text, "Memorial record unavailable")
	assert_false(text.contains(internal_ids[1]))
	screen.free()


func _fixture() -> Dictionary:
	var first := {
		"hero_id": "aaaaaaaaaaaaaaaa",
		"custom_callsign": "Ash",
		"name_version": 1,
		"recruitment_index": 0,
		"xp": 100,
	}
	var second := {
		"hero_id": "bbbbbbbbbbbbbbbb",
		"custom_callsign": "Brook",
		"name_version": 1,
		"recruitment_index": 1,
		"xp": 0,
	}
	return {
		"heroes": [first, second],
		"memorial":
		[
			{
				"memorial_id": "memorial:aaaaaaaaaaaaaaaa",
				"hero_id": "aaaaaaaaaaaaaaaa",
				"portrait_instance_id": "portrait:aaaaaaaaaaaaaaaa",
				"portrait_asset_id": "portrait_recruit_00",
				"class_id": "defender",
				"death":
				{
					"resolution_index": 1,
					"attempt_id": 1,
					"stage_id": "s1",
					"terminal_reason": "clear",
					"terminal_tick": 120,
				},
			},
			{
				"memorial_id": "memorial:bbbbbbbbbbbbbbbb",
				"hero_id": "bbbbbbbbbbbbbbbb",
				"portrait_instance_id": "portrait:bbbbbbbbbbbbbbbb",
				"portrait_asset_id": "portrait_recruit_01",
				"class_id": "recruit",
				"death":
				{
					"resolution_index": 2,
					"attempt_id": 2,
					"stage_id": "s1",
					"terminal_reason": "base_defeat",
					"terminal_tick": 80,
				},
			},
		],
		"command_receipts":
		[
			_resolution(
				"resolve-1",
				"clear",
				[
					_row("aaaaaaaaaaaaaaaa", 2, 0),
					_row("bbbbbbbbbbbbbbbb", 0, 0),
				]
			),
			_resolution(
				"resolve-2",
				"defeat",
				[
					_row("aaaaaaaaaaaaaaaa", 1, 1),
				]
			),
		],
	}


func _resolution(command_id: String, result: String, rows: Array) -> Dictionary:
	return {
		"command_id": command_id,
		"save_revision": 2 if command_id == "resolve-1" else 4,
		"verb": "resolve_attempt",
		"payload": {"outcome": {"result": result, "rows": rows}},
	}


func _row(hero_id: String, deployments: int, retreats: int) -> Dictionary:
	return {
		"hero_id": hero_id,
		"deployments": deployments,
		"retreats": retreats,
	}
