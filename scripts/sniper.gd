extends Enemy

@export var axis := 0  # 0=Q, 1=R, 2=S

func get_threat_tiles() -> Array[Vector3i]:
	var tiles: Array[Vector3i] = []
	var dir1: Vector3i
	var dir2: Vector3i

	match axis:
		0: dir1 = Vector3i(1, -1, 0); dir2 = Vector3i(-1, 1, 0)
		1: dir1 = Vector3i(0, 1, -1); dir2 = Vector3i(0, -1, 1)
		2: dir1 = Vector3i(1, 0, -1); dir2 = Vector3i(-1, 0, 1)

	for dist in range(2, 6):
		tiles.append(coord + dir1 * dist)
		tiles.append(coord + dir2 * dist)

	return tiles

func get_min_attack_range() -> int:
	return 2  # Can't attack adjacent tiles

func get_max_attack_range() -> int:
	return 5
