extends Node

# Combat system - damage resolution and Hoplite-style reactive attack rules

signal damage_dealt(attacker, target, amount)
signal damage_blocked(defender)
signal unit_died(unit)

# Returns list of enemies that will react when player moves to target from old_coord
# Reactive attack rules:
# - Melee enemies already adjacent to player at old_coord don't react
# - All other enemies that threaten the target coordinate will react
func get_reactive_enemies(old_coord: Vector3i, target: Vector3i) -> Array[Node3D]:
	var reactive: Array[Node3D] = []

	# Track which MELEE enemies player was already adjacent to
	var melee_enemies_already_adjacent = []

	for enemy in UnitRegistry.enemies:
		if not is_instance_valid(enemy):
			continue

		# Check if enemy is melee (min attack range == 1 means melee)
		var is_melee = enemy.get_min_attack_range() == 1

		if is_melee and enemy.dominates(old_coord):
			melee_enemies_already_adjacent.append(enemy)

	# Find all enemies that threaten target, excluding melee enemies already adjacent
	for enemy in UnitRegistry.enemies:
		if not is_instance_valid(enemy):
			continue

		# Skip melee enemies we were already adjacent to
		if enemy in melee_enemies_already_adjacent:
			continue

		# Check if player is now in this enemy's threat range
		if enemy.dominates(target):
			reactive.append(enemy)

	return reactive

# Returns list of enemies threatening a coordinate
func get_enemies_threatening(coord: Vector3i) -> Array[Node3D]:
	var threatening: Array[Node3D] = []

	for enemy in UnitRegistry.enemies:
		if not is_instance_valid(enemy):
			continue

		if enemy.dominates(coord):
			threatening.append(enemy)

	return threatening

# Get all enemies adjacent to a coordinate (for player counter-attacks)
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
