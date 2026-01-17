extends Enemy

func get_threat_tiles() -> Array[Vector3i]:
	# Diagonal lines in all 6 directions, range 2-5
	var tiles: Array[Vector3i] = []
	for dir in HexGrid.DIRS:
		for dist in range(2, 6):
			tiles.append(coord + dir * dist)

	# Debug output
	if tiles.size() > 0:
		print("Wizard at ", coord, " has threat tiles: ", tiles)

	return tiles
