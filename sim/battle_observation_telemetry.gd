class_name BattleObservationTelemetry
extends RefCounted

## External running aggregates only: no model reference and no per-tick arrays.

var _lanes: Dictionary = {}
var _samples := 0


func consume(observation: BattleObservation) -> void:
	consume_dictionary(observation.to_dictionary())


func consume_dictionary(observation: Dictionary) -> void:
	for lane_value: Variant in observation.get("paths", []):
		var lane := lane_value as Dictionary
		var key := str(int(lane["path_idx"]))
		if not _lanes.has(key):
			_lanes[key] = _empty_lane(int(lane["path_idx"]))
		var aggregate: Dictionary = _lanes[key]
		aggregate["peak_pressure"] = maxi(
			int(aggregate["peak_pressure"]), int(lane["pressure"])
		)
		aggregate["peak_upcoming_mass"] = maxi(
			int(aggregate["peak_upcoming_mass"]), int(lane["upcoming_mass"])
		)
		aggregate["peak_saturation_permille"] = maxi(
			int(aggregate["peak_saturation_permille"]),
			int(lane["saturation_permille"]),
		)
		if int(lane["overflow_weight"]) > 0:
			aggregate["overflow_duration_ticks"] = (
				int(aggregate["overflow_duration_ticks"]) + 1
			)
		if bool(lane["uncountered_aerial"]):
			aggregate["uncountered_aerial_duration_ticks"] = (
				int(aggregate["uncountered_aerial_duration_ticks"]) + 1
			)
		var eta := int(lane["minimum_unopposed_base_eta"])
		if eta >= 0:
			var previous := int(aggregate["minimum_nonnegative_base_eta"])
			aggregate["minimum_nonnegative_base_eta"] = eta if previous < 0 else mini(previous, eta)
	_samples += 1


func summary() -> Dictionary:
	var keys: Array = _lanes.keys()
	keys.sort_custom(func(a: String, b: String) -> bool: return int(a) < int(b))
	var lanes: Array = []
	for key: String in keys:
		lanes.append((_lanes[key] as Dictionary).duplicate(true))
	return {"sample_count": _samples, "lanes": lanes}


func _empty_lane(path_idx: int) -> Dictionary:
	return {
		"path_idx": path_idx,
		"peak_pressure": 0,
		"peak_upcoming_mass": 0,
		"peak_saturation_permille": 0,
		"overflow_duration_ticks": 0,
		"uncountered_aerial_duration_ticks": 0,
		"minimum_nonnegative_base_eta": -1,
	}
