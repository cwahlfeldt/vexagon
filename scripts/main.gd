extends Node3D

@export var tile_scene: PackedScene
@export var player_scene: PackedScene
@export var grunt_scene: PackedScene
@export var wizard_scene: PackedScene
@export var sniper_scene: PackedScene

var level_config: Resource  # LevelConfig type

func _ready():
	# Get level config from autoload (will be available after project reload)
	if Engine.has_singleton("LevelManager") or has_node("/root/LevelManager"):
		var lm = get_node_or_null("/root/LevelManager")
		if lm:
			level_config = lm.get_current_level()
	setup_level()

func setup_level():
	Game.reset_state()
	clear_level()
	generate_grid()
	await spawn_units()
	Game.start_game()

func clear_level():
	# Clear existing tiles
	for child in $Board.get_children():
		child.queue_free()
	# Clear existing units (except player template if any)
	for child in $Units.get_children():
		child.queue_free()

func generate_grid():
	var board = $Board
	var map_size = level_config.map_size if level_config else 5
	var blocked_chance = level_config.blocked_tile_chance if level_config else 0.15

	for hex in HexGrid.in_range(Vector3i.ZERO, map_size):
		var tile = tile_scene.instantiate()
		tile.coord = hex
		tile.position = HexGrid.to_world(hex)
		board.add_child(tile)

		# Random blocked tiles (not at center)
		if randf() < blocked_chance and hex != Vector3i.ZERO:
			tile.walkable = false

func spawn_units():
	var units_parent = $Units
	var player_hp = level_config.player_hp if level_config else 3
	var min_spawn_dist = level_config.min_spawn_distance if level_config else 3

	# Spawn player at edge of map
	var player = player_scene.instantiate()
	units_parent.add_child(player)
	var map_size = level_config.map_size if level_config else 5
	player.coord = Vector3i(0, map_size, -map_size)
	player.position = HexGrid.to_world(player.coord)
	player.max_hp = player_hp
	player.hp = player_hp

	# Collect spawnable tiles
	await get_tree().process_frame  # Wait for tiles to be added to group
	var spawnable = []
	for tile in get_tree().get_nodes_in_group("tiles"):
		if tile.walkable and HexGrid.distance(tile.coord, player.coord) >= min_spawn_dist:
			spawnable.append(tile.coord)
	spawnable.shuffle()

	var spawn_index = 0
	var hp_bonus = level_config.enemy_hp_bonus if level_config else 0
	var damage_bonus = level_config.enemy_damage_bonus if level_config else 0

	# Spawn Grunts
	var grunt_count = level_config.grunt_count if level_config else 2
	for i in grunt_count:
		if spawn_index >= spawnable.size():
			break
		var enemy = grunt_scene.instantiate()
		units_parent.add_child(enemy)
		enemy.coord = spawnable[spawn_index]
		enemy.position = HexGrid.to_world(spawnable[spawn_index])
		enemy.max_hp += hp_bonus
		enemy.hp = enemy.max_hp
		enemy.damage += damage_bonus
		spawn_index += 1

	# Spawn Wizards
	var wizard_count = level_config.wizard_count if level_config else 0
	for i in wizard_count:
		if spawn_index >= spawnable.size():
			break
		var enemy = wizard_scene.instantiate()
		units_parent.add_child(enemy)
		enemy.coord = spawnable[spawn_index]
		enemy.position = HexGrid.to_world(spawnable[spawn_index])
		enemy.max_hp += hp_bonus
		enemy.hp = enemy.max_hp
		enemy.damage += damage_bonus
		spawn_index += 1

	# Spawn Snipers
	var sniper_count = level_config.sniper_count if level_config else 0
	var sniper_axes = level_config.sniper_axes if level_config else []
	for i in sniper_count:
		if spawn_index >= spawnable.size():
			break
		var enemy = sniper_scene.instantiate()
		units_parent.add_child(enemy)
		enemy.coord = spawnable[spawn_index]
		enemy.position = HexGrid.to_world(spawnable[spawn_index])
		enemy.max_hp += hp_bonus
		enemy.hp = enemy.max_hp
		enemy.damage += damage_bonus
		# Assign axis if specified
		if i < sniper_axes.size():
			enemy.axis = sniper_axes[i]
		else:
			enemy.axis = i % 3  # Cycle through axes
		spawn_index += 1

func advance_to_next_level():
	var lm = get_node_or_null("/root/LevelManager")
	if lm and lm.advance_level():
		level_config = lm.get_current_level()
		await setup_level()
	else:
		print("=== ALL LEVELS COMPLETE! ===")

func restart_current_level():
	await setup_level()
