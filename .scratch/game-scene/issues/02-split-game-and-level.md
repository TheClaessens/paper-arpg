# 02: Split the game scene from its first Level

**What to build:** The split, as text, in a worktree no editor has open (the spec's "By an agent, in text"). `scenes/game.tscn` is new, written exactly as the spec gives it: the pixelated view, `World` with the player's Character, its camera and then the Level's instance, and the HUD with today's three node paths. `scenes/sandbox.tscn` is edited in place in the spec's four steps: it keeps its uid and becomes the first Level, a `Node3D` holding the light, the navigation region with the floor, walls and 19 props, and the seven Enemies. `project.godot`'s main scene becomes `res://scenes/game.tscn`. The tool comments and the conventions change as the spec words them. No script and no existing test changes. See `.scratch/game-scene/spec.md` (rules 1 to 7; The change, file by file; Two routes for the scene edit; Checking the move; Checking by hand, item 1; Docs this reopens, items 2 to 4).

**Blocked by:** 01, and the open rules, with their recommended answers unless the developer says otherwise. If the developer picks the editor route (open rule 7), the scene edit and `project.godot` are theirs, following the spec's "By the developer, in the editor", and the rest of this ticket stays an agent's.

**Status:** ready-for-agent

**Files:** `scenes/game.tscn` (new), `scenes/sandbox.tscn`, `project.godot` (`:14`), `tools/simulate.gd` (`:7`), `tools/screenshot.gd` (`:6`, `:8`), `tools/bake_navmesh.gd` (`:3`), `docs/agents/godot-conventions.md` ("Levels and navigation"; in "Tests and checks", the paragraph that starts "To check a change visually").

**Tests:** no new test. `tests/test_game.gd` (ticket 01) keeps passing and now checks `game.tscn`. In order:

1. Before touching a scene, run the spec's `tools/simulate.gd` command on `res://scenes/sandbox.tscn`, twice, and keep the output outside the repo. In a fresh worktree, run `tools/check.sh` first: it imports.
2. Write `scenes/game.tscn`. Edit `scenes/sandbox.tscn`: delete the moved lines first, then rewrite the parents. Change `project.godot:14`.
3. Run "Checking the move".
4. Run `tools/check.sh`.
5. Run the `tools/simulate.gd` command on `res://scenes/game.tscn`, and diff it with step 1's output.
6. Change the tool comments and the conventions.

- [x] `scenes/game.tscn` matches the spec's text line for line; `scenes/sandbox.tscn` differs from today's only as the spec's four steps say.
- [x] "Checking the move" prints exactly the spec's lines; the files hold 11 and 32 nodes; the Level's parents count 10, 2 and 19; the Level holds no `NodePath` and the game scene the three HUD paths; neither file has a `[connection`.
- [x] `project.godot` names `res://scenes/game.tscn`.
- [x] `tests/test_game.gd` passes; `tools/check.sh` passes.
- [x] With `--fixed-fps 60`, three runs on each side list the Characters in the same order and agree up to ±0.01; the PR gives the spread.
- [x] The three tool comments and the two conventions passages read as in the spec.
- [x] `git diff --stat` from ticket 01's commit lists only the files above.
