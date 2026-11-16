#!/usr/bin/env bash
# Exports a debug build with the iOS preset, installs it on the paired iPhone and launches it.
# The editor's Remote Debug button does the same with the debugger attached; this is for runs
# from the terminal. Set GODOT to use a Godot binary that isn't on PATH as `godot`.
#
# Known failures and their fixes:
# - "Cannot export project with preset iOS due to configuration errors" (no reason given):
#   open the preset in the editor's Export dialog, which lists the reasons. One seen so far:
#   rendering/textures/vram_compression/import_etc2_astc must be on.
# - "maximum number of installed apps using a free developer profile": a free Apple profile
#   allows 3 sideloaded apps. The developer has to delete one from the phone.
# - "device was not, or could not be, unlocked": the build is installed; unlock the phone and
#   open it there, or run this again.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
IPA="$HOME/Documents/godot-exports/paper-arpg/PaperARPG.ipa"
BUNDLE=com.thomasclaessens.paperarpg

mkdir -p "$(dirname "$IPA")"
rm -f "$IPA" # so a failed export can't pass with an old build
"$GODOT" --headless --path . --export-debug iOS "$IPA" 2>&1 | grep -E "EXPORT|^ERROR" || true
[[ -f "$IPA" ]] || { echo "!! export failed"; exit 1; }

# The first available physical iPhone; simulators are listed too, as "simulated".
device=$(xcrun devicectl list devices 2>/dev/null | grep -E "available.*iPhone.*physical" | grep -oE "[0-9A-F]{8}-[0-9A-F]{16}" | head -1 || true)
[[ -n "$device" ]] || { echo "!! no available paired iPhone (connect it, or unlock it once)"; exit 1; }

xcrun devicectl device install app --device "$device" "$IPA" 2>&1 | grep -E "App installed|ERROR|NSLocalizedRecoverySuggestion" || true
xcrun devicectl device process launch --terminate-existing --device "$device" "$BUNDLE" 2>&1 \
	| grep -E "Launched|ERROR|NSLocalizedFailureReason" || true
