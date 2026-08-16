extends RefCounted

const VariantSupportType := preload("res://selftest/recruit_promotion_variant_support.gd")


func run(h: SelfTestHarness) -> void:
	h.expect_done()
	h.max_frames = 2600
	await VariantSupportType.new().run_flow(h, &"scaled")
	print("RECRUIT_PROMOTION_FLOW_SCALED_COMPLETED")
	h.done()
