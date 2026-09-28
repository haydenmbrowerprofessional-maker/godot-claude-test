@tool
extends EditorScenePostImport
## Import-time only: drops character animations the game never plays.
## Kenney's Mini Characters ship ~32 clips each; units only use these four.
## Hooked up via `import_script/path` in assets/characters/*.glb.import.

const KEEP: PackedStringArray = ["idle", "walk", "attack-melee-right", "holding-right-shoot"]


func _post_import(scene: Node) -> Object:
	for player: AnimationPlayer in scene.find_children("*", "AnimationPlayer", true, false):
		for lib_name in player.get_animation_library_list():
			var lib := player.get_animation_library(lib_name)
			for anim_name in lib.get_animation_list():
				if not KEEP.has(String(anim_name)):
					lib.remove_animation(anim_name)
	return scene
