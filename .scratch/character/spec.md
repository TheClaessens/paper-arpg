# Character

Status: ready-for-agent

Tickets 01 to 04 are built on the recommended answers to the open rules, which the developer confirms when reading this step's PR. Ticket 05 is the developer's.

The glossary's **Character** gets a home in code. A thin `Character` script, which `Player` and `Enemy` both extend, holds a Character's **Faction**, its **Modifiers** and its **Skills**, and wires its components: its **Health** shows on its **Health bar**, and a hit on its **Hurtbox** lowers its Health, starts its **Stagger** and flashes and squashes its **Standee**. The slide with the knockback becomes a `Stagger` component. Each Character scene gets a `Skills` node that holds its Skill nodes. Nothing changes in play. One rule changes that no Skill reaches today: a Stagger of 0 (open rule 1).

Step 6 of `.scratch/future-proofing-review/plan.md`, on branch `character`, stacked on step 5 (`game-scene`) as the plan stacks every step (decision 8). Step 7 (`.scratch/skill-character/spec.md`) builds on it. Sources: `.scratch/future-proofing-review/analysis/character-enemy.md` sections 1, 3, 4, 6, 9 and 10 and work package WP1, each claim checked against the code at `8797660`. Line numbers are that commit's: steps 1 to 5 change none of `player.gd`, `enemy.gd`, `player.tscn` and `zombie.tscn`. Where this spec departs from the analysis is listed near the end.

## What changes and why

The player's Character and the zombie each carry their own copy of what every Character has. Both scripts declare a Faction with their own default (`player.gd:44-46`, `enemy.gd:9-11`), and both connect Health to the Health bar with the same line (`player.gd:78`, `enemy.gd:39`). Only the Player has Skills and Modifiers (`player.gd:35-50`); it hands its Skills their Faction once, in `_ready` (`:79-80`), so a Skill added later keeps the enum's first value, the player's. Only the zombie can be hit (`enemy.gd:37-38`, `:58-69`), and its slide is four pieces of `enemy.gd` (`:21-23`, `:51-55`, `:73-75`, `:123-137`). The first Enemy Skill would copy the Player's half into `enemy.gd`, and a player who can be hit would copy the Enemy's half into `player.gd`. And code that takes "a Character", such as a Skill's Character in step 7, has no type to name.

| A Character's part | Today | After |
|---|---|---|
| Its Faction | an export in each script, `player.gd:44-46` (player's), `enemy.gd:9-11` (Enemies') | `Character.faction`, the Enemies' by default; `player.tscn` sets the player's |
| Its Modifiers | `player.gd:48-50` | `Character.modifiers` |
| Its Skills | `player.gd:35-42`: every Skill child of the Player | `Character.skills`: every Skill under its `Skills` node; `add_skill()` |
| Its Faction handed to its Skills | `player.gd:79-80`; an Enemy has none | `Character._ready()` and `add_skill()` |
| Health shown on the Health bar | `player.gd:78`, `enemy.gd:39` | `Character._ready()` |
| Its Hurtbox on its Faction's layer | `enemy.gd:37` | `Character._ready()`, when it has a Hurtbox |
| A hit: Damage, Stagger, flash, squash | `enemy.gd:38`, `:58-69` | `Character._on_hit_taken()` |
| The slide with the knockback | `enemy.gd:21-23`, `:51-55`, `:73-75`, `:123-137` | a `Stagger` component; `Enemy._slide()` |
| Dying | `enemy.gd:40`, `:109-120` | unchanged, the Enemy's |
| Facing, Controls, aiming, the Skill bar, the Console commands | `player.gd` | unchanged, the Player's |
| Chasing, navigation, avoidance | `enemy.gd` | unchanged, the Enemy's |

### The node trees

```
player.tscn, today                          player.tscn, after
Player (player.gd)                          Player (player.gd)                faction = 0, new
├─ CollisionShape3D                         ├─ CollisionShape3D
├─ Standee                                  ├─ Standee
├─ Movement                                 ├─ Movement
├─ Health                                   ├─ Health
├─ Controls                                 ├─ Controls
├─ FacingArrow                              ├─ FacingArrow
│  └─ Mesh                                  │  └─ Mesh
├─ Attack           (1240203622)            ├─ Skills (Node3D)                new, no transform
├─ Fireball         (877120161)             │  ├─ Attack      (1240203622)
├─ SkillBar         main_skill ../Attack    │  └─ Fireball    (877120161)
├─ AimMarker                                ├─ SkillBar       main_skill ../Skills/Attack
├─ HoverRing                                ├─ AimMarker
└─ HealthBar                                ├─ HoverRing
                                            └─ HealthBar
                                            no Hurtbox and no Stagger, as today

zombie.tscn, today                          zombie.tscn, after
Zombie (enemy.gd)                           Zombie (enemy.gd)
├─ CollisionShape3D                         ├─ CollisionShape3D
├─ Standee                                  ├─ Standee
├─ Movement                                 ├─ Movement
├─ NavigationAgent3D                        ├─ NavigationAgent3D
├─ Aggro                                    ├─ Aggro
├─ Hurtbox                                  ├─ Hurtbox
├─ Health                                   ├─ Stagger (stagger.gd)           new
└─ HealthBar                                ├─ Health
                                            ├─ HealthBar
                                            └─ Skills (Node3D)                new, empty
```

The numbers are the nodes' `unique_id`s, which stay. Step 8 (`enemy-base`) moves the zombie's nodes into an inherited `enemy.tscn` built in the editor (plan.md decision 3). Nothing here depends on it: the scripts find their nodes by name, in whichever file they are declared.

## Why a base script, when the conventions say component first

The conventions say: "Reach for a new component before an inheritance chain." That warns against behaviour handed down through levels (a fighter under the Character, a melee fighter under that), where a change in one level reaches every level below, and a kind that wants half a level can't have it. `Character` is not that:

- **One level, for the glossary's own umbrella term.** The player's hero and every Enemy are each a Character. `Player` and `Enemy` extend it, and nothing extends them: an Enemy kind is a scene, not a script (step 8).
- **Identity and wiring, not behaviour.** It holds what makes something a Character (its Faction, its Modifiers, its Skills) and connects its components. Health, the Health bar, the Hurtbox, the Stagger, the Standee and Movement stay components that work the same on any Character. Where to walk and what to activate stay in `Player` and `Enemy`.
- **A component can't be this.** A Skill has to reach the body it belongs to: its Faction in step 7, its identity and its place in the world in steps 9 and 10. A component holding the Faction and Modifiers would only point back at the body.
- **Without it, the wiring is copied.** `player.gd:78` and `enemy.gd:39` are already the same line, and every Character that can be hit would copy the hit reaction.

