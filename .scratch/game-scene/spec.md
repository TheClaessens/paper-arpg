# The game scene and its first Level

Status: ready-for-agent

Tickets 01 and 02 are built on the recommended answers to the open rules, by the text route; the developer confirms them when reading this step's PR. Ticket 03 is the developer's.

Step 5 of the future-proofing plan (`.scratch/future-proofing-review/plan.md`, decision 4: "The game gets its own scene now, with the sandbox as its first Level, and nothing more"), on its own branch `game-scene`, stacked on the steps before it (plan.md, decision 8). It needs none of them: of the files they change it shares only `GLOSSARY.md` and `docs/agents/godot-conventions.md`, on other lines. Sources: `.scratch/future-proofing-review/analysis/ui-game-root.md` ("The game scene and the level", Brief 1 option A, "Missed by both reports" M4, work package 3), checked line by line against `scenes/sandbox.tscn` at `8797660`. Nothing changes in play, no script changes and no existing test changes.

## What changes and why

Today `scenes/sandbox.tscn` is the main scene and the whole game at once: the pixelated view, the 3D world, the place the player plays in (floor and walls, 19 props, the navmesh, the light), the player's Character with the camera, the seven Enemies and the HUD. A second Level would have to copy all of it or split it first.

After this step there are two scenes:

- **`scenes/game.tscn`**, the new main scene, holds what carries over from one Level to the next: the pixelated view; `World`, with the player's Character and its camera; and the HUD.
- **`scenes/sandbox.tscn`** keeps only the first Level: a `Node3D` holding the light, the floor, walls and props with their navmesh, and the seven Enemies. `game.tscn` instances it under `World`.

Why now: the next systems' nodes get their place before they are written. Things in flight for `ball-in-world` (step 10) find their natural parent in the game scene's `World`; Enemy spawning and the player's death come later on the same footing. A Level becomes the unit of content from the first content step. The split costs the same now as later, and it changes no script, because the HUD's three node paths keep their values.

Nothing more: no changing Levels, no start marker, no script on the game scene. They wait for the second Level (Out of scope).

Words: **Level** becomes a glossary term (Docs this reopens). "The game scene" is plain words for `scenes/game.tscn`. "The player's Character" is the `Player` node. "Things in flight" are a ball, or anything else a Skill leaves flying after its activation, as plan.md uses the words.

### The two scene trees

Today, `scenes/sandbox.tscn`, the main scene, 41 nodes:

```
Sandbox (Node)
├─ PixelatedView (SubViewportContainer, rendering/pixelated_view.gd)
│  └─ SubViewport
│     └─ World (Node3D)
│        ├─ Sun (DirectionalLight3D)
│        ├─ WorldEnvironment (dark background, ambient light)
│        ├─ NavigationRegion3D (scenes/sandbox_navmesh.tres)
│        │  ├─ Dungeon (GridMap, scenes/dungeon_tiles.tres)
│        │  └─ Props: 19 prop instances
│        ├─ Player (characters/player/player.tscn)
│        │  └─ Camera (Camera3D)
│        └─ PackZombie ×5, CorridorZombie, DetourZombie (characters/enemy/zombie.tscn)
└─ HUD (CanvasLayer)
   ├─ TouchStick
   ├─ PauseMenu     player → ../../PixelatedView/SubViewport/World/Player, hud → ../SkillBarHud
   └─ SkillBarHud   player → ../../PixelatedView/SubViewport/World/Player
```

After, `scenes/game.tscn`, the main scene, 11 nodes:

```
Game (Node)
├─ PixelatedView (SubViewportContainer, rendering/pixelated_view.gd)
│  └─ SubViewport
│     └─ World (Node3D)
│        ├─ Player (characters/player/player.tscn)
│        │  └─ Camera (Camera3D)
│        └─ Sandbox (instance of scenes/sandbox.tscn: the Level)
└─ HUD (CanvasLayer)
   ├─ TouchStick
   ├─ PauseMenu     player → ../../PixelatedView/SubViewport/World/Player, hud → ../SkillBarHud
   └─ SkillBarHud   player → ../../PixelatedView/SubViewport/World/Player
```

And `scenes/sandbox.tscn`, the first Level, 32 nodes:

```
Sandbox (Node3D)
├─ Sun (DirectionalLight3D)
├─ WorldEnvironment (dark background, ambient light)
├─ NavigationRegion3D (scenes/sandbox_navmesh.tres)
│  ├─ Dungeon (GridMap, scenes/dungeon_tiles.tres)
│  └─ Props: 19 prop instances
└─ PackZombie ×5, CorridorZombie, DetourZombie (characters/enemy/zombie.tscn)
```

## The rules

