class_name PromotionRulesDef
extends Resource

## Versioned, data-owned strategic promotion rules. Semantic IDs remain stable;
## localized labels and presentation stay outside the model contract.

@export var rules_version: int = 0
@export var source_class_id: StringName = &""
@export var xp_required: int = 0
@export var choices: Array[Dictionary] = []
