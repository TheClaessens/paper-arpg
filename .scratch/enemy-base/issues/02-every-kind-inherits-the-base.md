# 02: Every Enemy kind inherits the base

**What to build:** `tests/test_enemy_kinds.gd` as the spec sketches it, doc comment included. It builds every scene in the project off the tree and checks that each one whose root is an Enemy, but the base, inherits `characters/enemy/enemy.tscn` itself and gives its Standee frames; and that a bare Enemy packed as a scene, as a copy saved without the base would be, is reported on both counts. Then show that the test can fail. See `.scratch/enemy-base/spec.md` (rules 1 and 4; Tests › `tests/test_enemy_kinds.gd`).

**Files:** new `tests/test_enemy_kinds.gd` and its `.gd.uid` (written by the import step of `tools/check.sh`, committed with it).

**Tests:** `test_every_enemy_kind_inherits_the_base_and_has_frames`, `test_a_copy_is_no_kind`. Run one file with `godot --headless --path . -s addons/gut/gut_cmdln.gd -gselect=test_enemy_kinds.gd -gexit`.

**Blocked by:** 01: on the zombie before the split the first test fails, so it lands after it and no commit holds a failing test. Open rules 3, 4 and 5 take their recommended answers unless the developer says otherwise: under 3 b the walk is `characters/enemy/` alone, under 4 b the test walks down the base scenes until it reaches the base, under 5 c the frames check goes.

**Status:** ready-for-agent

The three breakages from the spec's "It can fail", each run on its own and reverted before the next. None is committed:

1. **A plain copy.** `git show skill-character:characters/enemy/zombie.tscn > characters/enemy/zombie.tscn`. The first test fails with "res://characters/enemy/zombie.tscn inherits no scene: …". Revert with `git checkout -- characters/enemy/zombie.tscn`.
2. **A kind of a kind.** A new `characters/enemy/elite_zombie.tscn`:

   ```
   [gd_scene format=3]

   [ext_resource type="PackedScene" path="res://characters/enemy/zombie.tscn" id="1_zombie"]

   [node name="EliteZombie" instance=ExtResource("1_zombie")]
   ```

   It fails with "…elite_zombie.tscn inherits res://characters/enemy/zombie.tscn: a kind inherits res://characters/enemy/enemy.tscn itself". Delete the file.
3. **A kind without frames.** A new `characters/enemy/blank.tscn`, written like the one above but with `path="res://characters/enemy/enemy.tscn"` and its root named `Blank`. It fails with "…blank.tscn gives its Standee no frames", and with nothing about its base. Delete the file.

Each failure message goes under `## Comments`, for the PR.

- [x] The test file is as the spec sketches it, with its doc comment, and both tests pass on the branch.
- [x] Each breakage failed the first test with its message and was undone; `git status` then shows only the new test file and its `.gd.uid`.
- [x] `tools/check.sh` passes.

## Comments

The failure each breakage gave `test_every_enemy_kind_inherits_the_base_and_has_frames`:

1. A plain copy: `res://characters/enemy/zombie.tscn inherits no scene: make a kind with Scene › New Inherited Scene from res://characters/enemy/enemy.tscn`
2. A kind of a kind: `res://characters/enemy/elite_zombie.tscn inherits res://characters/enemy/zombie.tscn: a kind inherits res://characters/enemy/enemy.tscn itself`
3. A kind without frames: `res://characters/enemy/blank.tscn gives its Standee no frames`
