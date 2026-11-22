# Fireball's ball in the world

Status: ready-for-agent

Tickets 01 to 05 are built on the recommended answers to the open rules, which the developer confirms when reading this step's PR. Ticket 06 is the developer's.

Fireball's ball carries the activation's **Hit**, lands it itself and lives in the world beside the **Character** that threw it, so it outlives the **Skill** and the Character. Its **Range** is measured from the Character's centre: the ball's front reaches exactly the Range, as the Aim marker's ring shows. It spends **Pierce** only on a Hit that landed, a ball whose **Projectile speed** is 0 ends, and the speeds at which a fast ball starts to slip through things are written down where it moves. Nothing else changes in play.

Step 10 of `.scratch/future-proofing-review/plan.md`, the last of the structural steps, on branch `ball-in-world`, stacked on step 9 (`hit`) as the plan stacks every step (decision 8). Sources: `.scratch/future-proofing-review/analysis/hit-pipeline.md` section 3 (the projectile), section 10 item 5, Brief D and work package HP3; `analysis/ui-game-root.md` ("The game scene and the level", seam H3); `.scratch/game-scene/spec.md` ("Things in flight"). Each claim was checked against the code at `8797660` and against what steps 2, 5, 6, 7 and 9 change. Line numbers are `master`'s (`8797660`); steps 2, 7 and 9 change `fireball.gd`, `projectile.gd`, `skill.gd` and `test_projectile.gd` before this step, so find lines by their text. Where this spec departs from the analysis is listed near the end, and what it takes from step 9 (`.scratch/hit/spec.md`) after that.

Words: a *ball* is Fireball's projectile, the `Projectile` node (the glossary's Projectile speed entry says "Fireball's ball"). *The world* is plain words for the 3D scene the Characters move in, and *things in flight* is plan.md's plain words for what a Skill leaves flying. A *throw* is one activation of Fireball. **Hit** is step 9's glossary term (plan.md's working answer), **Level** step 5's.

## What changes and why

After step 9 a Skill makes one Hit per activation (its Snapshot, the Character that dealt it, whether its impact freezes the world), and a Hit lands itself. But the ball is still a child of the Fireball node: Fireball adds it with `add_child` and `top_level` on (`fireball.gd:35`, `:38`), the ball reports each Hurtbox it touches through its `hit` signal, and a lambda on Fireball lands the throw's one Hit there (`:37`, two lines after step 9). Three things follow:

- **It dies with its Character.** `top_level` only stops a node following its parent's transform; freeing a node frees its children (Engine facts 6). A zombie frees itself 0.45 s after its killing Hit (`enemy.gd:119`), while a Fireball flies about 0.8 s. No Enemy has a Skill yet, so it hasn't happened; the first Enemy projectile would vanish with its Enemy.
- **It can't be anyone else's.** Landing needs the Fireball node, so nothing can carry a ball's Hit once its Skill is gone, and every later Skill that leaves something behind (a trap, a burning patch) would hang it under itself too.
- **Its Pierce counts what its Hit missed.** The ball adds a Hurtbox to its count before anything lands (`projectile.gd:46-50`). A Hurtbox whose Character was killed earlier in the same physics step misses (`hurtbox.gd:17`) but still uses up the pass-through, so the ball stops there. The developer left it as rare (`.scratch/factions-health/issues/03-enemy-death.md`, Comments); it goes for free once the ball learns whether its Hit landed.

And two of its numbers break their own rules:

- **Range.** The glossary's Range is "how far a Skill reaches from the Character that has it". The swing and Auto-aim both count a Hurtbox when any part of it is within Range of the Character's centre (`Hurtbox.around()`, `hurtbox.gd:46-47`, used by `attack.gd:43` and `player.gd:184`), and the Aim marker's ring is drawn at Range (`aim_marker.gd:28`). The ball starts 0.45 ahead of the Character, its centre then flies the whole Range, and the physics step never looks at its last position (Engine facts 2), so its last look has its centre about 10.25 from the Character and its front 10.45: it touches a zombie whose near side is up to 0.45 past the ring.
- **Projectile speed 0.** A ball that can't fly never reaches its Range: it never moves and never ends (`.scratch/number-bounds/spec.md`, Out of scope). Step 1 floors every number at 0, so a Modifier cutting Projectile speed by 100% reaches it.

| | After step 9 | After this step |
|---|---|---|
| Where the ball lives | a child of the Fireball node, `top_level` on | beside its Character, through `Skill._add_to_world()` |
| Who lands its Hit | Fireball, in a lambda on the ball's `hit` signal | the ball, with `hit.land()` |
| What it carries | the Snapshot | the activation's Hit |
| Its Character freed mid-flight | the ball goes with it | it flies on and lands its Hit |
| How far it reaches | front at about 10.65 from the Character's centre, for Range 10 | front at exactly 10.0 |
| Pierce | spent on every Hurtbox it touches | spent only on a Hit that landed |
| Projectile speed 0 | never moves, never ends | ends where it starts |
| Tunnelling | unmarked | a `ponytail:` comment with the speeds and the upgrade |

What stays, as the plan decided (the analysis's "disagreement settled"): the ball stays in `skills/fireball/` and stays Fireball's until a second projectile Skill shows what is shared; no `skills/projectile/` folder, no projectile base class. It moves by setting its position and trusts the physics step's overlaps.

### Where things in flight go

```
game.tscn while balls fly                     a test with no game scene

Game                                          the test's node (GutTest)
└─ PixelatedView › SubViewport › World        ├─ Player
   ├─ Player                                  │  └─ Skills ─ Attack, Fireball
   │  └─ Skills ─ Attack, Fireball            ├─ Projectile   the player's ball, beside it
   │     (after step 9 the ball is here,      └─ Zombie …
   │      under Fireball)
   ├─ Projectile    the player's ball, right after Player
   └─ Sandbox (the Level)
      ├─ PackZombie …
      └─ Projectile an Enemy's ball (once Enemies have Skills), right after its Enemy
```

`Skill._add_to_world(node)` puts `node` beside the Skill's Character, with `add_sibling` (Engine facts 7): the engine's own "next to this node", so no Skill reaches up with `get_parent()` or a path. That is the game scene's `World` for the player's Character and the Level's root for an Enemy (step 5: the Level is instanced under `World`, after the player's Character, and holds its Enemies at its root), and the test's own node in a test. Each case needs no wiring:

- **An Enemy's ball goes with its Level.** When a Level is replaced, freeing its root frees the Enemies and everything beside them, their balls included (Engine facts 6).
- **The player's ball stays in `World` when a Level is replaced.** Nothing changes Levels yet. When level changing comes (the second Level, step 5's Out of scope: "freeing things in flight on the way"), it frees them; `_add_to_world()` is the one line that changes if it wants them under one node of `World` instead. A `ponytail:` comment on `_add_to_world()` says so.
- **A test with no game scene** gets its balls in its own node, beside the player's Character it added. They are not freed with that Character, so the test frees them (Tests).

## The rules

