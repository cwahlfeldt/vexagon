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

@onready var animation_player = $AnimationPlayer

func _ready():
	add_to_group("player")
	hp = max_hp
	visible = false # Hidden until spawn animation plays

func play_spawn_animation():
	visible = true
	animation_player.play("Character/Spawn_Air")

func player_idle_animation():
	animation_player.play("Character/Idle_A")

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
	print("\n=== PLAYER MOVING FROM ", old_coord, " TO ", target, " ===")

	# Track which MELEE enemies player was already adjacent to
	# These enemies don't get reactive attacks (Hoplite rule)
	var melee_enemies_already_adjacent = []

	for enemy in Game.enemies:
		if not is_instance_valid(enemy):
			continue

		# Check if enemy is melee (min attack range == 1 means melee)
		var is_melee = enemy.get_min_attack_range() == 1

		if is_melee and enemy.dominates(old_coord):
			print(enemy.name, " was already adjacent (melee) - no reactive attack")
			melee_enemies_already_adjacent.append(enemy)

	# Execute movement animation
	coord = target
	var tween = create_tween()
	tween.tween_property(self, "position", HexGrid.to_world(target), 0.2)
	await tween.finished

	# PHASE 1: ENEMY REACTIVE ATTACKS
	# Enemies attack when player enters/remains in their range
	# Exception: Melee enemies player was already adjacent to don't get reactive attacks
	print("\n--- ENEMY REACTIVE ATTACKS ---")
	for enemy in Game.enemies:
		if not is_instance_valid(enemy):
			continue

		# Skip melee enemies we were already adjacent to
		if enemy in melee_enemies_already_adjacent:
			continue

		# Check if player is now in this enemy's threat range
		if enemy.dominates(target):
			print(enemy.name, " reactive attack (player entered/in threat zone)!")
			await enemy.attack(self)
			if hp <= 0:
				print("Player died!")
				return

	# PHASE 2: PLAYER ATTACKS
	# Player attacks ALL adjacent enemies after moving
	print("\n--- PLAYER ATTACKS ---")
	for enemy in Game.enemies:
		if not is_instance_valid(enemy):
			continue

		# Attack any enemy adjacent to player's new position
		if HexGrid.distance(target, enemy.coord) == 1:
			print("Player attacks ", enemy.name, "!")
			await attack(enemy)

func do_dash(target: Vector3i):
	var old_coord = coord
	print("\n=== PLAYER DASHING FROM ", old_coord, " TO ", target, " ===")

	dash_mode = false
	dash_cooldown = 4

	# Fast dash animation
	coord = target
	var tween = create_tween()
	tween.tween_property(self, "position", HexGrid.to_world(target), 0.15)
	await tween.finished

	# DASH RULE: No enemy reactive attacks during dash!
	# But player can attack enemies in range after landing

	print("\n--- PLAYER ATTACKS AFTER DASH ---")
	for enemy in Game.enemies:
		if not is_instance_valid(enemy):
			continue

		# Attack all adjacent enemies after dash
		if HexGrid.distance(target, enemy.coord) == 1:
			print("Player attacks ", enemy.name, " after dash!")
			await attack(enemy)

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
	if block_active:
		block_active = false
		block_cooldown = 3
		print("Block absorbed damage!")
		return

	hp -= amount
	print("Player took ", amount, " damage! HP: ", hp, "/", max_hp)
	if hp <= 0:
		died.emit()
		Game.trigger_defeat()

func show_move_range():
	hide_move_range() # Clear any existing highlights first

	var range = 2 if dash_mode else move_range
	var color = Color(0.3, 0.8, 1.0, 0.5) if dash_mode else Color(0.3, 1.0, 0.3, 0.5) # Blue for dash, green for normal

	# Get all tiles in range
	var tiles_in_range = HexGrid.in_range(coord, range)

	for tile_coord in tiles_in_range:
		if tile_coord == coord:
			continue # Skip player's current position

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
