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


func test_navigation_does_not_call_nullable_global_music_identifier() -> void:
	var source := FileAccess.get_file_as_string(GAME_PATH)
	assert_false(source.is_empty())
	assert_false(source.contains("Music.stop()"))
	assert_true(source.contains('get_node_or_null("/root/Music")'))
