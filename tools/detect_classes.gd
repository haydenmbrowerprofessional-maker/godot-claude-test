extends SceneTree
## Generates engine/build_profile.gdbuild: the engine classes Mini Command
## never uses, so the custom export templates can compile them out.
##
## A class is kept when the game can reach it by name, which is the only way
## a compiled-out class breaks at runtime (engine-internal objects still
## self-register on first construction, see Object::_initialize()):
##   - every object found by loading and walking each game resource/scene,
##   - every class name written in a game script (Timer.new(), type hints...),
##   - engine singletons and families the runtime creates by name
##     (InputEvent* from project.godot, MainLoop/SceneTree, StyleBox*),
##   - FORCE_KEEP below (types reached through untyped script calls),
##   - plus every ancestor of the above.
## Everything else of API_CORE is disabled (only top-most classes are listed,
## children are disabled implicitly), mirroring the editor's
## "Detect from Project" in editor/settings/editor_build_profile.cpp.
##
## Run with the official editor: godot --headless -s tools/detect_classes.gd

const SKIP_DIRS := ["res://.godot", "res://build", "res://engine", "res://tools"]
const RESOURCE_EXTS := ["tscn", "tres", "scn", "res", "gd", "gdshader", "glb", "png", "svg", "ttf"]
const FAMILIES := ["InputEvent", "MainLoop", "StyleBox"]
const FORCE_KEEP := [
	"Window", "Viewport", "World3D", "PhysicsDirectSpaceState3D", "PhysicsRayQueryParameters3D",
	"SceneTreeTimer", "KinematicCollision3D", "Input", "InputMap", "Image", "ImageTexture",
	"TextServerFallback", "TextServerManager", "GDScriptFunctionState",
]
const OUT := "res://engine/build_profile.gdbuild"

var used := {}
var visited := {}


func _init() -> void:
	var files: PackedStringArray = []
	_collect_files("res://", files)
	for path in files:
		_scan_file(path)

	# Classes the runtime instantiates by name or reaches implicitly.
	for family in FAMILIES:
		used[family] = true
		for c in ClassDB.get_inheriters_from_class(family):
			used[c] = true
	for name in Engine.get_singleton_list():
		var s := Engine.get_singleton(name)
		if s:
			used[s.get_class()] = true
	for c in FORCE_KEEP:
		used[c] = true
	used[ProjectSettings.get_setting("application/run/main_loop_type", "SceneTree")] = true

	# Keep every ancestor of a used class.
	for c in used.keys():
		var p: StringName = c
		while p != &"" and ClassDB.class_exists(p):
			used[p] = true
			p = ClassDB.get_parent_class(p)

	var disabled: PackedStringArray = []
	for c in ClassDB.get_class_list():
		if used.has(c) or c.begins_with("Editor") or ClassDB.class_get_api_type(c) != ClassDB.API_CORE:
			continue
		var parent := ClassDB.get_parent_class(c)
		if parent == &"" or used.has(parent):
			disabled.append(c)  # Top-most unused class; its subtree goes with it.
	disabled.sort()

	var kept: PackedStringArray = []
	for c in used.keys():
		if ClassDB.class_exists(c) and ClassDB.class_get_api_type(c) == ClassDB.API_CORE:
			kept.append(c)
	kept.sort()

	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(JSON.stringify({"type": "build_profile", "disabled_classes": disabled}, "\t") + "\n")
	f.close()
	print("scanned %d files; keeping %d core classes, disabling %d top-level classes" % [files.size(), kept.size(), disabled.size()])
	print("KEPT: ", ", ".join(kept))
	quit()


func _collect_files(dir: String, out: PackedStringArray) -> void:
	if SKIP_DIRS.has(dir.trim_suffix("/")):
		return
	for d in DirAccess.get_directories_at(dir):
		if not d.begins_with("."):
			_collect_files(dir.path_join(d), out)
	for f in DirAccess.get_files_at(dir):
		if RESOURCE_EXTS.has(f.get_extension()):
			out.append(dir.path_join(f))


func _scan_file(path: String) -> void:
	if path.get_extension() == "gd":
		_scan_script_source(FileAccess.get_file_as_string(path))
	if not ResourceLoader.exists(path):
		return
	var res := load(path)
	if res is PackedScene:
		var inst := (res as PackedScene).instantiate()
		_walk(res)
		_walk(inst)
		inst.free()
	else:
		_walk(res)


func _scan_script_source(src: String) -> void:
	var re := RegEx.create_from_string("\\b[A-Z][A-Za-z0-9_]*\\b")
	for m in re.search_all(src):
		var word := m.get_string()
		if ClassDB.class_exists(word):
			used[word] = true


func _walk(value: Variant) -> void:
	if value is Array:
		for v in value:
			_walk(v)
		return
	if value is Dictionary:
		for k in value:
			_walk(k)
			_walk(value[k])
		return
	if not (value is Object) or value == null:
		return
	var obj: Object = value
	var id := obj.get_instance_id()
	if visited.has(id):
		return
	visited[id] = true
	used[obj.get_class()] = true
	if obj is GDScript:
		_scan_script_source((obj as GDScript).source_code)
	for prop in obj.get_property_list():
		if prop.usage & PROPERTY_USAGE_STORAGE and (prop.type == TYPE_OBJECT or prop.type == TYPE_ARRAY or prop.type == TYPE_DICTIONARY):
			_walk(obj.get(prop.name))
	if obj is Node:
		for child in (obj as Node).get_children(true):
			_walk(child)
