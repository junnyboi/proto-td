extends StageBot

## S2 Tempo — Lane C timeline (td-phase-10.md §2.5). DP arithmetic derived
## on paper before authoring; every row must be accepted by apply_action or
## the driver fails loudly.


func stage_id() -> StringName:
	return &"s2"


func squad() -> Array[StringName]:
	return [&"vanguard_1", &"guard_1", &"defender_1", &"caster_1"]


func timeline() -> Array:
	return [
		[6, &"deploy", &"vanguard_1", Vector2i(4, 2), 0],
		[310, &"deploy", &"guard_1", Vector2i(5, 2), 0],
		[800, &"deploy", &"defender_1", Vector2i(3, 2), 0],
	]