1. **The main scene is `scenes/game.tscn`.** `project.godot` reads `run/main_scene="res://scenes/game.tscn"`.
2. **The game scene holds what carries over from one Level to the next, and only that**, eleven nodes: `Game` › `PixelatedView` › `SubViewport` › `World`; in `World`, first `Player` with `Camera` as its child, then the Level's instance; and `HUD` with `TouchStick`, `PauseMenu` and `SkillBarHud`.
3. **A Level is a scene of its own with a `Node3D` root, instanced at the origin.** The first, `scenes/sandbox.tscn`, holds 32 nodes: its root `Sandbox`; `Sun` and `WorldEnvironment`; `NavigationRegion3D` with the `Dungeon` GridMap and `Props` (19 props); and the seven Enemies. It holds no player's Character, camera, HUD or pixelated view.
4. **The move loses and changes nothing.** Every node, property, external resource and sub-resource of today's `sandbox.tscn` is in exactly one of the two files, written as it was, but for two things: in the Level, `parent=` paths lose `PixelatedView/SubViewport/World`, and the root is a `Node3D` instead of a `Node`.
5. **The HUD reaches the game scene's one player's Character, as today.** `PauseMenu.player` and `SkillBarHud.player` stay `../../PixelatedView/SubViewport/World/Player`, and `PauseMenu.hud` stays `../SkillBarHud`. In the running game they are that Character and that Skill bar HUD, never null.
6. **No node path crosses between the game scene and a Level.** The Level holds no `NodePath`. The game scene's three lead to `Player` and `SkillBarHud`, neither through the Level.
7. **Play doesn't change.** `tools/simulate.gd` prints the same lines on both sides of the split, and the screenshots, the navmesh bake and the iPhone build show the same game.

"Checking the move" checks rule 4 line by line, and rules 2, 3 and 6 by count. `tests/test_game.gd` checks rules 1 and 5, and that the one player's Character is the game scene's own. "Checking by hand" checks rule 7.

## The change, file by file

### `scenes/game.tscn`, new (ticket 02)

Exactly this:

```
[gd_scene format=3]

[ext_resource type="Script" uid="uid://cx1p31vvnlago" path="res://rendering/pixelated_view.gd" id="2_2d2mb"]
[ext_resource type="PackedScene" uid="uid://b7lxromdaqgee" path="res://characters/player/player.tscn" id="12_player"]
[ext_resource type="PackedScene" path="res://ui/touch_stick.tscn" id="16_touch_stick"]
[ext_resource type="PackedScene" path="res://ui/skill_bar_hud.tscn" id="17_skill_bar_hud"]
[ext_resource type="PackedScene" path="res://ui/pause_menu.tscn" id="20_pause_menu"]
[ext_resource type="PackedScene" uid="uid://dju5kanhrsbts" path="res://scenes/sandbox.tscn" id="21_sandbox"]

[node name="Game" type="Node"]

[node name="PixelatedView" type="SubViewportContainer" parent="." unique_id=1689867640]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
stretch = true
script = ExtResource("2_2d2mb")

[node name="SubViewport" type="SubViewport" parent="PixelatedView" unique_id=2110600729]
handle_input_locally = false
size = Vector2i(1152, 648)
render_target_update_mode = 4

[node name="World" type="Node3D" parent="PixelatedView/SubViewport" unique_id=122488929]

[node name="Player" parent="PixelatedView/SubViewport/World" unique_id=1861459470 instance=ExtResource("12_player")]

[node name="Camera" type="Camera3D" parent="PixelatedView/SubViewport/World/Player" unique_id=1078422878]
transform = Transform3D(0.70710677, -0.4055798, 0.579228, 0, 0.81915206, 0.57357645, -0.70710677, -0.4055798, 0.579228, 11.584559, 11.471529, 11.584559)
projection = 1
size = 6.0

[node name="Sandbox" parent="PixelatedView/SubViewport/World" instance=ExtResource("21_sandbox")]

[node name="HUD" type="CanvasLayer" parent="."]

[node name="TouchStick" parent="HUD" instance=ExtResource("16_touch_stick")]

[node name="PauseMenu" parent="HUD" node_paths=PackedStringArray("player", "hud") instance=ExtResource("20_pause_menu")]
player = NodePath("../../PixelatedView/SubViewport/World/Player")
hud = NodePath("../SkillBarHud")

[node name="SkillBarHud" parent="HUD" node_paths=PackedStringArray("player") instance=ExtResource("17_skill_bar_hud")]
player = NodePath("../../PixelatedView/SubViewport/World/Player")
```

- All of it but the lines in the next item is today's, copied as it stands, `unique_id` and all: the nine nodes `PixelatedView`, `SubViewport`, `World`, `Player`, `Camera`, `HUD`, `TouchStick`, `PauseMenu`, `SkillBarHud`, and the five `ext_resource` lines they use, with their ids.
- New: the header, with no uid yet; the root `Game`, a plain `Node` like today's root, with no `unique_id` yet; the Level's `ext_resource` line, with the uid that `sandbox.tscn`'s first line declares; and the Level's instance, written after `Camera` so that it is `World`'s second child (open rule 5). The editor's resave gives the header its uid and the new nodes their `unique_id` (ticket 03).
- The HUD's paths are today's, character for character. None passes through the Level.

### `scenes/sandbox.tscn` (ticket 02)

Edited in place, so it keeps its uid (`uid://dju5kanhrsbts`), its path and its history:

1. Delete the five `ext_resource` lines that moved: ids `2_2d2mb`, `12_player`, `16_touch_stick`, `17_skill_bar_hud`, `20_pause_menu`.
2. Delete the nine node blocks that moved, each with its property lines and the blank line after it.
3. The root line becomes `[node name="Sandbox" type="Node3D" unique_id=2138759999]`.
4. In every `parent=` left, `"PixelatedView/SubViewport/World"` becomes `"."`, and a leading `PixelatedView/SubViewport/World/` goes. Do it after step 2, so `Player`'s line is gone before the rewrite could make it a child of the Level.

Nothing else changes: the header, the ten `ext_resource` lines left, the `Environment` sub-resource and every property line stay as they are, the GridMap's cells included. `git diff` then shows each node line left once with its old parent and once with its new.

