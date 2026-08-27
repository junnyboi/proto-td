extends SceneTree


class PremiumPortraitCampaign:
	extends RefCounted

	const HEROES := [{
		"hero_id": "premium-archive-caster",
		"custom_callsign": "Archive Caster",
		"custom_title": null,
		"name_version": 1,
		"recruitment_index": 0,
		"current_class_id": "mage_apprentice",
		"first_class_id": "mage_apprentice",
		"advanced_class_id": null,
		"operator_def_id": "caster_1",
		"portrait_asset_id": "portrait_archive_caster",
		"identity_portrait_id": "portrait_archive_caster",
		"life_status": "ready",
		"hero_kind": "premium",
		"premium_id": "archive_caster",
		"premium_lives": 2,
		"premium_pull_count": 1,
		"xp": 0,
	}, {
		"hero_id": "premium-lunaris-vessel",
		"custom_callsign": "Lunaris Vessel",
		"custom_title": null,
		"name_version": 1,
		"recruitment_index": 1,
		"current_class_id": "sorcerer",
		"first_class_id": "sorcerer",
		"advanced_class_id": "sorcerer",
		"operator_def_id": "caster_2",
		"portrait_asset_id": "portrait_lunaris_vessel",
		"identity_portrait_id": "portrait_lunaris_vessel",
		"life_status": "ready",
		"hero_kind": "premium",
		"premium_id": "lunaris_vessel",
		"premium_lives": 3,
		"premium_pull_count": 1,
		"xp": 0,
	}, {
		"hero_id": "premium-reliquary-duelist",
		"custom_callsign": "Reliquary Duelist",
		"custom_title": null,
		"name_version": 1,
		"recruitment_index": 2,
		"current_class_id": "sword_saint",
		"first_class_id": "swordmaster",
		"advanced_class_id": "sword_saint",
		"operator_def_id": "guard_2",
		"portrait_asset_id": "portrait_reliquary_duelist",
		"identity_portrait_id": "portrait_reliquary_duelist",
		"life_status": "ready",
		"hero_kind": "premium",
		"premium_id": "reliquary_duelist",
		"premium_lives": 2,
		"premium_pull_count": 1,
		"xp": 0,
	}]

	func runtime_projection() -> Dictionary:
		var unlocked_operators: Array[StringName] = [&"caster_1", &"caster_2", &"guard_2"]
		var unlocked_traps: Array[StringName] = []
		var unlocked_spells: Array[StringName] = []
		return {
			"ready_heroes": HEROES.duplicate(true),
			"fallen_heroes": [],
			"premium_heroes": HEROES.duplicate(true),
			"premium_pool": [{
				"premium_id": "archive_caster", "rarity": 4,
			}, {
				"premium_id": "lunaris_vessel", "rarity": 5,
			}, {
				"premium_id": "reliquary_duelist", "rarity": 4,
			}],
			"premium_pull_history": [],
			"premium_pull_history_total": 0,
			"marks": 120,
			"basic_recruit_cost": 5,
			"basic_recruit_roster_limit": 32,
			"attempt_pending": false,
			"stage_ids": [&"s1"],
			"unlocked_operators": unlocked_operators,
			"unlocked_traps": unlocked_traps,
			"unlocked_spells": unlocked_spells,
		}

	func data_copy() -> Dictionary:
		return {"heroes": HEROES.duplicate(true)}

	func promotion_options(_hero_id: Variant) -> Dictionary:
		return {"accepted": false, "error_code": &"premium_fixed_kit", "choices": []}

	func campaign_uid() -> String:
		return "premium-portrait-visual"

	func save_revision() -> int:
		return 1

	func strategic_hash() -> Dictionary:
		return {"accepted": true, "value": "premium-portrait-visual"}


var _screen := "gacha"
var _output := ""
var _width := 1280
var _height := 720
var _scroll_bottom := false
var _focus_hero := ""


