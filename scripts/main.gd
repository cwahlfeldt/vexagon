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
	player.coord = Vector3i.ZERO
	player.position = HexGrid.to_world(Vector3i.ZERO)

	# Position enemies randomly
	var spawnable = []
	for tile in get_tree().get_nodes_in_group("tiles"):
		if tile.walkable and HexGrid.distance(tile.coord, Vector3i.ZERO) > 2:
			spawnable.append(tile.coord)
	spawnable.shuffle()

	var i := 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if i < spawnable.size():
			enemy.coord = spawnable[i]
			enemy.position = HexGrid.to_world(spawnable[i])
			i += 1
