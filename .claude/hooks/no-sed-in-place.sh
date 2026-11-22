#!/usr/bin/env bash
# PreToolUse hook for Bash (see .claude/settings.json): refuses in-place sed. On macOS, `sed -i`
# takes its next argument as a backup suffix, and a run that failed that way left a tracked file
# empty. The Edit tool changes a file without that risk.
command=$(jq -r '.tool_input.command // empty')
in_place="(^|[^[:alnum:]_./-])sed[[:space:]]([^|;&]*[[:space:]])?(-[[:alpha:]]*i([[:space:].'\"]|\$)|--in-place)"
if grep -qE "$in_place" <<<"$command"; then
	jq -n '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny",
		permissionDecisionReason: "In-place sed is refused in this repo: a failed `sed -i` on macOS left a tracked file empty. Change the file with the Edit tool instead."}}'
fi
