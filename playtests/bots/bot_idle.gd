extends PlaytestBot

## Stability floor: starts the default stage on its first tick, then does
## nothing and must survive to --max-ticks. From Phase 10 on it is also the
## differential loser (must lose every stage).


func tick(t: int) -> bool:
	if t == 0:
		var game: Node = tree.root.get_node("Game")
		game.call("start_battle", game.get("default_stage_id"))
	return false
