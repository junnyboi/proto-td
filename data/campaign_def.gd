class_name CampaignDef
extends Resource

## P16 strategic campaign bootstrap data. Runtime model code owns no starter,
## economy, or paid-offer tuning values.

const P16_ENVIRONMENT_SHA256 := \
	"cf4a272e5aa14a2c8606a6aa6de8efb8345af37d10c82ecf2e579987f7fdb8b6"

@export var schema_version: int = 1
@export var name_version: int = 1
@export var initial_marks: int = 0
@export var starter_operator_ids: Array[StringName] = []
@export var paid_offers: Array[Dictionary] = []
@export var environment_sha256: String = ""
