"""Attribute an MSVC linker map's bytes to libraries and object files.

Size of each public symbol = distance to the next symbol in the same section
(an approximation, but good enough to find what's big).

Usage: python engine/map_sizes.py <file.map> [top_n] [filter-substring]
"""
import collections
import re
import sys

path = sys.argv[1]
top_n = int(sys.argv[2]) if len(sys.argv) > 2 else 40
filt = sys.argv[3].lower() if len(sys.argv) > 3 else ""

# " 0001:00000000       ?sym@@...        0000000140001000 f   lib:obj"
line_re = re.compile(r"^\s*([0-9a-f]{4}):([0-9a-f]{8})\s+(\S+)\s+[0-9a-f]{16}\s+(?:f\s+)?(?:i\s+)?(\S+)\s*$", re.I)

section_lengths = {}
syms = []
in_publics = False
with open(path, encoding="latin-1") as f:
    for line in f:
        if not in_publics:
            m = re.match(r"^\s*([0-9a-f]{4}):([0-9a-f]{8})\s+([0-9a-f]{8})H\s+(\S+)", line, re.I)
            if m:
                sec = int(m.group(1), 16)
                end = int(m.group(2), 16) + int(m.group(3), 16)
                section_lengths[sec] = max(section_lengths.get(sec, 0), end)
            if "Publics by Value" in line:
                in_publics = True
            continue
        if line.startswith(" entry point") or "Static symbols" in line:
            continue
        m = line_re.match(line)
        if m:
            syms.append((int(m.group(1), 16), int(m.group(2), 16), m.group(3), m.group(4)))

syms.sort()
by_lib = collections.Counter()
by_obj = collections.Counter()
by_sym = []
for i, (sec, off, name, owner) in enumerate(syms):
    if i + 1 < len(syms) and syms[i + 1][0] == sec:
        size = syms[i + 1][1] - off
    else:
        size = section_lengths.get(sec, off) - off
    if size < 0 or size > 50_000_000:
        continue
    lib, _, obj = owner.partition(":")
    if not obj:
        lib, obj = "<none>", owner
    lib = re.sub(r"\.windows\.template_release\.x86_64", "", lib)
    obj = re.sub(r"\.windows\.template_release\.x86_64", "", obj)
    key_obj = f"{lib}:{obj}"
    if filt and filt not in key_obj.lower():
        continue
    by_lib[lib] += size
    by_obj[key_obj] += size
    by_sym.append((size, name, key_obj))

total = sum(by_lib.values())
print(f"total attributed: {total / 1048576:.2f} MB over {len(by_sym)} symbols\n")
print("== by library ==")
for lib, size in by_lib.most_common(top_n):
    print(f"{size / 1024:10.0f} KB  {lib}")
print("\n== by object file ==")
for obj, size in by_obj.most_common(top_n):
    print(f"{size / 1024:10.0f} KB  {obj}")
print("\n== largest symbols ==")
for size, name, obj in sorted(by_sym, reverse=True)[:top_n]:
    print(f"{size / 1024:10.1f} KB  {obj}  {name[:90]}")
