extends GutTest

const REQUIRED_PATHS := [
	"res://scenes/training.tscn",
	"res://scripts/ui/training.gd",
	"res://scripts/ui/components/training_roster_row.gd",
	"res://scripts/ui/components/promotion_path_card.gd",
]
const REQUIRED_KEYS: Array[StringName] = [
	&"ui.training.title",
	&"ui.training.choose_recruit",
	&"ui.training.view_paths",
	&"ui.training.choose_path",
	&"ui.training.permanent_warning",
	&"ui.training.confirm_action",
	&"ui.training.success",
	&"ui.error.unknown",
]
const EXPECTED_ERRORS: Array[StringName] = [
	&"invalid_argument_type", &"unknown_hero", &"hero_not_ready",
	&"insufficient_xp", &"wrong_source_class", &"invalid_choice",
	&"already_promoted", &"stale_revision", &"command_id_conflict",
	&"xp_overflow", &"save_failed",
]

var _previous_campaign: Variant = null
var _previous_content: Node = null
var _previous_active := false


func before_each() -> void:
	_previous_campaign = Game.campaign
	_previous_content = Game.content
	_previous_active = Game.campaign_active


func after_each() -> void:
	Game.campaign = _previous_campaign
	Game.content = _previous_content
	Game.campaign_active = _previous_active


func test_training_runtime_surfaces_exist() -> void:
	for path: String in REQUIRED_PATHS:
		assert_true(ResourceLoader.exists(path), path)


func test_game_and_staging_expose_guarded_training_route() -> void:
	var game_source := FileAccess.get_file_as_string("res://autoloads/game.gd")
	var staging_source := FileAccess.get_file_as_string("res://scripts/ui/staging.gd")
	assert_true(game_source.contains("func open_training()"))
	assert_true(staging_source.contains("Game.open_training()"))
	assert_true(staging_source.contains("_training_available"))


func test_training_copy_has_total_english_fallbacks() -> void:
	var fallbacks := UiCopy.static_fallbacks()
	for key: StringName in REQUIRED_KEYS:
		assert_true(fallbacks.has(key), String(key))
		assert_false(String(fallbacks.get(key, "")).is_empty(), String(key))


func test_witch_doctor_name_is_localized() -> void:
	var source := JSON.parse_string(
		FileAccess.get_file_as_string("res://localization/en-US.json"),
	) as Dictionary
	assert_eq(
		source["entries"].get("data.operator.witch_doctor_1.name"),
		"Witch Doctor",
	)


func test_training_roster_is_stable_and_model_owns_eligibility() -> void:
	var state := _promotion_state(400)
	var rows := state.training_roster()
	assert_eq(rows.size(), state.roster().all().size())
	for index: int in rows.size():
		assert_eq(rows[index]["hero_id"], state.roster().all()[index].hero_id())
	var mage := _mage_summary(rows)
	assert_true(mage["can_promote"])
	assert_eq(mage["eligibility_error"], &"")
	assert_eq(mage["xp"], 400)
	assert_eq(mage["xp_required"], 400)
	assert_eq((mage["choices"] as Array).size(), 2)
	var non_mage: Dictionary = rows.filter(
		func(row: Dictionary) -> bool:
			return row["first_class_id"] != "mage_apprentice"
	)[0]
	assert_false(non_mage["can_promote"])
	assert_eq(non_mage["eligibility_error"], &"wrong_source_class")


func test_training_roster_pins_399_boundary_without_ui_inference() -> void:
	var state := _promotion_state(399)
	var mage := _mage_summary(state.training_roster())
	assert_false(mage["can_promote"])
	assert_eq(mage["eligibility_error"], &"insufficient_xp")
	assert_eq(mage["xp_required"] - mage["xp"], 1)


func test_support_guard_rejects_legacy_and_accepts_canonical() -> void:
	var legacy: Variant = LegacyCampaignAdapter.create(_catalogs(), _stages())
	assert_false(TrainingScreen.supports_campaign(legacy))
	assert_true(TrainingScreen.supports_campaign(_promotion_state(400)))
	assert_false(TrainingScreen.supports_campaign(null))


func test_command_uses_current_uid_revision_hero_and_choice() -> void:
	var state := _promotion_state(400)
	var mage := _mage_summary(state.training_roster())
	var command: Dictionary = TrainingScreen.build_command(
		state, mage["hero_id"], "witch_doctor",
	)
	assert_eq(command.keys(), [
		"version", "verb", "command_id", "hero_id", "advanced_class_id",
		"expected_save_revision",
	])
	assert_eq(command["version"], 1)
	assert_eq(command["verb"], "promote_hero")
	assert_eq(command["hero_id"], mage["hero_id"])
	assert_eq(command["advanced_class_id"], "witch_doctor")
	assert_eq(command["expected_save_revision"], state.save_revision())
	assert_eq(
		command["command_id"],
		CampaignPromotion.command_id(
			state.campaign_uid(), state.save_revision(), mage["hero_id"],
			"witch_doctor",
		),
	)


