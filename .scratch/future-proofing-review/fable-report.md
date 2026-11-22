# Future-proofing review

Status: needs-triage

Reviewed `master` at `8797660` on 2026-11-22, at the developer's request. The brief: assume each file is fine on its own (it passed `/code-review`), and ask instead whether the foundation holds once the game has many Skills, many Modifiers, many Enemy kinds and more systems, and whether nodes, scripts and scenes are used the way Godot and a component architecture want.

**How it was done.** Every game script and scene outside `assets/` and `addons/` was read, with `GLOSSARY.md`, the ADRs and the specs under `.scratch/`. Nothing was run and nothing was changed: `tools/check.sh` was not run, and no claim below rests on a test run. Line numbers are those of `8797660`.

**How to use it.** This is input for specs, not a list of tickets to execute. Per the working agreement, each change gets its own branch and spec, and the developer settles open rules first. Three things to keep in mind:

- Code blocks are sketches that show a shape. They were not compiled. Check engine behaviour against the 4.7 class reference before relying on it.
- A name marked *(proposed)* is not in `GLOSSARY.md`. Propose it as a glossary entry first, or pick another.
- The section "Rules to settle with the developer" holds game-design questions. An agent does not answer those.

## Verdict

The rules engine is ready for scale. `Snapshot.of`, the tag pass and Modifiers as data are pure, immutable where it matters, documented in ADRs and well tested. Adding the hundredth Modifier costs one `.tres` file.

The parts around the rules engine are shaped for exactly one player, one Enemy kind and two Skills. The shortcuts sit in three contracts that every future piece of content will implement or pass through:

1. **What a Character is.** The glossary defines Character; the code has no such thing. `Player` and `Enemy` each rebuild half of it, and the halves don't overlap: only the Player can have Skills and Modifiers, only the Enemy can be hit.
2. **What a hit is.** A hit carries a direction and a Snapshot. It can't say who dealt it, and it is landed by the Skill node, so it can't outlive the Character that made it.
3. **What an Enemy is.** `enemy.gd` is one behaviour (stand, chase, stop at reach) welded to the things every Enemy needs (being hit, dying).

The yardstick used throughout: **a shortcut is worth fixing now if fixing it later means touching every Skill script, every Enemy scene or every Modifier file.** A shortcut that stays in one file can wait until something needs it. The second kind is listed under "Leave until needed", with the reason it is cheap to leave.

### What one more costs today

| To add | Today | It should cost |
|---|---|---|
| A Modifier | One `.tres`. A misspelled tag or number name is silently ignored. | One `.tres`, checked. |
| A second projectile Skill | Copy `fireball.gd`. The shared `Projectile` reads `Fireball.SPEED`, so the new Skill borrows Fireball's constant or forks `projectile.gd`. | A scene with its own numbers. |
| An Enemy that hits the player | Copy Skills, Modifiers, the Faction hand-down and aiming from `player.gd` into `enemy.gd`. Copy the Hurtbox wiring, Damage, knockback slide and Stagger from `enemy.gd` into `player.gd`. | A Skill node in the zombie's scene. |
| A second Enemy kind that behaves differently | Fork `enemy.gd`, or branch inside it. | A scene: other frames, other numbers, another behaviour node. |
| A Skill that moves its Character (Blink, Leap) | No route: a Skill has no reference to its Character and no signal for it. | A Skill script. |
| A second level | Copy the HUD, the pause menu, the Player, the camera and their node paths out of `sandbox.tscn`. | A level scene. |

## What to keep

Future agents: these are sound. Don't "fix" them.

- **Snapshot and the tag pass** (`skills/snapshot.gd`, `skills/tag_pass.gd`). Pure, no nodes, read-only once made, and the Modifier order never matters. This is the hardest part of an ARPG's rules and it is the best part of the code.
- **The Skill bar is only a binding** (`skills/skill_bar.gd`). Slots, the press queue and holds. The Skill runs its own Cooldown and activation. An Enemy can have Skills without a Skill bar.
- **Faction as Hurtbox layers** (`characters/faction.gd`). One small table answers "who is hostile", and the physics engine does the filtering.
- **Only a Hurtbox can be hit, and Skills find Hurtboxes with physics queries** (`Hurtbox.around`). No group scans, no `is Enemy` checks.
- **The small components**: `Movement` (a pure step function), `Health`, `Hurtbox`, `Aggro`, `HealthBar`, `Standee`. Each has one job and reports up with signals. No gameplay script calls `get_parent()` or searches the tree.
- **Two autoloads, both real global services**, and Console commands owned by the system that registers them.
- **Typing warnings as errors, `tools/check.sh`, and tests that use real physics.**

## Fix before adding content

In the order they should be done. Findings 1 to 4 belong together and come before the first Enemy Skill.

### 1. Character has no home in code

**Where.** `characters/player/player.gd`, `characters/enemy/enemy.gd`, `player.tscn`, `zombie.tscn`.

**What the code does.** `GLOSSARY.md` says a Character is "anything that moves through the world as a Standee and has a Faction: the player's hero and the Enemies". There is no `Character` class or scene. The two root scripts each hold a different half:

| A Character's part | Player | Enemy |
|---|---|---|
| `faction` export | `player.gd:46` | `enemy.gd:11` |
| Health wired to the Health bar | `player.gd:78` | `enemy.gd:39` |
| Skills, and handing them the Faction | `player.gd:36-42`, `79-80` | none |
| Modifiers | `player.gd:50` | none |
| Facing | `player.gd:28` | none (only `_standee.face()`) |
| Hurtbox on its Faction's layer | none (no Hurtbox) | `enemy.gd:37-38` |
| Taking a hit: Damage, knockback slide, Stagger, flash, squash | none | `enemy.gd:61-69`, `125-137` |
| Dying | none | `enemy.gd:112-120` |

