extends Node3D
class_name Enemy

@export var max_hp := 1
@export var damage := 1
@export var attack_range := 1  # For melee enemies

var coord: Vector3i
var hp: int
var hover_area: Area3D

func _ready():
	add_to_group("enemies")
	hp = max_hp
	setup_hover_detection()

func setup_hover_detection():
	# Create an Area3D for hover detection
	hover_area = Area3D.new()
	add_child(hover_area)

	# Create collision shape
	var collision = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = 0.5
	shape.height = 1.5
	collision.shape = shape
	hover_area.add_child(collision)

	# Connect signals
	hover_area.mouse_entered.connect(_on_mouse_entered)
	hover_area.mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
	highlight_threat_tiles(true)

func _on_mouse_exited():
	highlight_threat_tiles(false)

func highlight_threat_tiles(on: bool):
	var threat_tiles = get_threat_tiles()
	for tile_coord in threat_tiles:
		var tile = Game.get_tile(tile_coord)
		if tile:
			if on:
				tile.set_highlight(true, Color(1.0, 0.3, 0.3, 0.5))  # Red highlight
			else:
				tile.set_highlight(false)

# Override in subclasses for different patterns
func get_threat_tiles() -> Array[Vector3i]:
	return HexGrid.neighbors(coord)

func dominates(target_coord: Vector3i) -> bool:
	return target_coord in get_threat_tiles()

func take_turn():
	var player = Game.player
	var dist = HexGrid.distance(coord, player.coord)

	if dominates(player.coord):
		# Player in range - wait (Hoplite style)
		pass
	else:
		# Move toward player
		await move_toward_tile(player.coord)

func move_toward_tile(target: Vector3i):
	var best_tile = coord
	var best_dist = HexGrid.distance(coord, target)

	for neighbor in HexGrid.neighbors(coord):
		if Game.is_tile_blocked(neighbor):
			continue
		var d = HexGrid.distance(neighbor, target)
		if d < best_dist:
			best_dist = d
			best_tile = neighbor

	if best_tile != coord:
		coord = best_tile
		var tween = create_tween()
		tween.tween_property(self, "position", HexGrid.to_world(best_tile), 0.25)
		await tween.finished

func attack(target):
	var dir = (target.position - position).normalized()
	var tween = create_tween()
	tween.tween_property(self, "position", position + dir * 0.3, 0.1)
	tween.tween_property(self, "position", position, 0.1)
	await tween.finished

	target.take_damage(damage)

func take_damage(amount: int):
	hp -= amount
	if hp <= 0:
		Game.remove_enemy(self)
