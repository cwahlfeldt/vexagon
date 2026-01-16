extends Node

signal turn_started(unit)
signal player_died
signal enemy_died(enemy)

var player: Node3D
var enemies: Array[Node3D] = []
var tiles: Dictionary = {}  # Vector3i -> HexTile

var current_unit = null
var is_player_turn := true
var history: Array[Dictionary] = []  # For rewind

func _ready():
	pass

# Called after scene loads
func start_game():
	player = get_tree().get_first_node_in_group("player")
	var enemy_nodes = get_tree().get_nodes_in_group("enemies")
	enemies.clear()
	for e in enemy_nodes:
		enemies.append(e as Node3D)

	for tile in get_tree().get_nodes_in_group("tiles"):
		tiles[tile.coord] = tile

	save_state()
	start_player_turn()

func start_player_turn():
	is_player_turn = true
	player.start_turn()
	turn_started.emit(player)

func end_player_turn():
	is_player_turn = false
	await do_enemy_turns()
	save_state()
	start_player_turn()

func do_enemy_turns():
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		await enemy.take_turn()
		await get_tree().create_timer(0.2).timeout

func get_tile(coord: Vector3i) -> Node:
	return tiles.get(coord)

func is_tile_blocked(coord: Vector3i) -> bool:
	var tile = tiles.get(coord)
	if not tile or not tile.walkable:
		return true
	# Check if unit is there
	if player.coord == coord:
		return true
	for e in enemies:
		if is_instance_valid(e) and e.coord == coord:
			return true
	return false

func get_enemy_at(coord: Vector3i) -> Node3D:
	for e in enemies:
		if is_instance_valid(e) and e.coord == coord:
			return e
	return null

func remove_enemy(enemy):
	enemies.erase(enemy)
	enemy_died.emit(enemy)
	enemy.queue_free()

# === REWIND ===
func save_state():
	var state = {
		"player_coord": player.coord,
		"player_hp": player.hp,
		"player_dash_cd": player.dash_cooldown,
		"player_block_cd": player.block_cooldown,
		"player_block_active": player.block_active,
		"enemies": []
	}
	for e in enemies:
		if is_instance_valid(e):
			state.enemies.append({
				"scene": e.scene_file_path,
				"coord": e.coord,
				"hp": e.hp
			})
	history.append(state)
	if history.size() > 50:
		history.pop_front()

func rewind():
	if history.size() < 2:
		return
	if not is_instance_valid(player):
		return

	history.pop_back()  # Remove current
	var state = history.back()

	# Restore player
	player.coord = state.player_coord
	player.hp = state.player_hp
	player.dash_cooldown = state.player_dash_cd
	player.block_cooldown = state.player_block_cd
	player.block_active = state.player_block_active
	player.position = HexGrid.to_world(state.player_coord)
	player.dash_mode = false

	# Clear enemies
	for e in enemies:
		if is_instance_valid(e):
			e.queue_free()
	enemies.clear()

	# Wait for nodes to be freed
	await get_tree().process_frame
	await get_tree().process_frame

	# Respawn enemies
	var units_parent = get_tree().get_first_node_in_group("units_container")
	if not units_parent:
		print("Error: units_container not found")
		return

	for e_data in state.enemies:
		var scene = load(e_data.scene)
		if not scene:
			print("Error: Could not load enemy scene: ", e_data.scene)
			continue
		var enemy = scene.instantiate()
		units_parent.add_child(enemy)
		enemy.coord = e_data.coord
		enemy.hp = e_data.hp
		enemy.position = HexGrid.to_world(e_data.coord)
		enemies.append(enemy)

	start_player_turn()