What goes where, node by node (`…` stands for `PixelatedView/SubViewport`):

| Node (`unique_id`) | Parent today | Goes to | Parent after |
|---|---|---|---|
| `Sandbox`, the root (2138759999) | none | `sandbox.tscn`, its root | none; type `Node3D` instead of `Node` |
| `PixelatedView` (1689867640) | `.` | `game.tscn` | `.` |
| `SubViewport` (2110600729) | `PixelatedView` | `game.tscn` | `PixelatedView` |
| `World` (122488929) | `…` | `game.tscn` | `…` |
| `Sun` (587866993), `WorldEnvironment` (1776298479), `NavigationRegion3D` (1938274651) | `…/World` | `sandbox.tscn` | `.` |
| `Dungeon` (2089857684), `Props` (1565899750) | `…/World/NavigationRegion3D` | `sandbox.tscn` | `NavigationRegion3D` |
| The 19 props: `Column`, `Column2`, `Barrel`, `Barrel2`, `Chest`, `Pot`, `Rocks`, `Table`, `Stones`, `WallRocks`, `WallBarrel`, `WallBarrel2`, `WallBarrel3`, `HallColumn`, `HallTable`, `HallPot`, `HallBarrel`, `HallStones`, `HallChest` | `…/World/NavigationRegion3D/Props` | `sandbox.tscn` | `NavigationRegion3D/Props` |
| `Player` (1861459470) | `…/World` | `game.tscn` | `…/World` |
| `Camera` (1078422878) | `…/World/Player` | `game.tscn` | `…/World/Player` |
| `PackZombie`, `PackZombie2` to `PackZombie5`, `CorridorZombie`, `DetourZombie` (1938276100 to 1938276106) | `…/World` | `sandbox.tscn` | `.` |
| `HUD` (none) | `.` | `game.tscn` | `.` |
| `TouchStick`, `PauseMenu`, `SkillBarHud` (none) | `HUD` | `game.tscn` | `HUD` |
| New: `Game`, the root | | `game.tscn` | none |
| New: `Sandbox`, the Level's instance | | `game.tscn` | `…/World`, after `Camera` |

External resources and sub-resources:

| Entry today | Goes to |
|---|---|
| `2_2d2mb` `rendering/pixelated_view.gd`; `12_player` `characters/player/player.tscn`; `16_touch_stick`, `17_skill_bar_hud`, `20_pause_menu`, the three `ui/` scenes | `game.tscn` |
| `3_g7mfh` `scenes/dungeon_tiles.tres`; `4_8b5lh` to `10_f4qvn`, the seven `props/` scenes; `14_zombie` `characters/enemy/zombie.tscn`; `15_navmesh` `scenes/sandbox_navmesh.tres` | `sandbox.tscn` |
| Sub-resource `Environment_dugpm`, the background and ambient light | `sandbox.tscn` |
| New: `21_sandbox` `scenes/sandbox.tscn` (`uid://dju5kanhrsbts`) | `game.tscn` |

**uids and `unique_id`s.** Every line that moves keeps its `uid` and `unique_id`. A `unique_id` only has to be unique within its file (Engine facts 4), so the two files can't clash. New lines get none by hand, like today's four HUD nodes: the editor writes them in its resave (Engine facts 5). The one uid typed by hand is `sandbox.tscn`'s, copied from its own first line.

### `project.godot` (ticket 02)

Line 14 becomes `run/main_scene="res://scenes/game.tscn"`, a path as today (Engine facts 9). Edited as text in the worktree, not through Project Settings in an open editor, which reorders the file when it saves it.

### Tool comments (ticket 02)

- `tools/simulate.gd:7` becomes `##       res://scenes/game.tscn 6 "tp 16 7.5"`.
- `tools/screenshot.gd:6` becomes `##       res://scenes/game.tscn "tp 16 7.5" "set pixelated 0"`, and `:8` becomes `## Writes 0_start.png, 1_tp-16-7.5.png, ... to user://screenshots/ and prints each path.` Today's example runs `anim walk`, a command that went with `sandbox.gd` in the movement step (`.scratch/movement/spec.md:54`), so the line this step rewrites gets an example that runs.
- `tools/bake_navmesh.gd:3`: "Run after editing a level." becomes "Run after editing a Level." Its usage line (`:5`) keeps `res://scenes/sandbox.tscn`: the tool bakes every `NavigationRegion3D` in the scene it is given (`:23-28`), and that scene is now the Level.

### Unchanged on purpose

- **No script.** The HUD's paths keep their values (rule 5). The tools find the player's Character by name and every Character by class without asking for owned nodes, so they reach into the instanced Level (`simulate.gd:37-39`). The Console's `collisions` re-adds the current scene and finds its GridMaps the same way (`console.gd:198-204`), and `nav` searches from the root (`:213`). Hit feedback, the Standees and Controls find the camera through their viewport (`hit_feedback.gd:42`, `standee.gd:72`, `:109`, `controls.gd:78`, `:89`), and the camera stays in the same `SubViewport`. An Enemy learns of the player's Character from its Aggro, which the physics engine tells (`aggro.gd:36`, `:46-50`, `enemy.gd:41`).
- **`tools/deploy_ios.sh`.** It exports the iOS preset, which takes the main scene and every resource (`export_presets.cfg:11-13`).
- **No existing test** (Tests).
- **`player.tscn` and `zombie.tscn`** (Seams).

