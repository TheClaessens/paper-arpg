# 01: `enemy.tscn`, and the zombie as its first kind

**What to build:** The branch's first commit is `.scratch/enemy-base/` with the `GLOSSARY.md` changes from the spec's "Docs this reopens" (the Enemy entry, and the new Enemy kind entry after it), as the working agreement asks. Then, in a worktree no editor has open: a new `characters/enemy/enemy.tscn`, the base, made of today's zombie with the zombie taken out; and `characters/enemy/zombie.tscn` written over as a scene that inherits it, holding its root's name, its frames, its speed, its Health's maximum and its own Stagger. No script changes, and nothing changes in play. See `.scratch/enemy-base/spec.md` (rules 2 to 5 and 8; "What goes in the base, node by node"; "The change, file by file"; "Two routes for the scene edit" › "By an agent, in text" and "Checking the split").

**Files:** `GLOSSARY.md` (the Enemy entry, found by its text, and a new entry after it); new `characters/enemy/enemy.tscn`; `characters/enemy/zombie.tscn`. Not committed: `$TMPDIR/dump_scene.gd` and the outputs below.

**Tests:** none new here (ticket 02). Every existing test runs unchanged and passes: the tests that use the zombie preload `zombie.tscn`, so they now build the inherited one.

**Blocked by:** None in this folder. The branch starts from step 7's (`skill-character`), with step 6's resave of `zombie.tscn` committed. Open rules 1, 2, 5 and 6 take their recommended answers unless the developer says otherwise. Under open rule 6 b, steps 3 and 4 below are the developer's, following the spec's "By the developer, in the editor", and this ticket is ready-for-human.

**Status:** ready-for-agent

In order:

1. Commit `.scratch/enemy-base/` and the two glossary changes.
2. Before any scene changes, on the branch as it starts (in a fresh worktree, run `tools/check.sh` first: it imports):
   - write `$TMPDIR/dump_scene.gd` as the spec gives it, and save its dump of `res://characters/enemy/zombie.tscn` to `$TMPDIR/zombie-before.txt`;
   - save `godot --headless --path . --script res://tools/simulate.gd -- res://scenes/game.tscn 6 "tp 16 7.5"` to `$TMPDIR/simulate-before.txt`, twice, and diff the two runs. If they differ, the comparison in step 4 is to within 0.05, and the PR says so.
3. Write `enemy.tscn` and `zombie.tscn` as the spec gives them. Copy every line from the starting `zombie.tscn` as it stands (its uids, `unique_id`s and property order are step 6's resave's), and fill the three `<…>` from it: its first line's uid, `Stagger`'s `unique_id` and `Skills`' `unique_id`. Give `enemy.tscn` no uid and the `1_base` line none: no uid is made up by hand.
4. The checks in "Checking the split": the dump comparison, the line accounting and the counts. Then `tools/check.sh`, then the simulate run into `$TMPDIR/simulate-after.txt` and its diff with the before-run.
5. Commit the two scenes, as "Enemy kinds inherit enemy.tscn; the zombie is the first". After the commit, the developer reloads the project before saving anything in the editor.

If a check prints what the spec doesn't expect, stop and report it. Don't change a scene just to make a check pass: find out first why it failed.

- [x] The spec folder and the two glossary changes are the branch's first commit.
- [x] `enemy.tscn`: ten nodes in the spec's order, the root named `Enemy`, today's `unique_id`s and values, no frames, speed, maximum Health or Stagger, no uid on its first line.
- [x] `zombie.tscn`: its starting first line, three `ext_resource` lines, a root with `instance=ExtResource("1_base")` and `unique_id=1938276001`, and the four entries of the spec with their `index`es (1, 2, 6, 7) and `unique_id`s.
- [x] The line accounting prints exactly the spec's eight lines; the counts are 10 and 5 nodes, 7 and 3 `ext_resource` lines, and 0 sub-resources, connections and editable paths in `zombie.tscn`.
- [x] The dump comparison prints nothing. The base's dump, and the two outputs' line counts, go under `## Comments` for the PR.
- [x] `tools/check.sh` passes, and `git status` shows it changed neither scene; if it did, stop and report what changed.
- [ ] The simulate runs match, line for line or within the spread step 2 found.
- [x] The commit holds the two scenes only; the branch so far changes `GLOSSARY.md`, `.scratch/enemy-base/` and those two files, and no script.

## Comments