## The rules

1. **`Player` and `Enemy` extend `Character`**, which extends `CharacterBody3D`. Nothing extends `Player` or `Enemy`.
2. **A Character's Faction** is `Character.faction`: the Enemies' unless its scene says otherwise, and `player.tscn` says the player's. When the Character is ready, its Hurtbox (if it has one) is on its Faction's layer and each of its Skills has its Faction. A Skill given later with `add_skill()` gets it too. Its body's collision layers and its Aggro are set by its scene, not by its Faction.
3. **A Character's Skills** are the Skill nodes under its `Skills` node (`Character.skills`), in their order there. `add_skill(skill)` puts one there, before or after the Character enters the tree.
4. **The `Skills` node** is a `Node3D` without a transform of its own, so each Skill stands where its Character stands. Every Character scene has one, even an empty one. In `player.tscn` it comes before `SkillBar` (see "Process order").
5. **A Character's Modifiers** are `Character.modifiers`. The Player activates its Skills with them and aims with them, as today.
6. **A Character's Health shows on its Health bar**, for the player and the zombie, as today.
7. **A hit on a Character's Hurtbox** lowers its Health by the hit's Damage, then starts its Stagger with the hit's knockback (the hit's direction times its Knockback) and the hit's Stagger, then flashes and squashes its Standee with Hit feedback's values. A Character without a Hurtbox can't be hit. The killing hit doesn't knock back: when its Stagger starts, the Enemy's death has already stopped its physics, as today.
8. **A Stagger** slides its Character exactly its knockback over the Stagger's time, fastest at first, at any frame rate, and the Character doesn't walk meanwhile. A frame the world is frozen in (Hit feedback) moves nothing and doesn't run the Stagger's clock. A hit during a Stagger restarts it with that hit's knockback and Stagger.
9. **A Stagger of 0 does nothing** (open rule 1, the plan's working answer): no hold and no slide, even with knockback, and a Stagger already running goes on as it was. Today it is raised to 0.02 s (`enemy.gd:63-64`). No Skill or Modifier reaches 0 today.
10. **A Character without a Stagger is never staggered**: a hit still takes its Damage and shows on its Standee. The player has neither a Hurtbox nor a Stagger.
11. **Death stays the Enemy's.** At 0 Health an Enemy switches off today's list in `Enemy._die()`; the player at 0 stays at 0, which Health already does. `Character` connects nothing to `died`.
12. **The Console's `bar` finds a Skill by its node name**, in any case: `bar 2 fireball` finds the node `Fireball` whatever its title. The reply still names the Skill's title. A title with a space could never be typed.

Nothing else changes in play.

## The change, file by file

The sketches show shape and the doc comments to use; the implementer writes the code.

### `characters/character.gd`, new (tickets 02 and 03)

```gdscript
class_name Character
extends CharacterBody3D
## A Character (see GLOSSARY.md): the player's hero or an Enemy. It holds its Faction, its
## Modifiers and its Skills, and wires its components: its Health shows on its Health bar, and
## a hit on its Hurtbox lowers its Health, starts its Stagger and flashes and squashes its
## Standee. Wiring and identity only: Player and Enemy decide where it walks and what it
## activates, and the script driving the body (the Enemy) slides with the Stagger. Without a
## Hurtbox it can't be hit; without a Stagger it is never staggered. It puts its Hurtbox on its
## Faction's layer and hands its Faction to its Skills; its body's collision layers and its
## Aggro are its scene's.
## A script that extends it and has _ready() calls super() first: a subclass's _ready()
## replaces this one.

## Its Faction: its Hurtbox goes on that Faction's layer, and its Skills hit only Hurtboxes
## hostile to it. The Enemies' unless its scene says otherwise, as the player's scene does.
@export var faction := Faction.Id.ENEMIES
## Its Modifiers: every activation of its Skills is made with them.
@export var modifiers: Array[Modifier] = []

## The Skills it has: every Skill under its Skills node.
var skills: Array[Skill]:
	get: # today's getter (player.gd:37-42), reading $Skills.get_children()

## How much more Damage it can take.
@onready var health: Health = $Health
## Shows its Health while it is below the maximum.
@onready var health_bar: HealthBar = $HealthBar
## The part of it that Skills hit, or null: then it can't be hit.
@onready var hurtbox: Hurtbox = get_node_or_null(^"Hurtbox")
@onready var _stagger: Stagger = get_node_or_null(^"Stagger") # null: never staggered (ticket 03)
@onready var _standee: Standee = $Standee # ticket 03


func _ready() -> void:
	health.changed.connect(health_bar.show_health)
	if hurtbox:
		hurtbox.collision_layer = Faction.layer(faction)
		hurtbox.hit_taken.connect(_on_hit_taken) # ticket 03
	for skill in skills:
		skill.faction = faction


## Gives it `skill`: puts it under its Skills node, which stands where it stands and comes before
## whatever activates its Skills, and hands it its Faction. Before or after it enters the tree.
func add_skill(skill: Skill) -> void:
	$Skills.add_child(skill)
	skill.faction = faction


# A hit on its Hurtbox, pushing along `direction` (a unit vector on the ground): the one place a
# hit lands on a Character. Damage first, then the Stagger, then the Standee. (ticket 03)
func _on_hit_taken(direction: Vector3, snapshot: Snapshot) -> void:
	health.damage(snapshot.number(Skill.DAMAGE))
	if _stagger:
		_stagger.start(direction * snapshot.number(Skill.KNOCKBACK), snapshot.number(Skill.STAGGER))
	var feedback := HitFeedback.shared()
	_standee.flash(feedback.flash)
	_standee.squash(feedback.squash)
```

- **What it connects in `_ready`:** Health's `changed` to the Health bar's `show_health`; the Hurtbox's `hit_taken` to `_on_hit_taken` (ticket 03; until then `Enemy._ready()` keeps connecting its own); nothing to `died`.
- **Public:** `faction`, `modifiers`, `skills`, `health`, `health_bar`, `hurtbox`, `add_skill()`. `_slide()` lives in `Enemy`, not here: `Character` is wiring and identity only.
- **Not here:** Movement (`Player` and `Enemy` each keep their own `_movement` lookup: `Character` doesn't use it), Facing, a `died` signal of its own (`health.died` is public and nothing would connect a second one).
- **`Enemy._slide` in a frozen frame:** `next_velocity(0.0)` returns zero, so `velocity` reads zero for that frame where today it kept its last value (`enemy.gd:126-127` returned before touching it). Nothing reads a staggered Character's `velocity` before the next frame sets it again, so nothing shows.

### `characters/stagger/stagger.gd`, new (ticket 03)

Today's slide (`enemy.gd:21-23`, `:51-55`, `:63-66`, `:128-134`), moved into a component the Character polls, as it polls Movement.

```gdscript
class_name Stagger
extends Node
## A Character's Stagger (see GLOSSARY.md): the short time after a hit when it slides with the
## knockback and doesn't walk. Another hit restarts it; a hit with a Stagger of 0 doesn't stagger.
## The Character starts it when hit and asks it each physics frame whether it is staggered and how
## fast to slide, then moves itself, as it asks Movement how fast to walk. It has no process of
## its own, so it stops when its Character stops. A Character without one is never staggered.

var _left := 0.0 # seconds still to go
var _length := 0.0 # the whole Stagger, in seconds
var _knockback := Vector3.ZERO # direction on the ground times distance


## Staggers it for `seconds`, sliding `knockback` (a direction on the ground times a distance in
## world units) over that time, fastest at first. A Stagger already running restarts with these.
## A Stagger of 0 or less does nothing, and leaves one already running as it is.
func start(knockback: Vector3, seconds: float) -> void:
	if seconds <= 0.0:
		return
	# _length, _left and _knockback set as enemy.gd:64-66 set theirs, without the 0.02 floor


## Whether it is staggered now.
func is_active() -> bool:


## This frame's share of the slide, as a velocity, with the Stagger's clock run on by `delta`:
## over the whole Stagger it covers exactly the knockback, at any frame rate and however few
## frames it lasts. Zero, and the clock held, in a frame the world is frozen in (delta 0).
func next_velocity(delta: float) -> Vector3:
	# enemy.gd:130-134, returning the velocity instead of setting it


## How much of a `distance`-long knockback slide is still to go with `left` seconds of a
## `stagger`-long Stagger remaining. The slide's speed falls linearly to zero, so the distance
## still to go shrinks with the square of the time left.
static func knockback_left(distance: float, stagger: float, left: float) -> float:
	# enemy.gd:55, unchanged
```

No exports, no signals (nothing would listen), nothing in `_ready`. `knockback_left` keeps its name and body: it moves, it isn't renamed. If open rule 1 goes to option c (today's), `start()` loses its early return and sets `_length = maxf(seconds, 0.02)`, and its doc's last sentence goes.

### `characters/player/player.gd`

By today's line numbers.

- **Leaves:** `:35-42` the `skills` getter and `:48-50` `modifiers` (to `Character`; ticket 01 first makes the getter read `$Skills`); `:44-46` `faction` (to `Character`, whose default is the Enemies'); `:54-57` `health` and `health_bar` (to `Character`); `:61` `_standee` (to `Character`, ticket 03); `:78` the Health bar line and `:79-80` the Faction loop (to `Character._ready()`). GDScript refuses a member a parent script already declares, so each goes, not just its use.
- **Changes:** `:2` `extends Character`. `:3-7`: "It has its Skills (child nodes) and its Modifiers, and activates a Skill when its Skill bar asks" becomes "It activates one of its Skills (see Character) when its Skill bar asks"; the rest of the doc stays. `_ready()` (`:77`) starts with `super()`. In `_cmd_bar`, `:211` compares `String(skill.name).to_lower()` with the word typed, and `:214` lists the node names, which are what `bar` takes; `:213`'s reply keeps the title.
- **Stays:** everything else: `skill_activated`, the constants and `PROOF_MODIFIERS`, `facing`, `skill_bar`, `_face_aim_left`, `_controls`, `_movement`, `_facing_arrow`, `_aim_marker`, `_hover_ring`, `_enter_tree` and its six commands, `:81-85` of `_ready`, `_physics_process` (no Stagger: it never calls `_slide()`), the aiming and Auto-aim code, the command bodies. The HUD's surface stays as it is: `skill_bar`, `skill_activated`, `aim_from_drag`, `show_aim`, `hide_aim`, and `skills`, now inherited under the same name and type.

### `characters/enemy/enemy.gd`

By today's line numbers.

- **Leaves:** `:9-11` `faction` and `:25-30` `hurtbox`, `health`, `health_bar` (to `Character`, ticket 02); `:37` the Hurtbox's layer and `:39` the Health bar line (to `Character._ready()`, ticket 02); `:21-23` the Stagger fields, `:51-55` `knockback_left`, `:123-137` `_slide` (to `Stagger`, and `_slide` itself stays in `Enemy`, ticket 03); `:58-69` `_on_hit_taken` and `:38` its connection (to `Character`, ticket 03); `:32` `_standee` (to `Character`, ticket 03).
- **Changes:** `:2` `extends Character`. `_ready()` (`:36`) starts with `super()` and then asserts it has a Hurtbox. `:73-75` become `if _slide(delta): return`, and `_slide()` stays next to `_physics_process`, reading `Character`'s `_stagger`.
- **Stays:** the doc comment `:3-7` (it describes what an Enemy does, and still does), `reach_distance`, `resume_distance`, `_target`, `_chasing`, `_movement`, `_agent`, `:40-43` of `_ready` (`died` to `_die`, Aggro, avoidance, `max_speed`), `should_chase`, the rest of `_physics_process`, `_on_velocity_computed`, `_die()` whole, `_flat`.

### `characters/player/player.tscn`

Four edits, all safe in text (see "The scene edits and the open editor"):

1. Ticket 01: after the `Mesh` block (`:64-67`), a new block `[node name="Skills" type="Node3D" parent="."]`, with no `unique_id` (the editor's resave adds one) and no transform.
2. Ticket 01: `:69` and `:71`, `parent="."` becomes `parent="Skills"` for `Attack` and `Fireball`. Everything else on those lines stays, their `unique_id`s (1240203622, 877120161) above all.
3. Ticket 01: `:75`, `main_skill = NodePath("../Attack")` becomes `NodePath("../Skills/Attack")`. A path that leads nowhere would leave the main slot empty without an error; `test_player.gd`'s slot-0 tests catch it.
4. Ticket 02: on the root, after `script = ExtResource("1_player")` (`:42`), `faction = 0`. It goes in the same commit as the default it guards: the Player's default Faction becomes the Enemies' in that commit (the "Saved content" convention, from step 2). `Faction.Id` is now saved by a file, so its "only added to at the end" rule starts to bite.

Everything else stays character for character: the header's `uid://b7lxromdaqgee` (step 5's `game.tscn` names it), the `ext_resource` lines, the root's layer 2 and mask 5, `motion_mode`, `safe_margin`, `SkillBar`'s `node_paths`, every other `unique_id`.

### `characters/enemy/zombie.tscn`

1. Ticket 01: at the end, `[node name="Skills" type="Node3D" parent="."]`, no `unique_id`.
2. Ticket 03: an `ext_resource` line after `:10`, `[ext_resource type="Script" path="res://characters/stagger/stagger.gd" id="9_stagger"]`, and after the `Hurtbox` block (`:45`) a block `[node name="Stagger" type="Node" parent="."]` with `script = ExtResource("9_stagger")`, no `unique_id`.

Everything else stays: the nine `unique_id`s 1938276001 to 1938276009, the layers, the agent's settings, the header without a uid (the resave adds one).

### Unchanged on purpose

- `characters/health/health.gd`: step 1 (`number-bounds`) owns its guard on amounts of 0 or less.
- `skills/skill.gd`: its `faction` (`:53-55`) and the Skill's doc stay until step 7.
- `characters/hurtbox/hurtbox.gd`: the hit keeps its two arguments until step 9.
- `characters/standee/standee.gd`, `characters/movement.gd`, `characters/aggro/`, `ui/`, `scenes/`: no change. `game.tscn` (step 5) only adds a camera under the Player instance and sets nothing inside it.

## The scene edits and the open editor

The developer keeps the editor open, and it overwrites scenes changed on disk and resaves hand-written ones ("The open editor" in the conventions). So:

- **The agent edits both scenes in text** (tickets 01 to 03), in a worktree no editor has open, or while the developer's editor is closed or on another branch. Every edit is a line added or a value changed, so it can be checked line by line. Before committing each, from the repo root:

  ```bash
  scene_lines() { sed -E 's/ parent="[^"]*"//; s/ (uid="uid:\/\/[a-z0-9]+"|unique_id=[0-9]+)//g' | grep -v '^$' | LC_ALL=C sort; }
  for f in characters/player/player.tscn characters/enemy/zombie.tscn; do echo "== $f"; diff <(git show HEAD:$f | scene_lines) <(scene_lines < $f); done
  ```

  It shows only that ticket's lines: in 01, `player.tscn`'s new `Skills` line and `main_skill`'s new path, and `zombie.tscn`'s new `Skills` line (the two moved nodes don't show: only their parent changed); in 02, `faction = 0`; in 03, the Stagger's `ext_resource`, node and `script` lines. `grep -n 'name="Attack"\|name="Fireball"' characters/player/player.tscn` shows `parent="Skills"` and the two `unique_id`s.
- **After each of those commits, the developer reloads** (Project › Reload Current Project) before saving anything in the editor. If the editor asks about files newer on disk, choose Reload, never Resave. If `git diff` ever shows the `Skills` node gone from `player.tscn`, the editor wrote its stale copy: `git checkout -- characters/player/player.tscn` and reload.
- **The editor's resave, once, at the end** (ticket 05): open both scenes, save each, and commit that alone. It should add a uid to `zombie.tscn`'s first line, `unique_id`s to the new nodes, uids on `ext_resource` lines, and nothing else. The check, before committing it:

  ```bash
  scene_lines() { sed -E 's/ (uid="uid:\/\/[a-z0-9]+"|unique_id=[0-9]+)//g' | grep -v '^$' | LC_ALL=C sort; }
  for f in characters/player/player.tscn characters/enemy/zombie.tscn; do diff <(git show HEAD:$f | scene_lines) <(scene_lines < $f); done
  ```

  It prints nothing. A line it prints is one the editor changed or dropped: stop and look. If the resave writes a uid into an `ext_resource` line for a file whose own first line declares none on the branch (today none of `standee.tscn`, `hurtbox.tscn`, `aggro.tscn`, `health_bar.tscn`, `aim_marker.tscn`, `attack.tscn`, `fireball.tscn` and the two `SpriteFrames` files does), that file's first line goes in the same commit, or a fresh checkout fails `tools/check.sh` on "invalid UID". `scenes/sandbox.tscn` names `zombie.tscn` by path only; when the editor next saves it with `zombie.tscn`'s new uid, commit that with the file it came from.
- The new scripts' `.gd.uid` files (written by the import step of `tools/check.sh`) are committed with their scripts.

## Process order: what the `Skills` node gives

Godot runs physics callbacks of equal priority "in tree order, or top to bottom as seen in the editor" (`Node._physics_process`, 4.7), and no node here sets a priority. `Skills` comes before `SkillBar` in `player.tscn`, so every Skill under it, including one given later with `add_skill()`, runs its Cooldown before the Skill bar asks for activations in the same frame. That is today's order for the Attack and Fireball (`player.tscn:69-75`); a Skill added with `add_child()` came after the bar (`test_aim_modes.gd:32`).

That is enough, and no process priorities are needed. A held Attack (Cooldown 0.4 s: 24 ticks at 60 Hz leave a rounding crumb above 0, so it repeats every 25 frames, about 0.417 s) repeats every 25 frames in either order:

- **Skill before the bar:** activated in frame N; its Cooldown runs in N+1 to N+25 and ends in N+25; the bar, later in N+25, repeats it.
- **Skill after the bar:** activated in frame N; its Cooldown runs later in N too and ends in N+24; the bar repeats it in N+25.

Only two things move by one frame: the slot's ready flash (`ready_again`) comes in the repeat's frame or the frame before, and a fresh press arriving in that one frame is taken or ignored (`press()` checks `is_ready()` when the press arrives, `skill_bar.gd:56-60`). With every Skill under `Skills`, those are the same for every Skill, whenever it came, for free.

## Tests

Run one file with `godot --headless --path . -s addons/gut/gut_cmdln.gd -gselect=test_<subject>.gd -gexit`, then `tools/check.sh`.

**Moved.** `test_enemy.gd:31-37` (`test_knockback_left_over_the_stagger` and its comment) goes to `tests/test_stagger.gd`, `Enemy.knockback_left` becoming `Stagger.knockback_left`. `test_enemy.gd` keeps its four reach tests.

**A node path only.** `test_player.gd:132` (`"Fireball"` → `"Skills/Fireball"`), `:252` and `:263` (`"Attack"` → `"Skills/Attack"`); `test_pause_menu.gd:60` and `test_skill_bar_hud.gd:24` (`"Fireball"` → `"Skills/Fireball"`). Ticket 01.

**A call.** `test_aim_modes.gd:32`: `player.add_child(skill)` becomes `player.add_skill(skill)`. Ticket 02.

**Unchanged, and they check the moves end to end:** `test_skill.gd:29-35` (each zombie slides its 0.35: the hit, `Character`, `Stagger` and `_slide()` together); `test_attack.gd:35-49` and `test_projectile.gd:133-145` (knocked back); `test_enemy_death.gd` (the killing hit doesn't knock back; a dead zombie can't be hit); `test_health_bar.gd` (both bars; `:46-52` fails if `Player._ready()` forgets `super()`); `test_hurtbox.gd` (finds the zombie's Hurtbox on the Enemies' layer); `test_player.gd`, `test_pause_menu.gd`, `test_skill_bar_hud.gd` (the player's Skills, Faction and Skill bar, through `skills`).

**New:**

| Test | File, ticket | What it proves | On `master` |
|---|---|---|---|
| `test_its_skills_stand_where_it_stands` | `test_player.gd`, 01 | Rule 4: the player moved to (3, 0, −2), each of its Skills is at (3, 0, −2). | Passes; it fails if `Skills` were a plain `Node` (the Skills would stay at the origin). |
| `test_its_skills_come_before_its_skill_bar` | `test_player.gd`, 01 | Rule 4: `Skills`' index is below `SkillBar`'s. | Fails: no `Skills` node. |
| `test_bar_finds_a_skill_by_its_node_name` | `test_player.gd`, 01 | Rule 12: with Fireball's title set to "Ball of fire", `bar 2 fireball` puts the `Fireball` node in slot 2. | Fails: "Unknown Skill". |
| `test_an_enemys_hurtbox_is_on_the_enemies_layer` | `test_character.gd`, 02 | Rule 2, and that `Enemy._ready()` calls `super()`: a ready zombie's Hurtbox is on `Faction.layer(ENEMIES)`. | Passes: a guard for the move. |
| `test_the_players_scene_sets_the_players_faction` | `test_character.gd`, 02 | Rule 2: `player.faction` is the player's. It fails if `player.tscn` lacks `faction = 0`. (It can't catch a missing `super()`: `test_health_bar.gd:46-52` catches that.) | Passes: a guard. |
| `test_a_skill_it_already_has_takes_its_characters_faction` | `test_character.gd`, 02 | Rule 2: a bare `Skill` added under a zombie's `Skills` node before the zombie enters the tree has the Enemies' Faction once it is ready. A zombie, because the player's Faction is also a Skill's default. | Fails if the hand-over loop in `Character._ready()` is deleted. |
| `test_a_skill_given_later_takes_its_characters_faction` | `test_character.gd`, 02 | Rules 2 and 3: a bare `Skill` given to a ready zombie with `add_skill()` sits under the zombie's `Skills` node and has the Enemies' Faction. A zombie, because the player's Faction is also a Skill's default. | Fails: no `add_skill()`; `add_child()` would leave the player's Faction. |
| `test_without_a_stagger_a_hit_doesnt_push` | `test_character.gd`, 03 | Rule 10: a zombie whose `Stagger` node is freed before it enters the tree, hit through `zombie.hurtbox.take_hit()` with a Snapshot of Damage 10, Knockback 0.35 and Stagger 0.05 (made as `test_enemy_death.gd:63` makes one), loses 10 Health and is where it stood 10 physics frames later. | Fails: no `Stagger` node, and the zombie slides. |
| `test_knockback_left_over_the_stagger` | `test_stagger.gd`, 03 | Moved, as above. | Passes as `Enemy.knockback_left`. |
| `test_a_whole_stagger_slides_exactly_its_knockback` | `test_stagger.gd`, 03 | Rule 8: not active before `start()`; `start(Vector3(0.35, 0, 0), 0.05)` stepped at 1/60 s until inactive slides (0.35, 0, 0) in all (sum of `next_velocity(delta) * delta`), and again at 1/45 s. | New class; today's slide is checked only end to end, by `test_skill.gd:29-35`. |
| `test_a_frozen_frame_moves_nothing` | `test_stagger.gd`, 03 | Rule 8: `next_velocity(0.0)` is zero and leaves it active; the slide after it still totals the knockback. | New class. |
| `test_another_hit_restarts_it` | `test_stagger.gd`, 03 | Rule 8: two frames into `start(Vector3(1, 0, 0), 0.5)`, `start(Vector3(0, 0, 0.35), 0.05)` slides (0, 0, 0.35) from there, the first knockback's rest dropped, and is over after 4 steps at 1/60 s: 0.05 s is three, and a rounding crumb leaves the clock a hair above 0 after the third. | New class. |
| `test_a_stagger_of_0_does_nothing` | `test_stagger.gd`, 03 | Rule 9: `start(Vector3(0.35, 0, 0), 0.0)` leaves it inactive, with a zero velocity; started at 0 during a running Stagger, the running one goes on along its own knockback. If open rule 1 goes to option c, this test says a Stagger of 0 lasts 0.02 s instead. | Today a 0 is raised to 0.02 s (`enemy.gd:64`). |

`tests/test_character.gd` starts with the doc comment "A Character: its Faction reaches its Hurtbox and its Skills, a Skill given later joins its Skills, and only a Character with a Stagger is staggered." `tests/test_stagger.gd` with "A Stagger slides its Character exactly its knockback, fastest at first; a frozen frame moves nothing; another hit restarts it; a Stagger of 0 does nothing."

## Checking by hand

The tools run the game scene, `res://scenes/game.tscn`, since step 5 (on a base without step 5, `res://scenes/sandbox.tscn`). "The base" below is the branch this one is stacked on.

1. `tools/check.sh` passes.
2. **The chase, frame for frame.** On the base and on this branch, `godot --headless --path . --script res://tools/simulate.gd -- res://scenes/game.tscn 6 "tp 16 7.5"`, each output saved to a file, then `diff` the two: no line differs. An Enemy's `_physics_process` now starts with `_slide()`, which returns at once when nothing hits it. If two runs of the base already differ, compare to within 0.05 instead.
3. **A swing from where the player stands.** On both, `godot --path . --resolution 1280x720 --script res://tools/screenshot.gd -- res://scenes/game.tscn "tp 19 4" "activate 1 1 0"`. In `2_activate-1-1-0.png` the swing's white wedge lies at the player, toward the zombie standing at (20, 4), which shows the hit. The two pictures match.
4. **Play (F5).** Swing at a zombie: it flashes, squashes, slides back and walks back. Kill one with five swings: it sinks where it stood. `modifier pierce on`, then a Fireball through the pack: it passes one zombie and stops at the second. Esc › Skill bar › a slot: the drawer lists Attack and Fireball. `bar 2 fireball` puts Fireball in slot 2. `damage 10` shows the player's Health bar.

## Docs this reopens

**`GLOSSARY.md`**, committed with this spec on the branch (ticket 01's first commit):

- **Character** (`:11-13`). Today: "Anything that moves through the world as a Standee and has a Faction: the player's hero and the Enemies." Becomes:

  > **Character**:
  > Anything that moves through the world as a Standee and has a Faction: the player's hero and the Enemies. It has its Skills, and the Modifiers that change them.
  > _Avoid_: Actor, entity, unit

  Modifiers are now every Character's, and the plan already speaks of "a Character's list of Modifiers" (decision 2).

- **Stagger** (`:131-133`). Today: "The short time after a hit when an Enemy slides with the knockback and does not chase. Another hit restarts it." It no longer says what the code does: the Stagger is a Character's component, and a Stagger of 0 has a rule. Becomes:

  > **Stagger**:
  > The short time after a hit when a Character slides with the knockback and doesn't walk. Another hit restarts it, but a hit whose Stagger is 0 doesn't stagger at all. The player, for now, isn't staggered.
  > _Avoid_: Stun, hitstun, flinch

  The middle sentence follows open rule 1: under option c it goes, under option b it reads "a hit whose Stagger is 0 pushes at once, without a hold". "For now" mirrors Health's entry: whether the player is staggered is decided with the first Enemy Skill.

- **Skill** and **Faction** still say what the code does after this step. Skill changes in step 7, when a Skill knows its Character and an Enemy's Skill is first activated.

**`docs/agents/godot-conventions.md`**, "Composition": a new paragraph after the first one (find it by its text; other steps add lines elsewhere in this file):

> The base scripts are `Character` (`characters/character.gd`, the glossary's Character in code) and `Skill` (`Attack` and `Fireball` extend it). A base script is right when it is one level deep, stands for a glossary term that covers what extends it (Character for the player's hero and Enemies, Skill for Attack and Fireball), and holds identity and wiring, while behaviour stays in components and in the scripts that extend it. Anything else is a component. `Player` and `Enemy` extend `Character` and nothing extends them: an Enemy kind is a scene, not a script. A script that extends a base script and defines a function the base script also defines calls `super()` in it, unless it means to replace what the base does: in Godot 4 the subclass's function replaces the base's. `_ready()` is the example: `Player._ready()` and `Enemy._ready()` start with `super()`. A Character's Skills sit under its `Skills` node, a `Node3D` without a transform of its own, ahead of `SkillBar` in the scene so that a Skill's Cooldown runs before the Skill bar asks whether it is ready.

**`.scratch/factions-health/spec.md`:**

- Requirement 1 (`:19`), the sentence "Each Character has `@export var faction: Faction.Id`, defaulting to its own Faction (the player `PLAYER`, an Enemy `ENEMIES`); a scene changes it only to put a Character on another Faction." becomes: "Each Character has `@export var faction: Faction.Id`, one export on `Character` (`characters/character.gd`, since `.scratch/character/spec.md`), defaulting to the Enemies' (`ENEMIES`); `player.tscn` sets the player's (`faction = 0`), and otherwise a scene changes it only to put a Character on another Faction."
- Requirement 7 (`:29`) becomes: "**The Character wires its components** in `_ready` (`characters/character.gd`, since `.scratch/character/spec.md`): Hurtbox `hit_taken` → `health.damage(snapshot.number(Skill.DAMAGE))`, then its Stagger, if it has one, started with the Snapshot's Knockback and Stagger, then flash and squash as now. The Enemy connects `died` → the death below."
- Requirement 2 stays true in this step; step 7 rewrites it.

**`.scratch/combat/spec.md:104`** becomes: "**The Player answers "which Skills do I have".** `player.skills` is every Skill under its `Skills` node (`Character`'s property, since `.scratch/character/spec.md`), and `player.skill_bar` is its Skill bar. The pause screen and the touch slot button each point at the Player only. Adding a Skill means adding a node under the `Skills` node in `player.tscn`, or `add_skill()` in code. It will likely change once Skills are unlocked."

**`.scratch/skill-tags/spec.md:46`** becomes: "**Player** (`characters/player/player.gd`): answers `activation_requested` with its Character's `modifiers` (on `Character` since `.scratch/character/spec.md`): works out the aim when the press had none, calls `skill.try_activate(aim, modifiers)`, and on success turns to the aim, squashes, and emits `skill_activated(slot)`."

**`.scratch/content-checks/spec.md`**, two rows of the table under "Saved content today" (`:194-195`): `Player.faction`, `Player.modifiers` | `player.tscn` and `Enemy.faction`, `reach_distance`, `resume_distance` | `zombie.tscn` become `Character.faction` | `zombie.tscn` (`player.tscn` sets it since `.scratch/character/spec.md`); `Character.modifiers` | `player.tscn`, `zombie.tscn`; `Enemy.reach_distance`, `resume_distance` | `zombie.tscn`.

**Not reopened:** `.scratch/enemies/spec.md`. Requirement 5 ("a `CharacterBody3D`") stays true through `Character`. Its decision "No inherited enemy base scene" is about scenes, and this step adds a script; step 8 reopens it (plan.md decision 3). No ADR is touched.

## Seams

Lines this step touches in files other steps touch, and what later steps find:

- **`characters/character.gd`**, new here. Step 7 changes the two `skill.faction = faction` lines (`_ready`, `add_skill()`) to `skill.character = self`, and `add_skill()`'s doc. **Step 9 (`hit`)** finds the one place a hit lands on a Character: `Character._on_hit_taken(direction: Vector3, snapshot: Snapshot)`, connected in `Character._ready()` to `hurtbox.hit_taken`. It changes that method's parameters to the Hit and reads `hit.snapshot` where it reads `snapshot`; the flash and squash stay there for every Character hit, and decision 7 (which hits freeze and shake) stays where the impact plays. A dead Enemy's Hurtbox still leaves its layer in `Enemy._die()`, which is what `Hurtbox.take_hit()` reads.
- **`characters/enemy/enemy.gd`**: no other step in the plan touches it; the hit's receiver is `Character`'s now. Step 8 builds `enemy.tscn` with the nodes the two scripts look up: `Standee`, `Movement`, `NavigationAgent3D`, `Aggro`, `Hurtbox`, `Stagger`, `Health`, `HealthBar`, `Skills`.
- **`characters/player/player.gd`**: no other step touches it (step 3 says so for itself).
- **`characters/player/player.tscn`, `characters/enemy/zombie.tscn`**: step 5's `game.tscn` and `sandbox.tscn` name them by path and uid and set nothing inside them. Step 8 rebuilds `zombie.tscn` as an inherited scene.
- **Tests:** `test_skill_bar_hud.gd:24` is this step's (step 3 appends tests at the end of the file and leaves `:24` to this step; `:36` reads `player.skills`, which keeps its name). `test_projectile.gd` and `test_skill.gd` aren't touched here.
- **`docs/agents/godot-conventions.md`**: a paragraph in "Composition". Step 2 edits `:37` and adds "Saved content"; step 3 the touch paragraph and "Input and UI"; step 5 "Levels and navigation" and the tools paragraph; step 7 adds to "Tests and checks". No line in common.
- **`GLOSSARY.md`**: Character and Stagger. Step 2 adds Projectile speed, step 5 Level, step 7 changes Skill, step 9 adds Hit.
- **Other specs:** factions-health requirements 1 and 7 (step 7 takes requirement 2, step 9 rule 3 and requirements 3-4); `combat/spec.md:104` (steps 9 and 10 reopen other lines); `skill-tags/spec.md:46` (step 2 edits `:49` and `:65`, step 7 `:44`); content-checks' table (step 2's own spec).
- **Step 7** relies on: `class_name Character` with `faction`; `add_skill()`; every Character scene's `Skills` node; the player's own Attack and Fireball at `Skills/Attack` and `Skills/Fireball` for tests to use.

## Open rules for the developer

1. **What does a Stagger of 0 mean?** (The analysis's brief B3, part 1; the plan's working answer is a.)
   - **a. Nothing happens** (recommended, and written above): no hold and no slide, even with knockback, and a Stagger already running goes on as it was.
   - **b. An instant push** by the knockback, with no hold.
   - **c. Today's shortest slide**, 0.02 s: two frames of sliding, and the Character stopped dead at the end.

   *In play:* a burn ticking every 0.25 s with Stagger 0. Under c, a burning zombie is held two frames per tick and accelerates again from rest, so it loses about 0.06 s of chase a tick, a quarter of its chase: it limps. Under a and b (with no knockback), it chases at full speed. A slam (Stagger 0.5) and then, 0.1 s later, a burn tick: under a, the slam's slide runs its 0.5 s; under b, the tick's push replaces what is left of the slam's; under c, the zombie walks again at 0.12 s. A Skill that pushes with Stagger 0: under a, no push; under b, a jump of the whole knockback in one frame; under c, a two-frame slide. *Why a:* a Stagger is the time a Character "slides with the knockback", so no Stagger is no slide; a Skill that should push without holding gets a short Stagger instead. A burn isn't a hit today; this answer is ready for the day one is. *What each touches:* `Stagger.start()`, `test_a_stagger_of_0_does_nothing` and the Stagger glossary entry, nothing else.
2. **Which Faction is a Character's by default?**
   - **a. The Enemies'** (recommended): `player.tscn` sets `faction = 0`; the zombie, and every Enemy kind, sets nothing.
   - **b. The player's** (the enum's first value): `zombie.tscn` sets `faction = 1` instead, and factions-health requirement 1 says so.

   *In play:* nothing either way. *For the next kinds:* there will be many Enemy kinds and one player. Under a, a kind that forgets the line fights for the Enemies, as an Enemy should; under b, it fights for the player and its Skills would hit Enemies. Step 8's `enemy.tscn` could set it once either way, but a Character made from scratch, or a pet scene, still starts from the default.

Settled by the plan or the brief, not open: one level of inheritance and no base scene in this step; the `Skills` node is a `Node3D` ahead of the Skill bar; the player gets no Hurtbox and no Stagger; a hit during a Stagger restarts it; `bar` matches node names; death stays a list in `Enemy._die()`.

## Out of scope

| What | Trigger that brings it back |
|---|---|
| The player's Hurtbox and Stagger; what a hit does to the player; the player at 0 Health (the analysis's B2, B4) | The first Enemy Skill. A Stagger in `player.tscn` then also needs `_slide()` moved up from `Enemy` to `Character` and `if _slide(delta): return` in `Player._physics_process`. |
| Whether a staggered Character can activate Skills (B3, part 3) | The first Enemy Skill |
| A hit during a Stagger: the later end wins, instead of a restart (B3, part 2) | The first Skill whose Stagger is several times another's |
| A slide with no knockback still calls `move_and_slide()` each frame, which pushes the Character out of whatever presses on it: the shove the enemies spec stops for a standing Enemy | The first Skill or Modifier whose Knockback can be 0 while its Stagger isn't. Then `_slide()` skips `move_and_slide()` for a zero velocity. |
| Death through `process_mode` instead of the list in `Enemy._die()`. It needs three things: the Standee its own process mode, or the sink's tween freezes with its parent; perhaps a deferred switch, since a death inside a physics callback (a ball's `area_entered`) may not be allowed to take a body out of the space, which leaves the dead Character hittable to the end of the frame; and the Hurtbox's own "can't be hit" answer anyway | The first component on every Enemy that runs its own processing and must stop at death, such as a burn on its own timer |
| A dead Enemy's Aggro keeps watching | Pack Aggro |
| Facing on `Character` | The first Skill that reads its Character's Facing |
| The Enemy's chasing as its own node, beside `enemy.gd` | The first Enemy Skill, or a second Enemy kind before it (B5) |
| The Console commands and the proof Modifiers in a child node of the Player | The next command added to the Player |
| A `died` signal on `Character`; a Stagger `started` signal | Something that must react to them that can't connect to `health.died`: activations that take time, a hit pose |
| `character.tscn` above `player.tscn` and `enemy.tscn` | A third sort of Character that isn't an Enemy kind, such as a pet |
| Aggro by hostile Hurtboxes, and body layers that follow `faction`; a `faction` setter | Pets, a third Faction, or charm |
| A `max_health` setter; `Movement.speed` kept in step with the agent's `max_speed` | Gear or an effect that changes maximum Health or speed in play |
| Tests that read tuning numbers from the scenes | The first tuning change to the zombie or a Skill |
| Size classes, one navmesh each | The first Enemy kind of another size |
| The analysis's `ponytail:` comments on per-frame Standee updates, repathing and idle Enemies | A profile on the phone; they say nothing about where a Character's parts live |

