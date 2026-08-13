extends PlaytestBot

## The Phase 10 headline gate (td-phase-10.md §2.4.6): S1→S8 through the
## REAL unlock flow. Starts a fresh campaign, then chains the per-stage bots
## in campaign order, asserting between stages: the current stage is
## unlocked and the next still locked BEFORE the clear; the squad and every
## cast/trap in the timeline is drawn from the unlocked sets (the reward
## chain actually feeds the timelines); and after the clear the stage's
## rewards landed and the next stage opened. Navigates Game seams only —
## screens belong to campaign_flow.gd (raw input once per surface).

const BOT_COUNT := 8
const SETTLE_FRAMES := 4

var failed := false

var _started := false
var _stage_idx := 0
var _child: StageBot = null
var _settle := 0
var _pending_after: StageBot = null


func _init() -> void:
	expects_completion = true


func tick(t: int) -> bool:
	if failed:
		return false
	if not _started:
		_started = true
		_game().call("start_campaign", false)
	elif _settle > 0:
		_settle -= 1
		if _settle == 0 and _pending_after != null:
			_assert_after_clear(_pending_after)
			_pending_after = null
	elif _child == null and _stage_idx >= BOT_COUNT:
		return t >= StageBot.MIN_RUNNER_TICKS
	else:
		_drive_child(t)
	return false


func _drive_child(t: int) -> void:
	if _child == null:
		_child = _load_stage_bot(_stage_idx + 1)
		_child.tree = tree
		if not _assert_before_stage(_child):
			return
	if _child.failed:
		_fail("stage bot %s failed" % _child.stage_id())
		return
	if _child.tick(t):
		# settle a few frames so the view's result edge records the clear
		_pending_after = _child
		_settle = SETTLE_FRAMES
		_child = null
		_stage_idx += 1


func _load_stage_bot(index: int) -> StageBot:
	var script: GDScript = load("res://playtests/bots/bot_stage_0%d.gd" % index)
	return script.new()


func _assert_before_stage(bot: StageBot) -> bool:
	var game := _game()
	var sid := bot.stage_id()
	if not game.call("is_stage_unlocked", sid):
		return _fail("%s should be unlocked before its run" % sid)
	var order: Array = game.call("campaign_stage_ids")
	var index := order.find(sid)
	if index + 1 < order.size() and game.call("is_stage_unlocked", order[index + 1]):
		return _fail("%s unlocked before %s cleared" % [order[index + 1], sid])
	var campaign: LegacyCampaignAdapter = game.get("campaign")
	for op_id: StringName in bot.squad():
		if not campaign.unlocked_operators.has(op_id):
			return _fail("%s squad uses locked operator %s" % [sid, op_id])
	for row: Array in bot.timeline():
		if row[1] == &"cast" and not campaign.unlocked_spells.has(row[2]):
			return _fail("%s timeline casts locked spell %s" % [sid, row[2]])
		if row[1] == &"place_trap" and not campaign.unlocked_traps.has(row[2]):
			return _fail("%s timeline places locked trap %s" % [sid, row[2]])
	return true


func _assert_after_clear(bot: StageBot) -> void:
	var game := _game()
	var sid := bot.stage_id()
	var campaign: LegacyCampaignAdapter = game.get("campaign")
	if not campaign.stage_stars.has(sid):
		_fail("%s clear was not recorded" % sid)
		return
	var stage := load("res://data/stages/%s.tres" % sid) as StageDef
	for reward: Dictionary in stage.rewards:
		var item_id: StringName = reward["id"]
		var landed := (
			campaign.unlocked_operators.has(item_id)
			or campaign.unlocked_traps.has(item_id)
			or campaign.unlocked_spells.has(item_id)
		)
		if not landed:
			_fail("%s reward %s not granted" % [sid, item_id])
			return
	var order: Array = game.call("campaign_stage_ids")
	var index := order.find(sid)
	if index + 1 < order.size() and not game.call("is_stage_unlocked", order[index + 1]):
		_fail("%s cleared but %s still locked" % [sid, order[index + 1]])
		return
	print("[CAMPAIGN] %s cleared and recorded (%d/%d)" % [sid, index + 1, order.size()])


func _fail(message: String) -> bool:
	failed = true
	push_error("[CAMPAIGN] " + message)
	return false


func _game() -> Node:
	return tree.root.get_node("Game")
