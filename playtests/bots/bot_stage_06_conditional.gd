extends PolicyBotDriver


func stage_id() -> StringName:
	return &"s6"


func squad() -> Array[StringName]:
	return [
		&"vanguard_1", &"guard_1", &"guard_2",
		&"defender_1", &"caster_1", &"defender_2",
	]
