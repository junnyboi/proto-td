extends SceneTree

const LoaderType := preload("res://autoloads/content_pack_loader.gd")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_argument_contract()
	_test_resource_routing()
	_test_predictive_class_order()
	_test_network_policy()
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
	_check(
		LoaderType.pack_id_for_class("sword_saint") == "operator-sword-saint",
		"advanced class id did not route to its pack",
	)
	_check(LoaderType.pack_id_for_class("recruit").is_empty(), "Recruit class routed to a pack")


func _test_predictive_class_order() -> void:
	var roster: Array = [
		{"hero_id": "h1", "current_class_id": "swordmaster"},
		{"hero_id": "h2", "current_class_id": "defender"},
		{"hero_id": "h3", "current_class_id": "gunner"},
		{"hero_id": "h4", "current_class_id": "sorcerer"},
		{"hero_id": "h5", "current_class_id": "recruit"},
	]
	var predicted: Array[String] = LoaderType.predictive_class_order(roster, ["h3", "h2"])
	_check(
		predicted == ["gunner", "defender", "swordmaster"],
		"selected squad classes did not lead the bounded roster prediction",
	)
	_check(
		LoaderType.predictive_class_order(roster, [], 2) == ["swordmaster", "defender"],
		"roster prediction did not honor its class horizon",
	)


func _test_network_policy() -> void:
	_check(
		LoaderType.network_profile_from_arguments(PackedStringArray(["--network-profile=slow"])) == &"slow",
		"valid slow network profile did not parse",
	)
	_check(
		LoaderType.network_profile_from_arguments(PackedStringArray(["--network-profile=warp"])) == &"standard",
		"unknown network profile did not fall back safely",
	)
	_check(
		LoaderType.prefetch_limits_for_profile(&"constrained") == {
			&"classes": 0, &"resonance": 0, &"missions": 0,
		},
		"constrained network did not suppress speculative downloads",
	)
	_check(
		LoaderType.prefetch_limits_for_profile(&"slow")[&"classes"] == 1
		and LoaderType.prefetch_limits_for_profile(&"standard")[&"classes"] == 2
		and LoaderType.prefetch_limits_for_profile(&"fast")[&"classes"] == 3,
		"adaptive class horizons are not monotonic",
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
	var digest := "b".repeat(64)
	loader.call("reset_for_tests")
	loader.call("configure", PackedStringArray([
		"--network-profile=slow",
		"--content-pack=operator-swordmaster|https://cdn.example/swordmaster.zip|2048|%s" % digest,
		"--content-pack=operator-defender|https://cdn.example/defender.zip|2048|%s" % digest,
	]))
	_check(loader.call("network_profile") == &"slow", "autoload did not retain the slow network profile")
	_check(int(loader.call("background_class_limit")) == 1, "slow network did not cap class prefetch at one")
	var resonance_prefetch := root.get_node_or_null("CinematicPrefetch")
	var mission_prefetch := root.get_node_or_null("MissionCinematicPrefetch")
	_check(
		resonance_prefetch != null and int(resonance_prefetch.call("background_prefetch_limit")) == 0,
		"slow profile did not suppress speculative Resonance films",
	)
	_check(
		mission_prefetch != null and int(mission_prefetch.call("background_prefetch_limit")) == 0,
		"slow profile did not suppress speculative mission films",
	)
	loader.call("configure", PackedStringArray(["--network-profile=fast"]))
	_check(
		int(loader.call("background_class_limit")) == 3
		and int(resonance_prefetch.call("background_prefetch_limit")) == 6
		and int(mission_prefetch.call("background_prefetch_limit")) == 6,
		"live fast profile did not expand all speculative horizons",
	)
	loader.call("configure", PackedStringArray(["--network-profile=slow"]))
	var slow_requested: Array = loader.call(
		"prefetch_class_ids", ["swordmaster", "defender"], false,
	)
	_check(slow_requested == ["operator-swordmaster"], "slow network queued more than one predicted class")
	loader.call("set_background_downloads_enabled", false)
	_check(loader.call("queued_pack_ids").is_empty(), "metered preference did not clear speculative class work")
	_check(not bool(loader.call("request_class", "defender", true)), "disabled background policy accepted class prediction")
	_check(
		not bool(loader.call("request_class", "defender", true, false))
		and loader.call("queued_pack_ids") == ["operator-defender"],
		"foreground class request did not bypass the background preference",
	)
	loader.call("reset_for_tests")
	loader.call("configure", PackedStringArray([
		"--content-pack=operator-swordmaster|https://cdn.example/swordmaster.zip|2048|%s" % digest,
		"--content-pack=operator-defender|https://cdn.example/defender.zip|2048|%s" % digest,
		"--content-pack=operator-gunner|https://cdn.example/gunner.zip|2048|%s" % digest,
		"--content-pack=unknown|https://cdn.example/unknown.zip|2048|%s" % digest,
	]))
	_check(int(loader.call("configured_pack_count")) == 3, "autoload accepted an unknown content pack")
	_check(loader.call("request_resource", "res://project.godot"), "existing core resource did not resolve immediately")
	var requested: Array = loader.call(
		"prefetch_class_ids", ["swordmaster", "recruit", "defender", "swordmaster"], false,
	)
	_check(
		requested == ["operator-swordmaster", "operator-defender"],
		"class prefetch did not filter and deduplicate pack ids",
	)
	_check(
		loader.call("queued_pack_ids") == ["operator-swordmaster", "operator-defender"],
		"background prefetch queue did not preserve prediction order",
	)
	loader.call("request_class", "defender", true)
	_check(
		loader.call("queued_pack_ids") == ["operator-defender", "operator-swordmaster"],
		"prioritized speculative class intent did not reorder the queued pack",
	)
	loader.call("reset_for_tests")


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
