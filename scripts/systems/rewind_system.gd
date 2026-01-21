extends Node

# State snapshots and restoration system
# Saves game state at end of each turn for rewind functionality
#
# Enemies are never freed - just hidden when killed. This allows rewind to
# restore them by simply making them visible again and restoring their state.

signal state_saved
signal state_rewound

var history: Array[Dictionary] = []
const MAX_HISTORY := 50
var is_rewinding := false


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
		"enemies": {}
	}

	# Save ALL enemies that exist (including hidden/dead ones)
	var units_parent = get_tree().get_first_node_in_group("units_container")
	if units_parent:
		for child in units_parent.get_children():
			if child.is_in_group("enemies") and is_instance_valid(child):
				state.enemies[child.get_instance_id()] = {
					"ref": child,
					"coord": child.coord,
					"hp": child.hp,
					"alive": child.visible  # Track if enemy was alive at this point
				}

	history.append(state)
	if history.size() > MAX_HISTORY:
		history.pop_front()

	state_saved.emit()


func can_rewind() -> bool:
	return history.size() >= 2 and not is_rewinding


func rewind():
	if not can_rewind():
		return

	is_rewinding = true

	# Remove current state to get previous state
	history.pop_back()
	var state = history.back()

	var player = UnitRegistry.player
	if not player:
		is_rewinding = false
		return

	# Restore player state
	player.coord = state.player_coord
	player.hp = state.player_hp
	player.dash_cooldown = state.player_dash_cd
	player.block_cooldown = state.player_block_cd
	player.block_active = state.player_block_active
	player.position = HexGrid.to_world(state.player_coord)
	player.dash_mode = false

	# Clear current enemy registry - we'll rebuild it
	UnitRegistry.enemies.clear()

	# Restore all enemies from saved state
	for id in state.enemies:
		var e_data = state.enemies[id]
		var enemy = e_data.ref

		if not is_instance_valid(enemy):
			continue

		# Restore position and HP
		enemy.coord = e_data.coord
		enemy.hp = e_data.hp
		enemy.position = HexGrid.to_world(e_data.coord)
		enemy.scale = Vector3.ONE

		if e_data.alive:
			# Enemy was alive - make visible and re-enable
			enemy.visible = true
			enemy.set_process(true)
			enemy.set_physics_process(true)
			UnitRegistry.enemies.append(enemy)
		else:
			# Enemy was dead at this state - keep hidden
			enemy.visible = false
			enemy.set_process(false)
			enemy.set_physics_process(false)

	is_rewinding = false
	state_rewound.emit()


func reset():
	history.clear()
	is_rewinding = false
