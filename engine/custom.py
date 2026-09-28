# SCons profile for Mini Command's size-optimized export templates.
# Build from a Godot 4.5-stable checkout:
#   scons platform=<windows|linux|web> target=template_release profile=<path>/engine/custom.py
#
# Everything here strips engine features the game never touches. If you add a
# feature (audio, 2D physics, navigation, a new module...), re-enable it here.

# --- Optimize for size -------------------------------------------------------
production = "yes"
optimize = "size_extra"
lto = "full"
debug_symbols = "no"
deprecated = "no"

# --- Rendering: GL Compatibility only (no RenderingDevice backends) ---------
vulkan = "no"
d3d12 = "no"
metal = "no"
opengl3 = "yes"

# --- Engine subsystems the game doesn't use ----------------------------------
disable_physics_2d = "yes"
disable_navigation_2d = "yes"
disable_navigation_3d = "yes"
disable_xr = "yes"
disable_advanced_gui = "yes"
minizip = "no"
brotli = "no"
accesskit = "no"
sdl = "no"

# --- Modules: whitelist only what the game needs -----------------------------
modules_enabled_by_default = "no"
module_gdscript_enabled = "yes"          # game logic
module_godot_physics_3d_enabled = "yes"  # CharacterBody3D, raycasts, Area3D
module_freetype_enabled = "yes"          # font rasterizing for the HUD
module_text_server_fb_enabled = "yes"    # lightweight text server (no ICU/HarfBuzz)

# Engine patches (engine/patches/) add this option.
builtin_controller_mappings = "no"  # keyboard/mouse only; skip the gamepad DB
freetype_minimal = "yes"            # TrueType only: no PS/CFF/bitmap formats, hinting VM, var fonts