func _init() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--screen="):
			_screen = argument.trim_prefix("--screen=")
		elif argument.begins_with("--output="):
			_output = argument.trim_prefix("--output=")
		elif argument.begins_with("--width="):
			_width = int(argument.trim_prefix("--width="))
		elif argument.begins_with("--height="):
			_height = int(argument.trim_prefix("--height="))
		elif argument == "--scroll-bottom":
			_scroll_bottom = true
		elif argument.begins_with("--focus-hero="):
			_focus_hero = argument.trim_prefix("--focus-hero=")
	if _output.is_empty():
		print("PREMIUM_PORTRAIT_VISUAL_HARNESS_SMOKE_OK")
		quit(0)
		return
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(_width, _height)
	var game := root.get_node_or_null("Game")
	if game == null:
		push_error("premium portrait visual harness: Game autoload missing")
		quit(1)
		return
	game.call("set_run_seed", 8173)
	if not bool(game.call("start_campaign", false, true)):
		push_error("premium portrait visual harness: campaign fixture failed")
		quit(1)
		return
	game.set("selected_stage_id", &"s1")
	var scene_path := "res://scenes/gacha.tscn"
	if _screen in ["field", "training"]:
		game.set("campaign", PremiumPortraitCampaign.new())
		game.set("campaign_active", true)
		scene_path = (
			"res://scenes/squad_select.tscn"
			if _screen == "field"
			else "res://scenes/training.tscn"
		)
		if _screen == "training":
			game.set("training_return_path", &"staging")
	elif _screen != "gacha":
		push_error("premium portrait visual harness: unknown screen %s" % _screen)
		quit(1)
		return

	var screen := load(scene_path).instantiate() as Control
	root.add_child(screen)
	for _frame: int in range(24):
		await process_frame
	if _screen == "field":
		var command_scroll := screen.find_child("MissionCommandScroll", true, false) as ScrollContainer
		var roster_scroll := screen.find_child("OperatorRosterScroll", true, false) as ScrollContainer
		if command_scroll != null:
			command_scroll.scroll_vertical = 100000
		if roster_scroll != null:
			var target := screen.find_child("Pick_%s" % _focus_hero, true, false) as Control
			if target != null:
				roster_scroll.ensure_control_visible(target)
			else:
				roster_scroll.scroll_vertical = 100000 if _scroll_bottom else 0
		for _frame: int in range(6):
			await process_frame
	elif _screen == "gacha" and (_scroll_bottom or not _focus_hero.is_empty()):
		var hero_scroll := screen.find_child("PremiumHeroScroll", true, false) as ScrollContainer
		if hero_scroll != null:
			var target := screen.find_child("Premium_%s" % _focus_hero, true, false) as Control
			if target != null:
				hero_scroll.scroll_vertical = maxi(0, int(target.position.y))
			else:
				hero_scroll.scroll_vertical = 100000
		for _frame: int in range(6):
			await process_frame
	elif _screen == "training" and (_scroll_bottom or not _focus_hero.is_empty()):
		var training_scroll := screen.find_child("TrainingRosterScroll", true, false) as ScrollContainer
		if training_scroll != null:
			var target := screen.find_child("Recruit_%s" % _focus_hero, true, false) as Control
			if target != null:
				training_scroll.ensure_control_visible(target)
			else:
				training_scroll.scroll_vertical = 100000
		for _frame: int in range(6):
			await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_viewport().get_texture().get_image()
	var save_error := image.save_png(_output)
	if save_error != OK:
		push_error("premium portrait visual harness: screenshot failed %s" % error_string(save_error))
		quit(1)
		return

	if _screen == "gacha":
		var cards := screen.find_child("PremiumHeroGrid", true, false) as GridContainer
		if cards == null or cards.get_child_count() != 3:
			push_error("premium portrait visual harness: resonance cards missing")
			quit(1)
			return
	elif _screen == "field":
		var grid := screen.find_child("OperatorGrid", true, false) as GridContainer
		if grid == null or grid.get_child_count() != 3:
			push_error("premium portrait visual harness: field team cards missing")
			quit(1)
			return
	else:
		var rows := screen.find_child("TrainingRosterList", true, false) as Container
		if rows == null or rows.get_child_count() != 3:
			push_error("premium portrait visual harness: training rows missing")
			quit(1)
			return

	print(
		"PREMIUM_PORTRAIT_VISUAL_CAPTURE screen=%s size=%dx%d path=%s"
		% [_screen, image.get_width(), image.get_height(), _output]
	)
	root.remove_child(screen)
	screen.free()
	game.set("campaign_active", false)
	game.set("campaign", null)
	game.set("campaign_store", null)
	var music := root.get_node_or_null("Music")
	if music != null and music.has_method("stop"):
		music.call("stop")
	var sfx := root.get_node_or_null("Sfx")
	if sfx != null and sfx.has_method("stop_all"):
		sfx.call("stop_all")
	for _frame: int in range(8):
		await process_frame
	quit(0)
