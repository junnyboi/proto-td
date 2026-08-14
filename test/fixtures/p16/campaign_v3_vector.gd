extends SceneTree

const ContextScript := preload("res://test/fixtures/p16/campaign_v3_context.gd")
const MIGRATED_SHA256 := "2c87014e626af106e514434358f3c3148a9baa1e6da7f6c88718654d8b1101d5"
const MIGRATED_HASH := "4160b69281d05165"
const FRESH_SHA256 := "a43eb6ca96e9b5c0004aa1527caa1f023e3aaf007fc1545c95485c1760e52c3c"
const FRESH_HASH := "b62636c0071a53c4"


func _initialize() -> void:
	var context := ContextScript.build()
	var source := FileAccess.get_file_as_string(
		"res://test/fixtures/p16/campaign_v2_seed42.json"
	)
	var migrated := CampaignCodec.decode_save(source, context)
	var fresh := CampaignV3Codec.create_fresh(42, 1, context)
	var encoded_fresh := CampaignV3Codec.encode_save(fresh.get("value"), context)
	for result: Dictionary in [migrated, fresh, encoded_fresh]:
		if not result.get("accepted", false):
			printerr("CAMPAIGN_V3_VECTOR_FAIL=%s" % result.get("error_code", &""))
			quit(1)
			return
	var migrated_hash: String = CampaignV3Hash.of_data(migrated["data"], context)["hex"]
	var fresh_hash: String = CampaignV3Hash.of_data(fresh["value"], context)["hex"]
	if (
		migrated["sha256"] != MIGRATED_SHA256
		or migrated_hash != MIGRATED_HASH
		or encoded_fresh["sha256"] != FRESH_SHA256
		or fresh_hash != FRESH_HASH
		or encoded_fresh["text"] != FileAccess.get_file_as_string(
			"res://test/fixtures/p16/campaign_v3_fresh_seed42.json"
		)
	):
		printerr("CAMPAIGN_V3_VECTOR_FAIL=sentinel_mismatch")
		quit(1)
		return
	print("CAMPAIGN_V3_MIGRATED_SHA256=%s" % migrated["sha256"])
	print("CAMPAIGN_V3_MIGRATED_HASH=%s" % migrated_hash)
	print("CAMPAIGN_V3_FRESH_SHA256=%s" % encoded_fresh["sha256"])
	print("CAMPAIGN_V3_FRESH_HASH=%s" % fresh_hash)
	print("CAMPAIGN_V3_VECTOR_OK")
	quit(0)
