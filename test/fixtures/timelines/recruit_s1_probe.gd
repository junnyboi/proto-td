extends RefCounted

## Test-only attempt-local aliases let the current operator-ID battle model
## represent three distinct Recruits without changing production identity code.
const OMITTED_RECRUIT := &"recruit_probe_b"


static func winner() -> Array:
	return [
		[6, &"deploy", &"recruit_probe_a", Vector2i(3, 2), 0],
		[180, &"deploy", &"recruit_probe_b", Vector2i(1, 2), 0],
		[420, &"deploy", &"recruit_probe_c", Vector2i(2, 2), 0],
	]


static func filtered_loser() -> Array:
	var result: Array = []
	for row: Array in winner():
		if row[2] != OMITTED_RECRUIT:
			result.append(row)
	return result
