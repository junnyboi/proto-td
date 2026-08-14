class_name CampaignDef
extends Resource

## P16 strategic campaign bootstrap data. Runtime model code owns no starter,
## economy, or paid-offer tuning values.

const P16_ENVIRONMENT_SHA256 := \
		"766d1404bfa53e650cc419c49fde338eb20334611b49a19cd095a789f6f525b5"
const P16_V3_ENVIRONMENT_SHA256 := \
		"35e93197fc1af7ea861354ab95079a575937118e6a97488bfb3c78abf90b7feb"

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