func test_error_map_is_exhaustive_with_unknown_fallback() -> void:
	for code: StringName in EXPECTED_ERRORS:
		assert_ne(TrainingScreen.error_key(code), &"ui.error.unknown", String(code))
	assert_eq(TrainingScreen.error_key(&"future_error"), &"ui.error.unknown")


func test_path_screen_projects_both_exact_destination_facts() -> void:
	var fixture := await _screen_fixture(_promotion_state(400))
	var screen := fixture as TrainingScreen
	assert_not_null(screen)
	if screen == null:
		return
	(screen.find_child("ViewPaths", true, false) as Button).pressed.emit()
	await get_tree().process_frame
	assert_eq(screen.mode(), &"paths")
	var witch := screen.find_child("Path_witch_doctor", true, false) as Button
	var sorcerer := screen.find_child("Path_sorcerer", true, false) as Button
	assert_not_null(witch)
	assert_not_null(sorcerer)
	assert_true(witch.text.contains("WITCH DOCTOR"))
	assert_true(witch.text.contains("HEALER / SUPPORT"))
	assert_true(witch.text.contains("Mend"))
	assert_true(witch.text.contains("60 HP"))
	assert_true(witch.text.contains("18 DP"))
	assert_true(witch.text.contains("CLASS KIT"))
	assert_true(sorcerer.text.contains("SORCERER"))
	assert_true(sorcerer.text.contains("DAMAGE / CONTROL"))
	assert_true(sorcerer.text.contains("Tempest"))
	assert_true(sorcerer.text.contains("20 DP"))
	assert_true(sorcerer.text.contains("CLASS KIT"))


func test_cancel_confirmation_is_state_and_hash_equal() -> void:
	var state := _promotion_state(400)
	var before_data := state.data_copy()
	var before_hash := state.strategic_hash().duplicate(true)
	var screen := (await _screen_fixture(state)) as TrainingScreen
	await _open_confirmation(screen, "witch_doctor")
	var cancel := screen.find_child("CancelTraining", true, false) as Button
	assert_not_null(cancel)
	cancel.pressed.emit()
	await get_tree().process_frame
	assert_null(screen.find_child("PromotionConfirmationLayer", true, false))
	assert_eq(state.data_copy(), before_data)
	assert_eq(state.strategic_hash(), before_hash)


func test_confirm_promotes_same_identity_once_and_announces_success() -> void:
	var state := _promotion_state(400)
	var before := _mage_hero(state)
	var hero_id := before.hero_id()
	var portrait_id := before.identity_portrait_id()
	var callsign := String(before.display_callsign()["value"])
	var screen := (await _screen_fixture(state)) as TrainingScreen
	await _open_confirmation(screen, "witch_doctor")
	var confirm := screen.find_child("ConfirmTraining", true, false) as Button
	assert_not_null(confirm)
	confirm.pressed.emit()
	await get_tree().process_frame
	var after := state.roster().by_id(hero_id)
	assert_eq(after.hero_id(), hero_id)
	assert_eq(after.identity_portrait_id(), portrait_id)
	assert_eq(String(after.display_callsign()["value"]), callsign)
	assert_eq(after.advanced_class_id(), &"witch_doctor")
	assert_eq(after.operator_def_id(), &"witch_doctor_1")
	assert_eq(state.save_revision(), 2)
	assert_eq(state.data_copy()["promotion_receipts"].size(), 1)
	var success := screen.find_child("TrainingSuccess", true, false) as Label
	assert_not_null(success)
	assert_true(success.text.contains(callsign))
	assert_true(success.text.contains("Witch Doctor"))


func test_confirmation_traps_every_focus_direction_and_restores_background() -> void:
	var screen := (await _screen_fixture(_promotion_state(400))) as TrainingScreen
	await _open_confirmation(screen, "witch_doctor")
	var cancel := screen.find_child("CancelTraining", true, false) as Button
	var confirm := screen.find_child("ConfirmTraining", true, false) as Button
	var path := screen.find_child("Path_witch_doctor", true, false) as Button
	assert_eq(path.focus_mode, Control.FOCUS_NONE)
	for current: Control in [cancel, confirm]:
		var other := confirm if current == cancel else cancel
		var expected := current.get_path_to(other)
		for actual: NodePath in [
			current.focus_previous, current.focus_next,
			current.focus_neighbor_left, current.focus_neighbor_right,
			current.focus_neighbor_top, current.focus_neighbor_bottom,
		]:
			assert_eq(actual, expected)
	cancel.pressed.emit()
	await get_tree().process_frame
	assert_eq(path.focus_mode, Control.FOCUS_ALL)


