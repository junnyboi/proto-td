extends SceneTree

const LoaderType := preload("res://autoloads/content_pack_loader.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_argument_contract()
	_test_resource_routing()
	_test_export_boundary()
	_test_autoload_contract()
	if _failures.is_empty():
		print("WEB_CONTENT_PACK_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)


func _test_argument_contract() -> void:
	var digest := "a".repeat(64)
	var valid := LoaderType.parse_argument(
		"--content-pack=operator-swordmaster|https://cdn.example/swordmaster.zip|1234|%s" % digest
	)
	_check(valid.get(&"id") == "operator-swordmaster", "valid pack id did not parse")
	_check(valid.get(&"bytes") == 1234, "valid pack bytes did not parse")
	_check(valid.get(&"sha256") == digest, "valid pack digest did not parse")
	for invalid: String in [
		"--content-pack=unknown|https://cdn.example/a.zip|1234|%s" % digest,
		"--content-pack=operator-swordmaster|ftp://cdn.example/a.zip|1234|%s" % digest,
		"--content-pack=operator-swordmaster|https://cdn.example/a.zip|0|%s" % digest,
		"--content-pack=operator-swordmaster|https://cdn.example/a.zip|1234|abc",
	]:
		_check(LoaderType.parse_argument(invalid).is_empty(), "invalid content-pack argument was accepted")
	_check(LoaderType.valid_pack_ids().size() == 11, "expected exact 11 advanced-operator content pack ids")


func _test_resource_routing() -> void:
	_check(
		LoaderType.pack_id_for_resource("res://assets/enemy-variants/breacher_attack_ne.webp").is_empty(),
		"retired enemy variant path must not route to a runtime pack",
	)
	_check(
		LoaderType.pack_id_for_resource("res://assets/sprites/enemies/static/breacher.png").is_empty(),
		"core static enemy path must not route to a runtime pack",
	)
	_check(
		LoaderType.pack_id_for_resource("res://assets/sprites/operators/animated/sword_saint/female/idle_ne.webp") == "operator-sword-saint",
		"advanced operator path did not route to class pack",
	)
	_check(
		LoaderType.pack_id_for_resource("res://assets/sprites/operators/animated/lunaris_vessel/idle_ne.webp").is_empty(),
		"premium atlas was incorrectly routed out of the core pack",
	)
	_check(
		LoaderType.pack_id_for_resource("res://assets/sprites/operators/animated/recruit_female/idle_ne.webp").is_empty(),
		"Recruit atlas was incorrectly routed out of the core pack",
	)


func _test_export_boundary() -> void:
	var file := FileAccess.open("res://export_presets.cfg", FileAccess.READ)
	_check(file != null, "export preset is unreadable")
	if file == null:
		return
	var source := file.get_as_text()
	file.close()
	_check(source.contains("assets/enemy-variants/*.webp"), "enemy variant core exclusion is missing")
	_check(not source.contains("assets/sprites/enemies/static"), "core static enemy sprites leaked into Web exclusions")
	for class_id: String in LoaderType.ADVANCED_CLASSES:
		var pattern := "assets/sprites/operators/animated/%s/*/*.webp" % class_id
		_check(source.contains(pattern), "advanced core exclusion is missing: %s" % pattern)
	_check(source.contains("assets/cinematics/gacha/video/*.ogv"), "cinematic core exclusion regressed")
	_check(not source.contains("lunaris_vessel/*/*.webp"), "premium atlas leaked into exclusions")
	_check(not source.contains("recruit_female/*/*.webp"), "Recruit atlas leaked into exclusions")


func _test_autoload_contract() -> void:
	var loader := root.get_node_or_null("ContentPacks")
	_check(loader != null, "ContentPacks autoload is missing")
	if loader == null:
		return
	loader.call("reset_for_tests")
	var digest := "b".repeat(64)
	loader.call("configure", PackedStringArray([
		"--content-pack=operator-swordmaster|https://cdn.example/swordmaster.zip|2048|%s" % digest,
		"--content-pack=unknown|https://cdn.example/unknown.zip|2048|%s" % digest,
	]))
	_check(int(loader.call("configured_pack_count")) == 1, "autoload accepted an unknown content pack")
	_check(loader.call("request_resource", "res://project.godot"), "existing core resource did not resolve immediately")
	loader.call("reset_for_tests")


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
