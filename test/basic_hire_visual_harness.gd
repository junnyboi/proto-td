extends SceneTree

const BattleTicketRuntimeScript := preload("res://sim/battle_ticket_runtime.gd")
const UnitStateScript := preload("res://sim/unit_state.gd")

var _fixture: Node = null


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := _parse_user_args()
	var output_path := String(args.get("output", ""))
	var mode := String(args.get("mode", "mission"))
	var width := int(args.get("width", "1280"))
	var height := int(args.get("height", "720"))
	if output_path.is_empty():
		print("BASIC_HIRE_VISUAL_HARNESS_OK")
		quit(0)
		return
	if width < 320 or height < 320:
		push_error("feature visual harness requires output, width, and height")
		quit(1)
		return
	root.size = Vector2i(width, height)
	var built := false
	if mode == "battle":
		built = await _build_battle()
	elif mode == "mission":
		built = await _build_mission()
	else:
		push_error("unknown feature visual mode: %s" % mode)
		quit(1)
		return
	if not built:
		quit(1)
		return
	for _frame: int in 8:
		await process_frame
	if mode == "battle":
		_suppress_battle_overlays()
		await process_frame
	var image := root.get_texture().get_image()
	var error := image.save_png(output_path)
	if error != OK:
		push_error("feature visual capture failed: %s" % error_string(error))
		quit(1)
		return
	print(
		"BASIC_HIRE_VISUAL_OK|%s|%s|%dx%d"
		% [mode, output_path, image.get_width(), image.get_height()]
	)
	var music := root.get_node_or_null("Music")
	if music != null:
		music.call("stop")
	var sfx := root.get_node_or_null("Sfx")
	if sfx != null:
		sfx.call("stop_all")
	await _cleanup()
	quit(0)


func _build_mission() -> bool:
	var game := root.get_node("Game")
	game.set_run_seed(1701)
	game.start_campaign(false, true)
	var screen: Control = load("res://scenes/stage_select.tscn").instantiate()
	_fixture = screen
	root.add_child(screen)
	for _frame: int in 6:
		await process_frame
	var route_panel := screen.find_child("CampaignRoutePanel", true, false) as PanelContainer
	var route_inset := screen.find_child("RouteContentInset", true, false) as MarginContainer
	var expected_route_width := 0.0 if root.size.y > root.size.x else 480.0
	if route_panel == null or not is_equal_approx(route_panel.custom_minimum_size.x, expected_route_width):
		push_error("Campaign route rail does not match its responsive width contract")
		return false
	if route_inset == null:
		push_error("Campaign route content inset is unavailable")
		return false
	for side: StringName in [&"margin_left", &"margin_top", &"margin_right", &"margin_bottom"]:
		if route_inset.get_theme_constant(side) != 24:
			push_error("Campaign route content is missing its 24px inset")
			return false
	if screen.find_child("MissionControlRecruitDesk", true, false) != null:
		push_error("Campaign still contains Hire Recruit")
		return false
	return true


func _build_battle() -> bool:
	var game := root.get_node("Game")
	game.run_seed = 404
	game.campaign_active = false
	game.pending_stage = load("res://data/stages/s5.tres") as StageDef
	var direct_squad: Array[StringName] = [&"recruit"]
	game.set("default_squad", direct_squad)
	var battle: Node = load("res://scenes/battle.tscn").instantiate()
	_fixture = battle
	root.add_child(battle)
	if battle.get("startup_succeeded") != true:
		push_error("battle visual fixture failed to start")
		return false
	battle.set("ticks_per_frame_scale", 0.0)
	battle.set("_enemy_anim_seconds", 0.0)
	var stage: StageDef = battle.get("_stage")
	var cells := _representative_ground_cells(battle, stage)
	if cells.size() != 4:
		push_error("battle visual fixture could not select four ground cells")
		return false
	var facings: Array[int] = [
		UnitStateScript.Facing.RIGHT,
		UnitStateScript.Facing.DOWN,
		UnitStateScript.Facing.LEFT,
		UnitStateScript.Facing.UP,
	]
	var hero_ids: Array[StringName] = [&"a", &"b", &"c", &"d"]
	var operator := battle.get("_op_defs").get(&"recruit") as OperatorDef
	if operator == null:
		push_error("recruit definition is unavailable")
		return false
	var model: BattleModel = battle.get("model")
	for index: int in cells.size():
		var unit := UnitStateScript.new()
		unit.id = 800 + index
		unit.hero_id = hero_ids[index]
		unit.cell = cells[index]
		unit.facing = facings[index] as UnitState.Facing
		BattleTicketRuntimeScript.copy_legacy_unit(operator, unit)
		unit.portrait_asset_id = &""
		unit.last_attack_tick = -1
		model.units.append(unit)
	battle.call("_project_units")
	_suppress_battle_overlays()
	var navigator: RefCounted = battle.get("_map_nav")
	print("BATTLE_VISUAL_SCALE=", navigator.scale, "|CELLS=", cells)
	return true


func _representative_ground_cells(battle: Node, stage: StageDef) -> Array[Vector2i]:
	var candidates: Array[Vector2i] = []
	var size := stage.grid_size()
	for y: int in size.y:
		for x: int in size.x:
			var cell := Vector2i(x, y)
			if stage.tile_at(cell) == StageDef.Tile.GROUND:
				candidates.append(cell)
	var result: Array[Vector2i] = []
	if candidates.size() < 4:
		return result
	var viewport_center := Vector2(root.size) * 0.5
	candidates.sort_custom(
		func(a: Vector2i, b: Vector2i) -> bool:
			var a_center: Vector2 = battle.call("cell_center", a)
			var b_center: Vector2 = battle.call("cell_center", b)
			return a_center.distance_squared_to(viewport_center) < b_center.distance_squared_to(viewport_center)
	)
	for candidate: Vector2i in candidates:
		var projected: Vector2 = battle.call("cell_center", candidate)
		if (
			projected.x >= 90.0
			and projected.x <= float(root.size.x) - 90.0
			and projected.y >= 100.0
			and projected.y <= float(root.size.y) - 100.0
		):
			result.append(candidate)
			if result.size() == 4:
				return result
	for candidate: Vector2i in candidates:
		if not result.has(candidate):
			result.append(candidate)
			if result.size() == 4:
				break
	return result


func _suppress_battle_overlays() -> void:
	if _fixture == null or not is_instance_valid(_fixture):
		return
	var grid_root: Variant = _fixture.get("_grid_root")
	for child: Node in _fixture.get_children():
		if child == grid_root:
			continue
		if child is CanvasItem:
			(child as CanvasItem).visible = false
		elif child is CanvasLayer:
			(child as CanvasLayer).visible = false


func _cleanup() -> void:
	var game := root.get_node_or_null("Game")
	if game != null:
		game.set("content", null)
		game.set("pending_stage", null)
		game.set("current_battle", null)
		game.set("campaign", null)
		game.set("campaign_store", null)
		game.set("campaign_active", false)
	if _fixture != null and is_instance_valid(_fixture):
		_fixture.queue_free()
	for _frame: int in 16:
		await process_frame
	await create_timer(0.25).timeout


func _parse_user_args() -> Dictionary:
	var parsed: Dictionary = {}
	for argument: String in OS.get_cmdline_user_args():
		if not argument.begins_with("--") or not argument.contains("="):
			continue
		var separator := argument.find("=")
		parsed[argument.substr(2, separator - 2)] = argument.substr(separator + 1)
	return parsed
