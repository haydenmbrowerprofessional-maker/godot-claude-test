#!/usr/bin/env bash
# Builds Mini Command's size-optimized Godot export templates.
#
# Usage: engine/build_templates.sh <godot-source-dir> <windows|linux|web>...
#
#   - Checks out Godot 4.5-stable into <godot-source-dir> if it isn't there.
#   - Applies engine/patches/*.patch (skipped when already applied).
#   - Builds template_release with engine/custom.py + engine/build_profile.gdbuild.
#   - Copies the result into engine/templates/, where export_presets.cfg finds it.
#
# Toolchains: Windows needs Visual Studio 2022 (C++ workload); Linux needs
# GCC/Clang; Web needs an activated Emscripten 4.0.11 (emsdk). Python + SCons
# (pip install scons) on all.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
src="$1"; shift
tag="4.5-stable"

if [ ! -d "$src/.git" ]; then
	git clone --depth 1 --branch "$tag" https://github.com/godotengine/godot.git "$src"
fi

for p in "$here"/patches/*.patch; do
	if git -C "$src" apply --reverse --check "$p" 2>/dev/null; then
		echo "patch already applied: $(basename "$p")"
	else
		git -C "$src" apply "$p"
		echo "applied patch: $(basename "$p")"
	fi
done

mkdir -p "$here/templates"
touch "$here/templates/.gdignore"
jobs="${JOBS:-$(nproc 2>/dev/null || echo 8)}"

for platform in "$@"; do
	echo "=== building $platform template ==="
	extra=()
	[ "$platform" = "web" ] && extra+=(threads=no)
	(cd "$src" && MSYS_NO_PATHCONV=1 python -m SCons platform="$platform" target=template_release \
		"profile=$here/custom.py" "build_profile=$here/build_profile.gdbuild" "${extra[@]}" -j"$jobs")
	case "$platform" in
		windows) cp "$src/bin/godot.windows.template_release.x86_64.exe" "$here/templates/windows_release_x86_64.exe" ;;
		linux)   cp "$src/bin/godot.linuxbsd.template_release.x86_64" "$here/templates/linux_release.x86_64" ;;
		web)     cp "$src/bin/godot.web.template_release.wasm32.nothreads.zip" "$here/templates/web_nothreads_release.zip" ;;
	esac
done
ls -l "$here/templates"
