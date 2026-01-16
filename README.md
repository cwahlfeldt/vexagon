# Vexagon

A hex-grid turn-based tactics game built with Godot 4.5, inspired by [Hoplite](https://www.magmafortress.com/p/hoplite.html).

![Godot Version](https://img.shields.io/badge/Godot-4.5-blue)
![License](https://img.shields.io/badge/license-MIT-green)

## Overview

Vexagon is a tactical puzzle game where every move matters. Navigate a hexagonal battlefield, outmaneuver enemies with unique attack patterns, and use special abilities to survive. Made a mistake? Use the rewind system to undo your last moves and try a different strategy.

### Key Features

- **Hex-Grid Tactical Combat** - Strategic movement on a hexagonal grid using cube coordinates
- **Hoplite-Style Engagement** - Enemies attack when you enter their threat zones
- **Special Abilities**
  - **Dash** - Move 2 tiles to escape danger (4-turn cooldown)
  - **Block** - Negate the next hit (3-turn cooldown after use)
- **Rewind System** - Undo up to 50 turns to experiment with different strategies
- **Enemy Variety** - Three enemy types with distinct attack patterns
- **Visual Feedback** - Hover over enemies to see their threat zones, move range highlights

## Getting Started

### Prerequisites

- [Godot 4.5](https://godotengine.org/download) or later

### Running the Game

1. Clone this repository
2. Open Godot 4.5
3. Click "Import" and select the `project.godot` file
4. Press **F5** to run the game

Alternatively, if you have Godot in your PATH:
```bash
godot --path /path/to/vexagon
```

## How to Play

### Controls

| Key | Action |
|-----|--------|
| **Left Click** | Move to tile |
| **D** | Toggle Dash mode |
| **B** | Toggle Block ability |
| **R** | Rewind one turn |

### Objective

Survive as long as possible by defeating enemies while managing your health and abilities.

### Mechanics

**Movement**
- Click on a highlighted tile to move (1 tile per turn normally)
- Green highlights show normal move range
- Blue highlights show dash range (2 tiles)

**Combat**
- Enemies attack when you **enter** their threat zone
- Hovering over enemies shows their threat zones in red
- If you move while staying adjacent to an enemy, you counter-attack them
- Dash moves avoid triggering enemy attacks

**Abilities**
- **Dash (D key)**: Activate to move 2 tiles in one turn. Enemies won't attack during a dash. 4-turn cooldown after use.
- **Block (B key)**: Activate to negate the next hit. 3-turn cooldown after blocking a hit.

**Rewind**
- Press **R** to undo your last turn
- You can rewind up to 50 turns
- All game state is restored: positions, health, cooldowns, and enemies

## Enemy Types

### Grunt (Melee)
- **Threat Pattern**: All 6 adjacent tiles
- **Behavior**: Moves toward player until adjacent, then waits
- **HP**: 1

### Wizard (Ranged)
- **Threat Pattern**: Diagonal lines in all 6 hex directions, range 2-5 tiles
- **Behavior**: Maintains distance while threatening player
- **HP**: 1

### Sniper (Axis)
- **Threat Pattern**: Two opposite directions along one hex axis (Q, R, or S), range 2-5 tiles
- **Behavior**: Threatens along straight lines
- **HP**: 1
- **Variants**: Each sniper locks to one of three hex axes

## Project Structure

```
vexagon/
├── scenes/
│   ├── main.tscn           # Main game scene with grid generation
│   ├── hex_tile.tscn       # Individual hex tile
│   ├── player.tscn         # Player unit
│   ├── grunt.tscn          # Melee enemy
│   ├── wizard.tscn         # Ranged enemy
│   ├── sniper.tscn         # Axis enemy
│   └── ui.tscn             # HUD and UI elements
│
├── scripts/
│   ├── game.gd             # Autoload: Game state manager
│   ├── hex_grid.gd         # Autoload: Hex math utilities
│   ├── hex_tile.gd         # Tile behavior and highlighting
│   ├── player.gd           # Player movement and abilities
│   ├── enemy.gd            # Base enemy class
│   ├── wizard.gd           # Wizard enemy type
│   ├── sniper.gd           # Sniper enemy type
│   ├── main.gd             # Level setup and initialization
│   └── ui.gd               # UI updates and button handlers
│
├── assets/
│   ├── materials/          # Material resources
│   └── models/             # 3D models
│
├── project.godot           # Godot project configuration
├── PROJECT_IMPLEMENTATION_GUIDE.md  # Detailed implementation guide
├── CLAUDE.md               # AI assistant context file
└── README.md               # This file
```

## Technical Details

### Autoload Singletons

The game uses two autoload scripts for global state management:

- **Game** - Controls turn flow, maintains references to all units, handles rewind state snapshots
- **HexGrid** - Provides hex coordinate math (cube coordinates with x+y+z=0 invariant)

### Hex Coordinate System

The game uses **cube coordinates** for hex grid math:
- Each hex has coordinates `(x, y, z)` where `x + y + z = 0`
- Provides simple distance calculation: `(|dx| + |dy| + |dz|) / 2`
- Six directions stored as constant vectors in `HexGrid.DIRS`
- Conversion to world space via `HexGrid.to_world()`

### Turn System

1. **Player Turn Start** - Cooldowns decrement, move range highlights appear
2. **Player Action** - Click tile to move, triggering enemy attacks if entering threat zones
3. **Enemy Turns** - Each enemy either waits (if player in threat zone) or moves closer
4. **State Save** - Game state snapshot saved for rewind
5. **Loop** - Return to step 1

### Rewind Implementation

- Snapshots saved after each full turn cycle (player + all enemies)
- Stores: player stats/position, enemy types/positions/HP, ability cooldowns
- On rewind: player state restored, all enemies despawned and re-instantiated from snapshots
- Limited to last 50 states to prevent memory issues

## Development

### Key Design Patterns

- **Autoload Singletons** - Global game state and utilities accessible anywhere
- **Signal-Based Events** - Decoupled communication (`turn_started`, `player_died`, `enemy_died`)
- **Async Movement** - All movement uses `await` with tweens for smooth animations
- **Property Setters** - Reactive updates (e.g., `walkable` property updates tile visibility)
- **Template Method Pattern** - Enemy base class with `get_threat_tiles()` override points

### Adding New Enemy Types

1. Create new script extending `Enemy`
2. Override `get_threat_tiles()` to define attack pattern
3. Create scene with the script attached
4. Add to `Units` node in main scene with "enemies" group

Example:
```gdscript
extends Enemy

func get_threat_tiles() -> Array[Vector3i]:
    var tiles: Array[Vector3i] = []
    # Define your attack pattern here
    return tiles
```

### Modifying the Map

Edit `main.gd`:
- Change `map_size` export variable to adjust grid radius
- Modify line 20 to adjust random blocked tile percentage
- Customize `position_units()` for different enemy spawning logic

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

This project is licensed under the MIT License.

## Acknowledgments

- Inspired by [Hoplite](https://www.magmafortress.com/p/hoplite.html) by Doug Cowley
- Built with [Godot Engine](https://godotengine.org/)
- Hex grid math based on [Amit's Hexagonal Grids](https://www.redblobgames.com/grids/hexagons/)

## Resources

- [CLAUDE.md](CLAUDE.md) - Context file for Claude Code AI assistant
- [Godot Documentation](https://docs.godotengine.org/)
- [Red Blob Games - Hexagonal Grids](https://www.redblobgames.com/grids/hexagons/)
