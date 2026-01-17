extends Enemy

func get_threat_tiles() -> Array[Vector3i]:
	# Shoots in 6 hex directions (straight lines), range 2-5
	# Cannot shoot adjacent tiles (range starts at 2)
	var tiles: Array[Vector3i] = []
	for dir in HexGrid.DIRS:
		for dist in range(2, 6):
			tiles.append(coord + dir * dist)

	return tiles

func get_min_attack_range() -> int:
	return 2  # Can't attack adjacent tiles

func get_max_attack_range() -> int:
	return 5
