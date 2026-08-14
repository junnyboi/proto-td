class_name CampaignDef
extends Resource

## P16 strategic campaign bootstrap data. Runtime model code owns no starter,
## economy, or paid-offer tuning values.

const P16_ENVIRONMENT_SHA256 := \
	"693c3f42b492bde75c14940c1068d8a6e7ae551aa694d8551d5a49e26bdd9156"

@export var schema_version: int = 2
@export var name_version: int = 1
@export var initial_marks: int = 0
@export var starter_operator_ids: Array[StringName] = []
@export var paid_offers: Array[Dictionary] = []
@export var environment_sha256: String = ""
