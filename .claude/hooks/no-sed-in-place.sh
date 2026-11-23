#!/usr/bin/env bash
# PreToolUse hook for Bash (see .claude/settings.json): refuses in-place sed. On macOS, `sed -i`
# takes its next argument as a backup suffix, and a run that failed that way left a tracked file
# empty. The Edit tool changes a file without that risk.
# It guards against the accident, not against someone set on it: sed inside a quoted string
# (`sh -c '...'`) or a heredoc is not seen, and GNU sed called as `gsed` is let through.
# Without jq it refuses nothing; tools/check.sh still fails on the empty file.
command=$(jq -r '.tool_input.command // empty')
# Heredoc bodies and quoted strings are text, not commands (a commit message, a search pattern, a
# sed script with a `|` in it): drop them before looking.
bare=$(perl -0pe 's/<<-?\s*["\x27]?(\w+)["\x27]?[^\n]*\n.*?\n\s*\1\b//gs;
	s/\x27[^\x27]*\x27//g; s/"(?:\\.|[^"\\])*"//g' <<<"$command")
# sed as a command word (or by its path), then in the same simple command an option that edits in
# place: -i, -I, either with a suffix or among other letters (-Ei, -ibak), or --in-place.
in_place='(^|[^[:alnum:]_.-])sed[[:space:]]([^|;&]*[[:space:]])?(-[[:alpha:]]*[iI]|--in-place)'
if grep -qE "$in_place" <<<"$bare"; then
	jq -n '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny",
		permissionDecisionReason: "In-place sed is refused in this repo: a failed `sed -i` on macOS left a tracked file empty. Change the file with the Edit tool instead."}}'
fi
