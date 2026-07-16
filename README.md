# Creep Dodge

A small arcade game built in **Godot 4**: creeps swarm in from the edges of the screen — dodge them for as long as you can. Score is seconds survived.

## How to run

1. Install [Godot 4.3+](https://godotengine.org/download) (standard build, not .NET).
2. Open Godot → **Import** → select this folder's `project.godot`.
3. Press **F5** (Run Project).

## Controls

| Key | Action |
|---|---|
| Arrow keys | Move |
| Start button | Begin / restart |

## Project structure

The game follows Godot's scene-composition idiom: reusable scenes are instanced (cloned), never assembled node-by-node in code.

```
├── project.godot        # Godot 4 project config (480x720, GL Compatibility)
├── scenes/
│   ├── main.tscn        # game root: player + HUD instances, spawn path, timers
│   ├── player.tscn      # Area2D + animated sprite + capsule collision
│   ├── mob.tscn         # RigidBody2D creep, cloned by main.gd each spawn tick
│   └── hud.tscn         # CanvasLayer: score, messages, start button
├── scripts/
│   ├── main.gd          # game loop: spawning (mob_scene.instantiate()), scoring
│   ├── player.gd        # movement, screen clamping, hit signal
│   ├── mob.gd           # random animation, self-free off screen
│   └── hud.gd           # UI updates, start_game signal
└── art/                 # CC0 sprites (see credits)
```

Mobs spawn on a `Path2D` ring around the screen edge: a `PathFollow2D` jumps to a random `progress_ratio`, and the mob launches inward with randomized speed and spread. Nodes communicate with signals (`Player.hit → Main.game_over`, `HUD.start_game → Main.new_game`) rather than hard references.

## Credits

- **Sprites:** ["Abstract Platformer"](https://kenney.nl/assets/abstract-platformer) art pack by [Kenney](https://kenney.nl) — public domain (CC0).
- Game design based on the classic "Dodge the Creeps" Godot tutorial concept.

## License

Code is MIT (see [LICENSE](LICENSE)). Art is CC0 by Kenney.
