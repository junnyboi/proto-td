extends "res://playtests/bots/bot_stage_06.gd"

## S6 differential loser (td-phase-10.md §2.4.4): the SAME timeline minus
## the charm casts must lose — derived by filtering, so the two timelines
## can never drift apart. Proves S6 actually teaches Charm (acceptance #4's
## twist analogue).


func timeline() -> Array:
	var rows: Array = []
	for row: Array in super.timeline():
		if row[1] == &"cast" and row[2] == &"charm":
			continue
		rows.append(row)
	return rows


func expected_result() -> int:
	return BattleModel.Result.DEFEAT
