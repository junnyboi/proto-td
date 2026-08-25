extends SceneTree

const RuntimeContext := preload("res://sim/campaign_runtime_context.gd")
const CampaignStateV3 := preload("res://sim/campaign_state_v3.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var context := RuntimeContext.build()
	var created: Dictionary = CampaignStateV3.create(99, 1, context)
	_check(created.get("accepted", false), "campaign fixture failed")
	if not created.get("accepted", false):
		_finish()
		return
	var game: Node = root.get_node_or_null("Game")
	_check(game != null, "Game autoload missing")
	if game == null:
		_finish()
		return
	game.set("campaign", created["value"])
	game.set("campaign_active", true)
	var screen: Node = load("res://scenes/gacha.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	await process_frame
	var grid := screen.find_child("PremiumHeroGrid", true, false) as GridContainer
	var marks := screen.find_child("MarksLabel", true, false) as Label
	var pull := screen.find_child("PremiumPullButton", true, false) as Button
	_check(grid != null, "premium hero grid missing")
	_check(marks != null and marks.text == "120 MARKS", "Marks projection is incorrect")
	_check(pull != null and not pull.disabled, "pull action should be available at 120 Marks")
	if grid != null:
		_check(grid.get_child_count() == 3, "premium pool did not render three cards")
		for premium_id: String in ["archive_caster", "lunaris_vessel", "reliquary_duelist"]:
			var card := grid.get_node_or_null("Premium_%s" % premium_id)
			_check(card != null, "missing premium card %s" % premium_id)
			if card != null:
				var portrait := _first_texture_rect(card)
				_check(portrait != null and portrait.texture != null, "missing portrait %s" % premium_id)
	game.set("campaign_active", false)
	game.set("campaign", null)
	screen.queue_free()
	_finish()


func _first_texture_rect(node: Node) -> TextureRect:
	if node is TextureRect:
		return node as TextureRect
	for child: Node in node.get_children():
		var found := _first_texture_rect(child)
		if found != null:
			return found
	return null


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("PREMIUM_GACHA_UI_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)
