class_name CampaignDef
extends Resource

## P16 strategic campaign bootstrap data. Runtime model code owns no starter,
## economy, or paid-offer tuning values.

const P16_ENVIRONMENT_SHA256 := \
	"766d1404bfa53e650cc419c49fde338eb20334611b49a19cd095a789f6f525b5"

@export var schema_version: int = 2
@export var name_version: int = 1
@export var initial_marks: int = 0
@export var starter_operator_ids: Array[StringName] = []
@export var paid_offers: Array[Dictionary] = []
@export var environment_sha256: String = ""
