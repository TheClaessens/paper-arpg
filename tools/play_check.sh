#!/usr/bin/env bash
# Prints a checksum of a short headless play, to compare a branch with master: the lines differ
# only when play does. Usage: tools/play_check.sh [swing|ball|pierce]...   (all three by default)
# Writes an override.cfg next to project.godot (single-threaded avoidance, so runs repeat) and
# removes it on exit. Refuses to run when one already exists: it is the developer's own.
# Set GODOT to use a Godot binary that isn't on PATH as `godot`.
set -uo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"

case_commands() {
	case $1 in
	swing) echo '"tp 19 4" "activate 1 1 0"' ;;
	ball) echo '"tp 14 6" "bar 2 Fireball" "activate 2 1 0"' ;;
	pierce) echo '"tp 14 6" "bar 2 Fireball" "modifier pierce on" "activate 2 1 0"' ;;
	*) return 1 ;;
	esac
}

checksum() {
	if command -v md5 >/dev/null; then md5 -q; else md5sum | cut -d' ' -f1; fi
}

cases=("$@")
((${#cases[@]} > 0)) || cases=(swing ball pierce)
for name in "${cases[@]}"; do
	if ! case_commands "$name" >/dev/null; then
		echo "Usage: tools/play_check.sh [swing|ball|pierce]..." >&2
		exit 1
	fi
done

if [[ -e override.cfg ]]; then
	echo "!! override.cfg exists next to project.godot; move it away first" >&2
	exit 1
fi
trap 'rm -f override.cfg' EXIT
printf '[navigation]\navoidance/thread_model/avoidance_use_multiple_threads=false\n' >override.cfg

for name in "${cases[@]}"; do
	# The commands are quoted words in a string, so eval splits them into arguments.
	out=$(eval "\"\$GODOT\" --headless --fixed-fps 60 --path . --script res://tools/simulate.gd -- res://scenes/game.tscn 4 $(case_commands "$name")" 2>/dev/null | grep -E '^(t=|  )')
	if [[ -z "$out" ]]; then
		echo "!! $name: the run printed no positions" >&2
		exit 1
	fi
	echo "$name $(checksum <<<"$out")"
done
