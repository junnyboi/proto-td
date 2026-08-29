extends SceneTree

const TEST_TIMEOUT_SECONDS := 25.0
const AuthoritativeCampaignFixtureType := preload(
	"res://test/support/authoritative_campaign_fixture.gd"
)

var _failures: Array[String] = []
var _finished := false


func _init() -> void:
	create_timer(TEST_TIMEOUT_SECONDS).timeout.connect(_on_timeout)
	call_deferred("_run")


func _run() -> void:
	var game := root.get_node_or_null("Game")
	_check(game != null, "Game autoload missing")
	if game == null:
		_finish()
		return
	game.call("set_run_seed", 20260829)
	_check(bool(game.call("start_campaign", false, true)), "promotion fixture failed")
	var cleared := AuthoritativeCampaignFixtureType.clear_stage(
		game, &"s1", "training-immediate-promotion",
	)
	_check(
		bool(cleared.get("accepted", false)),
		"promotion XP fixture rejected: %s" % cleared.get("error_code", &"unknown"),
	)
	if not bool(cleared.get("accepted", false)):
		_cleanup(game, null)
		_finish()
		return

	var state: Variant = game.get("campaign")
	var hero_id := _first_promotable_hero_id(state)
	_check(not hero_id.is_empty(), "canonical S1 clear did not produce a promotable operator")
	if hero_id.is_empty():
		_cleanup(game, null)
		_finish()
		return
	var before_data: Dictionary = state.data_copy()
	var before_hero := _hero_by_id(before_data.get("heroes", []), hero_id)
	var before_receipts := (before_data.get("promotion_receipts", []) as Array).size()
	var before_revision: int = state.save_revision()

	root.size = Vector2i(1280, 720)
	var screen: Node = load("res://scenes/training.tscn").instantiate()
	root.add_child(screen)
	await _frames(3)
	screen.set("_selected_hero_id", hero_id)
	screen.call("_show_roster")
	await _frames(2)
	_check(screen.find_child("ReviewPlan", true, false) == null, "roster still exposes Review Plan")
	var choose_promotion := screen.find_child("ChoosePromotion", true, false) as Button
	var existing_row := screen.find_child("Recruit_%s" % hero_id, true, false)
	_check(choose_promotion != null and not choose_promotion.disabled, "eligible operator lacks Choose Promotion")
	if choose_promotion == null or choose_promotion.disabled:
		_cleanup(game, screen)
		_finish()
		return
	choose_promotion.pressed.emit()
	await _frames(2)

	var path_cards := screen.find_child("PathCards", true, false) as GridContainer
	var first_path := path_cards.get_child(0) as Button if path_cards != null and path_cards.get_child_count() > 0 else null
	_check(first_path != null, "promotion paths did not render")
	if first_path == null:
		_cleanup(game, screen)
		_finish()
		return
	var target_class_id := String(first_path.get("class_id"))
	_check(
		screen.find_child("ChoosePath", true, false) == null,
		"specialization selection still requires a separate approval action",
	)
	_check(screen.find_child("ConfirmTraining", true, false) == null, "promotion still requires confirmation review")

	# The first activation paints acknowledgement for one frame, then commits.
	# A duplicate activation during that frame must not publish twice.
	first_path.pressed.emit()
	var pending_status := screen.find_child(
		"PromotionCommitStatus", true, false,
	) as Label
	_check(
		pending_status != null and pending_status.visible
		and pending_status.text == "PROMOTING…",
		"promotion does not paint its pending state before persistence",
	)
	var pending_state: Variant = game.get("campaign")
	_check(
		pending_state.save_revision() == before_revision,
		"promotion mutated campaign data before the pending frame was visible",
	)
	first_path.pressed.emit()
	await _frames(3)
	state = game.get("campaign")
	var after_data: Dictionary = state.data_copy()
	var after_hero := _hero_by_id(after_data.get("heroes", []), hero_id)
	var after_receipts := (after_data.get("promotion_receipts", []) as Array).size()
	_check(String(after_hero.get("current_class_id", "")) == target_class_id, "selected specialization was not applied")
	_check(String(after_hero.get("hero_id", "")) == String(before_hero.get("hero_id", "")), "promotion changed hero identity")
	_check(state.save_revision() == before_revision + 1, "immediate promotion did not publish exactly one save revision")
	_check(after_receipts == before_receipts + 1, "double activation dispatched more than one promotion")
	_check(StringName(screen.call("mode")) == &"roster", "successful promotion did not refresh the roster in place")
	_check(
		existing_row != null
		and existing_row == screen.find_child("Recruit_%s" % hero_id, true, false),
		"successful promotion rebuilt the selected roster row instead of updating it",
	)
	_check(screen.find_child("ReviewPlan", true, false) == null, "review action returned after promotion")
	_check(screen.find_child("ConfirmTraining", true, false) == null, "confirmation action returned after promotion")
	var acknowledgement := game.call("training_call", &"peek_acknowledgement") as Array
	_check(
		acknowledgement.size() == 1
		and String((acknowledgement[0] as Dictionary).get("hero_id", "")) == hero_id
		and String((acknowledgement[0] as Dictionary).get("to_class_id", "")) == target_class_id,
		"immediate promotion acknowledgement does not match the committed operator",
	)

	_cleanup(game, screen)
	await create_timer(0.1).timeout
	_finish()


func _first_promotable_hero_id(state: Variant) -> String:
	for hero: Dictionary in state.data_copy().get("heroes", []):
		var hero_id := String(hero.get("hero_id", ""))
		var options: Dictionary = state.promotion_options(hero_id)
		if bool(options.get("accepted", false)):
			return hero_id
	return ""


func _hero_by_id(rows: Array, hero_id: String) -> Dictionary:
	for hero: Dictionary in rows:
		if String(hero.get("hero_id", "")) == hero_id:
			return hero
	return {}


func _frames(count: int) -> void:
	for _index: int in count:
		await process_frame


func _cleanup(game: Node, screen: Node) -> void:
	if screen != null and is_instance_valid(screen):
		var parent := screen.get_parent()
		if parent != null:
			parent.remove_child(screen)
		screen.free()
	game.set("content", null)
	game.set("campaign_active", false)
	game.set("campaign", null)
	game.set("campaign_store", null)
	game.set("training_return_path", &"staging")
	var music := root.get_node_or_null("Music")
	if music != null and music.has_method("stop"):
		music.call("stop")
	var sfx := root.get_node_or_null("Sfx")
	if sfx != null and sfx.has_method("stop_all"):
		sfx.call("stop_all")


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _finished:
		return
	_finished = true
	if _failures.is_empty():
		print("TRAINING_IMMEDIATE_PROMOTION_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)


func _on_timeout() -> void:
	if _finished:
		return
	_finished = true
	push_error("Training immediate promotion test exceeded %.1f seconds" % TEST_TIMEOUT_SECONDS)
	quit(124)
