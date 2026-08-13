extends GutTest

const StageNarrativeDefType := preload("res://data/presentation/narrative/stage_narrative_def.gd")
const StageNarrativeCatalogType := preload("res://data/presentation/narrative/stage_narrative_catalog.gd")
const CATALOG := preload("res://data/presentation/narrative/stage_narrative_catalog.tres")
const EXPECTED_IDS: Array[StringName] = [&"s1", &"s2", &"s3", &"s4", &"s5", &"s6", &"s7", &"s8"]


func test_catalog_has_exact_ordered_eight_records_and_seven_nonblank_fields() -> void:
	assert_eq(CATALOG.validate_contract(), PackedStringArray())
	assert_eq(CATALOG.records.size(), 8)
	var ids: Array[StringName] = []
	for record: StageNarrativeDefType in CATALOG.records:
		ids.append(record.id)
		assert_eq(record.validate_contract(), PackedStringArray(), String(record.id))
		for field: StageNarrativeDefType.Field in _fields():
			assert_false(record.fallback_for(field).strip_edges().is_empty())
	assert_eq(ids, EXPECTED_IDS)


func test_lookup_is_exact_and_unknown_fails_closed() -> void:
	for stage_id: StringName in EXPECTED_IDS:
		assert_eq(CATALOG.get_record(stage_id).id, stage_id)
	assert_null(CATALOG.get_record(&"s9"))
	assert_push_error("StageNarrativeCatalog.get_record: unknown stage id s9")


func test_definition_validation_order_and_invalid_enum_fail_closed() -> void:
	var record := StageNarrativeDefType.new()
	assert_eq(record.validate_contract(), PackedStringArray([
		"id: blank", "objective: blank", "threat: blank", "human_reason: blank",
		"clue: blank", "core_service: blank", "clear_debrief: blank", "defeat_debrief: blank",
	]))
	assert_eq(record.fallback_for(99 as StageNarrativeDefType.Field), "")
	assert_push_error("StageNarrativeDef.fallback_for: invalid field 99")
	assert_eq(record.field_slug(99 as StageNarrativeDefType.Field), &"")
	assert_push_error("StageNarrativeDef.field_slug: invalid field 99")


func test_catalog_rejects_null_duplicate_mismatch_blank_and_wrong_count() -> void:
	var catalog := StageNarrativeCatalogType.new()
	assert_eq(catalog.validate_contract(), PackedStringArray(["records: expected 8, got 0", "records: missing id s1", "records: missing id s2", "records: missing id s3", "records: missing id s4", "records: missing id s5", "records: missing id s6", "records: missing id s7", "records: missing id s8"]))
	catalog.records = CATALOG.records.duplicate()
	catalog.records[1] = catalog.records[0]
	var errors := catalog.validate_contract()
	assert_true(errors.has("records[1]: duplicate id s1"))
	assert_true(errors.has("records[1]: slot id s1, expected s2"))
	assert_true(errors.has("records: missing id s2"))
	catalog.records = CATALOG.records.duplicate()
	catalog.records[3] = null
	assert_true(catalog.validate_contract().has("records[3]: null"))
	assert_null(catalog.get_record(&"s1"))
	assert_push_error("StageNarrativeCatalog.get_record: invalid catalog: records[3]: null; records: missing id s4")


func test_derived_key_generation_and_locale_fallback_parity() -> void:
	var parsed := JSON.parse_string(FileAccess.get_file_as_string("res://localization/en-US.json")) as Dictionary
	var entries := parsed["entries"] as Dictionary
	for record: StageNarrativeDefType in CATALOG.records:
		for field: StageNarrativeDefType.Field in _fields():
			var key := "data.stage.%s.narrative.%s" % [record.id, record.field_slug(field)]
			assert_eq(entries[key], record.fallback_for(field), key)


func _fields() -> Array[StageNarrativeDefType.Field]:
	return [
		StageNarrativeDefType.Field.OBJECTIVE, StageNarrativeDefType.Field.THREAT,
		StageNarrativeDefType.Field.HUMAN_REASON, StageNarrativeDefType.Field.CLUE,
		StageNarrativeDefType.Field.CORE_SERVICE, StageNarrativeDefType.Field.CLEAR_DEBRIEF,
		StageNarrativeDefType.Field.DEFEAT_DEBRIEF,
	]
