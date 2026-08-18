extends RefCounted

const BattleModelType := preload("res://sim/battle_model.gd")
const GameConfigType := preload("res://data/game_config.gd")
const StageDefType := preload("res://data/stage_def.gd")
const MemorialSupportType := preload("res://scripts/ui/components/memorial_support.gd")
const TrainingSupportType := preload("res://scripts/ui/components/training_support.gd")
const InventoryAuditType := preload(
	"res://selftest/scenarios/recruit_promotion_active_inventory.gd"
)
const S1 := preload("res://data/stages/s1.tres")
const CONFIG := preload("res://data/config/game.tres")
const MAX_MODEL_TICKS := 2400
const INVENTORY_PATH := "res://test/test_ui_components.gd.inventory.json"


func run(h: SelfTestHarness) -> void:
	h.expect_done()
	h.max_frames = 2100
	h.root.size = Vector2i(1280, 720)
	await h.frames(3)
	var game := h.autoload("Game")
	var started := bool(game.call("start_campaign", false, true))
	h.check("fresh Memorial campaign starts", started)
	if not started:
		return
	var initial: Array = game.call("campaign_projection")["ready_heroes"]
	var hero_ids: Array[StringName] = []
	for hero: Dictionary in initial.slice(0, 3):
		hero_ids.append(StringName(hero["hero_id"]))
	var begun: Dictionary = game.call("start_stage", &"s1", hero_ids, false)
	h.check("real S1 Memorial attempt begins", begun.get("accepted", false))
	if not begun.get("accepted", false):
		return
	var ticket: Dictionary = begun["ticket"]
	var launch: Dictionary = game.call("battle_launch")
	var model := (
		BattleModelType
		. create(
			S1 as StageDefType,
			launch["input"],
			42,
			CONFIG as GameConfigType,
			_catalog("res://data/enemies"),
			_catalog("res://data/operators"),
			_catalog("res://data/traps"),
			_catalog("res://data/spells"),
			launch["trusted_ticket_hashes"],
		)
	)
	h.check("ticket creates real Memorial BattleModel", model != null)
	if model == null:
		return
	var timeline: Array = [
		[6, &"deploy", StringName(ticket["squad"][0]["battle_id"]), Vector2i(3, 2), 0],
		[450, &"deploy", StringName(ticket["squad"][1]["battle_id"]), Vector2i(4, 2), 0],
		[800, &"deploy", StringName(ticket["squad"][2]["battle_id"]), Vector2i(5, 2), 0],
	]
	var action_index := 0
	while model.result == BattleModelType.Result.RUNNING and model.tick < MAX_MODEL_TICKS:
		while action_index < timeline.size() and int(timeline[action_index][0]) == model.tick:
			(
				h
				. check(
					"Memorial S1 action accepted",
					model.apply_action((timeline[action_index] as Array).slice(1)),
					str(timeline[action_index]),
				)
			)
			action_index += 1
		model.step()
		if model.tick % 300 == 0:
			await h.frames(1)
	var outcome: Dictionary = model.snapshot().get("outcome", {})
	var fallen_ids: Array[String] = []
	for row: Dictionary in outcome.get("rows", []):
		if bool(row["fell"]):
			fallen_ids.append(String(row["hero_id"]))
	(
		h
		. check(
			"real S1 reaches clear with at least one casualty",
			model.result == BattleModelType.Result.CLEAR and not fallen_ids.is_empty(),
			"tick=%d leaked=%d fallen=%s" % [model.tick, model.leaked, fallen_ids],
		)
	)
	if fallen_ids.is_empty():
		return
	var before_commit: Dictionary = game.get("campaign").data_copy()
	(
		h
		. check(
			"battle death is not Memorial truth before result commit",
			(before_commit["memorial"] as Array).is_empty(),
		)
	)
	game.set("current_battle", model)
	h.check(
		"S1 casualty result commits durably", game.call("record_result", model.result, model.stars)
	)
	var dead_id := fallen_ids[0]
	var after_commit: Dictionary = game.get("campaign").data_copy()
	var memorial: Array = after_commit["memorial"]
	h.check(
		"committed death creates exactly one matching Memorial row",
		(
			memorial.size() == fallen_ids.size()
			and memorial.any(
				func(row: Dictionary) -> bool: return String(row["hero_id"]) == dead_id
			)
		),
		"fallen=%s memorial=%s" % [fallen_ids, memorial],
	)
	var row_before_retry: Dictionary = _memorial_by_hero(memorial, dead_id)
	var receipt_before := _resolve_receipt(
		after_commit, int(row_before_retry["death"]["attempt_id"])
	)
	var retry_bytes_before := game.get("campaign").encode_save()["bytes"] as PackedByteArray
	var retry_revision_before := int(game.get("campaign").save_revision())
	var retry: Dictionary = (
		game
		. get("campaign")
		. resolve_attempt(
			String(receipt_before["command_id"]),
			int(receipt_before["payload"]["attempt_id"]),
			receipt_before["payload"]["outcome"],
			int(receipt_before["expected_save_revision"]),
		)
	)
	h.check("exact result retry is accepted as a duplicate", retry.get("accepted", false))
	if retry.get("accepted", false):
		h.check("exact result retry is not fresh", not bool(retry["payload"]["fresh"]))
	(
		h
		. check(
			"exact result retry adds no Memorial row",
			game.get("campaign").data_copy()["memorial"] == memorial,
		)
	)
	(
		h
		. check(
			"exact result retry preserves save bytes and revision",
			(
				game.get("campaign").encode_save()["bytes"] == retry_bytes_before
				and int(game.get("campaign").save_revision()) == retry_revision_before
			),
		)
	)
	var dead_hero := _hero(after_commit, dead_id)
	var replacement_command: Dictionary = (
		game
		. get("campaign")
		. recruit_person(
			"memorial-replacement",
			game.get("campaign").save_revision(),
			"replacement",
			dead_id,
		)
	)
	var replacement_result: Dictionary = game.call("commit_campaign_command", replacement_command)
	h.check("casualty replacement command commits", replacement_result.get("accepted", false))
	if not replacement_result.get("accepted", false):
		return
	var replacement: Dictionary = replacement_result["result"]["recruitment"]["hero"]
	(
		h
		. check(
			"replacement inherits no personal identity",
			(
				String(replacement["hero_id"]) != dead_id
				and (
					String(replacement["portrait_instance_id"])
					!= String(dead_hero["portrait_instance_id"])
				)
				and replacement["custom_callsign"] == null
				and int(replacement["xp"]) == 0
				and String(replacement["current_class_id"]) == "recruit"
			),
			str(replacement),
		)
	)
	var ready_heroes: Array = game.call("campaign_projection")["ready_heroes"]
	h.check(
		"dead hero is absent from ready squads and Training projection",
		(
			not ready_heroes.any(
				func(hero: Dictionary) -> bool: return String(hero["hero_id"]) == dead_id
			)
			and not TrainingSupportType.roster(game.get("campaign")).any(
				func(hero: Dictionary) -> bool: return String(hero["hero_id"]) == dead_id
			)
		),
	)
	var rows := MemorialSupportType.rows(game.get("campaign"))
	var projected := _row_by_hero(rows, dead_id)
	(
		h
		. check(
			"Memorial projection preserves person class deeds and death context",
			(
				not projected.is_empty()
				and projected["class_id"] == row_before_retry["class_id"]
				and projected["portrait_instance_id"] == row_before_retry["portrait_instance_id"]
				and int(projected["deeds"]["operations_deployed"]) >= 1
				and projected["death"] == row_before_retry["death"]
			),
			str(projected),
		)
	)
	var authority_text := String(game.get("campaign").encode_save()["text"])
	game.call("open_staging")
	var staging := await _await_screen(h, game, "StagingShell")
	var memorial_button := staging.find_child("MemorialButton", true, false) as Button
	(
		h
		. check(
			"Staging enables Memorial only after committed death",
			memorial_button != null and not memorial_button.disabled,
		)
	)
	var inventory := JSON.parse_string(FileAccess.get_file_as_string(INVENTORY_PATH)) as Dictionary
	var inventory_audit := InventoryAuditType.new()
	(
		inventory_audit
		. call(
			"_check_state",
			h,
			staging,
			inventory,
			"staging_memorial_active",
			"staging_memorial_active standard 1280x720",
		)
	)
	var staging_scroll := staging.find_child("StagingScroll", true, false) as ScrollContainer
	staging_scroll.scroll_vertical = ceili(staging_scroll.get_v_scroll_bar().max_value)
	await h.frames(4)
	await h.shot_grab("staging_memorial_active_1280x720")
	var telemetry := h.autoload("Telemetry")
	var events_before := (telemetry.get("_events") as Array).size()
	memorial_button.pressed.emit()
	var screen := await _await_screen(h, game, "MemorialShell")
	h.check("Memorial button opens the Memorial screen", screen != null)
	if screen == null:
		return
	var person := screen.find_child("Person_%s" % dead_id, true, false) as Label
	var class_label := screen.find_child("Class_%s" % dead_id, true, false) as Label
	var deeds_label := screen.find_child("Deeds_%s" % dead_id, true, false) as Label
	var death_label := screen.find_child("DeathContext_%s" % dead_id, true, false) as Label
	var memorial_scroll := screen.find_child("MemorialDialogScroll", true, false) as ScrollContainer
	var back := screen.find_child("MemorialBack", true, false) as Button
	var card := screen.find_child("Memorial_%s" % dead_id, true, false) as Control
	(
		h
		. check(
			"Memorial renders the committed person service class deeds and death",
			(
				person != null
				and person.text == String(projected["callsign"])
				and class_label != null
				and class_label.text.contains("Class at death")
				and deeds_label != null
				and deeds_label.text.contains("deployments")
				and death_label != null
				and death_label.text.contains("First Stand")
			),
		)
	)
	(
		h
		. check(
			"Memorial landscape geometry and text floor are readable",
			(
				memorial_scroll != null
				and back != null
				and card != null
				and _inside_viewport(memorial_scroll, h.root.size)
				and _horizontal_encloses(memorial_scroll.get_global_rect(), card.get_global_rect())
				and _visible_text_floor(screen) >= 32
			),
		)
	)
	await h.frames(4)
	await h.shot_grab("memorial_1280x720")
	back.grab_focus()
	await h.frames(5)
	(
		h
		. check(
			"Memorial Back is focus-reachable visible and at least 44x44 in landscape",
			(
				h.root.get_viewport().gui_get_focus_owner() == back
				and _inside_viewport(back, h.root.size)
				and back.size.x >= 44.0
				and back.size.y >= 44.0
				and _button_text_fits(back)
			),
			str(back.get_global_rect()),
		)
	)
	await h.shot_grab("memorial_back_1280x720")
	h.root.size = Vector2i(720, 1280)
	await h.frames(6)
	memorial_scroll.scroll_vertical = 0
	memorial_scroll.grab_focus()
	await h.frames(4)
	(
		h
		. check(
			"Memorial portrait geometry and text floor are readable",
			(
				_inside_viewport(memorial_scroll, h.root.size)
				and _horizontal_encloses(memorial_scroll.get_global_rect(), card.get_global_rect())
				and _visible_text_floor(screen) >= 32
			),
		)
	)
	await h.shot_grab("memorial_720x1280")
	back.grab_focus()
	await h.frames(5)
	(
		h
		. check(
			"Memorial Back is focus-reachable visible and at least 44x44 in portrait",
			(
				h.root.get_viewport().gui_get_focus_owner() == back
				and _inside_viewport(back, h.root.size)
				and back.size.x >= 44.0
				and back.size.y >= 44.0
				and _button_text_fits(back)
			),
			str(back.get_global_rect()),
		)
	)
	await h.shot_grab("memorial_back_720x1280")
	back.pressed.emit()
	await _await_screen(h, game, "StagingShell")
	var events: Array = (telemetry.get("_events") as Array).slice(events_before)
	var click_events := 0
	for event: Dictionary in events:
		if event["name"] == "sfx_played" and String(event["data"]["id"]) == "ui_click":
			click_events += 1
	h.check("Memorial open and back emit exactly two silent click events", click_events == 2)
	(
		h
		. check(
			"Memorial navigation mutates no campaign bytes",
			String(game.get("campaign").encode_save()["text"]) == authority_text,
		)
	)
	print("MEMORIAL_FLOW_COMPLETED")
	h.done()


