class_name StageNarrativeCatalog
extends Resource

const StageNarrativeDefType := preload("res://data/presentation/narrative/stage_narrative_def.gd")
const EXPECTED_IDS: Array[StringName] = [&"s1", &"s2", &"s3", &"s4", &"s5", &"s6", &"s7", &"s8"]

@export var records: Array[StageNarrativeDefType] = []


func validate_contract() -> PackedStringArray:
	var errors := PackedStringArray()
	if records.size() != EXPECTED_IDS.size():
		errors.append("records: expected 8, got %d" % records.size())
	var seen: Dictionary = {}
	for index: int in records.size():
		var record: StageNarrativeDefType = records[index]
		if record == null:
			errors.append("records[%d]: null" % index)
			continue
		var record_id := String(record.id)
		if seen.has(record.id):
			errors.append("records[%d]: duplicate id %s" % [index, record_id])
		else:
			seen[record.id] = true
		if index < EXPECTED_IDS.size() and record.id != EXPECTED_IDS[index]:
			errors.append(
				"records[%d]: slot id %s, expected %s" % [index, record_id, EXPECTED_IDS[index]]
			)
		for detail: String in record.validate_contract():
			errors.append("records[%d].%s" % [index, detail])
	for expected_id: StringName in EXPECTED_IDS:
		if not seen.has(expected_id):
			errors.append("records: missing id %s" % expected_id)
	return errors


func get_record(stage_id: StringName) -> StageNarrativeDefType:
	var errors := validate_contract()
	if not errors.is_empty():
		push_error("StageNarrativeCatalog.get_record: invalid catalog: %s" % "; ".join(errors))
		return null
	if not EXPECTED_IDS.has(stage_id):
		push_error("StageNarrativeCatalog.get_record: unknown stage id %s" % stage_id)
		return null
	for record: StageNarrativeDefType in records:
		if record.id == stage_id:
			return record
	push_error("StageNarrativeCatalog.get_record: missing stage id %s" % stage_id)
	return null
