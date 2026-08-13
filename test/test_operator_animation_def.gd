extends GutTest


func test_admitted_catalog_and_manifest_contracts_are_exact() -> void:
	Art._reset_manifests_for_test()
	assert_true(OperatorVisualCatalog.validate_all().is_empty())
	assert_eq(
		OperatorVisualCatalog.template_ids(),
		[&"defender_1", &"vanguard_2"],
	)
	for template_id: StringName in OperatorVisualCatalog.template_ids():
		var animation := OperatorVisualCatalog.get_animation(template_id)
		assert_not_null(animation)
		assert_true(animation.validate_contract().is_empty(), String(template_id))
		assert_false(animation.placeholder)
		for direction: StringName in OperatorAnimationDef.DIRECTIONS:
			var idle_id := StringName(animation.idle_by_direction[direction])
			var attack_id := StringName(animation.attack_by_direction[direction])
			assert_eq(Art.frame_count(idle_id), 24)
			assert_eq(Art.frame_count(attack_id), 13)
			assert_eq(Art.size(idle_id), Vector2i(192, 192))
			assert_eq(Art.size(attack_id), Vector2i(192, 192))
			assert_almost_eq(Art.fps(idle_id), 12.0, 0.0001)
			assert_almost_eq(Art.fps(attack_id), 12.0, 0.0001)


func test_resource_rejects_missing_unknown_and_duplicate_directions() -> void:
	var value := _valid_def()
	value.idle_by_direction.erase(&"sw")
	value.idle_by_direction[&"south"] = &"bad"
	value.attack_by_direction[&"nw"] = value.attack_by_direction[&"ne"]
	var errors := value.validate_contract()
	assert_true(_contains(errors, "idle_by_direction: missing sw"))
	assert_true(_contains(errors, "idle_by_direction: unknown direction south"))
	assert_true(_contains(errors, "attack_by_direction: duplicate logical id"))


func test_resource_rejects_schema_timing_and_provenance_corruption() -> void:
	var value := _valid_def()
	value.schema_version = 2
	value.idle_frame_count = 25
	value.attack_frame_count = 12
	value.fps = 8.0
	value.provenance_sha256 = "not-a-digest"
	var errors := value.validate_contract()
	assert_true(_contains(errors, "schema_version"))
	assert_true(_contains(errors, "idle_frame_count"))
	assert_true(_contains(errors, "attack_frame_count"))
	assert_true(_contains(errors, "fps"))
	assert_true(_contains(errors, "provenance_sha256"))


func test_catalog_rejects_duplicate_visual_ids() -> void:
	var first := _valid_def()
	var second := _valid_def()
	var errors := OperatorVisualCatalog.validate_definitions(
		{&"first": first, &"second": second}, false
	)
	assert_true(_contains(errors, "duplicate visual_id"))


func _valid_def() -> OperatorAnimationDef:
	var value := OperatorAnimationDef.new()
	value.visual_id = &"test_visual"
	value.provenance_sha256 = "a".repeat(64)
	value.placeholder = false
	for direction: StringName in OperatorAnimationDef.DIRECTIONS:
		value.idle_by_direction[direction] = StringName("idle_%s" % direction)
		value.attack_by_direction[direction] = StringName("attack_%s" % direction)
	return value


func _contains(errors: PackedStringArray, needle: String) -> bool:
	for message: String in errors:
		if message.contains(needle):
			return true
	return false
