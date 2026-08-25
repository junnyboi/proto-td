extends SceneTree

const ACT_TRACKS := {
	1: [
		"res://assets/music/act_1_guild_threshold_bgm.ogg",
		"res://assets/music/act_1_guild_threshold_boss.ogg",
	],
	2: [
		"res://assets/music/act_2_twilight_grotto_bgm.ogg",
		"res://assets/music/act_2_twilight_grotto_boss.ogg",
	],
	3: [
		"res://assets/music/act_3_abyssal_vault_bgm.ogg",
		"res://assets/music/act_3_abyssal_vault_boss.ogg",
	],
}

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var output_dir := _output_dir()
	var output_absolute := ProjectSettings.globalize_path(output_dir)
	if DirAccess.make_dir_recursive_absolute(output_absolute) != OK:
		_fail("cannot create output directory: %s" % output_dir)
		_finish()
		return
	for act: int in ACT_TRACKS:
		_build_act_pack(act, output_dir.path_join("music-act-%d.pck" % act))
	_finish()


func _build_act_pack(act: int, output_path: String) -> void:
	var packer := PCKPacker.new()
	var start_error := packer.pck_start(ProjectSettings.globalize_path(output_path))
	if start_error != OK:
		_fail("act %d pck_start failed: %d" % [act, start_error])
		return
	for value: Variant in ACT_TRACKS[act]:
		var source_path := String(value)
		var import_path := source_path + ".import"
		var config := ConfigFile.new()
		var config_error := config.load(import_path)
		if config_error != OK:
			_fail("act %d cannot read %s: %d" % [act, import_path, config_error])
			return
		var imported_path := String(config.get_value("remap", "path", ""))
		if imported_path.is_empty():
			_fail("act %d import has no remap path: %s" % [act, import_path])
			return
		if packer.add_file(import_path, ProjectSettings.globalize_path(import_path)) != OK:
			_fail("act %d cannot add import metadata: %s" % [act, import_path])
			return
		if packer.add_file(imported_path, ProjectSettings.globalize_path(imported_path)) != OK:
			_fail("act %d cannot add imported stream: %s" % [act, imported_path])
			return
	var flush_error := packer.flush()
	if flush_error != OK:
		_fail("act %d flush failed: %d" % [act, flush_error])
		return
	print(
		"MUSIC_PACK act=%d path=%s bytes=%d sha256=%s" % [
			act,
			output_path,
			FileAccess.get_size(output_path),
			FileAccess.get_sha256(output_path),
		]
	)


func _output_dir() -> String:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			return argument.trim_prefix("--output=")
	return "res://build/web/packs"


func _fail(message: String) -> void:
	_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("MUSIC_PACK_BUILD_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)
