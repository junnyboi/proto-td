extends PlaytestBot

## Phase 4 headline gate: full S1-S8 through one durable CampaignStateV3.
## The driver issues real strategic commands and consumes committed tickets;
## this wrapper only schedules one bounded driver step per render tick.

const DriverScript := preload("res://playtests/bots/campaign_v3_driver.gd")
const MIN_FINISH_TICK := 110

var failed := false
var _driver: CampaignV3Driver = DriverScript.new()


func _init() -> void:
	expects_completion = true


func stop_reason() -> String:
	if failed:
		return "bot_failed"
	if _driver.completed:
		return "campaign_complete"
	return ""


func tick(t: int) -> bool:
	if failed:
		return false
	_driver.step(_game())
	if _driver.failed:
		failed = true
		push_error("[CAMPAIGN_V3] " + _driver.error)
		return false
	if _driver.completed and t >= MIN_FINISH_TICK:
		var game := _game()
		var projection: Dictionary = game.campaign_projection()
		if (projection["stage_stars"] as Dictionary).size() != 8:
			failed = true
			push_error("[CAMPAIGN_V3] campaign completed without eight star rows")
			return false
		print(
			(
				"[CAMPAIGN_V3] COMPLETE clears=%d training=%d promotions=%d replacements=%d revision=%d"
				% [
					_driver.stage_clears.size(),
					_driver.training_clears,
					_driver.promotions,
					_driver.replacements,
					projection["save_revision"],
				]
			)
		)
		return true
	return false


func _game() -> Node:
	return tree.root.get_node("Game")
