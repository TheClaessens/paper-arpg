# 03: The editor's resave, and the game checked by hand

**What to build:** Nothing new. The developer lets the editor write the two scenes in its own format, once, and commits that alone, so they stop churning. Then, with a window and on the iPhone, they check that the game looks and plays as before the split. See `.scratch/game-scene/spec.md` ("The editor's resave"; "Checking by hand", items 2 to 5).

**Blocked by:** 02.

**Status:** ready-for-human

**Files:** `scenes/game.tscn` and `scenes/sandbox.tscn` (the resave), and the first line of any file they now name a uid for. Results go under `## Comments` below.

In order:

1. On `master`, before taking the branch: the baseline screenshots (spec, "Checking by hand", item 2), copied out of `user://screenshots/`.
2. Take the branch where the editor opens it, then Project › Reload Current Project. If the editor asks about files newer on disk, choose Reload, never Resave. Keep Save Before Running off.
3. Open `scenes/game.tscn` and `scenes/sandbox.tscn` and save each (Scene › Save Scene). Run the spec's resave check: it prints nothing. Commit the two files alone, as "Editor resave: uids, unique_ids and its own property order". Leave the editor's churn in other files out, but for a first line these two now depend on (the spec says when).
4. The screenshots on the branch, compared with step 1's.
5. The navmesh bake (spec, "Checking by hand", item 3). `scenes/sandbox_navmesh.tres` stays as committed.
6. The iPhone with `tools/deploy_ios.sh`, which clears `.godot/exported` first. With the editor's Remote Debug instead, delete `.godot/exported` and reload the editor first. Then the checks in the spec, "Checking by hand", item 4.
7. Play (F5) in the editor.

If ticket 02 went the editor route, skip step 3: the files are in the editor's format already.

**Done when:**

- [ ] The resave is one commit of `scenes/game.tscn` and `scenes/sandbox.tscn` (and any first line they depend on), and the resave check printed nothing.
- [ ] `scenes/game.tscn` declares a uid of its own, not `sandbox.tscn`'s.
- [ ] Each pair of screenshots shows the same room, hall, props, light, background, zombies, player's Character and HUD.
- [ ] The bake printed the walkable area and left `scenes/sandbox_navmesh.tres` as committed, or printed the same area as `master`'s bake.
- [ ] On the iPhone the game opens in the start room and plays as before: the pixelated world and sharp HUD, the Touch stick, Fireball's aim line and its 4 s Cooldown, a Skill put in a slot from the pause menu, the pack chasing, a zombie killed with its Health bar showing.
- [ ] F5 in the editor runs `game.tscn`.
