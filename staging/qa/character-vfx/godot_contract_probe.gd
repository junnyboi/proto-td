extends SceneTree

const Pipeline = preload("res://tools/art_pipeline/character_vfx/godot/pipeline.gd")
const PixelOps = preload("res://tools/art_pipeline/character_vfx/godot/pixel_ops.gd")

var _checks := 0


func _require(condition: bool, detail: String) -> void:
	_checks += 1
	if not condition:
		print(JSON.stringify({"status": "FAIL", "detail": detail}, "", true, true))
		quit(2)


func _salvage_byte_contract() -> void:
	var root := ProjectSettings.globalize_path(
		"res://.godot/aui34-salvage-contract-%d" % OS.get_process_id()
	)
	var salvage := "%s.rollback-salvage.json" % root
	_require(not DirAccess.dir_exists_absolute(root), "probe root already exists")
	_require(not FileAccess.file_exists(salvage), "probe salvage already exists")
	_require(DirAccess.make_dir_recursive_absolute(root) == OK, "probe root create failed")
	var binary := PackedByteArray([0, 255, 10, 13, 128, 65])
	var handle := FileAccess.open(root.path_join("binary.bin"), FileAccess.WRITE)
	_require(handle != null, "probe binary open failed")
	if handle == null:
		return
	handle.store_buffer(binary)
	handle.close()
	var expected_base64 := "AP8KDYBB"
	_require(
		Marshalls.raw_to_base64(binary) == expected_base64,
		"probe fixture base64 mismatch"
	)
	var expected_text := (
		'{"entries":[{"data_base64":"%s","path":"binary.bin",'
		+ '"type":"file"}],"schema_version":1}\n'
	) % expected_base64
	var expected := expected_text.to_utf8_buffer()
	var write_result := Pipeline._write_salvage(root, salvage)
	_require(bool(write_result["ok"]), "probe salvage write failed")
	var actual := FileAccess.get_file_as_bytes(salvage)
	_require(actual.size() > 0, "probe salvage readback empty")
	_require(actual == expected, "probe salvage raw bytes differ")
	_require(Pipeline._remove_tree(root) == OK, "probe root cleanup failed")
	_require(DirAccess.remove_absolute(salvage) == OK, "probe salvage cleanup failed")


func _initialize() -> void:
	_salvage_byte_contract()
	var actual := Engine.get_version_info()
	_require(bool(Pipeline.check_backend_version(actual)["ok"]), "actual version rejected")
	for pair: Array in [
		["major", 5], ["minor", 8], ["patch", 2], ["status", "dev"],
		["build", "custom"], ["string", "4.7.1-stable (custom)"]
	]:
		var mismatched := actual.duplicate()
		mismatched[pair[0]] = pair[1]
		var result := Pipeline.check_backend_version(mismatched)
		_require(not bool(result["ok"]), "version mismatch accepted field=%s" % pair[0])
		_require("backend.version" in String(result["detail"]), "version detail missing")
	var nearest_cases: Array[Array] = [
		[1, 1, [0]],
		[1, 9, [0, 0, 0, 0, 0, 0, 0, 0, 0]],
		[9, 1, [0]],
		[2, 3, [0, 0, 1]],
		[3, 2, [0, 1]],
		[4, 7, [0, 0, 1, 1, 2, 2, 3]],
		[7, 4, [0, 1, 3, 5]],
	]
	for test_case: Array in nearest_cases:
		var measured: Array[int] = []
		for index: int in range((test_case[2] as Array).size()):
			measured.append(PixelOps.nearest_source_index(index, test_case[0], test_case[1]))
		_require(measured == test_case[2], "nearest mismatch case=%s" % [test_case])
	for test_case: Array in [
		[0, 0, 0, 0], [255, 255, 255, 255], [255, 0, 0, 77],
		[0, 255, 0, 149], [0, 0, 255, 29], [27, 34, 48, 33]
	]:
		_require(
			PixelOps.grayscale(test_case[0], test_case[1], test_case[2]) == test_case[3],
			"grayscale mismatch case=%s" % [test_case]
		)
	for test_case: Array in [[0, 1, 0], [1, 2, 1], [95, 97, 96], [96, 96, 96]]:
		_require(
			PixelOps.integer_midpoint(test_case[0], test_case[1]) == test_case[2],
			"midpoint mismatch case=%s" % [test_case]
		)
	print(JSON.stringify({"status": "PASS", "checks_executed": _checks}, "", true, true))
	quit(0)
