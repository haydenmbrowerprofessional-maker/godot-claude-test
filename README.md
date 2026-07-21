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
  | Hut | — | Trains **Soldiers** — balanced melee (max 3 alive per building; a slot frees when one dies) |
  | Archery Range | Hut | Trains **Archers** — ranged, fragile |
  | Watchtower | Hut | Shoots nearby enemies, wide vision — **upgradeable** |
  | Barracks | Watchtower | Trains **Knights** — tanky, slow, hard-hitting |
  | Workshop | Watchtower | +30% unit damage; unlocks the top tower tier |
  | Grand Totem | Workshop + 3 gems | **Build it to win** |

- **Unit types** — Soldiers are the all-rounder; Archers strike from range but fold in melee; Knights soak hits and hit hard but move slowly. Enemy camps field the same three flavors (grunts, skirmishers, brutes).
- **Tower upgrades** — click a friendly Watchtower to select it, then use the upgrade panel to raise it through three tiers: **Arrow → Reinforced → Ballista**, each boosting damage, range, and fire rate. The final tier needs a Workshop.
- **Fight** — camps respawn creeps (same 3-cap spawner as your huts) until destroyed. Creeps aggro your units and buildings.
- **Collect** — 4 gems are hidden in the map's corners; walk a unit over one to take it. You need 3 for the totem.

Defeat comes only when every unit *and* building you own is gone.

### Controls

| Input | Action |
|---|---|
| Left-click / drag | Select unit / box-select squad (Shift adds) |
| Left-click tower | Select a Watchtower to upgrade it |
| Right-click | Move (formation spread) / attack target |
| Build bar button | Enter placement (LMB place, RMB/Esc cancel) |
| WASD / arrows | Pan camera |
| Mouse wheel | Zoom |

## Architecture

Reusable scenes are instanced (cloned), never assembled node-by-node in code:

```
├── scenes/
│   ├── main.tscn            # the map: fog, camps, gems, scenery, camera
│   ├── unit.tscn            # base unit; unit_blue/red (soldier) + unit_{archer,knight}_{blue,red} add stats + models
│   ├── buildings/           # hut, archery_range, watchtower, barracks, workshop, grand_totem, camp
│   ├── gem.tscn             # collectible (Area3D + spinning jewel)
│   ├── ghost.tscn           # placement preview disc
│   └── hud.tscn             # build bar, objectives, selection, end screen
├── scripts/
│   ├── main.gd              # placement mode, tech gating, orders, win/lose
│   ├── destructible.gd      # building base: team, health, footprint
│   ├── spawner.gd           # timed unit production with living-unit cap
│   ├── tower.gd             # auto-attack defense; 3-tier in-place upgrades
│   ├── workshop.gd          # damage buff while standing
│   ├── grand_totem.gd       # victory trigger
│   ├── fog_of_war.gd        # reveal mask painting + enemy visibility
│   ├── unit.gd              # movement, auto-aggro, melee + ranged combat
│   ├── game_state.gd        # autoload: gems, tech buffs
│   └── camera_rig.gd, hud.gd, gem.gd, ghost.gd, selection_rect.gd
└── tools/                   # headless smoke tests (see below)
```

Notable mechanics:

- **Fog of war** — a dark plane hangs above the map; its shader samples a 160x160 reveal mask that `fog_of_war.gd` paints white circles into around friendly vision sources, four times a second. Revealed stays revealed (Totem Tribe style), and enemies toggle visibility based on the mask.
- **Placement** — build buttons spawn a ghost disc that follows the mouse, green/red for validity (revealed ground, in bounds, clear of other buildings). Valid click clones the building's scene into the world.
- **Tech gating** — buildings register by scene path; the build bar enables tiers from live counts, so losing your last Watchtower re-locks the Workshop tier.
- **Unit variety** — every unit shares `unit.gd`; variants are scenes that override exported stats (health, speed, damage, `attack_range`, `ranged`) and swap the character model. Ranged units keep their distance via `attack_range` and play a shoot animation.
- **Tower upgrades** — `tower.gd` holds a 3-entry level table; `upgrade()` bumps the tier and re-applies damage/range/fire-rate and a visual accent. `main.gd` gates the top tier on the Workshop and drives selection + the upgrade panel.

## Headless tests

```bash
godot --headless -s tools/combat_smoke_test.gd     # 2v1 fight resolves
godot --headless -s tools/building_smoke_test.gd   # spawn cap, respawn, destructibility
godot --headless -s tools/gem_smoke_test.gd        # walking over a gem collects it
godot --headless -s tools/fog_smoke_test.gd        # reveal persists, gates enemy visibility
godot --headless -s tools/units_smoke_test.gd      # unit variants + ranged combat
godot --headless -s tools/tower_smoke_test.gd      # tower upgrade tiers + firing
```

## Roadmap

- [x] Camera rig, map, scenery
- [x] Unit selection (click + drag box) and move orders
- [x] Melee combat, auto-aggro, win/lose
- [x] Production buildings (timed spawns, 3-unit cap, destructible)
- [x] Fog-of-war exploration, hidden gems
- [x] Building placement + tech tree (Hut → Watchtower → Workshop → Grand Totem)
- [x] Multiple unit types (Soldier / Archer / Knight) with ranged combat
- [x] Upgradeable towers (Arrow → Reinforced → Ballista)
- [ ] Pathfinding around obstacles (NavigationRegion3D)
- [ ] More maps / level progression
- [ ] Enemy wave AI
- [ ] Minimap

## Credits

All models are **CC0 (public domain)** by [Kenney](https://kenney.nl):

- [Mini Characters](https://kenney.nl/assets/mini-characters-1) — unit models (rigged + animated)
- [Platformer Kit](https://kenney.nl/assets/platformer-kit) — trees, rocks, flags, gems
- [Fantasy Town Kit](https://kenney.nl/assets/fantasy-town-kit) — building pieces, banners, scenery

## License

Code is MIT (see [LICENSE](LICENSE)). Models are CC0 by Kenney.
