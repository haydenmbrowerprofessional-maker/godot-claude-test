extends SceneTree
## Writes engine/app_icon.ico for the Windows export (application/icon).
## Without it the exporter embeds 6 PNG sizes of icon.svg (16-256 px, ~33 KB);
## Windows only needs 16/32/48 for UI and 256 for large Explorer views.
## Run with the official editor: godot --headless -s tools/make_app_icon.gd

const SIZES := [16, 32, 48, 256]
const OUT := "res://engine/app_icon.ico"


func _init() -> void:
	var svg := FileAccess.get_file_as_string("res://icon.svg")
	var base := Image.new()
	base.load_svg_from_string(svg, 256.0 / 128.0)  # icon.svg is 128x128.
	var pngs: Array[PackedByteArray] = []
	for size in SIZES:
		var img := base.duplicate() as Image
		if img.get_width() != size:
			img.resize(size, size, Image.INTERPOLATE_LANCZOS)
		pngs.append(img.save_png_to_buffer())

	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_16(0)  # Reserved.
	f.store_16(1)  # Type: icon.
	f.store_16(SIZES.size())
	var offset := 6 + 16 * SIZES.size()
	for i in SIZES.size():
		f.store_8(SIZES[i] % 256)  # 256 is stored as 0.
		f.store_8(SIZES[i] % 256)
		f.store_8(0)  # No palette.
		f.store_8(0)  # Reserved.
		f.store_16(1)  # Color planes.
		f.store_16(32)  # Bits per pixel.
		f.store_32(pngs[i].size())
		f.store_32(offset)
		offset += pngs[i].size()
	for png in pngs:
		f.store_buffer(png)
	f.close()
	print("wrote %s: %d bytes (%s px)" % [OUT, FileAccess.get_file_as_bytes(OUT).size(), SIZES])
	quit()
