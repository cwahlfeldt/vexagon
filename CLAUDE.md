# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Vexagon** is a hex-grid turn-based tactics game built with Godot 4.5, inspired by Hoplite. The game features:
- Turn-based combat where player moves, then enemies move
- Hoplite-style engagement: enemies attack when player enters their threat zones
- Player abilities: Dash (move 2 tiles, 4-turn cooldown), Block (negate one hit, 3-turn cooldown)
- Rewind system to undo mistakes (preserves last 50 game states)

## Running the Game

This is a Godot 4.5 project. Open it in Godot Editor and press F5 to run, or use:
```bash
# If godot CLI is available
godot --path /Users/chriswahlfeldt/code/vexagon
```

There is no separate build system - Godot handles compilation internally.

## Architecture

### Autoload Singletons (Global State)

Two autoload scripts manage core systems (configured in [project.godot:18-21](project.godot#L18-L21)):

1. **Game** ([scripts/game.gd](scripts/game.gd)) - Central game controller
   - Manages turn flow, player/enemy references, game state
   - Handles rewind system via state snapshots
   - Coordinates tile blocking and enemy lookups
   - Key methods: `start_game()`, `end_player_turn()`, `rewind()`

2. **HexGrid** ([scripts/hex_grid.gd](scripts/hex_grid.gd)) - Hex math utilities
   - Converts hex coordinates (Vector3i) to world positions (Vector3)
   - Provides hex algorithms: `neighbors()`, `distance()`, `in_range()`, `line()`
   - Uses cube coordinates (x+y+z=0 invariant)
   - Hex size constant: `SIZE = 1.05`

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
2. **Enemy Engagement**: When player enters enemy threat zone, enemy attacks immediately
3. **Counter-attack**: If player stays adjacent to enemy during move, player counter-attacks
4. **Enemy Turns**: After player action, `Game.do_enemy_turns()` moves each enemy toward player
5. **State Save**: After enemy turns complete, `Game.save_state()` captures snapshot

### Enemy Threat System

Each enemy type overrides `get_threat_tiles()` to define its attack pattern:
- **Grunt** ([scripts/enemy.gd](scripts/enemy.gd)): Adjacent tiles (6 neighbors)
- **Wizard** ([scripts/wizard.gd](scripts/wizard.gd)): Diagonal lines in 6 directions, range 2-5
- **Sniper** ([scripts/sniper.gd](scripts/sniper.gd)): Axis-aligned (Q/R/S), range 2-5

The `dominates(coord)` method checks if a coordinate is in the enemy's threat zone.

### Rewind Mechanics

- State saved at end of each turn cycle in `Game.history` (max 50 states)
- Stores: player position/stats, all enemy positions/HP, scene paths
- On rewind: restores player state, despawns all enemies, re-instantiates enemies from saved scene paths
- Requires "units_container" group on enemy parent node

### Input Actions

Configured in [project.godot:33-48](project.godot#L33-L48):
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
`Game.is_tile_blocked(coord)` checks:
1. Tile exists and is walkable
2. No player at that position
3. No valid enemy at that position

### Async Movement
All movement uses `await` with Tween animations. Player turn doesn't end until animations complete.

### Enemy AI
Simple greedy pathfinding: each enemy moves to adjacent tile that minimizes distance to player, or waits if player is already in threat zone.

## File Organization

- `scenes/` - All .tscn files (main, ui, hex_tile, player, enemies)
- `scripts/` - All .gd files (paired with scenes, plus autoloads)
- `assets/` - Game assets
- `.godot/` - Godot engine cache (auto-generated, don't modify)

## Important Gotchas

1. **Units container group**: The parent node for enemies MUST be in the "units_container" group or rewind will fail
2. **Enemy scene paths**: Enemies store `scene_file_path` for rewind - don't move enemy scenes without updating saved states
3. **Turn blocking**: Player input is ignored when `Game.is_player_turn` is false
4. **Instance validity**: Always check `is_instance_valid(enemy)` before accessing enemy references (they may be freed)
5. **Dash mode persistence**: Dash mode is cleared at start of each turn and on rewind

