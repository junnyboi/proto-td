extends SceneTree

const RuntimeContext := preload("res://sim/campaign_runtime_context.gd")
const CampaignStateV3 := preload("res://sim/campaign_state_v3.gd")
const BattleOutcomeV3 := preload("res://sim/battle_outcome_v3.gd")
const CampaignSaveStore := preload("res://sim/campaign_save_store.gd")
const ArtType := preload("res://scripts/view/art.gd")
const PortraitCatalogType := preload("res://data/presentation/operator_portrait_catalog.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var context := RuntimeContext.build()
	context["class_by_id"]["recruit"]["promotion_xp_required"] = 0
	var created: Dictionary = CampaignStateV3.create(31337, 1, context)
	_check(created.get("accepted", false), "Vahalla campaign fixture failed")
	if not created.get("accepted", false):
		_finish()
		return
	var state: Variant = created["value"]
	var initial: Dictionary = state.runtime_projection()
	var fallen_id := String(initial["ready_heroes"][0]["hero_id"])
	var active_id := String(initial["ready_heroes"][1]["hero_id"])
	var fallen_identity_portrait := StringName(initial["ready_heroes"][0]["portrait_asset_id"])
	state = _resolve_without_fall(state, context, fallen_id)
	if state == null:
		_finish()
		return
	state = _promote_once(state, context, fallen_id, "shock_trooper")
	if state == null:
		_finish()
		return
	var promoted_data: Dictionary = state.data_copy()
	var promoted_hero := _hero_by_id(promoted_data["heroes"], fallen_id)
	_check(
		StringName(promoted_hero.get("portrait_asset_id", &"")) == fallen_identity_portrait,
		"promotion changed the persisted Recruit portrait identity",
	)
	var expected_memorial_portrait := PortraitCatalogType.specialization_asset_id(
		&"shock_trooper", fallen_identity_portrait,
	)
	state = _fall_once(state, context, fallen_id)
	if state == null:
		_finish()
		return

	var game: Node = root.get_node_or_null("Game")
	var i18n: Node = root.get_node_or_null("I18n")
	_check(game != null, "Game autoload missing")
	_check(i18n != null, "I18n autoload missing")
	if game == null or i18n == null:
		_finish()
		return
	_check(bool(i18n.call("set_locale", &"en-US")), "English Vahalla locale activation failed")
	var store_result: Dictionary = CampaignSaveStore.create_production(state)
	_check(store_result.get("accepted", false), "Vahalla isolated save store failed")
	if not store_result.get("accepted", false):
		_finish()
		return
	var store: Variant = store_result["value"]
	var saved: Dictionary = store.save("", state)
	_check(saved.get("status") == CampaignSaveStore.COMMITTED, "Vahalla fixture was not durably seeded")
	if saved.get("status") != CampaignSaveStore.COMMITTED:
		_finish()
		return
	var seeded_authority: Dictionary = store._consume_commit_authority()
	state = seeded_authority.get("state")
	_check(state != null, "Vahalla fixture store did not publish authority")
	if state == null:
		_finish()
		return
	game.set("campaign", state)
	game.set("campaign_store", store)
	game.set("campaign_active", true)
	game.set("selected_stage_id", &"s1")

	var squad: Node = load("res://scenes/squad_select.tscn").instantiate()
	root.add_child(squad)
	await process_frame
	await process_frame
	var grid := squad.find_child("OperatorGrid", true, false) as GridContainer
	var active_tab := squad.find_child("ActiveRosterTab", true, false) as Button
	var fallen_tab := squad.find_child("FallenRosterTab", true, false) as Button
	var all_tab := squad.find_child("AllRosterTab", true, false) as Button
	_check(grid != null, "squad roster grid missing")
	_check(active_tab != null and active_tab.text.contains("4"), "active tab count is wrong")
	_check(fallen_tab != null and fallen_tab.text.contains("1"), "fallen tab count is wrong")
	if grid != null:
		_check(grid.get_node_or_null("Pick_%s" % fallen_id) == null, "fallen soldier visible by default")
	if fallen_tab != null:
		fallen_tab.pressed.emit()
		await process_frame
		var fallen_card := grid.get_node_or_null("Pick_%s" % fallen_id) as Button
		_check(fallen_card != null, "fallen tab did not reveal the dead soldier")
		_check(fallen_card != null and fallen_card.disabled, "fallen squad card remained deployable")
	if all_tab != null:
		all_tab.pressed.emit()
		await process_frame
		_check(grid.get_node_or_null("Pick_%s" % fallen_id) != null, "all tab omitted the fallen soldier")
		_check(grid.get_node_or_null("Pick_%s" % active_id) != null, "all tab omitted active soldiers")
	_dispose(squad)
	game.set("content", null)
	await process_frame

	var staging: Node = load("res://scenes/staging.tscn").instantiate()
	root.add_child(staging)
	await process_frame
	await process_frame
	var vahalla_tile := staging.find_child("VahallaButton", true, false) as Button
	var faction_heading := staging.find_child("FactionStandardsHeading", true, false)
	var faction_grid := staging.find_child("FactionStandardsGrid", true, false)
	_check(vahalla_tile != null, "Company Command Vahalla tile missing")
	_check(vahalla_tile != null and not vahalla_tile.disabled, "Company Command Vahalla tile disabled")
	_check(faction_heading == null, "Company Command faction standards heading still visible")
	_check(faction_grid == null, "Company Command faction standards grid still visible")
	_dispose(staging)
	game.set("content", null)
	await process_frame

	var memorial: Node = load("res://scenes/vahalla.tscn").instantiate()
	root.add_child(memorial)
	await process_frame
	await process_frame
	var obituary_list := memorial.find_child("VahallaObituaryList", true, false) as VBoxContainer
	var honor := memorial.find_child("Honor_%s" % fallen_id, true, false) as Button
	var portrait := memorial.find_child("SelectedMemorialPortrait", true, false) as TextureRect
	var ledger := memorial.find_child("ServiceLedger", true, false) as PanelContainer
	var roster_panel := memorial.find_child("MemorialRosterPanel", true, false) as PanelContainer
	var dossier_panel := memorial.find_child("MemorialDossier", true, false) as PanelContainer
	var memorial_scroll := memorial.find_child("VahallaMemorialScroll", true, false) as ScrollContainer
	var memorial_row := memorial.find_child("Memorial_%s" % fallen_id, true, false) as Button
	var back := memorial.find_child("BackToCommand", true, false) as Button
	var row_margin := memorial_row.find_child("MemorialRowMargin", true, false) as MarginContainer if memorial_row != null else null
	var row_class := memorial_row.find_child("MemorialRowClass", true, false) as Label if memorial_row != null else null
	var row_record := memorial_row.find_child("MemorialRowRecord", true, false) as Label if memorial_row != null else null
	_check(obituary_list != null and obituary_list.get_child_count() == 1, "Vahalla obituary entry missing")
	_check(back != null and back.text == "RETURN", "Vahalla return action was not shortened to RETURN")
	_check(not _tree_text(memorial).contains("HALL OF THE FALLEN"), "Vahalla retained the removed Reliquary eyebrow")
	_check(memorial.find_child("AllFactionFilter", true, false) == null, "Vahalla retained the removed faction filters")
	_check(obituary_list != null and obituary_list.get_theme_constant(&"separation") == 0, "Vahalla obituary entries still use card-grid gaps")
	_check(honor != null and not honor.disabled, "Vahalla honor action unavailable")
	_check(portrait != null and portrait.custom_minimum_size.y >= 380.0, "selected memorial identity is not visually dominant")
	_check(
		portrait != null and portrait.texture == ArtType.texture(expected_memorial_portrait),
		"Vahalla did not preserve the promoted operator's gender-matched specialization portrait",
	)
	_check(ledger != null and ledger.custom_minimum_size.y >= 132.0, "terminal service ledger hierarchy is missing")
	_check(memorial_row != null and memorial_row.custom_minimum_size.y >= 88.0 and memorial_row.custom_minimum_size.y < 104.0, "memorial entry is not a compact obituary row")
	_check(row_margin != null and row_margin.get_theme_constant(&"margin_left") >= 16, "memorial row padding is below 16px")
	_check(row_class != null and row_class.get_theme_font_size(&"font_size") >= 16, "memorial metadata is below 16px")
	_check(row_record != null and row_record.text.contains("FELL AT"), "obituary row omits the deceased service record")
	if memorial_row != null:
		var row_style := memorial_row.get_theme_stylebox(&"normal") as StyleBoxFlat
		_check(row_style != null and row_style.border_width_bottom == 1, "obituary row is not separated by a ledger rule")
	if roster_panel != null and dossier_panel != null:
		var roster_style := roster_panel.get_theme_stylebox(&"panel")
		var dossier_style := dossier_panel.get_theme_stylebox(&"panel")
		_check(roster_style.content_margin_left >= 24.0 and roster_style.content_margin_top >= 24.0 and roster_style.content_margin_right >= 24.0 and roster_style.content_margin_bottom >= 24.0, "Vahalla roster custom frame padding is below 24px")
		_check(dossier_style.content_margin_left >= 24.0 and dossier_style.content_margin_top >= 24.0 and dossier_style.content_margin_right >= 24.0 and dossier_style.content_margin_bottom >= 24.0, "Vahalla dossier custom frame padding is below 24px")
	if ledger != null:
		var ledger_style := ledger.get_theme_stylebox(&"panel")
		_check(ledger_style.content_margin_left >= 24.0 and ledger_style.content_margin_top >= 24.0 and ledger_style.content_margin_right >= 24.0 and ledger_style.content_margin_bottom >= 24.0, "Vahalla service ledger custom frame padding is below 24px")
	if memorial_row != null:
		memorial_row.grab_focus()
		memorial_row.pressed.emit()
		await process_frame
		await process_frame
		var restored_focus := root.gui_get_focus_owner()
		_check(restored_focus != null and restored_focus.name == StringName("Memorial_%s" % fallen_id), "Vahalla selection rebuild did not restore memorial-row focus")
	var text_scale_autoload := root.get_node("TextScale")
	text_scale_autoload.call("set_scale", 1.5)
	memorial.call("_apply_responsive_layout")
	await process_frame
	var intro := memorial.get("_intro_label") as Label
	_check(back != null and back.text == "RETURN", "150% Vahalla changed the RETURN label")
	_check(intro == null or not intro.visible, "150% Vahalla retained the redundant introduction")
	_check(memorial.find_child("VahallaObituaryList", true, false) is VBoxContainer, "150% Vahalla stopped using its single obituary list")
	text_scale_autoload.call("set_scale", 1.0)
	memorial.call("_apply_responsive_layout")
	await process_frame
	_check(bool(i18n.call("set_locale", &"zh-CN")), "Chinese Vahalla locale activation failed")
	await process_frame
	await process_frame
	var chinese_memorial := _tree_text(memorial)
	_check(chinese_memorial.contains("英灵殿"), "Vahalla title did not refresh to Chinese")
	_check(chinese_memorial.contains("失踪或被俘时可能获救") and chinese_memorial.contains("被消耗或粉碎则永久失去"), "Valhalla soul-status distinctions lost their reviewed Chinese meaning")
	_check(chinese_memorial.contains("第20刻"), "Vahalla service record did not localize its battle tick")
	var marks_before := int(game.call("campaign_projection").get("marks", 0))
	var revision_before := int(game.call("campaign_projection").get("save_revision", 0))
	honor = memorial.find_child("Honor_%s" % fallen_id, true, false) as Button
	if honor != null:
		honor.pressed.emit()
		await process_frame
		await process_frame
		var honored := memorial.find_child("Honor_%s" % fallen_id, true, false) as Button
		var honored_projection: Dictionary = game.call("campaign_projection")
		_check(int(honored_projection.get("marks", 0)) == marks_before + 5, "Honor did not grant exactly 5 Marks")
		_check(int(honored_projection.get("save_revision", 0)) == revision_before + 1, "Honor did not commit one save revision")
		_check((honored_projection.get("honored_fallen_hero_ids", []) as Array).has(fallen_id), "Honor was not projected as durable one-time state")
		_check(honored != null and honored.disabled, "honor action did not become permanently honored state")
		_check(honored != null and honored.text == "已致敬", "Chinese honor action copy did not update")
		var repeat: Dictionary = game.call("honor_fallen_hero", fallen_id)
		_check(not repeat.get("accepted", false) and repeat.get("error_code") == &"already_honored", "a second Honor command was not rejected")
		_check(int(game.call("campaign_projection").get("marks", 0)) == marks_before + 5, "repeated Honor paid Marks twice")
	var reloaded: Dictionary = store.load()
	_check(reloaded.get("accepted", false), "honored Vahalla save did not reload")
	if reloaded.get("accepted", false):
		var durable_state: Variant = reloaded["state"]
		var durable_data: Dictionary = durable_state.data_copy()
		var honor_record: Dictionary = durable_data["command_receipts"][-1]
		var duplicate: Dictionary = durable_state.honor_fallen(
			honor_record["command_id"],
			honor_record["expected_save_revision"],
			fallen_id,
		)
		_check(duplicate.get("accepted", false), "an exact Honor command retry was rejected")
		_check(not duplicate.get("payload", {}).get("fresh", true), "an exact Honor retry was treated as a new reward")
		var tampered: Dictionary = durable_data.duplicate(true)
		tampered["command_receipts"].pop_back()
		var tamper_restore: Dictionary = CampaignStateV3.restore(tampered, context)
		_check(not tamper_restore.get("accepted", false), "removing the Honor ledger entry left its five Marks valid")
	_dispose(memorial)
	game.set("content", null)
	if reloaded.get("accepted", false):
		game.set("campaign", reloaded["state"])
		var reopened: Node = load("res://scenes/vahalla.tscn").instantiate()
		root.add_child(reopened)
		await process_frame
		await process_frame
		var persisted_honor := reopened.find_child("Honor_%s" % fallen_id, true, false) as Button
		_check(persisted_honor != null and persisted_honor.disabled, "Honor did not remain disabled after save reload")
		_check(int(game.call("campaign_projection").get("marks", 0)) == marks_before + 5, "save reload changed the Honor reward")
		_dispose(reopened)
		game.set("content", null)
	var music := root.get_node_or_null("Music")
	if music != null and music.has_method("stop"):
		music.call("stop")
	var sfx := root.get_node_or_null("Sfx")
	if sfx != null and sfx.has_method("stop_all"):
		sfx.call("stop_all")
	game.set("campaign_active", false)
	game.set("campaign", null)
	game.set("campaign_store", null)
	await process_frame
	await create_timer(0.1).timeout
	_finish()


func _promote_once(
		state: Variant, context: Dictionary, hero_id: String, target_class_id: String,
	) -> Variant:
	var data := state.get("_data") as Dictionary
	var hero := _hero_by_id(data["heroes"], hero_id)
	if hero.is_empty():
		_check(false, "promotion fixture hero missing")
		return null
	var promoted: Dictionary = state.confirm_promotions(
		"vahalla-promoted-portrait", state.save_revision(), [{
			"hero_id": hero_id,
			"to_class_id": target_class_id,
		}],
	)
	_check(
		promoted.get("accepted", false),
		"promotion fixture command rejected: %s" % promoted.get("error_code", &"unknown"),
	)
	if not promoted.get("accepted", false):
		return null
	var mutation: Variant = promoted["payload"]["mutation"]
	var restored: Dictionary = CampaignStateV3.restore_source(
		mutation.prospective_save_text(), context,
	)
	_check(restored.get("accepted", false), "promoted portrait save did not restore")
	if not restored.get("accepted", false):
		return null
	var mutation_result := mutation.get("_result") as Dictionary
	var promotion_receipt := mutation_result.get("promotion", {}) as Dictionary
	_check(
		promotion_receipt.size() == 3
		and promotion_receipt.has("command_id")
		and promotion_receipt.has("save_revision")
		and promotion_receipt.has("choices"),
		"promotion receipt schema changed",
	)
	for choice: Dictionary in promotion_receipt.get("choices", []):
		_check(
			choice.size() == 3
			and choice.has("hero_id")
			and choice.has("from_class_id")
			and choice.has("to_class_id"),
			"promotion receipt leaked presentation identity fields",
		)
	return restored["value"]


func _hero_by_id(heroes: Array, hero_id: String) -> Dictionary:
	for hero: Dictionary in heroes:
		if String(hero.get("hero_id", "")) == hero_id:
			return hero
	return {}


func _resolve_without_fall(state: Variant, context: Dictionary, hero_id: String) -> Variant:
	var begin: Dictionary = state.begin_attempt(
		"test:vahalla:prepare:begin", "s1", [hero_id], 403, state.save_revision(),
	)
	_check(begin.get("accepted", false), "Vahalla promotion preparation attempt failed")
	if not begin.get("accepted", false):
		return null
	state = _restore_mutation(begin, context)
	if state == null:
		return null
	var ticket: Dictionary = state.data_copy()["tickets"][-1]
	var frozen: Dictionary = ticket["squad"][0]
	var outcome := BattleOutcomeV3.seal({
		"schema_version": BattleOutcomeV3.SCHEMA_VERSION,
		"attempt_id": ticket["attempt_id"],
		"ticket_hash": ticket["ticket_hash"],
		"result": "defeat",
		"terminal_reason": "resign",
		"terminal_tick": 10,
		"stars": 0,
		"leaks": 0,
		"kills": 0,
		"rows": [{
			"slot_index": frozen["slot_index"],
			"battle_id": frozen["battle_id"],
			"hero_id": frozen["hero_id"],
			"class_id": frozen["class_id"],
			"operator_def_id": frozen["operator_def_id"],
			"deployments": 1,
			"retreats": 1,
			"fell": false,
			"first_fall_tick": null,
		}],
	}, ticket)
	_check(outcome.get("accepted", false), "Vahalla promotion preparation outcome failed")
	if not outcome.get("accepted", false):
		return null
	var resolved: Dictionary = state.resolve_attempt(
		"test:vahalla:prepare:resolve",
		ticket["attempt_id"],
		outcome["value"],
		state.save_revision(),
	)
	_check(resolved.get("accepted", false), "Vahalla promotion preparation resolution failed")
	return _restore_mutation(resolved, context) if resolved.get("accepted", false) else null


func _fall_once(state: Variant, context: Dictionary, hero_id: String) -> Variant:
	var begin: Dictionary = state.begin_attempt(
		"test:vahalla:begin", "s1", [hero_id], 404, state.save_revision(),
	)
	_check(begin.get("accepted", false), "Vahalla fixture attempt failed")
	if not begin.get("accepted", false):
		return null
	state = _restore_mutation(begin, context)
	if state == null:
		return null
	var ticket: Dictionary = state.data_copy()["tickets"][-1]
	var frozen: Dictionary = ticket["squad"][0]
	var outcome := BattleOutcomeV3.seal({
		"schema_version": BattleOutcomeV3.SCHEMA_VERSION,
		"attempt_id": ticket["attempt_id"],
		"ticket_hash": ticket["ticket_hash"],
		"result": "defeat",
		"terminal_reason": "resign",
		"terminal_tick": 20,
		"stars": 0,
		"leaks": 0,
		"kills": 0,
		"rows": [{
			"slot_index": frozen["slot_index"],
			"battle_id": frozen["battle_id"],
			"hero_id": frozen["hero_id"],
			"class_id": frozen["class_id"],
			"operator_def_id": frozen["operator_def_id"],
			"deployments": 1,
			"retreats": 0,
			"fell": true,
			"first_fall_tick": 10,
		}],
	}, ticket)
	_check(outcome.get("accepted", false), "Vahalla fixture outcome failed")
	if not outcome.get("accepted", false):
		return null
	var resolved: Dictionary = state.resolve_attempt(
		"test:vahalla:resolve", ticket["attempt_id"], outcome["value"], state.save_revision(),
	)
	_check(resolved.get("accepted", false), "Vahalla fixture resolution failed")
	return _restore_mutation(resolved, context) if resolved.get("accepted", false) else null


func _restore_mutation(command: Dictionary, context: Dictionary) -> Variant:
	var mutation: Variant = command.get("payload", {}).get("mutation")
	if mutation == null:
		_check(false, "Vahalla fixture mutation missing")
		return null
	var restored: Dictionary = CampaignStateV3.restore_source(
		mutation.prospective_save_text(), context,
	)
	_check(restored.get("accepted", false), "Vahalla fixture save restore failed")
	return restored["value"] if restored.get("accepted", false) else null


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _dispose(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	var parent := node.get_parent()
	if parent != null:
		parent.remove_child(node)
	node.free()


func _tree_text(node: Node) -> String:
	var text := ""
	if node is Label or node is Button:
		text += String(node.get("text")) + "\n"
	for child: Node in node.get_children():
		text += _tree_text(child)
	return text


func _finish() -> void:
	if _failures.is_empty():
		print("VAHALLA_UI_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)
