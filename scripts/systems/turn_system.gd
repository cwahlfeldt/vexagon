extends Node

# Turn state transitions and sequencing

signal player_turn_started
signal player_turn_ended
signal enemy_turns_completed

var is_player_turn: bool = true

func start_player_turn():
	is_player_turn = true
	player_turn_started.emit()

func end_player_turn():
	is_player_turn = false
	player_turn_ended.emit()

func process_enemy_turns():
	# Signal that enemy turns have completed
	# Actual enemy turn logic is handled by Game.do_enemy_turns()
	await get_tree().process_frame
	enemy_turns_completed.emit()

func reset():
	is_player_turn = true
