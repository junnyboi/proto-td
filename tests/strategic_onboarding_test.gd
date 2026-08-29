extends SceneTree

const PREFS := preload("res://scripts/view/view_preferences.gd")
const AuthoritativeCampaignFixtureType := preload("res://test/support/authoritative_campaign_fixture.gd")
const PATH := "user://strategic_onboarding_test.cfg"

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_remove(PATH)
	var game := root.get_node_or_null("Game")
	var i18n := root.get_node_or_null("I18n")
	_check(game != null and i18n != null, "required autoloads are unavailable")
	if game == null or i18n == null:
		_finish()
		return
	game.call("set_view_preferences_path", PATH)
	game.call("set_run_seed", 20260829)
	_check(PREFS.mark_command_tutorial_seen(PATH), "command tutorial fixture was not persisted")
	_check(not PREFS.has_seen_field_team_tutorial(PATH), "Field Team tutorial should be unseen by default")
	_check(not PREFS.has_seen_post_mission_tutorial(PATH), "post-mission tutorial should be unseen by default")
	_check(bool(game.call("start_campaign", false, true)), "strategic onboarding campaign fixture failed")
	game.call("_arm_post_mission_tutorial", BattleModel.Result.DEFEAT, {"stage_id": &"s1", "stars_before": 0})
	_check(not bool(game.call("consume_post_mission_tutorial_request")), "defeat armed post-mission onboarding")
	game.call("_arm_post_mission_tutorial", BattleModel.Result.CLEAR, {"stage_id": &"s2", "stars_before": 0})
	_check(not bool(game.call("consume_post_mission_tutorial_request")), "a later mission armed first-mission onboarding")
	game.call("_arm_post_mission_tutorial", BattleModel.Result.CLEAR, {"stage_id": &"s1", "stars_before": 1})
	_check(not bool(game.call("consume_post_mission_tutorial_request")), "a first-mission replay armed post-mission onboarding")
	game.call("_arm_post_mission_tutorial", BattleModel.Result.CLEAR, {"stage_id": &"s1", "stars_before": 0})
	_check(
		not bool(game.call("consume_post_mission_tutorial_request")),
		"uncommitted first-clear metadata bypassed campaign tutorial eligibility",
	)
	game.call("request_post_mission_tutorial")
	game.call("open_staging")
	var pre_clear_staging := await _wait_for_content(game, "res://scripts/ui/staging.gd")
	_check(pre_clear_staging != null, "pre-clear Company Command did not open")
	_check(
		pre_clear_staging == null
		or pre_clear_staging.find_child("PostMissionTutorial", true, false) == null,
		"Training and Valhalla tutorial mounted before the first mission clear",
	)
	root.size = Vector2i(720, 1280)
	_check(bool(game.call("open_field_team_for_stage", &"s1")), "Mission Control route rejected the first Field Team entry")
	var field_team := await _wait_for_content(game, "res://scripts/ui/squad_select.gd")
	_check(field_team != null, "first Field Team entry did not open the squad workspace")
	if field_team != null:
		await _verify_field_team_tutorial(field_team, i18n)
	_check(PREFS.has_seen_field_team_tutorial(PATH), "Field Team tutorial completion did not persist")

	var previous_field_team := game.get("content") as Node
	_check(bool(game.call("open_field_team_for_stage", &"s1")), "Field Team replay route was rejected")
	var replay := await _wait_for_content(
		game, "res://scripts/ui/squad_select.gd", previous_field_team,
	)
	_check(replay != null, "Field Team replay did not open")
	_check(
		replay == null or replay.find_child("FieldTeamTutorial", true, false) == null,
		"completed Field Team tutorial mounted again",
	)

	var first_clear := AuthoritativeCampaignFixtureType.clear_stage(
		game, &"s1", "strategic-onboarding-first-clear",
	)
	_check(first_clear.get("accepted", false), "first mission clear fixture was rejected")
	_check(bool(game.call("has_cleared_first_mission")), "committed first clear did not unlock post-mission onboarding")
	game.call("_arm_post_mission_tutorial", BattleModel.Result.CLEAR, {"stage_id": &"s1", "stars_before": 0})
	_check(
		bool(game.call("consume_post_mission_tutorial_request")),
		"the committed first clear did not arm post-mission onboarding",
	)

	root.size = Vector2i(1280, 720)
	game.call("request_post_mission_tutorial")
	game.call("open_staging")
	var staging := await _wait_for_content(game, "res://scripts/ui/staging.gd")
	_check(staging != null, "post-mission request did not return to Company Command")
	if staging != null:
		await _verify_post_mission_tutorial(staging, i18n)
	_check(PREFS.has_seen_post_mission_tutorial(PATH), "post-mission tutorial completion did not persist")

	game.call("request_post_mission_tutorial")
	var previous_staging := game.get("content") as Node
	game.call("open_staging")
	var staging_replay := await _wait_for_content(
		game, "res://scripts/ui/staging.gd", previous_staging,
	)
	_check(
		staging_replay == null or staging_replay.find_child("PostMissionTutorial", true, false) == null,
		"completed post-mission tutorial mounted again",
	)
	_check(
		not PREFS.mark_tutorial_seen(&"unknown_tutorial", PATH),
		"unknown tutorial preference key was accepted",
	)
	await _cleanup(game, i18n)
	_remove(PATH)
	_finish()


