class_name NarrativeArchiveUnlocks
extends RefCounted


static func record_unlocked(required_stage: int, stage_stars: Dictionary) -> bool:
	return required_stage <= 0 or stage_stars.has(StringName("s%d" % required_stage))
