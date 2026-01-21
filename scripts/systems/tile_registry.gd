extends Node

# Central registry for hex tiles

var tiles: Dictionary = {} # Vector3i -> HexTile

func register_tile(tile):
	tiles[tile.coord] = tile

func get_tile(coord: Vector3i) -> Node:
	return tiles.get(coord)

func is_coord_blocked(coord: Vector3i) -> bool:
	var tile = tiles.get(coord)
	if not tile or not tile.walkable:
		return true

	# Check if player is there
	if UnitRegistry.player and UnitRegistry.player.coord == coord:
		return true

	# Check if any enemy is there
	for e in UnitRegistry.enemies:
		if is_instance_valid(e) and e.coord == coord:
			return true

	return false

func clear():
	tiles.clear()