1. **A ball carries its Hit.** Fireball's activation makes the activation's Hit (its Snapshot and its Character, which dealt it, with an impact that doesn't freeze) and hands it to the ball. The ball lands it on each hostile Hurtbox it touches, pushing along the throw. Nothing goes back to Fireball.
2. **A ball lives beside the Character that threw it**, never under the Skill: in the game scene the player's in `World`, right after the player's Character, an Enemy's in its Level; in a test, in the Character's parent.
3. **A ball outlives its Skill and its Character.** Freeing either mid-flight changes nothing for the ball: it flies on and lands its Hit, though the Character that dealt it is gone (the Hit's `dealer` then reads as null, step 9's rule 4).
4. **A ball ends at its end, at a wall or prop, at its last Pierce, or with its parent.** An Enemy's ball is freed with its Level, every ball when the game quits. Nothing frees the player's ball when a Level is replaced (level changing isn't built).
5. **A ball's front reaches exactly its Range from the centre of its Character, as it stood at the throw.** Its Range is its Snapshot's. Its centre starts 0.45 ahead of the Character's centre and 0.5 up, its last position puts its front at the Range, and the physics step looks there before it ends. So it touches a Hurtbox whose near side is within Range on its line, and nothing wholly beyond Range.
6. **Pierce is spent only on a Hit that landed.** A Hurtbox the ball touches without its Hit landing (its Character died earlier in the same physics step) doesn't count, and the ball flies on.
7. **A ball that can't leave where it starts ends there**, at its first physics frame: one whose Projectile speed is 0, or whose Range ends inside it (a Range under 0.65). Open rule 3.
8. **A frozen ball waits.** A hitstop doesn't move a ball and doesn't cut its flight short; a ball that had already reached its end, or that can't fly, still ends. One whose last move came in the frame the freeze began ends in the first frozen frame (a real physics step had already looked at its end, so nothing is missed), and one with a Projectile speed of 0 thrown during a freeze ends at once. Any other ball flies on after the freeze.
9. **Unchanged:** walls and props stop it, with or without Pierce; its Hit lands on each Hurtbox once, so touching one again after knocking it ahead does nothing; it never touches a Hurtbox of its own Character's Faction; landed on an Enemy, its Hit shakes the screen and doesn't freeze the world (step 9's `land()`); it keeps its throw's Snapshot whatever Modifiers do after.

Nothing else changes in play.

### The distances

Measured on the ground from the centre of the Character at the throw, for Fireball (Range 10, Projectile speed 12) and the zombie's Hurtbox.

| What | Where | From |
|---|---|---|
| The ball's radius | 0.2 | its `SphereShape3D`, `projectile.tscn:5-6` |
| Its centre at the start | 0.45 ahead, 0.5 up | `LAUNCH_OFFSET`, `FLIGHT_HEIGHT` (`fireball.gd:14-15`, moving to `projectile.gd`) |
| Its back and front at the start | 0.25 and 0.65 | |
| A Hurtbox at flight height | a circle of radius 0.25 | capsule radius 0.25, full height 1.0 including its ends, centred 0.5 up (`hurtbox.tscn:5-7`, `:16`; Engine facts 9): its straight part runs 0.25 to 0.75 up, which holds the whole ball (0.3 to 0.7) |
| A ball touches a Hurtbox | while their centres are under 0.2 + 0.25 = 0.45 apart on the ground | |
| Its front at the end | 10.0, the Range | rule 5 |
| Its centre at the end | 9.8 | 10.0 less its radius |
| How far its centre flies | 9.8 − 0.45 = 9.35: 46 steps of 0.2 and a last one of 0.15, 47 physics frames, about 0.78 s | a step is Projectile speed / 60 |
| The farthest zombie it touches, head-on | centre under 9.8 + 0.45 = 10.25: near side under 10.0 | |
| After step 9 | last look at centre 10.45, front 10.65: a zombie centred up to about 10.90 | `projectile.gd:27-32` frees it in the frame it reaches Range, before the physics step looks |
| The swing (Range 1.6), for comparison | any part within 1.6: a zombie centred up to 1.85 | `.scratch/combat/spec.md`, review decisions |

The ball's last step is shortened so its centre stops at exactly 9.8; without that it overshoots by up to one step and its front reaches up to 10.2.

The review of this branch worked the old ball's reach through in floating point and found the "After step 9" figure first written here (last look at centre about 10.25, front 10.45) was off. At a Projectile speed of 12 a step is exactly 0.2, but fifty additions of 0.2 sum to 9.999999999999996, just under 10, so the old ball took a 51st step: its last look was at centre 10.45, front 10.65, and it could hit a zombie centred up to about 10.90. The new ball's front stops at 10.0, so the reach drops by about 0.65, not 0.45. The code and its tests are right; the message of commit `fcd5045` repeats the earlier figure.

## The change, file by file

The sketches show shape and the doc comments to use; the implementer writes the code. Which ticket brings which piece is under Tickets and in each ticket.

### `skills/skill.gd` (ticket 01)

One new method, at the end of the file after step 9's `_hit()`:

```gdscript
## Puts `node` in the world beside the Skill's Character, where it lives on by itself and outlives
## the Skill and the Character: a ball in flight. Everything a Skill leaves in the world goes
## through here. For the Skills themselves.
# ponytail: beside the Character means the player's things go into the game scene's World, which a
# Level change doesn't free, and an Enemy's into its Level, which takes them with it. When changing
# Levels is built (with the second Level), it must free the player's things, or this function must
# put them under one node of World that the change frees.
func _add_to_world(node: Node3D) -> void:
	character.add_sibling(node)
```

No check of its own: `try_activate()` already asserts a Character (step 7), and a Skill is activated only in the tree, where its Character has a parent. Nothing else in `skill.gd` changes; `_activate()`'s doc already says "something it sets going, such as a ball, may go on by itself" (step 7), which is now true word for word.

### `skills/fireball/fireball.gd` (ticket 01)

- **The class doc** (`:4-7`, as step 2 left it) becomes:

  ```gdscript
  ## Fireball: throws a ball of fire (see Projectile) straight where it is aimed, carrying the
  ## activation's Hit. The ball lands the Hit itself on each hostile Hurtbox it touches, with the
  ## same Hit feedback as any other Skill except the hitstop: a projectile's Hit doesn't freeze the
  ## world. It lives in the world beside the Character, so it flies on after the Skill and the
  ## Character are gone.
  ```

- **`:13-15`**, `LAUNCH_OFFSET`, `FLIGHT_HEIGHT` and their doc line, move to `projectile.gd`. Nothing else names them (`grep` finds only `fireball.gd`).
- **`_activate`** (`:30-39`, as step 9 left it, with its lambda) becomes three lines:

  ```gdscript
  func _activate(snapshot: Snapshot, aim: Vector3) -> void:
  	var ball: Projectile = ProjectileScene.instantiate()
  	_add_to_world(ball)
  	ball.launch(_hit(snapshot, FREEZES), global_position, aim.normalized(), hostile_mask())
  ```

  `global_position` is the Character's centre: a Skill stands where its Character stands (step 6, rule 4). `_hit(snapshot, FREEZES)` is step 9's: the throw's one Hit, dealt by the Character, made at the activation as step 9 already makes it.
- **Leaves:** `ball.direction = …`, `ball.snapshot = …`, `ball.top_level = true`, `ball.collision_mask |= …`, step 9's `ball_hit` line and its `hit.connect` lambda, `add_child(ball)` and the position line: what the hit spec lists under "What step 10 changes here".
- **Stays:** `ProjectileScene`, `FREEZES` and its doc, `PROJECTILE_SPEED` and `projectile_speed` (step 2), `numbers()`.

### `skills/fireball/projectile.gd` (tickets 01 to 04)

The whole script, as it ends:

```gdscript
class_name Projectile
extends Area3D
## Fireball's ball. Thrown with launch(), it flies straight at its Hit's Projectile speed and lands
## its Hit on each hostile Hurtbox it touches, until its front reaches its Hit's Range from the
## centre of the Character that threw it, or it touches a wall or a prop. With Pierce among its
## Hit's Snapshot's tags it passes through the first Hurtbox its Hit lands on and stops at the next;
## a Hurtbox its Hit misses doesn't count. It looks for walls and props on the `world` layer and for
## Hurtboxes on the layers launch() adds. It lives in the world beside that Character (see
## Skill._add_to_world()) and needs neither the Skill nor the Character once thrown, so it flies on
## and lands its Hit after they are gone.
## It is Fireball's ball for now. With the second projectile Skill it becomes a piece Skills share,
## in a folder of its own and with its own Projectile speed name.

## How far in front of its Character's centre it starts, and how high it flies.
const LAUNCH_OFFSET := 0.45
const FLIGHT_HEIGHT := 0.5

## The Hit it carries and lands: its throw's Snapshot and the Character that threw it. Set by
## launch(); it never changes after.
var hit: Hit:
	get:
		return _hit
	set(_value):
		assert(false, "A ball's Hit is set by launch() and never changes")

var _hit: Hit
var _direction := Vector3.FORWARD # a unit vector on the ground
var _flight := 0.0 # how far its centre flies before it ends
var _flown := 0.0
var _hurtboxes_hit: Array[Hurtbox] = [] # those its Hit landed on

@onready var _shape: SphereShape3D = ($CollisionShape3D as CollisionShape3D).shape


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


## Throws it, once it is in the world (see Skill._add_to_world(); it sets its position and reads its
## shape, which need the tree), from `centre`, the centre of the Character that throws it, along
## `direction` (a unit vector on the ground). It carries `ball_hit`, which it lands on each Hurtbox
## it touches on the layers of `mask`. It starts LAUNCH_OFFSET along `direction` and FLIGHT_HEIGHT
## up, and flies until its front is its Hit's Range from `centre` (see GLOSSARY.md, Range). With a
## Projectile speed of 0, or a Range that ends inside it, it ends where it starts.
func launch(ball_hit: Hit, centre: Vector3, direction: Vector3, mask: int) -> void:
	assert(is_inside_tree(), "A ball is launched once it is in the world: Skill._add_to_world() first.")
	_hit = ball_hit
	_direction = direction
	collision_mask |= mask
	global_position = centre + direction * LAUNCH_OFFSET + Vector3.UP * FLIGHT_HEIGHT
	var can_fly := hit.snapshot.number(Fireball.PROJECTILE_SPEED) > 0.0
	# Its front is its radius ahead of its centre, and its centre starts LAUNCH_OFFSET out.
	_flight = hit.snapshot.number(Skill.RANGE) - LAUNCH_OFFSET - _shape.radius if can_fly else 0.0


# ponytail: moves by setting its position and trusts the physics step's overlaps, so it can skip
# whatever is thinner than one step (Projectile speed / 60). At Fireball's 12 a step is 0.2, and
# only a graze within 0.011 of a Hurtbox's edge can slip by. Above 24 a Hurtbox passed more than
# 0.40 from its centre can slip by, above 46 the thinnest prop head-on (a table), above 54 a
# Hurtbox head-on, above 84 a wall. With the first Modifier on Projectile speed, sweep it instead:
# cast_motion along each step for the wall or prop that stops it, and the Hurtboxes the swept ball
# touches before that point, taken in travel order.
func _physics_process(delta: float) -> void:
	if _flown >= _flight: # at its end, which the last physics step has looked at
		queue_free()
		return
	var step := minf(hit.snapshot.number(Fireball.PROJECTILE_SPEED) * delta, _flight - _flown)
	global_position += _direction * step
	_flown += step


## A wall or a prop: it stops the ball.
func _on_body_entered(_body: Node3D) -> void:
	queue_free()


func _on_area_entered(area: Area3D) -> void:
	if is_queued_for_deletion(): # it ended earlier in this physics step: nothing else counts
		return
	var hurtbox := area as Hurtbox
	if not hurtbox or hurtbox in _hurtboxes_hit: # touching it again after knocking it ahead
		return
	# The Hit missed: the Character of the Hurtbox it touched died earlier in this physics step.
	if not hit.land({hurtbox: _direction}):
		return
	_hurtboxes_hit.append(hurtbox)
	var passes_through := 1 if SkillTag.PIERCE in hit.snapshot.tags else 0
	if _hurtboxes_hit.size() > passes_through:
		queue_free()
```

Line by line, against step 9's file:

- **Leaves:** `signal hit(hurtbox)` (`:10`) and the class doc's last sentence, "It reports a Hurtbox it touched with `hit`, and that Skill lands the throw's Hit there." (`:7-8`, as step 9 words it); the public `direction` and `snapshot` (`:12-16`), which Fireball set one by one; `hit.emit(hurtbox)` (`:47`). `top_level` was set by Fireball and goes with Fireball's lines: the ball sits under `World`, a Level or a test's node, none of which moves.
- **New:** the two constants (from `fireball.gd`), `hit`, `_direction`, `_flight`, `launch()`, the `ponytail:` comment.
- **Changed:** `_physics_process` (`:27-32`) reads its Projectile speed from `hit.snapshot` (step 2's `Fireball.PROJECTILE_SPEED` stays), checks its end before it moves and shortens its last step; `_on_area_entered` (`:40-50`) lands the Hit and counts the Hurtbox only if it landed (step 2's `SkillTag.PIERCE` stays).
- **The radius** is read from the ball's own `CollisionShape3D`, kept in an `@onready` field (`_shape`), so `projectile.tscn` stays the one place its size is set. `launch()` runs once the ball is in the tree (it asserts so), so the field is set. `hit` is readable (two tests read it) but refuses writes as `Hit`'s fields do; `launch()` sets the private `_hit`.
- **Why the end check comes first:** a position the ball moves to is looked at by the physics step at the end of that frame and reported at the start of the next (Engine facts 1). Ended in the same frame as its last move, it is deleted before that step (Engine facts 2) and its last position is never looked at; ended at the start of the next frame, after the report, it is.
- **Why a Projectile speed of 0 sets the flight to 0, rather than a check each frame:** a hitstop makes `delta` 0 too, and a ball frozen by an Attack's hitstop must fly on afterwards (rule 8). The ball tests its Projectile speed, never its step. A Range under 0.65 gives a flight below 0, which the same first check ends: the ball never steps backwards.

### Unchanged on purpose

- `projectile.tscn` and `fireball.tscn`: nothing in them changes (the mask's `world` layer, the size, `monitorable = false` stay), so the editor has nothing to resave.
- `attack.gd`: it lands its Hit at once, through step 9's `_hit(snapshot).land(hits)`, and leaves nothing in the world.
- `hit.gd`, `hurtbox.gd`, `hit_feedback.gd`: step 9's. `character.gd`, `player.gd`, `enemy.gd`: no change.
- `game.tscn`, `sandbox.tscn`: no node for things in flight (step 5's Out of scope, now with the second Level as its trigger).

## The ball's life

1. **Made.** Fireball's `_activate`, during the activation. In play that is inside the tree's physics processing: the Skill bar asks for activations from its `_physics_process` (`skill_bar.gd:80-104`).
2. **Added to the world.** `_add_to_world(ball)` puts it right after its Character in the Character's parent. Its `_ready()` connects its two signals. Added while the tree processes physics, it is first processed in the next physics frame (Engine facts 3).
3. **Launched.** `launch()` gives it its Hit, its direction and its mask (the `world` layer plus the hostile Hurtbox layers), puts it 0.45 ahead of the Character's centre and 0.5 up, and works out its flight (9.35 for Fireball). From here it reads nothing from the Skill or the Character.
4. **Each physics frame**, 60 a second, in the engine's order (Engine facts 1):
   1. The signals for what the last physics step found it overlapping, walls and props through `body_entered`, Hurtboxes through `area_entered` (item 5).
   2. Its `_physics_process`. At its end, it `queue_free()`s and is deleted before the physics step (Engine facts 2). Otherwise it moves one step: its Projectile speed times `delta`, the last one shortened to end exactly at its flight. During a hitstop `delta` is 0: it holds still and its flight isn't cut short (rule 8: one already at its end, or that can't fly, still ends).
   3. The physics step finds what it overlaps where it now is.

   So every position it moves to is looked at once, its last one included. In play the step right after the throw also looks at the spot where it starts, since it isn't processed until the next frame; a ball thrown from a test's body after `wait_physics_frames` moves once before its first look (Known limits).
5. **What it touches:**
   - **A hostile Hurtbox that takes the Hit.** `hit.land({hurtbox: direction})`: the Character hit loses the Hit's Damage, its Stagger starts with the knockback along the throw, and its Standee flashes and squashes; if it is an Enemy, the screen shakes without a freeze, through that Hurtbox's viewport (step 9's `land()`, decision 7). The Hurtbox counts: without Pierce the ball ends; with Pierce, the second one ends it.
   - **A hostile Hurtbox that doesn't take it.** Its Character died earlier in this physics step, so it is off every layer and `take_hit()` misses, though the engine still reports the touch the step found (Engine facts 1): nothing happens, no impact plays, it doesn't count, and the ball flies on. It isn't reported again: off every layer, it overlaps nothing.
   - **A Hurtbox its Hit already landed on**, touched again after knocking it ahead: ignored.
   - **A Hurtbox of its own Character's Faction, or a Character's body:** never reported; their layers aren't in its mask.
   - **A wall or a prop:** it ends, Pierce or not.
   - **Several things in one physics step:** reported in an order the engine doesn't promise; once it has ended, the rest is ignored (Known limits).
6. **Pierce.** `SkillTag.PIERCE` among its Hit's Snapshot's tags lets one landed Hit through; the second landed Hit ends it. A missed Hit spends nothing (rule 6).
7. **The end of its Range.** The move that brings its centre to 9.8 (front at 10.0) is looked at by that frame's physics step; the next frame reports what it touched there, lands its Hit on it, and then ends the ball.
8. **Its Character freed mid-flight.** Nothing happens to the ball: it isn't the Character's child. It lands its Hit as before. The Hit's `dealer` then reads as null, since step 9 holds it weakly (its rule 4 and open rule 2), and nothing on the way reads it: `land()` plays the impact through a Hurtbox's viewport, and `Character._on_hit_taken()` reads only `hit.snapshot`. Its Skill freed alone is the same.
9. **The tree torn down.** The ball goes with its parent: an Enemy's with its Level, any ball when the game quits, a test's ball with the test's node at the end of the test file (Tests). A paused game pauses it, as today.

## Tests

Run one file with `godot --headless --path . -s addons/gut/gut_cmdln.gd -gselect=test_<subject>.gd -gexit`, then `tools/check.sh`.

### Balls outlive their test's Character

After step 9 a test's ball is a child of its Fireball, under the player's Character that GUT frees after the test. After this step it sits beside that Character, in the test's own node, which GUT keeps for every test in the file and frees only after the last one, with a warning (Engine facts 11). A ball left flying goes on into the next test's zombies. So every test file whose tests throw a ball frees them in `after_each`:

```gdscript
## The balls a Fireball threw live beside the player, not under it: free them, or they fly on into
## the next test.
func after_each() -> void:
	for ball in find_children("*", "Projectile", false, false):
		ball.free()
```

`find_children` matches the class through its script (step 5's Engine facts 6); `owned` is false because a ball added at run time has no owner. `after_each` runs before GUT frees the test's own nodes, and GUT skips one already freed (Engine facts 11). Files that throw balls, found with `grep -n "Fireball\|press(1\|touch 2" tests/`:

- `tests/test_projectile.gd`, below.
- `tests/test_player.gd`: `test_a_requested_skill_is_activated_with_the_players_modifiers` throws one (`player.skill_bar.press(1, Vector3.RIGHT)`, slot 1 holding Fireball). The `after_each` goes after `before_each`.
- `tests/test_skill_bar_hud.gd`: slot 1 holds the player's Fireball (`:24`, step 6's path), and `test_an_off_centre_tap_with_a_wobble_is_still_a_tap`, `test_a_drag_aims_by_hand` and `test_the_touch_command_taps_or_drags_a_slot` (two) throw one each through the Player's own connection to `activation_requested`. The `after_each` goes after `before_each`.

If step 9 or another step before this one added a test that throws a ball elsewhere, its file gets the same `after_each`.

### `tests/test_projectile.gd`

The file's helpers, as they end:

- `var hits: Array[Hurtbox]`: every Hurtbox a Hit landed on, in order. Cleared in a new `before_each` (it was `_fire()`'s first line).
- `after_each()`: `Engine.time_scale = 1.0` (in case a test froze it), then frees every ball, as above.
- `_balls() -> Array[Node]`: `find_children("*", "Projectile", false, false)`, the balls in the test's node: those a test made itself, and those the player's Fireball threw beside the player.
- `_zombie_at(x)`: as today, and its Hurtbox's `hit_taken` appends that Hurtbox to `hits` (a lambda taking step 9's arguments, `(_hit: Hit, _direction: Vector3)`). Hits are read from the zombies now: the ball has no signal.
- `_fire(tags, projectile_speed := 15.0, damage := 0.0) -> Projectile`: a ball made in the test, `add_child_autoqfree`d, then `launch()`ed from the origin along `Vector3.RIGHT` with the mask hostile to the player's Faction, carrying a Hit whose Snapshot holds `tags` and the numbers `{Fireball.PROJECTILE_SPEED: projectile_speed, Skill.RANGE: 12.0, Skill.DAMAGE: damage, Skill.KNOCKBACK: 0.0, Skill.STAGGER: 0.0}`, with no dealer and no freeze, made as step 9's `test_hit.gd` makes one: `Hit.new(snapshot, null, false)` (its open rule 3; answered b, the dealer is a stand-in `autofree(Character.new())` instead), as `test_flies_along_its_direction_then_disappears_after_its_range` makes its Hit too. It starts at (0.45, 0.5, 0), moves 0.25 a frame at 15, and its front stops at 12. The Damage, Knockback and Stagger are new: the ball now lands its Hit on real zombies, whose Character reads all three (`Snapshot.number()` asserts on a number it lacks). At 0 a zombie neither loses Health nor moves (step 1: Health ignores 0; step 6: a Stagger of 0 does nothing).
- `_players_fireball()`: step 7's, unchanged.

Every test, as step 9 leaves it:

| Test | What changes | Ticket |
|---|---|---|
| `test_flies_along_its_direction_then_disappears_after_its_range` | The ball is `add_child_autoqfree`d, then `launch()`ed from the origin along `Vector3.LEFT` with a mask of 0 and a Hit whose Snapshot holds Projectile speed 60 and Range 5 (1 unit a frame); it starts at (−0.45, 0.5, 0). Same assertions: left of −0.5 two frames on, straight, freed 8 frames later (its front stops at 5: 5 moves). | 01 |
| `test_a_ball_in_flight_keeps_its_throws_snapshot` | The ball is `_balls()[0]`, not `fireball.get_child(0)`; it reads `ball.hit.snapshot`. | 01 |
| `test_without_pierce_it_stops_at_the_first_enemy` | `_fire` launches; `hits` comes from the zombies. | 01 |
| `test_a_piercing_ball_passes_through_the_first_enemy_and_stops_at_the_second` | Same. | 01 |
| `test_a_piercing_ball_never_passes_through_a_wall` | Same. | 01 |
| `test_it_hits_an_enemy_only_once_even_when_it_touches_it_again` | The first Hurtbox is moved ahead of the ball on its own `hit_taken` (connected after `_zombie_at`'s), not on the ball's `hit`. | 01 |
| `test_a_ball_in_flight_keeps_pierce_when_the_modifier_goes` | `_balls()[0]`; `ball.hit.snapshot.tags`. | 01 |
| `test_a_piercing_ball_still_ends_at_its_range` | `_fire` launches; the zombie at 14 stays past the front's 12. | 01 |
| `test_a_fireball_hit_knocks_back_without_freezing_the_world` | Rewritten so it can fail (below). | 01 |
| `test_it_flies_through_a_hurtbox_of_its_own_faction` | `_fire` launches; `hits` comes from the zombie. | 01 |
| `test_a_fireball_lowers_a_zombies_health_by_its_damage` | None: `after_each` frees the ball. | 01 |
| `test_a_piercing_ball_passes_through_the_zombie_it_kills_and_stops_at_the_next` | None. | 01 |
| `test_a_piercing_ball_lands_its_throws_one_hit_on_both` (step 9's) | None: it already records from the zombies' `hit_taken`, and `after_each` frees the ball (the hit spec's seam on this file). | 01 |

**The test that must be able to fail.** `test_a_fireball_hit_knocks_back_without_freezing_the_world` samples the time scale in a callback on the ball's `hit` signal, connected after Fireball's lambda, so it reads the time scale after the Hit lands and its impact plays. With the signal gone, the obvious place is the zombie's `hit_taken`, but `land()` emits that through `take_hit()` before it plays the impact, so the time scale read there is always 1 and the test could never fail. It becomes: the player's Fireball thrown at a zombie at 2; then, for 20 frames, `await wait_physics_frames(1)` and keep the lowest `Engine.time_scale` seen; then `Engine.time_scale = 1.0`. Assert `hits == [zombie]` ("hit once"), the lowest time scale 1.0 ("the world never froze") and the zombie past 2 ("knocked back"). A hitstop lasts 0.06 s of real time, about four physics frames, which tick on while the world is frozen, so a freezing Hit is seen. **It can fail:** set Fireball's `FREEZES` to true and run the file: it fails on "the world never froze". Revert, and say so in the PR.

### New tests

All in `tests/test_projectile.gd`. "The base" is step 9's branch (`hit`).

| Test | Ticket | What it proves | On the base |
|---|---|---|---|
| `test_a_ball_whose_character_is_freed_mid_flight_still_lands_its_hit` | 01 | Rules 2 and 3: the player's Fireball thrown at a zombie at 3, then `fireball.character.free()` (the player, and its Fireball with it); 30 physics frames later the zombie's Health is 30. | Fails: the ball is the Fireball's child and goes with the player; Health stays 50. |
| `test_an_enemys_ball_goes_into_its_level_and_goes_with_it` | 01 | Rules 2 and 4: a `Node3D` standing in for a Level (`add_child_autofree`), a zombie in it, a Fireball (`fireball.tscn`) given to the zombie with `add_skill()` and thrown along `Vector3.RIGHT`. The ball, found with `level.find_children("*", "Projectile", true, false)`, has the Level as its parent; after `level.free()` it is freed. No physics frame is needed. | Fails: the ball's parent is the zombie's Fireball. |
| `test_a_ball_flies_on_past_a_zombie_its_hit_missed` | 02 | Rule 6: a zombie at 2 with 10 Health left (`health.damage(40.0)`), a second at 4; two balls `_fire([], 15.0, 10.0)`, no Pierce, side by side, so both touch the first zombie in the same physics step. One ball's Hit kills it and that ball ends; the other's misses it and flies on to the second. 20 frames later `hits == [first, second]`, read before the first zombie's 0.45 s sink frees it. | Fails before ticket 02: the second ball counts the dead zombie and stops; `hits` is `[first]`. |
| `test_a_fireballs_front_reaches_its_range` | 03 | Rule 5, the near side: the player's Fireball (Range 10) thrown at a zombie centred at 10.15, its near side 9.9 from the player's centre: 55 frames later its Health is 30. The ball touches it only from its last position (centre 9.8, 0.35 away; the one before, 9.65, is 0.5 away). | Passes: the base reaches farther. It guards the end check's place: a ball that ends in the frame of its last move never has that position looked at, and misses. |
| `test_a_fireball_never_touches_a_zombie_wholly_beyond_its_range` | 03 | Rule 5, the far side: the same throw at a zombie centred at 10.35, near side 10.1: 55 frames later its Health is 50 and `_balls()` is empty. | Fails: the base's ball looks with its centre at 10.45, 0.1 from the zombie's, and hits it. |
| `test_a_fireballs_last_step_is_cut_short_at_its_range` | 03 | Rule 5, the last step: a zombie centred at 10.27, near side 10.02 (the ball and the Hurtbox's straight part are both at height 0.5, so the horizontal gap is the whole distance): 55 frames later its Health is 50. Added by the review. | Fails without the `minf` clamp on the last step: a step of 0.2 puts the front at 10.05, which touches it. |
| `test_a_ball_with_no_projectile_speed_ends` | 04 | Rule 7: `_fire([], 0.0)`; 3 frames later it is freed. | Fails: it never moves and never ends. |
| `test_a_ball_frozen_by_a_hitstop_flies_on_after_it` | 04 | Rule 8: a zombie at 4, `_fire([])`, then `Engine.time_scale = 0.0` as a hitstop does; 10 frames later the ball is not freed; `Engine.time_scale = 1.0`, and 30 frames later `hits == [zombie]`. | Passes: a guard. It fails if a ball's end is tested on its step, which a hitstop makes 0, instead of its Projectile speed. |

Why these positions: the zombies at 10.15 and 10.35 are beyond their Aggro radius (6) of the player, so they never notice it; one at 3 notices the player and stands too (no navmesh in a test, `.scratch/skill-character/spec.md` Engine facts 8), and keeps standing once the player is freed (a freed target reads as false, Engine facts 8). The two Range tests can't share a throw: Fireball's 4 s Cooldown allows one per test, and two zombies 0.2 apart on one line would shove each other.

`tests/test_projectile.gd`'s doc comment becomes: "A ball (Projectile) flies straight from beside the Character that threw it and ends where its front reaches its Range from that Character's centre. It carries its throw's Hit and lands it itself, so it flies on when its Skill and its Character are gone. It stops at the first hostile Hurtbox its Hit lands on, or with Pierce at the second, lands on each once, flies on past one its Hit misses, and stops at any wall. Its front reaches exactly its Range, never farther. A ball that can't fly ends where it starts. A ball frozen by a hitstop flies on after it. A ball outlives its Character, and an Enemy's goes into its Level and goes with it. after_each frees every ball a test threw: a ball lives beside its Character, not under it."

## Checking by hand

On this branch, and on the base (`hit`) where a comparison is asked for. Take the branch in the editor, then Project › Reload Current Project; keep Save Before Running off. No scene changes on this branch, so there is no resave.

1. `tools/check.sh` passes.
2. **Play `scenes/game.tscn`** (F5). Put Fireball in a slot if it isn't (`bar 2 fireball` in the Console, or Pause › Skill bar). Aim it with a drag on touch or with the mouse, so the Aim marker shows its Range ring, and throw it across open floor: the ball appears just in front of the player and vanishes where its front meets the ring.
3. **The ring is the reach.** Find a lone zombie (the one west of the start room, or the one in the north corridor) and stay farther from it than its Aggro radius (the Console's `aggro` draws it). Stand where its body just crosses the ring and throw: it is hit. Step back until the ring stops short of its body and throw again: the ball vanishes in front of it. On the base, the second throw still hits.
4. **Where a ball lives.** Throw, and press Esc while the ball flies: the pause menu stops it. In the editor's Scene dock › Remote, it sits under `Game/PixelatedView/SubViewport/World`, right after `Player`, and nothing is under `Player/Skills/Fireball`. Close the menu: it flies on.
5. **Pierce.** `modifier pierce on`, then throw through the pack in the hall: the ball passes one zombie and stops at the second. Swing four times at a zombie, then throw through it: it dies, and the ball stops at the next.
6. **A hitstop.** Hold the Attack on a zombie while a Fireball flies past: the ball stops with each swing's freeze and flies on.

## Docs this reopens

**`GLOSSARY.md`**, committed with this spec on the branch (ticket 01's first commit):

- **Range** (`:119-121`). Today: "How far a Skill reaches from the Character that has it: the length of a swing, or how far a projectile flies." The ball now flies less than its Range (it starts 0.45 out and stops when its front, 0.2 ahead of its centre, reaches it), and the entry never said that a body counts by its nearest part. Checked against the code: the swing and Auto-aim both find a Hurtbox when any part of it is within Range of the Character's centre (`hurtbox.gd:46-47`, `attack.gd:43`, `player.gd:184`), and the combat spec's review says "The Range counts the Enemy's body". Becomes:

  > **Range**:
  > How far a Skill reaches from the centre of the Character that has it: the length of a swing, or how far a projectile's front gets. A Hurtbox is within Range when any part of it is.
  > _Avoid_: Reach, distance, radius

- **Pierce** (`:59-61`). Today: "A Skill tag that is also a behaviour: a Pierce projectile passes through the first Enemy it hits and stops at the next. It never passes through a wall." Rule 6 makes "it hits" a Hit that landed. Becomes:

  > **Pierce**:
  > A Skill tag that is also a behaviour: a Pierce projectile passes through the first Enemy its Hit lands on and stops at the next. An Enemy it touches without its Hit landing, such as one killed a moment before, doesn't count. It never passes through a wall.
  > _Avoid_: Penetrate, pass-through

- **Snapshot** (`:115-117`). Today it ends "…for everything the activation causes, such as a projectile in flight or a burn left on an Enemy." A projectile in flight now outlives what made it. Becomes:

  > **Snapshot**:
  > A Skill with every Modifier that applied when it was activated, fixed from that moment for everything the activation causes, such as a projectile in flight, even after its Skill and Character are gone, or a burn left on an Enemy.
  > _Avoid_: Activation, cast, invocation, instance

- **Projectile speed** (step 2's entry). It gains its last sentence (rule 7):

  > **Projectile speed**:
  > How fast a Skill's projectile flies, such as Fireball's ball. A number of the Skill that Modifiers change, named the same on every Skill that has a projectile, so one Modifier can speed them all. At 0 the projectile doesn't fly: it ends where it starts.
  > _Avoid_: Speed, ball speed, velocity

- **Hit** (step 9's entry, which leaves this out until now, as its seams say). It gains a last sentence:

  > **Hit**:
  > What one activation of a Skill does to each Hurtbox it reaches. It carries the activation's Snapshot and the Character that dealt it, and lands unchanged on every Hurtbox the activation reaches: each Character hit works out what it does to them. A projectile carries its Hit and lands it itself, even after the Skill and the Character that dealt it are gone.
  > _Avoid_: Strike, damage event, attack (the Attack is a Skill)

Hit feedback ("A projectile's Hit doesn't freeze the world"), Hurtbox, Aim and Activate still say what the code does.

**`docs/agents/godot-conventions.md`** (ticket 05):

- "Call down, signal up", the sentences on handing a child a reference (find them by their text), which now read:

  > A parent may hand a child a reference to what the child needs, as a Character hands itself to each of its Skills (`Skill.character`), and the child may use what it was handed. What stays ruled out is a child finding its parent by itself, with `get_parent()` or a path. A Skill uses its Character in three ways: it reads the Character's Faction to know what is hostile, its Hits name the Character as their dealer, and it puts what it leaves in the world beside the Character. A Skill puts a node in the world only through `Skill._add_to_world()`, never by adding it to another node itself.

- "Levels and navigation", a bullet after step 5's three on the game scene and the Level (find it by its text):

  > - What a Skill leaves in the world, such as a ball in flight, goes beside its Character, by the rule in "Call down, signal up": the player's into `World`, where a Level change doesn't free it, and an Enemy's into its Level, which frees it with itself. Whatever changes Levels, at the second Level, must free the player's too.

- "Tests and checks", at the end of step 7's paragraph that starts "A test that activates a Skill gives it a Character":

  > A ball a Skill throws lives beside its Character, not under it, so freeing the Character doesn't free the ball: a test file whose tests throw balls frees every `Projectile` left in its node in `after_each`, as `tests/test_projectile.gd` does, or they fly on into the next test.

**`.scratch/combat/spec.md:89`** (ticket 05), the decision that starts "**Fireball's ball is a `Projectile`**", becomes:

> - **Fireball's ball is a `Projectile`** (an Area3D) that flies 0.5 units above the ground, so the floor doesn't stop it. It looks for the `world` layer and the Hurtbox layers hostile to its Character. (Reopened by `.scratch/ball-in-world/spec.md`: it was a child of the Fireball Skill with `top_level` on, and nothing else had to own it; it reported an Enemy it touched to Fireball, which decided the hit. It now carries the activation's Hit, lands it itself, and lives in the world beside the Character that threw it, so it outlives the Skill and the Character.)

**`.scratch/factions-health/issues/03-enemy-death.md`** (ticket 05). The comment of 2026-11-22 stays as written; a new one is appended under `## Comments`, dated the day it is committed:

> - <date>: Fixed by `.scratch/ball-in-world/spec.md`: the ball lands its own Hit and spends its Pierce pass-through only on a Hit that landed, so it flies on past a zombie killed earlier in the same physics step.

**`.scratch/factions-health/spec.md`** (ticket 05), requirement 4's bullet that starts "`Projectile.hit_enemy(enemy)` → `hit(hurtbox)`", as step 9 leaves it, gains at its end:

> (Reopened by `.scratch/ball-in-world/spec.md`: the ball reports nothing to its Skill any more. It carries the activation's Hit, lands it itself, and its Pierce counts only the Hurtboxes its Hit landed on.)

**`.scratch/game-scene/spec.md`** (ticket 05), two passages:

- "Things in flight (for `ball-in-world`)", the last bullet, "Left to that step: whether every ball goes to `World` or each goes beside its Character. Left to the second Level: …", becomes:

  > - Settled by `ball-in-world` (`.scratch/ball-in-world/spec.md`): each goes beside its Character, through `Skill._add_to_world()`. Left to the second Level: freeing the player's balls when the Level changes, and with it, if wanted, a named child of `World` that holds them.

- "Out of scope", the bullet "**A node in `World` for things in flight.** Trigger: `ball-in-world` choosing one place for every ball, or the second Level." becomes:

  > - **A node in `World` for things in flight.** Trigger: the second Level (`ball-in-world` put each ball beside its Character).

**Not reopened:** `.scratch/hit/spec.md` already says what this step changes (its `fireball.gd` section's "What step 10 changes here", its `projectile.gd` section, its first Out of scope row), and its ADR, `docs/adr/0004-a-hit-lands-itself.md`, already says a projectile in flight lands its Hit after its Skill and Character are gone, which this step makes true. `.scratch/skill-character/spec.md` records step 7's changes ("the ball is still `fireball.get_child(0)`" was true there), and its seam already says this step puts a ball beside its Character. `.scratch/character/spec.md` still holds ("a Fireball through the pack: it passes one zombie and stops at the second"). `.scratch/skill-tags/spec.md:32-37` ("Fireball hands it to its projectile", "A projectile in flight keeps its Snapshot", "passes through the first Enemy it hits") stays true through the Hit. `.scratch/deepen-skills/spec.md` item 3 ("depends on what landed it (the projectile)") becomes true word for word. The two reports and `.scratch/future-proofing-review/` are records. No ADR: where things in flight go is one line in `_add_to_world()`.

## Seams

Lines this step touches in files other steps touch:

- **`skills/skill.gd`**: one new method, `_add_to_world()`, at the end of the file after step 9's `_hit()`. Step 1 changed the Cooldown lines, step 7 the class doc, `character`, `_notification`, `try_activate`, `_activate`'s doc and `hostile_mask()`, step 9 `_land_hits()` into `_hit()`. This step changes none of their lines.
- **`skills/fireball/fireball.gd`**: the class doc (`:4-7`; step 2 reworded `:4`), `:13-15` (leave), `_activate` (`:30-39`; step 9 changed `:37`). Step 2's `:17-21` and `:26` stay.
- **`skills/fireball/projectile.gd`**: rewritten around step 2's two names, `Fireball.PROJECTILE_SPEED` (`:28`) and `SkillTag.PIERCE` (`:48`), which stay, as step 2's spec expects ("`ball-in-world` rewrites `_physics_process` and `_on_area_entered` and keeps both names"). Step 9 changed only the class doc's last sentence, which goes.
- **`skills/hit.gd`**, **`characters/hurtbox/hurtbox.gd`**: step 9's, untouched. This step uses `Hit.land() -> bool`, `Skill._hit()` and `hit.snapshot` as the hit spec's seams promise them.
- **`tests/test_projectile.gd`**: the whole file. Step 2 changed `:15` and `:55` (`Fireball.PROJECTILE_SPEED`), step 7 added `_players_fireball()` and used it in five tests, step 9 appended `test_a_piercing_ball_lands_its_throws_one_hit_on_both`.
- **`tests/test_player.gd`** and **`tests/test_skill_bar_hud.gd`**: an `after_each` after `before_each`, nothing else. Step 3 appended tests to `test_skill_bar_hud.gd`; step 6 changed `test_skill_bar_hud.gd:24` and `test_player.gd`'s node paths.
- **`GLOSSARY.md`**: Range, Pierce, Snapshot, Projectile speed (step 2's) and Hit (step 9's, a last sentence, as its seams expect). Step 1 changed Cooldown, step 5 added Level, step 6 changed Character and Stagger, step 7 Skill, step 9 Damage, Damage type, Hit feedback and Stagger.
- **`docs/agents/godot-conventions.md`**: a bullet in "Levels and navigation" after step 5's, a sentence at the end of step 7's paragraph in "Tests and checks". No line in common with steps 2, 3 and 6.
- **Other specs**: `combat/spec.md:89` (step 6 reopened `:104`, step 9 `:101`, and its seams leave `:89` to this step); factions-health requirement 4's projectile bullet (step 9 rewrites the requirement's second bullet, and requirement 3); the factions-health issue 03 comments; game-scene's "Things in flight" and an Out of scope bullet.
- **Step 8 (`enemy-base`)** rebuilds `zombie.tscn` as a scene that inherits `enemy.tscn`, `Skills` included; `test_an_enemys_ball_goes_into_its_level_and_goes_with_it` instances `zombie.tscn` and calls `add_skill()`, which both survive it.
- **Step 11 (how a Skill is aimed)** may change what `_activate` is handed; Fireball's `_activate` reads only `aim.normalized()`.

## Open rules for the developer

1. **How far a ball reaches** (plan.md's working answer, the analysis's Brief D).
   - **a. Its front reaches exactly its Range from the Character's centre** (recommended, and written above): the same rule as the swing and Auto-aim.
   - b. Its centre travels to Range: its front reaches Range + 0.2.
   - c. As after step 9: its centre flies Range from 0.45 out, and the physics step never looks at its last position: its front reaches about 10.65.

   *In play:* under a, a zombie whose body crosses the ring is hit and one wholly outside it never is; under b a sliver of 0.2 past the ring can be hit, under c 0.65. *Why a:* what the ring shows is what is reached, for every Skill. *Touches:* `launch()`'s flight and the two Range tests.

2. **Where a Skill puts what it leaves in the world.**

   | | The player's ball in the game | An Enemy's ball | A Level replaced | A test with no game scene | Wiring |
   |---|---|---|---|---|---|
   | **a. Beside the Character** (recommended) | `World` | its Level | the Enemy's go with it; the player's fly on until level changing frees them | the test's node, beside the Character | none: `add_sibling` |
   | b. Always the game scene's `World` | `World` | `World` | none freed: level changing frees them all | no `World`: needs a second way | the Skill must find `World` without a path: a group lookup, or a reference handed to every Character |
   | c. A named node in `World` (an "Effects") | that node | that node | level changing frees the node's children | no node: needs a second way | as b, plus a node nothing else uses yet |

   *Why a:* it needs nothing found, works the same in the game and in a test, and the Level split already decides an Enemy's balls' lifetime. Its one gap, the player's balls through a Level change, can't happen until Levels change, and fixing it then changes `_add_to_world()`'s one line or adds a few lines to the level change. Step 5's analyst preferred `World` (`ui-game-root.md`, seam H3) for that gap; the hit-pipeline analyst chose a.

3. **A ball that can't leave where it starts:** a Projectile speed of 0, or a Range under 0.65, where its front already is at the throw.
   - **a. It ends at its first physics frame, where it starts** (recommended, rule 7). In play the physics step right after the throw looks there, so it can still land its Hit on a Hurtbox touching it at the start; with a Range under 0.65 that Hurtbox may lie a little beyond the Range.
   - b. Fireball throws nothing: the activation still starts its Cooldown, and nothing is hit. A check in `_activate` that knows the ball's radius and offset.
   - c. The ball starts nearer the Character, so its front is at the Range from the start; with a Range under 0.2 it starts inside the Character.

   For the short Ranges, where the ball's front is at its last look (old ball, new ball):

   - Range 0.5: old 1.05, new 0.65 (the ball ends at its first frame).
   - Range 0.65: old 1.25, new 0.65 (ends at its first frame).
   - Range 0.66: old 1.25, new 0.66 (one step of 0.01, ends at its second frame).

   *In play:* nothing reaches either today: Fireball's Range is 10 and its Projectile speed 12, and no Modifier changes them by that much. A Range of 0 breaks the Attack anyway (`.scratch/number-bounds/spec.md`, Out of scope). *Why a:* no extra code; the first check in `_physics_process` covers both. Revisit with the first Modifier that can cut Range under 0.65.

4. **A Hurtbox the ball's Hit missed, still touching the ball, that can be hit again before the ball leaves it** (an immunity that ends). The physics step reports a touch only when it starts, so the ball passes through it without landing. *Recommended:* leave it until the first immunity, when the Hurtbox gains its own "can't be hit" answer (the analysis's "A Hurtbox found but not hit"). Today only death makes a Hit miss, and a dead Hurtbox never becomes hittable again.

Settled by the plan or the brief, not open: the ball carries its Hit, lands it itself and lives in the world; no shared projectile folder yet; Pierce only on a landed Hit; a ball with Projectile speed 0 ends; movement by position with a `ponytail:` comment; one function on `Skill` for what a Skill leaves in the world.

## Out of scope

| What | Trigger that brings it back |
|---|---|
| A shared projectile folder (`skills/projectile/`), with Projectile speed's constant, the launch offset and the flight height taken off Fireball's ball | The second projectile Skill (plan.md) |
| Swept movement: `cast_motion` along each step, contacts taken in travel order | The first Modifier on Projectile speed |
| A pool of balls instead of a new one per throw | A profile on the phone that points at making balls |
| Freeing the player's things in flight when Levels change; a named node in `World` for them | The second Level |
| A Hurtbox found but not hit, and a ball landing on one that becomes hittable while touching it (open rule 4) | The first immunity |
| An Enemy turning on the Character that dealt a Hit, when that Character is gone | The first Enemy Skill (the analysis's R6) |
| A Range floor that keeps a ball's front past where it starts (open rule 3) | The first Modifier that can cut Range under 0.65 |
| `_add_to_world()` called from inside a physics callback (a ball that throws another when it lands) | The first Skill that does it: Godot refuses some physics changes while it reports overlaps (`aggro.gd:47-49` defers for that reason), so it may need `call_deferred` |

## Known limits

- **Tunnelling**, as the `ponytail:` comment on `_physics_process` says. The speeds, for the shapes in the scenes (ball radius 0.2 at height 0.5): a Hurtbox is touched while centres are under 0.45 apart, a stretch of 2√(0.45² − b²) for a pass at b from its centre, so at a step of s a pass can slip by when that stretch is under s: at 12 (s 0.2) only past b = 0.439, at 24 (0.4) past 0.403, at 36 (0.6) past 0.335, and above 54 (0.9) head-on too. Props and walls, head-on across their thinnest side: the table (0.65 deep, its top at 0.31 only grazed by the ball's bottom at 0.3, so the ball overlaps it over a disc of radius 0.06) at 0.65 + 0.12 = 0.77, above 46; the pot (0.41 deep, top 0.43, disc 0.19) above 47; the barrel, chest and column 53 to 55; a wall (1 deep) above 84.
- **Several touches in one physics step come in an order the engine doesn't promise**: a wall and a Hurtbox, or two Hurtboxes without Pierce. At a step of 0.2 they are side by side, so either can count first. The swept upgrade takes them in travel order.
- **The player's balls outlive a Level change** until level changing frees them (rule 4).
- **In play the physics step looks at where a ball starts; in a test thrown from the test's body it doesn't.** A ball added during the tree's physics processing is first processed in the next frame, so the step looks at its start; a test resuming from `wait_physics_frames` runs before the frame's processing, so the ball moves once first (Engine facts 3, 11). No test depends on it.
- **A Character whose parent moves would carry its balls with it**, now that the ball has no `top_level`. Nothing moves `World` or a Level (step 5: a Level is instanced at the origin).

## Where this departs from the analysis

- `launch()` is called once the ball is in the world and takes the Character's centre, not a reach: the ball reads its Range from its Hit's Snapshot as it reads its Projectile speed, and the launch offset and flight height move into it. The whole rule ("front at Range from the Character's centre") is then one line in one function, and Fireball's `_activate` is three lines. The analysis subtracted the offset in Fireball and the radius in the ball.
- A Projectile speed of 0 gives the ball a flight of 0 at launch: the analysis's "test the Speed, not the step", in one place.
- The thinnest prop head-on is the table, at about 46 units/s, then the pot at 47; the analysis had the pot at 48.6. The low props' tops lie below the ball's centre, so the ball overlaps them over a disc narrower than its radius.
- Tests outside `test_projectile.gd` throw balls too: one in `test_player.gd`, three in `test_skill_bar_hud.gd`. They get the same `after_each`.
- The tests' own balls need Damage, Knockback and Stagger in their Snapshots, since the ball now lands its Hit on real zombies.
- Only another `area_entered` in the same physics step can make a ball's Hit miss: an Attack's kill takes the Hurtbox off its layer in the tree's processing, before the physics step looks, while a touch found by the step is reported even if the Hurtbox left its layers since (Engine facts 1). So the missed-Hit test throws two balls at once.
- After step 9 nothing at the ball's last position counts because the tree deletes a queued node at the end of its physics processing, before the physics step (Engine facts 2), not because of `projectile.gd:41`'s check. The outcome is the same.
- `top_level` was set by Fireball (`fireball.gd:35`), not by the ball.
- Two tests beyond the analysis's four: an Enemy's ball in its Level, and a ball frozen by a hitstop.

## What this step takes from `hit` (step 9)

From `.scratch/hit/spec.md`, which lists these three as what step 10 relies on (its Seams):

- `Skill._hit(snapshot: Snapshot, freezes := true) -> Hit`, dealt by the Skill's Character. Fireball calls it once per throw, with `FREEZES`, as step 9 already does.
- `Hit.land(pushes: Dictionary[Hurtbox, Vector3]) -> bool`: lands, plays the impact once if it landed on an Enemy, through that Hurtbox's viewport, and **says whether it landed on any**. Rule 6 reads that answer.
- `Hurtbox.take_hit(hit, direction) -> bool` and `hit_taken(hit: Hit, direction: Vector3)`: the tests' lambdas take the signal's arguments in that order.

And three things it settles that this step leans on:

- **`land()` and `Character._on_hit_taken()` read nothing of the dealer** (the impact goes through a Hurtbox's viewport, the Character reads `hit.snapshot`), so a ball lands its Hit after its Skill and Character are gone. `test_a_ball_whose_character_is_freed_mid_flight_still_lands_its_hit` checks it end to end.
- **A freed dealer reads as null** (its rule 4, open rule 2 a). Answered b, the `dealer` is a freed Character instead; nothing in this step reads it either way.
- **A Hit may be made with no dealer** (its open rule 3 a), which `_fire()` does. Answered b, `_fire()` passes a stand-in.

After step 9, as its spec leaves the code: Fireball still sets `ball.snapshot`, makes `ball_hit` and lands it in a lambda on the ball's `hit` signal, sets `top_level` and adds the ball as its child; the ball still counts Pierce on every Hurtbox it touches.

## Assumed of steps 5 to 8

- **Step 5**: `World` holds the player's Character, then the Level (its open rule 5); the Level's root is a `Node3D` instanced at the origin (open rule 2) with its Enemies as children (open rule 4). The branch being built has all three.
- **Step 6**: every Skill sits under its Character's `Skills` `Node3D`, so a Skill's `global_position` is its Character's; `add_skill()`. Its open rule 1 (a Stagger of 0) doesn't matter here: the tests' own Hits push nothing.
- **Step 7**: `Skill.character`; `try_activate()` asserts a Character; `test_projectile.gd`'s `_players_fireball()`, the player at the origin with its physics off.
- **Step 8**: `zombie.tscn` keeps its path and inherits its empty `Skills` node from `enemy.tscn`, so `add_skill()` gives a zombie a Fireball as today.

## Engine facts

Godot 4.7 class reference, read 2026-11-22, the 4.7-stable source where marked, and the vendored GUT 9.7.1.

1. **The order of a physics frame** (4.7-stable `main/main.cpp`, `Main::iteration`): `PhysicsServer3D.sync()`, `flush_queries()`, the main loop's `physics_process(physics_step * time_scale)`, `end_sync()`, `step(physics_step * time_scale)`. `time_scale` is read once per frame, so a frame's physics processing and its physics step use the same step. Jolt's `flush_queries()` calls each space's `call_queries()`, which calls each area's `call_queries()` (4.7-stable `modules/jolt_physics/`), whose `_flush_events()` reports to the area's monitor callbacks the pairs the last step added or removed (`objects/jolt_area_3d.cpp`): the `Area3D` node turns those into `area_entered` and `body_entered`. It checks neither whether the other object still matches the area's mask nor whether it still exists, so a Hurtbox taken off every layer earlier in the same report still arrives at a ball that touched it in the step.
2. **A node freed in physics processing is gone before the physics step** (4.7-stable `scene/main/scene_tree.cpp`, `SceneTree::physics_process`): it emits `physics_frame`, processes the nodes, flushes messages, timers and tweens, and flushes its delete queue last ("This should happen last"). The reference says only "at the end of the current frame" (`Node.queue_free()`).
3. **A node added during processing is first processed in the next frame** (4.7-stable `SceneTree::_process_group`: "Make a copy, so if nodes are added/removed from process, this does not break").
4. **Areas see a move at the next physics step.** `Area3D.get_overlapping_areas()`: "For performance reasons (collisions are all processed at the same time) this list is modified once during the physics step, not immediately after objects are moved."
5. **Same priority, tree order.** `Node._physics_process`: "Nodes with the same priority are processed in tree order"; "only called if the node is present in the scene tree".
6. **Children go with their parent; `top_level` is only about the transform.** `Node` (class description): "when a node is freed with Object.free() or queue_free(), it will also free all its children." `Node.queue_free()`: "When deleted, all of its children are deleted as well". `Node3D.top_level`: "If true, the node does not inherit its transformations from its parent", nothing about lifetime.
7. **`add_sibling`.** `Node.add_sibling()`: "Adds a sibling node to this node's parent, and moves the added sibling right below this node." Not confirmed: what it does for a node without a parent (the reference read doesn't say). It doesn't arise: a Skill is activated only in the tree, where its Character has a parent.
8. **A freed object.** `Object`: "In a boolean context, an Object will evaluate to false if it is equal to null or it has been freed"; `is_instance_valid()` is false for it, and "any attempt to access [it] will result in a runtime error".
9. **The Hurtbox's shape.** `CapsuleShape3D.height`: "The capsule's full height, including the hemispheres."
10. **A hitstop.** `delta` is the frame's physics step times the time scale (fact 1), so 0 during a hitstop, while physics frames keep coming. The hitstop's timer ignores the time scale (`hit_feedback.gd:41`).
11. **GUT.** One node per test file runs all its tests (`addons/gut/gut.gd:524-529`); after each test it calls `after_each`, then frees what `add_child_autofree` added (`:636-642`), skipping anything already freed (`addons/gut/autofree.gd:65-71`). After the file's last test it warns "Test script has N unfreed children" and frees the node with whatever is left (`gut.gd:377-392`, `:865-877`). `wait_physics_frames(n)` resumes the test when the tree's `physics_frame` signal comes the (n+1)th time (`addons/gut/awaiter.gd:71-78`), which is before that frame's processing (fact 2). GUT fails a test on an unexpected engine error or `push_error` (`addons/gut/gut_config.gd:57`).

## Done when

- [ ] `projectile.gd` has no signal, `fireball.gd` sets no `top_level` and connects nothing, and Fireball's `_activate` is the three lines above. A search for `add_child` and `add_sibling` under `skills/` finds only `_add_to_world()`.
- [ ] A ball whose Character is freed mid-flight lands its Hit; an Enemy's ball goes into its Level and is freed with it.
- [ ] A Hit that misses spends no Pierce.
- [ ] A Range-10 Fireball touches a zombie whose near side is 9.9 from the player's centre and not one whose near side is 10.1.
- [ ] A ball with Projectile speed 0 ends; a ball frozen by a hitstop flies on.
- [ ] Every test listed is changed as listed, the new tests pass, the time-scale test failed once with `FREEZES` true, and no test file leaves a ball flying. `tools/check.sh` passes after each ticket.
- [ ] The docs say what the code does. A search for `LAUNCH_OFFSET` and `FLIGHT_HEIGHT` outside `projectile.gd`, `.hit.connect`, `ball.snapshot`, `ball.direction` and `get_child(0)` in code and tests comes back clean; only records (the reports, `.scratch/future-proofing-review/`, earlier steps' specs) keep the old words.
- [ ] "Checking by hand" matches, and `/code-review` has run on the branch before its PR.

## Tickets

1. `issues/01-ball-in-the-world.md`: the spec and the glossary; `Skill._add_to_world()`; the ball carries its Hit, lands it itself and lives beside its Character; the tests follow it and free their balls. Pierce, Range and a Projectile speed of 0 still behave as after step 9.
2. `issues/02-pierce-only-on-a-landed-hit.md`: rule 6.
3. `issues/03-range-from-the-character.md`: rule 5.
4. `issues/04-a-ball-that-cannot-fly-ends.md`: rules 7 and 8.
5. `issues/05-reopened-docs.md`: the conventions and the other specs.
6. `issues/06-check-and-pr.md`: the developer's checks by hand, `/code-review` and the PR.
