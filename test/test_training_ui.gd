extends GutTest

const TrainingScreenType := preload("res://scripts/ui/training.gd")
const TrainingSupportType := preload("res://scripts/ui/components/training_support.gd")
const UiCopyType := preload("res://scripts/ui/components/ui_copy.gd")

const REQUIRED_PATHS := [
	"res://scenes/training.tscn",
	"res://scripts/ui/training.gd",
	"res://scripts/ui/components/training_support.gd",
	"res://scripts/ui/components/training_roster_row.gd",
	"res://scripts/ui/components/promotion_path_card.gd",
]
const REQUIRED_KEYS: Array[StringName] = [
	&"ui.results.training_available",
	&"ui.results.train_recruits",
	&"ui.training.title",
	&"ui.training.choose_recruit",
	&"ui.training.add_to_plan",
	&"ui.training.review_plan",
		&"ui.training.review_title",
		&"ui.training.review_entry",
		&"ui.training.removed_heading",
		&"ui.training.removed_entry",
		&"ui.training.skill_facts",
	&"ui.training.not_now",
	&"ui.training.permanent_warning",
	&"ui.training.confirm_action",
	&"ui.training.acknowledgement",
	&"ui.error.unknown",
]
const EXPECTED_ERRORS: Array[StringName] = [
	&"unknown_hero", &"dead_hero", &"insufficient_xp", &"locked_class",
	&"already_promoted_class", &"illegal_class_edge", &"missing_catalog",
	&"attempt_pending", &"malformed_hero_id", &"malformed_command",
	&"invalid_promotion_choice", &"invalid_promotion_choices",
	&"duplicate_hero_choice", &"stale_revision", &"command_id_conflict",
	&"command_history_unavailable", &"store_write_failed",
	&"store_integrity_failure", &"mutation_restore_mismatch",
	&"duplicate_authority_mismatch", &"invalid_runtime_mutation",
	&"campaign_inactive", &"promotion_retry_pending", &"no_promotion_retry",
]


class FakeCampaign:
	extends RefCounted

	var heroes: Array[Dictionary]
	var options_by_id: Dictionary


	func _init(hero_rows: Array[Dictionary], option_rows: Dictionary) -> void:
		heroes = hero_rows.duplicate(true)
		options_by_id = option_rows.duplicate(true)


	func data_copy() -> Dictionary:
		return {"heroes": heroes.duplicate(true)}


	func promotion_options(hero_id: String) -> Dictionary:
		return options_by_id.get(
			hero_id, {"accepted": false, "error_code": &"unknown_hero", "choices": []},
		).duplicate(true)


	func campaign_uid() -> String:
		return "0123456789abcdef"


	func save_revision() -> int:
		return 7


	func strategic_hash() -> Dictionary:
		return {"schema_version": 3, "full": "fake", "body": "fake"}


var _previous_campaign: Variant = null
var _previous_store: Variant = null
var _previous_content: Node = null
var _previous_active := false
var _previous_return_path: StringName = &"staging"
var _previous_pending: Variant = null


func before_each() -> void:
	_previous_campaign = Game.campaign
	_previous_store = Game.campaign_store
	_previous_content = Game.content
	_previous_active = Game.campaign_active
	_previous_return_path = Game.training_return_path
	_previous_pending = Game.get("_pending_promotion_mutation")
	Game.set("_pending_promotion_mutation", null)


func after_each() -> void:
	Game.campaign = _previous_campaign
	Game.campaign_store = _previous_store
	Game.content = _previous_content
	Game.campaign_active = _previous_active
	Game.training_return_path = _previous_return_path
	Game.set("_pending_promotion_mutation", _previous_pending)


func test_training_runtime_surfaces_exist() -> void:
	for path: String in REQUIRED_PATHS:
		assert_true(ResourceLoader.exists(path), path)


func test_game_results_and_staging_use_guarded_training_dispatch() -> void:
	var game_source := FileAccess.get_file_as_string("res://autoloads/game.gd")
	var results_source := FileAccess.get_file_as_string("res://scripts/ui/results.gd")
	var staging_source := FileAccess.get_file_as_string("res://scripts/ui/staging.gd")
	assert_true(game_source.contains("func training_call("))
	assert_true(results_source.contains('training_call(&"open", &"results")'))
	assert_true(staging_source.contains('training_call(&"open", &"staging")'))
	assert_true(staging_source.contains("_training_available"))
	assert_true(staging_source.contains("training_support.gd"))
	assert_false(staging_source.contains('preload("res://scripts/ui/training.gd")'))


