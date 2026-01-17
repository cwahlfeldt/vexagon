extends Resource
class_name LevelConfig

@export var level_name: String = "Level 1"
@export var map_size: int = 5

# Player stats for this level
@export var player_hp: int = 3

# Enemy spawn configuration
@export var grunt_count: int = 2
@export var wizard_count: int = 0
@export var sniper_count: int = 0
@export var sniper_axes: Array = []  # Which axes (0, 1, 2) for each sniper

# Difficulty modifiers
@export var enemy_hp_bonus: int = 0
@export var enemy_damage_bonus: int = 0

# Spawn rules
@export var min_spawn_distance: int = 3  # Minimum distance from player
@export var blocked_tile_chance: float = 0.15

# Special rules
@export var allow_rewind: bool = true
