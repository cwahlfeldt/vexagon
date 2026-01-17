extends Node

# Level definitions - matches old game's 8 levels
var levels: Array[LevelConfig] = []
var current_level_index := 0

func _ready():
	_create_level_definitions()

func _create_level_definitions():
	# Level 1: The Awakening - Tutorial with Grunts
	var level1 = LevelConfig.new()
	level1.level_name = "The Awakening"
	level1.map_size = 4
	level1.player_hp = 5
	level1.grunt_count = 2
	level1.wizard_count = 0
	level1.sniper_count = 0
	level1.min_spawn_distance = 4
	level1.blocked_tile_chance = 0.1
	levels.append(level1)

	# Level 2: Distant Threats - Introduction to Wizards
	var level2 = LevelConfig.new()
	level2.level_name = "Distant Threats"
	level2.map_size = 5
	level2.player_hp = 4
	level2.grunt_count = 1
	level2.wizard_count = 2
	level2.sniper_count = 0
	level2.min_spawn_distance = 4
	level2.blocked_tile_chance = 0.12
	levels.append(level2)

	# Level 3: Line of Sight - Learn Sniper firing lanes
	var level3 = LevelConfig.new()
	level3.level_name = "Line of Sight"
	level3.map_size = 5
	level3.player_hp = 4
	level3.grunt_count = 2
	level3.wizard_count = 0
	level3.sniper_count = 2
	level3.sniper_axes = [0, 1]  # Q and R axis snipers
	level3.min_spawn_distance = 3
	level3.blocked_tile_chance = 0.12
	levels.append(level3)

	# Level 4: Convergence - Multiple enemy types together
	var level4 = LevelConfig.new()
	level4.level_name = "Convergence"
	level4.map_size = 5
	level4.player_hp = 4
	level4.grunt_count = 2
	level4.wizard_count = 1
	level4.sniper_count = 1
	level4.sniper_axes = [0]
	level4.min_spawn_distance = 3
	level4.blocked_tile_chance = 0.15
	levels.append(level4)

	# Level 5: Hardened Foes - Tougher enemies
	var level5 = LevelConfig.new()
	level5.level_name = "Hardened Foes"
	level5.map_size = 6
	level5.player_hp = 3
	level5.grunt_count = 3
	level5.wizard_count = 2
	level5.sniper_count = 1
	level5.sniper_axes = [2]
	level5.enemy_hp_bonus = 1
	level5.min_spawn_distance = 3
	level5.blocked_tile_chance = 0.15
	levels.append(level5)

	# Level 6: The Gauntlet - Overwhelming numbers
	var level6 = LevelConfig.new()
	level6.level_name = "The Gauntlet"
	level6.map_size = 6
	level6.player_hp = 3
	level6.grunt_count = 4
	level6.wizard_count = 2
	level6.sniper_count = 2
	level6.sniper_axes = [0, 1]
	level6.enemy_hp_bonus = 1
	level6.min_spawn_distance = 2
	level6.blocked_tile_chance = 0.1
	levels.append(level6)

	# Level 7: Deadly Force - Enemies deal more damage
	var level7 = LevelConfig.new()
	level7.level_name = "Deadly Force"
	level7.map_size = 6
	level7.player_hp = 3
	level7.grunt_count = 3
	level7.wizard_count = 2
	level7.sniper_count = 3
	level7.sniper_axes = [0, 1, 2]
	level7.enemy_hp_bonus = 2
	level7.enemy_damage_bonus = 1
	level7.min_spawn_distance = 2
	level7.blocked_tile_chance = 0.12
	levels.append(level7)

	# Level 8: Final Stand - Everything combined, no rewind
	var level8 = LevelConfig.new()
	level8.level_name = "Final Stand"
	level8.map_size = 7
	level8.player_hp = 3
	level8.grunt_count = 4
	level8.wizard_count = 3
	level8.sniper_count = 3
	level8.sniper_axes = [0, 1, 2]
	level8.enemy_hp_bonus = 3
	level8.enemy_damage_bonus = 1
	level8.min_spawn_distance = 2
	level8.blocked_tile_chance = 0.1
	level8.allow_rewind = false
	levels.append(level8)

func get_current_level() -> LevelConfig:
	if current_level_index < levels.size():
		return levels[current_level_index]
	return levels[0]

func advance_level() -> bool:
	current_level_index += 1
	return current_level_index < levels.size()

func reset_to_level(index: int):
	current_level_index = clampi(index, 0, levels.size() - 1)

func get_level_count() -> int:
	return levels.size()
