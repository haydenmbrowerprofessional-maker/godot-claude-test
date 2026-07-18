extends Node
## Autoload: run-wide state shared across scripts (gems, tech buffs).
## Reset by main.gd on every new game since autoloads survive scene reloads.

signal gems_changed(count: int)
signal totem_built

var gems := 0
var damage_multiplier := 1.0


func reset() -> void:
	gems = 0
	damage_multiplier = 1.0


func collect_gem() -> void:
	gems += 1
	gems_changed.emit(gems)
