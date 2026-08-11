extends StageBot

## S6 Turncoat — Lane C timeline (td-phase-10.md §2.5, retuned td-phase-14.md
## §14.3 for wave_starts (0, 500)). Charm is ONCE_PER_WAVE, so the two casts
## sit one per window: heavy id 3 spawns tick 305, charmed at 320 (window 0 =
## [0, 500)); heavy id 8 spawns tick 545, charmed at 700 (window 1 = [500, ∞)).
## Each turncoat duels the next heavy up path 0. Terminal: CLEAR leaked=1
## killed=9 charmed=2 stars=2 @tick 1319. Every row must be accepted by
## apply_action or the driver fails loudly.


func stage_id() -> StringName:
	return &"s6"


func squad() -> Array[StringName]:
	return [&"vanguard_1", &"guard_1", &"guard_2", &"defender_1", &"caster_1", &"defender_2"]


func timeline() -> Array:
	return [
		[6, &"deploy", &"vanguard_1", Vector2i(4, 4), 0],
		[200, &"place_trap", &"spike_plate", Vector2i(3, 4)],
		[320, &"cast", &"charm", 3],
		[360, &"deploy", &"guard_1", Vector2i(5, 4), 0],
		[700, &"cast", &"charm", 8],
		[720, &"deploy", &"guard_2", Vector2i(6, 4), 0],
	]
