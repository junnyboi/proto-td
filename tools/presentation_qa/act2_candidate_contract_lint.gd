extends SceneTree

const BASE_MANIFEST_PATH := "res://assets/manifest.tres"
const CANDIDATE_MANIFEST_PATH := "res://assets/act2_candidate_manifest.tres"
const FRAGMENT_ROOTS := [
	"res://assets/provenance/fragments/act2-shared",
	"res://assets/provenance/fragments/s2",
	"res://assets/provenance/fragments/s3",
]
const APPROVAL_TOKEN := "ACT-II-S2-S3-H0"
const PENDING_STATE := "CANDIDATE_MACHINE_CONFORMANT_H1_PENDING"
const RESERVED := [Color8(244, 244, 244), Color8(65, 166, 246)]
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

var _errors := PackedStringArray()


func _initialize() -> void:
	var base := load(BASE_MANIFEST_PATH) as AssetManifest
	var candidate := load(CANDIDATE_MANIFEST_PATH) as AssetManifest
	if base == null:
		_fail("base manifest failed to load")
	if candidate == null:
		_fail("candidate manifest failed to load")
	if base != null:
		for detail: String in base.validate_contract():
			_fail("base manifest.%s" % detail)
	if candidate != null:
		for detail: String in candidate.validate_contract():
			_fail("candidate manifest.%s" % detail)
	if base != null and candidate != null:
		_validate_disjoint(base, candidate)
		_validate_inventory(candidate)
		_validate_fragments(candidate)
	_validate_themes()
	if _errors.is_empty():
		print("ACT2_CANDIDATE_CONTRACT_OK")
		quit(0)
		return
	for detail: String in _errors:
		push_error("[act2_candidate_contract] %s" % detail)
	quit(1)


func _validate_disjoint(base: AssetManifest, candidate: AssetManifest) -> void:
	for id: Variant in candidate.entries:
		if base.entries.has(id):
			_fail("duplicate manifest id: %s" % id)


func _validate_inventory(candidate: AssetManifest) -> void:
	if candidate.entries.size() != 18 or EXPECTED.size() != 18:
		_fail("candidate inventory must contain exactly 18 entries")
	for id: Variant in candidate.entries:
		if not EXPECTED.has(id):
			_fail("unexpected candidate manifest id: %s" % id)
	for id: StringName in EXPECTED:
		if not candidate.entries.has(id):
			_fail("missing candidate manifest id: %s" % id)
			continue
		var expected: Array = EXPECTED[id]
		var entry: Dictionary = candidate.entries[id]
		if String(entry.get("pattern", "")) != String(expected[0]):
			_fail("pattern mismatch: %s" % id)
		if entry.get("size") != expected[2]:
			_fail("size mismatch: %s" % id)
		if int(entry.get("frames", 0)) != 1:
			_fail("frames mismatch: %s" % id)
		if not bool(entry.get("placeholder", false)):
			_fail("candidate must remain placeholder: %s" % id)
		var texture := load(expected[0]) as Texture2D
		if texture == null:
			_fail("imported texture failed to load: %s" % id)
		elif texture.get_size() != Vector2(expected[2]):
			_fail("imported texture size mismatch: %s" % id)
		if Art.size(id) != expected[2] or Art.texture(id) == null:
			_fail("Art did not resolve candidate: %s" % id)
		if FileAccess.get_sha256(expected[0]) != FileAccess.get_sha256(expected[1]):
			_fail("runtime/staging PNG bytes differ: %s" % id)
		_validate_image(expected[0], id, expected[2])


func _validate_fragments(candidate: AssetManifest) -> void:
	var by_id: Dictionary = {}
	var file_count := 0
	for root: String in FRAGMENT_ROOTS:
		var dir := DirAccess.open(root)
		if dir == null:
			_fail("missing fragment root: %s" % root)
			continue
		dir.list_dir_begin()
		var name := dir.get_next()
		while not name.is_empty():
			if not dir.current_is_dir() and name.ends_with(".json"):
				file_count += 1
				var path := root.path_join(name)
				var data := _read_json(path)
				var id := StringName(String(data.get("logical_id", "")))
				if id == &"":
					_fail("fragment missing logical_id: %s" % path)
				elif by_id.has(id):
					_fail("duplicate fragment logical_id: %s" % id)
				else:
					by_id[id] = path
					_validate_fragment_truth(id, path, data)
			name = dir.get_next()
		dir.list_dir_end()
	if file_count != 18 or by_id.size() != 18:
		_fail("fragment inventory must contain exactly 18 unique logical IDs")
	for id: Variant in by_id:
		if not EXPECTED.has(id):
			_fail("extra fragment logical_id: %s" % id)
	for id: StringName in EXPECTED:
		if not by_id.has(id):
			_fail("missing fragment logical_id: %s" % id)
		elif candidate.entries.has(id):
			var digest := FileAccess.get_sha256(by_id[id])
			if String(candidate.entries[id].get("provenance_sha256", "")) != digest:
				_fail("fragment provenance digest mismatch: %s" % id)


