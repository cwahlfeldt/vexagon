# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Vexagon** is a hex-grid turn-based tactics game built with Godot 4.5, inspired by Hoplite. The game features:
- Turn-based combat where player moves, then enemies move
- Hoplite-style engagement: enemies attack when player enters their threat zones
- Player abilities: Dash (move 2 tiles, 4-turn cooldown), Block (negate one hit, 3-turn cooldown)
- Rewind system to undo mistakes (preserves last 50 game states)
- 8-level campaign with progressive difficulty
- Victory/defeat conditions with UI feedback

## Running the Game

This is a Godot 4.5 project. Open it in Godot Editor and press F5 to run.

There is no separate build system - Godot handles compilation internally.

## Architecture

### Autoload Singletons (Global State)

Eight autoload scripts manage core systems (configured in [project.godot:20-27](project.godot#L20-L27)):

**Core Systems** (`scripts/systems/`):

1. **UnitRegistry** ([unit_registry.gd](scripts/systems/unit_registry.gd)) - Unit tracking
   - Central registry for player and enemies
   - Key methods: `register_player()`, `register_enemy()`, `remove_enemy()`, `get_enemy_at()`, `get_valid_enemies()`

2. **TileRegistry** ([tile_registry.gd](scripts/systems/tile_registry.gd)) - Tile tracking
   - Central registry for hex tiles
   - Key methods: `register_tile()`, `get_tile()`, `is_coord_blocked()`

3. **RewindSystem** ([rewind_system.gd](scripts/systems/rewind_system.gd)) - State snapshots
   - Manages game state history (max 50 states)
   - Key methods: `save_state()`, `can_rewind()`, `rewind()`, `reset()`

4. **TurnSystem** ([turn_system.gd](scripts/systems/turn_system.gd)) - Turn state machine
   - Manages turn state and transitions
   - Signals: `player_turn_started`, `player_turn_ended`, `enemy_turns_completed`
   - Key methods: `start_player_turn()`, `end_player_turn()`, `process_enemy_turns()`

5. **CombatSystem** ([combat_system.gd](scripts/systems/combat_system.gd)) - Damage resolution
   - Hoplite-style reactive attack rules
   - Key methods: `get_reactive_enemies()`, `get_adjacent_enemies()`, `get_enemies_threatening()`

**Facade & Utilities**:

6. **Game** ([scripts/game.gd](scripts/game.gd)) - Facade/coordinator
   - Thin coordinator that delegates to systems
   - Maintains backward compatibility via delegating properties
   - Victory/defeat detection and signals
   - Key methods: `start_game()`, `end_player_turn()`, `trigger_defeat()`, `check_victory()`

7. **HexGrid** ([scripts/hex_grid.gd](scripts/hex_grid.gd)) - Hex math utilities
   - Converts hex coordinates (Vector3i) to world positions (Vector3)
   - Provides hex algorithms: `neighbors()`, `distance()`, `in_range()`, `line()`
   - Uses cube coordinates (x+y+z=0 invariant)
   - Hex size constant: `SIZE = 1.05`

8. **LevelManager** ([scripts/level_manager.gd](scripts/level_manager.gd)) - Level progression
   - Defines 8 levels with increasing difficulty
   - Manages current level index and progression
   - Key methods: `get_current_level()`, `advance_level()`, `reset_to_level()`

### Communication Patterns

| From | To | Method |
|------|----|----|
| Player | TurnSystem | Direct call: `end_player_turn()` |
| Player | CombatSystem | Direct call: `get_reactive_enemies()`, `get_adjacent_enemies()` |
| TurnSystem | RewindSystem | Direct call: `save_state()` |
| Enemy | CombatSystem | Direct call for damage resolution |
| UI | Game | Signals: `game_won`, `game_lost`, `turn_started` |

**Rule**: Signals for events (turn changes, damage, death). Direct calls for queries and commands needing return values.

### Scene Structure

```
Main (Node3D)
├── Camera3D
├── DirectionalLight3D
├── Board (Node3D)              # Parent for all hex tiles
├── Units (Node3D)              # Must be in "units_container" group - rewind needs this
│   ├── Player (player.tscn)
│   └── Enemies (grunt/wizard/sniper.tscn)
└── UI (CanvasLayer)
```

### Core Gameplay Loop

1. **Player Turn**: Player clicks tile → `player.try_move_to()` validates and executes move
2. **Enemy Engagement**: `CombatSystem.get_reactive_enemies()` determines which enemies attack
3. **Counter-attack**: `CombatSystem.get_adjacent_enemies()` finds enemies to counter-attack
4. **Enemy Turns**: After player action, `Game.do_enemy_turns()` moves each enemy toward player
5. **State Save**: After enemy turns complete, `RewindSystem.save_state()` captures snapshot

### Enemy Threat System

Each enemy type overrides `get_threat_tiles()` to define its attack pattern:
- **Grunt** ([scripts/enemy.gd](scripts/enemy.gd)): Adjacent tiles (6 neighbors), 1 HP, 1 damage
- **Wizard** ([scripts/wizard.gd](scripts/wizard.gd)): Diagonal lines in 6 directions, range 2-5, 2 HP, 1 damage
- **Sniper** ([scripts/sniper.gd](scripts/sniper.gd)): Axis-aligned (Q/R/S), range 2-5, 1 HP, 2 damage

The `dominates(coord)` method checks if a coordinate is in the enemy's threat zone.

### Level System

Levels are configured via [LevelConfig](scripts/level_config.gd) resources with:
- Map size, blocked tile chance
- Player starting HP
- Enemy counts per type (grunt, wizard, sniper)
- Enemy stat bonuses (HP, damage)
- Spawn distance rules
- Rewind availability (disabled in final level)

The 8 levels progress from tutorial (2 grunts) to final challenge (mixed enemies, no rewind).

### Rewind Mechanics

- State saved at end of each turn cycle via `RewindSystem.save_state()` (max 50 states)
- Stores: player position/stats, all enemy positions/HP, scene paths
- On rewind: restores player state, despawns all enemies, re-instantiates enemies from saved scene paths
- Requires "units_container" group on enemy parent node

### Input Actions

Configured in [project.godot:36-54](project.godot#L36-L54):
- `dash` - D key
- `block` - B key
- `rewind` - R key

### Coordinate System

Uses cube coordinates (Vector3i) where x+y+z=0:
- Standard hex directions in `HexGrid.DIRS`
- Conversion to 3D world space via `HexGrid.to_world()`
- Flat-top hex orientation

## Key Implementation Details

### Tile Clicking
Tiles are Area3D nodes that emit `input_event` signal. On left-click, calls `Game.player.try_move_to(coord)`.

### Movement Validation
`TileRegistry.is_coord_blocked(coord)` checks:
1. Tile exists and is walkable
2. No player at that position
3. No valid enemy at that position

### Async Movement
All movement uses `await` with Tween animations. Player turn doesn't end until animations complete.

### Enemy AI
Simple greedy pathfinding: each enemy moves to adjacent tile that minimizes distance to player, or waits if player is already in threat zone.

## File Organization

```
scripts/
├── game.gd              # Facade/coordinator
├── player.gd            # Movement + abilities
├── enemy.gd             # AI + threat system (base class)
├── wizard.gd            # Enemy variant
├── sniper.gd            # Enemy variant
├── hex_grid.gd          # Hex math utilities
├── hex_tile.gd          # Tile input handling
├── level_manager.gd     # Level progression
├── level_config.gd      # LevelConfig resource
├── main.gd              # Level setup
├── ui.gd                # UI layer
├── free_camera.gd       # Camera controls
└── systems/
    ├── unit_registry.gd   # Unit tracking
    ├── tile_registry.gd   # Tile tracking
    ├── rewind_system.gd   # State snapshots
    ├── turn_system.gd     # Turn state machine
    └── combat_system.gd   # Damage resolution

scenes/
├── main.tscn            # Game entry point
├── player.tscn          # Player prefab
├── grunt.tscn           # Grunt enemy prefab
├── wizard.tscn          # Wizard enemy prefab
├── sniper.tscn          # Sniper enemy prefab
├── hex_tile.tscn        # Hex tile prefab
├── ui.tscn              # UI canvas layer
├── world.tscn           # Free camera demo scene
└── map.tscn             # Environment for world.tscn

assets/                  # Game assets
.godot/                  # Godot engine cache (auto-generated, don't modify)
.old-game/               # Reference implementation (C# version, porting guides)
```

## Important Gotchas

1. **Units container group**: The parent node for enemies MUST be in the "units_container" group or rewind will fail
2. **Enemy scene paths**: Enemies store `scene_file_path` for rewind - don't move enemy scenes without updating saved states
3. **Turn blocking**: Player input is ignored when `TurnSystem.is_player_turn` is false
4. **Instance validity**: Always check `is_instance_valid(enemy)` before accessing enemy references (they may be freed)
5. **Dash mode persistence**: Dash mode is cleared at start of each turn and on rewind
6. **Game state reset**: Call `Game.reset_state()` before setting up a new level to clear history and references
7. **Dynamic unit spawning**: Units are spawned dynamically by main.gd based on LevelConfig - don't add units directly to the scene
8. **System delegation**: Game.gd is a facade - actual logic lives in systems. Modify the appropriate system, not Game.gd
