# Vexagon Codebase Modularization Plan

## Overview

Reorganize the ~1,300 line codebase into well-defined modules that isolate core gameplay systems while following Godot 4.5 best practices.

## Current Problems

| File        | Lines | Issues                                                                                |
| ----------- | ----- | ------------------------------------------------------------------------------------- |
| `game.gd`   | 216   | God object: turn flow, combat coordination, tile/unit queries, rewind, victory/defeat |
| `player.gd` | 214   | Mixed: movement, combat phases, abilities, input, animations                          |
| `enemy.gd`  | 214   | Mixed: AI decisions, threat calculation, combat, death handling                       |

## Proposed Module Structure

```
scripts/
  game.gd              # Slimmed to ~80 lines - Facade/coordinator only
  player.gd            # ~180 lines - Combat logic extracted
  enemy.gd             # ~150 lines - Cleaner separation

  systems/
    turn_system.gd     # ~60 lines - Turn state machine
    combat_system.gd   # ~80 lines - Damage resolution, engagement rules
    rewind_system.gd   # ~80 lines - State snapshots and restoration
    unit_registry.gd   # ~40 lines - Unit tracking and queries
    tile_registry.gd   # ~30 lines - Tile tracking and queries
```

## Module Specifications

### 1. TurnSystem (autoload)

**Purpose**: Turn state transitions and sequencing

```gdscript
# Signals
signal player_turn_started
signal player_turn_ended
signal enemy_turns_completed

# State
var is_player_turn: bool = true

# API
func start_player_turn()
func end_player_turn()
func process_enemy_turns()  # async
```

### 2. CombatSystem (autoload)

**Purpose**: Damage resolution, Hoplite-style reactive attack rules

```gdscript
# Signals
signal damage_dealt(attacker, target, amount)
signal damage_blocked(defender)
signal unit_died(unit)

# API
func resolve_player_move(player, from, to) -> Array[Node3D]  # enemies that react
func deal_damage(attacker, target, amount)
func get_enemies_threatening(coord) -> Array[Node3D]
```

### 3. RewindSystem (autoload)

**Purpose**: State snapshots and restoration

```gdscript
# Signals
signal state_saved
signal state_rewound

# API
func save_state()
func can_rewind() -> bool
func rewind()
func reset()
```

### 4. UnitRegistry (autoload)

**Purpose**: Central registry for player and enemies

```gdscript
# Signals
signal enemy_removed(enemy)

# API
func register_player(p)
func register_enemy(e)
func remove_enemy(e)
func get_enemy_at(coord) -> Node3D
func get_valid_enemies() -> Array[Node3D]
```

### 5. TileRegistry (autoload)

**Purpose**: Central registry for hex tiles

```gdscript
# API
func register_tile(tile)
func get_tile(coord) -> Node
func is_coord_blocked(coord) -> bool
```

### 6. Game.gd (Facade)

**Purpose**: Thin coordinator that delegates to systems, maintains backward compatibility

```gdscript
# Delegating properties
var player: get = UnitRegistry.player
var enemies: get = UnitRegistry.enemies
var tiles: get = TileRegistry.tiles
var is_player_turn: get = TurnSystem.is_player_turn

# Delegating methods
func get_tile(coord) -> TileRegistry.get_tile(coord)
func is_tile_blocked(coord) -> TileRegistry.is_coord_blocked(coord)
func get_enemy_at(coord) -> UnitRegistry.get_enemy_at(coord)
```

## Communication Patterns

| From       | To           | Method                                           |
| ---------- | ------------ | ------------------------------------------------ |
| Player     | TurnSystem   | Direct call: `end_player_turn()`                 |
| Player     | CombatSystem | Direct call: `resolve_player_move()`             |
| TurnSystem | RewindSystem | Direct call: `save_state()`                      |
| Enemy      | CombatSystem | Direct call: `deal_damage()`                     |
| UI         | Game         | Signals: `game_won`, `game_lost`, `turn_started` |

**Rule**: Signals for events (turn changes, damage, death). Direct calls for queries and commands needing return values.

## Implementation Phases

### Phase 1: Extract Registries

1. Create `systems/unit_registry.gd` and `systems/tile_registry.gd`
2. Add as autoloads in `project.godot`
3. Update `Game.start_game()` to populate registries
4. Add getter properties to `Game.gd` that delegate

**Files**: game.gd, project.godot, systems/unit_registry.gd, systems/tile_registry.gd

### Phase 2: Extract RewindSystem

1. Create `systems/rewind_system.gd`
2. Move `save_state()`/`rewind()` logic from game.gd
3. Update game.gd, ui.gd, player.gd to use RewindSystem

**Files**: game.gd, ui.gd, player.gd, project.godot, systems/rewind_system.gd

### Phase 3: Extract TurnSystem

1. Create `systems/turn_system.gd`
2. Move turn state and sequencing logic
3. Wire signals for turn transitions

**Files**: game.gd, player.gd, enemy.gd, project.godot, systems/turn_system.gd

### Phase 4: Extract CombatSystem

1. Create `systems/combat_system.gd`
2. Extract engagement rules from player.gd (`do_move`/`do_dash`)
3. Centralize damage application

**Files**: player.gd, enemy.gd, project.godot, systems/combat_system.gd

### Phase 5: UI Signal Migration

1. Update UI to use signals instead of polling where beneficial
2. Add appropriate signals to systems

**Files**: ui.gd

## Godot Best Practices Applied

- **Autoloads for global systems** - Standard Godot pattern for singletons
- **Signals for decoupling** - Preferred event mechanism in Godot
- **Composition over inheritance** - No forced Unit base class; player/enemy remain independent
- **Scene tree groups** - Continue using groups for node discovery
- **Facade pattern** - Game.gd maintains backward compatibility during migration

## What This Plan Does NOT Do

1. **No Unit base class** - Player and Enemy have different concerns; forced inheritance would be awkward
2. **No event bus** - Direct signals are clearer at this scale
3. **No ECS pattern** - Overkill; scene-based approach is idiomatic Godot
4. **No AI extraction** - Enemy AI is only ~50 lines; extracting it adds indirection without benefit

## Honest Assessment

### Benefits

- Clearer boundaries - each system has one job
- Easier to test systems in isolation
- Combat rules centralized in one place
- Easier to extend with new mechanics

### Costs

- 5 new files in systems/ directory
- 6 autoloads instead of 3 (Godot handles this fine)
- Slight indirection for `Game.player` access
- Developer needs to know which system to modify

### Acceptable Remaining Coupling

- Player iterating `enemies` in combat - localized and clear
- Enemy accessing `Game.player.coord` for AI - passing as parameter adds noise
- UI polling some state - signals could help but polling works

## Verification

After each phase:

1. Run the game (F5 in Godot Editor)
2. Test player movement on all tile types
3. Test combat: engage enemies, take damage, block, dash
4. Test rewind functionality
5. Complete a level to verify victory detection
6. Die to verify defeat detection
7. Test UI updates (HP, cooldowns, level progression)

## Critical Files

- [game.gd](scripts/game.gd) - Primary refactor target
- [player.gd](scripts/player.gd) - Combat logic extraction (lines 79-161)
- [enemy.gd](scripts/enemy.gd) - Threat/AI system
- [project.godot](project.godot) - Register new autoloads (lines 18-22)
- [ui.gd](scripts/ui.gd) - Signal migration
