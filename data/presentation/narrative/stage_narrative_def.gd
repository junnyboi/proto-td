class_name StageNarrativeDef
extends Resource

enum Field {
	OBJECTIVE,
	THREAT,
	HUMAN_REASON,
	CLUE,
	CORE_SERVICE,
	CLEAR_DEBRIEF,
	DEFEAT_DEBRIEF,
	TRANSMISSION_SPEAKER,
	TRANSMISSION,
}

@export var id: StringName = &""
@export_multiline var objective: String = ""
@export_multiline var threat: String = ""
@export_multiline var human_reason: String = ""
@export_multiline var clue: String = ""
@export_multiline var core_service: String = ""
@export_multiline var clear_debrief: String = ""
@export_multiline var defeat_debrief: String = ""
@export var transmission_speaker: String = ""
@export_multiline var transmission: String = ""


func validate_contract() -> PackedStringArray:
	var errors := PackedStringArray()
	if String(id).strip_edges().is_empty():
		errors.append("id: blank")
	for field: Field in [
		Field.OBJECTIVE, Field.THREAT, Field.HUMAN_REASON, Field.CLUE,
		Field.CORE_SERVICE, Field.CLEAR_DEBRIEF, Field.DEFEAT_DEBRIEF,
		Field.TRANSMISSION_SPEAKER, Field.TRANSMISSION,
	]:
		if fallback_for(field).strip_edges().is_empty():
			errors.append("%s: blank" % field_slug(field))
	return errors


func fallback_for(field: Field) -> String:
	match field:
		Field.OBJECTIVE:
			return objective
		Field.THREAT:
			return threat
		Field.HUMAN_REASON:
			return human_reason
		Field.CLUE:
			return clue
		Field.CORE_SERVICE:
			return core_service
		Field.CLEAR_DEBRIEF:
			return clear_debrief
		Field.DEFEAT_DEBRIEF:
			return defeat_debrief
		Field.TRANSMISSION_SPEAKER:
			return transmission_speaker
		Field.TRANSMISSION:
			return transmission
	push_error("StageNarrativeDef.fallback_for: invalid field %s" % field)
	return ""


func field_slug(field: Field) -> StringName:
	match field:
		Field.OBJECTIVE:
			return &"objective"
		Field.THREAT:
			return &"threat"
		Field.HUMAN_REASON:
			return &"human_reason"
		Field.CLUE:
			return &"clue"
		Field.CORE_SERVICE:
			return &"core_service"
		Field.CLEAR_DEBRIEF:
			return &"clear_debrief"
		Field.DEFEAT_DEBRIEF:
			return &"defeat_debrief"
		Field.TRANSMISSION_SPEAKER:
			return &"transmission_speaker"
		Field.TRANSMISSION:
			return &"transmission"
	push_error("StageNarrativeDef.field_slug: invalid field %s" % field)
	return &""
