# Character and Enemy structure: findings checked, decisions, work packages

Analyst for Character and Enemy structure. `master` at `8797660`, 2026-11-22. Read only: nothing was run (no Godot, no `tools/check.sh`). Line numbers are those of `8797660`. Engine behaviour was checked against the Godot 4.7 class reference, and against the engine source where the reference says nothing; each claim says which (sources at the end). "Needs a run" marks what only running can settle, and says what to run.

**Scope.** `characters/` (Player, Controls, Enemy, the zombie, Faction, Movement, Health, Health bar, the Hurtbox scene, Aggro, Standee), how `scenes/sandbox.tscn` places Characters, their tests and their specs. The other analysts own the hit pipeline (what a hit carries, how a Skill refers to its Character, the Hurtbox's own "can be hit" state, Hit feedback, Aim, activations that take time), the rules engine and content data, and the UI and game root. Every place my packages meet theirs is listed under "Seams".

Words: glossary terms as in `GLOSSARY.md`. Not in the glossary: **Behaviour** *(proposed)*, **size class** *(proposed)*. Engine words (base scene, inherited scene, node) are used as Godot uses them.

## In short

- **Character has no home (Fable 1, Sol S1): confirmed, every row of Fable's table.** Do it now, before the first Enemy Skill. Two corrections to Fable's sketch: the `Skills` node must be a `Node3D`, not a plain `Node` (Skills read their own `global_position`); and `Character.died` adds nothing over `health.died`. Facing stays on Player for now (Sol's side).
- **Scenes: one inherited base for Enemy kinds, now; no `character.tscn` above it.** This sides with Fable on `enemy.tscn` (against Sol's "wait for a second kind") and against both on `character.tscn`. Adding an Enemy base later means rebuilding every kind made in the meantime. Adding a Character base later means rebuilding two scenes (`player.tscn`, `enemy.tscn`), however many kinds exist. Brief B1.
- **Stagger: an optional component** with `start(push, seconds)`, `is_active()` and `next_velocity(delta)`. A Character without one is never staggered. Extracting it keeps today's behaviour and forces no rule now. The first Enemy Skill forces two rules (is the player staggered; can a staggered Enemy activate Skills). The first Stagger of 0 forces a third. Briefs B2, B3.
- **Death: keep the hand-kept list in `Enemy._die()`.** Fable's `process_mode` route checks out against the class reference, but it brings three conditions with it: the Standee needs its own process mode, the switch may have to be deferred inside physics callbacks, and the Hurtbox still needs its own guard. Until the player can be hit, the player's death needs nothing from shared code beyond `Health`. After that, it needs a rule (brief B4).
- **Behaviour split (Fable 5, Sol S3): the claims hold, one is overstated.** Reach is measured between centres; Range counts the target's body. Do the split with the first Enemy Skill. Its activation half would be guessing today (no Skill exists, and R1 and R2 are open). Its movement half is knowable now. Brief B5.
- **Missed by both reports.** Enemy kinds can't differ in body size: the navmesh is baked for one agent radius (brief B6). Tests assert the zombie's tuned numbers. `Health.heal()` with a negative amount reaches 0 without dying. `Movement.speed` reaches the agent's `max_speed` only once. A Character's body layer doesn't follow its `faction`.

---

## 1. Character has no home in code (Fable 1, Sol S1)

### Verify

Fable's table, row by row:

| A Character's part | Fable's evidence | Checked |
|---|---|---|
| `faction` export | `player.gd:46`, `enemy.gd:11` | Yes. Each script declares its own, with its own default. |
| Health wired to the Health bar | `player.gd:78`, `enemy.gd:39` | Yes. The same line in both. |
| Skills, and handing them the Faction | `player.gd:36-42`, `79-80`; Enemy none | Yes. The `skills` getter scans children for `is Skill`. The hand-down runs once, in `_ready`. |
| Modifiers | `player.gd:50`; Enemy none | Yes. |
| Facing | `player.gd:28`; Enemy only `_standee.face()` | Yes. The Enemy faces its velocity or its target (`enemy.gd:103`, `106`). |
| Hurtbox on its Faction's layer | Player none; `enemy.gd:37-38` | Yes. `player.tscn` has no Hurtbox node. |
| Taking a hit: Damage, knockback slide, Stagger, flash, squash | Player none; `enemy.gd:61-69`, `125-137` | Yes. Also the fields at `:21-23`, the curve at `:54-55` and the check at `:73-75`. |
| Dying | Player none; `enemy.gd:112-120` | Yes. |

The other shared pieces Fable lists also check out. The capsule (radius 0.25, height 1.0) is written three times: `player.tscn:15-17`, `zombie.tscn:12-14`, `hurtbox.tscn:5-7`. The Health bar sits at y 1.1 in both scenes (`player.tscn:87`, `zombie.tscn:52`). Both bodies use `motion_mode = 1` and `safe_margin = 0.02` (`player.tscn:40-41`, `zombie.tscn:19-20`).

Sol S1's list (only the Player has Skills and Modifiers; only the Enemy takes hits and Stagger; both repeat Faction, Movement, Standee, Health, Health bar, body shape, motion mode and wiring) checks out too.

Not in either table: the **body layers** are part of every Character too, and each scene sets them by hand. The player is on `player` with mask world+enemy (`player.tscn:38-39`). The zombie is on `enemy` with mask world+player+enemy (`zombie.tscn:17-18`). They decide who blocks whom and what Aggro notices, and they don't follow `faction` (section 9).

**Corrections to Fable's sketch**

1. **"A plain `Skills` node" has to be a `Node3D`.** Skills are `Node3D`s that query the world from their own position: `Hurtbox.around(get_world_3d(), global_position, ...)` (`attack.gd:43-44`), and the ball's start point (`fireball.gd:39`). A `Node3D` whose parent isn't a `Node3D` inherits no transform: `get_parent_node_3d()` "Returns null if no parent exists, the parent is not a Node3D, or top_level is true" (Node3D, 4.7). Under a plain `Node`, the Attack would swing around the world origin.
2. **`skills()` as a function** renames a property that `pause_menu.gd:126` and four tests read. Keep the `skills` property.
3. **`signal died` on Character**, re-emitted from Health, has no listener. `character.health.died` is already public. Leave it out.
4. **Facing on Character:** wait, as Sol says. Today only the player's code reads Facing (`player.gd:95-104`, `150-151`, `160`, `186`). Move it on the day a Skill reads its Character's Facing, which is an Aim question for the hit-pipeline analyst. It costs one line then, in `enemy.gd`, which every kind shares.

**Something the `Skills` node buys that neither report connected to it.** Sol S2 says a Skill added after `_ready` processes after the `SkillBar`, so its held repeat comes one physics frame late. That is true: physics callbacks run in tree order at equal priority, and `test_aim_modes.gd:32` adds a Skill after `SkillBar`. A `Skills` node placed ahead of `SkillBar` in `player.tscn` puts every Skill ahead of the bar, including Skills added later. That fixes the order through the tree, with no process priorities.

### Judge

**Do now.** Before the first Enemy Skill, which needs every row of the table on both sides. Both reports agree. If it waits, the halves get copied into each other's scripts.

### Shape

`characters/character.gd` *(sketch, not compiled)*:

```gdscript
class_name Character
extends CharacterBody3D
## A Character (see GLOSSARY.md): what the player's hero and every Enemy share. It holds its
## Faction, its Modifiers and its Skills, and wires its components: its Health shows on its
## Health bar, and a hit on its Hurtbox lowers its Health, flashes and squashes its Standee and
## starts its Stagger. Wiring and identity only: Player and Enemy decide where it walks and what
## it activates. Without a Hurtbox it can't be hit; without a Stagger it is never staggered.
## Its Faction moves its Hurtbox and its Skills; its body layers and Aggro are its scene's.
## A script that extends it and has _ready() calls super() first: in Godot 4 a subclass's
## _ready() replaces this one.

## Its Faction: its Hurtbox goes on that Faction's layer, and its Skills hit only Hurtboxes
## hostile to it. The Enemies', unless its scene says otherwise.
@export var faction := Faction.Id.ENEMIES
## Its Modifiers: every activation of its Skills is made with them.
@export var modifiers: Array[Modifier] = []

## The Skills it has: every Skill under its Skills node.
var skills: Array[Skill]:
	get:
		var found: Array[Skill] = []
		for child in $Skills.get_children():
			if child is Skill:
				found.append(child as Skill)
		return found

## How much more Damage it can take.
@onready var health: Health = $Health
## Shows its Health while it is below the maximum.
@onready var health_bar: HealthBar = $HealthBar
## The part of it that Skills hit, or null: then it can't be hit.
@onready var hurtbox: Hurtbox = get_node_or_null(^"Hurtbox")
@onready var _stagger: Stagger = get_node_or_null(^"Stagger")
@onready var _standee: Standee = $Standee
@onready var _movement: Movement = $Movement


func _ready() -> void:
	health.changed.connect(health_bar.show_health)
	if hurtbox:
		hurtbox.collision_layer = Faction.layer(faction)
		hurtbox.hit_taken.connect(_on_hit_taken)
	for skill in skills:
		skill.faction = faction # seam H2: becomes the Skill's reference to its Character


## Gives it `skill`, at any time, even before it enters the tree. Under its Skills node, so the
## Skill's Cooldown runs ahead of anything that activates it.
func add_skill(skill: Skill) -> void:
	$Skills.add_child(skill)
	skill.faction = faction # seam H2


## Slides with its Stagger if it is staggered, and says whether it did: a staggered Character
## doesn't walk that frame. A hitstop frame doesn't move it, and the slide ends at rest.
func _slide(delta: float) -> bool:
	if _stagger == null or not _stagger.is_active():
		return false
	velocity = _stagger.next_velocity(delta)
	if delta > 0.0:
		move_and_slide()
	if not _stagger.is_active():
		velocity = Vector3.ZERO
	return true


## Hit on its Hurtbox: the one place a hit lands on a Character. It loses the hit's Damage, is
## staggered by its Knockback and Stagger, and its Standee flashes and squashes.
func _on_hit_taken(direction: Vector3, snapshot: Snapshot) -> void: # seam H1: the hit's shape
	health.damage(snapshot.number(Skill.DAMAGE))
	if _stagger:
		_stagger.start(direction * snapshot.number(Skill.KNOCKBACK), snapshot.number(Skill.STAGGER))
	var feedback := HitFeedback.shared() # seam H4: which hits show Hit feedback
	_standee.flash(feedback.flash)
	_standee.squash(feedback.squash)
```

The killing hit still doesn't knock back. `damage()` emits `died`, `Enemy._die()` stops the body's physics (`enemy.gd:113`), and the Stagger started right after is never slid. That is the same order as today.

**What Player keeps** (`player.gd`, `extends Character`): Controls, the Skill bar and its wiring, choosing the Aim, Auto-aim, the Aim marker, the hover ring, the Facing arrow, `facing`, `skill_activated`, the commands (section 6). It loses `faction` (`:46`), `modifiers` (`:50`), the `skills` getter (`:36-42`), the `health`, `health_bar`, `_movement` and `_standee` lookups (`:55-61`), the Health wiring (`:78`) and the Faction loop (`:79-80`). Its `_ready()` starts with `super()`. `player.tscn` stores `faction = 0` on its root, because the default is now the Enemies'.

**What Enemy keeps** (`enemy.gd`, `extends Character`): reach and resume, the target, chasing, the navigation agent, avoidance, `_on_velocity_computed`, `_die()`, `_flat()`. It loses `faction` (`:9-11`), the Stagger fields (`:21-23`), the lookups (`:26-32`), the Hurtbox and Health wiring (`:37-39`), `knockback_left` (`:51-55`), `_on_hit_taken` (`:58-69`) and `_slide` (`:123-137`). Its `_ready()` starts with `super()` and connects `health.died` to `_die` as now. Its `_physics_process` starts with `if _slide(delta): return`.

**Node trees after WP1 and WP2** (WP2 only if B1 picks option B):

```
player.tscn             Player: body layer `player`, mask world+enemy, faction 0
├─ CollisionShape3D     capsule 0.25 × 1.0
├─ Standee              adventurer frames
├─ Movement
├─ Health               100
├─ Controls
├─ FacingArrow
├─ Skills (Node3D)      new: ahead of SkillBar
│  ├─ Attack
│  └─ Fireball
├─ SkillBar             main_skill = ../Skills/Attack
├─ AimMarker
├─ HoverRing
└─ HealthBar            y 1.1
                        no Hurtbox and no Stagger until the first Enemy Skill (B2, B4)

enemy.tscn              Enemy: body layer `enemy`, mask world+player+enemy. The base; never placed.
├─ CollisionShape3D
├─ Standee              no frames: each kind sets its own
├─ Movement
├─ NavigationAgent3D
├─ Aggro
├─ Hurtbox
├─ Stagger              new
├─ Health
├─ HealthBar            y 1.1
└─ Skills (Node3D)      new, empty

zombie.tscn             inherits enemy.tscn. Overrides: Standee frames, Movement speed 2.5,
                        Health 50. Later: its Behaviour node, and its Skills under Skills.
```

Without WP2, `zombie.tscn` stays a complete scene and gains the `Stagger` and `Skills` nodes.

**Tests.**
- New `tests/test_stagger.gd`. It takes over `test_knockback_left_over_the_stagger` (`test_enemy.gd:34-37`) as `Stagger.slide_left`. It adds four cases. A 3-frame Stagger slides exactly its push in all. A frame with delta 0 moves nothing and doesn't run the clock. A second `start()` restarts it with the new push and time. It isn't active before `start()`. One more case pins the 0.02 s floor until B3 settles it.
- New `tests/test_character.gd`, three tests. A zombie's Hurtbox is on the Enemies' layer once ready, which fails if `Enemy._ready()` forgets `super()`. The player's Skills carry the player's Faction, which fails if `Player._ready()` forgets it. A Skill given with `add_skill()` after ready carries the Faction and sits ahead of the `SkillBar`.
- Path changes only: `test_player.gd:132` (`"Fireball"` becomes `"Skills/Fireball"`), `:252`, `:263` (`"Skills/Attack"`); `test_pause_menu.gd:60`; `test_skill_bar_hud.gd:24`; `test_aim_modes.gd:32` (`player.add_child(skill)` becomes `player.add_skill(skill)`).
- Unchanged, and they test the moved hit reaction from end to end: `test_skill.gd:29-35` (each zombie slides its 0.35), `test_attack.gd:48-49`, `test_enemy_death.gd`, `test_health_bar.gd`, `test_projectile.gd`. The reach tests in `test_enemy.gd:15-28` stay until WP4.

**Docs it reopens.**
- `.scratch/factions-health/spec.md`. Requirement 1 says each Character's export defaults to its own Faction; there is now one export, on Character, defaulting to the Enemies', and the player's scene sets its own. Requirements 2 and 7 say "The Enemy wires its components"; the Character does now.
- `.scratch/combat/spec.md`, decision "The Player answers 'which Skills do I have' … Adding a Skill means adding a node to `player.tscn`." It becomes a node under the Player's `Skills` node.
- `docs/agents/godot-conventions.md` gains two lines: "a script extending a script that has `_ready()` calls `super()` first", and "a Character's Skills sit under its `Skills` node, a `Node3D`".
- `GLOSSARY.md`: no change in WP1. Stagger keeps "an Enemy" until B2 is settled.

---

## 2. How a Character scene is assembled (the reports disagree)

Fable: `character.tscn`, inherited by `enemy.tscn`, inherited by each kind; the player optional. Sol: a thin `Character` script and a shared scene, but no `enemy.tscn` until a second kind shows what Enemies share. The conventions say: "reach for a new component before an inheritance chain."

Neither report makes this point: **the structure every Enemy kind needs is already fixed, by what `enemy.gd` looks up** (`$Hurtbox`, `$Health`, `$HealthBar`, `$Movement`, `$Standee`, `$NavigationAgent3D`, `$Aggro`). A kind without one of these crashes in `_ready`. So a base scene holding exactly those nodes is not a guess about what kinds share. What a second kind would show is which *values* are the kind's (frames, numbers, Behaviour, Skills), and an inherited scene overrides values anyway.

### The options at 30 Enemy kinds

| | A. Script base, every scene composed by hand | B. Script base + `enemy.tscn` that kinds inherit (player by hand) | C. Fable: `character.tscn` → `enemy.tscn` → kind | D. A shared "parts" scene instanced under each root | E. One Enemy scene + a data Resource per kind |
|---|---|---|---|---|---|
| The 31st kind | Duplicate a kind (about 13 nodes), change about 4 values. Copies drift. | New Inherited Scene, about 4 overrides, add its Behaviour and Skills | As B | Body + shape + parts instance, then per-kind values through Editable Children or forwarding exports | One `.tres` (and its Behaviour and Skills as PackedScenes) |
| Add a component to every Enemy (say a burn) | 30 scene edits | 1 edit | 1 edit | 1 edit | 1 edit + code to apply it |
| Change a shared value (Health bar height) | 30 edits | 1 | 1 (at the right level) | 1 | 1 |
| A kind without a shared part (a turret without Movement) | Delete the node | Can't delete an inherited node, so the base holds only what every kind needs | As B, at two levels | Can't delete inside the instance | A data flag |
| Reading one kind's file | Complete | Only its overrides; read it next to the base | Overrides across two bases | Complete but nested | Data only |
| Editor hazards (below) | The usual | Base edits in the editor only; don't hand-write inherited scenes | Doubled | Editable Children overrides are fragile | Few |
| Checked by a test | Every kind has the nodes Enemy needs | Every kind inherits `enemy.tscn` (`SceneState.get_base_scene_state()`) | As B | — | Resource validation |
| Undo later | Becoming B means rebuilding every kind | Per kind: clear the inheritance (the Scene dock's "Clear Inheritance"; unverified in 4.7) | As B | — | — |

**How inherited scenes behave in the editor.** This matters for B and C.
- A kind is made with Scene › New Inherited Scene. It can add nodes and override base properties; each override gets a revert arrow back to the base value. It can't delete or reorder base nodes. The 4.2 import docs state this for imported scenes ("Nodes from the base scene can't be removed … Subresources can't be edited"). For a `.tscn` base, treat it as unverified until checked in the editor.
- A base value reaches every kind that hasn't overridden it. An accidental override in one kind (a stray drag in the inspector) silently stops that kind following the base.
- Base node names become a contract. Renaming or moving a node in the base orphans every kind's overrides on it.
- Shared sub-resources belong to the base. A kind that needs a different capsule assigns its own shape resource rather than editing the base's. Needs an editor check: whether 4.7 lets a kind edit a base sub-resource in place, and where that edit is saved.
- **The open editor** (conventions, "The open editor"). If the base changes on disk while the editor holds the old copy, a save from the editor writes the old base back, and every kind inherits the damage. Rule: the developer edits the base in the editor, or reloads the project before touching any Enemy scene. An agent may write the plain base in text. Inherited scenes should come from the editor, because their file format (an `instance=` root, an override entry per base node) is easy to get wrong by hand. Needs an editor check: does saving `enemy.tscn` make the editor resave every kind (churn)?

**Tests.** All five options leave today's tests alone, because they instantiate `zombie.tscn`. A needs a test that every scene under `characters/enemy/` has the nodes Enemy looks up. B and C need a test that every scene there except `enemy.tscn` has `enemy.tscn` as its base. That test also stops a kind being made by copying.

**Why B and not C.** Adding B's base later means rebuilding every kind made by then. Adding C's top level (`character.tscn`) later means rebuilding only `player.tscn` and `enemy.tscn`: the kinds keep inheriting `enemy.tscn`, at any count. So B pays to have now and C can wait. And C costs something now: every kind sits two levels down, a value set in `enemy.tscn` hides a change made in `character.tscn`, and the player inherits whatever the base holds, which can't be deleted (a Stagger, if B2 says the player has none). Trigger for C: a third sort of Character that isn't an Enemy kind (a pet).

**Why not D.** A kind's own numbers (Health 50, speed 2.5, frames) live on nodes inside the instance. Each kind then needs Editable Children, or the parts root re-exports every tunable value. The body's `CollisionShape3D` must stay a direct child of the body anyway. It is inheritance by another route, with more wiring.

**Why not E.** A scene already holds a kind's data and is edited in the editor. That is the reason both reports give for not adding Skill definitions as Resources. Revisit E when Enemies are spawned by level and rarity. A rarity changes any kind at spawn, and that is a question about a Character's own numbers (R8), not a kind file.

**Pick.** B, built now, in the same editor session as WP1, which restructures `zombie.tscn` anyway. Brief B1 puts it to the developer.

---

## 3. Stagger as a component (Fable 1; Sol S1, S3, D8)

### Verify Sol D8 and today's rules

- **Zero becomes 0.02 s:** confirmed. `_stagger_time = maxf(snapshot.number(Skill.STAGGER), 0.02)` (`enemy.gd:64`), with the `ponytail:` comment at `:63`. At 60 physics frames a second, that is two frames of slide. During them the Enemy doesn't chase, and at the end its velocity is set to zero (`:136-137`), so it accelerates again from rest (60 u/s² to 2.5 u/s takes about 0.04 s). So a hit with Stagger 0 costs about 0.06 s of chase. Sol is right that "a Modifier cannot remove Stagger fully".
- **Found while checking:** with Knockback 0 the slide still calls `move_and_slide()` at zero velocity (`:135`). That pushes the Enemy out of whatever presses into it. It is exactly the shove the standing rule avoids (`:96-99`; enemies spec, "A standing Enemy skips `move_and_slide()`"). So a 0-Knockback hit can nudge a packed Enemy onto the player.
- **A hit during a Stagger replaces both its time and its push** (`:64-66`). A short Stagger cuts a long one short, and whatever is left of the first push is dropped. The glossary says "Another hit restarts it", which agrees.
- A staggered Enemy skips the navigation agent (`:123-124`), so avoidance doesn't bend the slide.

### The component's interface

`characters/stagger/stagger.gd` *(sketch)*. It is polled, as `Movement` is (`movement.gd:18`): the body asks it for this frame's velocity and moves itself.

```gdscript
class_name Stagger
extends Node
## A Character's Stagger (see GLOSSARY.md): the short time after a hit when it slides with the
## knockback and doesn't walk. Another hit restarts it. The Character asks it each physics frame
## whether it is staggered, and for this frame's share of the slide. A Character without one is
## never staggered.

var _left := 0.0 # seconds still to go
var _length := 0.0 # the whole Stagger, in seconds
var _push := Vector3.ZERO # direction on the ground times distance


## Staggers it for `seconds`, sliding `push` over that time, fastest at first.
func start(push: Vector3, seconds: float) -> void:
	# ponytail: a Stagger of 0 would need an instant push; the shortest slide stands in for it (B3).
	_length = maxf(seconds, 0.02)
	_left = _length
	_push = push


## Whether it is staggered now.
func is_active() -> bool:
	return _left > 0.0


## This frame's share of the slide as a velocity, with the clock run on by `delta`. Exactly the
## push in all, at any frame rate. Zero during a hitstop (delta 0).
func next_velocity(delta: float) -> Vector3:
	if delta == 0.0 or not is_active():
		return Vector3.ZERO
	var left_after := maxf(_left - delta, 0.0)
	var distance := _push.length()
	var step := slide_left(distance, _length, _left) - slide_left(distance, _length, left_after)
	_left = left_after
	return _push.normalized() * step / delta


## How much of a `distance`-long slide is still to go with `left` of `seconds` remaining: the
## speed falls linearly to zero, so the distance shrinks with the square of the time left.
static func slide_left(distance: float, seconds: float, left: float) -> float:
	return distance * (left / seconds) ** 2
```

- **No signals.** Nothing listens yet. Add `started` when something must react to a Stagger beginning: an activation in progress being cut short (R1), or a "hit" pose.
- **No process of its own.** The clock runs only when the body asks. So it stops when the body stops (death), and it adds no process-order question.
- **Optional on purpose.** "A Character without a Stagger is never staggered" puts the rule in the scene, the way "A Character without a Hurtbox can't be hit" already does in the glossary. Whether the player is staggered (B2) and whether a boss is become a node in a scene, not code.
- **Where the bodies use it.** `Character._slide(delta)` (section 1), called on the first line of `Enemy._physics_process`. The Player calls it only if B2 says the player is staggered.

### Which rules extracting it forces, and when

Extracting it forces **none of them now**. The extraction keeps today's behaviour, and the player gets no Stagger in WP1. Each rule comes due at its own trigger:

| Rule | Comes due at | Where it lives | Brief |
|---|---|---|---|
| Is the player staggered and knocked back? | The first Enemy Skill | `player.tscn` (a Stagger node or not), one line in `Player._physics_process` | B2 |
| Can a staggered Character activate its Skills? | The first Enemy Skill (for Enemies); B2 (for the player) | The Enemy's activation path, the Behaviour or the Character, and the hit pipeline's `can_activate()` | B3, part 3 |
| What a Stagger of 0 means | The first Skill or Modifier that reaches 0, or damage over time delivered as hits | `Stagger.start()` | B3, part 1 |
| A hit during a Stagger: restart, or the later end wins | The first Skill whose Stagger is several times another's | `Stagger.start()` | B3, part 2 |

Parts 1 and 2 live in one file, so deciding them late costs one file. That is why they don't block WP1.

---

## 4. Death

### Verify

`Enemy._die()` (`enemy.gd:112-120`) switches off, in order: its physics process (`:113`); the walk pose (`:114`); avoidance (`:115`); the body's layer (`:116`); the Hurtbox's layer (`:117`); the Health bar (`:118`). It then frees itself once the Standee has sunk (`:119-120`). It doesn't switch off Aggro. A dead Enemy keeps monitoring until it fires and can still take a target. That is harmless now, but wrong once pack Aggro exists (it is on the enemies spec's "Later" list).

### Fable's `process_mode` route, checked

- `PROCESS_MODE_DISABLED`: "Never processes. Completely disables processing, ignoring SceneTree.paused" (Node, 4.7). Children on the default `PROCESS_MODE_INHERIT` follow. **Confirmed.**
- `CollisionObject3D.disable_mode`, default `DISABLE_MODE_REMOVE`: "remove from the physics simulation to stop all physics interactions with this CollisionObject3D. Automatically re-added … when the Node is processed again" (4.7). This covers the body, the Hurtbox and the Aggro area. (`MAKE_STATIC` "Doesn't affect Area3D".) **Confirmed.**
- The sink: `Standee.sink()` runs a tween from `create_tween()`. A bound tween in the default `TWEEN_PAUSE_BOUND` "will process when that node can process" (Tween, 4.7). Under a disabled Character, the sink would freeze. **Fable is right**; the Standee would need `process_mode = PROCESS_MODE_PAUSABLE` set on itself. It then runs unless the game is paused, whatever its parent says.
- The avoidance agent: `NavigationAgent3D` has no case for `NOTIFICATION_DISABLED`. On `NOTIFICATION_PAUSED` it calls `agent_set_paused(rid, !parent.can_process())` (engine source). Disabling a node sends `NOTIFICATION_PAUSED` to every node whose ability to process changes (engine source, `node.cpp`, per the UI analyst's check). So the agent gets paused. **Needs a run:** do neighbours stop steering around a paused agent the way they do with `avoidance_enabled = false`? Run a pack in `tools/simulate.gd`, with one zombie killed by a test hook.
- **Not mentioned by Fable:** death usually happens inside a physics callback (a ball's `area_entered`, then the hit, then `died`). Godot refuses some physics-state changes during that report: `aggro.gd:47-49` defers `monitoring` for that reason. If taking a body or area out of the space is refused too, the switch must be `set_deferred(&"process_mode", …)`, and then the dead Enemy stays hittable until the end of the frame. Either way, `Hurtbox.take_hit` still needs its own "can be hit" answer. **Needs a run:** switch `_die()` to `process_mode`, then run `test_projectile.gd:172` (a ball kills a zombie inside `area_entered`) and watch for physics errors.

### What the player's death needs from shared code

Nothing yet. `Health` already gives the player what the glossary asks ("the player, for now, stays at 0"): it clamps at 0 (`health.gd:40`), emits `died` once (`:29-30`), and ignores healing afterwards (`:41`; checked by `test_player.gd:282`). So `Character` doesn't connect `died`; `Enemy` connects it to its own `_die()`, as at `enemy.gd:40`.

The gap opens when the player gets a Hurtbox (the first Enemy Skill). Damage at 0 does nothing, but every later hit still plays its Stagger (if B2 says so), flash, squash and Hit feedback, and Enemies keep swinging. That is brief B4. If B4 picks "can't be hit at 0", switching the Hurtbox off moves from `Enemy._die()` into `Character`. The Enemy keeps the sink, the body layer, avoidance and the Health bar.

### Judge

**Keep the list in `Enemy._die()`.** It is seven lines in one file, and it is correct. The `process_mode` route swaps them for three conditions (the Standee's own mode, perhaps a deferred switch, and the Hurtbox guard anyway) plus a run to check avoidance. Revisit at the first component on every Enemy that runs its own processing and must stop at death, such as a burn ticking on its own timer. Design to put that day off: components the Character polls (Movement, Stagger, a Behaviour) stop when the body stops, so the list doesn't grow.

---

## 5. `enemy.gd` is one behaviour, not "an Enemy" (Fable 5, Sol S3)

### Verify

- **"`reach_distance` (1.0) is unrelated to any Skill":** confirmed (`enemy.gd:14`; the zombie has no Skill). **Overstated: "or the swing misses".** The two numbers aren't measured the same way. Reach is the distance between centres (`enemy.gd:78`). Range "counts the Enemy's body" (combat spec, review decisions): `Hurtbox.around` finds any part of a Hurtbox within reach (`hurtbox.gd:46-62`). A zombie that stops 1.0 away would hit with a 1.6-Range swing. The real failures are elsewhere. A ranged Skill would walk into melee before using its Range. A Modifier that lowers Range can push it under the hand-kept reach. So "stop where the Skill reaches" means: centre distance up to Range plus the target's body radius (0.25), minus a margin. It does not mean reach equals Range.
- **"Nothing decides an Enemy's Aim or when it activates":** confirmed. Outside tests, only `player.gd:112` calls `try_activate`.
- Sol S3's list of what `enemy.gd` handles: confirmed.

### Interface, mirroring Controls

`Controls` answers "where to walk" and "where to aim" when asked, and signals slot presses up (`controls.gd:8-11`, `62-68`). A Behaviour *(proposed: "How the game tells an Enemy what to do: where to walk, what to face, and which Skill to activate at what Aim. Each Enemy kind has one. Avoid: AI, brain")* does the same for an Enemy:

```gdscript
class_name Chase # one Behaviour: today's, moved out of enemy.gd
extends Node
## Stands until its Aggro notices the player, then walks after them for good, standing once
## within reach. The Enemy asks it each physics frame where to walk and what to face, and
## connects its Aggro to notice(). It has no process of its own.

## (with the first Enemy Skill) It wants `skill` activated now, aimed at `aim`.
signal activation_requested(skill: Skill, aim: Vector3)

## Its Aggro noticed `target`.
func notice(target: Node3D) -> void: ...
## Where it wants to walk to, as a spot in the world, or Vector3.INF to stand.
func destination(from: Vector3) -> Vector3: ...
## Which way to face while standing, as a direction on the ground, or zero to keep the last.
func facing_while_standing(from: Vector3) -> Vector3: ...
```

**A destination, not Fable's `move_direction()`.** An Enemy walks a navmesh path, and the direction comes from the agent (`enemy.gd:80-81`). A Behaviour that returned a direction would have to own the agent, and the agent's avoidance answer (`velocity_computed`) must reach the body that moves. A destination keeps the agent, avoidance and `move_and_slide()` in the body. That gives "how a body the game drives moves" one home, as Fable wants. It also lets a ranged kind return a spot at its own distance, and a fleeing kind a spot away. The body sets the agent's target only while it has a destination, as today. That is also where the repath fix goes (section 8).

### Knowable now, and guessing now

- **Knowable:** the boundary above, and Aggro feeding the Behaviour through `notice()`. This is a refactor with no change in play. `should_chase` and its four tests move to `test_chase.gd`.
- **Guessing:** the activation half.
  - When to activate: an instant swing in Range, or a wind-up first (R1)?
  - What an Aim holds (R2).
  - Where to stop: which Skill sets it, and its Range "as it stands now" with the Character's Modifiers. A Behaviour can only read the Modifiers through whatever reference the hit-pipeline analyst gives Skills, or by having them handed down.

### Judge

**Split with the first Enemy Skill, as both reports say.** The split exists mainly to make the stopping distance follow a Skill's Range and to decide when to activate, and both need a Skill. Doing the movement half now would design a two-method interface around one user, with its second half unknown. **Exception:** if the developer wants a second Enemy kind before Enemy Skills, do the movement half first, because otherwise that kind forks `enemy.gd`. Brief B5.

---

## 6. `player.gd` carries the developer's tools (Fable 8)

- **Confirmed:** six commands registered at `player.gd:68-74`, their bodies at `:195-262`, and `PROOF_MODIFIERS` at `:20-24`. That is about 81 of 287 lines.
- **Confirmed:** `_cmd_bar` matches `skill.title` (`:211`). The Console splits on spaces (`console.gd:83`), so a two-word title can't be typed.
- **Confirmed, and harmless:** the proof Modifiers are `preload`ed in a `const`, so they load in release builds too, where `Console.register` does nothing (console-commands spec, requirement 7). They are two small `.tres` files.

**Judge.** By the yardstick this can wait: it stays in one file.
- **Match `bar` by node name now** (`String(skill.name).to_lower()`). The strings are the same as today ("attack", "fireball"), so `simulate.gd`, `screenshot.gd`, the conventions and `test_player.gd:131` keep working. It is one line and rides with WP1, which touches `skills`.
- **Moving the commands out is optional.** Do it when the next command lands on the Player (WP5). Shape: a `PlayerCommands` child node. "Console command" isn't a domain term, per the console-commands spec's requirement 9, so it needs no glossary entry. It registers its own methods in `_enter_tree`, so the Console drops them when it leaves. The Player hands it itself in `_ready()`, as a Character hands itself to its Skills (call down). Don't give it an export pointing at its parent: the conventions rule out a child reaching its parent. Command names stay the same (the UI analyst's seam C3). The conventions' example ("as … `Player` with `tp`") then names the new node.

---

## 7. Fable's "leave until needed" rows in this area

| Row | Checked | Judge |
|---|---|---|
| **Aggro looks for the `player` body layer while Skills look for hostile Hurtboxes** | Yes. `aggro.tscn:20` masks layer 2 (`player`); `aggro.gd:4-5`. Skills use `Faction.hostile_mask` (`skill.gd:141-143`). Also, the body layers themselves are hand-set per scene and don't follow `faction` (section 9). | **Leave.** Trigger: a pet, a third Faction, or an Enemy scene put on the player's Faction. The change then: Aggro masks `Faction.hostile_mask()` over Hurtbox layers (areas it monitors), with the Faction handed down by its Character as a Skill's is. `aggro.tscn` is one sub-scene, so every kind follows. The player getting a Hurtbox doesn't force it. |
| **A Character's Faction is handed down once** | Yes: `player.gd:79-80`, `enemy.gd:37`. Also, a Skill added after `_ready` misses it. `test_aim_modes.gd:32` passes only because the enum's first value is `PLAYER`. | The "Skill added later" part: **fixed in WP1** by `add_skill()`, and properly by the hit pipeline's reference from Skill to Character. The "Faction changes" part: **leave** until charm. Then a `faction` setter re-puts the Hurtbox on its layer (three lines in Character). |
| **`Health.max_health` has no setter** | Yes (`health.gd:13`). `current` is set from it once, at ready (`:16`). **Correction:** a rarity applied before the Enemy enters the tree works today, because the value is read at ready. Only a change during play misses the clamp and the `changed` signal. A trap nearby: before ready, `current` is 0, so `is_dead()` is true and `damage()` and `heal()` silently do nothing. | **Leave.** Trigger: gear or an effect that changes maximum Health during play (R8). |
| **`Health.current` is read only by comment** | Yes (`health.gd:15`). A search finds no write outside Health. | **Leave.** A getter-only property over a private field is three lines on the day something writes to it. |
| **Enemies are placed by hand** | Yes: `sandbox.tscn:125-144`, seven instances; enemies spec decision. | **Leave** (the UI and game root analyst's level split). WP2 doesn't change placement: the instances point at `zombie.tscn` by path (`sandbox.tscn:13`). |
| **The camera is a child of the Player** | Yes. It is a child of the *instance* in `sandbox.tscn:120-123`, not of `player.tscn`. Hit feedback shakes its offsets (`hit_feedback.gd:42-46`, `55-58`). | **Leave** (the UI analyst's). One note from this side: if B4 ever picks a respawn that frees the player's Character, the camera goes with it. The UI analyst prefers a respawn that resets the same Character, and so do I. |

---

## 8. Known ceilings and performance (Fable's list and Sol's, this area)

| Claim | Checked | Judge |
|---|---|---|
| **One material per Standee; texture and flash parameters set every frame** (Fable) | Yes. `standee.tscn:7` is `resource_local_to_scene`. `standee.gd:105` sets `tex` every frame (through `:155-156`), and `:127` sets `flash` every frame. Also a `QuadMesh` per Standee (`:49`) and card transform writes each frame (`:117-130`). The Health bar's cheaper pattern is real (`health_bar.gd:13`, an instance uniform). "The texture can't be per instance" is right: "Per-instance uniforms do not support textures or arrays" (4.7 shading reference); the documented route is a texture array with a per-instance index. | **Leave; measure 40 Enemies on the phone first.** The cheapest first step stays inside `standee.gd`: set a parameter only when it changes. Add a `ponytail:` comment now. |
| **32 texture samples per fragment** (Sol) | Yes, a loop of 16 directions × 2 radii (`standee.gdshader:26-29`). **Overstated as a cost.** The 3D view renders about 216-240 pixels tall (`pixelated_view.gd:9-12`, `34`), so there are few fragments. The CPU work per frame (row above) is what to measure. | **Leave.** |
| **A chasing Enemy sets its agent's target every physics frame** (Fable, Sol) | Yes (`enemy.gd:80`, inside `if _chasing`). Engine: `set_target_position` is "Intentionally not checking for equality … we want to update the path even if the target position is the same" and calls `_request_repath()` (engine source). The class reference: "If set, a new navigation path … is requested". That is one path query per chasing Enemy per physics frame. | **Leave until profiled** with 20-40 Enemies chasing. The fix lives in the body: set the target only when it moved more than a small distance. WP4 is the natural place. Add a `ponytail:` comment now. |
| **Dormant Enemies run physics and avoidance** (Sol) | Yes. `enemy.gd:72-91` runs for every Enemy. With no target the direction is zero, but the velocity still goes to the agent every frame (`:88-89`), and avoidance is on (`zombie.tscn:37`). The class reference: "Avoidance processing with many registered agents has a significant performance cost." | **Leave until profiled.** The cheapest fix: an Enemy with no target and no Stagger skips its physics process until Aggro fires; collision still makes it an obstacle. |

---

## 9. An "Enemy" on another Faction (the note in Fable 5)

Confirmed: `enemy.gd:9-11` lets a scene set the `faction` export, while the glossary defines an Enemy as "A Character of the Enemies' Faction". Here is what such a scene would get today. Its Hurtbox moves to the player's layer, so the player's Skills can't hit it and Enemies' Skills could. Its Skills (once it has any) would hit Enemies. But its body stays on the `enemy` layer (`zombie.tscn:17`), and its Aggro still hunts the player (`aggro.tscn:20`). It is half converted.

**Judge.** Leave until pets: the glossary's naming question and the physics question go together. A pet would be "a Character the game drives" of the player's Faction, which needs a word and a decision on its body layer and its Aggro. In the meantime, WP1 states the rule in the Character doc comment: "Its Faction moves its Hurtbox and its Skills; its body layers and Aggro are its scene's."

---

## 10. Missed by both reports

Each is held to the same yardstick: would fixing it later touch every Enemy scene, every Skill or every Modifier?

1. **Enemy kinds can't differ in body size.** The level's navmesh is baked for one agent: `agent_radius = 0.3`, `agent_height = 1.0` (`scenes/sandbox_navmesh.tres`). A bigger body is routed through gaps it doesn't fit and wedges; a smaller one can't use gaps it would fit. Size also sits in several hand-kept copies: the body capsule in each scene, the one Hurtbox capsule in `hurtbox.tscn` that every Character shares, the agent's radius, the Health bar height, and `Attack.POINT_BLANK` (`attack.gd:8`, "pressed against the player"). Content would hit this as soon as a kind is designed, so the developer should know before designing kinds. Brief B6.
2. **The `Skills` node must be a `Node3D`** (section 1). This is a fault in Fable's sketch that would put every Skill at the world origin.
3. **Tests assert the zombie's and the Skills' tuned numbers.** For example `test_attack.gd:70` ("50 less the Attack's Damage of 10"), `test_projectile.gd:169` and `:176`, `test_enemy_death.gd:31-36` ("five Attacks kill a zombie"), `test_health_bar.gd:38`, `test_skill.gd:34-35`. The first tuning pass on the zombie or the Attack breaks combat tests that aren't about tuning. **Trigger:** the first tuning change. **Fix:** read the numbers from the scenes (`zombie.health.max_health - attack.damage`), or give the tests their own target scene with fixed numbers.
4. **`Health.heal()` with a negative amount reaches 0 without dying.** `heal(-x)` clamps to 0 and emits `changed` but never `died` (`health.gd:34-35`, `39-44`). `is_dead()` is then true, so the Character ignores Damage forever: a zombie that stands at 0 and never sinks. `damage(-x)` heals. Sol's D3 traces negative Damage back to Modifiers (the rules engine's side). The Health side is a component invariant ("At 0 Health a Character dies, once", factions-health rule 5) that Health should keep whatever its caller sends. **Do now:** two lines (amounts of 0 or less do nothing, as a hit of 0 Damage already doesn't) and two tests, riding with WP1. Coordinate with the rules-engine analyst, who may floor Snapshot numbers too.
5. **`Movement.speed` reaches the agent's `max_speed` once** (`enemy.gd:43`). A slow or a haste during play changes Movement but not avoidance's cap, so a hasted Enemy stays capped at its old speed. **Trigger:** the first effect that changes a Character's speed in play (R8). The fix stays in one file.
6. **A Character's Faction lives in two places in physics.** Hurtbox layers follow `faction`. Body layers are hand-set per scene (`player.tscn:38-39`, `zombie.tscn:17-18`) and decide blocking and Aggro (section 9). **Trigger:** pets or charm.
7. **A dead Enemy's Aggro keeps watching** (section 4). Harmless until pack Aggro, which is on the enemies spec's "Later" list.

---

## Decision briefs

Each brief stands on its own.

### B1. How are Enemy kinds built as scenes?

**The question.** The glossary says Enemies come in kinds. When there are thirty kinds, is each kind a complete scene of its own, or a variant of one Enemy scene? (Either way a shared `Character` script holds what the player and every Enemy have in common.)

**Options.**
- **A. Each kind is a complete scene.** A new kind is a duplicate of the zombie with its frames and numbers changed. A change for every Enemy means opening every kind. A test checks that each kind has the nodes the Enemy script needs.
- **B. One Enemy base scene (`enemy.tscn`) that every kind inherits, built now. The player's scene stays its own.** A new kind: Scene › New Inherited Scene from `enemy.tscn`, set its frames and numbers, add its Behaviour and Skills. A change for every Enemy is one edit in `enemy.tscn`. Costs: a kind can't delete a node the base has, so the base holds only what every kind needs. The base's node names become a contract. The developer edits the base in the editor, and agents don't hand-write inherited scenes. A test checks that every kind inherits `enemy.tscn`.
- **C. B, plus a `character.tscn` above both the player and `enemy.tscn`** (Fable's sketch). One more place for what every Character shares. Every kind then sits two levels down, a value set in `enemy.tscn` hides a change made in `character.tscn`, and the player inherits nodes it can't delete.
- **D. B, built at the second Enemy kind instead of now** (Sol's timing). The same end state. The zombie is restructured twice, once now for the Character work and again then. Until then, nothing stops the second kind being made as a copy.

**The tenth kind, a skeleton archer, under each.** A: copy the zombie's 13 nodes, change 4 values, add a bow Skill and its Behaviour; a burn for every Enemy later is ten edits. B and D: New Inherited Scene, 4 overrides, add the bow and Behaviour; the burn is one edit. C: as B, with one more level to look through when a value doesn't take.

**What each touches.** All: `characters/character.gd`, `player.gd`, `enemy.gd`, `player.tscn`. A: `zombie.tscn` edited in place. B and D: a new `enemy.tscn`, `zombie.tscn` rebuilt in the editor, a new test, `.scratch/enemies/spec.md` (decision "No inherited enemy base scene") and the conventions. C: also `character.tscn`, with `player.tscn` rebuilt as an inherited scene.

**Recommendation: B, now**, in the same editor session as the Character work, which reshapes the zombie anyway. The structure every kind needs is already fixed by what the Enemy script looks up (`$Health`, `$Hurtbox`, `$NavigationAgent3D` and the rest), so the base isn't a guess. Kind values (frames, numbers, Behaviour, Skills) stay out of it. Adding the base later means rebuilding every kind made in the meantime. Adding C's top level later means rebuilding two scenes, however many kinds exist. So C can wait for a third sort of Character that isn't an Enemy kind, such as a pet.

### B2. Is the player staggered and knocked back?

**The question.** When an Enemy's Skill hits the player, does the player get a Stagger: slide with the knockback and lose control for a moment, as an Enemy does?

**Options.**
- **A. No.** A hit lowers the player's Health and shows on the Standee. The player keeps walking and activating. The player's scene has no Stagger. (A boss can be made the same way later.)
- **B. Yes, as an Enemy.** The player slides and can't walk until the Stagger ends. Whether Skills can still be activated meanwhile follows B3, part 3.
- **C. Knocked back, but keeps control.** The push is added to the player's walk, and nothing is taken away.
- **D. Only big hits stagger the player.** A threshold, in the spirit of other ARPGs' stun against maximum Health. Needs a rule for "big".

**In play.** Inside a pack of five zombies, each swinging every second or so (no Enemy Skill exists yet, so the numbers are illustrative): under B, with Stagger 0.05 for each hit, the player loses control several times a second. Under A, never. Under C, the player is jostled but steers.

**What each touches.** A: nothing; the glossary's Stagger stays "an Enemy". B: a Stagger node in `player.tscn`; one line in `Player._physics_process` plus a choice of what still updates during the slide (Facing, the hover ring); the glossary's Stagger becomes "a Character". C: `Player._physics_process` adds the slide's velocity to the walk, and "does not chase" stays Enemy-only. D: B plus a threshold number and a home for it (a Character's own numbers, R8).

**Recommendation: A for the first Enemy Skill.** The prototype's question is whether the controls feel good (README). Taking control away on every hit works against that, and more so on touch. It is cheap to change later: a Stagger node in `player.tscn` (B), or a few lines (C). Decide again with the first Enemy Skill meant to push the player, such as a boss's slam.

### B3. What does a Stagger of 0 mean, what does a second hit do, and what can a staggered Enemy do?

**The question.** The Stagger component's rules. Today a Stagger of 0 is quietly turned into 0.02 s, a second hit restarts the Stagger with its own numbers, and a Stagger stops an Enemy chasing.

**Part 1: a Stagger of 0.**
- a. **Nothing happens:** no hold and no push, even with Knockback (Knockback is the slide of a Stagger).
- b. **An instant push** by the Knockback, with no hold.
- c. **Today's shortest slide**, 0.02 s.

*In play:* take a burn that ticks every 0.25 s with Stagger 0. Under c, a burning zombie is held for two frames per tick and stopped dead each time, so it limps. Under a, it chases at full speed.

**Part 2: a hit during a Stagger.**
- a. **Restart** with the new hit's push and time (the glossary's "Another hit restarts it"; today).
- b. **The later end wins.** The new push replaces what is left of the slide.
- c. **The times add up.**

*In play:* a slam (Stagger 0.5), then the player's own Attack swing 0.1 s later (Stagger 0.05). Under a, the Enemy recovers at 0.15 s: the swing wasted the slam. Under b, it stays staggered until 0.5 s. Under c, until 0.55 s, and fast Skills chain into a lock.

**Part 3: a staggered Enemy's own Skills** (once Enemies have Skills).
- a. **Stagger stops walking only.**
- b. **Stagger stops walking and activating.** A request made during it is dropped.
- c. **As b, and it cuts short an activation in progress.** Needs activations that take time (R1).

*In play:* a zombie one frame from swinging is hit by the player's Attack. Under a, it swings anyway. Under b, it swings once the Stagger ends. Under c, its wind-up is lost.

**What each touches.** Parts 1 and 2: `Stagger.start()` and `test_stagger.gd` only. Part 3: the Enemy's activation path (its Behaviour, or a Character-level activation) and the hit pipeline's `can_activate()`; for c, also the contract for activations that take time.

**Recommendation.** Part 1: **a**. The glossary defines a Stagger as the time it "slides with the knockback", so no Stagger means no slide. Decide before the first zero (a reduced-Stagger Modifier, or a burn). Part 2: **a** until a Skill with a long Stagger exists, then **b**. Part 3: **b**, with the first Enemy Skill: hitting an Enemy delays its attack, which gives the player's hits weight. Settle **c** with R1.

### B4. What is the player at 0 Health?

**The question.** The glossary says that at 0 an Enemy dies, and "the player, for now, stays at 0". Once Enemies can hit the player, is a player at 0 Health still hit?

**Options.**
- **A. Still hit.** Damage does nothing, but every hit still flashes and squashes the Standee, staggers (if B2 says so) and plays Hit feedback. Enemies keep swinging.
- **B. Can't be hit.** At 0 the player's Hurtbox switches off, as a dead Enemy's does. Enemy Skills find nothing. Enemies still chase (Aggro notices the body) and stand at reach.
- **C. Dies, and play restarts.** The player sinks like an Enemy, Controls stop, and the game resets the same Character at a start point. This needs a game scene that can restart (the UI and game root analyst's level split). It also needs `Health` to come back from 0, which today it never does (`health.gd:41`).

**In play,** playing on after reaching 0 to keep testing a Skill. Under A, every zombie swing flashes the player, and freezes the world too if hits on the player freeze it (R5). Under B, it is quiet. Under C, the run starts over.

**What each touches.** A: nothing. B: switching the Hurtbox off at 0 moves from `Enemy._die()` into `Character`, shared by both; the glossary's Health entry gains "and can't be hit". C: player death handling, a reset in Health, the game scene's restart, and the glossary.

**Recommendation: B** for the first Enemy Skill step; **C** when sessions exist.

### B5. When does the Enemy's Behaviour move out of `enemy.gd`?

**The question.** `enemy.gd` is one Behaviour *(proposed: how the game tells an Enemy what to do)*: stand, chase, stop at reach. It sits on top of what every Enemy needs. When does that Behaviour become its own node, the way Controls is the player's?

**Options.**
- **A. Now, all of it.** The movement and a request to activate a Skill, with a guessed Aim and no Skill to drive it.
- **B. Now, the movement half only.** A `Chase` node answers where to walk and what to face. `enemy.gd` keeps navigation, avoidance and death. The activation half comes with the first Enemy Skill.
- **C. With the first Enemy Skill** (both reports). The step that gives the zombie its swing moves chasing into a Behaviour node, makes it stop where the swing reaches, and adds the activation request.
- **D. At the second Behaviour.**

**The tenth kind,** a skeleton archer that keeps its distance and shoots. Once the split exists (B, C or D), it is a new Behaviour node in its scene and `enemy.gd` doesn't change. Before the split, it can't be made without forking `enemy.gd`.

**What each touches.** All: `enemy.gd`, a new Behaviour script, the zombie scene, and the reach tests, which move from `test_enemy.gd`. C also meets the hit pipeline: the Skill's reference to its Character, what an Aim holds, and activations that take time.

**Recommendation: C.** The split exists mainly to make the stopping distance follow a Skill's Range and to decide when to activate, and both need a Skill and answers to R1 and R2. Designing the interface without them is half guessing. **B** is the fallback if a second Enemy kind is planned before Enemy Skills.

### B6. Can Enemy kinds differ in body size?

**The question.** Can an Enemy kind take up more or less room on the ground than the zombie: an ogre, a rat?

**What stands in the way.** The level's navmesh is baked for one size of walker (radius 0.3, height 1.0, `scenes/sandbox_navmesh.tres`). A bigger body is routed through gaps it doesn't fit and wedges; a smaller one can't use gaps it would fit. Every Character's body is the same 0.25 capsule, and one Hurtbox capsule in `hurtbox.tscn` serves them all.

**Options.**
- **A. One size for every Character for now.** Kinds differ in their art, numbers, Behaviour and Skills. A big Standee can stand on the same footprint.
- **B. A few size classes *(proposed)*.** Each level bakes one navmesh per class: a navigation region per class, on its own navigation layer. `tools/bake_navmesh.gd` already bakes every region in a scene. Each kind sets its class, its body capsule, its Hurtbox and its agent radius.
- **C. Any size on one navmesh.** Big kinds get stuck. Not workable.

**In play.** An ogre of radius 0.6: under A, it uses the zombie's footprint and its card overlaps walls. Under B, it uses the large class's navmesh and can't enter one-tile corridors, which may be exactly what level design wants.

**What each touches.** B: every level (an extra bake per class), the Enemy base (its agent's navigation layers), and the Hurtbox's shape. The Character could hand its body's shape to its Hurtbox, so a kind sets its size once.

**Recommendation: A** until the first kind that must be another size, then **B**. This is worth knowing before designing Enemy kinds.

---

## Work packages

In order. Each is one branch off `master`, landed by a PR with a merge commit, with a spec first (working agreement). "Scene edits" says which edits an agent can make in text and which need the developer's hands in the editor. Per the project's memory of the open editor: after any scene change made in text, the developer uses Project › Reload Current Project before saving anything, and the editor's resave of a file the branch changed is committed once, on its own.

### WP1. Character, Stagger and the Skills node (branch `character`)

- **What.** Section 1 and section 3: `characters/character.gd` and `characters/stagger/stagger.gd`; `player.gd` and `enemy.gd` extend `Character`; a `Skills` `Node3D` in both scenes; a Stagger node in the zombie; `add_skill()`. It keeps today's behaviour.
- **Ride-alongs** (small, same files): `bar` matches by node name (section 6). Health ignores amounts of 0 or less, with two tests (section 10, item 4). `ponytail:` comments for the three ceilings in section 8.
- **Files.** New: `characters/character.gd`, `characters/stagger/stagger.gd`, `tests/test_stagger.gd`, `tests/test_character.gd`. Changed: `characters/player/player.gd`, `characters/enemy/enemy.gd`, `characters/health/health.gd`, `characters/standee/standee.gd` (comment only), `characters/player/player.tscn`, `characters/enemy/zombie.tscn`, `tests/test_player.gd`, `tests/test_enemy.gd`, `tests/test_pause_menu.gd`, `tests/test_skill_bar_hud.gd`, `tests/test_aim_modes.gd`, `tests/test_health.gd`.
- **Tests that move.** The knockback curve test, from `test_enemy.gd` to `test_stagger.gd`. Node paths to `Skills/…`, and `add_child` to `add_skill` (section 1).
- **Docs it reopens.** The factions-health spec (requirements 1, 2 and 7), the combat spec (where the player's Skills live), two lines in the conventions (`super()` first; the `Skills` node is a `Node3D`). No glossary change.
- **Depends on.** Nothing. It doesn't need B1: without WP2 the zombie simply gains two nodes. **For the other analysts:** it creates the `Character` type that the hit pipeline's reference from Skill to Character names. Land it before that work, and before the `Hit` change, so the hit has one receiver (`Character._on_hit_taken`) instead of one per script.
- **Implementer.** Opus writes the spec with the developer (short; this analysis is most of it). Sonnet implements.
- **Scene edits.** Text-safe for an agent. In `player.tscn`: add a `Skills` `Node3D` ahead of `SkillBar`, move `Attack` and `Fireball` under it (`parent="Skills"`, keeping their `unique_id`s), set `main_skill = NodePath("../Skills/Attack")`, and store `faction = 0` on the root. In `zombie.tscn`: add a `Stagger` node (with its script) and an empty `Skills` `Node3D`. Then the developer reloads the project.
- **Done when.** `enemy.gd` has no Faction, hit reaction or Stagger code. `player.gd` has no Faction, Modifiers, Skills list or Health wiring. Every existing test passes with only the path changes above. `test_stagger.gd` and `test_character.gd` pass. A zombie hit in the sandbox slides and recovers as on `master`. *Needs a run:* `tools/check.sh`, then a look in game or with `tools/screenshot.gd -- res://scenes/sandbox.tscn "tp 18 4" "activate 1 2 0"`.

### WP2. `enemy.tscn`, the base every Enemy kind inherits (branch `enemy-base`; only if B1 picks B)

- **What.** Section 2, option B. `enemy.tscn` holds what every Enemy needs. `zombie.tscn` becomes an inherited scene that overrides frames, speed and Health. A test checks that every scene under `characters/enemy/` other than `enemy.tscn` has `enemy.tscn` as its base (`(load(path) as PackedScene).get_state().get_base_scene_state()`).
- **Files.** New: `characters/enemy/enemy.tscn`, `tests/test_enemy_kinds.gd`. Rebuilt: `characters/enemy/zombie.tscn`. Docs: the enemies spec decision "No inherited enemy base scene" is reopened; the conventions gain "Enemy kinds inherit `enemy.tscn`, made with Scene › New Inherited Scene; the base holds only what every Enemy needs; edit the base in the editor."
- **Tests that move.** None. Every test instantiates `zombie.tscn`.
- **Depends on.** WP1 (so the base has its Stagger and Skills nodes) and B1.
- **Implementer.** The developer, in the editor, for the two scenes. Haiku for the test and the doc lines.
- **Scene edits.** An agent may draft `enemy.tscn` in text: it is the zombie with its frames, speed and Health left to the kinds. **`zombie.tscn` must be made in the editor**: Scene › New Inherited Scene from `enemy.tscn`, set the three values, then Save As over `characters/enemy/zombie.tscn`. The sandbox refers to it by path, so its seven zombies keep loading. *Needs an editor check:* that saving `enemy.tscn` doesn't resave the kinds.
- **Done when.** `zombie.tscn` lists only its overrides. `test_enemy_kinds.gd` passes. *Needs a run:* `godot --headless --path . --script res://tools/simulate.gd -- res://scenes/sandbox.tscn 6 "tp 16 7.5"` prints the same distances as on `master`.

### WP3. The player's Hurtbox and the player at 0 Health (part of the first Enemy Skill step)

- **What.** `player.tscn` gains a Hurtbox, plus a Stagger if B2 picks B. The rule from B4 goes into `Character`: under B, the Hurtbox switches off at 0, shared, and `Enemy._die()` keeps the rest. If B2 picks B, the line `if _slide(delta): return` goes into `Player._physics_process`.
- **Files.** `player.tscn`, `character.gd`, `enemy.gd`, `player.gd` (if B2 picks B), new tests in `test_character.gd`, and `GLOSSARY.md`: Health (B4), Stagger (B2).
- **Depends on.** WP1; B2; B4. The hit pipeline's `Hit` and the Hurtbox's own "can be hit" state (seams H1, H3); R5, which hits play Hit feedback (seam H4). The factions-health spec already puts this in the step that first lets an Enemy deal Damage.
- **Implementer.** Sonnet, once those are settled.
- **Scene edits.** Text-safe: one Hurtbox instance (and a Stagger node) in `player.tscn`.
- **Done when.** An Enemy's hit lowers the player's Health following B2's rule, and a player at 0 follows B4's.

### WP4. The Enemy's Behaviour as a node (with the first Enemy Skill; brief B5)

- **What.** Section 5. A `Chase` node (one Behaviour) with `notice()`, `destination()`, `facing_while_standing()`, and the activation request. `enemy.gd` keeps the agent, avoidance, `velocity_computed` and death. The stopping distance follows the Skill's Range (section 5's conversion from Range to distance between centres). A staggered Enemy doesn't request activations (B3, part 3). Repath only when the destination moves, if profiling asks for it (section 8).
- **Files.** New: `characters/enemy/chase.gd`, `tests/test_chase.gd`. Changed: `enemy.gd`, the zombie scene, `test_enemy.gd` (reach tests move). Glossary: **Behaviour** *(proposed)*.
- **Depends on.** WP1 (and WP2 if B1 picks B); B3 part 3; B5. The hit pipeline's reference from Skill to Character, the shape of an Aim (R2) and activations that take time (R1); the spec for the first Enemy Skill.
- **Implementer.** Opus.
- **Scene edits.** Adding the Behaviour node to an inherited `zombie.tscn`: in the editor.
- **Done when.** (Fable's line, which still fits.) `enemy.gd` has no `reach_distance`, `should_chase` or `_target`. A second Enemy scene with another Behaviour node needs no change to `enemy.gd`. The zombie stops where its Skill reaches.

### WP5 (optional). The console commands leave `player.gd`

- **What.** Section 6: a `PlayerCommands` child, handed the Player in `Player._ready()`. Command names unchanged.
- **Files.** New: `characters/player/player_commands.gd`. Changed: `player.gd`, `player.tscn`, one line in the conventions (the Autoloads paragraph's example). Tests: `test_player.gd`'s command tests keep running through `Console.execute`, so they stay, unchanged.
- **Depends on.** WP1. Trigger: the next command added to the Player.
- **Implementer.** Haiku.
- **Scene edits.** Text-safe: one node in `player.tscn`.
- **Done when.** `player.gd` has no `_cmd_` function and preloads no Modifier, and `tp` still leaves and returns with the Player (`test_player.gd:28-32`).

### At their triggers (no package now)

| What | Trigger |
|---|---|
| `character.tscn` above `player.tscn` and `enemy.tscn` (B1, C) | A third sort of Character that isn't an Enemy kind (a pet) |
| Size classes, one navmesh each (B6, B) | The first kind that must be another size |
| Aggro by hostile Hurtboxes, and body layers per Faction | Pets, a third Faction, or charm |
| A `faction` setter on Character | Charm |
| A `max_health` setter; `Movement.speed` kept in step with the agent's `max_speed` | Gear or an effect that changes maximum Health or speed during play |
| Death through `process_mode` | The first component on every Enemy with its own processing that must stop at death |
| Tests read tuning numbers from the scenes | The first tuning change to the zombie or a Skill |
| Standee parameters set only on change; repath only on change; dormant Enemies skip physics | Profiling with 20-40 Enemies on the phone |
| A Stagger `started` signal | Activations that take time (R1), or a hit pose |

---

## Seams with the other analysts

**Hit pipeline and the Skill contract**
- **H1. What a hit carries.** After WP1, the hit lands in one place, `Character._on_hit_taken(direction, snapshot)`. A `Hit` object changes that one method and the Hurtbox. WP1 assumes today's signature.
- **H2. How a Skill refers to its Character.** WP1 gives Skills their Faction in two lines (`Character._ready()` and `add_skill()`). Their package swaps those for the Skill's reference to its Character and removes `Skill.faction`. `add_skill()` is the "one owner method" Sol asks for. It works before the Character enters the tree.
- **H3. The Hurtbox's own "can be hit" state.** `Enemy._die()` switches off `hurtbox.collision_layer` today, and under B4's option B so will the shared code at 0. Whatever they define must also take a dead Character out of Skill queries and Auto-aim, not just out of `take_hit`, because `Hurtbox.around` finds anything on the layer.
- **H4. Hit feedback on the Character hit.** The flash and squash move into `Character._on_hit_taken`. R5 (which hits show Hit feedback) decides what a hit on the player shows.
- **H5. Process order.** The `Skills` node ahead of `SkillBar` settles Sol's S2 order question through the tree. If they prefer process priorities, the `Skills` node is still wanted, for `add_skill()`.
- **H6. Things in flight.** An Enemy is freed when its sink ends (`enemy.gd:119`), and takes its children with it. Before Enemies get projectile Skills, their host for things in flight has to take balls out from under the Skill.
- **H7. A staggered Character's activations.** B3 part 3, option b, needs a check in the activation path. If they add `can_activate()` (Fable 7), the Character's Stagger is a second reason it says no.
- **H8. An Enemy's Aim and activations that take time** (R1, R2). These feed WP4's activation half.

**Rules engine and content data**
- **R1.** `Character.modifiers` keeps today's name and type. If they split Modifier definitions from occurrences (Sol D2), the type changes here, in one place.
- **R2.** Negative numbers: Health ignores amounts of 0 or less (WP1). They may floor Snapshot numbers too. Both together are fine.
- **R3.** A Character's own numbers (R8): Health's maximum and Movement's speed are plain exports. When they become numbers that change in play, the `max_health` setter and the agent's `max_speed` follow (section 7, and section 10 item 5).

**UI and game root** (their `ui-game-root.md`, seams C1-C4)
- **C1.** The HUD and pause menu read `skill_bar`, `skill_activated`, `aim_from_drag`, `show_aim`, `hide_aim` and `skills`. All stay on `Player`, with `skills` now inherited from `Character` as the same property. `pause_menu.gd:126` doesn't change.
- **C2.** The node-path changes in their tests (`test_skill_bar_hud.gd:24`, `test_pause_menu.gd:60`) are in WP1's list.
- **C3.** Command names stay the same if WP5 happens.
- **C4.** Respawn: we agree on resetting the same Character. Under B4's option C, `Health` needs a reset that comes back from 0.

---

## Engine facts relied on

| Fact | Source |
|---|---|
| In Godot 4, a subclass's `_ready()` replaces its parent script's; call `super()` | GDScript 2.0 write-up (godotengine.org/article/gdscript-progress-report-new-gdscript-now-merged). The 4.7 GDScript reference doesn't state it. WP1's `test_character.gd` fails if `super()` is missing. |
| A `Node3D` under a non-`Node3D` parent inherits no transform | Node3D, 4.7: `get_parent_node_3d()` "Returns null if … the parent is not a Node3D" |
| `PROCESS_MODE_DISABLED` and `PROCESS_MODE_PAUSABLE` semantics | Node, 4.7 |
| `disable_mode` `DISABLE_MODE_REMOVE` takes bodies and areas out of physics while disabled | CollisionObject3D, 4.7 |
| A tween from `create_tween()` pauses when its node can't process (`TWEEN_PAUSE_BOUND`) | Tween, 4.7 |
| `set_target_position` asks for a new path on every call, even to the same spot | Engine source, `navigation_agent_3d.cpp` (comment and `_request_repath()`); class reference "If set, a new navigation path … is requested" |
| `NavigationAgent3D` pauses its avoidance agent on `NOTIFICATION_PAUSED` and has no `DISABLED` case | Engine source, `navigation_agent_3d.cpp`. Effect on neighbours: needs a run. |
| Disabling a node sends `NOTIFICATION_PAUSED` to every node whose ability to process changes | Engine source `node.cpp:727-742`, as checked by the UI analyst |
| Many avoidance agents cost significant performance | NavigationAgent3D, 4.7 |
| Instance uniforms can't hold textures | Shading language, 4.7: "Per-instance uniforms do not support textures or arrays" |
| `SceneState.get_base_scene_state()` returns the inherited base, or null | SceneState, 4.7 |
| Inherited scenes can't remove base nodes or edit sub-resources | 4.2 import docs, for imported scenes. **Unverified for `.tscn` bases**; check in the editor. |
| Removing a body or area from the space during a physics report may be refused | **Unverified.** `aggro.gd:47-49` defers `monitoring` for this reason. Needs a run (section 4). |