## Where this departs from the analysis

- `_movement` stays in `Player` and `Enemy`: `Character` doesn't use it.
- `knockback_left` keeps its name; the analysis renamed it `slide_left`.
- A Stagger of 0 does nothing (the plan's working answer), where the analysis pinned 0.02 s. The case of a 0 arriving during a running Stagger is new here.
- The analysis's test "the player's Skills carry the player's Faction, which fails if `Player._ready()` forgets it" can't fail that way: `Skill.faction` already defaults to the player's. It guards `faction = 0` instead, and the hand-over and `add_skill()` are tested on a zombie.
- That the `Skills` node passes its position on is a test (`test_its_skills_stand_where_it_stands`), not a run.
- `test_aim_modes.gd:32` doesn't pass "only because the enum's first value is PLAYER": its test Skill never asks for a hostile mask. It moves to `add_skill()` all the same.
- Not here: Health's guard (step 1), the `ponytail:` comments, `standee.gd`.
- The branch is stacked on step 5, and the checks run `game.tscn`.

## Changed in review

The slide was built in `Character` and moved to `Enemy` in code review, because `Character` is wiring and identity only, only the Enemy slides, and walking is already each script's own; if the player is ever staggered, it moves up then.

## Engine facts

Godot 4.7 class reference and manual, read on 2026-11-22, and the 4.7-stable source where marked.

1. **A subclass's `_ready()` replaces its parent script's.** GDScript reference: "functions in extending classes replace functions with the same name in their super classes … If you still want to call them, you can use `super`". `Object._notification`: "Unlike other virtual methods, this method is called automatically for every script that overrides it." The reference doesn't name `_ready` here; `test_health_bar.gd:46-52` and `test_character.gd` fail when a `super()` is missing.
2. **Every script level's `@onready` variables are set before any `_ready()` body runs**, so `Player._ready()` can call `super()` and `Character._ready()` finds `health`. Not in the reference; every test that instances a Character runs through it.
3. **A script can't declare a member its parent script declares.** Not in the reference; the GDScript analyzer refuses it, and `tools/check.sh` fails at load.
4. **A `Node3D`'s transform is "in parent space (relative to the parent node)"** (`Node3D.transform`), and `get_parent_node_3d()` "Returns the parent Node3D that directly affects this node's global_transform. Returns null if no parent exists, the parent is not a Node3D, or top_level is true." So under a plain `Node`, nothing above moves a Skill. The reference doesn't spell out that a plain `Node` cuts the chain; `test_its_skills_stand_where_it_stands` checks the `Node3D` case.
5. **Equal priorities run in tree order.** `Node._physics_process`: "Processing happens in order of process_physics_priority, lower priority values are called first. Nodes with the same priority are processed in tree order, or top to bottom as seen in the editor (also known as pre-order traversal)."
6. **GUT 9.7.1 fails a test on an unexpected engine error or `push_error`** (`failure_error_types`, default `["engine", "gut", "push_error"]`, `addons/gut/gut_config.gd:57`); `assert_engine_error()` and `assert_push_error()` take one as expected. `Console.register()` asserts when a second node registers a taken command (`console.gd:62`), so two Players in one test fail it (`test_console.gd:76`).

## Done when

- [ ] `characters/character.gd` holds the Faction, the Modifiers, the Skills (`skills`, `add_skill()`), the Health bar line, the Hurtbox's layer, the hit; `characters/stagger/stagger.gd` holds the slide's clock and speed, and `Enemy._slide()` moves the body with them.
- [ ] `enemy.gd` has no Faction, no hit and no Stagger fields, and `_slide()` is its own; `player.gd` has no Faction, Modifiers, Skills list, Health lookups or Health line. Both `_ready()`s start with `super()`.
- [ ] Both scenes have a `Skills` `Node3D`; the player's Attack and Fireball sit under it, ahead of `SkillBar`, with their `unique_id`s; the zombie has a Stagger; `player.tscn` sets `faction = 0`.
- [ ] Every existing test passes, changed only as listed under Tests; the new tests pass; `tools/check.sh` passes.
- [ ] The docs above say what the code does; a search for `Enemy.knockback_left`, `_stagger_left` and `get_node("Fireball")` / `get_node("Attack")` in code and tests comes back clean.
- [ ] The editor's resave is one commit, and "Checking by hand" matches the base.

## Tickets

1. `issues/01-skills-node.md`: each Character scene gets a `Skills` node; `bar` finds Skills by node name.
2. `issues/02-character-script.md`: `Character` with the Faction, Modifiers, Skills and Health bar; `Player` and `Enemy` extend it.
3. `issues/03-stagger-and-the-hit.md`: the `Stagger` component, and the hit lands in `Character`.
4. `issues/04-reopened-docs.md`: the conventions and the other specs.
5. `issues/05-resave-check-and-pr.md`: the developer's resave, the checks by hand, `/code-review` and the PR.
