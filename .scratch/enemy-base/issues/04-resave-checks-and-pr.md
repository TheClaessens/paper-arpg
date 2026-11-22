# 04: The editor's resave, the checks by hand, and the PR

**What to build:** Nothing new. The developer lets the editor write `enemy.tscn` and `zombie.tscn` in its own format once and commits that alone, so they stop churning; checks by hand that the game plays as on the base branch; then reviews the branch and opens its PR. See `.scratch/enemy-base/spec.md` ("The editor's resave"; "Checking by hand").

**Files:** `characters/enemy/enemy.tscn` and `characters/enemy/zombie.tscn` (the resave), and the first line of any file the resave now names a uid for. Results go under `## Comments` below.

**Blocked by:** 03.

**Status:** ready-for-human

In order:

1. On the base branch (`skill-character`), before taking this one: `godot --headless --path . --script res://tools/simulate.gd -- res://scenes/game.tscn 6 "tp 16 7.5"`, saved to a file outside the repo.
2. Take the branch where the editor opens it, then Project › Reload Current Project. If the editor asks about files newer on disk, choose Reload, never Resave. Keep Save Before Running off.
3. Open `characters/enemy/enemy.tscn` and save it (Scene › Save Scene); then open `characters/enemy/zombie.tscn` and save it. The base first, so the zombie's line for it gets the base's new uid. Run the spec's resave check: the first command prints nothing, and `git diff -U0` shows `enemy.tscn`'s first line and `zombie.tscn`'s `1_base` line, each gaining the same uid. Read the spec's warning signs against anything else. Commit the two files alone, as "Editor resave: enemy.tscn's uid", with any first line they now depend on (the spec says when). Under open rule 6 b, skip this step: the files are in the editor's format already.
4. "Checking by hand" 1 to 4 on the branch, the simulate run compared with step 1's; 5, the iPhone, if you want it.
5. `/code-review` on the branch, then the PR against `skill-character` (plan.md decision 8), merged with a merge commit once the steps before it have landed. The PR shows the dump comparison, the base's dump and the three failures from ticket 02.

- [ ] The resave is one commit; the resave check printed nothing, and the diff held only uids.
- [ ] `simulate.gd`'s output matches the base branch's, line for line (or within the spread ticket 01 found).
- [ ] Played: the seven zombies look, idle and walk as before; their Aggro rings are as wide; a swing slides one back and it walks back; five swings kill one and its Health bar shows as high as before.
- [ ] In the editor, `zombie.tscn` shows "Inherits: res://characters/enemy/enemy.tscn" on its root, revert arrows on Frames, Speed and Max Health, and deleting `Movement` is refused.
- [ ] `/code-review`'s findings are handled and the PR is open.

## Comments
