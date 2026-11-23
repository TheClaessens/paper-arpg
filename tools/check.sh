#!/usr/bin/env bash
# Project check, run by the pre-commit hook. Fails if a tracked file is empty, a comment line in a
# script is over-long, any script, scene or resource doesn't load (parse errors, including typing
# warnings that project.godot treats as errors) or a test fails.
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

echo "== no empty file"
empty=$(git ls-files -z | while IFS= read -r -d '' file; do
	case ${file##*/} in (.gdignore | .gitkeep) continue ;; esac
	[[ -f "$file" && ! -s "$file" ]] && echo "$file"
done)
if [[ -n "$empty" ]]; then
	echo "$empty"
	echo "!! empty file (a failed edit leaves one: restore it from git, or delete it)"
	exit 1
fi

echo "== comment lines"
# A line that is only a comment is at most 110 characters (tabs count as one). Characters, not bytes:
# comments here hold `é`, `›` and `°`, and macOS's awk counts bytes whatever the locale, so perl counts.
# The inner read needs a newline separator: -0 made NUL the outer one, for the NUL-separated names.
long=$(git ls-files -z autoloads characters skills ui scenes props rendering tests tools |
	perl -0ne 'chomp; next unless /\.gd$/; my $file = $_;
		open(my $in, "<:encoding(UTF-8)", $file) or next;
		local $/ = "\n";
		while (my $line = <$in>) {
			chomp $line;
			print "$file:$.: ", length($line), " characters\n" if $line =~ /^\s*#/ && length($line) > 110;
		}
		close $in')
if [[ -n "$long" ]]; then
	echo "$long"
	echo "!! comment lines over 110 characters (re-wrap them)"
	exit 1
fi

step "import" "SCRIPT ERROR" "$GODOT" --headless --path . --import
step "load every script, scene and resource" "Parse Error|GDScript::reload|FAILED|load_all:" \
	"$GODOT" --headless --path . --script res://tools/load_all.gd
step "tests" "\[Failed\]|Passing Tests|Failing Tests|All tests passed" \
	"$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd
echo "== check passed"