func test_training_copy_has_total_bilingual_fallbacks_and_parity() -> void:
	var fallbacks := UiCopyType.static_fallbacks()
	var english := _catalog("en-US")
	var chinese := _catalog("zh-CN")
	assert_eq(english.keys(), chinese.keys())
	for key: StringName in REQUIRED_KEYS:
		assert_true(fallbacks.has(key), String(key))
		assert_false(String(fallbacks.get(key, "")).is_empty(), String(key))
		assert_false(String(english.get(String(key), "")).is_empty(), String(key))
		assert_false(String(chinese.get(String(key), "")).is_empty(), String(key))


func test_v3_support_guard_and_roster_projection_are_stable() -> void:
	var campaign := _campaign_fixture()
	assert_true(TrainingSupportType.supports_campaign(campaign))
	assert_false(TrainingSupportType.supports_campaign(RefCounted.new()))
	assert_false(TrainingSupportType.supports_campaign(null))
	var rows := TrainingSupportType.roster(campaign)
	assert_eq(rows.map(func(row: Dictionary) -> int: return row["recruitment_index"]), [0, 1, 2, 3])
	assert_eq(TrainingSupportType.eligible_count(campaign), 2)
	assert_true(rows[0]["can_promote"])
	assert_eq(rows[0]["xp"], 100)
	assert_eq(rows[0]["xp_required"], 100)
	assert_eq((rows[0]["choices"] as Array).size(), 5)
	assert_false(rows[2]["can_promote"])
	assert_eq(rows[2]["eligibility_error"], &"insufficient_xp")
	assert_false(rows[3]["can_promote"])
	assert_eq(rows[3]["eligibility_error"], &"dead_hero")


func test_recruit_choice_screen_projects_exactly_five_standard_classes() -> void:
	var screen := await _screen_fixture(_campaign_fixture())
	(screen.find_child("ViewPaths", true, false) as Button).pressed.emit()
	await get_tree().process_frame
	assert_eq(screen.call("mode"), &"paths")
	var expected := [
		"defender", "gunner", "mage_apprentice", "shock_trooper", "swordmaster",
	]
	var skill_names := {
		"defender": "Hold the Line", "gunner": "Deadeye",
		"mage_apprentice": "Conflagration", "shock_trooper": "Rally",
		"swordmaster": "Flurry",
	}
	var cadences := {
		"defender": 30, "gunner": 30, "mage_apprentice": 45,
		"shock_trooper": 30, "swordmaster": 24,
	}
	for class_id: String in expected:
		var card := screen.find_child("Path_%s" % class_id, true, false) as Button
		assert_not_null(card, class_id)
		assert_true(
			card.text.contains(TrainingScreenType.class_label(class_id).to_upper()), class_id,
		)
		assert_true(card.text.contains("DP"), class_id)
		assert_true(card.text.contains("Skill: %s" % skill_names[class_id]), class_id)
		assert_true(card.text.contains("ATK %sT" % cadences[class_id]), class_id)
		assert_true(card.text.contains("CLASS KIT"), class_id)
	assert_eq(screen.find_children("Path_*", "Button", true, false).size(), 5)
	assert_not_null(screen.find_child("PermanentWarning", true, false))


func test_two_recruits_remain_distinct_and_review_once_each() -> void:
	var screen := await _screen_fixture(_campaign_fixture())
	await _draft_choice(screen, "hero_a", "defender")
	await _select_roster(screen, "hero_b")
	await _draft_choice(screen, "hero_b", "gunner")
	var review := screen.find_child("ReviewPlan", true, false) as Button
	assert_not_null(review)
	review.pressed.emit()
	await get_tree().process_frame
	assert_eq(screen.call("mode"), &"review")
	assert_not_null(screen.find_child("Review_hero_a", true, false))
	assert_not_null(screen.find_child("Review_hero_b", true, false))
	assert_eq(screen.find_children("Review_hero_*", "Label", true, false).size(), 2)
	var choices := screen.call("_draft_choices") as Array[Dictionary]
	assert_eq(choices, [
		{"hero_id": "hero_a", "to_class_id": "defender"},
		{"hero_id": "hero_b", "to_class_id": "gunner"},
	])