## Two routes for the scene edit

### By an agent, in text (recommended)

Ticket 02, in a worktree no editor has open. Then the developer's resave, once, in ticket 03.

Recommended because every line of the two files is a line of today's file or one of the new lines above, so "Checking the move" proves the move line by line. It needs no editor while the developer's stays open on `master`, and the editor's own format then arrives as one commit that changes no value.

### By the developer, in the editor

With the branch open in the editor (after Project › Reload Current Project) and Save Before Running off:

1. Open `scenes/sandbox.tscn`. Scene › Save Scene As… `scenes/game.tscn`. The open tab is now `game.tscn`.
2. Open `scenes/sandbox.tscn` again. Right-click `World` › Make Scene Root: the old root becomes `World`'s last child (Engine facts 11). Delete that old root, which takes `PixelatedView`, `SubViewport` and `HUD` with it. Delete `Player`, which takes `Camera`. Rename `World` to `Sandbox`. Save.
3. In `game.tscn`, delete `Sun`, `WorldEnvironment`, `NavigationRegion3D` and the seven zombies from `World`. Rename the root `Game`. Select `World`, then Instance Child Scene… (not a drag, which drops it where the mouse is) and `scenes/sandbox.tscn`: it lands last, after `Player` (Engine facts 11). Save.
4. Close the editor and change `project.godot` line 14 as above.
5. "Checking the move", below. Both files are in the editor's format already, so ticket 03 has no resave to commit. The roots' `unique_id`s differ from the text route's, which is fine (Engine facts 4).

### Checking the move (either route)

From the repo root, in bash or zsh:

```bash
scene_lines() { sed -E 's/ parent="[^"]*"//; s/ (uid="uid:\/\/[a-z0-9]+"|unique_id=[0-9]+)//g' | grep -v '^$' | LC_ALL=C sort; }
diff <(git show master:scenes/sandbox.tscn | scene_lines) <(cat scenes/game.tscn scenes/sandbox.tscn | scene_lines)
```

`scene_lines` drops every `parent=`, uid and `unique_id`, and blank lines, and sorts what is left, so the diff compares what the files say, wherever a block sits. `master`'s `sandbox.tscn` is the one this step starts from: no step before it changes that file. The text route prints exactly this:

```
12a13
> [ext_resource type="PackedScene" path="res://scenes/sandbox.tscn" id="21_sandbox"]
17a19
> [gd_scene format=3]
26a29
> [node name="Game" type="Node"]
46c49,50
< [node name="Sandbox" type="Node"]
---
> [node name="Sandbox" instance=ExtResource("21_sandbox")]
> [node name="Sandbox" type="Node3D"]
```

