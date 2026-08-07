extends StageBot

## S4 Air Raid — Lane C timeline (td-phase-10.md §2.5). DP arithmetic derived
## on paper before authoring; every row must be accepted by apply_action or
## the driver fails loudly.


func stage_id() -> StringName:
	return &"s4"


func squad() -> Array[StringName]:
	return [&"vanguard_1", &"guard_1", &"defender_1", &"sniper_1", &"caster_1"]


func timeline() -> Array:
	return [
		[6, &"deploy", &"vanguard_1", Vector2i(4, 4), 0],
		[310, &"deploy", &"sniper_1", Vector2i(2, 2), 0],
		[500, &"deploy", &"guard_1", Vector2i(5, 4), 0],
		[900, &"deploy", &"defender_1", Vector2i(3, 4), 0],
	]
