extends SceneTree

const ContextScript := preload("res://test/fixtures/p16/campaign_v3_context.gd")
const MIGRATED_SHA256 := "81beccb348423bb83e431a4a94428c24f17872754add45ae4d51aa5dd7d347da"
const MIGRATED_HASH := "da67f175d2ae8950"
const FRESH_SHA256 := "e348483cceee4651c697f323ad4db56dce5fedcd0c33f7551a36b5f35a9aff56"
const FRESH_HASH := "bf4a5c25be2b0efd"


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
