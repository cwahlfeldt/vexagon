extends Node3D
class_name Enemy

@export var max_hp := 1
@export var damage := 1
@export var attack_range := 1 # For melee enemies

var coord: Vector3i
var hp: int
var hover_area: Area3D
@onready var animation_player = $AnimationPlayer

func _ready():
	add_to_group("enemies")
	hp = max_hp
	visible = false # Hidden until spawn animation plays
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
				tile.set_highlight(true, Color(1.0, 0.3, 0.3, 0.5)) # Red highlight
			else:
				tile.set_highlight(false)

# Override in subclasses for different patterns
func get_threat_tiles() -> Array[Vector3i]:
	return HexGrid.neighbors(coord)

func dominates(target_coord: Vector3i) -> bool:
	var threat_tiles = get_threat_tiles()
	var result = target_coord in threat_tiles
	if result:
		print(name, " dominates ", target_coord, " (has ", threat_tiles.size(), " threat tiles)")
	return result

# Override in subclasses for ranged enemies (default is melee: min=1, max=1)
func get_min_attack_range() -> int:
	return 1

func get_max_attack_range() -> int:
	return 1

func play_spawn_animation():
	if (animation_player != null):
		animation_player.stop()
		animation_player.play("Enemy/Skeletons_Spawn_Ground")
		visible = true

func take_turn():
	var player = Game.player
	if not is_instance_valid(player):
		return

	var dist = HexGrid.distance(coord, player.coord)
	# Use CombatSystem to check if we can ACTUALLY attack (includes LoS check)
	var can_attack_player = CombatSystem.can_enemy_attack(self, player.coord)

	print(name, " taking turn. Distance to player: ", dist, ". Can attack: ", can_attack_player)

	# HOPLITE-STYLE AI: Enemies NEVER attack on their turn
	# They only move to position themselves, or pass if player is in threat zone

	if can_attack_player:
		# Player in threat zone with clear LoS - stay put and wait for player to move
		print(name, " can attack player, passing turn")
		return

	# Need to move - find best position
	await find_and_move_to_best_position(player.coord)

func find_and_move_to_best_position(player_coord: Vector3i):
	# Get all walkable neighbors
	var candidates = []
	for neighbor in HexGrid.neighbors(coord):
		if not Game.is_tile_blocked(neighbor):
			candidates.append(neighbor)

	if candidates.is_empty():
		print(name, " has no valid moves (surrounded)")
		return

	# Score each candidate position
	var best_tile = coord
	var best_score = - INF

	var min_range = get_min_attack_range()
	var max_range = get_max_attack_range()
	var is_melee = (min_range == 1)

	for candidate in candidates:
		var score = score_position(candidate, player_coord, min_range, max_range, is_melee)
		if score > best_score:
			best_score = score
			best_tile = candidate

	# Only move if we found a better position
	if best_tile != coord:
		await move_to(best_tile)
	else:
		print(name, " staying put (no better position found)")

func score_position(pos: Vector3i, player_coord: Vector3i, min_range: int, _max_range: int, is_melee: bool) -> float:
	var dist = HexGrid.distance(pos, player_coord)

	# Check if player would be in threat zone from this position
	var would_threaten = would_dominate_from(pos, player_coord)

	if is_melee:
		# MELEE AI (Grunt): Get as close as possible
		# Strong preference for positions that threaten the player
		if would_threaten:
			return 1000.0 - dist # Threaten + minimize distance
		else:
			return -dist # Just minimize distance
	else:
		# RANGED AI (Wizard/Sniper): Maintain optimal range (around 3)
		# Strong preference for positions that threaten the player
		var ideal_dist = 3.0
		var dist_penalty = abs(dist - ideal_dist)

		if would_threaten:
			return 1000.0 - dist_penalty # Threaten + stay at ideal range
		elif dist < min_range:
			return -500.0 + dist # Too close, need to back away
		else:
			return -dist_penalty # Move toward ideal range

func would_dominate_from(from_pos: Vector3i, target_coord: Vector3i) -> bool:
	# Check if we would threaten target_coord if we were at from_pos
	# This needs to calculate threat tiles as if we were at from_pos
	var old_coord = coord
	coord = from_pos
	var result = dominates(target_coord)
	coord = old_coord
	return result

func move_to(target: Vector3i):
	print(name, " moving from ", coord, " to ", target)
	coord = target
	var tween = create_tween()
	tween.tween_property(self, "position", HexGrid.to_world(target), 0.2)
	await tween.finished

func attack(target):
	# Lunge animation toward target and back
	var start_pos = position
	var dir = (target.position - position).normalized()
	var tween = create_tween()
	tween.tween_property(self, "position", start_pos + dir * 0.3, 0.1)
	tween.tween_property(self, "position", start_pos, 0.1)
	await tween.finished

	target.take_damage(damage)

func take_damage(amount: int):
	hp -= amount
	print(name, " took ", amount, " damage! HP: ", hp)

	# Flash red on hit
	flash_damage()

	if hp <= 0:
		await play_death_animation()
		Game.remove_enemy(self)

func flash_damage():
	# Brief red flash on damage
	var model = get_node_or_null("Model")
	if model:
		# Find all mesh instances and flash them
		for child in model.get_children():
			if child is MeshInstance3D and child.get_surface_override_material_count() > 0:
				# Store original and apply flash (simplified approach)
				pass
	# Visual feedback via scale pulse
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3(1.2, 0.8, 1.2), 0.05)
	tween.tween_property(self, "scale", Vector3.ONE, 0.1)

func play_death_animation():
	print(name, " defeated!")
	# Death animation: shrink and fade
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector3(0.1, 0.1, 0.1), 0.3)
	tween.tween_property(self, "position:y", position.y - 0.5, 0.3)
	await tween.finished