Both scenes also assemble the same nodes by hand: the body capsule, `Standee`, `Movement`, `Health`, `HealthBar` at the same height, and the same `motion_mode` and `safe_margin`. The capsule's size is written three times (both bodies and `hurtbox.tscn`).

**What happens when the game grows.** The next step in `.scratch/factions-health/spec.md` is an Enemy Skill that hits the player. That needs every row of the table on both sides. Without a shared home, each half is copied into the other script, and every later rule (resistances, a burn, immunity while Blinking, death of the player) is written twice and drifts. A pet, which the glossary already mentions, would be a third copy.

**Change.** Give Character one script and one base scene, and move the hit reaction into a component.

- `Character` (`characters/character.gd`, `extends CharacterBody3D`): Faction, Modifiers, Facing, the Skills it has, and the wiring between Hurtbox, Health, Health bar, Stagger and Standee. Thin: wiring and identity only. `Player` and `Enemy` extend it and keep what differs, which is who decides where it walks and what it activates.
- A `Stagger` component (the glossary term): the knockback slide and its clock, taken from `enemy.gd:21-23`, `54-55` and `125-137`. The body asks it for this frame's velocity, as it asks `Movement`.
- A plain `Skills` node that holds the Skill nodes, instead of Skills mixed among the body's other children and found by `child is Skill`.
- `character.tscn` as the base scene. `enemy.tscn` inherits it, and each Enemy kind inherits `enemy.tscn`. Enemy kinds are what will multiply, so that is where an inherited scene pays. Whether `player.tscn` also inherits is the developer's call.

This is one level of inheritance under a class both scripts already extend, for the glossary's own umbrella term. `docs/agents/godot-conventions.md` says to reach for a component before an inheritance chain; the behaviour still goes into components, and the base script only wires them. A shared type also matters here because typing is enforced: a hit's dealer (finding 3), a Skill's Character (finding 2) and whom an Enemy chases all need one type to name.

```gdscript
class_name Character
extends CharacterBody3D
## A Character (see GLOSSARY.md): what the player's hero and every Enemy share.

## Its Health reached 0.
signal died

@export var faction := Faction.Id.ENEMIES
## Its Modifiers: every activation of its Skills is made with them.
@export var modifiers: Array[Modifier] = []

## Its Facing: a unit direction on the ground.
var facing := Vector3.RIGHT

@onready var health: Health = $Health
@onready var health_bar: HealthBar = $HealthBar
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var stagger: Stagger = $Stagger
@onready var standee: Standee = $Standee
@onready var movement: Movement = $Movement


func _ready() -> void:
	hurtbox.collision_layer = Faction.layer(faction)
	hurtbox.hit_taken.connect(_on_hit_taken)
	health.changed.connect(health_bar.show_health)
	health.died.connect(_die)
	for skill in skills():
		skill.character = self # see finding 2


## The Skills it has.
func skills() -> Array[Skill]:
	var found: Array[Skill] = []
	found.assign($Skills.get_children())
	return found


## Hit on its Hurtbox: the one place Damage, Stagger and the flash are applied, for the
## player and Enemies alike. Resistances and the like go here, once.
func _on_hit_taken(hit: Hit, direction: Vector3) -> void:
	health.damage(hit.snapshot.number(Skill.DAMAGE))
	stagger.start(direction * hit.snapshot.number(Skill.KNOCKBACK), hit.snapshot.number(Skill.STAGGER))
	standee.flash(HitFeedback.shared().flash)
	standee.squash(HitFeedback.shared().squash)


## At 0 Health. An Enemy sinks and is gone; the player, for now, plays on.
func _die() -> void:
	died.emit()
```

```gdscript
class_name Stagger
extends Node
## A Character's Stagger (see GLOSSARY.md): the slide a hit's knockback gives it, and how long.

func start(push: Vector3, seconds: float) -> void: ...
func is_active() -> bool: ...
## This frame's share of the slide, as a velocity. Zero while a hitstop freezes the game.
func next_velocity(delta: float) -> Vector3: ...
```

A subclass that defines `_ready` calls `super()` first: in Godot 4 a script's `_ready` replaces its parent script's.

```
character.tscn            Character
├─ CollisionShape3D
├─ Standee
├─ Movement
├─ Stagger                new: the knockback slide from enemy.gd
├─ Hurtbox
├─ Health
├─ HealthBar
└─ Skills                 new: a plain Node holding the Skill nodes

enemy.tscn                inherits character.tscn, script Enemy
├─ NavigationAgent3D
├─ Aggro
└─ (its behaviour, see finding 5)

zombie.tscn               inherits enemy.tscn: frames, Health 50, speed 2.5, its Skills
```

**Open points for the spec.**

