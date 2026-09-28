"""Build assets/fonts/ui_font.ttf: Godot's default UI font (Open Sans SemiBold),
subset to just the glyphs the game can display and stored as plain TrueType.

Why: the engine's built-in default font is WOFF2, which needs the Brotli
decoder compiled into the engine. Shipping our own tiny TTF lets the custom
export templates drop Brotli (and the 46 KB embedded font) entirely.

Usage: python engine/make_ui_font.py <path-to-godot-source>
Requires: pip install fonttools brotli
"""
import os
import sys
import tempfile

from fontTools import subset
from fontTools.ttLib import TTFont, woff2

# Printable ASCII plus the two symbols used in UI strings: · —
# (Open Sans has no arrow glyph, so UI text avoids "→".)
UNICODES = list(range(0x20, 0x7F)) + [0x00B7, 0x2014]

here = os.path.dirname(os.path.abspath(__file__))
src = os.path.join(sys.argv[1], "thirdparty", "fonts", "OpenSans_SemiBold.woff2")
out = os.path.join(here, "..", "assets", "fonts", "ui_font.ttf")

with tempfile.TemporaryDirectory() as tmp:
    full_ttf = os.path.join(tmp, "full.ttf")
    woff2.decompress(src, full_ttf)
    font = TTFont(full_ttf)
    options = subset.Options()
    options.layout_features = ["kern"]
    options.hinting = False
    options.desubroutinize = True
    options.name_IDs = [0, 1, 2, 3, 4, 5, 6]
    options.flavor = None  # plain TrueType, no WOFF/WOFF2 compression
    subsetter = subset.Subsetter(options)
    subsetter.populate(unicodes=UNICODES)
    subsetter.subset(font)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    font.flavor = None
    font.save(out)

check = TTFont(out)
cmap = check.getBestCmap()
missing = [hex(u) for u in UNICODES if u not in cmap]
print(f"wrote {os.path.normpath(out)}: {os.path.getsize(out)} bytes, "
      f"{len(cmap)} glyphs mapped, flavor={check.flavor}, missing={missing}")
