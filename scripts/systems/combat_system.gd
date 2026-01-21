extends Node

# Combat system - Hoplite-style turn resolution and attack mechanics
#
# HOPLITE TURN ORDER:
# 1. Player moves (walk, leap, dash, etc.)
# 2. Player attacks resolve (stab, lunge)
# 3. Enemies attack player (all enemies that can hit player's NEW position)
# 4. Enemies move (AI phase - NO attacks during enemy turn)
#
# KEY RULES:
# - Stab: Player attacks enemy when moving between two tiles adjacent to that enemy
# - Lunge: Player attacks enemy when moving DIRECTLY TOWARD that enemy
# - Enemy attacks: ALL enemies that threaten player's final position attack
# - Ranged enemies need clear line of sight (no demons blocking)

signal damage_dealt(attacker, target, amount)
signal damage_blocked(defender)
signal unit_died(unit)


# === PLAYER ATTACK RESOLUTION ===

# Get enemies the player will STAB when moving from old_coord to new_coord
# Stab rule: Moving between two tiles that are BOTH adjacent to an enemy
func get_stab_targets(old_coord: Vector3i, new_coord: Vector3i) -> Array[Node3D]:
	var targets: Array[Node3D] = []

	for enemy in UnitRegistry.enemies:
		if not is_instance_valid(enemy):
			continue

		# Stab requires: enemy adjacent to BOTH old and new position
		var dist_from_old = HexGrid.distance(enemy.coord, old_coord)
		var dist_from_new = HexGrid.distance(enemy.coord, new_coord)

		if dist_from_old == 1 and dist_from_new == 1:
			targets.append(enemy)

	return targets


# Get enemies the player will LUNGE when moving from old_coord to new_coord
# Lunge rule: Moving DIRECTLY TOWARD an enemy (straight hex line, closing distance)
func get_lunge_targets(old_coord: Vector3i, new_coord: Vector3i) -> Array[Node3D]:
	var targets: Array[Node3D] = []

	for enemy in UnitRegistry.enemies:
		if not is_instance_valid(enemy):
			continue

		# Check if we're moving directly toward this enemy
		if is_moving_toward(old_coord, new_coord, enemy.coord):
			# Lunge hits the enemy we moved toward if now adjacent
			if HexGrid.distance(new_coord, enemy.coord) == 1:
				targets.append(enemy)

	return targets


# Check if moving from old to new is moving DIRECTLY TOWARD target
# This means: the movement direction points at the target in a straight hex line
func is_moving_toward(old_coord: Vector3i, new_coord: Vector3i, target_coord: Vector3i) -> bool:
	# Get movement direction
	var move_delta = new_coord - old_coord

	# Normalize to a unit hex direction (if it's a valid hex direction)
	var move_dir = normalize_hex_direction(move_delta)
	if move_dir == Vector3i.ZERO:
		return false  # Not a valid hex move

	# Target must be in same direction and we must be getting closer
	var old_dist = HexGrid.distance(old_coord, target_coord)
	var new_dist = HexGrid.distance(new_coord, target_coord)

	if new_dist >= old_dist:
		return false  # Not getting closer

	# Check if target is on the line in move direction
	return is_on_hex_line(old_coord, move_dir, target_coord)


# Normalize a hex delta to a unit direction, or return ZERO if not a straight hex line
func normalize_hex_direction(delta: Vector3i) -> Vector3i:
	# Check each standard hex direction
	for dir in HexGrid.DIRS:
		# Check if delta is a positive multiple of this direction
		if delta.x != 0:
			var factor = delta.x / dir.x if dir.x != 0 else 0
			if factor > 0 and delta == dir * factor:
				return dir
		elif delta.y != 0:
			var factor = delta.y / dir.y if dir.y != 0 else 0
			if factor > 0 and delta == dir * factor:
				return dir
		elif delta.z != 0:
			var factor = delta.z / dir.z if dir.z != 0 else 0
			if factor > 0 and delta == dir * factor:
				return dir

	# For single-step moves, the delta itself might be a direction
	if delta in HexGrid.DIRS:
		return delta

	return Vector3i.ZERO


# Check if target is on the hex line starting at origin going in direction dir
func is_on_hex_line(origin: Vector3i, dir: Vector3i, target: Vector3i) -> bool:
	if dir == Vector3i.ZERO:
		return false

	var delta = target - origin

	# Check if delta is a positive multiple of dir
	# For cube coords, we need to check all three components
	if dir.x != 0:
		var factor = delta.x / dir.x
		if factor > 0 and delta == dir * factor:
			return true
	elif dir.y != 0:
		var factor = delta.y / dir.y
		if factor > 0 and delta == dir * factor:
			return true
	elif dir.z != 0:
		var factor = delta.z / dir.z
		if factor > 0 and delta == dir * factor:
			return true

	return false


