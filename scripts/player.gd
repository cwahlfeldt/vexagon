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

	# Check enemies we're entering range of (they attack us)
	for enemy in Game.enemies:
		if not is_instance_valid(enemy):
			continue
		var dominated_before = enemy.dominates(old_coord)
		var dominated_after = enemy.dominates(target)
		if dominated_after and not dominated_before:
			# Entering new enemy range - they attack
			await enemy.attack(self)
			if hp <= 0:
				return

	# Check if we can counter-attack (already adjacent, staying adjacent)
	for enemy in Game.enemies:
		if not is_instance_valid(enemy):
			continue
		var adj_before = HexGrid.distance(old_coord, enemy.coord) == 1
		var adj_after = HexGrid.distance(target, enemy.coord) == 1
		if adj_before and adj_after:
			await attack(enemy)

	# Move
	coord = target
	var tween = create_tween()
	tween.tween_property(self, "position", HexGrid.to_world(target), 0.25)
	await tween.finished

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
