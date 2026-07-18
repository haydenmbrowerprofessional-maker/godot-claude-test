# Mini Command

A small real-time strategy game built in **Godot 4**, inspired by *Totem Tribe*: explore a fog-covered fantasy map, expand your village through a building tech tree, clear enemy camps, hunt hidden gems, and raise the Grand Totem to win.

## How to run

1. Install [Godot 4.3+](https://godotengine.org/download) (standard build, not .NET).
2. Open Godot → **Import** → select this folder's `project.godot`.
3. Press **F5** (Run Project).

## How to play

You start with a Hut, three fighters, and a dark map.

- **Explore** — the fog lifts permanently around your units and buildings. Enemy camps and gems stay hidden until you scout them.
- **Build** — the build bar (bottom) places buildings on revealed ground. The tech tree gates each tier:

  | Building | Requires | Effect |
  |---|---|---|
  | Hut | — | Trains fighters (max 3 alive per hut; a slot frees when one dies) |
  | Watchtower | Hut | Shoots nearby enemies, wide vision |
  | Workshop | Watchtower | +30% unit damage while standing |
  | Grand Totem | Workshop + 3 gems | **Build it to win** |

- **Fight** — camps respawn creeps (same 3-cap spawner as your huts) until destroyed. Creeps aggro your units and buildings.
- **Collect** — 4 gems are hidden in the map's corners; walk a unit over one to take it. You need 3 for the totem.

Defeat comes only when every unit *and* building you own is gone.

### Controls

| Input | Action |
|---|---|
| Left-click / drag | Select unit / box-select squad (Shift adds) |
| Right-click | Move (formation spread) / attack target |
| Build bar button | Enter placement (LMB place, RMB/Esc cancel) |
| WASD / arrows | Pan camera |
| Mouse wheel | Zoom |

## Architecture

Reusable scenes are instanced (cloned), never assembled node-by-node in code:

```
├── scenes/
│   ├── main.tscn            # the map: fog, camps, gems, scenery, camera
│   ├── unit.tscn            # base unit; unit_blue/red.tscn add team models
│   ├── buildings/           # hut, watchtower, workshop, grand_totem, camp
│   ├── gem.tscn             # collectible (Area3D + spinning jewel)
│   ├── ghost.tscn           # placement preview disc
│   └── hud.tscn             # build bar, objectives, selection, end screen
├── scripts/
│   ├── main.gd              # placement mode, tech gating, orders, win/lose
│   ├── destructible.gd      # building base: team, health, footprint
│   ├── spawner.gd           # timed unit production with living-unit cap
│   ├── tower.gd             # auto-attack defense
│   ├── workshop.gd          # damage buff while standing
│   ├── grand_totem.gd       # victory trigger
│   ├── fog_of_war.gd        # reveal mask painting + enemy visibility
│   ├── unit.gd              # movement, auto-aggro, melee combat
│   ├── game_state.gd        # autoload: gems, tech buffs
│   └── camera_rig.gd, hud.gd, gem.gd, ghost.gd, selection_rect.gd
└── tools/                   # headless smoke tests (see below)
```

Notable mechanics:

- **Fog of war** — a dark plane hangs above the map; its shader samples a 160x160 reveal mask that `fog_of_war.gd` paints white circles into around friendly vision sources, four times a second. Revealed stays revealed (Totem Tribe style), and enemies toggle visibility based on the mask.
- **Placement** — build buttons spawn a ghost disc that follows the mouse, green/red for validity (revealed ground, in bounds, clear of other buildings). Valid click clones the building's scene into the world.
- **Tech gating** — buildings register by scene path; the build bar enables tiers from live counts, so losing your last Watchtower re-locks the Workshop tier.

## Headless tests

```bash
godot --headless -s tools/combat_smoke_test.gd     # 2v1 fight resolves
godot --headless -s tools/building_smoke_test.gd   # spawn cap, respawn, destructibility
godot --headless -s tools/gem_smoke_test.gd        # walking over a gem collects it
godot --headless -s tools/fog_smoke_test.gd        # reveal persists, gates enemy visibility
```

## Roadmap

- [x] Camera rig, map, scenery
- [x] Unit selection (click + drag box) and move orders
- [x] Melee combat, auto-aggro, win/lose
- [x] Production buildings (timed spawns, 3-unit cap, destructible)
- [x] Fog-of-war exploration, hidden gems
- [x] Building placement + tech tree (Hut → Watchtower → Workshop → Grand Totem)
- [ ] Pathfinding around obstacles (NavigationRegion3D)
- [ ] More maps / level progression
- [ ] More unit types and tech branches
- [ ] Enemy wave AI
- [ ] Minimap

## Credits

All models are **CC0 (public domain)** by [Kenney](https://kenney.nl):

- [Mini Characters](https://kenney.nl/assets/mini-characters-1) — unit models (rigged + animated)
- [Platformer Kit](https://kenney.nl/assets/platformer-kit) — trees, rocks, flags, gems
- [Fantasy Town Kit](https://kenney.nl/assets/fantasy-town-kit) — building pieces, banners, scenery

## License

Code is MIT (see [LICENSE](LICENSE)). Models are CC0 by Kenney.
