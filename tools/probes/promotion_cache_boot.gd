extends SceneTree

## Loads the player-facing Training screen and its promotion command dependency by
## explicit path while the caller supplies a class registry from before
## CampaignProgression existed. This script must not use project class_name types.

const TRAINING_SCRIPT_PATH := "res://scripts/ui/training.gd"
const PROMOTION_SCRIPT_PATH := "res://sim/campaign_promotion.gd"


func _initialize() -> void:
	var promotion_script := load(PROMOTION_SCRIPT_PATH) as Script
	if promotion_script == null or not promotion_script.can_instantiate():
		_fail("CampaignPromotion script unavailable")
		return
	var training_script := load(TRAINING_SCRIPT_PATH) as Script
	if training_script == null or not training_script.can_instantiate():
		_fail("Training script unavailable")
		return
	var command_id := String(
		(
			promotion_script
			. call(
				"command_id",
				"campaign",
				7,
				"0123456789abcdef",
				"sorcerer",
			)
		)
	)
	if command_id != "promote:campaign:7:0123456789abcdef:sorcerer":
		_fail("promotion command seam changed")
		return
	print("[PROMOTION-CACHE-BOOT] PASS training=ready promotion=ready")
	quit(0)


func _fail(detail: String) -> void:
	push_error("[PROMOTION-CACHE-BOOT] FAIL: %s" % detail)
	quit(1)
