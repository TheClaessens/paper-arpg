# Hit

Status: ready-for-agent

Tickets 01 to 05 are built on the recommended answers to the open rules, which the developer confirms when reading this step's PR. Ticket 06 is the developer's.

A hit becomes a **Hit** (a new glossary term): one small object per activation of a **Skill**, holding the activation's **Snapshot**, the **Character** that dealt it and whether its impact freezes the world. It is fixed once made and lands itself (`Hit.land()`), the same Hit on every **Hurtbox** the activation reaches, so what lands a hit no longer has to be the Skill node. `Hurtbox.take_hit(hit, direction)` and `hit_taken(hit, direction)` replace the two-argument forms, and `Skill._hit()` replaces `Skill._land_hits()`. Only a Hit that lands on an **Enemy** freezes the world and shakes the screen (plan.md decision 7): a Hit on the player, once the player can be hit, shows only on the player's **Standee**. `Hurtbox.around()` finds up to 128 Hurtboxes instead of 32 and warns when it fills up. Nothing changes in play today: no Skill hits the player yet, and no query reaches 32.

Step 9 of `.scratch/future-proofing-review/plan.md`, on branch `hit`, stacked on step 8 (`enemy-base`) as the plan stacks every step (decision 8). It needs step 7 (`.scratch/skill-character/spec.md`); step 8 changes no script. Step 10 (`ball-in-world`) builds on it. Sources: `.scratch/future-proofing-review/analysis/hit-pipeline.md` sections 2, 4, 5, 8 and 10, briefs C and E, work packages HP2 and HP4, each claim checked against the code at `8797660` and against the specs of steps 1 to 7. Line numbers are `8797660`'s; steps 1, 2, 6 and 7 move lines in some of these files, so find each line by its text. Where this spec departs from the analysis is listed near the end.

Words: "the impact" is Hit feedback's freeze and screen shake together, what `HitFeedback.play_impact()` plays; "hitstop" is the freeze's name in code. "Dealer" is the code's word for the Character that dealt a Hit (open rule 1).

## What changes and why

Today a hit is two loose arguments. A Skill lands it with `Skill._land_hits(hits, snapshot, freezes)` (`skill.gd:146-157`): each Hurtbox in `hits` gets `take_hit(direction, snapshot)` (`hurtbox.gd:13-20`), which emits `hit_taken(direction, snapshot)` (`:8-10`) to its Character, and the Skill plays the impact through its own viewport. After step 6 the one receiver is `Character._on_hit_taken(direction, snapshot)`. Three things the next steps need can't be said that way:

- **Who dealt it.** An Enemy that turns on whoever hit it, kill credit, leech: each needs the Character that dealt the hit, and each new fact on a hit would change the signature of `take_hit`, `hit_taken` and every receiver.
- **Something other than the Skill landing it.** Step 10's ball must land its hit after its Skill and Character are gone. `_land_hits()` is a method of the Skill node and plays the impact through the Skill's viewport.
- **Which hits freeze the world.** `_land_hits()` plays the impact for whatever it landed on. Once Enemies have Skills, every hit on the player would freeze the game for a hitstop: the analysis estimates 31% of the time with three zombies swinging (brief C). Decision 7: only hits on an Enemy freeze and shake.

| | After step 8 | After this step |
|---|---|---|
| What a hit is | two arguments: a direction and the activation's Snapshot | a `Hit` (Snapshot, dealer, freezes), and a direction for each Hurtbox |
| What lands it | `Skill._land_hits()`, through the Skill's viewport | `Hit.land()`, through the viewport of an Enemy's Hurtbox it landed on |
| The Hurtbox | `take_hit(direction, snapshot)`, `hit_taken(direction, snapshot)` | `take_hit(hit, direction)`, `hit_taken(hit, direction)` |
| The Character hit | `Character._on_hit_taken(direction, snapshot)` | `Character._on_hit_taken(hit, direction)` |
| Attack | `_land_hits(hits, snapshot)` | `_hit(snapshot).land(pushes)` |
| Fireball | `_land_hits()` at each ball contact, with the throw's Snapshot | one Hit per throw, landed at each ball contact |
| Which landings play the impact | any that landed | one that landed on an Enemy |
| `Hurtbox.around()` | at most 32, silently | at most 128, with a warning when full |

`Hurtbox.around()` rides along because it is in the same file: it asks the physics engine for at most 32 results (`hurtbox.gd:58`), so with more hostile Hurtboxes within reach a swing, or a later area Skill, misses the rest, and Auto-aim's nearest is the nearest of those 32. The enemies spec expects "maybe 20–40 on screen", and Fireball's Auto-aim asks within its Range of 10.

## Assumed of steps 5 to 8

- **Step 6** (`.scratch/character/spec.md`): `Character._on_hit_taken(direction, snapshot)` is the one place a hit lands on a Character, connected in `Character._ready()` to `hurtbox.hit_taken`, and it flashes and squashes every Character hit. `Enemy._die()` still takes the Hurtbox off every layer. Its open rule 1 is assumed answered a (a Stagger of 0 does nothing); only the Stagger glossary entry depends on it, and this step only capitalises "hit" in whatever wording step 6 settled. Its open rule 2 is assumed answered a (`player.tscn` sets `faction = 0`); either answer puts the player's Hurtbox, the day it has one, on the player's layer.
- **Step 7** (`.scratch/skill-character/spec.md`): `Skill.character` exists, and `try_activate()` asserts that a Skill has one (its open rule 5 as recommended), so `_hit()` doesn't assert again. The hitting tests use the player's own Skills: `_players_attack()` in `test_attack.gd`, `_players_fireball()` in `test_projectile.gd`, and the player's Attack in `test_enemy_death.gd`'s `before_each`. `test_skill.gd`'s `before_each` Skill and its two landing tests are as on `8797660`.
- **Step 8** (`enemy-base`): `zombie.tscn` keeps its path and a node named `Hurtbox`, so every test that instances it is unchanged.
- **Step 5** (`.scratch/game-scene/spec.md`): `scenes/game.tscn` is the main scene, and the Player's Camera is in the same SubViewport as every Hurtbox, so the impact shakes that camera through a Hurtbox's viewport as it does through a Skill's today.
- **Steps 1 and 2**: Snapshot's fields refuse writes with `assert(false, "A Snapshot never changes")`, the pattern the Hit follows, with one difference for the dealer (open rule 2). `projectile.gd` reads `Fireball.PROJECTILE_SPEED` and `SkillTag.PIERCE`.

## The rules

