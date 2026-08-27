extends SceneTree

const TEST_TIMEOUT_SECONDS := 20.0
const ArtType := preload("res://scripts/view/art.gd")

const PREMIUM := {
	"archive_caster": &"portrait_archive_caster",
	"lunaris_vessel": &"portrait_lunaris_vessel",
	"reliquary_duelist": &"portrait_reliquary_duelist",
}

var _failures: Array[String] = []
var _finished := false


func _init() -> void:
	create_timer(TEST_TIMEOUT_SECONDS).timeout.connect(_on_timeout)
	call_deferred("_run")


func _run() -> void:
	var manifest := load("res://assets/manifest.tres")
	_check(manifest != null, "asset manifest did not load")
	if manifest != null:
		var diagnostics: PackedStringArray = manifest.call("validate_contract")
		_check(diagnostics.is_empty(), "asset manifest contract failed: %s" % diagnostics)

	var campaign = load("res://data/campaigns/p16_v3.tres")
	_check(campaign != null, "campaign definition did not load")
	var premium_rows: Array = campaign.premium_hero_rows if campaign != null else []
	_check(premium_rows.size() == PREMIUM.size(), "premium campaign pool no longer has three heroes")
	var campaign_portraits := {}
	for raw_row: Variant in premium_rows:
		if raw_row is Dictionary:
			var row := raw_row as Dictionary
			campaign_portraits[String(row.get("premium_id", ""))] = StringName(
				row.get("portrait_asset_id", "")
			)

	for premium_id: String in PREMIUM:
		var asset_id := PREMIUM[premium_id] as StringName
		var fullsize_id := StringName("portrait_%s_fullsize" % premium_id)
		var runtime_path := "res://assets/portraits/premium/%s.png" % premium_id
		var fullsize_path := "res://assets/portraits/fullsize/%s_fullsize.webp" % premium_id
		_check(
			campaign_portraits.get(premium_id, &"") == asset_id,
			"campaign portrait ID drifted for %s" % premium_id,
		)
		_check_portrait(asset_id, runtime_path, Vector2i(512, 512), true)
		_check_portrait(fullsize_id, fullsize_path, Vector2i(640, 800), false)
		_check(
			FileAccess.file_exists("res://docs/portraits/premium/sources/%s.png" % premium_id),
			"immutable GPT Image 2 source is missing for %s" % premium_id,
		)

	for legacy_name: String in [
		"archive_caster_premium.png",
		"lunaris_vessel_premium.png",
		"reliquary_duelist_premium.png",
	]:
		_check(
			not FileAccess.file_exists("res://assets/portraits/%s" % legacy_name),
			"obsolete premium runtime portrait remains: %s" % legacy_name,
		)

	_finish()


func _check_portrait(
		asset_id: StringName,
		expected_path: String,
		expected_size: Vector2i,
		png: bool,
	) -> void:
	var metadata := ArtType.metadata(asset_id)
	_check(not metadata.is_empty(), "manifest metadata missing for %s" % asset_id)
	_check(String(metadata.get("pattern", "")) == expected_path, "manifest path mismatch for %s" % asset_id)
	_check(metadata.get("placeholder", true) == false, "portrait stayed placeholder: %s" % asset_id)
	_check(ArtType.size(asset_id) == expected_size, "manifest size changed for %s" % asset_id)
	_check(ArtType.texture(asset_id) != null, "portrait texture did not load: %s" % asset_id)
	_check(FileAccess.file_exists(expected_path), "portrait file missing: %s" % expected_path)
	if not FileAccess.file_exists(expected_path):
		return
	var image := Image.new()
	var bytes := FileAccess.get_file_as_bytes(expected_path)
	var load_error := (
		image.load_png_from_buffer(bytes) if png else image.load_webp_from_buffer(bytes)
	)
	_check(load_error == OK and not image.is_empty(), "portrait image failed to decode: %s" % asset_id)
	if load_error == OK and not image.is_empty():
		_check(image.get_size() == expected_size, "decoded portrait size changed for %s" % asset_id)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _on_timeout() -> void:
	if _finished:
		return
	_failures.append("test timed out")
	_finish()


func _finish() -> void:
	if _finished:
		return
	_finished = true
	if _failures.is_empty():
		print("PREMIUM_PORTRAIT_CATALOG_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error("premium_portrait_catalog_test: %s" % failure)
	quit(1)
