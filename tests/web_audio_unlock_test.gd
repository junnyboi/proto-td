extends SceneTree

const EXPORT_PRESETS_PATH := "res://export_presets.cfg"
const SFX_CATALOG_PATH := "res://assets/sfx/catalog.tres"
const REQUIRED_UNLOCK_TOKENS := [
	"window.AudioContext=Wrapped",
	"window.__protosAudioContexts=contexts",
	"context.state==='suspended'",
	"context.resume()",
	"['pointerdown','touchstart','keydown']",
	"visibilitychange",
]
const REQUIRED_SFX_ALIASES := {
	&"kill": &"operator_select",
	&"wave": &"placement_ready",
	&"bastion_slam": &"ability_ready",
	&"conflagration": &"ability_ready",
	&"deadeye": &"ability_ready",
	&"flurry": &"ability_ready",
	&"hold_the_line": &"ability_ready",
	&"mend": &"ability_ready",
	&"overpower": &"ability_ready",
	&"rally": &"ability_ready",
	&"rapid_volley": &"ability_ready",
	&"tempest": &"ability_ready",
	&"war_banner": &"ability_ready",
}

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var preset_text := FileAccess.get_file_as_string(EXPORT_PRESETS_PATH)
	_check(not preset_text.is_empty(), "Web export preset is unavailable")
	for token: String in REQUIRED_UNLOCK_TOKENS:
		_check(preset_text.contains(token), "Web Audio unlock token is missing: %s" % token)
	_check(
		int(ProjectSettings.get_setting("audio/general/default_playback_type", -1))
			== AudioServer.PLAYBACK_TYPE_STREAM,
		"project audio does not force the direct streaming mixer",
	)
	var music := root.get_node_or_null("Music")
	var sfx := root.get_node_or_null("Sfx")
	_check(music != null and sfx != null, "audio autoloads are unavailable")
	if music != null:
		for player_value: Variant in music.call("_ensure_players"):
			var player := player_value as AudioStreamPlayer
			_check(
				player != null and player.playback_type == AudioServer.PLAYBACK_TYPE_STREAM,
				"music player can fall back to the Web sample graph",
			)
	if sfx != null:
		for child: Node in sfx.get_children():
			if child is AudioStreamPlayer:
				_check(
					(child as AudioStreamPlayer).playback_type
						== AudioServer.PLAYBACK_TYPE_STREAM,
					"SFX voice can fall back to the Web sample graph",
				)
	var catalog := load(SFX_CATALOG_PATH) as Resource
	_check(catalog != null, "SFX catalog is unavailable")
	var aliases_value: Variant = catalog.get("aliases") if catalog != null else null
	_check(aliases_value is Dictionary, "SFX aliases are unavailable")
	if aliases_value is Dictionary:
		var aliases: Dictionary = aliases_value
		for semantic_id: StringName in REQUIRED_SFX_ALIASES:
			_check(
				aliases.get(semantic_id, &"") == REQUIRED_SFX_ALIASES[semantic_id],
				"%s is not routed to an audible shipped cue" % semantic_id,
			)
	if _failures.is_empty():
		print("WEB_AUDIO_UNLOCK_TEST_OK")
		quit(0)
		return
	for failure: String in _failures:
		push_error(failure)
	quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
