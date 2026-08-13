extends GutTest

const GAME_SCRIPT := preload("res://autoloads/game.gd")
const GAME_PATH := "res://autoloads/game.gd"

var game: Node = null


class MusicStub:
	extends Node

	var stop_calls := 0

	func stop() -> bool:
		stop_calls += 1
		return true


class SelfPublishingCandidate:
	extends Node

	var game_ref: Node = null

	func _ready() -> void:
		game_ref.set("content", self)


func before_each() -> void:
	game = GAME_SCRIPT.new()
	add_child_autoqfree(game)


func test_missing_music_never_blocks_content_navigation() -> void:
	assert_false(game.call("_stop_music_node", null))


func test_node_without_stop_never_blocks_content_navigation() -> void:
	var incompatible := Node.new()
	add_child_autoqfree(incompatible)
	assert_false(game.call("_stop_music_node", incompatible))


func test_available_music_receives_exactly_one_stop() -> void:
	var music := MusicStub.new()
	add_child_autoqfree(music)
	assert_true(game.call("_stop_music_node", music))
	assert_eq(music.stop_calls, 1)


func test_captured_predecessor_retires_after_candidate_self_publication() -> void:
	var previous := Node.new()
	add_child(previous)
	game.set("content", previous)
	var candidate := SelfPublishingCandidate.new()
	candidate.game_ref = game
	add_child(candidate)
	assert_eq(game.get("content"), candidate, "candidate self-published during ready")
	assert_true(bool(game.call("_accept_content_candidate", candidate, false, previous)))
	assert_eq(game.get("content"), candidate)
	assert_null(previous.get_parent(), "captured predecessor retired synchronously")
	assert_true(previous.is_queued_for_deletion())
	candidate.queue_free()


func test_navigation_does_not_call_nullable_global_music_identifier() -> void:
	var source := FileAccess.get_file_as_string(GAME_PATH)
	assert_false(source.is_empty())
	assert_false(source.contains("Music.stop()"))
	assert_true(source.contains('get_node_or_null("/root/Music")'))
