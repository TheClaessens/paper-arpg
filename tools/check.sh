#!/usr/bin/env bash
# Project check, run by the pre-commit hook. Fails if any script, scene or resource doesn't load
# (parse errors, including typing warnings that project.godot treats as errors) or a test fails.
# Set GODOT to use a Godot binary that isn't on PATH as `godot`.
set -uo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"

# step <label> <grep filter for the lines worth showing> <command...>
step() {
	local label=$1 filter=$2 out status=0
	shift 2
	echo "== $label"
	out=$("$@" 2>&1) || status=$?
	grep -E "$filter" <<<"$out"
	# Godot falls back to the path on a bad uid="..." and only warns, so catch it here.
	if grep "invalid UID" <<<"$out"; then
		echo "!! $label: invalid UID (fix it, or drop the uid attribute)"
		exit 1
	fi
	if ((status != 0)); then
		echo "!! $label failed (exit $status)"
		exit "$status"
	fi
}

step "import" "SCRIPT ERROR" "$GODOT" --headless --path . --import
step "load every script, scene and resource" "Parse Error|GDScript::reload|FAILED|load_all:" \
	"$GODOT" --headless --path . --script res://tools/load_all.gd
step "tests" "\[Failed\]|Passing Tests|Failing Tests|All tests passed" \
	"$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd
echo "== check passed"
