class_name CampaignDef
extends Resource

## P16 strategic campaign bootstrap data. Runtime model code owns no starter,
## economy, or paid-offer tuning values.

const P16_ENVIRONMENT_SHA256 := \
	"693c3f42b492bde75c14940c1068d8a6e7ae551aa694d8551d5a49e26bdd9156"
const P16_V3_ENVIRONMENT_SHA256 := \
		"c8707ad886034a045eec9fdf85264a20898359e6b5802de874f93a9832a81480"

@export var schema_version: int = 2
@export var name_version: int = 1
@export var initial_marks: int = 0
@export var starter_operator_ids: Array[StringName] = []
@export var paid_offers: Array[Dictionary] = []
@export var environment_sha256: String = ""
## CampaignSave v3 additions. V1/v2 resources omit these fields and retain
## their exact legacy semantics.
@export var starter_rows: Array[Dictionary] = []
@export var starting_class_ids: Array[StringName] = []
@export var stage_class_entitlements: Array[Dictionary] = []
@export var v3_stage_rewards: Array[Dictionary] = []
@export var portrait_asset_ids: Array[StringName] = []
## Premium hero pool additions. Legacy resources keep the zero/empty defaults.
@export var premium_pull_cost: int = 0
@export var premium_hero_rows: Array[Dictionary] = []
