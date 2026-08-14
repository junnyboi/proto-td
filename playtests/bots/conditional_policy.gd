class_name ConditionalPolicy
extends RefCounted


func decide(_observation: Dictionary) -> Dictionary:
	return {"action": [], "reason": "idle", "considered_candidates": []}
