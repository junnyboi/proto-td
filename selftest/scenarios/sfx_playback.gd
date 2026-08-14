extends RefCounted

## Runtime SFX contract: ten accepted cues, eight bounded voices, raw telemetry
## per logical call, and one audible semantic start per render frame.


func run(h: SelfTestHarness) -> void:
	h.max_frames = 600
	await h.frames(10)
	h.expect_done()
	var sfx := h.autoload("Sfx")
	var telemetry := h.autoload("Telemetry")
	h.check("Sfx autoload exists", sfx != null)
	h.check("Telemetry autoload exists", telemetry != null)
	if sfx == null or telemetry == null:
		return
	sfx.call("stop_all")
	var starts_before := int(sfx.call("audible_start_count"))
	var dedupes_before := int(sfx.call("dedupe_count"))
	var events_before := (telemetry.get("_events") as Array).size()
	(
		h
		. check(
			"catalog exposes all ten accepted cues",
			int(sfx.call("catalog_entry_count")) == 10,
			"entries=%d" % int(sfx.call("catalog_entry_count")),
		)
	)
	(
		h
		. check(
			"Sfx owns exactly eight bounded voices",
			int(sfx.call("player_count")) == 8,
			"players=%d" % int(sfx.call("player_count")),
		)
	)

	h.check("raw leak alias starts", bool(sfx.call("play", "leak")))
	h.check(
		"same-frame resolved duplicate is audio-only no-op",
		not bool(sfx.call("play", "base_breach"))
	)
	h.check("leak resolves to base breach", sfx.call("last_resolved_id") == &"base_breach")
	(
		h
		. check(
			"same-frame alias pair starts exactly one voice",
			int(sfx.call("audible_start_count")) == starts_before + 1,
			"starts=%d" % int(sfx.call("audible_start_count")),
		)
	)
	(
		h
		. check(
			"same-frame alias pair records one dedupe",
			int(sfx.call("dedupe_count")) == dedupes_before + 1,
			"dedupes=%d" % int(sfx.call("dedupe_count")),
		)
	)
	var pair_events := (telemetry.get("_events") as Array).slice(events_before)
	h.check(
		"deduped pair preserves two raw events",
		pair_events.size() == 2,
		"events=%d" % pair_events.size()
	)
	if pair_events.size() == 2:
		h.check(
			"first raw telemetry id remains leak", String(pair_events[0]["data"]["id"]) == "leak"
		)
		(
			h
			. check(
				"second raw telemetry id remains base_breach",
				String(pair_events[1]["data"]["id"]) == "base_breach",
			)
		)

	await h.frames(2)
	var ui_ids := [
		"operator_select", "ability_ready", "action_reject", "ui_click", "placement_ready"
	]
	var ui_starts_before := int(sfx.call("audible_start_count"))
	for cue_id: String in ui_ids:
		h.check("direct UI cue starts: %s" % cue_id, bool(sfx.call("play", cue_id)))
	(
		h
		. check(
			"five distinct UI cues start five voices",
			int(sfx.call("audible_start_count")) == ui_starts_before + ui_ids.size(),
			"delta=%d" % (int(sfx.call("audible_start_count")) - ui_starts_before),
		)
	)

	await h.frames(2)
	var unknown_events_before := (telemetry.get("_events") as Array).size()
	var unknown_starts_before := int(sfx.call("audible_start_count"))
	h.check("unknown cue rejects playback", not bool(sfx.call("play", "missing")))
	(
		h
		. check(
			"unknown cue leaves start count unchanged",
			int(sfx.call("audible_start_count")) == unknown_starts_before,
			"starts=%d" % int(sfx.call("audible_start_count")),
		)
	)
	var unknown_events := (telemetry.get("_events") as Array).slice(unknown_events_before)
	h.check(
		"unknown cue still emits one raw event",
		unknown_events.size() == 1,
		"events=%d" % unknown_events.size()
	)
	if unknown_events.size() == 1:
		h.check("unknown raw id is preserved", String(unknown_events[0]["data"]["id"]) == "missing")
	h.check("scenario stops assigned voices", bool(sfx.call("stop_all")))
	h.check("stop leaves the eight-player pool", int(sfx.call("player_count")) == 8)
	h.done()
