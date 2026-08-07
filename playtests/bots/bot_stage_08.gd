extends StageBot

## S8 The Gatecrasher — Lane C timeline (td-phase-10.md §2.5). DP arithmetic derived
## on paper before authoring; every row must be accepted by apply_action or
## the driver fails loudly.


func stage_id() -> StringName:
	return &"s8"


func squad() -> Array[StringName]:
	return [&"vanguard_1", &"guard_1", &"guard_2", &"defender_2", &"sniper_1", &"caster_2"]


func timeline() -> Array:
	return [
		[6, &"deploy", &"vanguard_1", Vector2i(4, 4), 0],
		[306, &"deploy", &"guard_1", Vector2i(5, 4), 0],
		[700, &"deploy", &"sniper_1", Vector2i(5, 1), 0],
		[960, &"deploy", &"defender_2", Vector2i(8, 2), 0],
		[1200, &"cast", &"charm", 9],
		[1560, &"deploy", &"caster_2", Vector2i(8, 1), 1],
		[1520, &"cast", &"bolt", Vector2i(8, 2)],
	]
