extends GutTest

const FRAGMENT_ROOTS := [
	"res://assets/provenance/fragments/act2-shared",
	"res://assets/provenance/fragments/s2",
	"res://assets/provenance/fragments/s3",
]
const EXPECTED := {
	&"world.pressure.ground_calm": ["res://assets/world/act2-shared/ground-calm.png", "res://staging/assets/world/act2-shared/ground-calm.png", Vector2i(32, 16)],
	&"world.pressure.ground_runoff": ["res://assets/world/act2-shared/ground-runoff.png", "res://staging/assets/world/act2-shared/ground-runoff.png", Vector2i(32, 16)],
	&"world.pressure.route_plate": ["res://assets/world/act2-shared/route-plate.png", "res://staging/assets/world/act2-shared/route-plate.png", Vector2i(32, 16)],
	&"world.pressure.cadence_e": ["res://assets/world/act2-shared/cadence-e.png", "res://staging/assets/world/act2-shared/cadence-e.png", Vector2i(32, 16)],
	&"world.pressure.cadence_s": ["res://assets/world/act2-shared/cadence-s.png", "res://staging/assets/world/act2-shared/cadence-s.png", Vector2i(32, 16)],
	&"world.pressure.cadence_e_s": ["res://assets/world/act2-shared/cadence-e-s.png", "res://staging/assets/world/act2-shared/cadence-e-s.png", Vector2i(32, 16)],
	&"world.pressure.cadence_s_e": ["res://assets/world/act2-shared/cadence-s-e.png", "res://staging/assets/world/act2-shared/cadence-s-e.png", Vector2i(32, 16)],
	&"world.s2.elevated_manometer": ["res://assets/world/s2/elevated-manometer.png", "res://staging/assets/world/s2/elevated-manometer.png", Vector2i(32, 24)],
	&"world.s2.elevated_relief": ["res://assets/world/s2/elevated-relief.png", "res://staging/assets/world/s2/elevated-relief.png", Vector2i(32, 24)],
	&"world.s2.spawn_louver": ["res://assets/world/s2/spawn-louver.png", "res://staging/assets/world/s2/spawn-louver.png", Vector2i(32, 32)],
	&"world.s2.core_receiver": ["res://assets/world/s2/core-receiver.png", "res://staging/assets/world/s2/core-receiver.png", Vector2i(32, 32)],
	&"world.s2.backdrop_panorama": ["res://assets/world/s2/backdrop-panorama.png", "res://staging/assets/world/s2/backdrop-panorama.png", Vector2i(240, 120)],
	&"world.s3.elevated_assay": ["res://assets/world/s3/elevated-assay.png", "res://staging/assets/world/s3/elevated-assay.png", Vector2i(32, 24)],
	&"world.s3.blocked_regulator": ["res://assets/world/s3/blocked-regulator.png", "res://staging/assets/world/s3/blocked-regulator.png", Vector2i(32, 16)],
	&"world.s3.blocked_pressure_jaw": ["res://assets/world/s3/blocked-pressure-jaw.png", "res://staging/assets/world/s3/blocked-pressure-jaw.png", Vector2i(32, 16)],
	&"world.s3.spawn_rain_sluice": ["res://assets/world/s3/spawn-rain-sluice.png", "res://staging/assets/world/s3/spawn-rain-sluice.png", Vector2i(32, 32)],
	&"world.s3.core_pressure_keeper": ["res://assets/world/s3/core-pressure-keeper.png", "res://staging/assets/world/s3/core-pressure-keeper.png", Vector2i(32, 32)],
	&"world.s3.backdrop_panorama": ["res://assets/world/s3/backdrop-panorama.png", "res://staging/assets/world/s3/backdrop-panorama.png", Vector2i(256, 128)],
}

var base_manifest: AssetManifest
var candidate_manifest: AssetManifest
var fragments: Dictionary
var s2: StageDef
var s3: StageDef
var s2_theme: StageArtTheme
var s3_theme: StageArtTheme


func before_all() -> void:
	base_manifest = load("res://assets/manifest.tres") as AssetManifest
	candidate_manifest = load("res://assets/act2_candidate_manifest.tres") as AssetManifest
	fragments = _fragments_by_logical_id()
	s2 = load("res://data/stages/s2.tres") as StageDef
	s3 = load("res://data/stages/s3.tres") as StageDef
	s2_theme = load("res://data/presentation/s2_world_theme.tres") as StageArtTheme
	s3_theme = load("res://data/presentation/s3_world_theme.tres") as StageArtTheme
	Art._reset_manifests_for_test()