That is the second header, the Level's line, the new root, the new instance and the root's new type, and nothing lost. Anything else is a lost or changed line: stop and look. The editor route prints these lines too, and more: `game.tscn` is a new file to the editor, which gives its `ext_resource` lines new ids (Engine facts 5), so its five moved `ext_resource` lines and the five lines that name them (`PixelatedView`'s `script`, and the `instance=` of `Player`, `TouchStick`, `PauseMenu` and `SkillBarHud`) show up in pairs that must differ in that id only. Then:

- `grep -c '^\[node' scenes/game.tscn scenes/sandbox.tscn`: 11 and 32.
- `grep -o 'parent="[^"]*"' scenes/sandbox.tscn | sort | uniq -c`: 10 `parent="."`, 2 `parent="NavigationRegion3D"`, 19 `parent="NavigationRegion3D/Props"`.
- `grep -c NodePath scenes/sandbox.tscn`: 0. `grep NodePath scenes/game.tscn`: the three HUD paths above.
- `grep -c '^\[connection' scenes/game.tscn scenes/sandbox.tscn`: 0 and 0. Today's file has none either: every signal is connected in code, so no connection can be lost.
- `head -1 scenes/game.tscn scenes/sandbox.tscn`: `sandbox.tscn` still declares `uid://dju5kanhrsbts`; `game.tscn` declares none (text route) or another (editor route).

### The editor's resave (ticket 03, after the text route)

The editor rewrites a hand-written scene in its own format when it saves it ("The open editor" in the conventions). Do it once, on purpose, and commit it alone, so the files stop churning. What it should change, and nothing else:

- `game.tscn`: a uid on its first line, and a `unique_id` on `Game`, `Sandbox`, `HUD`, `TouchStick`, `PauseMenu` and `SkillBarHud`.
- `sandbox.tscn`: the navmesh's line gains `uid="uid://bss5uj3ivwxee"`, the uid its own file declares.
- Either file: property lines may change order within their block.

The check, after the resave and before committing it:

```bash
scene_lines() { sed -E 's/ (uid="uid:\/\/[a-z0-9]+"|unique_id=[0-9]+)//g' | grep -v '^$' | LC_ALL=C sort; }
for f in scenes/game.tscn scenes/sandbox.tscn; do diff <(git show HEAD:$f | scene_lines) <(scene_lines < $f); done
```

It prints nothing. A line it prints is one the editor changed or dropped: stop and look. If the resave writes a uid for `zombie.tscn` or one of the three `ui/` scenes (none declares one today), that file's own first line now carries it too and must go in the same commit, or a fresh checkout reads a uid nothing declares and `tools/check.sh` fails on "invalid UID".

## Tests

### `tests/test_game.gd`, new (ticket 01)

```gdscript
extends GutTest
## The main scene, run as the game runs it. Its HUD elements reach the player's Character through
## exports that the game scene sets by node path, and a path that leads nowhere loads as null
## without an error: only a run shows it. GUT fails a test on any engine error or warning too, so
## this one also fails if the main scene logs one as it gets ready or in its first physics step.


func test_the_hud_reaches_the_one_player_of_the_game_scene() -> void:
	var main_scene: PackedScene = load(ProjectSettings.get_setting("application/run/main_scene") as String)
	var game := main_scene.instantiate()
	add_child_autofree(game)
	await wait_physics_frames(1)
	var players := game.find_children("*", "Player", true, false)
	assert_eq(players.size(), 1, "one player's Character in the running game")
	var player: Player = players[0]
	assert_eq(player.owner, game, "the game scene's own, not a Level's")
	var hud: SkillBarHud = game.get_node("HUD/SkillBarHud")
	var menu: PauseMenu = game.get_node("HUD/PauseMenu")
	assert_eq(hud.player, player, "the Skill bar HUD's player")
	assert_eq(menu.player, player, "the pause menu's player")
	assert_eq(menu.hud, hud, "the pause menu's Skill bar HUD")
```

What each part proves:

- **The main scene setting.** The test loads whatever `project.godot` names, so it checks today's `sandbox.tscn` before the split and `game.tscn` after it, and follows any later main scene.
- **In the tree, one physics step.** `add_child_autofree` runs every `_ready` in the game; one physics step runs the player's Character, the seven Enemies and the navigation once. All of it under GUT's error tracking, which fails the test on any engine error or warning (Engine facts 10). Nothing else puts the main scene in the tree: `tools/load_all.gd` instances it off the tree, where no `_ready` runs and a broken path passes (Engine facts 1).
- **One player's Character, the game scene's own.** Found by class, not by path, so the test checks the wiring wherever `Player` sits. The count fails if a Level brings a player's Character of its own (2) or the game scene loses it (0). The owner check fails if the only one sits inside a Level: an instanced scene's root is owned by the scene that instances it (Engine facts 7).
- **The three exports** (rule 5). Each fails if its path leads nowhere (null) or to another node.

**It can fail** (CODING_STANDARDS.md). Before the split, change `scenes/sandbox.tscn:155` to `player = NodePath("../../PixelatedView/SubViewport/World/Nobody")` and run `godot --headless --path . -s addons/gut/gut_cmdln.gd -gselect=test_game.gd -gexit`. Two failures: the assertion "the Skill bar HUD's player" (null), and GUT's "Unexpected Errors" for `SkillBarHud._ready` reading `skill_bar` on null (`skill_bar_hud.gd:52`). Revert with `git checkout -- scenes/sandbox.tscn`. Once more with `:152`, `hud = NodePath("../Nobody")`: "the pause menu's Skill bar HUD" fails, with an unexpected error from `pause_menu.gd:40`.

**Before the split it passes**: today's main scene has the same wiring and one player's Character, owned by its root. It keeps passing through the split; that is the test's job.

**Needs a run.** No test puts the main scene in the tree today. If the test fails on an engine error or warning that has nothing to do with the wiring, stop and report the message. Don't switch GUT's error tracking off and don't hide the message.

### Existing tests

None loads `sandbox.tscn` or assumes its structure. Checked: no test names `sandbox`, `scenes/`, the main scene setting, `PixelatedView` or a `HUD/` path. Tests instance `player.tscn`, `zombie.tscn` and the Skill, Hurtbox, Aggro, Standee, Console and HUD scenes, or build nodes in code (`PixelatedView.new()` in `test_pixelated_view.gd:8`). `test_pause_menu.gd:16-25` and `test_skill_bar_hud.gd:21-27` set the HUD's `player` and `hud` in code. None moves.

`tools/load_all.gd`, the load step of `tools/check.sh`, loads and instances every `.tscn`, the two new ones included. If `content-checks` (step 2) has landed below this step, its `tests/test_content.gd` instances both scenes off the tree too, and finds the player's Skills through `game.tscn` instead of `sandbox.tscn`. Nothing in it changes.

## Checking by hand

1. **`tools/simulate.gd`** (ticket 02; headless). On the branch, before the scenes change (in a fresh worktree, run `tools/check.sh` first, which imports):

   ```bash
   godot --headless --path . --script res://tools/simulate.gd -- res://scenes/sandbox.tscn 6 "tp 16 7.5" > "$TMPDIR/simulate-before.txt"
   ```

   Run it once more into `simulate-before-2.txt` and diff the two: if they differ, the run isn't repeatable on this machine, and the comparison below can only be to that spread; say so in the PR. After the split:

   ```bash
   godot --headless --path . --script res://tools/simulate.gd -- res://scenes/game.tscn 6 "tp 16 7.5" > "$TMPDIR/simulate-after.txt"
   diff "$TMPDIR/simulate-before.txt" "$TMPDIR/simulate-after.txt"
   ```

   No output. The player's Character stands at (16, 7.5) in the hall for 6 s while the pack chases it, and the lines list the Characters in `World`'s order (open rule 5). One thing in the run does happen in another order than before: the player's body joins the physics world before the Level's walls and props instead of after them. If the lines differ, look there first, and report.
2. **Screenshots** (ticket 03; needs a window). First on `master`, before taking the branch: `godot --path . --resolution 1280x720 --script res://tools/screenshot.gd -- res://scenes/sandbox.tscn "tp 16 7.5"`, then copy `0_start.png` and `1_tp-16-7.5.png` out of the folder it prints (`user://screenshots/`, the same folder for every checkout, so the next run overwrites them). Then on the branch, the same command with `res://scenes/game.tscn`. Flip between each pair: the start room, the hall, the props, the light and the dark background, the zombies, the player's Character and the HUD look the same. Animation frames and a zombie's first steps may differ.
3. **The navmesh bake** (ticket 03; needs a window). On the branch: `godot --path . --script res://tools/bake_navmesh.gd -- res://scenes/sandbox.tscn`. It prints `NavigationRegion3D -> res://scenes/sandbox_navmesh.tres: OK` and the walkable area by height, and rewrites that file. `git status` must then show `scenes/sandbox_navmesh.tres` unchanged. If it changed, bake `master`'s `sandbox.tscn` the same way and compare the two printed areas, which must be equal. Either way, `git checkout -- scenes/sandbox_navmesh.tres`: this step commits no navmesh.
4. **The iPhone** (ticket 03). `tools/deploy_ios.sh` clears `.godot/exported` before it exports: a stale export cache once scrambled scene settings in a device build (2026-11-21, the script's header). To deploy with the editor's Remote Debug instead, delete `.godot/exported` by hand and reload the editor first. On the phone: the game opens in the start room; the world is pixelated and the HUD sharp; the Touch stick walks; dragging Fireball's slot shows its aim line (not a spot ring) and its slot sweeps a 4 s Cooldown; Pause › Skill bar puts a Skill in a slot; in the hall the pack chases, Attacks kill a zombie and its Health bar shows.
5. **In the editor** (ticket 03). Play (F5) runs `game.tscn`, and the Remote tree shows `Game` › `PixelatedView` › `SubViewport` › `World` › `Player`, `Sandbox`.

## Docs this reopens

1. **`GLOSSARY.md`**, a new entry after Aggro radius (`:31-33`), committed with this spec (ticket 01):

   > **Level**:
   > One place the player plays through, with its own ground, walls, props, light and Enemies. The player's Character, the camera and the HUD are not part of a Level: they carry over from one Level to the next.
   > _Avoid_: Map, stage, zone, scene

   Checked against what the Level holds after the split: ground and walls (the `Dungeon` GridMap), props (19), light (`Sun`, and `WorldEnvironment`'s background and ambient light) and the seven Enemies. The navmesh is left out as an engine word. The analysis's draft listed the same five; this entry says what is outside a Level as a sentence of its own, in the glossary's words ("the player's Character", after Character's entry). "Scene" is avoided because it is Godot's word for a file: the game scene is a scene and no Level.
2. **`docs/agents/godot-conventions.md`, "Levels and navigation"** (ticket 02). Three bullets go at the top, and "a level" in the bake bullet becomes "a Level". The section reads:

   > ## Levels and navigation
   >
   > - A Level (see GLOSSARY.md) is a scene of its own with a `Node3D` root: its ground, walls, props, navmesh, light and Enemies. `scenes/sandbox.tscn` is the first.
   > - The game scene, `scenes/game.tscn`, is the main scene: the pixelated view, `World` with the player's Character and its camera, and the HUD. It instances the Level under `World`, after the player's Character. The player's Character, the camera and the HUD belong to the game scene, never to a Level.
   > - No node path crosses between the two. Nothing in a Level points at the game scene: an Enemy learns where the player is through physics, as Aggro does. No HUD element points into a Level.
   > - A GridMap cell (x, z) covers [x, x+1] × [z, z+1]; its centre is (x + 0.5, z + 0.5). Place props and Characters by that, not by the cell index.
   > - After editing a Level, re-bake its navmesh with `tools/bake_navmesh.gd` (usage in its header). It needs a window: a `--headless` bake reads no floor meshes and bakes no floor.
   > - Navigation cell size and height are 0.1, in each NavigationMesh and in project settings, which must match. At 0.25 an agent radius of 0.3 rounds up to 0.5 and closes one-tile corridors.
   > - The floor bakes at y 0.2 (heights round up to the cell height), so each NavigationAgent3D has `path_height_offset` 0.2. Change one, change the other.
3. **`docs/agents/godot-conventions.md`, "Tests and checks"** (ticket 02). In the paragraph that starts "To check a change visually", after "prints every Character's position once per second.", insert: "Give both the game scene, `res://scenes/game.tscn`: a Level's scene on its own has no player's Character, so the commands below don't exist there."
4. **The tool comments** in "The change, file by file".
5. **Specs that name `sandbox.tscn` as the whole game**: `.scratch/art-style-slice/spec.md:28` calls it the main scene; `.scratch/movement/spec.md:28` and `.scratch/touch-controls/spec.md:17` put the camera and the Touch stick in it; `.scratch/combat/spec.md:93` has "the sandbox" hand the Skill menu its Skills. They record what was built then and stay as written, as do the two reports and `.scratch/future-proofing-review/`. `.scratch/enemies/spec.md:9`, `:32` and `:56` speak of the level, its zombies and its navmesh, and stay true. Later steps' own specs run `game.tscn` (Seams).

## Things in flight (for `ball-in-world`)

Their natural parent in `game.tscn` is **`World`** (`PixelatedView/SubViewport/World`). This step adds no node for them.

- It is the root of the 3D world inside the pixelated view. A ball under it is drawn pixelated with the Characters and moves in the same physics space as the Hurtboxes, walls and props it must touch (Engine facts 2). Nothing outside the `SubViewport` can hold a 3D node that shows.
- It belongs to the game scene, so it is there whatever Level is loaded, and nothing in a Level needs a path to it.
- It is the parent of both the player's Character and the Level. A ball put beside the player's Character, as the hit pipeline's analysis sketches `_add_to_world` (`character.add_sibling(node)`, `.scratch/future-proofing-review/analysis/hit-pipeline.md:198-205`), lands in `World` with no path at all. One put beside an Enemy lands in the Level's root and goes with the Level.
- Left to that step: whether every ball goes to `World` or each goes beside its Character. Left to the second Level: freeing the player's balls when the Level changes, and with it, if wanted, a named child of `World` that holds them.

## Seams

- **`character` (step 6) and `enemy-base` (step 8)** change `characters/player/player.tscn` and `characters/enemy/zombie.tscn`: a `Skills` node, a Stagger component, an inherited Enemy base scene. This step opens neither. What their instances need to keep working:
  - The `Player` instance in `game.tscn` sets nothing inside `player.tscn`; it only adds `Camera` under it. `player.tscn` keeps its path and uid (`uid://b7lxromdaqgee`, both written in `game.tscn`), and its root stays a `Player`, whose class the HUD's exports require (any other loads them as null, and `tests/test_game.gd` fails), and a `Node3D`, whose transform the camera follows. Whatever moves inside it, a `Skills` node included, leaves `game.tscn` alone. `tp`, `bar` and `activate` keep their names: the tools and the conventions use them.
  - The seven zombies in `sandbox.tscn` set only their `transform`. `zombie.tscn` keeps its path, by which alone the Level names it, and its root stays a `Node3D`. If the editor gives `zombie.tscn` a uid when it is rebuilt, its next save of `sandbox.tscn` writes that uid into the Level's line for it: commit the two together.
  - Their checks by hand run the game scene. `.scratch/future-proofing-review/analysis/character-enemy.md` writes `screenshot.gd -- res://scenes/sandbox.tscn "tp 18 4" "activate 1 2 0"` (WP1) and `simulate.gd -- res://scenes/sandbox.tscn 6 "tp 16 7.5"` (WP2). After this step that scene is the Level alone, with no player's Character, so neither finds `tp` or `activate`. Their specs name `res://scenes/game.tscn`.
- **`content-checks` (step 2).** Its `tests/test_content.gd` instances every scene off the tree; after this step it finds the player's Skills through `game.tscn`, and nothing in it changes. Its Out of scope "Scenes in the tree" points at this step's smoke test.
- **The shared docs.** `content-checks` edits `godot-conventions.md:37` and adds a section after "Scenes live in the editor"; `touch-interruptions` (step 3) edits the paragraph on screen touches in "Tests and checks" and adds to "Input and UI"; `number-bounds` (step 1) and `content-checks` edit other glossary entries. This step edits "Levels and navigation", the paragraph on the tools in "Tests and checks", and adds the Level entry. No line in common; quote the paragraph, not a line number, when editing.
- **`hit` (step 9) and `ball-in-world` (step 10)**: things in flight, above.

## Open rules for the developer

1. **Names.** The game scene's root is `Game`, a plain `Node` as today's root is. The Level keeps its file and its root's name, `Sandbox`, and its instance in `game.tscn` is named `Sandbox` too, the name the editor gives an instance. *Recommended as written*: nothing looks the instance up by name, and the level-changing code at the second Level picks how it finds the Level.
2. **The Level's root is a `Node3D`.** A `Node3D` follows only a `Node3D` parent (Engine facts 3), so a plain `Node` there would cut the Level's contents off from `World`'s transform. Nothing moves `World` today, so either works now. *Recommended: `Node3D`*, what a place in the 3D world is.
3. **Light and environment live in the Level.** `Sun` and `WorldEnvironment` (the dark background and ambient light) go with the place: a cave can be darker than a hall. Only one `WorldEnvironment` may be in a scene at a time (Engine facts 8), so a game-wide one would fight a Level's. *Recommended: in the Level.* The other choice, one light in the game scene for every Level, suits a game whose places all look alike.
4. **The Enemies live in the Level**, as children of its root, where they stood under `World`. They are placed by hand for this place, go when the Level goes, and find the player through physics, never by path. *Recommended.*
5. **In `World`, the player's Character comes first and the Level second.** The Characters then take their physics steps in today's order, the player's Character before the Enemies, and `tools/simulate.gd` lists them in today's order, so its output compares line for line (Engine facts 6). The editor's Instance Child Scene also puts a new instance last. With the Level first, the Enemies would step, and print, before the player's Character. *Recommended: the player's Character first.* (The analysis's sketch drew the Level first.)
6. **The Level's file stays where it is**, `scenes/sandbox.tscn`, with its uid, its history and its navmesh beside it. *Recommended.* A `levels/` folder waits for the second Level.
7. **The route for the scene edit.** *Recommended: by an agent, in text* (ticket 02), then the developer's resave (ticket 03). The editor route is in "Two routes for the scene edit"; with it, ticket 02 needs the developer's hands and ticket 03 has no resave.

## Out of scope

- **Changing Levels**: freeing the Level and instancing the next, a `level <path>` Console command so the tools can pick one, and freeing things in flight on the way. Trigger: the second Level.
- **A start marker in each Level.** Today the player's Character starts at the game scene's origin, which is inside the sandbox's start room. Trigger: the second Level.
- **A script on the game scene.** Trigger: the first job only the game scene can do: changing Levels, or handing the HUD something of a Level's, such as a boss's Health.
- **A node in `World` for things in flight.** Trigger: `ball-in-world` choosing one place for every ball, or the second Level.
- **The HUD's root handing the player's Character down**, one script on `HUD` instead of a path in each HUD element. Trigger: the second Level (plan.md), or a player's Character replaced while the game runs.
- **A camera rig in the game scene** that follows the player's Character and owns the shake. Trigger: a second camera behaviour (look-ahead, zoom) or a second source of shake.
- **Enemies placed by a spawner** instead of by hand. Trigger: a session with a start and an end, or a Level not laid out by hand (`.scratch/enemies/spec.md:47`).
- **A smoke test over every exported node reference in the main scene**, instead of the three it names. Trigger: the third HUD element set by node path.

## Known limits

- Running the Level's scene on its own (F6 on `sandbox.tscn` in the editor, or a tool given `sandbox.tscn`) shows an empty window: it has no camera, no player's Character and no HUD, and `tp`, `bar` and `activate` don't exist. Run the game scene.
- The player's Character starts at the game scene's origin, which happens to be inside the sandbox's start room. Where a Level wants the player to start is its own business at the second Level.

## Engine facts

Checked against the Godot 4.7-stable source at `5b4e0cb0f` (the build the analysis found the local editor reports) and its class reference, and against the vendored GUT.

1. An exported node reference set by node path is resolved when the scene is instanced, once all its nodes exist, with `get_node_or_null`: a path that leads nowhere sets null and logs nothing (`scene/resources/packed_scene.cpp:597-640`, the plain case at `:639`). Instancing doesn't need the tree, so `tools/load_all.gd` passes a broken path too.
2. A `SubViewport` without a world of its own uses its parent viewport's (`scene/main/viewport.cpp:4855-4866`; `own_world_3d` defaults to false, `doc/classes/Viewport.xml:391`). A Level inside it shares the physics space and navigation with the player's Character, as everything under `World` does today.
3. A `Node3D` follows its parent only when that parent is a `Node3D` (`scene/3d/node_3d.cpp:155-158`).
4. A node written without `unique_id` loads unassigned (`scene/resources/resource_format_text.cpp:198-216`). Saving gives an unassigned or repeated id a new random one, repeats counted within the one file (`packed_scene.cpp:1099-1123`).
5. The editor's saver keeps each `ext_resource` id the file had when it was loaded, and gives new ids in a file it saves for the first time; it writes a uid on a scene's first line when it has none (`resource_format_text.cpp:1812-1816`, `:1822-1856`, the ids kept per file at `:543`), and writes a node's `unique_id` right after its `parent` (`:2024-2078`).
6. `find_children(pattern, type, recursive, owned)` walks depth-first in child order and matches a `class_name` through the node's script (`scene/main/node.cpp:2018-2052`). `_physics_process` runs in tree order among nodes of the same physics priority (`scene/main/scene_tree.cpp:1190`).
7. An instanced scene's root is owned by the scene that instances it; the nodes inside it are owned by that root (`packed_scene.cpp:567-571`).
8. "Only one `WorldEnvironment` may be instantiated in a given scene at a time" (`doc/classes/WorldEnvironment.xml`).
9. `application/run/main_scene`: "Path to the main scene file that will be loaded when the project runs" (`doc/classes/ProjectSettings.xml:420-422`).
10. GUT 9.7.1 as vendored fails a test on engine errors, GUT errors and `push_error` by default (`addons/gut/gut_config.gd:57`). An engine error is any message through Godot's logger that isn't a `push_error` or `push_warning`, warnings included (`addons/gut/gut_tracked_error.gd:52-53`, `addons/gut/error_tracker.gd:67-76`). `.gutconfig.json` doesn't change it.
11. In the editor, Make Scene Root adds the old root as the new root's last child, and Instance Child Scene adds the instance as the selected node's last child (`editor/docks/scene_tree_dock.cpp:1112-1114`, `:293-314`, `:371-373`).

## Done when

- Rules 1 to 7 hold: "Checking the move" prints exactly the lines and counts above, `tests/test_game.gd` passes, and `tools/simulate.gd` prints the same lines on both sides of the split.
- `tests/test_game.gd` failed once with a broken path, and the PR says how (ticket 01).
- `tools/check.sh` passes after each ticket.
- The branch changes only `.scratch/game-scene/`, `GLOSSARY.md`, `tests/test_game.gd`, `scenes/game.tscn`, `scenes/sandbox.tscn`, `project.godot`, `tools/simulate.gd`, `tools/screenshot.gd`, `tools/bake_navmesh.gd` and `docs/agents/godot-conventions.md`, plus a uid line ticket 03 may depend on. No script in the game folders, no other test.
- The docs read as in "Docs this reopens".
- Ticket 03: the resave is one commit; the screenshots, the bake and the iPhone show the same game.
- `/code-review` has run on the branch before its PR.

## Tickets

1. `issues/01-main-scene-smoke-test.md`: this spec and the Level entry, then `tests/test_game.gd`, written against today's main scene.
2. `issues/02-split-game-and-level.md`: the split, `project.godot`, the tool comments and the conventions, checked line by line and with `tools/simulate.gd`.
3. `issues/03-editor-resave-and-device-check.md`: the developer's resave commit, the screenshots, the navmesh bake and the iPhone.
