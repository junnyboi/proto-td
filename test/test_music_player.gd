extends GutTest

const MusicScript := preload("res://autoloads/music.gd")
const S1 := preload("res://data/stages/s1.tres")
const S5 := preload("res://data/stages/s5.tres")

var music: Node = null


func before_each() -> void:
	music = MusicScript.new()
	music.name = "TestMusic"
	add_child_autoqfree(music)
	assert_true(music.call("reload_catalog"))


func test_controller_owns_one_player_and_duplicate_cue_is_no_op() -> void:
	var stage := S1 as StageDef
	assert_true(music.call("play_stage_bgm", stage))
	assert_eq(music.call("current_id"), &"act_1_bgm")
	assert_eq(int(music.call("player_count")), 1)
	assert_eq(int(music.call("start_count")), 1)
	assert_eq(int(music.call("stop_count")), 0)
	var first_stream := String(music.call("current_stream_path"))
	assert_true(music.call("play_stage_bgm", stage), "duplicate request remains valid")
	assert_eq(music.call("current_id"), &"act_1_bgm")
	assert_eq(String(music.call("current_stream_path")), first_stream)
	assert_eq(int(music.call("start_count")), 1, "duplicate request never calls play again")
	assert_eq(int(music.call("stop_count")), 0, "duplicate request never stops")
	assert_eq(int(music.call("player_count")), 1, "duplicate request never adds a player")


func test_different_cue_hard_replaces_on_same_player() -> void:
	var stage := S1 as StageDef
	assert_true(music.call("play_stage_bgm", stage))
	assert_true(music.call("play_stage_boss", stage))
	assert_eq(music.call("current_id"), &"act_1_boss")
	assert_eq(int(music.call("start_count")), 2)
	assert_eq(int(music.call("stop_count")), 1, "old cue stopped before replacement")
	assert_eq(int(music.call("player_count")), 1, "replacement reuses the sole player")
	assert_true(
		String(music.call("current_stream_path")).ends_with("act_1_guild_threshold_boss.ogg")
	)


func test_invalid_request_rejects_with_zero_controller_state_change() -> void:
	var stage := S5 as StageDef
	assert_true(music.call("play_stage_bgm", stage))
	var before := [
		music.call("current_id"),
		music.call("current_stream_path"),
		music.call("start_count"),
		music.call("stop_count"),
		music.call("player_count"),
	]
	assert_false(music.call("play_cue", &"missing"))
	var after := [
		music.call("current_id"),
		music.call("current_stream_path"),
		music.call("start_count"),
		music.call("stop_count"),
		music.call("player_count"),
	]
	assert_eq(after, before)


func test_stop_is_idempotent_and_clears_the_stream_once() -> void:
	var stage := S5 as StageDef
	assert_true(music.call("play_stage_bgm", stage))
	assert_true(music.call("stop"))
	assert_false(music.call("stop"))
	assert_eq(music.call("current_id"), &"")
	assert_eq(String(music.call("current_stream_path")), "")
	assert_eq(int(music.call("start_count")), 1)
	assert_eq(int(music.call("stop_count")), 1)
	assert_eq(int(music.call("player_count")), 1)


func test_stage_data_routes_current_acts_and_final_wave_bosses() -> void:
	var expected := {
		&"s1": [1, -1],
		&"s2": [1, -1],
		&"s3": [1, -1],
		&"s4": [1, 1],
		&"s5": [2, -1],
		&"s6": [2, -1],
		&"s7": [2, -1],
		&"s8": [2, 2],
	}
	for stage_id: StringName in expected:
		var stage := load("res://data/stages/%s.tres" % stage_id) as StageDef
		assert_not_null(stage)
		assert_eq(stage.music_act, int(expected[stage_id][0]), "%s act" % stage_id)
		assert_eq(
			stage.music_boss_wave_index,
			int(expected[stage_id][1]),
			"%s boss wave" % stage_id,
		)
	var future := StageDef.new()
	future.music_act = 3
	assert_true(music.call("play_stage_bgm", future))
	assert_eq(music.call("current_id"), &"act_3_bgm")
	assert_true(music.call("play_stage_boss", future))
	assert_eq(music.call("current_id"), &"act_3_boss")
	assert_eq(int(music.call("player_count")), 1)


func test_s8_sync_holds_bgm_then_switches_to_boss_once() -> void:
	var stage := load("res://data/stages/s8.tres") as StageDef
	assert_true(music.call("sync_stage_wave", stage, 0))
	assert_eq(music.call("current_id"), &"act_2_bgm")
	assert_eq(int(music.call("start_count")), 1)
	assert_true(music.call("sync_stage_wave", stage, 1))
	assert_eq(music.call("current_id"), &"act_2_bgm")
	assert_eq(int(music.call("start_count")), 1, "wave 1 does not restart BGM")
	assert_true(music.call("sync_stage_wave", stage, 2))
	assert_eq(music.call("current_id"), &"act_2_boss")
	assert_eq(int(music.call("start_count")), 2)
	assert_true(music.call("sync_stage_wave", stage, 2))
	assert_eq(int(music.call("start_count")), 2, "boss request does not restart")
	assert_eq(int(music.call("player_count")), 1)
