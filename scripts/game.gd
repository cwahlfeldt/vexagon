extends Node

signal turn_started(unit)
signal player_died
signal enemy_died(enemy)
signal game_won
signal game_lost

# Delegating properties to registries
var player: Node3D:
	get: return UnitRegistry.player
var enemies: Array[Node3D]:
	get: return UnitRegistry.enemies
var tiles: Dictionary:
	get: return TileRegistry.tiles
var is_player_turn: bool:
	get: return TurnSystem.is_player_turn

var current_unit = null

# Game state
var game_over := false

func _ready():
	randomize() # useful for initial random setup
	pass

func reset_state():
	# Reset all game state for a new level
	game_over = false
	TurnSystem.reset()
	RewindSystem.reset()
	UnitRegistry.clear()
	TileRegistry.clear()
	current_unit = null

# Called after scene loads
func start_game():
	# Populate registries
	var player_node = get_tree().get_first_node_in_group("player")
	UnitRegistry.register_player(player_node)

	var enemy_nodes = get_tree().get_nodes_in_group("enemies")
	for e in enemy_nodes:
		UnitRegistry.register_enemy(e as Node3D)

	for tile in get_tree().get_nodes_in_group("tiles"):
		TileRegistry.register_tile(tile)

	RewindSystem.save_state()
	start_player_turn()

func start_player_turn():
	if game_over:
		return

	TurnSystem.start_player_turn()

	player.start_turn()
	turn_started.emit(player)
	player.player_idle_animation()


func end_player_turn():
	if game_over:
		return

	TurnSystem.end_player_turn()

	# Check for victory (all enemies dead)
	if check_victory():
		return

	await do_enemy_turns()
	RewindSystem.save_state()
	start_player_turn()

func check_victory() -> bool:
	# Count valid enemies
	var alive_count := 0
	for e in enemies:
		if is_instance_valid(e):
			alive_count += 1

	if alive_count == 0:
		game_over = true
		game_won.emit()
		print("=== VICTORY! All enemies defeated! ===")
		return true
	return false

func trigger_defeat():
	if game_over:
		return
	game_over = true
	game_lost.emit()
	print("=== DEFEAT! Player has fallen! ===")
	player_died.emit()

func do_enemy_turns():
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		await enemy.take_turn()
		await get_tree().create_timer(0.2).timeout

func get_tile(coord: Vector3i) -> Node:
	return TileRegistry.get_tile(coord)

func is_tile_blocked(coord: Vector3i) -> bool:
	return TileRegistry.is_coord_blocked(coord)

func get_enemy_at(coord: Vector3i) -> Node3D:
	return UnitRegistry.get_enemy_at(coord)

func remove_enemy(enemy):
	UnitRegistry.remove_enemy(enemy)
	enemy_died.emit(enemy)
	enemy.queue_free()

# === REWIND DELEGATION ===
func can_rewind() -> bool:
	return RewindSystem.can_rewind()

func rewind():
	if not can_rewind():
		return

	# Reset game over state (allows rewinding from defeat)
	game_over = false

	await RewindSystem.rewind()
	start_player_turn()
