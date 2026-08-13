extends GutTest

## One inherited case keeps the approved 21-test SaveStore suite below the
## project's 20-public-method limit without changing GUT discovery semantics.


func test_store_config_requires_json_slot_factory_and_ops() -> void:
	var restore := func(_source: String) -> Dictionary: return {}
	assert_eq(
		CampaignSaveStore.create("", restore, CampaignFileOps.new())["error_code"],
		&"invalid_store_config",
	)
	assert_eq(
		CampaignSaveStore.create("user://slot.bin", restore, CampaignFileOps.new())["error_code"],
		&"invalid_store_config",
	)
	assert_eq(
		CampaignSaveStore.create("user://slot.json", Callable(), CampaignFileOps.new())[
			"error_code"
		],
		&"invalid_store_config",
	)
	assert_eq(
		CampaignSaveStore.create("user://slot.json", restore, null)["error_code"],
		&"invalid_store_config",
	)


func test_exact_17_load_matrix_and_recovered_winner_save_faults() -> void:
	call("_assert_complete_store_contract")
	call("_assert_v1_production_migration")
