extends Node

# State snapshots and restoration system

signal state_saved
signal state_rewound

var history: Array[Dictionary] = []
const MAX_HISTORY := 50

func save_state():
	var player = UnitRegistry.player
	if not player:
		return

	var state = {
		"player_coord": player.coord,
		"player_hp": player.hp,
		"player_dash_cd": player.dash_cooldown,
		"player_block_cd": player.block_cooldown,
		"player_block_active": player.block_active,
		"enemies": []
	}

	for e in UnitRegistry.enemies:
		if is_instance_valid(e):
			state.enemies.append({
				"scene": e.scene_file_path,
				"coord": e.coord,
				"hp": e.hp
			})

	history.append(state)
	if history.size() > MAX_HISTORY:
		history.pop_front()

	state_saved.emit()

func can_rewind() -> bool:
	return history.size() >= 2

func rewind():
	if not can_rewind():
		return

	history.pop_back() # Remove current state
	var state = history.back()

	var player = UnitRegistry.player
	if not player:
		return

	# Restore player
	player.coord = state.player_coord
	player.hp = state.player_hp
	player.dash_cooldown = state.player_dash_cd
	player.block_cooldown = state.player_block_cd
	player.block_active = state.player_block_active
	player.position = HexGrid.to_world(state.player_coord)
	player.dash_mode = false

	# Clear enemies
	for e in UnitRegistry.enemies:
		if is_instance_valid(e):
			e.queue_free()
	UnitRegistry.enemies.clear()

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
		UnitRegistry.register_enemy(enemy)

	state_rewound.emit()

func reset():
	history.clear()