1. **One activation, one Hit.** A Skill that hits makes one Hit for the activation, with `Skill._hit()`, and lands that same Hit on every Hurtbox the activation reaches: each one a swing sweeps, and both a Pierce ball passes.
2. **A Hit carries the activation's Snapshot, the Character that dealt it, and whether its impact freezes the world**, and nothing else. Where it pushes is not on the Hit: it differs per Hurtbox, so it goes with the Hit to each one (`take_hit(hit, direction)`).
3. **A Hit never changes.** Assigning any of its fields leaves the Hit as it was and, in a debug build, fails an assertion, "A Hit never changes" (open rule 2). What a Hit does to a Character (today its Damage, knockback and Stagger; later, say, Damage after resistances) is worked out by that Character and written nowhere on the Hit.
4. **A Hit's dealer** is the Character whose Skill made it, or null: in a Hit made without one (open rule 3), and once that Character has been freed, as an Enemy is after its sink. Reading it never gives a freed Character (open rule 2). Every Hit a Skill makes names the Skill's Character.
5. **A Hit lands itself** (`Hit.land(pushes)`): on each Hurtbox it is given, pushing along that Hurtbox's direction, and it says whether it landed on any. A Hurtbox off every layer (its Character has died) misses: its Character takes nothing and shows nothing. `Hurtbox.take_hit(hit, direction)` says the same for one Hurtbox.
6. **Only a Hit on an Enemy plays the impact** (plan.md decision 7). If, in one `land()` call, the Hit landed on at least one Hurtbox that was on the Enemies' layer when the Hit reached it, the impact plays once: the screen shakes, and the world freezes for the hitstop if the Hit freezes (a projectile's doesn't). Otherwise nothing plays and the game keeps running: a landing on nothing, on Characters that have died, or on Characters of the player's Faction. The killing Hit on an Enemy plays it like any other (open rule 4).
7. **Every Character a Hit lands on shows it itself**: it takes the Hit's Damage, starts its Stagger if it has one, and its Standee flashes and squashes (step 6's `Character._on_hit_taken()`, which reads the Hit now). The player too, the day it has a Hurtbox: its Health drops and its Standee flashes, and nothing freezes.
8. **`Hurtbox.around()` finds up to 128 Hurtboxes** (`Hurtbox.MOST_FOUND`), in no particular order, and prints a warning when it finds that many, since any more were left out (open rule 6).

Nothing else changes in play.

## How the impact is decided

**Where.** In `Hit.land()`, the one call every Hit passes through on its way to Hurtboxes: the Attack's now, Fireball's lambda now, the ball itself in step 10.

**When.** Once per `land()` call, after every Hurtbox in the call has taken the Hit, and only if at least one it landed on is an Enemy's. One swing through three zombies freezes once; a Pierce ball lands its Hit in two calls, one per zombie, and shakes twice, as today.

**How "an Enemy" is asked.** By the Hurtbox's layer, read before the Hurtbox takes the Hit:

```gdscript
var on_enemy := hurtbox.is_of(Faction.Id.ENEMIES)
```

In code review the question moved into `Hurtbox` (`is_of()`), so no code outside the Hurtbox reads its physics layer as game state.

- **The layer is the Faction.** `Character._ready()` puts its Hurtbox on `Faction.layer(faction)` (step 6), and an Enemy is "a Character of the Enemies' Faction" (GLOSSARY.md). Skills already find Hurtboxes by these layers (`hostile_mask()`), so what a Skill aims at and what plays the impact read the same fact.
- **Not the Character.** A Hurtbox has no way to its Character but reaching up (`get_parent()`, `owner`), which "Call down, signal up" rules out, and a test's bare Hurtbox has none. Asking the Character's class (`is Enemy`) would also disagree with the glossary once charm exists: a charmed Enemy fights for the player.
- **Not the dealer.** Decision 7 is about what was hit, not who dealt it. A dealer can be gone when a ball lands (step 10), and a Hit made in a test has none.
- **Before the Hit lands.** An Enemy's death takes its Hurtbox off every layer inside `take_hit()`: `hit_taken` runs `Character._on_hit_taken()`, whose Damage makes `Health` emit `died`, which runs `Enemy._die()`, which sets `hurtbox.collision_layer = 0`, all before `take_hit()` returns. Asked after, the killing blow would never freeze (open rule 4).

**Why it holds later.**

- **An Enemy's Hit on the player** (the first Enemy Skill): the player's Hurtbox is put on the player's layer, so nothing plays. The player's Standee flashes and squashes and its Health bar drops (rule 7); the game keeps running however many zombies swing. An Enemy's projectile plays nothing either, whatever its `freezes`.
- **A pet** of the player's Faction: an Enemy's Hit on it plays nothing; its own Hits on Enemies play the impact like the player's (open rule 5).
- **An Enemy's Hit on another Enemy** can't happen: a Skill hits only Factions hostile to its Character's.
- **Charm**: when charm moves a Hurtbox to another Faction's layer (its trigger in plan.md), the rule follows the Hurtbox's Faction with it.

## The change, file by file

The sketches show shape and the doc comments to use; the implementer writes the code.

### `skills/hit.gd`, new (tickets 01, 02, 04)

As it stands after ticket 04:

```gdscript
class_name Hit
extends RefCounted
## A Hit (see GLOSSARY.md): what one activation of a Skill does to each Hurtbox it reaches. The
## Skill makes it with Skill._hit() and lands it with land(), the same Hit on every Hurtbox the
## activation reaches. So it never changes: its fields can't be replaced, and each Character hit
## works out from it what it does to them and writes nothing back.

## The activation's Snapshot: the Character hit reads Damage, Knockback and Stagger from it.
var snapshot: Snapshot:
	get:
		return _snapshot
	set(_value):
		assert(false, "A Hit never changes")
## The Character that dealt it, or null: none was given, or that Character has been freed since
## (an Enemy is, once it has sunk). Never a freed Character.
var dealer: Character:
	get:
		return _dealer.get_ref() as Character
	set(_value):
		assert(false, "A Hit never changes")
## Whether its impact freezes the world. A projectile's doesn't.
var freezes: bool:
	get:
		return _freezes
	set(_value):
		assert(false, "A Hit never changes")

var _snapshot: Snapshot
var _dealer: WeakRef # a freed dealer reads as null: a typed getter can't return a freed one
var _freezes: bool


## A Hit made as `hit_snapshot`, dealt by `hit_dealer` (or null for none), whose impact freezes
## the world if `hit_freezes`. Skills make theirs with Skill._hit().
func _init(hit_snapshot: Snapshot, hit_dealer: Character, hit_freezes: bool) -> void:
	_snapshot = hit_snapshot
	_dealer = weakref(hit_dealer) # an empty WeakRef for null
	_freezes = hit_freezes


## Lands it on each Hurtbox in `pushes`, pushing each along its direction (a unit vector on the
## ground), and says whether it landed on any: a Hurtbox off every layer (its Character has died)
## misses. If it landed on an Enemy, the impact plays once, however many it landed on: the screen
## shakes, and the world freezes if `freezes`. On any other Character it shows only on that
## Character (see Character._on_hit_taken()), and the game keeps running.
func land(pushes: Dictionary[Hurtbox, Vector3]) -> bool:
	var landed := false
	var impact_viewport: Viewport = null # the viewport of an Enemy's Hurtbox it landed on
	for hurtbox in pushes:
		# Asked before it lands: the killing Hit takes its Enemy's Hurtbox off every layer.
		var on_enemy := hurtbox.is_of(Faction.Id.ENEMIES)
		if hurtbox.take_hit(self, pushes[hurtbox]):
			landed = true
			if on_enemy:
				impact_viewport = hurtbox.get_viewport()
	if impact_viewport:
		HitFeedback.shared().play_impact(impact_viewport, freezes)
	return landed
```