# === ENEMY ATTACK RESOLUTION ===

# Get all enemies that will attack after player moves to target
# In Hoplite: ALL enemies that can hit the player's NEW position attack
# This is simpler than the old "reactive" system - just check who threatens the new tile
func get_attacking_enemies(target_coord: Vector3i) -> Array[Node3D]:
	var attackers: Array[Node3D] = []

	for enemy in UnitRegistry.enemies:
		if not is_instance_valid(enemy):
			continue

		# Check if enemy can attack the target position
		if can_enemy_attack(enemy, target_coord):
			attackers.append(enemy)

	return attackers


# Check if a specific enemy can attack a target coordinate
# Considers range, line of sight, and any special rules
func can_enemy_attack(enemy: Node3D, target_coord: Vector3i) -> bool:
	var dist = HexGrid.distance(enemy.coord, target_coord)
	var min_range = enemy.get_min_attack_range()
	var max_range = enemy.get_max_attack_range()

	# Check basic range
	if dist < min_range or dist > max_range:
		return false

	# For melee enemies (min_range == 1), just need adjacency
	if min_range == 1:
		return dist == 1

	# For ranged enemies, need line of sight AND must be on a valid attack line
	# First check if target is on a valid hex line from enemy
	if not is_on_attack_line(enemy, target_coord):
		return false

	# Then check line of sight (no other demons blocking)
	if not has_clear_line_of_sight(enemy.coord, target_coord):
		return false

	return true


# Check if target is on one of the enemy's attack lines
# Ranged enemies can only shoot in 6 hex directions
func is_on_attack_line(enemy: Node3D, target_coord: Vector3i) -> bool:
	var delta = target_coord - enemy.coord

	# Check if delta aligns with any hex direction
	for dir in HexGrid.DIRS:
		if dir == Vector3i.ZERO:
			continue

		# Check each component to find a scalar multiple
		var factor = 0
		if dir.x != 0:
			factor = delta.x / dir.x
		elif dir.y != 0:
			factor = delta.y / dir.y
		elif dir.z != 0:
			factor = delta.z / dir.z

		if factor > 0 and delta == dir * factor:
			return true

	return false


# Check if there's a clear line of sight between two coords
# Returns false if any demon is blocking the line
func has_clear_line_of_sight(from_coord: Vector3i, to_coord: Vector3i) -> bool:
	var delta = to_coord - from_coord
	var dir = normalize_hex_direction(delta)

	if dir == Vector3i.ZERO:
		return false  # Not on a straight hex line

	var dist = HexGrid.distance(from_coord, to_coord)

	# Check each tile along the line (excluding start and end)
	for i in range(1, dist):
		var check_coord = from_coord + dir * i

		# Check if any enemy is at this position (blocking the shot)
		if UnitRegistry.get_enemy_at(check_coord) != null:
			return false

		# Could also check for altars or other blocking terrain here
		# var tile = TileRegistry.get_tile(check_coord)
		# if tile and tile.blocks_line_of_sight:
		#     return false

	return true


# === LEGACY COMPATIBILITY METHODS ===
# These maintain backward compatibility with existing code

# Returns list of enemies that will react when player moves to target from old_coord
# DEPRECATED: Use get_attacking_enemies() instead
func get_reactive_enemies(_old_coord: Vector3i, target: Vector3i) -> Array[Node3D]:
	# In true Hoplite style, ALL enemies that can hit the new position attack
	# The old "already adjacent" exception was incorrect
	return get_attacking_enemies(target)


# Returns list of enemies threatening a coordinate
func get_enemies_threatening(coord: Vector3i) -> Array[Node3D]:
	var threatening: Array[Node3D] = []

	for enemy in UnitRegistry.enemies:
		if not is_instance_valid(enemy):
			continue

		if enemy.dominates(coord):
			threatening.append(enemy)

	return threatening


# Get all enemies adjacent to a coordinate
# Used for simple adjacency checks, NOT for player attacks (use get_stab_targets/get_lunge_targets)
func get_adjacent_enemies(coord: Vector3i) -> Array[Node3D]:
	var adjacent: Array[Node3D] = []

	for enemy in UnitRegistry.enemies:
		if not is_instance_valid(enemy):
			continue

		if HexGrid.distance(coord, enemy.coord) == 1:
			adjacent.append(enemy)

	return adjacent


# Centralized damage application
func deal_damage(attacker, target, amount: int):
	damage_dealt.emit(attacker, target, amount)
	target.take_damage(amount)