func test_review_cancel_sequence_retains_draft() -> void:
	var screen := await _screen_fixture(_campaign_fixture())
	await _draft_choice(screen, "hero_a", "defender")
	(screen.find_child("ReviewPlan", true, false) as Button).pressed.emit()
	await get_tree().process_frame
	assert_eq(screen.call("mode"), &"review")
	screen.call("_unhandled_input", _cancel_event())
	await get_tree().process_frame
	assert_eq(screen.call("mode"), &"paths")
	assert_eq(screen.call("selected_choice_id"), "defender")
	screen.call("_unhandled_input", _cancel_event())
	await get_tree().process_frame
	assert_eq(screen.call("mode"), &"roster")
	assert_eq(screen.get("_draft"), {"hero_a": "defender"})


func test_stale_reconciliation_lists_removed_rows_and_retains_legal_draft() -> void:
	var campaign := _campaign_fixture()
	var screen := await _screen_fixture(campaign)
	await _draft_choice(screen, "hero_a", "defender")
	await _draft_choice(screen, "hero_b", "gunner")
	campaign.options_by_id["hero_a"] = {
		"accepted": false, "error_code": &"dead_hero", "choices": [],
	}
	var removed := screen.call("_reconcile_draft") as Array
	screen.call("_show_review", &"stale_revision", removed)
	await get_tree().process_frame
	var error := screen.find_child("TrainingReviewError", true, false) as Label
	assert_not_null(error)
	assert_false(error.text.is_empty())
	assert_eq(screen.get_viewport().gui_get_focus_owner(), error)
	assert_eq(screen.get("_draft"), {"hero_b": "gunner"})
	var removed_entry := screen.find_child("Removed_hero_a", true, false) as Label
	assert_not_null(removed_entry)
	assert_true(removed_entry.text.contains("Defender"))
	assert_true(removed_entry.text.contains("Dead recruits cannot train"))
	assert_false((screen.find_child("ConfirmTraining", true, false) as Button).disabled)


func test_stale_total_invalidation_stays_in_focused_review_with_confirm_disabled() -> void:
	var campaign := _campaign_fixture()
	var screen := await _screen_fixture(campaign)
	await _draft_choice(screen, "hero_a", "defender")
	campaign.options_by_id["hero_a"] = {
		"accepted": false, "error_code": &"dead_hero", "choices": [],
	}
	var removed := screen.call("_reconcile_draft") as Array
	screen.call("_show_review", &"stale_revision", removed)
	await get_tree().process_frame
	assert_eq(screen.call("mode"), &"review")
	assert_true((screen.get("_draft") as Dictionary).is_empty())
	assert_not_null(screen.find_child("Removed_hero_a", true, false))
	var error := screen.find_child("TrainingReviewError", true, false) as Label
	assert_eq(screen.get_viewport().gui_get_focus_owner(), error)
	assert_true((screen.find_child("ConfirmTraining", true, false) as Button).disabled)
	assert_false((screen.find_child("ReviewBack", true, false) as Button).disabled)


func test_missing_presentation_resource_surfaces_focused_catalog_error() -> void:
	var campaign := _campaign_fixture()
	var choices := campaign.options_by_id["hero_a"]["choices"] as Array
	(choices[0] as Dictionary)["operator_def_id"] = "missing"
	var projected := TrainingSupportType.options(campaign, "hero_a")
	assert_false(projected["accepted"])
	assert_eq(projected["error_code"], &"missing_catalog")
	assert_eq(TrainingSupportType.eligible_count(campaign), 2)
	var screen := await _screen_fixture(campaign)
	assert_eq(screen.call("mode"), &"roster")
	var error := screen.find_child("TrainingRosterError", true, false) as Label
	assert_not_null(error)
	assert_false(error.text.is_empty())
	assert_eq(screen.get_viewport().gui_get_focus_owner(), error)


func test_error_map_is_total_with_unknown_fallback() -> void:
	for code: StringName in EXPECTED_ERRORS:
		assert_ne(TrainingScreenType.error_key(code), &"ui.error.unknown", String(code))
	assert_eq(TrainingScreenType.error_key(&"future_error"), &"ui.error.unknown")


