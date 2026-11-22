# Enemy base

Status: ready-for-agent

Tickets 01 to 03 are built on the recommended answers to the open rules, by the text route; the developer confirms them when reading this step's PR. Ticket 04 is the developer's.

Every **Enemy kind** becomes a scene that inherits one base scene, `characters/enemy/enemy.tscn`, which holds what every **Enemy** needs. The zombie, the one kind so far, is the first: `characters/enemy/zombie.tscn` inherits the base and sets only what makes a zombie (its frames, its speed, its **Health**), and keeps its own **Stagger**. A test fails on any scene whose root is an Enemy and that doesn't inherit the base. No script changes, and nothing changes in play.

Step 8 of `.scratch/future-proofing-review/plan.md` (decision 3), on branch `enemy-base`, stacked on step 7 (`skill-character`) as the plan stacks every step (decision 8). It starts from the zombie step 6 leaves (`.scratch/character/spec.md`: a `Stagger` node, an empty `Skills` node, and the editor's resave of its ticket 05) and runs the game scene of step 5 (`.scratch/game-scene/spec.md`). Sources: `.scratch/future-proofing-review/analysis/character-enemy.md` section 2, briefs B1 and B6, and work package WP2, each claim checked against the code at `8797660` and against what steps 6 and 7 change. Engine claims are checked against the Godot 4.7-stable source at `5b4e0cb0f`, the build of the local editor, and the 4.7 docs (Engine facts). Nothing was run for this spec. Where it departs from the analysis is listed near the end.

## What changes and why

Today the zombie is one complete scene: after step 6, eleven nodes and the values that make it a zombie, all in `zombie.tscn`. The second kind would be made by copying it. From then on every change for every Enemy (a new component, the Health bar's height, a crowding setting) is one edit per kind, and the copies drift.

After this step there are two scenes:

- **`characters/enemy/enemy.tscn`, the base**: the nodes every Enemy needs, with the values every Enemy shares. No Level places it.
- **`characters/enemy/zombie.tscn`, the first kind**: it inherits the base and holds only its root's name, three values and its own Stagger.

**Why now** (plan.md decision 3). The nodes every kind needs are already fixed: they are the ones `character.gd` and `enemy.gd` look up by name ("The contract", below). So the base isn't a guess about what kinds share. What a second kind would show is which values are a kind's, and an inherited scene sets values anyway. And a base added later means rebuilding every kind made in the meantime, where a base added now costs one rebuilt zombie.

Words: **Enemy kind** becomes a glossary term (Docs this reopens). "The base" is plain words for `enemy.tscn`, and "a base node" is one of its nodes as a kind sees it; Godot calls the base the base scene and a kind an inherited scene. A kind "overrides" a value when it sets one on a base node, as the editor says.

### The node trees

```
zombie.tscn, today (after step 6)            zombie.tscn, after: inherits enemy.tscn
Zombie (enemy.gd)          1938276001         Zombie                       1938276001
├─ CollisionShape3D        1938276002         ├─ CollisionShape3D          the base's
├─ Standee  zombie frames  1938276003         ├─ Standee                   the base's; frames: zombie
├─ Movement  speed 2.5     1938276004         ├─ Movement                  the base's; speed 2.5
├─ NavigationAgent3D       1938276005         ├─ NavigationAgent3D         the base's
├─ Aggro                   1938276006         ├─ Aggro                     the base's
├─ Hurtbox                 1938276007         ├─ Hurtbox                   the base's
├─ Stagger (stagger.gd)    step 6's id        ├─ Stagger (stagger.gd)      the zombie's own, same id
├─ Health  max 50          1938276008         ├─ Health                    the base's; max_health 50
├─ HealthBar               1938276009         ├─ HealthBar                 the base's
└─ Skills (Node3D)         step 6's id        └─ Skills                    the base's, empty

enemy.tscn, the base (new)
Enemy (enemy.gd)           1938276001         body layers 4 and 7, floating, safe_margin 0.02
├─ CollisionShape3D        1938276002         the 0.25 × 1.0 capsule at y 0.5
├─ Standee                 1938276003         no frames
├─ Movement                1938276004         no speed: the script's 4
├─ NavigationAgent3D       1938276005         today's seven settings
├─ Aggro                   1938276006
├─ Hurtbox                 1938276007
├─ Health                  1938276008         no maximum: the script's 100
├─ HealthBar               1938276009         at y 1.1
└─ Skills (Node3D)         step 6's id        empty
```

The numbers are the nodes' `unique_id`s. Every node keeps its own, and the zombie's tree is today's, node for node and in today's order.

## What goes in the base, node by node

The rule: **a node goes in the base when every Enemy needs it**: a script looks it up by name and fails without it, or the body can't work without it. A kind can't delete, rename or move a node it inherits (Engine facts 5), so a node some kind might do without stays out of the base, even if every kind so far has one. Values follow the same rule: the base keeps the values every Enemy shares and leaves a kind's own to the kinds.

| Node (today's values) | Base or kind | Why |
|---|---|---|
| Root, a `CharacterBody3D` with `enemy.gd`: `collision_layer` 4, `collision_mask` 7, `motion_mode` 1, `safe_margin` 0.02 | Base, named `Enemy` | Every Enemy is an `Enemy`. The layers put every Enemy on the `enemy` body layer, blocked by the world, the player and other Enemies (`.scratch/enemies/spec.md`, requirement 2); floating motion and the margin are every Character's (requirement 5). Its name is the kind's: the zombie names its root `Zombie`. |
| `CollisionShape3D`: the `CapsuleShape3D_body` sub-resource (radius 0.25, height 1.0), at y 0.5 | Base | The body's shape: without one, `move_and_slide()` touches nothing. Every Character has this capsule, and the navmesh is baked for one walker size (Out of scope, size classes). |
| `Standee` (`standee.tscn`) | Base; its `frames` the kind's | `Character` looks it up (`$Standee`). How a kind looks is the first thing a kind is, so the base has no frames (open rule 5). |
| `Movement` (`movement.gd`) | Base; its `speed` the kind's | `Enemy` looks it up (`$Movement`). The base sets no speed, so it has the script's 4. Acceleration and deceleration stay the script's, as today. |
| `NavigationAgent3D`: `path_desired_distance` 0.1, `path_height_offset` 0.2, `avoidance_enabled`, `target_desired_distance` 0.5, `height` 1.0, `radius` 0.3, `neighbor_distance` 3.0 | Base | `Enemy` looks it up (`$NavigationAgent3D`). Its settings belong to the Level's navmesh (the floor's baked height, the walker's size) and to the crowding decision (`.scratch/enemies/spec.md`), which hold for every Enemy. |
| `Aggro` (`aggro.tscn`; radius 6, the script's default) | Base | `Enemy` connects it in `_ready` (`$Aggro`). A kind may set its own radius on it; the zombie doesn't. |
| `Hurtbox` (`hurtbox.tscn`) | Base | `Character` finds it with `get_node_or_null`, since the player has none, but `Enemy._die()` switches it off, and the glossary's Enemy can be hit and dies at 0 Health. An Enemy that can't be hit for a while is a state of the Hurtbox (plan.md, "the first immunity"), not a missing node. |
| `Stagger` (`stagger.gd`) | **Kind** | `Character` finds it with `get_node_or_null`: a Character without one is never staggered, by design (step 6, rule 10). The player has none, and the analysis foresees a boss without one (brief B2). A kind can't delete a base node, so the Stagger is each kind's own (open rule 1). |
| `Health` (`health.gd`) | Base; its `max_health` the kind's | `Character` looks it up (`$Health`). The base sets no maximum, so it has the script's 100. |
| `HealthBar` (`health_bar.tscn`), at y 1.1 | Base | `Character` looks it up (`$HealthBar`). Every Character's bar sits at 1.1 today; a tall kind may set its own. |
| `Skills` (a `Node3D`, empty) | Base | `Character` reads it for its Skills and `add_skill()` adds to it (`$Skills`); every Character scene has one (step 6, rule 4). A kind's Skills go under it. |

### The contract

The base's node names are a contract with the two scripts, after step 6:

| Name | Looked up by | A kind without it |
|---|---|---|
| `Standee` | `Character._standee = $Standee` | errors from its first physics frame, when `Enemy` plays an animation |
| `Health` | `Character.health = $Health` | fails in `Character._ready()` |
| `HealthBar` | `Character.health_bar = $HealthBar` | fails in `Character._ready()` |
| `Skills` | `Character.skills` and `add_skill()`: `$Skills` | fails in `Character._ready()`, which reads `skills` |
| `Hurtbox` | `Character.hurtbox = get_node_or_null(^"Hurtbox")`; `Enemy._die()` | can't be hit; `_die()` would fail on a death by other means |
| `Movement` | `Enemy._movement = $Movement` | fails in `Enemy._ready()` |
| `NavigationAgent3D` | `Enemy._agent = $NavigationAgent3D` | fails in `Enemy._ready()` |
| `Aggro` | `Enemy._ready()`: `$Aggro` | fails in `Enemy._ready()` |
| `CollisionShape3D` | no script; the body | touches nothing |
| (`Stagger`, each kind's own) | `Character._stagger = get_node_or_null(^"Stagger")` | never staggered |

Renaming or removing a base node is a change to `character.gd` or `enemy.gd` too, in the same commit. A kind's file names the base nodes it changes, and a renamed one is found again by its `unique_id`, with a warning to resave the kind (Engine facts 2); `tests/test_content.gd` fails on that warning (Engine facts 9).

## Why one inherited scene is not an inheritance chain

The conventions say: "Reach for a new component before an inheritance chain." That warns against behaviour handed down through levels, where a change in one level reaches every level below it and a kind that wants half a level can't have it. `enemy.tscn` is not that:

- **It is the components, assembled once.** Its nodes are the same components the player is built from (Standee, Movement, Health, Health bar, Hurtbox, the `Skills` node) and the Enemy's own (navigation, Aggro). A kind gets them as parts and changes their values. Without the base, each kind would assemble the same ten nodes by hand.
- **One level, and no behaviour of its own.** The base's only script is `enemy.gd`, which every Enemy runs anyway. What makes kinds differ beyond their values, their Skills and later their behaviour, are nodes each kind adds.
- **Only what every kind has.** Since a kind can't delete what it inherits, the base holds nothing some kind might do without.

What would be the chain the conventions warn against:

- **A second level.** A kind that inherits another kind (an elite zombie inheriting the zombie), or a scene between the base and the kinds (a "melee Enemy"). A value set in the middle hides a change made in the base, and a kind can't drop what the middle added. The kinds test fails on it (open rule 4).
- **Behaviour in the base.** A chasing node or a Skill in `enemy.tscn`: every kind would get it and couldn't remove it, so a kind that behaves otherwise would fight its base. Behaviour and Skills are each kind's nodes.
- **A script per kind** extending `Enemy`. Step 6 rules it out: nothing extends `Player` or `Enemy`, and an Enemy kind is a scene, not a script.

## The rules

1. **Every Enemy kind is a scene that inherits `characters/enemy/enemy.tscn` itself**: its root's `instance=` names the base, not another kind, and not nothing. `tests/test_enemy_kinds.gd` checks every scene whose root is an Enemy.
2. **The base holds exactly ten nodes**, in this order: the root `Enemy` (`enemy.gd`), `CollisionShape3D`, `Standee`, `Movement`, `NavigationAgent3D`, `Aggro`, `Hurtbox`, `Health`, `HealthBar`, `Skills`, with today's zombie's `unique_id`s and its values but the three below.
3. **The base sets no kind's value**: its Standee has no frames, its Movement no speed, its Health no maximum. It has no Stagger, no Skill and no behaviour of its own, and no script but `enemy.gd`.
4. **A kind sets only what makes it that kind**: its root's name, values on base nodes, and nodes of its own. Every kind gives its Standee frames. The zombie sets frames `zombie.tres`, speed 2.5 and maximum Health 50, and has its own `Stagger`, between `Hurtbox` and `Health` as today.
5. **The zombie is the zombie it was.** Built by the engine, it has today's nodes, in today's order, with today's classes and stored values: "Checking the split" prints nothing. `zombie.tscn` keeps its path and its uid.
6. **The base's node names are a contract** with `character.gd` and `enemy.gd` (the table above). A kind can't remove one; the base renames one only with the scripts, in the same commit.
7. **No Level places the base, and it doesn't run on its own.** Off the tree it loads and instances without an error (`tools/load_all.gd`, `tests/test_content.gd`); in the tree its Standee fails its assertion for want of frames ("The base on its own").
8. **No script changes, and nothing that names `zombie.tscn` changes**: the Level, the tests and the tools find it as today.
9. **Play doesn't change**: `tools/simulate.gd` on the game scene prints the same lines as on the base branch.
10. **The editor's first save of the two files changes no value, and no node or its order**: it adds uids and `unique_id`s, and in `enemy.tscn` drops one default and moves one line, all listed in "The editor's resave".

"Checking the split" checks rules 2 to 5; `tests/test_enemy_kinds.gd` rules 1 and 4; `tools/check.sh` rule 7; `git diff --stat` rule 8; "Checking by hand" rule 9; "The editor's resave" rule 10.

## The change, file by file

### `characters/enemy/enemy.tscn`, new (ticket 01)

Today's `zombie.tscn` with the zombie taken out. The lines below are written as `master` has them. Copy each line from the starting `zombie.tscn` instead, as step 6's resave left it: where it added a `uid` to an `ext_resource` line or a `unique_id` to a node, or put a block's properties in another order, its version is the one to keep. This listing says which lines, not their final spelling.

```
[gd_scene format=3]

[ext_resource type="Script" path="res://characters/enemy/enemy.gd" id="1_enemy"]
[ext_resource type="PackedScene" path="res://characters/standee/standee.tscn" id="2_standee"]
[ext_resource type="Script" path="res://characters/movement.gd" id="4_movement"]
[ext_resource type="PackedScene" path="res://characters/aggro/aggro.tscn" id="5_aggro"]
[ext_resource type="PackedScene" path="res://characters/hurtbox/hurtbox.tscn" id="6_hurtbox"]
[ext_resource type="Script" path="res://characters/health/health.gd" id="7_health"]
[ext_resource type="PackedScene" path="res://characters/health_bar/health_bar.tscn" id="8_health_bar"]

[sub_resource type="CapsuleShape3D" id="CapsuleShape3D_body"]
radius = 0.25
height = 1.0

[node name="Enemy" type="CharacterBody3D" unique_id=1938276001]
collision_layer = 4
collision_mask = 7
motion_mode = 1
safe_margin = 0.02
script = ExtResource("1_enemy")

[node name="CollisionShape3D" type="CollisionShape3D" parent="." unique_id=1938276002]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.5, 0)
shape = SubResource("CapsuleShape3D_body")

[node name="Standee" parent="." unique_id=1938276003 instance=ExtResource("2_standee")]

[node name="Movement" type="Node" parent="." unique_id=1938276004]
script = ExtResource("4_movement")

[node name="NavigationAgent3D" type="NavigationAgent3D" parent="." unique_id=1938276005]
path_desired_distance = 0.1
path_height_offset = 0.2
avoidance_enabled = true
target_desired_distance = 0.5
height = 1.0
radius = 0.3
neighbor_distance = 3.0

[node name="Aggro" parent="." unique_id=1938276006 instance=ExtResource("5_aggro")]

[node name="Hurtbox" parent="." unique_id=1938276007 instance=ExtResource("6_hurtbox")]

[node name="Health" type="Node" parent="." unique_id=1938276008]
script = ExtResource("7_health")

[node name="HealthBar" parent="." unique_id=1938276009 instance=ExtResource("8_health_bar")]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.1, 0)

[node name="Skills" type="Node3D" parent="." unique_id=<Skills' unique_id in the starting file>]
```

- The first line has no uid: the editor writes one when it first saves the file (ticket 04), as it did for step 5's `game.tscn`. No uid is made up by hand.
- The `ext_resource` ids keep today's, gaps and all (`3` and `9` went to the zombie). Ids only have to be unique within a file, and the editor keeps the ids a file had when it loaded it (Engine facts 4), so every line here is a line of today's file.
- The root is renamed `Enemy`; every other line is today's, with four taken out: `Standee`'s `frames`, `Movement`'s `speed`, `Health`'s `max_health`, and the `Stagger` block with its `ext_resource`. The file ends after the `Skills` line, with no blank line after it, as the editor writes a scene.
- If step 6's open rule 2 went to b, the zombie's root has `faction = 1`: it goes on this root, since every Enemy kind is of the Enemies' Faction.

### `characters/enemy/zombie.tscn` (ticket 01)

Written over in place, so it keeps its path, its uid and its history. Exactly this, with the three `<…>` filled from the starting file and the `3_frames` and `9_stagger` lines copied from it as they are, uid and all:

```
[gd_scene format=3 uid="<the uid on the starting file's first line>"]

[ext_resource type="PackedScene" path="res://characters/enemy/enemy.tscn" id="1_base"]
[ext_resource type="SpriteFrames" path="res://characters/standee/frames/zombie.tres" id="3_frames"]
[ext_resource type="Script" path="res://characters/stagger/stagger.gd" id="9_stagger"]

[node name="Zombie" unique_id=1938276001 instance=ExtResource("1_base")]

[node name="Standee" parent="." index="1" unique_id=1938276003]
frames = ExtResource("3_frames")

[node name="Movement" parent="." index="2" unique_id=1938276004]
speed = 2.5

[node name="Stagger" type="Node" parent="." index="6" unique_id=<Stagger's unique_id in the starting file>]
script = ExtResource("9_stagger")

[node name="Health" parent="." index="7" unique_id=1938276008]
max_health = 50.0
```

### The inherited scene's text, line by line

This is what the 4.7 editor writes for an inherited scene (Engine facts 1 to 4), so the developer can read a kind's file:

- **`[ext_resource …]`**: the base scene, and what the kind's own values and nodes use: its frames and its Stagger's script. Not the base's scripts and scenes, nor its capsule: those come with the base.
- **`[node name="Zombie" unique_id=1938276001 instance=ExtResource("1_base")]`**: a root with `instance=` and no `parent` is what makes the file inherit the base: the engine builds the base, then sets this file's values on it. No `type`: the root is the base's. Its name is the kind's. Its `unique_id` is the one the zombie's root has today; New Inherited Scene gives a kind's root its base root's id, and the base keeps 1938276001, so the editor would write the same number.
- **`[node name="Standee" parent="." index="1" unique_id=1938276003]`** and its one line: a base node the kind changes, with only what it changes. No `type`, since the node is the base's. `index` is its place among the root's children; the editor writes it for every node it writes in an inherited scene but the root, and reads it only for a node the kind adds. `unique_id` is the base node's own, which the engine uses to find the node if the base renames or moves it.
- **A base node the kind doesn't change isn't written at all**: `CollisionShape3D`, `NavigationAgent3D`, `Aggro`, `Hurtbox`, `HealthBar` and `Skills`. A value equal to the base's isn't written either: the editor drops it on its next save.
- **`[node name="Stagger" type="Node" parent="." index="6" …]`**: a node of the kind's own, written in full like any node, with an `index` that puts it between `Hurtbox` and `Health`, where it is today. Without one it would come last; nothing reads the Stagger's place, so it only keeps the tree as it was.
- **`index="7"` on `Health`** counts the zombie's tree, with its Stagger at 6. In the base alone `Health` is at 6.
- **No `[sub_resource]`, no `[connection]`**: the capsule is the base's, and every signal is connected in code, as today.

### Today's `zombie.tscn`, accounted for

| Today (after step 6) | Goes to |
|---|---|
| First line, with its uid | `zombie.tscn`, as it is |
| `ext_resource` `1_enemy` (`enemy.gd`), `2_standee`, `4_movement`, `5_aggro`, `6_hurtbox`, `7_health`, `8_health_bar` | `enemy.tscn`, as they are |
| `ext_resource` `3_frames` (`zombie.tres`), `9_stagger` (`stagger.gd`) | `zombie.tscn`, as they are |
| Sub-resource `CapsuleShape3D_body` | `enemy.tscn` |
| Root `Zombie` (1938276001), its layers, motion mode, margin and script | `enemy.tscn`, renamed `Enemy`; `zombie.tscn`'s root keeps the name and the id, with no values |
| `CollisionShape3D` (…002), `NavigationAgent3D` (…005), `Aggro` (…006), `Hurtbox` (…007), `HealthBar` (…009), `Skills`, each with its values | `enemy.tscn` |
| `Standee` (…003), `Movement` (…004), `Health` (…008), with their scripts or instance | `enemy.tscn` |
| `frames`, `speed = 2.5`, `max_health = 50.0` | `zombie.tscn`, under entries that name the same three nodes by the same ids |
| `Stagger`, its id and its script | `zombie.tscn` |
| Signal connections | none today, none after |
| New | `enemy.tscn`'s first line; `zombie.tscn`'s `1_base` line and root line; the three entries' headers |

### Unchanged on purpose

- **No script.** `enemy.gd` and `character.gd` find their nodes by name, in whichever file declares them; `enemy.gd`'s doc still says what an Enemy does. Nothing in the split needs a script change.
- **The Level** (`scenes/sandbox.tscn`, step 5) names `zombie.tscn` by path, and by uid if a resave has written it, and its seven zombies set only their `transform`. The path, the uid and the root class stay.
- **The tests and tools** ("Every place that names the zombie").

## Two routes for the scene edit

### By an agent, in text (recommended)

Ticket 01, in a worktree no editor has open, then the developer's resave once, in ticket 04.

The analysis held that inherited scenes must come from the editor, because their format is easy to get wrong by hand. The 4.7-stable source of the editor in use shows what the editor writes for an inherited scene (Engine facts 1 to 4), and `zombie.tscn` above is that, value for value: the base nodes it changes, each with its `index` and the base's `unique_id`; its own node in full; nothing equal to the base's. So the editor's first save changes no value and no node (rule 10; the uids and the two lines in `enemy.tscn` it does change are listed in "The editor's resave"), and "Checking the split" proves the result before anything is committed: the engine builds the zombie it built before, and every line of today's file is in one of the two. The developer reads two short files and resaves them, instead of rebuilding the zombie by hand.

**How sure.** High, not certain: no Godot was run for this spec. Two things could still show in the resave: a uid the editor's cache holds for a file whose first line declares none (as step 6 warned), and a rule the source reading missed. The resave check shows either before its commit, and "The editor's resave" says which is harmless.

### By the developer, in the editor

About ten minutes. With the branch open in the editor after Project › Reload Current Project, Save Before Running off, and no tab of `zombie.tscn` open:

1. In a terminal, the "before" dump of "Checking the split", before anything changes.
2. Open `characters/enemy/zombie.tscn`. Scene › Save Scene As… `characters/enemy/enemy.tscn`. The open tab is now `enemy.tscn`; `zombie.tscn` on disk is untouched.
3. In `enemy.tscn`: double-click the root and name it `Enemy`. Select `Standee` and click the revert arrow beside its Frames (it goes empty); revert `Movement`'s Speed (4) and `Health`'s Max Health (100). Delete `Stagger`. Scene › Save Scene.
4. Scene › New Inherited Scene… `characters/enemy/enemy.tscn`. In the new tab, double-click the root and name it `Zombie`. Give `Standee` the frames `characters/standee/frames/zombie.tres`, `Movement` the Speed 2.5, `Health` the Max Health 50.
5. Select the root, Add Child Node › `Node`, name it `Stagger`, and drag `characters/stagger/stagger.gd` from the FileSystem dock onto it. Drag it up between `Hurtbox` and `Health`. (Add Child Node › `Stagger` also works, but the editor then stores `metadata/_custom_type_script` on the node, and the dump shows that line; Engine facts 5.)
6. Scene › Save Scene As… `characters/enemy/zombie.tscn`, and confirm replacing it. The editor keeps the file's uid (Engine facts 4).
7. "Checking the split": the dump comparison prints nothing, and the counts hold. The line accounting prints more than eight lines on this route, since the editor gives both files new `ext_resource` ids: the dump is the proof.
8. Commit the two files. Both are in the editor's format already, so there is no resave to commit afterwards; ticket 04 skips it.

If the editor won't let `Stagger` be dropped between the base's nodes, leave it last: the dump then shows its block after `Skills` instead of after `Hurtbox`, and nothing else.

### Checking the split (either route)

**The dump comparison** proves rule 5: the engine builds the same zombie. A throwaway script, not a test and not committed: a test would have to hold today's zombie as expected values, a second copy of the scene to keep in step with it, while the zombie's own numbers are already checked where they matter (Health 50 by `test_attack.gd:70` and `test_projectile.gd:169`, five swings to kill by `test_enemy_death.gd`, the slide by `test_skill.gd`) and the kinds test checks the structure. Save it outside the repo, as `$TMPDIR/dump_scene.gd`:

```gdscript
extends SceneTree
## Throwaway (enemy-base ticket 01), not committed. Prints a scene as the engine builds it, off the
## tree: each node's path and class in tree order, then each stored property and its value. A
## resource with a file of its own prints as its path; a built-in one as its class and its stored
## properties, so the same capsule declared in another file prints the same.
##   godot --headless --path . --script "$TMPDIR/dump_scene.gd" -- res://characters/enemy/zombie.tscn


func _initialize() -> void:
	var scene: PackedScene = load(OS.get_cmdline_user_args()[0])
	var root := scene.instantiate()
	_print_node(root, root)
	root.free()
	quit()


func _print_node(root: Node, node: Node) -> void:
	var where := String(root.name) if node == root else String(root.get_path_to(node))
	print("%s (%s)" % [where, node.get_class()])
	for line in _stored(node):
		print("  " + line)
	for child in node.get_children():
		_print_node(root, child)


## Each stored property of `object`, as "name = value".
func _stored(object: Object) -> PackedStringArray:
	var lines := PackedStringArray()
	for property in object.get_property_list():
		var usage: int = property["usage"]
		if usage & PROPERTY_USAGE_STORAGE:
			var key: String = property["name"]
			lines.append("%s = %s" % [key, _shown(object.get(key))])
	return lines


func _shown(value: Variant) -> String:
	if value is Resource:
		var resource: Resource = value
		if not resource.resource_path.is_empty() and not resource.resource_path.contains("::"):
			return resource.resource_path
		return "%s {%s}" % [resource.get_class(), ", ".join(_stored(resource))]
	return var_to_str(value)
```

It instances off the tree, as `tools/load_all.gd` does, so no `_ready` runs and nothing is in play: what it prints is what the scene files say, after the engine has put the base and the kind together. It walks every node, the Standee's, Aggro's and Hurtbox's own children included. The capsule's path names the file that declares it (`zombie.tscn::…` before, `enemy.tscn::…` after), which is why a built-in resource prints by its values. If Godot won't load a script from `$TMPDIR`, put it at the worktree's root as `dump_scene.gd` and delete it before committing; it names no project class, so it compiles as a `--script` entry point. Then, from the repo root:

```bash
# On the branch as it starts, before any scene changes (in a fresh worktree, run tools/check.sh first: it imports).
godot --headless --path . --script "$TMPDIR/dump_scene.gd" -- res://characters/enemy/zombie.tscn > "$TMPDIR/zombie-before.txt"
# After writing the two files:
godot --headless --path . --script "$TMPDIR/dump_scene.gd" -- res://characters/enemy/zombie.tscn > "$TMPDIR/zombie-after.txt"
diff "$TMPDIR/zombie-before.txt" "$TMPDIR/zombie-after.txt"
```

It prints nothing. A line it prints is a node or value the split lost, changed or moved: stop and look. Dump `res://characters/enemy/enemy.tscn` too, for the PR: it shows the base's frames empty, speed 4 and maximum 100, and no `Stagger`.

**The line accounting** proves that every line of today's file is in one of the two (text route; before committing, so `HEAD` is the starting file):

```bash
scene_lines() { sed -E 's/ (uid="uid:\/\/[a-z0-9]+"|unique_id=[0-9]+|index="[0-9]+")//g' | grep -v '^$' | LC_ALL=C sort; }
diff <(git show HEAD:characters/enemy/zombie.tscn | scene_lines) <(cat characters/enemy/enemy.tscn characters/enemy/zombie.tscn | scene_lines)
```

`scene_lines` drops uids, `unique_id`s, `index`es and blank lines and sorts what is left, so the diff compares what the files say wherever a line sits. It prints exactly these eight lines (`diff` may number its hunks differently):

```
> [ext_resource type="PackedScene" path="res://characters/enemy/enemy.tscn" id="1_base"]
> [gd_scene format=3]
> [node name="Enemy" type="CharacterBody3D"]
> [node name="Health" parent="."]
> [node name="Movement" parent="."]
< [node name="Zombie" type="CharacterBody3D"]
> [node name="Standee" parent="."]
> [node name="Zombie" instance=ExtResource("1_base")]
```

That is the base's line in the zombie, the base's own first line, the root renamed, the three entries naming base nodes, and the zombie's root becoming an inherited one. Every property line, `ext_resource` and sub-resource line is there once on each side. Then:

- `grep -c '^\[node' characters/enemy/enemy.tscn characters/enemy/zombie.tscn`: 10 and 5.
- `grep -c '^\[ext_resource' characters/enemy/enemy.tscn characters/enemy/zombie.tscn`: 7 and 3.
- `grep -c '^\[sub_resource\|^\[connection\|^\[editable' characters/enemy/zombie.tscn`: 0.
- `head -1 characters/enemy/zombie.tscn` still declares the uid the starting file did; `head -1 characters/enemy/enemy.tscn` is `[gd_scene format=3]`.

### The editor's resave (ticket 04, after the text route)

The editor rewrites a scene written outside it when it saves it ("The open editor" in the conventions). Do it once, on purpose, and commit it alone:

1. Take the branch where the editor opens it, then Project › Reload Current Project. If the editor asks about files newer on disk, choose Reload, never Resave. Keep Save Before Running off.
2. Open `characters/enemy/enemy.tscn` and save it (Scene › Save Scene). Then open `characters/enemy/zombie.tscn` and save it. The base first, so the zombie's line for it gets the base's new uid; saved the other way round, save the zombie again.
3. The check:

   ```bash
   scene_lines() { sed -E 's/ (uid="uid:\/\/[a-z0-9]+"|unique_id=[0-9]+)//g' | grep -v '^$' | LC_ALL=C sort; }
   for f in characters/enemy/enemy.tscn characters/enemy/zombie.tscn; do diff <(git show HEAD:$f | scene_lines) <(scene_lines < $f); done
   git diff -U0 -- characters/enemy/
   ```

   The `scene_lines` comparison drops uids and `unique_id`s and sorts, so it prints only the dropped `height = 1.0` in `enemy.tscn` and nothing for `zombie.tscn` (it keeps `index`, so a moved node shows). The `git diff -U0` shows what is expected below, and nothing else.
4. Commit the two files alone, as "Editor resave: enemy.tscn's uid".

**Expected in `enemy.tscn`** (read from the engine's source; the first save shows whether it holds):

- A `uid` on its first line.
- A `uid` on the `ext_resource` lines of the three scripts that have a `.gd.uid` file: `1_enemy` (`enemy.gd`), `4_movement` (`movement.gd`) and `7_health` (`health.gd`).
- A `unique_id` on the `Skills` node.
- On the `NavigationAgent3D` node, the line `height = 1.0` dropped (it is the built-in default), and `target_desired_distance` moved above `path_height_offset`.

**Expected in `zombie.tscn`:**

- A `uid` on its first line.
- `enemy.tscn`'s new uid on the `1_base` line.
- A `uid` on the `9_stagger` line.
- A `unique_id` on the `Stagger` node.

If an `ext_resource` file's own first line declares no uid on the branch (today none of `standee.tscn`, `aggro.tscn`, `hurtbox.tscn`, `health_bar.tscn` and `zombie.tres` does), the editor writing one on the line that names it is harmless, but that first line goes in the same commit, or a fresh checkout fails `tools/check.sh` on "invalid UID", the rule step 6 set.

**A warning sign is anything else**: a changed value, a node that appears, disappears or moves, a `unique_id` that changes on a node that already had one, an override that vanishes from `zombie.tscn`.

**Warning signs in detail**, each meaning stop and look before committing:

- A property line added to `zombie.tscn`, dropped from it or changed: an override the text got wrong, such as a value the base already has.
- A new entry in `zombie.tscn` for a base node (`[node name="CollisionShape3D" parent="." …]` with a value): the editor sees the kind holding a value that differs from the base's.
- An `index` or a `unique_id` that changes in `zombie.tscn`: the zombie's entries don't match the base's order or nodes.
- A `[sub_resource]` in `zombie.tscn`: a copy of a base resource in the kind.
- The root line losing `instance=` or gaining `type=`: inheritance cleared.
- `[editable path=…]` lines: Editable Children switched on.
- In `enemy.tscn`, a property line added or dropped: a line that wasn't in the editor's format.
- `zombie.tscn` back as a plain scene (a `type="CharacterBody3D"` root and eleven nodes): the editor wrote its stale copy. `git checkout -- characters/enemy/zombie.tscn`, reload, and start again.
- Any other scene changed (`scenes/sandbox.tscn`, `player.tscn`): churn, not this commit ("The open editor").

## The base on its own

- **The checks load it.** `tools/load_all.gd` loads and instances every scene, the base included, and fails only if it can't. `tests/test_content.gd` instances every scene to read its Skills, finds none in the base (its `Skills` node is empty) and reports nothing. Both instance off the tree, where no `_ready` runs (Engine facts 8), so the missing frames log nothing; no script on the base has an `_init`.
- **It doesn't run.** Put in the tree, its Standee fails `assert(frames != null, …)` in `_ready` (`standee.gd:46`), and its `_process` then errors every frame reading the frames. So the base is instantiable, for the checks, and not playable (open rule 5). Nothing places it: a Level places kinds.
- **The checks also guard the kinds.** `test_content.gd` instances every kind inside a test, and a kind whose entry names a node the base no longer has makes the engine warn (Engine facts 2), which fails that test (Engine facts 9). `load_all.gd` only sees the warning and passes.

## Tests

Run one file with `godot --headless --path . -s addons/gut/gut_cmdln.gd -gselect=test_enemy_kinds.gd -gexit`, then `tools/check.sh`.

### `tests/test_enemy_kinds.gd`, new (ticket 02)

```gdscript
extends GutTest
## Enemy kinds (see GLOSSARY.md): every scene whose root is an Enemy, but the base
## characters/enemy/enemy.tscn, is a kind that inherits the base itself, so a change for every
## Enemy is one edit there; and it gives its Standee frames, which the base leaves to its kinds.
## A Level that places Enemies isn't a kind: its root isn't an Enemy.

const LoadAll := preload("res://tools/load_all.gd")
const BASE := "res://characters/enemy/enemy.tscn"


func test_every_enemy_kind_inherits_the_base_and_has_frames() -> void:
	var kinds := 0
	var problems: Array[String] = []
	for path in LoadAll.find_files("res://", ["tscn"]):
		var scene: PackedScene = load(path)
		var root := scene.instantiate()
		if root is Enemy and path != BASE:
			kinds += 1
			problems.append_array(_kind_problems(path, scene, root))
		root.free()
	assert_gt(kinds, 0, "found no Enemy kind")
	assert_true(problems.is_empty(), "; ".join(problems))


func test_a_bare_enemy_is_no_kind_and_has_no_frames() -> void:
	var enemy := Enemy.new()
	var copy := PackedScene.new()
	copy.pack(enemy)
	enemy.free()
	var root := copy.instantiate()
	var problems := _kind_problems("a copy", copy, root)
	root.free()
	assert_eq(problems.size(), 2, str(problems))
	assert_string_contains(problems[0], "inherits no scene")
	assert_string_contains(problems[1], "no frames")


## What is wrong with the Enemy kind `scene` at `path`, built as `root`, one line each.
func _kind_problems(path: String, scene: PackedScene, root: Node) -> Array[String]:
	var problems: Array[String] = []
	var base := scene.get_state().get_base_scene_state()
	if base == null:
		problems.append("%s inherits no scene: make a kind with Scene › New Inherited Scene from %s" % [path, BASE])
	elif base.get_path() != BASE:
		problems.append("%s inherits %s: a kind inherits %s itself" % [path, base.get_path(), BASE])
	var standee := root.get_node_or_null(^"Standee") as Standee
	if standee == null or standee.frames == null:
		problems.append("%s gives its Standee no frames" % path)
	return problems
```

What each part does:

- **How it finds the kinds: by what a scene is, not where it is** (open rule 3). It walks every scene as the check does (`LoadAll.find_files`, the same walk `test_content.gd` uses) and builds each off the tree. A scene whose root is an `Enemy` is the base or a kind. So a kind saved in another folder is checked, and a scene in `characters/enemy/` that isn't a kind (an Enemy Skill's ball, later) isn't taken for one. Building every scene costs what `test_content.gd` already spends.
- **How it asks a scene for its base.** `PackedScene.get_state()` is the scene file's contents; its `get_base_scene_state()` is the state of the scene it inherits, or null when it inherits none, and `get_path()` is that scene's path (Engine facts 6). Only the direct base counts: a kind of a kind reports the kind it inherits (open rule 4).
- **A scene instanced inside another.** The test looks at each file's own root. The Level's root is a `Node3D`, so the Level isn't a kind; the zombies in it are instances of `zombie.tscn`, which the test checks as its own file. `game.tscn` and `player.tscn` have a plain `Node` and a `Player` at their roots. A scene that places the base itself under another root isn't a kind either and goes unchecked here: the base's Standee fails its assertion as soon as that scene runs, and `tests/test_game.gd` (step 5) runs the game scene and its Level (Out of scope: a check that nothing places the base).
- **Frames.** The one value a kind must set, because the base has none (open rule 5). Speed and Health have working defaults.
- **`test_a_bare_enemy_is_no_kind_and_has_no_frames`** packs a bare `Enemy` into a scene in memory, as a copy saved without the base would be, and checks that both problems are reported, so the check can't quietly stop reporting (as `test_content.gd` checks its problem functions on hand-made broken content).

**It can fail** (CODING_STANDARDS.md). Each of these, run once in ticket 02 and reverted, fails `test_every_enemy_kind_inherits_the_base_and_has_frames` with the message given:

1. **A kind saved as a plain copy**: `git show skill-character:characters/enemy/zombie.tscn > characters/enemy/zombie.tscn`, the zombie as it was before this step. "…zombie.tscn inherits no scene". Revert with `git checkout -- characters/enemy/zombie.tscn`.
2. **A kind of a kind**: a file `characters/enemy/elite_zombie.tscn` holding `[gd_scene format=3]`, a blank line, `[ext_resource type="PackedScene" path="res://characters/enemy/zombie.tscn" id="1_zombie"]`, a blank line and `[node name="EliteZombie" instance=ExtResource("1_zombie")]`. "…elite_zombie.tscn inherits res://characters/enemy/zombie.tscn". Delete the file.
3. **A kind without frames**: a file `characters/enemy/blank.tscn` written the same way, inheriting `enemy.tscn` instead, its root named `Blank`. "…blank.tscn gives its Standee no frames", and nothing about its base. Delete the file.

**On the base branch** it fails: the zombie inherits no scene. Hence ticket 02 comes after the split, so no commit holds a failing test.

### Existing tests

None changes. Every test that uses the zombie preloads `zombie.tscn` and reads what it reads today: `health`, `hurtbox`, `health_bar`, Health 50, the slide, `add_skill()` onto its `Skills` node (step 7), its `Stagger` node (step 6's `test_character.gd`). `tests/test_game.gd` (step 5) puts the game scene in the tree for a physics step, so the seven inherited zombies in the Level get ready under GUT's error tracking. `tests/test_enemy.gd` makes a bare `Enemy.new()` and needs no scene.

## Every place that names the zombie

| Where | How | Changes? |
|---|---|---|
| `scenes/sandbox.tscn`, the Level (step 5) | `ext_resource` `14_zombie` by path (and its uid, if a resave wrote it); seven instances that set only `transform` | No: `zombie.tscn` keeps its path, its uid and an `Enemy` root |
| `scenes/game.tscn` (step 5) | instances the Level | No |
| `tests/test_skill.gd:6`, `test_enemy_death.gd:5`, `test_hurtbox.gd:6`, `test_health_bar.gd:12`, `test_attack.gd:7`, `test_aim_modes.gd:6`, `test_player.gd:6`, `test_projectile.gd:7` (lines at `8797660`), step 6's `test_character.gd`, step 7's new test in `test_attack.gd` | preload `zombie.tscn` | No |
| `tests/test_enemy.gd` | `Enemy.new()` | No |
| `tests/test_content.gd` (step 2), `tools/load_all.gd` | build every scene off the tree | No; they now build the base too |
| `tests/test_game.gd` (step 5) | the game scene in the tree | No |
| `tools/simulate.gd`, `tools/screenshot.gd`, the Console's `nav` and `aggro` | Characters and agents by class, Aggro rings by group | No |
| `docs/agents/godot-conventions.md` | | A section on Enemy kinds (Docs this reopens) |
| `.scratch/enemies/spec.md:31`, `:41` | the zombie as built then | No: still true of the zombie the engine builds |
| `.scratch/character/spec.md`, `.scratch/game-scene/spec.md`, the analysis, the reports | other steps' records | No |

## Checking by hand

The tools run the game scene, `res://scenes/game.tscn`. "The base branch" is `skill-character`, which this branch is stacked on.

1. `tools/check.sh` passes.
2. **The chase, frame for frame.** The repeatable form of `tools/simulate.gd` (its header): put an `override.cfg` next to `project.godot` with `[navigation]` and `avoidance/thread_model/avoidance_use_multiple_threads=false` on the next line, delete it afterwards, and on the base branch and on this one run `godot --fixed-fps 60 --headless --path . --script res://tools/simulate.gd -- res://scenes/game.tscn 4 "tp 19 4" "activate 1 1 0"`, each into a file, then compare the two (the filtered output's checksum, or `diff`): no line differs. What this build found: the filtered output's checksum was `fc6af6dbd110508d8e597824a4f40861` before and after, two runs each.
3. **Play (F5).** The seven zombies look, idle and walk as before. `aggro` shows their rings at the same radius. A swing slides a zombie back and it walks back (its Stagger). Five swings kill one (Health 50), and its Health bar shows over it, as high as before.
4. **In the editor.** Open `zombie.tscn`: the root's tooltip says "Inherits: res://characters/enemy/enemy.tscn", the Inspector shows a revert arrow beside Frames, Speed and Max Health, and `Stagger` is the zombie's own. Select `Movement` and press Delete: the editor refuses ("Can't operate on nodes the current scene inherits from!"). Close the tab without saving.
5. **The iPhone**, optional: `tools/deploy_ios.sh`, which clears the export cache first. The zombies chase and die as before.

## Docs this reopens

**`GLOSSARY.md`**, committed with this spec on the branch (ticket 01's first commit). Find the entries by their text; other steps add entries around them.

- **Enemy**. Today: "A Character of the Enemies' Faction, hostile to the player and their allies. Later Enemies come in kinds (such as elites and bosses) and rarities." Becomes:

  > **Enemy**:
  > A Character of the Enemies' Faction, hostile to the player and their allies. Every Enemy is of an Enemy kind, such as the zombie. Later Enemies also come in rarities.
  > _Avoid_: Monster, mob, creep

- **Enemy kind**, new, right after Enemy:

  > **Enemy kind**:
  > A sort of Enemy, such as the zombie: how it looks, how fast it walks, how much Health it has, its Skills and how it behaves. Every Enemy of a kind starts out the same.
  > _Avoid_: Enemy type, monster type, archetype, variant

  The word needs its own entry because it now names a scene per kind, a test and a section of the conventions, and because the glossary's example gave it another sense: "kinds (such as elites and bosses)". The plan, the analysis and the specs of steps 6 and 7 already say "Enemy kind" for the zombie and a skeleton archer, which is this entry (open rule 2). It stays two words, so it can't be read as the `Kind` enums of `NumberChange` and `TagChange`. Where elites and bosses go is decided when they come.

**`docs/agents/godot-conventions.md`**, ticket 03:

- A new section after "Saved content", before "Static typing":

  > ## Enemy kinds
  >
  > Every Enemy kind (see GLOSSARY.md) is a scene that inherits `characters/enemy/enemy.tscn`, the base. The base holds what every Enemy needs: the nodes `character.gd` and `enemy.gd` look up by name (`Standee`, `Movement`, `NavigationAgent3D`, `Aggro`, `Hurtbox`, `Health`, `HealthBar`, `Skills`) and the body's `CollisionShape3D`, with the values every Enemy shares. Those names are a contract: renaming or removing one changes the scripts too. A kind can't delete, rename or move a node it inherits, so a node some kind might do without, such as a `Stagger`, is each kind's own, and so are its Skills and its behaviour. A kind sets only its own values: its Standee's frames (the base has none), its Movement's speed and its Health's maximum.
  >
  > This is the one place a scene inherits, and it stays one level: a kind inherits the base itself, never another kind, and the base has no behaviour of its own. `tests/test_enemy_kinds.gd` fails on any scene but the base whose root is an Enemy and that doesn't inherit the base directly, or whose Standee has no frames.
  >
  > To add a kind, in the editor:
  >
  > 1. Scene › New Inherited Scene…, and pick `characters/enemy/enemy.tscn`.
  > 2. Double-click the root and name it after the kind.
  > 3. Set `Standee`'s Frames, `Movement`'s Speed and `Health`'s Max Health. Each changed value shows a revert arrow back to the base's.
  > 4. Unless the kind is never staggered, select the root and Add Child Node › `Stagger`. Its Skills go under `Skills`.
  > 5. Scene › Save Scene As… `characters/enemy/<kind>.tscn`, then place it in a Level.
  >
  > A value set in the base is part of every kind that doesn't override it, as a script's default is part of every file that doesn't set it (Saved content). Change the base in the editor, after a reload if the files changed on disk ("The open editor"): an editor holding an old copy of the base writes it back, and every kind then inherits the old one. A kind's file lists only the base nodes it changes, each with its `index` and the base node's `unique_id`, and its own nodes in full; written by hand, it must say exactly that, or the editor rewrites it on its next save.

- In "Saved content", the second bullet's "and the scenes that instance those without overriding it" becomes "and the scenes that instance or inherit those without overriding it". A kind inherits the base; it doesn't instance it.

**`.scratch/enemies/spec.md`**, ticket 03:

- `:49`, the decision "**No inherited enemy base scene.** One Enemy type; extract a base when the second one shows what they share." becomes:

  > - **Enemy kinds inherit one base scene** (since `.scratch/enemy-base/spec.md`, which replaced "No inherited enemy base scene. One Enemy type; extract a base when the second one shows what they share"). `characters/enemy/enemy.tscn` holds what every Enemy needs, and each kind, the zombie first, inherits it and sets only its own values and nodes. It didn't wait for a second kind: the nodes every kind needs are the ones the Enemy and Character scripts look up by name, and a base added later means rebuilding every kind made in the meantime.

- `:48`: "every Enemy type reuses it" becomes "every Enemy kind reuses it" (the glossary now avoids "Enemy type").
- `:99`: "Enemy kinds (elites, bosses) and rarities." becomes "More Enemy kinds; elites, bosses and rarities."
- Requirement 6 (`:31`) and the commit list (`:41`) stay: they say what the zombie is, which is still what the engine builds.

**`.scratch/future-proofing-review/plan.md`**, ticket 03, if open rule 6 keeps the text route: decision 3's last sentence, "The developer rebuilds `zombie.tscn` in the editor.", becomes "An agent writes `enemy.tscn` and the inherited `zombie.tscn` in text, checked against today's zombie, and the developer resaves them once in the editor (`.scratch/enemy-base/spec.md`)." Row 8's "Needs" becomes "step 6; the developer's resave". Under the editor route, nothing changes.

**`.scratch/content-checks/spec.md`**, ticket 03: the rows of the table under "Defaults files rely on" that name `zombie.tscn`, as step 6 leaves them. The second cell becomes:

- `Character.faction`: "`enemy.tscn`, and so `zombie.tscn` (since `.scratch/enemy-base/spec.md`); `player.tscn` sets it (since `.scratch/character/spec.md`)".
- `Character.modifiers`: "`player.tscn`; `enemy.tscn`, and so `zombie.tscn`".
- `Enemy.reach_distance`, `resume_distance`: "`enemy.tscn`, and so `zombie.tscn`".
- `Movement.speed`, `acceleration`, `deceleration`: "`player.tscn` all three; `enemy.tscn` all three, and so `zombie.tscn` the last two (it sets speed 2.5)".
- `Aggro.radius`: "`aggro.tscn`, and so `enemy.tscn` and `zombie.tscn`".
- The Standee row: "`standee.tscn`, and so `player.tscn`, `enemy.tscn` and `zombie.tscn`".
- The sentence after the table, "Nothing relies on `Skill.cooldown` (both Skills set it; rule 3 fails one that would) or `Health.max_health` (both Characters set it).", becomes: "Nothing relies on `Skill.cooldown` (both Skills set it; rule 3 fails one that would), and only `enemy.tscn` on `Health.max_health`: the base leaves the maximum to each kind, and the player and the zombie set theirs."

**Not reopened:** `.scratch/character/spec.md`, whose note that step 8 builds the base "in the editor" followed the plan's wording and records step 6; `.scratch/game-scene/spec.md`; the analysis and the reports. No ADR is touched or written: the conventions' section and the enemies spec's decision say it where agents look.

## Seams

- **Step 6 (`character`)** leaves the zombie this step starts from: its `Stagger` and `Skills` nodes and the editor's resave of them. Copy the starting file's lines, whatever that resave wrote; nothing here depends on its uids. If its open rule 2 went to b (`faction = 1` on the zombie), that line goes on the base's root. `test_character.gd` frees the zombie's `Stagger` before it enters the tree: it still can, the Stagger being the zombie's own.
- **Step 7 (`skill-character`)** changes no scene. Its test gives a zombie an Attack with `add_skill()`, which puts it under the base's `Skills` node.
- **Step 9 (`hit`)** and **step 10 (`ball-in-world`)**, specced in parallel, change scripts under `skills/` and `characters/hurtbox/`, and open no Enemy scene. What would make them: a node every Character needs for a hit (one edit in `enemy.tscn` and one in `player.tscn`, none in the kinds); renaming `Hurtbox` or `Stagger` (the contract: the base or each kind's own node, with the scripts); a value per kind, such as a resistance to knockback (each kind's file); an Enemy Skill that throws a ball (a node under a kind's `Skills`, with the first Enemy Skill).
- **Step 5 (`game-scene`)**: the Level keeps naming `zombie.tscn` by path; nothing in `game.tscn` reaches into an Enemy.
- **Shared docs.** `GLOSSARY.md`: the Enemy entry and a new one after it (step 2 changes Cooldown and adds Projectile speed, step 5 adds Level, step 6 Character and Stagger, step 7 Skill, step 9 Hit). `godot-conventions.md`: a new section after "Saved content" and two words in its second bullet (step 2 wrote that section; steps 3, 5, 6 and 7 edit other paragraphs). `.scratch/content-checks/spec.md`: the rows step 6 also edits, after step 6. Find each by its text, not a line number.

## Open rules for the developer

1. **The Stagger: each kind's own, or the base's?**
   - **a. Each kind's own** (recommended, and written above). The zombie keeps its Stagger as a node of its own, in today's place (`index="6"`), and the base has none.
   - **b. The base's.** `enemy.tscn` gains the `stagger.gd` line and the `Stagger` block between `Hurtbox` and `Health`; `zombie.tscn` loses its `9_stagger` line and its Stagger block, keeping three values. The line accounting prints the same eight lines; the counts become 11 and 4 nodes, 8 and 2 `ext_resource` lines.

   *In play:* nothing either way, today. *For the next kinds:* under a, a kind that should be staggered adds one (Add Child Node › Stagger), and one that forgets is never staggered, which shows on its first hit. Under b, no kind can be made without one: a boss that mustn't be staggered (the analysis's B2) then needs a script change, such as a setting on `Stagger`, or the Stagger leaves the base and is added to every kind made by then. *Why a:* a Character without a Stagger is never staggered by design (step 6, rule 10), so the Stagger is a part some kind will do without, and the settled rule keeps such parts out of the base.

2. **What an Enemy kind is.**
   - **a. A sort of Enemy, such as the zombie** (recommended): the glossary gains **Enemy kind**, and the Enemy entry loses "(such as elites and bosses)".
   - **b. Elites and bosses, as the glossary has it.** The zombie-level idea then needs another word, which this spec, the test's name and the conventions use instead.

   *Why a:* plan.md decision 3, the analysis and the specs of steps 6 and 7 already use "Enemy kind" for the zombie and a skeleton archer. An elite may well turn out to be a rarity of a kind, and a boss a kind of its own; that is decided when they come.

3. **How the test finds the kinds.**
   - **a. Every scene in the project whose root is an Enemy** (recommended).
   - **b. Every scene under `characters/enemy/` but the base** (the analysis's).

   *For the next kinds:* under b, a kind saved elsewhere is never checked, and a scene in that folder that isn't a kind (an Enemy Skill's ball) fails the test. Under a, the test builds every scene off the tree, as `test_content.gd` already does.

4. **One level of inheritance.**
   - **a. A kind inherits the base itself**; a kind that inherits another kind fails the test (recommended).
   - **b. Kinds of kinds allowed**: the test walks down the base scenes until it reaches `enemy.tscn`.

   *Why a:* a second level is the inheritance chain the conventions warn against ("Why one inherited scene is not an inheritance chain"). Elites and rarities are designed when they come, perhaps not as scenes at all (the analysis's option E).

5. **Frames: none in the base, checked in every kind.**
   - **a. As written** (recommended): the base has no frames, so it doesn't run on its own, and the test fails a kind whose Standee has none.
   - **b. The base has the zombie's frames**, so `enemy.tscn` runs on its own (F6). A kind that forgets its frames then looks like a zombie, and the test can't tell. The zombie's frames would equal the base's, and the editor drops them from `zombie.tscn`.
   - **c. As a, without the frames check**: a kind that forgets its frames fails only once a Level places it and the game runs.

6. **The route for the scene edit.**
   - **a. By an agent, in text** (ticket 01), then the developer's resave (ticket 04) (recommended).
   - **b. By the developer, in the editor** (the plan's wording): ticket 01's scene part becomes the developer's ("By the developer, in the editor"), and ticket 04 has no resave.

   *Why a:* the same two files and the same proof, about two minutes of the developer's time instead of ten, and every line readable before the editor touches it.

Settled by the plan, not open: one base scene for Enemy kinds, built now; no `character.tscn` above it; the player's scene stays its own; the base holds only what every Enemy needs; the zombie sets its frames, speed and Health; a test checks that every kind inherits the base; no script changes.

## Out of scope

| What | Trigger that brings it back |
|---|---|
| `character.tscn` above `player.tscn` and `enemy.tscn` | A third sort of Character that isn't an Enemy kind, such as a pet. Adding it then rebuilds two scenes, however many kinds exist. |
| Size classes | The first Enemy kind that must be another size. The analysis found (brief B6): the Level's navmesh is baked for one walker, radius 0.3 and height 1.0 (`scenes/sandbox_navmesh.tres:8-9`), and every Character has the same 0.25 capsule, with one Hurtbox capsule in `hurtbox.tscn`. A bigger body is routed through gaps it doesn't fit and wedges; a smaller one can't use gaps it would fit. The way it found: a few size classes, each with its own navigation region and navigation layer and its own bake (`tools/bake_navmesh.gd` already bakes every region in a scene), and each kind setting its class: its body capsule, its Hurtbox's shape, its agent's radius and layers. In this base, a kind would set its own capsule on `CollisionShape3D` rather than edit the base's, which the editor won't do from a kind (Engine facts 5); the Character could hand its body's shape to its Hurtbox, so a kind sets its size once. Until then, a big Standee can stand on the same footprint. |
| The Enemy's behaviour as its own node | The first Enemy Skill, or a second kind that behaves otherwise before it (the analysis's B5, the plan's table). It is then a node each kind adds, not a base node, and `enemy.gd` loses its chasing. Until then every kind chases as the zombie does. |
| A kind of a kind; elites and rarities | Their design, likely with Enemies spawned by Level and rarity, where the analysis's option E (one scene and a data resource per kind) is worth weighing again |
| A kind without one of the base's nodes, such as a turret that doesn't walk | That kind: `Movement` and `NavigationAgent3D` then leave the contract, through the behaviour node above or a change to `enemy.gd` |
| A check that nothing places the base itself | A spawner, or a second place that instances Enemies |
| Skills in a kind's `Skills` node | The first Enemy Skill |

## Known limits

- The base doesn't run on its own: F6 on `enemy.tscn` shows the Standee's assertion and an error every frame. Run a kind, or the game scene.
- A node added to the base ahead of a node a kind changes shifts that kind's `index` numbers, so the kind's file changes the next time it is saved, though nothing in play does. A base node added after `Skills` shifts nothing.
- `tools/load_all.gd` passes a kind whose entry names a node the base no longer has, since the engine only warns; `tests/test_content.gd` fails on the warning.
- A kind given its Stagger with Add Child Node › `Stagger` carries `metadata/_custom_type_script`, the editor's note that the node was made as a Stagger. Harmless.
- A kind's file is read next to the base, or opened in the editor: alone it lists only what the kind changes.

## Where this departs from the analysis

- **The base follows step 6's scripts**, not `enemy.gd` at `8797660`. The analysis listed seven lookups, each failing in `_ready`. After step 6, `Standee`, `Health` and `HealthBar` are `Character`'s; the Hurtbox is found with `get_node_or_null` (the player has none), though `Enemy._die()` still needs it; `Skills` is required; and `Stagger` is optional, so it stays with the kind, where the analysis put it in the base.
- **The zombie is written in text**, where the analysis said it "must be made in the editor". The format comes from the 4.7-stable source, the dump proves the result, and the developer resaves it once (open rule 6).
- **What the analysis left to an editor check, read from the source**: a kind can't delete, rename, move or reparent a base node (the editor refuses); Clear Inheritance exists; saving the base writes no kind's file; a kind can't edit a base resource from the Inspector. And renaming a base node doesn't silently orphan a kind's values: the engine finds the node by its `unique_id` and warns (Engine facts 2, 5).
- **The test** finds kinds by their root's class instead of their folder, allows one level only, and checks frames; the analysis's version checked the folder and the base.
- **"Enemy kind" gets a glossary entry**, and the Enemy entry loses its example of elites and bosses.
- **The checks run `game.tscn`**, step 5's main scene; the analysis ran `sandbox.tscn`, which is the Level alone after step 5.

## Engine facts

Godot 4.7-stable source at `5b4e0cb0f` (the local editor's build) and the 4.7 docs, read on 2026-11-22. Nothing was run.

1. **Reading a scene file.** A `[node]` with `instance=` and no `parent`, first in the file, makes the scene inherit that scene; a `[node]` without `type` is taken as a node of an instanced or inherited scene; `index` and `unique_id` are read from the header (`scene/resources/resource_format_text.cpp:215-223`, `:234-241`, `:270-274`).
2. **Building an inherited scene.** The root is the base built first, then the file's values are set on it (`scene/resources/packed_scene.cpp:229-238`). A node without a type is found in its parent by name; failing that, by its `unique_id`, with the warning "A node in the scene this one inherits from has been removed or moved … Please re-save this scene"; failing that, it is skipped with the warning "was modified from inside an instance, but it has vanished" (`:282-315`). A base node takes the base's `unique_id` whatever the file says (`:301-307`). A node the file adds is moved to its `index` among its siblings (`:514-547`).
3. **Saving a scene** (what the editor writes). A base node is written only if it holds a value or a group that differs from the base's (`packed_scene.cpp:1066-1079`); a value equal to the base's, to the script's default or to the class's default is left out (`:980-996`), floats compared approximately (`scene/property_utils.cpp:44-47`), the base's value found through the base's scene state (`property_utils.cpp:80-150`, `:239-286`). In an inherited scene, every node written but the root gets its `index` (`packed_scene.cpp:821-831`). A base node is written without a type (`:1050-1064`). A node keeps its `unique_id` unless it has none or repeats one already written in the file (`:1099-1123`). The inherited root's `instance=` names the base (`:1912-1928`).
4. **The text the saver writes.** A node's header is name, type, parent, owner, `index="N"`, `unique_id=N`, node paths, groups, then `instance=` (`resource_format_text.cpp:2024-2086`). `ext_resource` lines are sorted by id in natural order (`resource_format_text.h:193-199`, `.cpp:1868-1890`); each keeps the id it had in that file when the file was loaded (`.cpp:538-543`, `:1822-1839`); a line gets a uid only if its file's uid is known (`:1884-1887`). A scene's first line gets its uid, a new one if it has none, kept when a file is saved over (`:1812-1816`; `editor/file_system/editor_file_system.cpp:3660-3688`).
5. **The editor.** New Inherited Scene builds the base as the new scene's root and records it as inherited (`editor/editor_node.cpp:4917-4931`). The Scene dock refuses to delete, rename, move, reparent or change the type of a node the scene inherits: "Can't operate on nodes the current scene inherits from!" (`editor/docks/scene_tree_dock.cpp:2405-2429`; erase `:1158-1169`, rename `:624-630`, move `:872-889`, reparent `:1044-1060`, type `:798-805`, drag `:3792-3793`). The inherited root can be renamed in the tree (`editor/scene/scene_tree_editor.cpp:301`, `:405-406`). Clear Inheritance exists, without undo (`scene_tree_dock.cpp:1456-1479`, `:5216-5218`). A base's resource, opened from a kind, shows as "This object is read-only.": "This resource belongs to a scene that was instantiated or inherited. Changes to it must be made inside the original scene." (`editor_node.cpp:3186`, `:3268-3271`). Saving a scene writes that one file (`editor_node.cpp:2466-2558`). A node made from a script class in the Create dialog gets `metadata/_custom_type_script` (`editor/editor_data.cpp:1058-1066`, `scene/property_utils.cpp:288-299`).
6. **`SceneState`, 4.7.** `get_base_scene_state()`: "Returns the SceneState of the scene that this scene inherits from, or null if it doesn't inherit from any scene." `get_path()`: "Returns the resource path to the represented PackedScene", which a loaded scene's state carries (`packed_scene.cpp:2600-2608`). `get_node_index()`: "only relevant and saved in scenes for cases where new nodes are added to an instantiated or inherited scene among siblings from the base scene." `PackedScene.get_state()`: "Returns the SceneState representing the scene file contents."
7. **The TSCN format, 4.7 docs.** `index` "sets the order of appearance in the tree; if absent, inherited nodes will take precedence over plain ones"; `unique_id` is "used to track nodes even if they are moved or renamed", in scenes saved with 4.6 or later; "properties equal to the default value are not stored"; `load_steps` is deprecated since 4.6. The page doesn't describe inherited scenes; facts 1 to 4 do.
8. **No `_ready` off the tree.** `Node._ready()`: "Called when the node is 'ready', i.e. when both the node and its children have entered the scene tree." `tools/load_all.gd` and `tests/test_content.gd` build every scene without adding it.
9. **GUT 9.7.1, as vendored, fails a test on an engine warning** as on an error: an engine error is any logger message that isn't a `push_error` or `push_warning` (`addons/gut/gut_tracked_error.gd:52-53`, `error_tracker.gd:67-76`, `gut_config.gd:57`).

## Done when

- [ ] `enemy.tscn` and `zombie.tscn` are as in "The change, file by file"; the line accounting prints its eight lines, and the dump comparison prints nothing.
- [ ] `tests/test_enemy_kinds.gd` passes, and failed on each of its three breakages; the PR says how.
- [ ] No script changed, and nothing that names `zombie.tscn` changed; `tools/check.sh` passes.
- [ ] `tools/simulate.gd` on the game scene prints the same lines as on `skill-character`.
- [ ] The docs read as in "Docs this reopens".
- [ ] The editor's resave is one commit, and changed no value; "Checking by hand" holds.
- [ ] `/code-review` has run on the branch before its PR.

## Tickets

1. `issues/01-the-base-and-the-zombie.md`: this spec and the glossary, then `enemy.tscn` and the inherited `zombie.tscn`, checked by the dump and the line accounting.
2. `issues/02-every-kind-inherits-the-base.md`: `tests/test_enemy_kinds.gd`, and the three breakages it fails on.
3. `issues/03-reopened-docs.md`: the conventions, the enemies spec, the plan and the content-checks table.
4. `issues/04-resave-checks-and-pr.md`: the developer's resave, the checks by hand, `/code-review` and the PR.
