extends "res://playtests/bots/bot_stage_06_conditional.gd"


func policy_capabilities() -> Array[String]:
	var out := super.policy_capabilities()
	out.erase("charm")
	return out


func accepted_terminal_results() -> Array[int]:
	return [BattleModel.Result.DEFEAT]