func _verify_field_team_tutorial(field_team: Control, i18n: Node) -> void:
	var tutorial := field_team.find_child("FieldTeamTutorial", true, false) as Control
	_check(tutorial != null and bool(tutorial.call("is_active")), "first Field Team tutorial did not mount")
	if tutorial == null:
		return
	await _verify_step(tutorial, &"build_squad", "PickCounter")
	var body := tutorial.find_child("TutorialBody", true, false) as Label
	_check(body != null and body.text.contains("squad limit") and body.text.contains("operator cards"), "Field Team squad-limit callout lost its card-selection guidance")
	tutorial.call("advance")
	await process_frame
	await _verify_step(tutorial, &"hire_recruits", "HireBasicRecruit")
	_check(body != null and body.text.contains("5 Marks"), "Field Team hiring callout lost the five-Mark cost")
	_check(bool(i18n.call("set_locale", &"zh-CN")), "Chinese locale activation failed")
	await process_frame
	var title := tutorial.find_child("TutorialTitle", true, false) as Label
	_check(title != null and title.text == "招募更多新兵", "Field Team tutorial did not refresh localized copy")
	_check(bool(i18n.call("set_locale", &"en-US")), "English locale restoration failed")
	await process_frame
	tutorial.call("advance")
	await process_frame
	await _verify_step(tutorial, &"deploy_squad", "StartBattle")
	_check(body != null and body.text.contains("deploy the squad"), "Field Team deploy callout lost its launch guidance")
	tutorial.call("advance")
	await process_frame
	_check(field_team.find_child("FieldTeamTutorial", true, false) == null, "completed Field Team tutorial remained mounted")


func _verify_post_mission_tutorial(staging: Control, i18n: Node) -> void:
	var tutorial := staging.find_child("PostMissionTutorial", true, false) as Control
	_check(tutorial != null and bool(tutorial.call("is_active")), "post-mission tutorial did not mount")
	if tutorial == null:
		return
	await _verify_step(tutorial, &"training", "TrainingButton")
	var body := tutorial.find_child("TutorialBody", true, false) as Label
	_check(body != null and body.text.contains("XP") and body.text.contains("specializations"), "Training callout lost XP promotion guidance")
	tutorial.call("advance")
	await process_frame
	await _verify_step(tutorial, &"valhalla", "VahallaButton")
	_check(body != null and body.text.contains("Death is permanent") and body.text.contains("Valhalla"), "Valhalla callout lost permanent-death guidance")
	_check(bool(i18n.call("set_locale", &"zh-CN")), "post-mission Chinese locale activation failed")
	await process_frame
	var title := tutorial.find_child("TutorialTitle", true, false) as Label
	_check(title != null and title.text == "缅怀阵亡者", "post-mission tutorial did not refresh localized copy")
	_check(bool(i18n.call("set_locale", &"en-US")), "post-mission English locale restoration failed")
	await process_frame
	tutorial.call("skip")
	await process_frame
	_check(staging.find_child("PostMissionTutorial", true, false) == null, "skipped post-mission tutorial remained mounted")


func _verify_step(tutorial: Control, step: StringName, target_name: String) -> void:
	await process_frame
	_check(StringName(tutorial.call("current_step_name")) == step, "%s tutorial step is not active" % step)
	_check(StringName(tutorial.call("current_target_name")) == StringName(target_name), "%s tutorial points to the wrong target" % step)
	var target := tutorial.get_parent().find_child(target_name, true, false) as Control
	var ring_rect := tutorial.call("current_target_rect") as Rect2
	_check(target != null and ring_rect.encloses(target.get_global_rect()), "%s tutorial target geometry is incorrect" % step)
	_check(
		target != null and tutorial.get_global_rect().grow(1.0).encloses(target.get_global_rect()),
		"%s tutorial target %s was not scrolled into viewport %s"
		% [step, target.get_global_rect() if target != null else Rect2(), tutorial.get_global_rect()],
	)
	var primary := tutorial.find_child("TutorialPrimary", true, false) as Button
	var card := tutorial.find_child("TutorialCallout", true, false) as Control
	_check(
		target != null and card != null
		and not card.get_global_rect().intersects(target.get_global_rect()),
		"%s tutorial callout obscures target %s"
		% [step, target.get_global_rect() if target != null else Rect2()],
	)
	var focus_owner := root.gui_get_focus_owner()
	_check(primary != null and focus_owner != null and tutorial.is_ancestor_of(focus_owner), "%s tutorial did not contain keyboard focus" % step)


func _wait_for_content(
	game: Node, script_path: String, previous: Node = null,
) -> Control:
	for _frame: int in range(180):
		var candidate := game.get("content") as Control
		if (
			candidate != null
			and candidate != previous
			and candidate.get_script() != null
			and String(candidate.get_script().resource_path) == script_path
		):
			for _settle: int in range(4):
				await process_frame
			return candidate
		await process_frame
	return null


func _cleanup(game: Node, i18n: Node) -> void:
	if i18n != null:
		i18n.call("set_locale", &"en-US")
	var content := game.get("content") as Node
	if content != null and is_instance_valid(content):
		var parent := content.get_parent()
		if parent != null:
			parent.remove_child(content)
		content.free()
	game.set("content", null)
	game.set("campaign_active", false)
	game.set("campaign", null)
	game.set("campaign_store", null)
	game.set("selected_stage_id", &"")
	game.set("selected_squad", [])
	game.call("set_view_preferences_path", PREFS.DEFAULT_PATH)
	var music := root.get_node_or_null("Music")
	if music != null:
		music.call("stop")
	var sfx := root.get_node_or_null("Sfx")
	if sfx != null:
		sfx.call("stop_all")
	for _frame: int in range(8):
		await process_frame
	await create_timer(0.5).timeout


func _remove(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("STRATEGIC_ONBOARDING_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)
