extends Node

const SIZE := 1.05

const DIRS := [
	Vector3i(1, -1, 0), Vector3i(1, 0, -1), Vector3i(0, 1, -1),
	Vector3i(-1, 1, 0), Vector3i(-1, 0, 1), Vector3i(0, -1, 1)
]

func to_world(hex: Vector3i) -> Vector3:
	var x = SIZE * 1.5 * hex.x
	var z = SIZE * sqrt(3) * (hex.y + hex.x / 2.0)
	return Vector3(x, 0, z)

func neighbors(hex: Vector3i) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	for d in DIRS:
		result.append(hex + d)
	return result

func distance(a: Vector3i, b: Vector3i) -> int:
	return (abs(a.x - b.x) + abs(a.y - b.y) + abs(a.z - b.z)) / 2

func in_range(center: Vector3i, radius: int) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	for q in range(-radius, radius + 1):
		for r in range(max(-radius, -q - radius), min(radius, -q + radius) + 1):
			var s = -q - r
			result.append(center + Vector3i(q, r, s))
	return result

func line(from: Vector3i, dir: Vector3i, length: int) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	for i in range(1, length + 1):
		result.append(from + dir * i)
	return result
