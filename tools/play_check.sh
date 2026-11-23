#!/usr/bin/env bash
# Prints a checksum of a short headless play, to compare a branch with master: the lines differ
# only when play does. Usage: tools/play_check.sh [swing|ball|pierce]...   (all three by default)
# Writes an override.cfg next to project.godot (single-threaded avoidance, so runs repeat) and
# removes it on exit. Refuses to run when one already exists: it is the developer's own.
# Set GODOT to use a Godot binary that isn't on PATH as `godot`.
set -uo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"

# Sets `commands` to the console commands of the case, or returns 1 for a name that is none.
set_commands() {
	case $1 in
	swing) commands=("tp 19 4" "activate 1 1 0") ;;
	ball) commands=("tp 14 6" "bar 2 Fireball" "activate 2 1 0") ;;
	pierce) commands=("tp 14 6" "bar 2 Fireball" "modifier pierce on" "activate 2 1 0") ;;
	*) return 1 ;;
	esac
}

checksum() {
	if command -v md5 >/dev/null; then md5 -q; else md5sum | cut -d' ' -f1; fi
}

cases=("$@")
((${#cases[@]} > 0)) || cases=(swing ball pierce)
for name in "${cases[@]}"; do
	if ! set_commands "$name"; then
		echo "Usage: tools/play_check.sh [swing|ball|pierce]..." >&2
		exit 1
	fi
done

if [[ -e override.cfg ]]; then
	echo "!! override.cfg exists next to project.godot; move it away first" >&2
	exit 1
fi
errfile=$(mktemp)
trap 'rm -f override.cfg "$errfile"' EXIT
printf '[navigation]\navoidance/thread_model/avoidance_use_multiple_threads=false\n' >override.cfg

# fail <case> <what went wrong> [text to show]: reports on stderr and ends the script.
fail() {
	echo "!! $1: $2" >&2
	[[ -n "${3:-}" ]] && echo "$3" >&2
	exit 1
}

for name in "${cases[@]}"; do
	set_commands "$name"
	status=0
	# Godot's stderr holds unrelated warnings in a normal run: it is shown only when the run fails.
	all=$("$GODOT" --headless --fixed-fps 60 --path . --script res://tools/simulate.gd -- \
		res://scenes/game.tscn 4 "${commands[@]}" 2>"$errfile") || status=$?
	((status == 0)) || fail "$name" "Godot exited with status $status" "$(cat "$errfile")"
	# simulate.gd prints `> <command>` and then the console's answer; these are the refusals.
	refused=$(grep -E -B1 '^(Unknown command|Usage:|Unknown Skill)' <<<"$all")
	[[ -z "$refused" ]] || fail "$name" "the console refused a command" "$refused"
	out=$(grep -E '^(t=|  )' <<<"$all")
	[[ -n "$out" ]] || fail "$name" "the run printed no positions" "$all
$(cat "$errfile")"
	echo "$name $(checksum <<<"$out")"
done