func test_pending_storage_retry_disables_review_back() -> void:
	var screen := await _screen_fixture(_campaign_fixture())
	await _draft_choice(screen, "hero_a", "defender")
	Game.set("_pending_promotion_mutation", RefCounted.new())
	screen.call("_show_review", &"store_write_failed")
	await get_tree().process_frame
	var back := screen.find_child("ReviewBack", true, false) as Button
	var confirm := screen.find_child("ConfirmTraining", true, false) as Button
	assert_true(back.disabled)
	assert_false(confirm.disabled)
	screen.call("_unhandled_input", _cancel_event())
	await get_tree().process_frame
	assert_eq(screen.call("mode"), &"review")


func _screen_fixture(campaign: FakeCampaign) -> Control:
	Game.campaign = campaign
	Game.campaign_store = null
	Game.campaign_active = true
	var scene := load("res://scenes/training.tscn") as PackedScene
	var screen := scene.instantiate() as Control
	add_child_autofree(screen)
	await get_tree().process_frame
	await get_tree().process_frame
	return screen


func _draft_choice(screen: Control, hero_id: String, class_id: String) -> void:
	if String(screen.call("selected_hero_id")) != hero_id:
		await _select_roster(screen, hero_id)
	(screen.find_child("ViewPaths", true, false) as Button).pressed.emit()
	await get_tree().process_frame
	(screen.find_child("Path_%s" % class_id, true, false) as Button).pressed.emit()
	await get_tree().process_frame
	(screen.find_child("ChoosePath", true, false) as Button).pressed.emit()
	await get_tree().process_frame


func _select_roster(screen: Control, hero_id: String) -> void:
	var row := screen.find_child("Recruit_%s" % hero_id, true, false) as Button
	assert_not_null(row, hero_id)
	row.pressed.emit()
	await get_tree().process_frame


func _campaign_fixture() -> FakeCampaign:
	var heroes: Array[Dictionary] = [
		_hero("hero_c", 2, 99, "ready", "portrait_recruit_02"),
		_hero("hero_a", 0, 100, "ready", "portrait_recruit_00"),
		_hero("hero_dead", 3, 100, "dead", "portrait_recruit_03"),
		_hero("hero_b", 1, 100, "ready", "portrait_recruit_01"),
	]
	var choices := _standard_choices()
	return FakeCampaign.new(
		heroes,
		{
			"hero_a": {"accepted": true, "error_code": &"", "choices": choices},
			"hero_b": {"accepted": true, "error_code": &"", "choices": choices},
			"hero_c": {
				"accepted": false, "error_code": &"insufficient_xp", "choices": [],
			},
			"hero_dead": {"accepted": false, "error_code": &"dead_hero", "choices": []},
		},
	)


func _hero(
	hero_id: String, index: int, xp: int, life_status: String, portrait: String,
) -> Dictionary:
	return {
		"hero_id": hero_id,
		"current_class_id": "recruit",
		"operator_def_id": "recruit",
		"portrait_asset_id": portrait,
		"identity_portrait_id": portrait,
		"recruitment_index": index,
		"name_version": 1,
		"custom_callsign": "Recruit %d" % (index + 1),
		"life_status": life_status,
		"xp": xp,
	}


func _standard_choices() -> Array[Dictionary]:
	return [
		_choice("shock_trooper", "vanguard_1"),
		_choice("swordmaster", "guard_1"),
		_choice("defender", "defender_1"),
		_choice("gunner", "sniper_1"),
		_choice("mage_apprentice", "caster_1"),
	]


func _choice(class_id: String, operator_id: String) -> Dictionary:
	return {
		"hero_id": "",
		"from_class_id": "recruit",
		"to_class_id": class_id,
		"operator_def_id": operator_id,
		"xp_required": 100,
	}


func _catalog(locale: String) -> Dictionary:
	var payload := JSON.parse_string(
		FileAccess.get_file_as_string("res://localization/%s.json" % locale),
	) as Dictionary
	return payload["entries"]


func _cancel_event() -> InputEventAction:
	var event := InputEventAction.new()
	event.action = &"ui_cancel"
	event.pressed = true
	return event