func _catalog(path: String) -> Dictionary:
	var result := {}
	var directory := DirAccess.open(path)
	for filename: String in directory.get_files():
		var source := filename.trim_suffix(".remap")
		if source.ends_with(".tres"):
			var resource: Resource = load("%s/%s" % [path, source])
			result[resource.get("id")] = resource
	return result


func _hero(data: Dictionary, hero_id: String) -> Dictionary:
	for hero: Dictionary in data["heroes"]:
		if String(hero["hero_id"]) == hero_id:
			return hero
	return {}


func _memorial_by_hero(rows: Array, hero_id: String) -> Dictionary:
	for row: Dictionary in rows:
		if String(row["hero_id"]) == hero_id:
			return row
	return {}


func _row_by_hero(rows: Array[Dictionary], hero_id: String) -> Dictionary:
	for row: Dictionary in rows:
		if String(row["hero_id"]) == hero_id:
			return row
	return {}


func _resolve_receipt(data: Dictionary, attempt_id: int) -> Dictionary:
	for record: Dictionary in data["command_receipts"]:
		if (
			record["verb"] == "resolve_attempt"
			and int(record["payload"]["attempt_id"]) == attempt_id
		):
			return record
	return {}


func _await_screen(
	h: SelfTestHarness,
	game: Node,
	marker: String,
) -> Control:
	var budget := 120
	while budget > 0:
		var content := game.get("content") as Node
		if content != null and is_instance_valid(content) and content is Control:
			if content.name == marker or content.find_child(marker, true, false) != null:
				await h.frames(3)
				return content
		budget -= 1
		await h.frames(1)
	return null


func _inside_viewport(control: Control, viewport_size: Vector2i) -> bool:
	return Rect2(Vector2.ZERO, Vector2(viewport_size)).encloses(control.get_global_rect())


func _horizontal_encloses(outer: Rect2, inner: Rect2) -> bool:
	return inner.position.x >= outer.position.x and inner.end.x <= outer.end.x


func _visible_text_floor(root: Control) -> int:
	var floor := 1 << 20
	for node: Node in root.find_children("*", "Label", true, false):
		var label := node as Label
		if label.is_visible_in_tree() and not label.text.strip_edges().is_empty():
			floor = mini(floor, label.get_theme_font_size(&"font_size"))
	return floor if floor < 1 << 20 else 0


func _button_text_fits(button: Button) -> bool:
	var label := button.get_node_or_null("PresentationLabel") as Label
	if label == null:
		return false
	var font := label.get_theme_font(&"font")
	var font_size := label.get_theme_font_size(&"font_size")
	var text_width := (
		font
		. get_string_size(
			label.text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			font_size,
		)
		. x
	)
	return text_width + 32.0 <= button.size.x