func _validate_fragment_truth(id: StringName, path: String, data: Dictionary) -> void:
	if not EXPECTED.has(id):
		return
	if String(data.get("state", "")) != PENDING_STATE:
		_fail("fragment state is not H1 pending: %s" % id)
	if bool(data.get("human_final_art", true)):
		_fail("fragment claims human final art: %s" % id)
	var approval: Dictionary = data.get("approval", {})
	if String(approval.get("token", "")) != APPROVAL_TOKEN:
		_fail("fragment approval token mismatch: %s" % id)
	if bool(approval.get("human_final_art", false)):
		_fail("fragment approval claims human final art: %s" % id)
	if approval.has("approved_content_hash_launch_dependency") and bool(approval["approved_content_hash_launch_dependency"]):
		_fail("fragment launch dependency is enabled: %s" % id)
	if approval.has("approved_content_hash_gates_launch") and bool(approval["approved_content_hash_gates_launch"]):
		_fail("fragment hash gates launch: %s" % id)
	if approval.has("phase") and String(approval["phase"]) != "H0":
		_fail("fragment phase is not H0: %s" % id)
	if approval.has("h1_required") and not bool(approval["h1_required"]):
		_fail("fragment does not require H1: %s" % id)
	var expected: Array = EXPECTED[id]
	var runtime := ""
	var staging := ""
	var recorded_sha := ""
	if data.has("candidate_files"):
		var files: Dictionary = data["candidate_files"]
		runtime = "res://" + String(files.get("runtime", ""))
		staging = "res://" + String(files.get("staging", ""))
		recorded_sha = String(files.get("sha256", ""))
		if not bool(files.get("bytes_identical", false)):
			_fail("fragment does not attest identical bytes: %s" % id)
	else:
		runtime = "res://" + String(data.get("final_file", ""))
		staging = "res://" + String(data.get("staged_file", ""))
		recorded_sha = String(data.get("final_file_sha256", ""))
	if runtime != expected[0] or staging != expected[1]:
		_fail("fragment path contract mismatch: %s (%s)" % [id, path])
	if recorded_sha != FileAccess.get_sha256(expected[0]):
		_fail("fragment PNG digest mismatch: %s" % id)


func _validate_image(path: String, id: StringName, expected_size: Vector2i) -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null or image.is_empty():
		_fail("PNG failed to decode: %s" % id)
		return
	if image.get_size() != expected_size:
		_fail("PNG size mismatch: %s" % id)
	for y: int in image.get_height():
		for x: int in image.get_width():
			var pixel := image.get_pixel(x, y)
			if pixel.a > 0.0 and (pixel.is_equal_approx(RESERVED[0]) or pixel.is_equal_approx(RESERVED[1])):
				_fail("reserved color present: %s" % id)
				return


func _validate_themes() -> void:
	if StageArtTheme.REQUIRED_THEME_STAGE_IDS != [&"s1"]:
		_fail("dormant required stage inventory changed")
	for stage_id: String in ["s2", "s3"]:
		var stage := load("res://data/stages/%s.tres" % stage_id) as StageDef
		var theme := load("res://data/presentation/%s_world_theme.tres" % stage_id) as StageArtTheme
		if stage == null or theme == null:
			_fail("failed to load real %s stage/theme" % stage_id)
			continue
		for detail: String in theme.validation_errors(stage):
			_fail("%s theme.%s" % [stage_id, detail])
		if theme.human_final_art:
			_fail("%s theme claims human final art" % stage_id)
		if theme.approval_token != &"ACT-II-S2-S3-H0":
			_fail("%s theme approval token mismatch" % stage_id)
		if not String(theme.approval_manifest_sha256).is_empty():
			_fail("%s theme has a hash launch gate" % stage_id)
		if StageArtTheme.expects_theme(stage):
			_fail("%s theme is not dormant" % stage_id)


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_fail("failed to open JSON: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is not Dictionary:
		_fail("failed to parse JSON object: %s" % path)
		return {}
	return parsed


func _fail(detail: String) -> void:
	_errors.append(detail)
