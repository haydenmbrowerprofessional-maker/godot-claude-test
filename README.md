# Mini Command

A small real-time strategy game built in **Godot 4**. Select your squad, issue orders, and wipe out the red team. Early days — see the roadmap below.

## How to run

1. Install [Godot 4.3+](https://godotengine.org/download) (standard build, not .NET).
2. Open Godot → **Import** → select this folder's `project.godot`.
3. Press **F5** (Run Project).

## Controls

| Input | Action |
|---|---|
| Left-click / drag | Select unit / box-select squad (Shift adds) |
| Right-click ground | Move selected units (formation spread) |
| Right-click enemy unit or building | Attack target |
| WASD / arrows | Pan camera |
| Mouse wheel | Zoom |

Units also auto-attack enemies that wander into aggro range. Each team's barracks trains a new unit every few seconds, but supports **at most 3 living units at a time** — a slot frees up when one of its units dies. Destroy all red units *and* the red barracks to win.

## Architecture

Reusable scenes are instanced (cloned), never assembled node-by-node in code:

```
├── scenes/
│   ├── main.tscn        # map: ground, sky, scenery, camera rig, HUD
│   ├── unit.tscn        # base unit: body, collision, selection ring, health bar
│   ├── unit_blue.tscn   # inherits unit.tscn + player character model
│   ├── unit_red.tscn    # inherits unit.tscn + enemy character model
│   ├── building.tscn    # base barracks: collision, health bar, spawn timer
│   ├── building_blue/red.tscn  # watchtower composed from town-kit pieces
│   └── hud.tscn         # selection rectangle, status line, end screen
├── scripts/
│   ├── main.gd          # spawning (scene cloning), selection, order routing, win/lose
│   ├── unit.gd          # movement, auto-aggro, melee combat, health
│   ├── building.gd      # timed unit production with living-unit cap
│   ├── camera_rig.gd    # RTS camera pan/zoom
│   ├── hud.gd           # UI updates
│   └── selection_rect.gd
├── tools/
│   ├── combat_smoke_test.gd     # headless: 2v1 fight must resolve (CI-able)
│   ├── building_smoke_test.gd   # headless: spawn cap, respawn-on-death, destructibility
│   └── inspect_assets.gd        # prints model sizes + animation lists
└── assets/              # CC0 models (see credits)
```

Key mechanics:

- **Selection** — click raycasts against the unit collision layer; drag-box projects unit positions to screen space and tests them against the rectangle.
- **Orders** — right-click raycasts ground + units in one pass: enemies become attack targets, ground points become move targets with a grid formation spread.
- **Combat** — units chase into melee range, attack on a cooldown, and play the matching character animations (walk, attack, idle). Idle units scan for nearby enemies twice a second. Wide targets (buildings) add their footprint radius to melee reach so corners are attackable.
- **Production** — each barracks clones its team's unit scene on a timer, tracks its living units, and refuses to spawn past the cap until one dies.

## Headless tests

```bash
godot --headless -s tools/combat_smoke_test.gd
godot --headless -s tools/building_smoke_test.gd
```

## Roadmap

- [x] Camera rig, map, scenery
- [x] Unit selection (click + drag box) and move orders
- [x] Melee combat, auto-aggro, win/lose
- [x] Production buildings (timed spawns, 3-unit cap, destructible)
- [ ] Pathfinding around obstacles (NavigationRegion3D)
- [ ] Resource gathering (jewel pickups)
- [ ] Base construction (place new buildings)
- [ ] Enemy wave AI
- [ ] Minimap

## Credits

All models are **CC0 (public domain)** by [Kenney](https://kenney.nl):

- [Mini Characters](https://kenney.nl/assets/mini-characters-1) — unit models (rigged + animated)
- [Platformer Kit](https://kenney.nl/assets/platformer-kit) — trees, rocks, flags, flowers
- [Fantasy Town Kit](https://kenney.nl/assets/fantasy-town-kit) — barracks walls, roofs, banners

## License

Code is MIT (see [LICENSE](LICENSE)). Models are CC0 by Kenney.
