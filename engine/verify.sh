#!/usr/bin/env bash
# Runs every headless smoke test *inside an exported build*, so a stripped
# custom engine is exercised exactly as players get it. Any engine/script
# error printed during a run fails it, even if the test itself reports PASS.
#
# Usage: engine/verify.sh <exported-binary> <tests.pck>
#   (export the pack with: godot --headless --export-pack "Test Pack" build/tests.pck)
set -u
bin="$1"
pck="$2"
tests="combat building gem fog units tower e2e"
failed=0

run() {  # $1 = label, rest = args
	local label="$1"; shift
	local out
	out=$("$bin" --headless "$@" 2>&1)
	local errors
	errors=$(printf '%s\n' "$out" | grep -E "SCRIPT ERROR|^ERROR|Parse Error|Invalid call|Nonexistent" | sort | uniq -c)
	local verdict
	verdict=$(printf '%s\n' "$out" | grep -E "SMOKE TEST (PASS|FAIL)" | head -1)
	if [ -n "$errors" ] || { [ -n "$verdict" ] && [[ "$verdict" != *PASS* ]]; }; then
		failed=1
		printf '%-9s FAIL %s\n' "$label" "$verdict"
		printf '%s\n' "$errors" | sed 's/^/            /'
	else
		printf '%-9s ok   %s\n' "$label" "${verdict:-clean}"
	fi
}

run boot --quit-after 300
for t in $tests; do
	run "$t" --main-pack "$pck" -s "res://tools/${t}_smoke_test.gd"
done
exit $failed