- The glossary says Stagger is something an Enemy has. Whether the player is knocked back and staggered is a rule for the developer (the factions-health spec leaves it to the next step). The component can sit on every Character and simply not be started for the player.
- `_die()` today is a hand-kept list of things to switch off (`enemy.gd:112-120`). Kept in one shared place it is fine. Every component added later that must stop at death (Skills, a behaviour, a burn) has to be added to it. If that list grows, look at setting the Character's `process_mode` to disabled, which stops every child and, through `CollisionObject3D.disable_mode`, takes bodies and areas out of physics in one line. The Standee would need its own process mode so the sink still plays. Verify before relying on it.
- Inherited scenes should be built in the editor. The editor rewrites hand-written scenes (see the conventions' "The open editor").

**Reopens.** `.scratch/enemies/spec.md`: "No inherited enemy base scene. One Enemy type; extract a base when the second one shows what they share." The two that share are already here: the player and the Enemy.

**Tests that move.** `test_enemy.gd` (`knockback_left` goes with `Stagger`), `test_enemy_death.gd`, `test_player.gd:93` (its Skills are the Skill nodes it holds), `player.tscn:75` (`main_skill` path).

**Done when.** `enemy.gd` and `player.gd` hold no line that the other would need. A scene made of `character.tscn` alone, with a Skill added, can be hit, lose Health, be staggered, die and activate that Skill.

### 2. A Skill doesn't know its Character

**Where.** `skills/skill.gd:55`, `player.gd:79-80`.

**What the code does.** A Skill gets one thing from its Character: `faction`, pushed once in `Player._ready`. `var faction: Faction.Id` defaults to the enum's first value, `PLAYER`.

**What happens when the game grows.**

- **A Skill nobody hands a Faction fights for the player.** `Enemy` never pushes a Faction (it has no Skills yet), and a Skill added after `_ready` is never pushed one. Give the zombie an `Attack` node today and its swing hits other Enemies and never the player, with no error. The tests already lean on this default: `test_attack.gd` and `test_projectile.gd` activate a bare Skill scene and never set its Faction.
- **A Skill can't do anything to its own Character.** Blink and Leap (README step 1) must move it. A cost must be paid from it. `get_parent()` is ruled out by the conventions, and there is no reference.
- **A hit can't name its dealer** (finding 3).

**Change.** The Character gives each Skill a reference to itself when it takes the Skill in, at `_ready` and whenever a Skill is added later. The Skill reads the Faction from it. An activation without a Character fails loudly. Godot's own guidance is that a parent provides its child's dependencies, and a node reference is one of the listed ways (`.scratch/skill-tags/research-skill-systems.md`, the Godot section).

```gdscript
# skill.gd
## The Character that has the Skill, given by that Character (see Character.add_skill()).
var character: Character


func hostile_mask() -> int:
	return Faction.hostile_mask(character.faction)


func try_activate(aim: Vector3, modifiers: Array[Modifier]) -> bool:
	assert(character != null, "%s has no Character: add it with Character.add_skill()." % name)
	...
```

```gdscript
# character.gd
## Gives the Character `skill`, at any time.
func add_skill(skill: Skill) -> void:
	$Skills.add_child(skill)
	skill.character = self
```

Passing `modifiers` into `try_activate` can stay as it is. It is explicit and the tests like it.

**Done when.** `Skill.faction` is gone. A Skill added to a zombie hits the player's Faction. A Skill activated with no Character asserts.

### 3. A hit can't say who dealt it, and it dies with its Skill

**Where.** `characters/hurtbox/hurtbox.gd:10-20`, `skills/skill.gd:151-157`, `skills/fireball/fireball.gd:32-39`.

**What the code does.** A hit is two loose arguments, `(direction, snapshot)`, through `Hurtbox.take_hit`, the `hit_taken` signal and `Enemy._on_hit_taken`. The Skill node lands it (`Skill._land_hits`, an instance method that needs the Skill's viewport). Fireball's ball is a child of the Fireball node and reports back to it through a signal and a lambda.

**What happens when the game grows.**

- **Nothing that happens after a hit can know the dealer.** A zombie hit by a Fireball from outside its Aggro radius stands still and takes it: Fireball's Range is 10, the Aggro radius is 6, and `_target` is set only by `Aggro` (`enemy.gd:41`). It can't turn on whoever hit it because the hit doesn't say. The same gap blocks credit for a kill (loot, experience, a Skill set off by a kill), leech, and reflecting Damage.
- **A hit's shape is repeated in every signature.** Adding the dealer later means changing `take_hit`, `hit_taken`, every receiver and every Skill script that builds a hits dictionary. With two Skills and one receiver that is an afternoon. With thirty Skills it is a migration.
- **A ball in flight vanishes when its Character is freed.** The ball is a child of the Skill, which is a child of the Character. `top_level` frees its transform, not its lifetime. An Enemy is freed when its sink ends (`enemy.gd:119`), so an Enemy that throws something and dies takes the throw with it. A burn left on an Enemy (the glossary's own example under Snapshot) has the same problem if the Skill node must tick it.

**Change.** Make the hit one small object, and let it land itself.

```gdscript
class_name Hit
extends RefCounted
## One activation's hit (proposed glossary entry): what it does and who dealt it. The same
## Hit lands on every Hurtbox the activation hits.

## The activation's Snapshot: its Damage, Knockback and Stagger, for the Character hit to read.
var snapshot: Snapshot
## The Character that dealt it. It may be gone by the time a projectile lands: check
## is_instance_valid() before using it.
var dealer: Character
## Whether its impact freezes the world. A projectile's doesn't.
var freezes := true


func _init(hit_snapshot: Snapshot, hit_dealer: Character, hit_freezes := true) -> void:
	snapshot = hit_snapshot
	dealer = hit_dealer
	freezes = hit_freezes


## Lands it on each Hurtbox in `pushes`, pushing along its direction. The impact plays once,
## and only if at least one landed.
func land(pushes: Dictionary[Hurtbox, Vector3], viewport: Viewport) -> void:
	var landed := false
	for hurtbox in pushes:
		if hurtbox.take_hit(self, pushes[hurtbox]):
			landed = true
	if landed:
		HitFeedback.shared().play_impact(viewport, freezes)
```

`Hurtbox.take_hit(hit, direction)` and `hit_taken(hit, direction)` replace the two-argument forms. `Skill._land_hits` goes; Attack calls `Hit.new(snapshot, character).land(hits, get_viewport())`. Anything added to a hit later (a part of the Damage, whether it is a critical one) is a field on `Hit` and changes no signature.

While here, give `Hurtbox` its own answer to "can I be hit". Today `collision_layer == 0` stands in for "dead" (`hurtbox.gd:17`). A physics layer doing double duty as game state will be bent again for immunity during a Blink, a boss that can't be hit for a phase, and so on.

**Reopens.** `.scratch/factions-health/spec.md` rule 3: "A hit reports where it pushes and the activation's Snapshot, nothing else". The rule's stated aim is that "the hit never changes shape". One object serves that aim better than two arguments. Whether `Hit` becomes a glossary term is the developer's call; the glossary already says "hit" in several entries (Damage, Stagger, Hurtbox, Hit feedback).

**Done when.** A zombie hit from outside its Aggro radius can find out who hit it (what it then does is a rule: see R6). A ball whose Character was freed mid-flight still lands its hit. `test_hurtbox.gd`, `test_attack.gd`, `test_projectile.gd`, `test_enemy_death.gd` and `test_hit_feedback.gd` pass in the new shape.

### 4. The projectile belongs to Fireball

**Where.** `skills/fireball/projectile.gd`, `skills/fireball/fireball.gd`.

**What the code does.** `Projectile` is written as a shared piece (it knows nothing of fire) but lives in Fireball's folder, reads its speed as `snapshot.number(Fireball.SPEED)` (`projectile.gd:28`), and depends on the Skill that fired it to set its mask, connect its `hit` signal and land the hit (`fireball.gd:32-39`). Those eight lines are what any projectile Skill would repeat.

**What happens when the game grows.** The glossary already names the next projectile: "a bow shoots". A second projectile Skill either imports `Fireball.SPEED` or copies the file. Speed is also a number, so Modifiers will raise it. The ball moves by setting its position and trusts the area overlap to notice what it touches (`projectile.gd:29`). At 12 units a second that is a 0.2 step. Past roughly 54 units a second (350% increased) a step is longer than a ball and an Enemy together, and the ball can skip an Enemy.

**Change.**

- Move it to `skills/projectile/`. It names its own number (`Projectile.SPEED`).
- It carries a `Hit` (finding 3) and lands it itself, so it needs no signal back to a Skill and can be added to the world next to the Character instead of under the Skill.
- The launch becomes one call that every projectile Skill shares.

```gdscript
# skills/projectile/projectile.gd
const SPEED := &"Speed"

## Sends it flying along `direction` (a unit vector on the ground), landing `hit` on the
## Hurtboxes on the layers in `mask`.
func launch(hit: Hit, direction: Vector3, mask: int) -> void: ...
```

```gdscript
# fireball.gd, all that is left
func _activate(snapshot: Snapshot, aim: Vector3) -> void:
	var facing := aim.normalized()
	var ball: Projectile = ProjectileScene.instantiate()
	ball.launch(Hit.new(snapshot, character, false), facing, hostile_mask())
	character.add_sibling(ball) # in the world, so it outlives the Character
	ball.global_position = global_position + facing * LAUNCH_OFFSET + Vector3.UP * FLIGHT_HEIGHT
```

`add_sibling` puts the ball wherever the Character is. If the developer would rather have a named place in the level for things in flight, that works as well; the point is that the ball is not a child of what fired it.

Stop there. Whether Fireball then needs a script at all, or becomes "the projectile Skill" with a `projectile` scene export, is the question `.scratch/deepen-skills/spec.md` deferred to the third or fourth Skill. That deferral still stands. The second projectile Skill will show the answer.

The step-size limit can wait for a Modifier that reaches it. Mark it in the code (`# ponytail: steps by position, skips a thin Hurtbox past ~54 units/s; sweep the shape if Speed Modifiers get there`).

**Reopens.** `.scratch/combat/spec.md`: the ball is "a child of the Fireball Skill ... Nothing else has to own it."

**Done when.** `projectile.gd` doesn't mention Fireball. A second projectile Skill needs no change to `projectile.gd`.

### 5. `enemy.gd` is one behaviour, not "an Enemy"

**Where.** `characters/enemy/enemy.gd`.

**What the code does.** The script holds three things: what every Character needs (being hit, Stagger, dying: goes with finding 1), how a body the game drives moves (the navigation agent, avoidance, `velocity_computed`), and one behaviour: stand until aggroed, chase, stop at `reach_distance`, start again past `resume_distance` (`enemy.gd:14-17`, `47-48`, `77-84`).

**What happens when the game grows.**

- The glossary says Enemies come in kinds. A kind that keeps its distance and shoots, one that charges, a boss with phases: each either forks `enemy.gd` or adds a branch to it.
- `reach_distance` (1.0) is unrelated to any Skill. The moment the zombie has a melee Skill, where it stops must follow that Skill's Range, or the swing misses. Two numbers per Enemy kind to keep in step by hand, and a Modifier that changes the Range breaks them apart.
- An Enemy's Skills need an Aim and a moment to activate. Today nothing decides either.

**Change.** After finding 1, split what is left in two.

- The body keeps how it moves: it asks for a direction, runs it through `Movement`, the agent's avoidance and `move_and_slide`, as now.
- The behaviour moves to a child node. Its interface mirrors `Controls`, which is the same thing for the player: "where to walk, where to aim and which Skill slot to activate" (the glossary's words for Controls). The body calls down for a direction each physics frame; the behaviour signals up when it wants a Skill activated.

```gdscript
# enemy.gd after the split
func _physics_process(delta: float) -> void:
	if stagger.is_active():
		velocity = stagger.next_velocity(delta)
		move_and_slide()
		return
	var direction := _behaviour.move_direction() # as Player asks _controls.move_direction()
	... # Movement, avoidance and velocity_computed as today
```

```gdscript
# characters/enemy/chase.gd (proposed name): today's behaviour, moved
## Walks an Enemy toward what drew its Aggro until its Skill reaches, then asks to activate it.
signal activation_requested(skill: Skill, aim: Vector3)

@export var skill: Skill # the Skill it closes in to activate; its Range sets where it stops

func move_direction() -> Vector3: ...
```

One behaviour script then covers the zombie and an Enemy that shoots from afar: the same script with a long-Range Skill. A kind that behaves differently gets a different behaviour node in its scene.

Don't build a state-machine framework or behaviour trees for this. One script per behaviour is enough until there are several behaviours to compare.

**Before building: settle rule R1 below** (an activation that takes time). The first Enemy Skill is where it bites, because a swing with no warning can't be dodged.

A note for later: `enemy.gd` already lets a scene put an "Enemy" on another Faction (`enemy.gd:9-11`), while the glossary says an Enemy is a Character of the Enemies' Faction. After the split, what is left in `enemy.gd` is "a Character the game drives", and a pet would be exactly that with the player's Faction. The naming is a glossary question for when pets arrive.

**Done when.** `enemy.gd` has no `reach_distance`, no `should_chase` and no `_target`. A second Enemy scene with a different behaviour node needs no change to `enemy.gd`.

### 6. Skill tags and number names are free text that nothing checks

**Where.** `skills/tag_pass.gd:13-15`, `skills/fireball/projectile.gd:48`, `skills/modifiers/*.tres`, `skills/attack/attack.tscn:18`, `skills/fireball/fireball.tscn:10`, `skills/number_change.gd:11`.

**What the code does.** A number has a constant in code (`Skill.RANGE`, `Fireball.SPEED`), and a `.tres` writes it as text (`number = &"Cooldown"`). A Skill tag has no constant anywhere: `&"Pierce"`, `&"Fire"`, `&"Spell"` are typed out where they are used. By design, "a Skill that doesn't have the number ignores it" (`number_change.gd:3-4`), and a filter tag no Skill has simply never matches.

**What happens when the game grows.** Both rules are right for play and wrong for authoring. A Modifier that says `&"Cooldwon"` or filters on `&"Projectiles"` loads, applies to nothing and reports no error, and its "why" line reads "missed, not Projectiles", which looks like a correct miss. With two proof Modifiers you would notice. Among a few hundred from gear and talents you would not.

Enums carry a second quiet risk. `.tres` and `.tscn` files store an enum as its number: `kind = 1` (`spell_cooldown.tres:10`), `aim = 2` (`fireball.tscn:8`). Insert a value in the middle of `NumberChange.Kind`, `TagChange.Kind`, `Skill.Aim` or `Faction.Id` and every saved file silently means something else.

**Change.** Three small things, none of them a new system.

1. **Name every Skill tag once.**

```gdscript
class_name SkillTag
## Every Skill tag (see GLOSSARY.md), named once. A tag that isn't here doesn't exist.
const SPELL := &"Spell"
const ATTACK := &"Attack"
const MELEE := &"Melee"
const PROJECTILE := &"Projectile"
const FIRE := &"Fire"
const ELEMENTAL := &"Elemental"
const PIERCE := &"Pierce"

const ALL: Array[StringName] = [SPELL, ATTACK, MELEE, PROJECTILE, FIRE, ELEMENTAL, PIERCE]
```

   `TagPass.IMPLIED_TAGS` and `projectile.gd:48` use the constants. The implied table can stay in `TagPass`.

2. **One test that reads all the content.** It needs no registry of numbers: a number that no Skill has is a typo.

```gdscript
# tests/test_content.gd
## Every Skill scene and Modifier file under skills/ names only tags and numbers that exist.

func test_every_modifier_names_real_tags_and_numbers() -> void:
	var numbers := _numbers_of_every_skill() # the keys of numbers(), over every Skill scene
	for path in _files("res://skills", "tres"):
		var modifier := load(path) as Modifier
		if modifier == null:
			continue
		assert_ne(modifier.title, "", path)
		for tag in modifier.filter:
			assert_has(SkillTag.ALL, tag, "%s filters on a tag that doesn't exist" % path)
		for change in modifier.number_changes:
			assert_has(numbers, change.number, "%s changes a number no Skill has" % path)
		for change in modifier.tag_changes:
			assert_has(SkillTag.ALL, change.tag, path)
			assert_eq(change.into != &"", change.kind == TagChange.Kind.REPLACE, "%s: only a replace has an `into`" % path)


func test_every_skill_is_complete() -> void:
	for path in _files("res://skills", "tscn"):
		var skill := (load(path) as PackedScene).instantiate() as Skill
		if skill == null:
			continue
		assert_gt(skill.cooldown, 0.0, "%s needs a Cooldown above 0" % path)
		assert_ne(skill.title, "", path)
		assert_not_null(skill.icon, path)
		for tag in skill.tags:
			assert_has(SkillTag.ALL, tag, path)
		skill.free()
```

   This test also covers what `@tool` on every Skill script is there for (the Cooldown warning). Whether to keep `@tool` for the in-editor warning is the developer's call; the test is what stops a bad Skill from being committed.

3. **A line in `docs/agents/godot-conventions.md`:** an enum that scenes or resources save is only ever added to at the end.

**Done when.** A Modifier with a misspelled tag or number fails `tools/check.sh`. In scripts, a Skill tag is written out as text only in `skill_tag.gd`.

### 7. "Can this Skill be activated?" is asked in four places

**Where.** `skills/skill_bar.gd:58` and `:101`, `ui/skill_bar_hud.gd:98`, `skills/skill.gd:108`.

**What the code does.** All four ask `skill.is_ready()`, which means "its Cooldown ran out". The glossary says the Cooldown is the only limit, so today the two questions have the same answer.

**What happens when the game grows.** The factions-health and skill-tags specs both mention mana as coming. A cost, a Character that is dead or staggered, a weapon a Skill needs: each is a second reason a Skill can't be activated, and each would have to be added in four places across three files, one of them the HUD.

**Change.** One question, asked by all four. `is_ready()` stays for what it means (the HUD's ready flash).

```gdscript
## Whether it can be activated now. Today only its Cooldown decides. Anything else that stops
## an activation is added here, once.
func can_activate() -> bool:
	return is_ready()
```

**Done when.** `is_ready()` is called only inside `skill.gd`.

### 8. `player.gd` carries the developer's tools

**Where.** `characters/player/player.gd:21-24`, `68-74`, `195-262`.

**What the code does.** Six Console commands (`tp`, `bar`, `activate`, `damage`, `heal`, `modifier`) and the proof Modifiers they switch take about 80 of the script's 287 lines. The proof Modifiers are preloaded by the player's Character in every build.

**What happens when the game grows.** Each system adds commands, by convention on the node that owns the system. On the Player that means the script the developer most needs to read is a quarter debug code now and more later. `_cmd_bar` also finds a Skill by its `title` (`player.gd:211`), the name the player sees: a title with a space can't be typed as one word, and a translated title changes the command.

**Change.** After finding 1 has taken the shared parts out, move the commands and `PROOF_MODIFIERS` to a child node of their own that registers them in `_enter_tree`, as the convention asks. It holds an export to the Player and calls the Player's public methods. Match Skills by node name or a short `id` rather than `title`.

This is the smallest of the eight and can ride along with finding 1.

**Done when.** `player.gd` has no `_cmd_` function and preloads no Modifier.

## Rules to settle with the developer

These are game-design questions that the code currently answers by accident, or can't answer. They are the developer's to decide. Each one changes a contract or the meaning of saved content, so it is cheaper to decide before the content exists. An agent lists the cases and asks; it does not pick.

**R1. An activation that takes time.** `try_activate` is instant: Snapshot, Cooldown, effect, in one call. `.scratch/remove-use-time/spec.md` removed the shared pause for the player on purpose. The README still asks "Will we use telegraphed abilities?", and an Enemy's swing with no warning can't be avoided. A warning before the hit, a channel, a Leap that takes half a second: all need an activation with a beginning and a later moment when it lands. That raises questions the Skill contract has no place for today. Is the Snapshot made at the start or when it lands? Where is the Aim fixed? Can a Stagger stop it? Is the Character busy meanwhile, and can it walk? Settle this before the first Enemy Skill, because `_activate(snapshot, aim)` is the function every Skill script implements.

**R2. What an Aim can hold.** An Aim is a `Vector3` offset on the ground, with `Vector3.INF` standing in for "none" (`skill_bar.gd:22`). README step 3's curse "must be targeted". A Skill can show what it would pick (`target_for`, `skill.gd:137`) but can't be told "this Character": it would have to find its pick again from the offset inside `_activate`. An Enemy's behaviour knows exactly whom it means and can only pass a direction. The glossary defines Aim as a direction and a distance, so this is a glossary question too. Related: how a Skill aims is spread over three knobs (`Skill.Aim`, `aims_at_spot`, `target_for`) read in four places (`player.gd:124`, `player.gd:150`, `aim_marker.gd:31-38`, `skill_bar_hud.gd:100`). No shipped Skill uses `Aim.AROUND`, `aims_at_spot` or `target_for`; only a test-only Skill does (`test_aim_modes.gd`). Decide both together, before the third Skill.

**R3. Increased on a Modifier that also changes tags multiplies.** `Snapshot.of` stacks the number changes of tag-changing Modifiers as a pool of their own, before everyone else's (`snapshot.gd:39-42`). This is specified (skill-tags rule 6) and tested (`test_snapshot.gd:186`: Range 10, 50% Increased on a tag-changer, +2 flat elsewhere gives 17, not 18). The consequence: 20% Increased on a tag-changing Modifier and 10% Increased on a plain one give ×1.32, not ×1.30. The glossary says an Increased percentage "is added to every other increased or reduced percentage on the same number". ADR 0002 expects Modifiers that carry both kinds of effect to be common ("a Modifier that should change both what a Skill is and what it deals lists both effects"), and its goal is that "every result can be worked out by the player". A player can't see which Increased is secretly on its own. Confirm this is wanted before many such Modifiers exist, or reword the glossary entry.

**R4. The same Modifier twice applies once.** `modifier not in counted` (`snapshot.gd:37`) and `m not in _applied` (`tag_pass.gd:34`) compare Modifier resources, and `test_snapshot.gd` has "a modifier listed twice applies once". The rule in the spec exists so the tag pass ends. As written it also means two copies of the same ring, or two talents that point at the same `.tres`, count once. If that is not the intent, "each entry in the list applies at most once" keeps the tag pass ending and lets two rings stack. Decide with gear.

**R5. Which hits play Hit feedback.** `Skill._land_hits` plays the impact for whatever Skill landed a hit, and `HitFeedback` freezes the whole game through `Engine.time_scale` with a static counter (`hit_feedback.gd:32-52`). The glossary speaks only of "the moment a Skill hits an Enemy". Once Enemies have Skills, every zombie swing that lands on the player freezes the world and shakes the screen, unless decided otherwise. A burn's ticks would too. `freezes` is already a flag passed down two calls (`skill.gd:151`, `hit_feedback.gd:36`); with `Hit` (finding 3) it has a home, but someone has to say what each kind of hit shows.

**R6. A hit from outside the Aggro radius.** See finding 3: today the Enemy doesn't react. Once the hit names its dealer the code can do either; which is a rule.

**R7. Modifiers that depend on what is hit.** A Snapshot is made at activation, before anything is hit, and the Character hit reads its Damage straight from it (`enemy.gd:62`). "More Damage against staggered Enemies" has nowhere to be worked out. So does anything on the defending side: resistances, armour. Nothing to build now. When Damage types are designed, decide where the per-hit step lives; `Character._on_hit_taken` (finding 1) is the natural place.

**R8. A Character's own numbers.** The glossary says a Modifier is a change "to Skills". Maximum Health and walking speed are plain exports on `Health` and `Movement`. Gear that gives Health, or an Enemy rarity with more of it, needs either a wider meaning of Modifier or a second mechanism. `Snapshot._stack` (flat, Increased, More) is already a pure function and could serve both. Decide with gear.

## Before the second level

**`sandbox.tscn` is a level and the whole game at once.** It holds the pixelated view, the world, the level (GridMap, props, navmesh), the Player with the camera as its child (`sandbox.tscn:118-123`), the Enemies, and the HUD, whose `player` and `hud` exports are node paths into that same file (`sandbox.tscn:150-155`). `project.godot` runs it as the main scene.

A second level today means copying everything but the GridMap and re-pointing three node paths. The Player's Health, Skills, Modifiers and Skill bar would also be born again with each level, since the Player is part of the level's scene.

Split it in two when the first of these arrives: a second level, a session with a beginning and an end, or anything that must survive a level change.

```
game.tscn                 the main scene
├─ PixelatedView/SubViewport/World
│   ├─ (the level, instanced here)
│   └─ Player + Camera
└─ HUD: TouchStick, PauseMenu, SkillBarHud      (their exports point inside this scene)

levels/sandbox.tscn       NavigationRegion3D (GridMap, props), light, environment, Enemies,
                          and a marker for where the Player starts
```

`tools/simulate.gd` and `tools/screenshot.gd` take a scene path and keep working with `game.tscn`.

It is listed here and not under "fix before adding content" because Skills, Modifiers and Enemy kinds don't touch it. It is cheap now and gets more expensive with each HUD element wired by node path.

## Leave until needed

Shortcuts that are fine to keep, each with what makes it cheap to leave and what should prompt the change. Don't do these early.

| Shortcut | Why it can wait | Do it when |
|---|---|---|
| **Every Skill has Damage, Knockback and Stagger** (`skill.gd:47-51`), even one that will never hit. | Scenes save properties by name. Moving the three exports off the base later changes no Skill scene that still has them. | The first Skill that doesn't hit (Blink). |
| **A number is declared three times**: an export, a name constant and an entry in `numbers()`. | Two Skills with one extra number each. Forgetting the `numbers()` entry is caught the first time a Modifier names it, by finding 6's test. | Skills become settings on shared pieces. |
| **Skills are one script each.** | Deferred in `.scratch/deepen-skills/spec.md`, and still right. After finding 4, Fireball is ten lines. | The second projectile Skill or the second swing. |
| **`modifiers` is a bare array** changed in place (`player.gd:259-261`), with no signal and no record of where a Modifier came from. | The skill-tags spec deferred this on purpose. Moving the array to `Character` (finding 1) is all that is needed now. | A second source of Modifiers, or anything that must react when they change. |
| **A Skill has no stable id.** The Skill bar holds node references. | One line per Skill, or the scene's file name, when needed. | Saving the Skill bar, or Skills gained during play. |
| **The pause menu and the Console agree on pausing by asking `Console.is_open()`** (`pause_menu.gd:49`, `:57`). | Two things pause. | A third thing that pauses (an inventory, a reward screen). Then one owner of `get_tree().paused`. |
| **The camera is a bare child of the Player** and shakes by its offsets (`hit_feedback.gd:42-46`). Two shakes at once fight over them. | One source of shake. | A second source, or any camera behaviour (look ahead, zoom). |
| **Aggro looks for the `player` body layer** (`aggro.tscn`, mask 2) while Skills look for hostile Hurtboxes. Two definitions of "hostile". | Two Factions, one player. | A pet, or a third Faction. Then Aggro asks `Faction`. |
| **A Character's Faction is handed down once**, in `_ready`. | Nothing changes Faction. | Charm. |
| **`Health.max_health` has no setter**: changing it later neither clamps nor signals (`health.gd:13-16`). | Nothing changes it after `_ready`. | Gear or a rarity that gives Health. |
| **Enemies are placed by hand**, straight under `World`. | The enemies spec defers spawning to "session and level structure". | With the level split above. |
| **Settings hold only booleans and forget on quit.** | One setting. | A settings screen. |

### Known ceilings

None of these is a problem at today's numbers. Measure on the phone before changing any. Each deserves a `ponytail:` comment in the code naming the ceiling, so it is found when it matters.

- **Each Standee has its own material** (`standee.tscn:7`, `resource_local_to_scene`) and sets its texture and flash shader parameters every frame whether or not they changed (`standee.gd:103-128`, `155-156`). Forty Enemies are forty materials and forty `_process` calls. `HealthBar` already shows the cheaper pattern: a shared material with a per-instance shader parameter (`health_bar.gd:13`). The texture can't be per instance, so that route needs a sprite sheet per kind.
- **A chasing Enemy sets its agent's target every physics frame** (`enemy.gd:80`), which asks for a new path each time. The enemies spec expects 20 to 40 on screen and doesn't rule out more.
- **`Hurtbox.around` returns at most 32** (`hurtbox.gd:58`), unsorted. A Skill around the player in a large pack silently misses the rest, and Auto-aim's "nearest" is the nearest of whichever 32 came back.
- **Each Snapshot writes a "why" line for every Modifier** (`snapshot.gd:36`), and there are two Snapshots per activation (one to aim, `player.gd:192`, one to activate) and two per drag event (`skill_bar_hud.gd:123`, `153-155`). With a few hundred Modifiers that is a few hundred formatted strings per thumb movement. Making `why` something the Snapshot works out when asked removes it.
- **`modifier not in counted`** and the tag pass's `not in _applied` are a scan inside a loop.

## Small traps

One-line hazards for whoever writes the next Skill or component.

- **`range` hides GDScript's `range()`** in every Skill script (`skill.gd:46`). `for i in range(3)` inside a Skill fails. `for i in 3` works.
- **A hitstop sets `Engine.time_scale` to 0**, and `enemy.gd:126` guards its division against a `delta` of 0 for that reason. Every later component that divides by `delta` needs the same guard. Worth a line in the conventions.
- **`HitFeedback` ends a hitstop by setting the time scale to 1.0** (`hit_feedback.gd:52`). Anything else that changes the time scale (slow motion) is overwritten.
- **`HitFeedback` is a Resource that tweens the camera and changes engine time**, reached through a static `shared()`. It is a third global service in everything but name. The conventions list two autoloads. Either form is fine; the conventions should say which this is.
- **`Health.current` is "read only" by comment** (`health.gd:15`). Nothing stops a write.
- **Each Skill script must remember `@tool` and guard its code with `Engine.is_editor_hint()`** (`skill.gd:7-8`). `attack.gd:18-19` already runs its `@onready` lines inside the editor.

## Not recommended

Things a review like this often proposes. Each would add more than it removes at this size.

- **A generic state machine or behaviour tree for Enemies.** One script per behaviour (finding 5) until several exist to compare.
- **Skill definitions as a second family of Resources beside the Skill scenes.** A Skill scene already is its data, editable in the editor. A scene can be instantiated off the tree to read its title and icon if a screen ever needs a Skill the Character doesn't have.
- **An event bus autoload.** Signals up and calls down are followed everywhere and are enough.
- **A general system for a Character's numbers** before gear exists (see R8).
- **Moving touch aiming from `SkillBarHud` into `Controls`.** The glossary puts touch under Controls and the code puts it in the HUD. The buttons are HUD by nature, and the split works.

## Decisions this report reopens

So nobody overrides a recorded decision without noticing.

| Decision | Recorded in | This report |
|---|---|---|
| No base scene for Enemies until a second kind exists. | `.scratch/enemies/spec.md`, Decisions | Reopened (finding 1): the player and the Enemy are already two. |
| A hit reports its direction and Snapshot, "nothing else". | `.scratch/factions-health/spec.md`, rule 3 | Extended (finding 3): one `Hit` object that also names its dealer. |
| The ball is a child of the Fireball Skill. | `.scratch/combat/spec.md`, Decisions | Reopened (findings 3 and 4): it must outlive what fired it. |
| Skills as settings on shared pieces wait for the third or fourth Skill. | `.scratch/deepen-skills/spec.md`, Out of scope | Kept. Only the projectile's ties to Fireball go now. |
| Aim lives in Player; no Aim component. | `.scratch/deepen-skills/spec.md`, item 4 | Kept. Only `facing` moves to Character. See R2 for what an Aim holds. |
| Where Modifiers come from is decided with the second source. | `.scratch/skill-tags/spec.md`, Deferred | Kept. The list moves to Character. |
| A tag-changer's number changes are their own pool; a Modifier applies once. | `.scratch/skill-tags/spec.md`, rules 4 and 6 | Not reopened. R3 and R4 ask the developer to confirm two consequences. |

No ADR is contradicted.

## Suggested order

1. **Finding 6** (tags named once, the content test, the enum rule). Independent of everything else, small, and it protects all later content.
2. **Finding 1** (Character, Stagger, Skills node, base scene), with **finding 8** riding along.
3. **Finding 2** (a Skill knows its Character) and **finding 7** (`can_activate`). Small, and they need finding 1.
4. **Findings 3 and 4** together (`Hit`, then the shared projectile).
5. Settle **R1** and **R2** with the developer.
6. **Finding 5** (Enemy behaviour), in the same step as the first Enemy Skill, which is its first real user.
7. The level split, when its moment comes.

R3 to R8 are asked when the system they belong to is designed: R5 and R6 with the first Enemy Skill, R3, R4 and R8 with gear, R7 with Damage types.