- **Ticket 01** writes the class with three plain fields (`var snapshot: Snapshot`, `var dealer: Character`, `var freezes: bool`, the dealer's doc reading "The Character that dealt it, or null in a Hit made without one."), `_init` setting them, and `land()` playing the impact as `_land_hits()` does today: once, if any landed, through the viewport of a Hurtbox it landed on. The class doc's last sentence says only that each Character hit works out what the Hit does to it and writes nothing back.
- **Ticket 02** gives `land()` the Enemy condition and the doc above.
- **Ticket 04** makes the fields properties over private fields, the dealer held by a `WeakRef`, as above (open rule 2), and the class doc says the fields can't be replaced.
- **No more fields.** Each has a reader: the Character hit reads `snapshot`, `land()` reads `freezes`, and `dealer` is what the next steps read (the tests read it now). Nothing for leech, reflect, kill credit or resistances.
- **Why a `RefCounted`**, as Snapshot is: plain data that lives as long as something holds it, the Skill's call now and a ball in flight in step 10.

### `characters/hurtbox/hurtbox.gd` (tickets 01, 03)

Ticket 01:

- **The class doc** (`:3-6`): "Skills find it on the layers hostile to their Faction" becomes "hostile to their Character's Faction" (a Skill has no Faction since step 7), and "a hit is reported up to the Character through `hit_taken`" becomes "a Hit that lands on it is reported up to the Character through `hit_taken`".
- **The signal** (`:8-10`):

  ```gdscript
  ## A Hit landed on it, pushing along `direction` (a unit vector on the ground). The Character
  ## reads what the Hit does to it from `hit`.
  signal hit_taken(hit: Hit, direction: Vector3)
  ```

- **`take_hit`** (`:13-20`), the same body with the new arguments:

  ```gdscript
  ## Takes `hit`, pushing along `direction`, and says whether it landed: off every layer (its
  ## Character has died) it misses, so a second Hit in the frame that killed the Character reports
  ## nothing. Hit.land() calls it on each Hurtbox; if the Hit landed on an Enemy it then plays the
  ## impact.
  func take_hit(hit: Hit, direction: Vector3) -> bool:
  	if collision_layer == 0:
  		return false
  	hit_taken.emit(hit, direction)
  	return true
  ```

Ticket 02 (moved here in code review), `is_of()` after `take_hit()`: the question whether a Hurtbox is of the Enemies' Faction, which `Hit.land()` asks before it lands.

```gdscript
## Whether it is on `faction`'s layer: its Character is of that Faction and can still be hit.
## Off every layer (its Character has died) it is of none.
func is_of(faction: Faction.Id) -> bool:
	return collision_layer & Faction.layer(faction) != 0
```

Ticket 03, a constant after the signal and the cap in `around()` (`:46-62`):

```gdscript
# ponytail: one physics query, capped at MOST_FOUND and in no order. Past that a Skill misses the
# rest and Auto-aim's nearest is the nearest of those found; around() warns. Ask in rings around
# the centre, or keep a list of Hurtboxes, if a pack ever gets that big.
## The most Hurtboxes around() finds at once.
const MOST_FOUND := 128

...

## Every Hurtbox in `world` on the layers in `mask` with any part of it within `reach` of
## `centre`, up to MOST_FOUND of them, in no particular order: a warning says when that many were
## found, since any more were left out. The physics engine finds them: the sphere looks for areas
## only, on `mask` only.
static func around(world: World3D, centre: Vector3, reach: float, mask: int) -> Array[Hurtbox]:
	... # the sphere and the query, as now
	var results := world.direct_space_state.intersect_shape(query, MOST_FOUND)
	if results.size() == MOST_FOUND:
		push_warning("Hurtbox.around() found its most, %d Hurtboxes: any more were left out." % MOST_FOUND)
	var hurtboxes: Array[Hurtbox] = []
	for result in results:
		... # as now
```

`nearest()` and `nearest_to()` don't change; `nearest()` gets the cap through `around()`.

### `skills/skill.gd` (ticket 01)

- **`_land_hits()`** (`:146-157`, the file's last method) goes. In its place:

  ```gdscript
  ## This activation's Hit: made as `snapshot` and dealt by the Skill's Character. A Skill that hits
  ## makes one per activation and lands that one on every Hurtbox it reaches (see Hit.land()), at
  ## once or, for a ball, as it flies. `freezes`: whether its impact freezes the world; a
  ## projectile's doesn't. For the Skills themselves.
  func _hit(snapshot: Snapshot, freezes := true) -> Hit:
  	return Hit.new(snapshot, character, freezes)
  ```

- **`character`'s doc** (step 7's) gains a sentence at its end: "Its Hits name it as their dealer (see _hit())."

Nothing else in the file: `try_activate()` already asserts that the Skill has a Character before `_activate()` can call `_hit()` (step 7).

### `skills/attack/attack.gd` (ticket 01)

In `_activate()` (`:42-48`) the local `hits` becomes `pushes`, since "hits" would now read as several Hits, and the last line becomes:

```gdscript
	_hit(snapshot).land(pushes)
```

A swing that finds nothing still makes its Hit and lands it on nothing, which plays nothing, as `_land_hits({})` did.

### `skills/fireball/fireball.gd` (ticket 01)

The smallest change that keeps one Hit per throw while the ball still belongs to the Fireball node and still reports back to it. `_activate()`'s `ball.hit.connect(...)` line (`:37`) becomes two:

```gdscript
	var ball_hit := _hit(snapshot, FREEZES) # one Hit for the throw: a Pierce ball lands it twice
	ball.hit.connect(func(hurtbox: Hurtbox) -> void: ball_hit.land({hurtbox: facing})) # pushed along the throw
```

The Hit is made once, at the activation, and the lambda keeps it, so both landings of a Pierce ball land the same Hit (rule 1). Every other line of `_activate()` stays, `ball.snapshot = snapshot` included: the ball still reads its Projectile speed, Range and Pierce from it.

- **The class doc**'s last sentence (as step 2 leaves it) becomes: "Each Hurtbox it touches takes the throw's one Hit, with the same Hit feedback as any other Skill except the hitstop: a projectile's Hit doesn't freeze the world."
- **`FREEZES`' doc** (`:10`) becomes: "Whether the throw's Hit freezes the world: a projectile's doesn't."

**What step 10 changes here** (its spec decides how): the ball carries `_hit(snapshot, FREEZES)` itself, so `ball.snapshot = snapshot`, the `ball_hit` line and the lambda go, and the ball moves out from under the Fireball node (`ball.top_level = true`, `add_child(ball)`) to beside the Character in the world.

### `skills/fireball/projectile.gd` (ticket 01)

Only the class doc's last sentence (`:7-8`): "It reports a Hurtbox it touched with `hit`; that Skill decides what the hit does." becomes "It reports a Hurtbox it touched with `hit`, and that Skill lands the throw's Hit there." The signal, the `snapshot` field and Pierce stay as they are. Step 10 removes the signal and the `snapshot` field (the ball reads `hit.snapshot`), and spends Pierce only on a Hit that landed.

### `characters/character.gd` (ticket 01)

- **The class doc** (step 6's): "a hit on its Hurtbox lowers its Health, starts its Stagger and flashes and squashes its Standee" becomes "a Hit on its Hurtbox …".
- **`_on_hit_taken`** (step 6's), the same three steps reading the Hit's Snapshot:

  ```gdscript
  # A Hit on its Hurtbox, pushing along `direction` (a unit vector on the ground): the one place a
  # Hit lands on a Character, whoever it is. Damage first, then the Stagger, then the Standee. What
  # it takes is worked out here and written nowhere on the Hit, which lands unchanged on the next
  # Hurtbox. The world's part of Hit feedback, the freeze and the shake, is Hit.land()'s.
  func _on_hit_taken(hit: Hit, direction: Vector3) -> void:
  	var snapshot := hit.snapshot
  	... # step 6's body, unchanged
  ```

`_ready()`'s `hurtbox.hit_taken.connect(_on_hit_taken)` stays: the method follows the signal's new arguments.

### `skills/hit_feedback.gd` (ticket 02)

Docs only. The class doc (`:3-8`) becomes:

```gdscript
## Hit feedback (see GLOSSARY.md): how the game shows the moment a Hit lands. Game-wide, not
## per Skill: no game system changes it, and melee and ranged hits felt the same in the tuning
## study the values started from (see .scratch/combat/spec.md). One shared set,
## `hit_feedback.tres`, serves everything: shared() returns it. Tune it in the editor. How hard a
## Hit pushes (knockback, Stagger) belongs to the Skill. The Character hit shows the flash and
## squash (see Character._on_hit_taken()); Hit.land() plays the impact, hitstop and screen shake,
## and only for a Hit that landed on an Enemy. A projectile's Hit shakes the screen but doesn't
## freeze the world.
```

`flash`'s doc (`:12`): "The hit Enemy turns white this long." becomes "The Character hit turns white this long." `play_impact()`'s doc (`:35`): "The impact of a hit: …" becomes "The impact of a Hit on an Enemy (see Hit.land()): …", the rest as it is.

### Unchanged on purpose

- **`HitFeedback`'s code**: `play_impact(viewport, freezes)`, the hitstop counter and the shake stay. Moving its runtime into a piece the game scene owns waits for its trigger (Out of scope).
- **`characters/enemy/enemy.gd`, `characters/player/player.gd`**: no code. A dead Enemy's Hurtbox still leaves its layer in `Enemy._die()`, which is what `take_hit()` and `land()` read. Ticket 05 capitalises "hit" in two of `enemy.gd`'s doc comments.
- **`characters/faction.gd`**: `layer()` already answers what `land()` asks.
- **Every scene and resource**: no change, so no resave.

## Tests

Run one file with `godot --headless --path . -s addons/gut/gut_cmdln.gd -gselect=test_<subject>.gd -gexit`, then `tools/check.sh`. Write each new test first.

**Moved (ticket 01).** `test_skill.gd`'s two landing tests (`:29-40`) go to a new `tests/test_hit.gd`, and with them `_zombie_at()` (`:22-26`), `ZombieScene` (`:6`) and the `after_each` that resets the time scale (`:18-19`); `test_skill.gd` keeps a copy of one only if a test left there uses it. Each Hit is made by hand, `Hit.new(snapshot, null, true)`, from a helper Snapshot that carries every number the Character hit reads:

```gdscript
## A Snapshot with the numbers a Character hit reads: Character._on_hit_taken() asks for all three.
func _snapshot(damage: float, knockback: float, stagger: float) -> Snapshot:
	return Snapshot.new([], {Skill.DAMAGE: damage, Skill.KNOCKBACK: knockback, Skill.STAGGER: stagger}, [])
```

- `test_each_enemy_is_pushed_its_own_way` keeps its name, its zombies and its assertions, with `Hit.new(_snapshot(0.0, 0.35, 0.05), null, true).land({...})` for `skill._land_hits({...}, skill.snapshot([]))`.
- `test_no_hits_no_impact` becomes `test_landing_on_nothing_plays_no_impact`: `land({})` returns false and the time scale stays 1.

What stays in `test_skill.gd`: its `before_each` loses `skill.knockback` and `skill.stagger` (only the landing tests read them), and its header (`:1-4`) becomes "A Skill: it warns without a Cooldown, try_activate() is the one way to set it off, and its numbers are what Modifiers change. Landing its Hit is test_hit.gd's." `tests/test_hit.gd` starts with "A Hit lands itself: each Hurtbox it lands on tells its Character, which is pushed along its own direction. The impact plays once per landing, and only when the Hit landed on an Enemy. A Hit never changes, and a dealer that is freed reads as none."

**A call only (ticket 01).**

- `test_enemy_death.gd`, `test_a_hit_after_the_killing_hit_misses` (`:59-66`): `zombie.hurtbox.take_hit(Vector3.RIGHT, snapshot)` becomes `zombie.hurtbox.take_hit(attack._hit(snapshot), Vector3.RIGHT)`.
- `test_enemy_death.gd`, `test_hit_feedback_plays_only_when_a_hit_landed` (`:69-74`): the local `hits` becomes `pushes`, and `attack._land_hits(hits, Snapshot.new(…))` becomes `attack._hit(Snapshot.new(…)).land(pushes)`. The file's header (`:2-3`) says "A Hit on it after that misses."
- `test_character.gd`, `test_without_a_stagger_a_hit_doesnt_push` (step 6's): its `take_hit(direction, snapshot)` becomes `take_hit(Hit.new(snapshot, null, true), direction)`.
- Then `grep -rn "take_hit\|hit_taken\|_land_hits" tests/`: any other test an earlier step added that calls the old forms changes the same way.

**Unchanged, and they check the change end to end:** `test_attack.gd`'s `test_a_swing_that_hits_two_enemies_freezes_the_world` (a Hit on Enemies still freezes) and `test_a_swing_hits_a_zombie_and_not_the_players_faction_in_the_same_spot` (it counts `hit_taken`, whatever its arguments); step 7's `test_an_enemys_swing_hits_the_players_faction_not_the_enemies`; every test in `test_projectile.gd`, among them `test_a_fireball_hit_knocks_back_without_freezing_the_world` (sampled in its own `ball.hit` connection, after Fireball's lambda has landed the Hit) and `test_a_piercing_ball_passes_through_the_zombie_it_kills_and_stops_at_the_next`; `test_health_bar.gd`; `test_hit_feedback.gd` (`play_impact()` doesn't change).

**New:**

| Test | File, ticket | What it proves | On the base (`enemy-base`) |
|---|---|---|---|
| `test_one_swing_lands_one_hit_dealt_by_the_player` | `test_attack.gd`, 01 | Rules 1, 2 and 4: the player's own Attack (`_players_attack()`) swung toward (1, 0, 0) at two zombies at (1, 0, ±0.4), each zombie's `hit_taken` recording its Hit: two Hits recorded, the same one (`assert_same`), whose `dealer` is the Attack's `character`. | Fails: `hit_taken` carries a direction and a Snapshot, no Hit. |
| `test_a_piercing_ball_lands_its_throws_one_hit_on_both` | `test_projectile.gd`, 01 | Rule 1 for a ball: the player's own Fireball (`_players_fireball()`) thrown toward (1, 0, 0) with Pierce through zombies at x 2 and 4, recording from their Hurtboxes' `hit_taken`: two Hits, the same one, dealt by the Fireball's `character`. It fails if Fireball made a Hit per contact. | Fails: no Hit. |
| `test_a_hit_on_the_player_neither_freezes_nor_shakes_the_world` | `test_hit.gd`, 02 | Rules 6 and 7, decision 7, the day the player has a Hurtbox, without one in `player.tscn`: a current `Camera3D` added to the test (asserted to be `get_viewport().get_camera_3d()`), a Player instance given a `hurtbox.tscn` instance before it enters the tree (physics off, as step 7's helper does), and a freezing Hit of 10 Damage landed on `player.hurtbox`: `land()` returns true, the player has 90 Health, the time scale is 1, and three process frames later the camera's `h_offset` and `v_offset` are both 0. | Fails: no Hit; `_land_hits()` there freezes the world and shakes the camera. After ticket 01 it fails too: the impact plays for any landing. |
| `test_the_killing_hit_on_an_enemy_still_freezes_the_world` | `test_hit.gd`, 02 | Rule 6, "when the Hit reached it": a zombie brought to 10 Health, a freezing Hit of 10 Damage landed on it: it dies, and the time scale is 0. (The zombie dies, so add it with `add_child_autoqfree`, as `test_enemy_death.gd` does.) | Passes after ticket 01, since any landing plays: a guard that ticket 02 asks the layer before the Hurtbox takes the Hit. |
| `test_around_finds_more_than_32` | `test_hurtbox.gd`, 03 | Rule 8: 33 `hurtbox.tscn` instances on the Enemies' layer at (0.5, 0, 0), two physics frames later: `Hurtbox.around(world, Vector3.ZERO, 1.0, ENEMIES)` finds all 33. | Fails: 32. |
| `test_around_warns_when_it_finds_its_most` | `test_hurtbox.gd`, 03 | Rule 8: `Hurtbox.MOST_FOUND + 1` such Hurtboxes: `around()` finds `MOST_FOUND`, and `assert_push_warning("found its most")` takes its warning. | Fails: no `MOST_FOUND`, no warning. |
| `test_a_hits_fields_cannot_be_replaced` | `test_hit.gd`, 04 | Rules 3 and 4: a freezing Hit made with no dealer; assigning a new value to each of `snapshot`, `dealer` and `freezes` reports "A Hit never changes" (three `assert_engine_error` calls, one per assignment, as `test_snapshot.gd`'s `test_a_snapshots_fields_cannot_be_replaced` does) and leaves each as it was: the same Snapshot (`assert_same`), the dealer still null, still freezing. | Fails after ticket 01: plain fields take the new values, and no error comes. |
| `test_a_dealer_that_is_freed_reads_as_none` | `test_hit.gd`, 04 | Rule 4: a Hit dealt by a `Character.new()` kept out of the tree names it (`assert_same`); after the Character's `free()`, `hit.dealer` is null itself, `assert_same(hit.dealer, null)`, and reading it reports no error. | Fails after ticket 01: `hit.dealer` is the freed object, which `assert_same` tells from null. Snapshot's pattern with a getter returning the dealer fails it with "Trying to return a previously freed instance." |

Helpers for the new tests: `test_hit.gd` preloads `player.tscn` and `hurtbox.tscn`; `test_hurtbox.gd` gets one helper that adds `count` Hurtboxes on the Enemies' layer at a spot, beside its `_player_hurtbox_at()`. Its header gains "up to Hurtbox.MOST_FOUND at once, with a warning when that many are found". One Player per test (step 7's rule): the Player test is the only one in `test_hit.gd` that makes one.

## Checking by hand

On this branch, and on the base (`enemy-base`) to compare. The tools run the game scene, `res://scenes/game.tscn`.

1. `tools/check.sh` passes.
2. **Play** `scenes/game.tscn` (F5). Swing at a zombie: it flashes, squashes and slides back, the world freezes for an instant and the screen shakes. Swing at two side by side: one freeze. Throw a Fireball at one: the screen shakes and nothing freezes. `modifier pierce on`, then a Fireball through the pack: it passes one zombie and stops at the second, two shakes, no freeze. Five swings kill a zombie: the fifth flashes it and freezes the world, then it sinks. All as on the base.
3. **A swing from where the player stands.** `godot --path . --resolution 1280x720 --script res://tools/screenshot.gd -- res://scenes/game.tscn "tp 19 4" "activate 1 1 0"` on the base and on the branch: in each `2_activate-1-1-0.png` the swing's wedge lies at the player, toward the zombie at (20, 4), whose Health bar shows the hit. The two pictures match.

Not by hand: a Hit on the player (no Enemy Skill and no player Hurtbox yet) and more than 32 Hurtboxes in one query (the Level has seven zombies). Their tests check them.

## Docs this reopens

**`GLOSSARY.md`**, committed with this spec on the branch (ticket 01's first commit).

- **Hit**, new, right before Hit feedback:

  > **Hit**:
  > What one activation of a Skill does to each Hurtbox it reaches. It carries the activation's Snapshot and the Character that dealt it, and lands unchanged on every Hurtbox the activation reaches: each Character hit works out what it does to them.
  > _Avoid_: Strike, damage event, attack (the Attack is a Skill)

- **Damage** (`:71-73`): "How much Health a Skill's hit takes away." becomes "How much Health a Skill's Hit takes away."; the rest stays.
- **Damage type** (`:75-77`): "What kind of damage a hit deals, such as fire." becomes "What kind of damage a Hit deals, such as fire."; the rest stays.
- **Hit feedback** (`:127-129`), decision 7:

  > **Hit feedback**:
  > How the game shows the moment a Hit lands so it feels solid: the Character hit flashes and squashes, and if it is an Enemy, the world freezes for an instant and the screen shakes. A projectile's Hit doesn't freeze the world, so a ball flying on through Enemies doesn't stutter, and a Hit on the player shows only on the player's Standee, so the game keeps running however many Enemies hit them. It is the same for every Skill otherwise, and no game system changes it. How far the Character hit is knocked back, and its Stagger, belong to the Skill.
  > _Avoid_: Juice, game feel, impact effects

- **Stagger**, as step 6 leaves it, with "hit" capitalised where it names the Hit. Under step 6's open rule 1 answered a:

  > **Stagger**:
  > The short time after a Hit when a Character slides with the knockback and doesn't walk. Another Hit restarts it, but a Hit whose Stagger is 0 doesn't stagger at all. The player, for now, isn't staggered.
  > _Avoid_: Stun, hitstun, flinch

- **Unchanged:** Hurtbox ("that Skills hit", "can't be hit": the verb), Faction ("their Skills hit each other": the verb), Pierce ("the first Enemy it hits": the verb; step 10 decides whether a Hit that missed spends Pierce), Health (no "hit"), Snapshot.

**`docs/agents/godot-conventions.md`**: a new section, "Frozen frames", after "Autoloads" (code review moved it there from the end of "Composition"), holding:

> `HitFeedback` is the only game code that sets `Engine.time_scale`: a hitstop sets it to 0, and the last hitstop to end sets it back to 1. While it is 0, every `delta` is 0, so a component that divides by `delta` returns early on 0, as `Stagger.next_velocity()` does.

**`.scratch/factions-health/spec.md`:**

- **Rule 3** (`:11`) becomes: "3. **A hit is a Hit** (`skills/hit.gd`): the activation's Snapshot, the Character that dealt it, and whether its impact freezes the world. Where it pushes goes with it to each Hurtbox (`take_hit(hit, direction)`). The Character that was hit reads Damage, Knockback and Stagger from the Snapshot and writes nothing back. Later effects (a burn, a curse) read their own numbers from the same Snapshot, and a fact a later hit needs is a new field on the Hit, so `take_hit` and `hit_taken` never change shape. (Reopened by `.scratch/hit/spec.md`: the dealer and the freeze joined the Hit; the Snapshot holds neither.)"
- **Requirement 3** (`:21`): "`take_hit(direction: Vector3, snapshot: Snapshot)` emits `hit_taken(direction, snapshot)` (call down, signal up)." becomes "`take_hit(hit: Hit, direction: Vector3)` emits `hit_taken(hit, direction)` (call down, signal up) and returns whether the Hit landed (since `.scratch/hit/spec.md`)."; the rest stays.
- **Requirement 4**, its second bullet (`:24`), becomes: "A Skill makes one Hit per activation (`Skill._hit()`), and `Hit.land()` takes `Dictionary[Hurtbox, Vector3]`, calls `take_hit` on each, then plays the impact once if it landed on an Enemy (since `.scratch/hit/spec.md`; it was `Skill._land_hits()`)."
- **Requirement 7**, as step 6 leaves it: "`health.damage(snapshot.number(Skill.DAMAGE))`" becomes "`health.damage(hit.snapshot.number(Skill.DAMAGE))`"; the rest stays.
- **Edge case 4** (`:49`), its last clause: "and `_land_hits` plays Hit feedback only when at least one hit landed." becomes "and `Hit.land()` plays the impact only when the Hit landed on at least one Enemy (since `.scratch/hit/spec.md`; it was `_land_hits`)."

**`.scratch/deepen-skills/spec.md`**, item 3 (`:11`): after "`_land_hits` says what it really does: one impact per call." add "(Since `.scratch/hit/spec.md` that is `Hit.land()`: one impact per call, and only for a Hit that landed on an Enemy. Whether it freezes is the Hit's, set by the Skill that made it.)" The rest of the item stays as history.

**`.scratch/combat/spec.md:101`** becomes: "  - **A Hit lands itself** (since `.scratch/hit/spec.md`; until then "Skill lands its own hits", `Skill._land_hits()`). A Skill makes one Hit per activation with `Skill._hit()`, and `Hit.land()` lands it on each Hurtbox, whose Character takes its Damage, knockback and Stagger, then plays the impact once per call, and only if it landed on an Enemy. Attack and Fireball both use it." `:81` ("One impact per use") still holds for Enemies and stays.

**Three doc comments in code** that name a hit as a thing: `enemy.gd:5` ("A hit on its Hurtbox lowers its Health by the hit's Damage" → "A Hit … the Hit's Damage"), `enemy.gd:109` ("the killing hit" → "the killing Hit"), `standee.gd:94` ("the hit's flash and squash" → "the Hit's flash and squash").

**An ADR: yes**, short. All three of the domain-modeling tests hold: the shape is costly to reverse once every Skill and receiver uses it; a data object that lands itself and plays feedback looks odd in this step, where only Fireball's lambda and the Attack land Hits (step 10 is why); and there were real alternatives, which the resistances to come would otherwise reopen. `docs/adr/0004-a-hit-lands-itself.md`:

```md
# A Hit lands itself, and the Character hit writes nothing back

One activation of a Skill makes one Hit, fixed once made: the activation's Snapshot, the Character that dealt it, and whether its impact freezes the world. The Hit lands itself on every Hurtbox the activation reaches and decides the impact in one place, so whatever carries it can land it: the Skill now, a projectile in flight after its Skill and Character are gone. Each Character hit works out what the Hit does to it and writes nothing back, because the same Hit goes on to the next Hurtbox.

## Considered Options

- **A hit as two loose arguments, landed by the Skill** (`take_hit(direction, snapshot)` and `Skill._land_hits()`, until `.scratch/hit/spec.md`). Rejected: a projectile can't land a hit once its Skill is gone, and each new fact on a hit, such as who dealt it, would change every receiver's signature.
- **Per-target results on the Hit**: Damage after resistances written back by the Character hit, or a Hit per Hurtbox to hold them. Rejected: a result written on the one Hit would reach the next Hurtbox it lands on, and a Hit per Hurtbox splits what is one activation's.

## Consequences

- A fact a later system needs, such as the parts of a Hit's Damage by Damage type, is a new field on the Hit, filled where the Skill makes it (`Skill._hit()`). No receiver changes.
- The Character that dealt a Hit can be gone when it lands; the Hit then names no dealer, and every reader of the dealer handles that.
- Which landings freeze and shake the world is decided in `Hit.land()` from what each Hurtbox was when the Hit reached it: only a Hit on an Enemy (`.scratch/future-proofing-review/plan.md`, decision 7).
```

**Not reopened:** the specs of steps 6 and 7, and resolved tickets such as `.scratch/factions-health/issues/01-faction-and-hurtbox.md`, which name `_land_hits` or `hit_taken(direction, snapshot)` as the plan or the history of their time. ADRs 0001 to 0003.

## Seams

Lines this step touches in files other steps touch, and what step 10 finds.

- **`skills/hit.gd`**, new. **Step 10 relies on three things, kept as written here:** `Hit.land(pushes: Dictionary[Hurtbox, Vector3]) -> bool`, which lands, decides the impact and says whether it landed on any; `Hurtbox.take_hit(hit: Hit, direction: Vector3) -> bool`; and `Skill._hit(snapshot: Snapshot, freezes := true) -> Hit`, the way a Skill makes this activation's Hit. It also finds: a Hit's `dealer` is null once its Character is freed, so a ball whose Character died mid-flight lands a Hit without a dealer and without an error (rule 4); and the impact's viewport is a Hurtbox's, so a ball in the world needs none of its own.
- **`skills/skill.gd`**: `_land_hits()` (`:146-157` on `8797660`, the file's last method) goes and `_hit()` takes its place; one sentence at the end of `character`'s doc (step 7's). Steps 1 and 7 change other lines (`SHORTEST_COOLDOWN`, `start_cooldown`, `try_activate`, `_notification`, `hostile_mask`), which this step keeps. Step 10 adds the method that puts a thing in flight beside the Character.
- **`skills/fireball/fireball.gd`**: the class doc's last sentence and `FREEZES`' doc, and the `ball.hit.connect` line with a line before it. Step 2 renamed the speed; step 10 rewrites `_activate()` (see "What step 10 changes here").
- **`skills/fireball/projectile.gd`**: the class doc's last sentence. Step 2 changed `:3`, `:14`, `:28` and `:48`; step 10 rewrites the file and finds the `hit` signal, the `snapshot` field and Pierce counted on every Hurtbox touched, as on `8797660`.
- **`skills/attack/attack.gd`**: the `hits` local and the last line of `_activate()`. No other step.
- **`characters/character.gd`**: one word in the class doc, and `_on_hit_taken()`'s comment, parameters and first line (step 6's method). Step 7 changes `_ready()`'s and `add_skill()`'s Skill lines, which this step doesn't touch.
- **`characters/hurtbox/hurtbox.gd`**: the class doc, the signal, `take_hit()`, a constant after the signal, and `around()`'s doc and query. No other step.
- **`skills/hit_feedback.gd`**: three doc comments. No other step.
- **`characters/enemy/enemy.gd:5`, `:109`, `characters/standee/standee.gd:94`**: one word each, in doc comments step 6 keeps.
- **Tests**: `test_skill.gd` loses `:1-40`'s landing part (step 1 added a test after `:83`, step 7 changed `_recording()` and appended tests, all kept); `test_enemy_death.gd` `:2-3`, `:59-74` (step 7 changed its `before_each`); `test_character.gd` (step 6's test); `test_attack.gd`, `test_projectile.gd` and `test_hurtbox.gd` gain tests at their ends. **Step 10 rewrites `test_projectile.gd`:** `test_a_piercing_ball_lands_its_throws_one_hit_on_both` records from the zombies' `hit_taken`, so it holds as written, but step 10's ball outlives the player and the test must then free it, as step 10 has every test that fires do.
- **`GLOSSARY.md`**: Hit (new), Damage, Damage type, Hit feedback, Stagger. Step 2 added Projectile speed, step 5 Level, step 6 Character and Stagger, step 7 Skill. Step 10 may add to Hit that a projectile carries its Hit even after the Character that dealt it is gone, and to Range.
- **`docs/agents/godot-conventions.md`**: a section "Frozen frames" after "Autoloads". Step 6 adds a paragraph to "Composition"; steps 2, 3, 5 and 7 edit other sections.
- **Other specs**: factions-health rule 3, requirements 3, 4 and 7 and edge case 4 (step 6 took requirements 1 and 7, step 7 requirement 2; this step changes only `snapshot.number` in 7); deepen-skills item 3; `combat/spec.md:101` (step 6 took `:104`; step 10 takes `:89`).
- **`docs/adr/0004-a-hit-lands-itself.md`**, new.

## Open rules for the developer

1. **"Hit" as a glossary term, and `dealer` in code** (plan.md's working answer, confirmed when reading the PR). The other word for the dealer, "source", already means where Modifiers come from (gear, talents) in the skill-tags spec. *Recommended: confirm.* Without the term, the code keeps `Hit`, the glossary's lowercase "hit" stays a plain word, and the new entry and the capitalised wording go.
2. **How a Hit stays fixed, and what a dealer that is gone reads as.**
   - **a. Refusing setters, the dealer held weakly** (recommended, ticket 04): each field is a property over a private field whose setter refuses writes, as Snapshot's are, and the dealer is held by a `WeakRef`, so `hit.dealer` is null once its Character is freed and never a freed object. About 18 lines more than plain fields, and two tests.
   - **b. Plain fields**, fixed by their doc and by review. `hit.dealer` then holds a freed Character once it is gone: `is_instance_valid(hit.dealer)` is safe, but a call, `is` or `as` on it is an error in a debug build, so each reader checks first.
   - **c. Snapshot's pattern word for word**, a getter returning the dealer itself: not workable. A property's getter returns with the property's type, and a typed return of a freed object is an error in a debug build ("Trying to return a previously freed instance."), so every read of a gone dealer would print an error and fail its test.

   *In play:* nothing today; the first reader of the dealer comes later (an Enemy that turns on whoever hit it, kill credit). *For that reader:* under a, `if hit.dealer:` and then anything; under b, `is_instance_valid(hit.dealer)` before any call, `is` or `as`, in every reader. *Why a:* the one place that knows a dealer can be gone handles it, once; and one Hit lands on several Hurtboxes in turn, so a write by one Character's rule would change the Hit the next one gets. Under b, ticket 04 keeps only the dealer's doc ("check `is_instance_valid()` before using it") and its test, which then asserts that `is_instance_valid(hit.dealer)` is false.
3. **A Hit made with no dealer.**
   - **a. Allowed** (recommended): `Hit.new(snapshot, null, freezes)`. It reads as a dealer that is gone, which every reader handles anyway (rule 4). Game code makes Hits only through `Skill._hit()`, whose Skill has its Character (step 7's assertion), so only tests make one without.
   - **b. Refused**, with an assertion in `_init`: tests then give a stand-in, `autofree(Character.new())`, as step 7's tests do for a Skill.

   *Why a:* refusing it protects no reader, since a dealer can be gone anyway, and costs every test that lands a Hit by hand a stand-in.
4. **The killing Hit on an Enemy.** Its death takes the Hurtbox off every layer inside `take_hit()` (see "How the impact is decided").
   - **a. It plays the impact like any other** (recommended, and today's): `land()` asks each Hurtbox's layer before the Hit lands. `Standee.sink()`'s doc counts on it: "a hitstop holds it still and the hit's flash and squash show first".
   - **b. It plays nothing**, unless another Enemy in the same landing lived: `land()` would ask after.

   *Why a:* the kill is the blow that should feel most solid; b would be an accident of order, not a rule.
5. **A pet's Hits.** The rule asks what was hit, not who dealt it. A pet of the player's Faction would freeze and shake the world with every Hit on an Enemy, as the player's own do, and an Enemy's Hit on the pet would play nothing.
   - **a. Leave it as the rule gives** (recommended), and decide with pets whether a pet's Hits should freeze (brief C left it open).
   - **b. Only the player's own Hits play the impact**: `land()` would also ask whether the dealer is the player, and a Hit whose dealer is gone (step 10's ball) would need an answer of its own.

   *Why a:* no pet exists, and the rule as written is the glossary's: a Hit on an Enemy.
6. **How far past 32, and how loud.**
   - **a. 128, and a warning** (recommended): over three times the 40 the enemies spec expects on screen. Jolt keeps the first 32 results in place and the rest on the heap, and stops the query once it has 128. A warning shows in the output and the debugger's Errors tab without stopping the game or failing a test.
   - **b. An error** (`push_error`): red, and GUT fails any test that fills the query. But a full query is content outgrowing a known ceiling, not a mistake in code.
   - **c. Another number**: the constant and its doc, nothing else.

   One more case: a query that finds exactly 128 warns although none may have been left out, since one query can't tell 128 from more. Asking for one more and keeping 128 would tell, for a line or two. *Recommended:* accept; the warning says "any more".

Settled by the plan or the brief, not open: decision 7 itself; the Hit holds only its Snapshot, its dealer and whether it freezes; `take_hit(hit, direction)` and `hit_taken(hit, direction)` keep reporting whether the Hit landed; Fireball's ball still belongs to the Fireball node in this step; no registry and no spatial index behind `around()`.

## Out of scope

| What | Trigger that brings it back |
|---|---|
| The ball carries its Hit, lands it itself, lives in the world, and spends Pierce only on a Hit that landed | Step 10 (`ball-in-world`) |
| The player's Hurtbox, and what an Enemy's Hit does to the player beyond Hit feedback (a Stagger, the player at 0 Health) | The first Enemy Skill |
| What an Enemy does when hit from outside its Aggro radius. The hook, now that a Hit names its dealer: `Character._on_hit_taken(hit, direction)`. An Enemy overrides it, calls `super()` first, and hands `hit.dealer`, when it isn't null, to whatever decides where it walks (the character analysis's `notice()`) | The first Enemy Skill |
| A Hurtbox that can be found but not hit; today death's layer does both | The first immunity: a Blink, a boss that can't be hit for a phase |
| Hit feedback's runtime in a piece the game scene owns; restoring the time scale it found; two shakes at once on one camera | Slow motion, or a second camera effect |
| A lighter shake, or a HUD cue, when the player is hit (brief C's options C and D) | Trying a zombie's Hits on the phone, after the first Enemy Skill |
| More on a Hit: its Damage by Damage type, whether it is critical, where it landed, which impact it plays (`freezes` becoming a kind of impact) | Damage types; critical hits; an effect at the point of contact; a third kind of impact, such as a burn's tick that plays none |
| Damage after resistances, kill credit, leech, reflect | Their systems. Resistances are worked out in `Character._on_hit_taken()` from `hit.snapshot` and the Character's own state, and written nowhere on the Hit (rule 3) |
| `Hurtbox.around()` in rings, or a list of Hurtboxes; its results in order | Its warning in play, or a Skill that needs the nearest Hurtboxes first |
| What a Hit on a third Faction (destructible pots, wildlife) plays | A third Faction |

## Where this departs from the analysis

- **The dealer can't use Snapshot's read-only pattern as is.** Section 2 makes the Hit's fields "read-only the same way" as Snapshot's, though its sketch has plain fields. A property's getter returns with the property's type, and a typed return of a freed object is an error in a debug build, so a getter returning the dealer would error once its Character is freed. Here the dealer is held by a `WeakRef` behind the getter (open rule 2). Under plain fields, the analysis's "check is_instance_valid() before using it" has to come before any `is` or `as` too: on a freed dealer, those are errors as well as a call.
- **Each Hurtbox is asked whether it is an Enemy's before it takes the Hit.** HP4's one condition, "a landed Hurtbox is on the Enemies' layer", read after `take_hit()` as the sketch's `landed` would be, drops the killing blow's freeze: the death clears the layer inside `take_hit()`. A test pins it.
- **Fireball makes its Hit once per throw.** HP2's `_hit(snapshot, FREEZES).land(...)` inside the lambda would make a Hit per contact, so a Pierce ball would land two Hits. Here `_activate()` makes it and the lambda lands it; a test pins it.
- **The moved landing tests need a full Snapshot.** They made theirs from a Skill; a hand-made one must carry Damage, Knockback and Stagger, which `Character._on_hit_taken()` reads with `number()`, which asserts on a missing name.
- **Decision 7's test needs no Hurtbox in `player.tscn`.** HP4 waited for the player's Hurtbox "for an end-to-end check"; the test gives a Player instance one before it enters the tree, and `Character._ready()` puts it on the player's layer as it will the day the scene has one.
- **The conventions line names `Stagger.next_velocity()`**: since step 6 the division by `delta` is there, not in `Enemy._slide()`, the analysis's example. (`Enemy._slide()` itself still exists: step 6's code review moved it back from `Character` to `Enemy`.)
- **More docs reopen**: factions-health edge case 4 and requirement 7 also name `_land_hits` and the receiver's Snapshot, and three doc comments in code say "hit" for the thing.
- **The constant is `MOST_FOUND`, and its warning has a test** (GUT 9.7.1's `assert_push_warning`); the analysis named it `MOST`.
- **Jolt checked.** The analysis read only the class reference for `intersect_shape`. The project runs Jolt, whose collector keeps as many results as asked, not a fixed 32 (engine fact 2).
- **The R6 hook is an override in `Enemy`**: `Character._on_hit_taken()` itself, shared by every Character, can't reach an Enemy's chase.
- **The glossary entry is shorter**, to the glossary's one-or-two-sentence rule, and leaves out what step 9 doesn't do yet: a projectile carrying its Hit after its Character is gone (step 10).

## Engine facts

Godot 4.7 class reference and manual, read on 2026-11-22, and the 4.7-stable source where marked.

1. **`PhysicsDirectSpaceState3D.intersect_shape(parameters, max_results = 32)`**: "The number of intersections can be limited with the max_results parameter, to reduce the processing time." The page says nothing about the order of results.
2. **Jolt keeps as many results as asked** (4.7-stable, `modules/jolt_physics/spaces/`). `JoltPhysicsDirectSpaceState3D::intersect_shape` passes `p_result_max` to a `JoltQueryCollectorAnyMulti<JPH::CollideShapeCollector, 32>`. The 32 is only the inline buffer the array reserves; `AddHit` keeps hits while there are fewer than the maximum and forces an early out once it is full. So a query asking for 128 gets up to 128, in the order Jolt meets them.
3. **`is_instance_valid(instance)`**: "Returns true if instance is a valid Object (e.g. has not been deleted from memory)." The answer is about the object, not about what holds the reference, so a freed Character held by a `RefCounted` Hit answers false.
4. **A freed object in typed code** (4.7-stable source). Holding one in a typed field is no error, and reading a plain field of another object compiles to a named get with no type check (`gdscript_compiler.cpp`). In a debug build these are errors: a typed return ("Trying to return a previously freed instance."), a typed assignment checked at run time ("Trying to assign invalid previously freed instance."), an `as` cast ("Trying to cast a freed object."), an `is` test and a method call (`gdscript_vm.cpp`). A property's inline getter is compiled with the property's type as its return type (`GDScriptAnalyzer::resolve_class_body`: `getter->return_type = member.variable->datatype_specifier`).
5. **`weakref(obj)`**: "Returns a WeakRef instance holding a weak reference to obj. Returns an empty WeakRef instance if obj is null." **`WeakRef.get_ref()`**: "Returns null if that object no longer exists." So `_dealer.get_ref()` is null for a dealer freed since. That an empty WeakRef's `get_ref()` is null too is not stated: `test_a_hits_fields_cannot_be_replaced` reads the dealer of a Hit made with none and checks it.
6. **Setters run on every assignment**, "even when accessed inside the same class"; "If you need direct access to the value, use another variable for direct access and make the property code use that name" (GDScript reference, Properties). Hence private fields that `_init` writes, as Snapshot has.
7. **Bitwise AND binds tighter than a comparison** (GDScript reference, the operators table), so `layer & mask != 0` is `(layer & mask) != 0`, as `test_faction.gd:7` already relies on.
8. **A signal runs its connections inside `emit()`** unless connected deferred: `CONNECT_DEFERRED` "Deferred connections trigger their Callables on idle time (at the end of the frame), rather than instantly." So `take_hit()` returns after the Character hit has taken the Hit and, for a killing Hit, after `Enemy._die()` has cleared the layer. `test_enemy_death.gd`'s `test_a_hit_after_the_killing_hit_misses` relies on the same.
9. **GUT 9.7.1** (`addons/gut/test.gd`, `gut_config.gd:57`): `assert_push_warning(text)` takes one `push_warning` containing the text; `failure_error_types` is engine, gut and push_error, so a warning nobody claims fails no test; a failed `assert()` is an engine error that `assert_engine_error(text)` takes; `wait_process_frames()` waits on idle frames, where the shake's tween runs.

## Done when

- [ ] `skills/hit.gd` holds the Hit: its Snapshot, its dealer, whether it freezes, and `land()`. Its fields can't be replaced, and a freed dealer reads as null (or as open rule 2 is answered).
- [ ] `take_hit(hit, direction)` and `hit_taken(hit, direction)` are the Hurtbox's only forms, and `Character._on_hit_taken(hit, direction)` reads `hit.snapshot`.
- [ ] `Skill._land_hits()` is gone and `Skill._hit()` makes the activation's Hit; the Attack lands one Hit per swing, Fireball one per throw.
- [ ] Only a landing on an Enemy plays the impact: a Hit on the player's Faction neither freezes nor shakes, and the killing Hit on an Enemy still freezes.
- [ ] `Hurtbox.around()` finds up to 128, warns when full, and has its `ponytail:` comment.
- [ ] Every test listed is moved or changed as listed, the new tests pass, and `tools/check.sh` passes.
- [ ] The docs above say what the code does, and a search for `_land_hits`, `take_hit(direction` and `hit_taken(direction` comes back clean in code and tests, and in `docs/` finds them only in ADR 0004's account of what was replaced.
- [ ] "Checking by hand" matches the base.

## Tickets

1. `issues/01-the-hit-lands-itself.md`: the Hit, its new shape on the Hurtbox, the Character and every Skill at once.
2. `issues/02-only-enemies-freeze-and-shake.md`: decision 7 in `Hit.land()`.
3. `issues/03-around-past-32.md`: `Hurtbox.around()` past 32, with a warning when full.
4. `issues/04-a-hit-never-changes.md`: the fields refuse writes, and a freed dealer reads as none.
5. `issues/05-reopened-docs.md`: the conventions, the other specs, three doc comments and the ADR.
6. `issues/06-check-and-pr.md`: the developer's checks by hand, `/code-review` and the PR.
