extends Node3D

signal died

@export var max_hp := 3
@export var move_range := 1
@export var damage := 1

var coord: Vector3i
var hp: int

var dash_cooldown := 0
var dash_mode := false
var block_cooldown := 0
var block_active := false

func _ready():
	add_to_group("player")
	hp = max_hp

func start_turn():
	if dash_cooldown > 0:
		dash_cooldown -= 1
	if block_cooldown > 0:
		block_cooldown -= 1
	dash_mode = false
	show_move_range()

func _input(event):
	if not Game.is_player_turn:
		return
	if event.is_action_pressed("dash"):
		toggle_dash()
	if event.is_action_pressed("block"):
		toggle_block()
	if event.is_action_pressed("rewind"):
		Game.rewind()

func toggle_dash():
	if dash_cooldown > 0:
		return
	dash_mode = not dash_mode
	show_move_range()

func toggle_block():
	if block_active:
		block_active = false
	elif block_cooldown == 0:
		block_active = true

func try_move_to(target: Vector3i):
	if not Game.is_player_turn:
		return

	var dist = HexGrid.distance(coord, target)

	if dash_mode:
		if dist <= 2 and not Game.is_tile_blocked(target):
			hide_move_range()
			await do_dash(target)
			Game.end_player_turn()
	else:
		if dist <= move_range and not Game.is_tile_blocked(target):
			hide_move_range()
			await do_move(target)
			Game.end_player_turn()

func do_move(target: Vector3i):
	var old_coord = coord
	print("\n=== PLAYER MOVING TO ", target, " ===")

	# HOPLITE TILE OWNERSHIP RULES:
	# - Enemies "own" tiles in their threat zones
	# - Player "owns" tiles adjacent (distance=1) to them after moving
	# - If ONLY enemies own the tile → enemies attack, player doesn't
	# - If ONLY player owns the tile → player attacks, enemies don't
	# - If BOTH own the tile → contested, both attack

	var enemies_that_own_tile = []
	var enemies_adjacent_to_tile = []

	for enemy in Game.enemies:
		if not is_instance_valid(enemy):
			continue

		# Does this enemy have the target tile in their threat zone?
		var threat_tiles = enemy.get_threat_tiles()
		if target in threat_tiles:
			print(enemy.name, " owns tile ", target, " (in threat zone)")
			enemies_that_own_tile.append(enemy)

		# Is this enemy adjacent to the target tile?
		var distance_to_tile = HexGrid.distance(enemy.coord, target)
		if distance_to_tile == 1:
			print(enemy.name, " is adjacent to tile ", target)
			enemies_adjacent_to_tile.append(enemy)

	# Player owns tiles adjacent to enemies (after moving there)
	var player_owns_tile = enemies_adjacent_to_tile.size() > 0
	var enemies_own_tile = enemies_that_own_tile.size() > 0

	print("\nTile ownership:")
	print("  - Player owns: ", player_owns_tile, " (", enemies_adjacent_to_tile.size(), " adjacent enemies)")
	print("  - Enemies own: ", enemies_own_tile, " (", enemies_that_own_tile.size(), " enemies)")

	# Move to the tile
	coord = target
	var tween = create_tween()
	tween.tween_property(self, "position", HexGrid.to_world(target), 0.25)
	await tween.finished

	# COMBAT RESOLUTION based on tile ownership
	if enemies_own_tile:
		# Enemies own the tile - they attack
		print("\n--- ENEMIES ATTACK (they own the tile) ---")
		for enemy in enemies_that_own_tile:
			if is_instance_valid(enemy):
				print(enemy.name, " attacking player!")
				await enemy.attack(self)
				if hp <= 0:
					print("Player died!")
					return

	if player_owns_tile:
		# Player owns the tile - player attacks
		print("\n--- PLAYER ATTACKS (player owns the tile) ---")
		for enemy in enemies_adjacent_to_tile:
			if is_instance_valid(enemy):
				print("Player attacking ", enemy.name, "!")
				await attack(enemy)

func do_dash(target: Vector3i):
	dash_mode = false
	dash_cooldown = 4
	coord = target
	var tween = create_tween()
	tween.tween_property(self, "position", HexGrid.to_world(target), 0.15)
	await tween.finished

func attack(target):
	# Lunge animation
	var dir = (target.position - position).normalized()
	var tween = create_tween()
	tween.tween_property(self, "position", position + dir * 0.3, 0.1)
	tween.tween_property(self, "position", position, 0.1)
	await tween.finished

	target.take_damage(damage)

func take_damage(amount: int):
	if block_active:
		block_active = false
		block_cooldown = 3
		return

	hp -= amount
	if hp <= 0:
		died.emit()

func show_move_range():
	hide_move_range()  # Clear any existing highlights first

	var range = 2 if dash_mode else move_range
	var color = Color(0.3, 0.8, 1.0, 0.5) if dash_mode else Color(0.3, 1.0, 0.3, 0.5)  # Blue for dash, green for normal

	# Get all tiles in range
	var tiles_in_range = HexGrid.in_range(coord, range)

	for tile_coord in tiles_in_range:
		if tile_coord == coord:
			continue  # Skip player's current position

		var dist = HexGrid.distance(coord, tile_coord)
		if dist > range:
			continue

		# Check if tile is blocked
		if not Game.is_tile_blocked(tile_coord):
			var tile = Game.get_tile(tile_coord)
			if tile:
				tile.set_highlight(true, color)

func hide_move_range():
	# Clear all tile highlights
	for tile in Game.tiles.values():
		if tile.highlighted:
			tile.set_highlight(false)
