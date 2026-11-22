# Agent guardrails

Status: ready-for-agent

From the retro of the future-proofing session (2026-11-22). Four things that session did by hand, or got wrong and caught late, become scripts and checks. No game code changes.

## 1. The play comparison is a script

Comparing play before and after a change needed `--fixed-fps 60` and a temporary `override.cfg` that puts navigation avoidance on one thread. Every brief repeated that recipe by hand.

- **`tools/play_check.sh [swing|ball|pierce]...`**, new. With no argument it runs all three. For each it prints one line, `<name> <checksum>`.
  - It refuses to run when `override.cfg` already exists next to `project.godot` (the developer's own), and says so.
  - It writes `override.cfg` with `[navigation]` and `avoidance/thread_model/avoidance_use_multiple_threads=false`, and removes it on exit, also on failure (`trap`).
  - Each case runs `"$GODOT" --headless --fixed-fps 60 --path . --script res://tools/simulate.gd -- res://scenes/game.tscn 4 <commands> 2>/dev/null | grep -E '^(t=|  )'` and checksums the result (`md5`, or `md5sum` where there is no `md5`). `GODOT` defaults to `godot`, as in `tools/check.sh`.
  - The commands: swing `"tp 19 4" "activate 1 1 0"`; ball `"tp 14 6" "bar 2 Fireball" "activate 2 1 0"`; pierce is the ball with `"modifier pierce on"` before the activation.
  - An unknown name prints the usage and exits 1. A case whose run prints no line fails with a message instead of printing the checksum of nothing.
  - It stores no expected checksum: play changes on purpose. A PR compares the branch with `master`.
- **Known today, on `master` at `34cad72`:** swing `fc6af6dbd110508d8e597824a4f40861`, ball `53636a0a689c4a5707347e78441f5d67`, pierce `052184001127d78a11e520a69a4fb6dd`. The script must print these.
- **`.gitignore`** gains `override.cfg`.
- **`tools/simulate.gd`'s header** and **`docs/agents/godot-conventions.md`** ("Tests and checks") point at the script where they spell the recipe out. `simulate.gd` keeps one sentence on why a comparison needs both settings.

## 2. An empty tracked file fails the check; in-place sed is refused

A failed `sed -i` on macOS left a ticket file at 0 bytes, and it was committed.

- **`tools/check.sh`** gains a first step, "no empty file": every file `git ls-files` lists has content, except `.gdignore` and `.gitkeep`. It names each empty file and fails.
- **`.claude/settings.json` and `.claude/hooks/no-sed-in-place.sh`**, already on this branch: a hook refuses a Bash command that runs `sed -i` or `sed --in-place`.

## 3. A hand-written resource gets its uid from a script

`ResourceSaver.save()` run headless writes no `uid`; the editor then adds one on its first save, which shows up as churn.

- **`tools/give_uid.gd`**, new: `godot --headless --path . --script res://tools/give_uid.gd -- <res:// path>...`. For each file without a `uid` it makes one (`ResourceUID.create_id()`) and writes it into the file's header (`ResourceSaver.set_uid()`), and prints the path and the `uid`. A file that has one is left alone and reported. Proven on `.tres` files in the Aim modes step.
- Try it once on a throwaway copy of a `.tscn` outside the tracked files. If it works, the header and the docs say scenes too; if not, they say `.tres` only. Either way a scene's nodes still get their `unique_id` from the editor.
- **`docs/agents/godot-conventions.md`**, "The open editor": one sentence after the bullet on the editor resaving files, naming the script and what it does and doesn't cover.

## 4. The reviewer's recurring findings are written down

- **`CODING_STANDARDS.md`** gains, as judgement calls:
  - Under a new heading "Comments": **A comment still says what the code does.** After an edit, reread the doc comment of what changed, and of what points at it.
  - Under "Tests": **A test's name and message promise only what its assertions show.** A test named for "the dragged Aim" checks the Aim, not only that there is one.
  - Under a new heading "Renames": **A rename also searches the prose.** A removed setting leaves words in comments and test names that no search for the identifier finds: `AIMED` left "an aimed Skill".
- **`tools/check.sh`** gains a step, "comment lines": in the `.gd` files of `autoloads/ characters/ skills/ ui/ scenes/ props/ rendering/ tests/ tools/`, a line that is only a comment is at most 110 characters, tabs counted as one. It names each longer line and fails. The lines over that today are re-wrapped in the same commit, words unchanged.
- `CODING_STANDARDS.md`'s first paragraph says mechanical rules live in `tools/check.sh`; no change needed there.

## Tests

`tools/check.sh` is shell and has no test harness. Show each new step fail once by hand, and put the output in the report:

1. An empty tracked file (stage one, run the check, unstage and delete it).
2. A comment line of 111 characters in a `.gd` file (add, run, revert).
3. `tools/play_check.sh` with an `override.cfg` present; with an unknown name; and killed mid-run (`override.cfg` is gone afterwards).

## Done when

- `tools/play_check.sh` prints the three known checksums.
- `tools/check.sh` passes, and each new step was seen to fail.
- `/code-review` ran on the branch.
