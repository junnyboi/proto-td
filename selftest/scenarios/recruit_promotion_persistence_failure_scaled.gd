extends RefCounted

const VariantSupportType := preload("res://selftest/recruit_promotion_variant_support.gd")


func run(h: SelfTestHarness) -> void:
	h.expect_done()
	h.max_frames = 3200
	await VariantSupportType.new().run_failure(h, &"scaled")
	print("RECRUIT_PROMOTION_PERSISTENCE_FAILURE_SCALED_COMPLETED")
	h.done()
