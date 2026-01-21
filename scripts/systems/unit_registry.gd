extends Node

# Central registry for player and enemies

signal enemy_removed(enemy)

var player: Node3D
var enemies: Array[Node3D] = []

func register_player(p: Node3D):
	player = p

func register_enemy(e: Node3D):
	if not enemies.has(e):
		enemies.append(e)

func remove_enemy(e: Node3D):
	enemies.erase(e)
	enemy_removed.emit(e)

func get_enemy_at(coord: Vector3i) -> Node3D:
	for e in enemies:
		if is_instance_valid(e) and e.coord == coord:
			return e
	return null

func get_valid_enemies() -> Array[Node3D]:
	var valid: Array[Node3D] = []
	for e in enemies:
		if is_instance_valid(e):
			valid.append(e)
	return valid

func clear():
	player = null
	enemies.clear()