func test_confirm_dispatch_is_consumed_before_duplicate_signal() -> void:
	var state := _promotion_state(400)
	var screen := (await _screen_fixture(state)) as TrainingScreen
	await _open_confirmation(screen, "witch_doctor")
	var confirm := screen.find_child("ConfirmTraining", true, false) as Button
	confirm.pressed.emit()
	confirm.pressed.emit()
	await get_tree().process_frame
	assert_eq(int(screen.get("_promotion_dispatch_count")), 1)
	assert_eq(state.save_revision(), 2)
	assert_eq(state.data_copy()["promotion_receipts"].size(), 1)


func test_ui_cancel_is_modal_only_in_roster_and_path_modes() -> void:
	var state := _promotion_state(400)
	var before := state.data_copy()
	var screen := (await _screen_fixture(state)) as TrainingScreen
	screen._unhandled_input(_cancel_event())
	await get_tree().process_frame
	assert_eq(screen.mode(), &"roster")
	assert_eq(Game.content, screen)
	(screen.find_child("ViewPaths", true, false) as Button).pressed.emit()
	await get_tree().process_frame
	assert_eq(screen.mode(), &"paths")
	screen._unhandled_input(_cancel_event())
	await get_tree().process_frame
	assert_eq(screen.mode(), &"paths")
	assert_eq(Game.content, screen)
	assert_eq(state.data_copy(), before)


func _screen_fixture(state: CampaignState) -> Control:
	Game.campaign = state
	Game.campaign_active = true
	var scene := load("res://scenes/training.tscn") as PackedScene
	var screen := scene.instantiate() as Control
	add_child_autofree(screen)
	await get_tree().process_frame
	await get_tree().process_frame
	return screen


func _cancel_event() -> InputEventAction:
	var event := InputEventAction.new()
	event.action = &"ui_cancel"
	event.pressed = true
	return event


func _open_confirmation(screen: TrainingScreen, choice_id: String) -> void:
	(screen.find_child("ViewPaths", true, false) as Button).pressed.emit()
	await get_tree().process_frame
	var path := screen.find_child("Path_%s" % choice_id, true, false) as Button
	path.pressed.emit()
	await get_tree().process_frame
	(screen.find_child("ChoosePath", true, false) as Button).pressed.emit()
	await get_tree().process_frame


func _promotion_state(xp: int) -> CampaignState:
	var created := CampaignState.create(42, 1, _definition(), _catalogs(), _stages())
	assert_true(created["accepted"], str(created.get("error_code", &"")))
	var data: Dictionary = (created["value"] as CampaignState).data_copy()
	for row: Dictionary in data["heroes"]:
		if row["first_class_id"] == "mage_apprentice":
			row["xp"] = xp
	var restored := CampaignState.restore(
		data, _definition(), _catalogs(), _stages(),
	)
	assert_true(restored["accepted"], str(restored.get("error_code", &"")))
	return restored["value"]


func _mage_summary(rows: Array[Dictionary]) -> Dictionary:
	for row: Dictionary in rows:
		if row["first_class_id"] == "mage_apprentice":
			return row
	return {}


func _mage_hero(state: CampaignState) -> HeroState:
	for hero: HeroState in state.roster().all():
		if hero.first_class_id() == &"mage_apprentice":
			return hero
	return null


func _definition() -> CampaignDef:
	return load("res://data/campaigns/p16_v2.tres") as CampaignDef


func _catalogs() -> Dictionary:
	return {
		"operators": _catalog_ids("res://data/operators"),
		"traps": _catalog_ids("res://data/traps"),
		"spells": _catalog_ids("res://data/spells"),
	}


func _stages() -> Array:
	var values: Array = []
	for index: int in range(1, 9):
		values.append(load("res://data/stages/s%d.tres" % index) as StageDef)
	return values


func _catalog_ids(path: String) -> Array[StringName]:
	var values: Array[StringName] = []
	for filename: String in DirAccess.open(path).get_files():
		var source := filename.trim_suffix(".remap")
		if source.ends_with(".tres"):
			values.append(StringName(source.trim_suffix(".tres")))
	return values
