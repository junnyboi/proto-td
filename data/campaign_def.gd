class_name CampaignDef
extends Resource

## P16 strategic campaign bootstrap data. Runtime model code owns no starter,
## economy, or paid-offer tuning values.

const P16_ENVIRONMENT_SHA256 := \
	"b0188079cc71f817bdc05383258a14238c5f65e3327b7bc7830ec548deaf5835"

@export var schema_version: int = 2
@export var name_version: int = 1
@export var initial_marks: int = 0
@export var starter_operator_ids: Array[StringName] = []
@export var paid_offers: Array[Dictionary] = []
@export var environment_sha256: String = ""
