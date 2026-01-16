extends Node3D

@export var tile_scene: PackedScene
@export var map_size := 5

func _ready():
	generate_grid()
	position_units()
	Game.start_game()

func generate_grid():
	var board = $Board
	for hex in HexGrid.in_range(Vector3i.ZERO, map_size):
		var tile = tile_scene.instantiate()
		tile.coord = hex
		tile.position = HexGrid.to_world(hex)
		board.add_child(tile)

		# Random blocked tiles
		if randf() < 0.15 and hex != Vector3i.ZERO:
			tile.walkable = false
			# Swap to water mesh or whatever

func position_units():
	var player = $Units/Player
	player.coord = Vector3i(0, 5, -5)
	player.position = HexGrid.to_world(Vector3i(0, 5, -5))

	# Position enemies randomly
	var spawnable = []
	for tile in get_tree().get_nodes_in_group("tiles"):
		if tile.walkable and HexGrid.distance(tile.coord, player.coord) > 2:
			spawnable.append(tile.coord)
	spawnable.shuffle()

	var occupied_tiles = [player.coord]  # Track occupied positions

	for enemy in get_tree().get_nodes_in_group("enemies"):
		# Find first unoccupied spawnable position
		for spawn_coord in spawnable:
			if spawn_coord not in occupied_tiles:
				enemy.coord = spawn_coord
				enemy.position = HexGrid.to_world(spawn_coord)
				occupied_tiles.append(spawn_coord)
				break
