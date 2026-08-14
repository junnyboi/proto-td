extends GutTest


func _observation(
	pressure: int,
	upcoming_mass: int,
	saturation: int,
	overflow: int,
	uncountered: bool,
	eta: int,
) -> Dictionary:
	return {"paths": [{
		"path_idx": 0,
		"pressure": pressure,
		"upcoming_mass": upcoming_mass,
		"saturation_permille": saturation,
		"overflow_weight": overflow,
		"uncountered_aerial": uncountered,
		"minimum_unopposed_base_eta": eta,
	}]}


func test_peaks_durations_minimum_eta_and_deep_copy() -> void:
	var telemetry := BattleObservationTelemetry.new()
	telemetry.consume_dictionary(_observation(10, 4, 500, 1, true, 20))
	telemetry.consume_dictionary(_observation(30, 2, 250, 0, true, 8))
	telemetry.consume_dictionary(_observation(20, 9, 1000, 3, false, -1))
	var summary := telemetry.summary()
	assert_eq(summary["sample_count"], 3)
	var lane: Dictionary = summary["lanes"][0]
	assert_eq(lane["peak_pressure"], 30)
	assert_eq(lane["peak_upcoming_mass"], 9)
	assert_eq(lane["peak_saturation_permille"], 1000)
	assert_eq(lane["overflow_duration_ticks"], 2)
	assert_eq(lane["uncountered_aerial_duration_ticks"], 2)
	assert_eq(lane["minimum_nonnegative_base_eta"], 8)
	(summary["lanes"] as Array).clear()
	assert_eq((telemetry.summary()["lanes"] as Array).size(), 1)
