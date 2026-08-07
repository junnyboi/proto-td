extends Node

## Passive instrumentation envelope (genre-agnostic). Game code records via
## count()/sample()/event(); output is written to artifacts/telemetry.json on
## quit or on an explicit flush() from the playtest runner. Series are stored
## as running aggregates (min/max/avg/last), never full arrays, so the file
## stays small enough to paste whole into agent context.

const OUTPUT_PATH := "res://artifacts/telemetry.json"

var current_tick: int = 0

var _counters: Dictionary = {}
var _series: Dictionary = {}
var _events: Array[Dictionary] = []
var _flushed := false


func count(counter_name: String, amount: int = 1) -> void:
	_counters[counter_name] = int(_counters.get(counter_name, 0)) + amount


func sample(series_name: String, value: float) -> void:
	if not _series.has(series_name):
		_series[series_name] = {"min": value, "max": value, "sum": 0.0, "n": 0, "last": value}
	var s: Dictionary = _series[series_name]
	s["min"] = minf(float(s["min"]), value)
	s["max"] = maxf(float(s["max"]), value)
	s["sum"] = float(s["sum"]) + value
	s["n"] = int(s["n"]) + 1
	s["last"] = value


func event(event_name: String, data: Dictionary = {}) -> void:
	_events.append({"t": current_tick, "name": event_name, "data": data})


func flush(meta: Dictionary) -> void:
	if _flushed:
		return
	_flushed = true
	var series_out: Dictionary = {}
	for key: String in _series:
		var s: Dictionary = _series[key]
		series_out[key] = {
			"min": s["min"],
			"max": s["max"],
			"avg": float(s["sum"]) / maxi(int(s["n"]), 1),
			"last": s["last"],
		}
	var payload := {
		"meta": meta,
		"counters": _counters,
		"series": series_out,
		"events": _events,
	}
	var dir := ProjectSettings.globalize_path(OUTPUT_PATH).get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var f := FileAccess.open(ProjectSettings.globalize_path(OUTPUT_PATH), FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(payload, "  "))
		f.close()
	print("[TELEMETRY] written: %s" % OUTPUT_PATH)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		flush({"quit_reason": "wm_close", "engine": Engine.get_version_info()["string"]})