func test_base_and_supplement_are_valid_and_disjoint() -> void:
	assert_not_null(base_manifest)
	assert_not_null(candidate_manifest)
	assert_eq(base_manifest.validate_contract(), PackedStringArray())
	assert_eq(candidate_manifest.validate_contract(), PackedStringArray())
	assert_eq(candidate_manifest.schema_version, 2)
	assert_eq(candidate_manifest.entries.size(), 18)
	for id: StringName in candidate_manifest.entries:
		assert_false(base_manifest.entries.has(id), "duplicate across manifest layers: %s" % id)


func test_all_18_candidates_resolve_through_art_and_remain_placeholders() -> void:
	assert_eq(EXPECTED.size(), 18)
	assert_eq(fragments.size(), 18)
	for id: StringName in EXPECTED:
		var contract: Array = EXPECTED[id]
		assert_true(candidate_manifest.entries.has(id), "missing supplemental id: %s" % id)
		var entry: Dictionary = candidate_manifest.entries[id]
		assert_eq(String(entry["pattern"]), String(contract[0]), "%s pattern" % id)
		assert_eq(int(entry["frames"]), 1, "%s frames" % id)
		assert_eq(entry["size"], contract[2], "%s size" % id)
		assert_true(bool(entry["placeholder"]), "%s remains H1-pending" % id)
		assert_eq(Art.metadata(id), entry, "%s Art metadata" % id)
		assert_eq(Art.size(id), contract[2], "%s Art size" % id)
		assert_not_null(Art.texture(id), "%s texture" % id)
		assert_eq(FileAccess.get_sha256(contract[0]), FileAccess.get_sha256(contract[1]), "%s runtime/staging bytes" % id)
		assert_true(fragments.has(id), "%s candidate fragment" % id)
		assert_eq(String(entry["provenance_sha256"]), FileAccess.get_sha256(fragments[id]), "%s fragment binding" % id)


func test_real_candidate_themes_validate_and_remain_dormant() -> void:
	assert_not_null(s2_theme)
	assert_not_null(s3_theme)
	assert_eq(s2_theme.validation_errors(s2), PackedStringArray())
	assert_eq(s3_theme.validation_errors(s3), PackedStringArray())
	assert_eq(s2_theme.approval_token, &"ACT-II-S2-S3-H0")
	assert_eq(s3_theme.approval_token, &"ACT-II-S2-S3-H0")
	assert_false(s2_theme.human_final_art)
	assert_false(s3_theme.human_final_art)
	assert_eq(s2_theme.approval_manifest_sha256, "")
	assert_eq(s3_theme.approval_manifest_sha256, "")
	assert_eq(StageArtTheme.REQUIRED_THEME_STAGE_IDS, [&"s1"])
	for stage: StageDef in [s2, s3]:
		assert_false(StageArtTheme.expects_theme(stage))
		var resolver := func(path: String) -> Resource: return load(path)
		var result := StageArtTheme.resolve_for(stage, resolver)
		assert_false(bool(result["required"]))
		assert_null(result["theme"])
		assert_eq(String(result["error"]), "")


func test_duplicate_id_merge_fails_closed_without_repository_mutation() -> void:
	var base := {&"shared.id": {"layer": "base"}}
	var supplement := {&"shared.id": {"layer": "supplement"}, &"new.id": {}}
	var result := Art.merge_manifest_entries(base, supplement)
	assert_false(bool(result[&"ok"]))
	assert_eq(result[&"entries"], {})
	assert_eq(result[&"duplicate_id"], &"shared.id")
	assert_eq(base[&"shared.id"]["layer"], "base")


func _fragments_by_logical_id() -> Dictionary:
	var result: Dictionary = {}
	for root: String in FRAGMENT_ROOTS:
		var dir := DirAccess.open(root)
		assert_not_null(dir, "fragment root exists: %s" % root)
		if dir == null:
			continue
		dir.list_dir_begin()
		var name := dir.get_next()
		while not name.is_empty():
			if not dir.current_is_dir() and name.ends_with(".json"):
				var path := root.path_join(name)
				var file := FileAccess.open(path, FileAccess.READ)
				var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else null
				assert_true(parsed is Dictionary, "fragment parses: %s" % path)
				if parsed is Dictionary:
					var id := StringName(String(parsed.get("logical_id", "")))
					assert_false(result.has(id), "fragment logical_id unique: %s" % id)
					result[id] = path
			name = dir.get_next()
		dir.list_dir_end()
	return result
