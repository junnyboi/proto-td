class_name ActionTrace
extends RefCounted

const SCHEMA_ID := "prototype_td_action_trace"
const VERSION := 1

var _rows: Array = []
var _observation_hashes: Array[String] = []
var _sequence := 0


func note_observation(observation_sha256: String) -> void:
	_observation_hashes.append(observation_sha256)


func record_attempt(
	tick: int,
	action: Array,
	reason: String,
	observation_sha256: String,
	accepted: bool,
	before_hash: int,
	after_hash: int,
) -> void:
	_rows.append({
		"tick": tick,
		"sequence": _sequence,
		"action": canonical_action(action),
		"reason": reason,
		"observation_sha256": observation_sha256,
		"accepted": accepted,
		"before_model_hash": _hash_text(before_hash),
		"after_model_hash": _hash_text(after_hash),
	})
	_sequence += 1


func rows() -> Array:
	return _rows.duplicate(true)


func command_count() -> int:
	return _rows.size()


func rejected_hashes_equal() -> bool:
	for row_value: Variant in _rows:
		var row := row_value as Dictionary
		if not bool(row["accepted"]) and row["before_model_hash"] != row["after_model_hash"]:
			return false
	return true


func finish(
	terminal_tick: int,
	terminal_cause: String,
	watchdog: bool,
	stop_reason: String,
) -> Dictionary:
	var accepted := 0
	for row_value: Variant in _rows:
		if bool((row_value as Dictionary)["accepted"]):
			accepted += 1
	var body := {"schema_id": SCHEMA_ID, "version": VERSION, "rows": _rows}
	return {
		"schema_id": SCHEMA_ID,
		"version": VERSION,
		"accepted_count": accepted,
		"rejected_count": _rows.size() - accepted,
		"terminal_tick": terminal_tick,
		"terminal_cause": terminal_cause,
		"observation_sequence_sha256": CanonicalJson.sha256_hex(_observation_hashes),
		"trace_sha256": CanonicalJson.sha256_hex(body),
		"command_count": _rows.size(),
		"watchdog": watchdog,
		"stop_reason": stop_reason,
		"rejected_hashes_equal": rejected_hashes_equal(),
	}


static func canonical_action(action: Array) -> Array:
	var out: Array = []
	for value: Variant in action:
		match typeof(value):
			TYPE_STRING, TYPE_STRING_NAME:
				out.append(String(value))
			TYPE_VECTOR2I:
				var cell: Vector2i = value
				out.append({"x": cell.x, "y": cell.y})
			TYPE_INT, TYPE_BOOL:
				out.append(value)
			_:
				out.append(str(value))
	return out


static func _hash_text(value: int) -> String:
	return HeroIdentity.format_u64_hex(value)
