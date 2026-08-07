extends StageBot

## S6 Turncoat — Lane C timeline (td-phase-10.md §2.5). DP arithmetic derived
## on paper before authoring; every row must be accepted by apply_action or
## the driver fails loudly.


func stage_id() -> StringName:
	return &"s6"


func squad() -> Array[StringName]:
	return [&"vanguard_1", &"guard_1", &"guard_2", &"defender_1", &"caster_1", &"defender_2"]


func timeline() -> Array:
	return [
		[6, &"deploy", &"vanguard_1", Vector2i(4, 4), 0],
		[200, &"place_trap", &"spike_plate", Vector2i(3, 4)],
		[360, &"deploy", &"guard_1", Vector2i(5, 4), 0],
		[720, &"deploy", &"guard_2", Vector2i(6, 4), 0],
		[820, &"cast", &"charm", 3],
		[940, &"cast", &"charm", 10],
	]
