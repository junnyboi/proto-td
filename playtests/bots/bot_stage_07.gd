extends StageBot

## S7 Full Kit — Lane C timeline (td-phase-10.md §2.5). DP arithmetic derived
## on paper before authoring; every row must be accepted by apply_action or
## the driver fails loudly.


func stage_id() -> StringName:
	return &"s7"


func squad() -> Array[StringName]:
	return [&"vanguard_1", &"guard_1", &"guard_2", &"sniper_1", &"caster_2", &"defender_1"]


func timeline() -> Array:
	return [
		[6, &"deploy", &"vanguard_1", Vector2i(4, 4), 0],
		[306, &"deploy", &"guard_1", Vector2i(5, 4), 0],
		[490, &"deploy", &"sniper_1", Vector2i(5, 1), 0],
		[920, &"deploy", &"defender_1", Vector2i(6, 4), 0],
		[1250, &"cast", &"charm", 19],
		[1390, &"deploy", &"guard_2", Vector2i(10, 2), 0],
		[1620, &"cast", &"bolt", Vector2i(10, 2)],
	]
