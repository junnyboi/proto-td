extends PlaytestBot

## Stability floor: no input, must survive to --max-ticks. From Phase 10 on
## it is also the differential loser (must lose every stage).


func tick(_t: int) -> bool:
	return false
