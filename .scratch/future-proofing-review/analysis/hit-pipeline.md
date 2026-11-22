# Hit pipeline and the Skill contract: findings checked, decisions, work packages

Analyst for the hit pipeline and the Skill contract. `master` at `8797660`, 2026-11-22. Read only: nothing was run (no Godot, no `tools/check.sh`). Line numbers are those of `8797660`. Engine behaviour was checked against the Godot 4.7 class reference (docs.godotengine.org/en/4.7, pages read today; quotes in "Engine facts relied on" at the end). "Needs a run" marks what only running can settle.

**Scope.** `skills/skill.gd`, `skill_bar.gd`, `attack/`, `fireball/` (with `projectile.gd`, `.tscn`), `hit_feedback.gd`/`.tres`, `characters/hurtbox/`, `characters/faction.gd`, and the callers in `player.gd`, `aim_marker.gd`, `enemy.gd`, `skill_bar_hud.gd`; their tests; the combat, factions-health, deepen-skills, aiming, remove-use-time and skill-tags specs. The other three analysts' files in this folder were read for the seams.

**Words.** *(proposed)* marks a term that isn't in `GLOSSARY.md`; each comes with a draft entry. "Dealer" (the Character that dealt a hit) and "the world" are plain words here, not proposed terms.

## In short

- **The one shape:** a Skill holds a reference to its Character instead of a Faction; one activation makes one **Hit** *(proposed)*, a small read-only object with the Snapshot, the dealer and whether its impact freezes; `Hurtbox.take_hit(hit, direction)`; a Hit lands itself (`hit.land(pushes)`), so a ball can carry it into the world and land it after its Skill and Character are gone. Skills make Hits and put things into the world through one base method each, so whatever is added later changes one place, not every Skill script.
- **Refuted:** Sol's claim that sibling order changes held-repeat timing (the period is the same; only the ready flash and a one-tick press window move), and Sol's "a long mobile frame can tunnel" (Godot steps physics at a fixed 1/60 s). **Overstated:** Fable's "adding the dealer later touches every Skill script", Fable's "Hurtbox needs its own can-be-hit state now", Sol's "`take_hit` should report whether it landed" (it already does; the ball never asks).
- **Projectile disagreement settled:** Fable is right about the contract (the ball carries its Hit, lands it itself and lives in the world), Sol is right about the generalisation (no `skills/projectile/` folder until a second projectile Skill), and Sol is right about the Range defect. Tunnelling is a ceiling, not a defect: comment now, fix before Speed passes about 24 units a second.
- **Briefs:** R1 (an activation that takes time): decide now only that `_activate` means "the effect happens now"; pick instant or wind-up with the first Enemy Skill. R2 (what an Aim holds): keep the offset, decide before the third Skill script. R5 (Hit feedback when the player is hit): only hits on Enemies freeze and shake. Plus two small ones: Hit as a glossary term, and how far a ball reaches.
- **Missed by both:** a Skill script that defines `_physics_process` silently stops its own Cooldown; a zero-length aim reaches every Skill's `aim.normalized()`; the glossary already answers two of R1's questions; one Hit lands on several Hurtboxes in turn, so it must stay read-only; balls that outlive their Skill will fly into the next test.

## Verdicts at a glance

| Finding | Verdict | When |
|---|---|---|
| Fable 2 / Sol S2: a Skill knows only a Faction, PLAYER by default; late Skills get none; tests lean on it | Confirmed. Four test files lean on it, not two | Now, with the Character work (HP1) |
| Sol S2: sibling order changes held-repeat timing | Refuted (section 1) | Don't. Keep Skills above the Skill bar |
| Fable 3 / Sol D4: a hit can't name its dealer; it dies with its Skill | Confirmed; Fable's migration cost overstated; Sol's `take_hit` point misdescribed | Now (HP2, HP3) |
| Fable 3: Hurtbox needs its own "can be hit" state | Overstated: one file and one caller | Trigger: the first immunity |
| Fable 4 / Sol D6: the projectile belongs to Fireball | Split verdict (section 3) | Contract now (HP3); folder at the second projectile Skill |
| Sol D6 defect 1: Range counted from the launch point | Confirmed | Now, riding with HP3 |
| Sol D6 defect 2: tunnelling on a long frame or at high Speed | Long frame refuted; Speed is a ceiling | `ponytail:` comment now; fix before about 24 units/s |
| Sol D5 / Fable ceiling: `Hurtbox.around` returns at most 32, unsorted | Confirmed | One line, riding with HP2 |
| Sol S6 / Fable R5 and traps: HitFeedback | Confirmed | R5 before the first Enemy Skill lands a hit; the rest at triggers |
| Fable R1 / Sol D9: `try_activate` is instant | Confirmed; two of its questions already answered by the glossary | Doc line now; brief A at the first Enemy Skill |
| Fable R2 / Sol D9: Aim's shape | Confirmed | Brief B before the third Skill script |
| Fable R6, R7 / Sol D9 defender side | Hooks located (section 8) | With the Character analyst's packages |
| Fable "leave until needed": Damage, Knockback, Stagger on every Skill; one script each | Confirmed; Fable's reason corrected | Leave |
| Sol perf: every ready Skill runs `_physics_process` | Confirmed | Leave until a profile |

---

## 1. A Skill knows only a Faction (Fable 2, Sol S2)

### Verify

- `skill.gd:53-55`: `var faction: Faction.Id`, no initialiser, so it holds the enum's first value, `PLAYER` (`faction.gd:7`).
- It is handed down once, in `Player._ready()` (`player.gd:79-80`). `enemy.gd` never does (no Skills). A Skill added after `_ready` is never given one: `test_aim_modes.gd:32` adds a Skill with `player.add_child(skill)` and it keeps `PLAYER` only by default.
- Tests that activate a hitting Skill with no Faction and pass only because of the default: `test_attack.gd:35-49`, `:54-70`; `test_projectile.gd:133-145`, `:160-170`, `:172-188`; `test_enemy_death.gd:11-29` (its `before_each` Attack); `test_health_bar.gd:9-26`. Fable names the first two.
- A Skill has no route to its Character (no reference; `get_parent()` is ruled out by `docs/agents/godot-conventions.md`, "Call down, signal up"). Confirmed: Blink, Leap and any cost have nowhere to start.

**Sol's extra claim, refuted.** "Dynamic Skills can process after SkillBar, changing held-repeat timing because sibling order currently determines whether cooldown advances first."

- The order is real. `player.tscn:69-75` puts Attack, then Fireball, then SkillBar. Equal-priority physics callbacks run in tree order (4.7: "Nodes with the same priority are processed in tree order"). Each Skill runs its Cooldown in `_physics_process` (`skill.gd:83-85`), then `SkillBar._physics_process` asks for presses and holds (`skill_bar.gd:78-94`). `add_child` on the Player appends after `SkillBar`.
- The repeat rhythm doesn't change. A held Attack, Cooldown 0.4 s, 24 physics ticks:
  - Skill before the bar (today): activated in tick N after its own Cooldown step; steps in N+1 … N+24 run it to 0 in N+24; the bar, later in N+24, repeats it. Every 24 ticks.
  - Skill after the bar: activated in tick N, and its own step runs later in N; it reaches 0 at the end of N+23; the bar repeats it in N+24. Every 24 ticks.
- What moves by one tick: `ready_again` (the slot's ready flash) fires one tick before the repeat instead of in the same tick; and a fresh press arriving in that tick is accepted after the bar and ignored before it, since `press()` checks `is_ready()` when the press arrives (`skill_bar.gd:56-60`).
- Judge: no process priorities. One order for every Skill comes free from the tree: the Character analyst's `Skills` node sits above `SkillBar` and `add_skill()` puts late Skills under it (their H5). Nothing else is needed.

### Judge

Do now, in the same step as the Character class (it needs a type to name). Yardstick: a Skill without its Character is the gap every Enemy Skill, every movement Skill and every cost would route around.

### Shape (HP1)

- `skill.gd`: `var character: Character` replaces `faction`. `hostile_mask()` reads `character.faction` live, so a later charm only has to move the Hurtbox's layer.
- Fail loudly where the Character is used (`hostile_mask()`, `_hit()`, `_add_to_world()`), not at the top of `try_activate`. A Skill that never hits or launches needs no Character, so `test_skill_bar.gd` and the recording Skills in `test_skill.gd` stay as they are. There is no default Faction left to fall back on, so the silent "fights for the player" failure is gone either way.
- The Character sets `skill.character = self` in `_ready()` and in `add_skill()`. Those are the two `skill.faction = faction # seam H2` lines in the Character analyst's sketch.
- Two riders in the same file, both found while checking (section 10): the Cooldown runs on internal physics processing, so a Skill script's own `_physics_process` can't stop it; and `try_activate` refuses an aim with no direction (no activation, no Cooldown, an error in the output).

```gdscript
# skill.gd
## The Character that has the Skill, given by that Character when it takes the Skill in (see
## Character.add_skill()). The Skill hits what is hostile to its Faction, deals its Hits in its
## name and puts what it launches beside it in the world.
var character: Character


# The Cooldown runs on internal physics processing: a Skill script's own _physics_process()
# replaces its parent's, but _notification() runs at every level.
func _notification(what: int) -> void:
	if what == NOTIFICATION_READY:
		set_physics_process_internal(not Engine.is_editor_hint())
	elif what == NOTIFICATION_INTERNAL_PHYSICS_PROCESS:
		cool_down(get_physics_process_delta_time())


func try_activate(aim: Vector3, modifiers: Array[Modifier]) -> bool:
	if not is_ready():
		return false
	if Vector3(aim.x, 0.0, aim.z).is_zero_approx(): # every Skill reads aim.normalized()
		push_error("%s: an aim needs a direction on the ground." % name)
		return false
	...


func hostile_mask() -> int:
	assert(character != null, "%s has no Character: give it with Character.add_skill()." % name)
	return Faction.hostile_mask(character.faction)
```

`skill.gd:83-85` (`_physics_process`) goes. The base then asks for no regular physics processing at all; a Skill script that defines `_physics_process` gets it as usual.

---

## 2. A hit can't name its dealer, and it dies with its Skill (Fable 3, Sol D4)

### Verify

- A hit is two loose arguments: `signal hit_taken(direction, snapshot)` and `take_hit(direction, snapshot)` (`hurtbox.gd:10`, `:16-20`), received by `Enemy._on_hit_taken(direction, snapshot)` (`enemy.gd:61`). Confirmed.
- The Skill node lands it, through its own viewport (`skill.gd:151-157`). Fireball's ball reports back through a signal and a lambda on Fireball (`fireball.gd:37`). Confirmed.
- **The ball dies with its Character.** It is added under the Fireball Skill (`fireball.gd:38`) with `top_level` on (`:35`). The 4.7 reference describes `top_level` only as "the node does not inherit its transformations from its parent"; `queue_free`: "When deleted, all of its children are deleted as well". An Enemy frees itself when its sink ends (`enemy.gd:119`), 0.45 s after the killing hit, while a Range-10 ball at 12 units/s flies for 0.83 s. Latent today: only Enemies are freed, and none has a Skill.
- **Fable overstated the migration.** "Adding the dealer later means changing `take_hit`, `hit_taken`, every receiver and every Skill script that builds a hits dictionary." Skills land through the base's `_land_hits` (`attack.gd:48`, `fireball.gd:37`), so a dealer filled in there touches no Skill script. The real reasons for an object: the ball must land without its Skill, which needs everything for landing in one thing it can carry; and each new fact on a hit would otherwise change `hit_taken`'s signature for every listener.
- **Sol misdescribed the Pierce point.** `take_hit` already reports whether the hit landed (`hurtbox.gd:16-20`, used for feedback at `skill.gd:154-157`). The ball never learns the answer: it counts the Hurtbox toward Pierce and emits `hit`, which returns nothing, then frees itself if that was its last (`projectile.gd:44-50`). A Hurtbox killed earlier in the same physics step therefore uses up Pierce. The developer accepted this as rare (`.scratch/factions-health/issues/03-enemy-death.md`, Comments). It goes away for free once the ball lands its own Hit.
- **Fable's "can I be hit" state: overstated.** `take_hit` reads `collision_layer == 0` (`hurtbox.gd:17`), with one writer, death (`enemy.gd:117`). Changing it later touches `hurtbox.gd` and that line. The layer does two jobs at once, and both are wanted at death: nothing finds the dead Character (`Hurtbox.around` searches by layer, the Character analyst's H3) and nothing lands on it. Separate the two at the first rule that wants a Hurtbox found but not hit: immunity during a Blink, a boss that can't be hit for a phase.

### Judge

Do now, before the first Enemy Skill: the first Enemy projectile would vanish with its Enemy, and R5 and R6 both need to know who dealt a hit.

### The one shape

**What a Hit carries on day one**, each with a reader that exists or arrives with the first Enemy Skill:

| Field | Read by | Why now |
|---|---|---|
| `snapshot` | the Character hit: Damage, Knockback, Stagger (`enemy.gd:62-66`) | today |
| `dealer` | an Enemy turning on whoever hit it (R6); kill credit later | the first Enemy Skill. Both reports want it, and it costs one line |
| `freezes` | Hit feedback: a projectile's hit doesn't freeze (`fireball.gd:11`) | today, passed down two calls (`skill.gd:151`, `hit_feedback.gd:36`) |

The direction stays an argument of `take_hit`: it differs per Hurtbox (the Attack pushes each away from the Character, `attack.gd:47`).

**Added later as fields**, each without changing any signature. Fields the base knows are filled in `Skill._hit()`, in one place; fields only a Skill knows are arguments of that call.

- The parts of its Damage by Damage type, when Damage types are designed.
- Whether it is a critical hit, when crits exist.
- Where it landed, for an effect at the point of contact.
- Which impact it plays, when a third kind appears (a burn's tick plays none): `freezes` becomes an enum, added at the end.

**Never on the Hit:** anything that differs per Character hit. Damage after the defender's resistances (R7) and whether the hit killed belong to the Character hit, which reads the Hit and writes nothing back. One Hit lands on several Hurtboxes in turn (`skill.gd:153-155`), so a defender rule that wrote to it would change the hit the next Hurtbox receives. Make its fields read-only the same way the rules analyst makes Snapshot's (Sol D7, their section 6).

```gdscript
# skills/hit.gd
class_name Hit
extends RefCounted
## A Hit (see GLOSSARY.md): what one activation does to each Hurtbox it reaches, and the
## Character that dealt it. A Skill makes it (see Skill._hit()); the same Hit lands on every
## Hurtbox the activation reaches, and a projectile carries it until it lands. Fixed once made:
## the Character hit works out what it does from it and writes nothing back.

## The activation's Snapshot: the Character hit reads Damage, Knockback and Stagger from it.
var snapshot: Snapshot
## The Character that dealt it. A projectile can land it after that Character is gone: check
## is_instance_valid() before using it.
var dealer: Character
## Whether its impact freezes the world. A projectile's doesn't.
var freezes: bool


func _init(hit_snapshot: Snapshot, hit_dealer: Character, hit_freezes: bool) -> void:
	snapshot = hit_snapshot
	dealer = hit_dealer
	freezes = hit_freezes


## Lands it on each Hurtbox in `pushes`, pushing each along its direction (a unit vector on the
## ground). The impact plays once, and only if at least one landed. Whether any landed.
func land(pushes: Dictionary[Hurtbox, Vector3]) -> bool:
	var landed: Hurtbox = null
	for hurtbox in pushes:
		if hurtbox.take_hit(self, pushes[hurtbox]):
			landed = hurtbox
	if landed: # brief C decides which landed hits play it
		HitFeedback.shared().play_impact(landed.get_viewport(), freezes)
	return landed != null
```

```gdscript
# hurtbox.gd
## A Hit landed on it, pushing along `direction` (a unit vector on the ground).
signal hit_taken(hit: Hit, direction: Vector3)


## Lands `hit` on it, pushing along `direction`. Whether it landed: off every layer (its
## Character has died) it misses, so a second hit in the frame that killed it reports nothing.
func take_hit(hit: Hit, direction: Vector3) -> bool:
	if collision_layer == 0:
		return false
	hit_taken.emit(hit, direction)
	return true
```

```gdscript
# skill.gd: two base methods replace _land_hits()
## This activation's Hit, dealt by the Skill's Character, made as `snapshot`. `freezes`: whether
## its impact freezes the world (a projectile's doesn't). For the Skills themselves.
func _hit(snapshot: Snapshot, freezes := true) -> Hit:
	assert(character != null, "%s has no Character: give it with Character.add_skill()." % name)
	return Hit.new(snapshot, character, freezes)


## Puts `node` in the world beside the Character, where it outlives the Skill and its Character:
## a projectile in flight. Everything a Skill leaves behind goes through here. For the Skills
## themselves.
# ponytail: beside the Character, so it goes where the Character's level goes. A named place for
# things in flight, if the game and level split wants one, changes only this line.
func _add_to_world(node: Node3D) -> void:
	character.add_sibling(node)
```

```gdscript
# attack.gd:48
	_hit(snapshot).land(hits)
```

The receiver (the Character analyst's `Character._on_hit_taken`, their seam H1) becomes `(hit: Hit, direction: Vector3)` and reads `hit.snapshot` where it read `snapshot`.

**Why `_add_to_world` and not each Skill calling `character.add_sibling()`, nor Sol's `Effects` node now.** Where things in flight live may change once, when the game and the level split (the UI analyst's brief 1): an Enemy's balls should go with the level, and the player's shouldn't fly on into the next level. Behind one base method, that choice changes one line instead of every Skill script that launches something. `add_sibling` needs no wiring today: a ball lands beside its Character, under `World` in the sandbox. Sol's `Effects` node needs a reference handed to every Character, or a group lookup, which the conventions avoid. It is worth having only once a level change exists to clear it.

**Sol's "small immutable context, only demonstrated facts", and Fable's `Hit` with `land()`**, are the same thing at this size. The shape above takes Fable's `land()` (the ball needs it) and Sol's restraint (three fields, each with a reader, and nothing written back).

### Proposed glossary entry

> **Hit** *(proposed)*:
> What one activation of a Skill does to each Hurtbox it reaches. It carries the activation's Snapshot and the Character that dealt it. The same Hit lands on every Hurtbox the activation reaches; the Character hit reads its Damage, knockback and Stagger from the Snapshot. A projectile carries its Hit until it lands, even after the Character that dealt it is gone. A Hit on a Hurtbox that can't be hit misses.
> _Avoid_: Strike, damage event, attack (the Attack is a Skill)

The glossary already uses "a hit" in Damage, Damage type ("What kind of damage a hit deals"), Hit feedback and Stagger; capitalised, those keep their meaning.

---

## 3. The projectile (Fable 4, Sol D6)

### Verify

- `projectile.gd:28` reads `snapshot.number(Fireball.SPEED)`. Its mask, its `hit` signal and the landing are Fireball's (`fireball.gd:32-39`). Confirmed.
- **Range is counted from the launch point.** Confirmed with numbers. The ball starts `LAUNCH_OFFSET` 0.45 ahead of the Character (`fireball.gd:14`, `:39`). It queues itself for deletion in the tick its flight reaches Range (`projectile.gd:30-32`), so nothing it touches at that last position counts (`:41`), and the last position whose touches count is 0.45 + 10 − 0.2 = 10.25 from the Character's centre. The ball's front then reaches 10.45 (radius 0.2, `projectile.tscn:6`). It can touch a zombie whose near side is 10.45 away, centre up to 10.70. The Aim marker's ring and line show 10 (`aim_marker.gd:28-37`; `ground_aim`, `player.gd:131-134`), and Range "counts the Enemy's body" for the swing (combat spec, review decisions) and for Auto-aim (`Hurtbox.around`, `hurtbox.gd:46-47`). Sol's 10.45 is right.
- **Tunnelling: the long-frame half is wrong, the Speed half is a ceiling.**
  - Physics runs at a fixed step. The 4.7 reference: `delta` "is equal to Engine.time_scale / Engine.physics_ticks_per_second"; a long frame runs up to `max_physics_steps_per_frame` (default 8) steps, and past that "the project will appear to slow down". A dropped frame never lengthens a step; each of the extra steps looks for overlaps. Only `Engine.time_scale` above 1 would, and only Hit feedback sets it, to 0 or 1 (`hit_feedback.gd:39`, `:52`).
  - The step is Speed / 60: 0.2 at Fireball's 12 (`fireball.gd:21`).
  - At flight height (0.5) the ball (radius 0.2) overlaps a Hurtbox (capsule radius 0.25, `hurtbox.tscn:5-7`, `:16`) while their centres are within 0.45 on the ground. Head-on, that is a stretch of 0.9 along the path, so a head-on Hurtbox can be skipped above 0.9 × 60 = **54 units/s**. Fable's number (350% increased) is right.
  - Off-centre the stretch is shorter (2√(0.45² − b²) at offset b), so near-misses slip through first. Within that edge band, a pass is missed in a share 1 − stretch/step of the cases.

    | Speed | Step | A Hurtbox can be missed when its centre passes more than … from the line (of 0.45) |
    |---|---|---|
    | 12 (today) | 0.2 | 0.439: the outer 2.5% |
    | 24 | 0.4 | 0.403: the outer 10% |
    | 36 | 0.6 | 0.335: the outer 25% |
    | 54 | 0.9 | head-on too |

  - Props and walls, head-on: the thinnest prop is the pot (0.41 deep, `props/pot.tscn:6`), skipped above 48.6 units/s. Walls are 1-unit boxes (`scenes/dungeon_tiles.tres`, `BoxShape3D_wall` and the default-size `wall_half`), skipped above 84.
  - Order: two contacts in one step are reported in an order the engine doesn't promise. At a 0.2 step they are side by side, so either can count as first; the error grows with Speed.

### Judge, and the disagreement settled

| Question | Fable | Sol | Verdict |
|---|---|---|---|
| The ball carries a Hit, lands it itself, lives in the world | yes, now | world-owned `Effects` | **Now (HP3)**, through `_add_to_world` (section 2). It is the lifetime and Pierce contract, not sharing. |
| `launch(...)`, one call | yes | n/a | **Now (HP3).** It replaces four property writes and the signal hookup, which change anyway. |
| Move to `skills/projectile/`, `Projectile.SPEED` | now | wait for a second projectile | **Wait (Sol).** The move is cosmetic and costs the same at any time: a Modifier file names the number as text (`&"Speed"`), never the constant. A second projectile Skill shows whether it is the same shape (an arrow likely is; a lobbed bomb isn't). Moving files with the editor open also churns `.uid` files (the project memory "Godot editor overwrites"). The rules analyst wants the number renamed (*projectile speed*, their WP-2); where its constant lives stays Fireball until the move. |
| Range from the Character | not raised | fix | **Now**, riding with HP3, in the same lines. Brief D settles the edge. |
| Swept movement | `ponytail:` comment | fix before Speed Modifiers | **Comment now (Fable)**, with the corrected numbers; fix before any projectile can pass about 24 units/s. It stays inside `projectile.gd`: no Skill script, Enemy scene or Modifier file changes when it's fixed. |

### Shape (HP3)

```gdscript
# fireball.gd, all of _activate
func _activate(snapshot: Snapshot, aim: Vector3) -> void:
	var facing := aim.normalized()
	var ball: Projectile = ProjectileScene.instantiate()
	ball.launch(_hit(snapshot, FREEZES), facing, hostile_mask(), snapshot.number(RANGE) - LAUNCH_OFFSET)
	_add_to_world(ball)
	ball.global_position = global_position + facing * LAUNCH_OFFSET + Vector3.UP * FLIGHT_HEIGHT
```

```gdscript
# projectile.gd (the parts that change)
var hit: Hit
var direction := Vector3.FORWARD
var _reach := 0.0 # how far its front may get from where it starts
var _flown := 0.0
var _hurtboxes_hit: Array[Hurtbox] = []


## Sends it along `direction` (a unit vector on the ground), its front reaching `reach` world
## units from where it starts, landing `hit` on each Hurtbox on the layers in `mask` it touches.
## Walls and props stop it. Before it enters the tree.
func launch(ball_hit: Hit, ball_direction: Vector3, mask: int, reach: float) -> void: ...


# ponytail: moves by position and trusts overlap signals. A step is Speed / 60 (0.2 at 12).
# Near-misses on a Hurtbox start slipping through around 24 units/s, a head-on one at 54, the
# thinnest prop at 49, a wall at 84. Sweep the shape along each step (cast_motion against walls,
# a shape query along the step for Hurtboxes, taken in travel order) before any Speed gets there.
func _physics_process(delta: float) -> void:
	if _flown >= _flight(): # reached its end last tick, and the physics step has looked there
		queue_free()
		return
	var step := minf(hit.snapshot.number(Fireball.SPEED) * delta, _flight() - _flown)
	global_position += direction * step
	_flown += step


func _on_area_entered(area: Area3D) -> void:
	if is_queued_for_deletion():
		return
	var hurtbox := area as Hurtbox
	if not hurtbox or hurtbox in _hurtboxes_hit:
		return
	if not hit.land({hurtbox: direction}): # its Character died earlier this step: no Pierce spent
		return
	_hurtboxes_hit.append(hurtbox)
	if _hurtboxes_hit.size() > (1 if &"Pierce" in hit.snapshot.tags else 0):
		queue_free()
```

`_flight()` is `_reach` less the ball's own radius under brief D's option A. Three details the implementer must keep:

- **The end is checked before moving.** The physics step then looks at the last position before the ball goes, so its front reaches exactly that far (today it never looks there).
- **A ball with Speed 0 must end** (the rules analyst's find: 100% reduced Speed reaches 0, rules-engine §5). Test the Speed, not the step: a hitstop gives a step of 0 too, and a ball frozen by an Attack's hitstop must fly on afterwards.
- **No `hit` signal and no `top_level`.** Nothing outside needs the signal; the ball isn't under anything that moves.

---

## 4. `Hurtbox.around` returns at most 32 (Sol D5, Fable ceiling)

**Verify.** `intersect_shape(query, 32)` (`hurtbox.gd:58`). The 4.7 reference states the cap ("The number of intersections can be limited with the `max_results` parameter") and says nothing about order. Auto-aim gets its offsets from it (`player.gd:182-186`), so with more than 32 hostile Hurtboxes in Range its "nearest" is the nearest of whichever 32 came back. With Fireball's Range of 10 and the enemies spec's 20 to 40 on screen, that can happen in play; a later area Skill would miss the rest. The hover ring (reach 1.0) and the Attack (1.6) can't reach 32.

**Judge.** One line and a test, riding with HP2 (same file). Unsorted results are fine: only `nearest_to` needs an order, and it works one out.

```gdscript
## ponytail: at most MOST Hurtboxes, in no order; past that a Skill misses the rest and Auto-aim's
## nearest is the nearest of those found. Ask in rings, or keep a list, if a pack gets that big.
const MOST := 128
...
	var results := world.direct_space_state.intersect_shape(query, MOST)
	if results.size() == MOST:
		push_warning("Hurtbox.around() found its most, %d: some Hurtboxes were left out." % MOST)
```

---

## 5. Hit feedback (Sol S6, Fable R5 and small traps)

### Verify

- A Resource with static runtime state: `static var _hitstops` (`hit_feedback.gd:32`), reached through a static `shared()` (`:21-28`). Confirmed.
- It sets `Engine.time_scale = 0.0` (`:39`) and ends the last hitstop with `Engine.time_scale = 1.0` (`:52`), overwriting any other owner of the time scale. Confirmed. Nothing else sets it today, except tests resetting it.
- It tweens the camera's `h_offset`/`v_offset` (`:42-46`, `:56-58`). Two impacts close together run two tweens on the same offsets. Cosmetic today.
- **It will play for every hit on the player.** `_land_hits` plays the impact for whatever it hit (`skill.gd:151-157`); nothing asks whom. Today no Skill hits the player (the player has no Hurtbox), so this is a prediction about the code path, and it is right. Brief C.
- **Dividing by `delta`**: during a hitstop `delta` is 0 (4.7: `delta` is `Engine.time_scale / physics_ticks_per_second`). The only division in game code is `enemy.gd:133`, guarded at `:126`. Confirmed as a trap for every later component.

### Judge

- Which hits play the impact: **brief C**, before the first Enemy Skill lands a hit. The rule lives in `Hit.land()`, one condition.
- The static counter, and restoring the previous time scale: wait for a second owner of the time scale or the camera's offsets (slow motion, a camera look-ahead). It stays inside one file. The UI analyst puts the camera's owner in the game scene and the shake through it, at the same trigger (their "leave" row on the camera).
- One line in `docs/agents/godot-conventions.md` now, with HP2: "`HitFeedback` is game-wide tuning data plus the only writer of `Engine.time_scale`. A hitstop makes `delta` 0: a component that divides by it returns early on 0, as `Enemy._slide()` does." The Character analyst's Stagger already keeps that guard.

---

## 6. An activation that takes time (Fable R1, Sol D9)

### Verify

`try_activate` checks the Cooldown, makes the Snapshot, starts the Cooldown and calls `_activate(snapshot, aim)`, all in one call (`skill.gd:104-113`). Confirmed: there is no place for a warning before the effect, a Character that is busy meanwhile, or a cancel.

**Two of the reports' open questions are already answered by the glossary**, and the code follows it:

- "Is the Snapshot made at the start or when it lands?" Snapshot: "fixed from that moment" the Skill is activated.
- "Whether Cooldown starts at wind-up or release" (Sol). Cooldown: "how long after an activation **starts**".

The Aim is fixed when it is handed to `try_activate`; whether a warning follows a moving player is a real question, but only once a warning exists.

**Why the player has no busy time.** `.scratch/remove-use-time/spec.md` removed the shared Use time "which blocked the whole Skill bar after any use", so Skills "are limited only by their own Cooldown". A shared pause comes back "only if play shows Skills feel spammy". It was a choice about feel on a handheld (README: "Does the game feel snappy"), and it concerns the player. An Enemy's wind-up is a different matter: fairness, a swing the player can step away from.

### What each answer costs (the full brief is A, below)

| | The two existing Skills | `skill.gd` | Every later Skill script | Migration later? |
|---|---|---|---|---|
| Instant only | nothing | nothing | builds its own delay inside `_activate` if it wants one | only for Skills that built their own delays, if a shared wind-up comes later |
| Optional wind-up run by the base | nothing (wind-up 0) | ~20 lines: a countdown, a cancel, "winding up" counted by `can_activate()` | may set a wind-up in its scene and draw a warning in one optional method | none, if `_activate` keeps meaning "the effect, now" |
| General begin / land / end | both rewritten into phases, with their tests | a small state machine | up to three methods | none, but every Skill pays for it now |

**What can stay open without migrating every Skill script:** everything except the meaning of `_activate`. If `_activate` is "the effect happens now", a later wind-up runs between `start_cooldown` and `_activate` in the base, and every existing Skill keeps a wind-up of 0. If `_activate` were "the activation starts", a later shared wind-up would delay Skills that already show their own warnings. So the one thing to write down now is a doc line on `_activate` (HP1). `interrupt()`, a "winding up" state, and the Character asking whether a Skill holds it are additions with empty defaults.

**Leap is not a wind-up.** A Skill that carries its Character moves it over time from inside its own script (it needs `character`, which HP1 adds), and needs a Character-side rule that walking waits meanwhile (the Character analyst's area). Both are additive at the first movement Skill (README step 1). **Blink** needs only `character`.

**A trap for whoever builds the first delay:** run it on something the Skill owns. `create_tween()` on the Skill is "killed when the bound object is freed" and pauses when the node can't process (4.7, `Tween.bind_node`). A timer from `get_tree().create_timer()` belongs to the tree, not the Skill, so its timeout still comes after the Skill and its Character are gone.

---

## 7. What an Aim holds (Fable R2, Sol D9)

### Verify

- An Aim is a `Vector3` offset on the ground from the Character (`skill.gd:128-133`). "No aim yet" exists only between the Skill bar and the Player: `SkillBar.NO_AIM` is `Vector3.INF` (`skill_bar.gd:22`), and the Player replaces it (`player.gd:111`). A Skill never sees it. Confirmed.
- A Skill activated around the player is handed Facing × Range and ignores it (`player.gd:150-151`). The glossary says such a Skill "has none". Harmless.
- How a Skill aims is three settings: `aim` (`AROUND`, `AUTO`, `AIMED`, `skill.gd:13-15`), `aims_at_spot` (`:34`) and `target_for()` (`:136-138`). They are read in four places: `player.gd:124`, `:150`, `aim_marker.gd:31-38`, `skill_bar_hud.gd:100`. Confirmed. `AUTO` against `AIMED` really means "on touch, activates when the thumb lands" against "activates when the thumb lifts, after an optional drag" (`skill_bar_hud.gd:100-108`): a touch gesture, not a shape of aim.
- No shipped Skill uses `AROUND`, `aims_at_spot` or `target_for()`: Attack sets none (`attack.tscn:15-25`), Fireball only `aim = 2` (`fireball.tscn:8`); only the test Skill does (`test_aim_modes.gd:10-18`). Confirmed. They were kept on purpose for the curse (`.scratch/remove-use-time/spec.md:22`).
- A Skill can show what it would pick (`target_for`) but is handed only the offset at activation, so it picks again from the spot. Confirmed. Mark worked this way and the developer accepted it after a device test (`.scratch/aiming/spec.md:22`, `:63`). An Enemy "aims … with its target standing in for the devices" (`.scratch/player-controls/spec.md:12`): it passes the offset to the player.
- **Found while checking:** nothing guarantees an aim has a direction. Every Skill takes `aim.normalized()` (`attack.gd:38`, `fireball.gd:31`). The Console's `activate 1 0 0` hands the Attack a zero vector today (`player.gd:217-226`, `:111`). A Range of 0, which Modifiers can reach (the rules analyst's §5), turns every aim the Player makes except the mouse's into a zero vector, since each is Facing or a drag times the Range (`player.gd:134`, `:151`, `:160`, `:168`, `:174`). An Enemy whose behaviour computes a zero offset would do the same. **Needs a run** for the exact symptom: it should be an engine error from `Basis.looking_at` and a swing that counts every Hurtbox in Range as inside its Sweep (the angle to a zero vector is 0).

### Judge

Brief B, decided before the third Skill script: the cost of changing `_activate`'s parameters grows with every Skill script, and today there are two. The foundation work (HP1 to HP3) doesn't touch `_activate`'s parameters, so nothing about it has to be decided first. The zero-aim guard goes in now (HP1): it holds under every option.

---

## 8. Where the defender-side hooks live (Fable R6, R7; Sol D9)

Once the Hit exists, both live in the one place a hit meets the Character hit, the Character analyst's `Character._on_hit_taken(hit, direction)`:

- **R7, defender side** (resistances, "more Damage against staggered Enemies"): the Damage taken is worked out there from `hit.snapshot` and the Character's own state at that moment, by a pure function the rules side will own once Damage types exist. Nothing is written to the Hit (section 2).
- **R6, a hit from outside the Aggro radius** (the zombie stands still under a Fireball from 10 away: Fireball's Range 10, Aggro radius 6 at `aggro.gd:17`, and the target set only by Aggro at `enemy.gd:41`): the same handler hands `hit.dealer` (if `is_instance_valid`) to whatever decides where the Enemy walks. The Character analyst's Behaviour already has `notice(target)`, so this is one line in their WP4, and the rule itself is the developer's.

---

## 9. Fable's "leave until needed" rows here, and Sol's performance item

- **Every Skill has Damage, Knockback and Stagger** (`skill.gd:46-51`, `:100-101`). Confirmed. **Leave**, but for a better reason than Fable's. Moving the exports off the base later does change scripts: a hitting Skill would have to `extends` an intermediate class, one line in every hitting Skill script. The reason to leave them: a Skill that never hits loses nothing by carrying zeros ("a hit with 0 Damage leaves it alone", factions-health rule 4), and the Hit reads the numbers by name from the Snapshot wherever they are declared. Trigger: the first Skill that doesn't hit, and only if its inspector should look clean.
- **Skills are one script each.** Confirmed; the deepen-skills deferral stands. After HP3, Fireball's `_activate` is five lines.
- **Every ready Skill runs `_physics_process`** (`skill.gd:83-85`, returning early in `cool_down`). Confirmed. **Leave until a profile.** After HP1, stopping the internal tick while ready is two lines no Skill script can break. But direct writes to `cooldown_left` (`test_enemy_death.gd:27`, `test_health_bar.gd:25`) would then have to restart it, so do it with a setter, at the trigger (packs of Enemies with Skills, profiled on the phone). The rules analyst lists the same trigger.

---

## 10. Missed by both reports

Held to the same yardstick: does it touch every Skill script, every Enemy scene or every Modifier file?

1. **A Skill script that defines `_physics_process` stops its own Cooldown.** The base runs the Cooldown in `_physics_process` (`skill.gd:83-85`). In GDScript "functions in extending classes replace functions with the same name in their super classes" (4.7, GDScript reference); `_notification` is the exception, "called automatically for every script that overrides it" (4.7, Object). A channel, a beam or an orbit that writes its own `_physics_process` and forgets `super(delta)` gets a Cooldown that never ends, with no error. Every future Skill script with per-frame work is exposed. **Do now** (HP1): five lines in `skill.gd` (section 1), and a test that fails today.
2. **An aim with no direction reaches every Skill** (section 7). Every Skill script would otherwise need its own guard. Small; rides with HP1: `try_activate` refuses it (no activation, no Cooldown, an error in the output). Its likeliest real source is a Range of 0, so a floor on Range like the rules analyst's Cooldown floor is the other half (a seam).
3. **The glossary already answers two of R1's questions** (section 6). The brief can be shorter for it.
4. **One Hit lands on several Hurtboxes in turn**, so it must stay read-only, and per-Character results stay with the Character hit (section 2). Sets the rule before R7's first resistance is written.
5. **Balls that outlive their Skill will outlive their test.** Today a test's ball is freed with its `autoqfree`d Fireball. After HP3 a ball lands beside the Character, under the test node, and flies on into the next test's zombies unless the test frees it or waits it out. `test_projectile.gd:24-37` and `:112-120` fire and don't wait. HP3's tests must free every ball they fire.
6. **The `Skills` node must be a `Node3D`.** Fable's sketch makes it a plain `Node`, which would put every Skill, and so every swing and every ball's start, at the world origin. The Character analyst found this too and their WP1 already has it as a `Node3D`.

---

## Decision briefs

Each stands on its own. Words as in `GLOSSARY.md`.

### Brief A. Can an activation take time? (Fable R1)

**The question.** When a Skill is activated, does what it does always happen at once? Or can an activation take time: a warning before an Enemy's swing lands, or a Leap that carries its Character for half a second?

**Today.** Activating checks the Cooldown, makes the Snapshot, starts the Cooldown and does what the Skill does, in the same physics tick (`skill.gd:104-113`). `_activate` is the one method every Skill script writes. Fireball already does something later, since its ball flies on, but on its own, after the activation.

**Already settled by the glossary, to confirm rather than decide.** The Snapshot is fixed when the Skill is activated, and the Cooldown runs from when the activation starts. So any delay sits between those two and what the Skill does, whichever option is picked. Nothing below brings back the shared pause that `remove-use-time` removed from the player on purpose ("Skills are limited only by their own Cooldown").

**Options.**

- **A. Instant only.**
  - *In play:* a zombie's swing hits the moment it decides to swing. The player can stay out of its reach but can't react to a swing.
  - *For the twentieth Skill script:* one method, where the effect happens. A Skill that wants a delay builds its own timer and warning, and nothing cancels it on a Stagger or death unless that script does.
  - *Touches:* nothing.
- **B. An optional wind-up** *(proposed)* **before the effect.** It is a number on the Skill, 0 for every existing Skill, so Modifiers can change it. The Skill shows its warning during it, then does what it does as today. A Stagger or the death of its Character cancels it, and the Cooldown has already started.
  - *In play:* a red wedge appears where the zombie will swing, and half a second later the swing lands. A player who steps out of the wedge takes nothing. A hard enough hit on the zombie cancels the swing.
  - *For the twentieth Skill script:* `_activate` unchanged. The wind-up is set in its scene, and one more optional method draws the warning.
  - *Touches:* ~20 lines in `skill.gd`. The Character calls the cancel on Stagger and death (Character analyst). "Winding up" becomes the second reason `can_activate()` says no (the rules analyst's trigger for building it).
- **C. Phases: begin, land, end, and a tick for channels.**
  - *In play:* B's swings, plus channels (a beam held for two seconds).
  - *For the twentieth Skill script:* up to three methods to understand instead of one.
  - *Touches:* Attack and Fireball rewritten into phases, with their tests. No planned Skill needs an end or a tick, and holding a slot already repeats the Attack in a steady rhythm.

**Leap and Blink** fit any option. A Skill that carries its Character moves it from inside its own script, using its reference to its Character (HP1). A Character-side rule makes walking wait meanwhile. Both are additions at the first movement Skill.

**Recommendation.** Decide one thing now: `_activate` means "what the Skill does happens now". It is true today and is a doc line in HP1. That rules out C and makes B an addition later, with existing Skills untouched. Choose between A and B with the first Enemy Skill, which is when README step 3's open question ("Will we use telegraphed abilities?") gets its answer. If telegraphs are wanted, B for Enemy Skills, and the player's Skills keep a wind-up of 0.

If B, decide then: does the warning stay where it was aimed (dodgeable) or follow the player; can the Enemy walk during it; does any Stagger cancel it, or only some.

> **Wind-up** *(proposed, only if B)*:
> The moment between activating a Skill and what it does, while the Skill shows where it will land. Its Snapshot and Cooldown start when it is activated. A Stagger or the death of its Character cuts it short, and the Skill then does nothing.
> _Avoid_: Cast time, charge-up, telegraph

### Brief B. What can an Aim hold? (Fable R2)

**The question.** An Aim is "a direction on the ground, and for a Skill that lands on a spot, also how far". Should an Aim also be able to name a particular Character to hit? That would let README step 3's targeted curse be handed "this Enemy", and an Enemy's Skill "the player".

**Today.** An Aim is an offset on the ground from the Character. A Skill that picks out a Character shows its pick with a ring while aiming (`target_for()`), and picks again from the spot when activated. How a Skill aims is three settings (`aim`, `aims_at_spot`, `target_for()`), and no shipped Skill uses the last two. An Enemy aims by passing the offset to the player.

**Options.**

- **A. An Aim stays an offset.** A Skill that picks a Character picks it from the spot with `target_for(aim)`, the same function that rings it.
  - *In play:* on touch, the curse is dragged onto a zombie and the ring shows which one; lifting curses the zombie nearest that spot within reach (Mark worked this way). On PC it is the one under the cursor. An Enemy curses the player by aiming where the player stands. If another zombie steps nearer the spot in the instant between ring and release, that one is cursed.
  - *For the twentieth Skill script:* `_activate(snapshot, aim)`. A Skill that picks also writes `target_for()` and calls it from `_activate`.
  - *Touches:* nothing now. If lock-on or homing is ever wanted, every `_activate` written by then changes signature.
- **B. An Aim object** *(proposed)* **with the offset and, optionally, a chosen Hurtbox.** `_activate(snapshot, aim: Aim)`. The player's aiming fills the Hurtbox from the ring; an Enemy's behaviour with the player's Hurtbox.
  - *In play:* the same as A on screen, except the curse lands on the ringed zombie even if another stepped nearer the spot. A homing ball or a lock-on becomes possible later.
  - *For the twentieth Skill script:* `aim.offset` wherever it now writes `aim`.
  - *Touches, now:* Attack, Fireball, three test Skills, the Skill bar's press and hold aims, the Player's aiming, the Aim marker, the HUD, and their tests (about ten call sites).
- **C. Keep the offset, and have `try_activate` leave the chosen Hurtbox on the Skill for `_activate` to read.** No signature change, but a hidden side channel every picking Skill must know about. Not recommended.

**Recommendation: A**, decided before the third Skill script. The glossary defines Aim without a chosen Character and lists "lock-on" and "soft target" as words to avoid under Auto-aim. Mark proved spot-and-ring picking on touch, and the planned curse works with it. Pick B only if lock-on or homing is a rule you want; deciding it later costs a change to every Skill script written by then.

**Can wait, whatever the answer:** renaming `AUTO` and `AIMED` to say what they mean on touch (thumb lands, thumb lifts). Scenes save the enum as a number (`fireball.tscn:8`, `aim = 2`), so renaming its values is safe and reordering them is not (the rules analyst's append-only rule).

**Holds under every option, done now (HP1):** an aim must have a direction, so `try_activate` refuses one without (no activation, an error in the output).

### Brief C. What shows when an Enemy hits the player? (Fable R5, Sol S6)

**The question.** Hit feedback is "how the game shows the moment a Skill hits an Enemy": the world freezes for an instant (except for a projectile's hit), the Enemy flashes and squashes, the screen shakes. When Enemies have Skills, what does the player see when an Enemy's Skill hits *them*?

**Today.** Nothing decides it. The code that lands a hit plays the freeze and the shake for whatever it hits (`skill.gd:151-157`).

**Why it matters.** Freezes add up. A landed swing freezes the game for 0.06 s, and the game doesn't advance meanwhile. Say zombies swing as often as the player's Attack, every 0.4 s, and N of them are in reach: the game is frozen about 0.15N ÷ (1 + 0.15N) of the time. That is 13% with one zombie, 31% with three and 60% with ten. The player would feel it as constant stutter, in exactly the fights that should feel best.

**Options.**

- **A. Like an Enemy's hit.** Freeze, shake, and the player's Standee flashes and squashes. *In play:* the stutter above.
- **B. Only hits on an Enemy freeze and shake.** A hit on the player flashes and squashes the player's Standee and drops its Health bar, and the world keeps running. *In play:* the player sees their card blink white and squash; nothing stutters, however many zombies hit at once.
- **C. B, plus a lighter shake (no freeze) when the player is hit.** One new tuning value in `hit_feedback.tres`. *In play:* a small jolt of the screen per hit taken, constant in a pack.
- **D. B, plus a "you were hit" cue on the HUD**, such as a red flash at the screen's edge, designed with the developer.

*For the twentieth Skill script:* nothing in any option. The rule lives in one place, `Hit.land()`, and an Enemy's Attack is the same scene as the player's.

*Touches:* one condition in `skills/hit.gd`, the Hit feedback entry in `GLOSSARY.md`, one test. C also touches `hit_feedback.gd` and `.tres` (and, as a second source of shake, brings forward the UI analyst's camera owner). D touches the HUD.

**Recommendation: B now**, and try C on the phone once a zombie hits the player. B needs no new tuning and is what the glossary entry already describes ("the moment a Skill hits an Enemy"). C and D add to B, so starting with B loses nothing. It fits the Character analyst's B2 recommendation that the player isn't staggered: the player keeps control and sees each hit on their own card. Decide before the first Enemy Skill lands a hit. Left open by B: a pet's hits on Enemies would freeze the world too; decide with pets.

### Brief D. How far does a ball reach? (Sol D6)

**The question.** Range is "how far a Skill reaches from the Character that has it". A swing reaches any part of an Enemy within Range, and so does Auto-aim. Fireball's ball starts 0.45 ahead of the Character and then flies its whole Range, so with Range 10 it still touches a zombie whose near side is 10.45 away, while the aim line and ring show 10.

**Options.** A: the ball's front reaches exactly Range from the Character's centre, the same rule as the swing. B: the ball's centre travels to Range, so its front reaches Range plus its radius (0.2). C: leave it.

*In play:* under A, a zombie just outside the ring is never hit and one just inside always is. Under B, a sliver of 0.2 beyond the ring can be hit; under C, 0.45. *For the twentieth Skill script:* nothing; the rule is the projectile's.

**Recommendation: A.** One rule for every Skill: what the ring shows is what is reached. It goes into HP3 with a test, and one sentence in the Range entry: "A Hurtbox is within Range when any part of it is."

### Brief E. Is "Hit" a glossary term?

The working agreement asks for a proposed glossary entry before a new word goes into code. The draft is in section 2. Two choices: the name (`Hit`, already the glossary's lowercase word in four entries), and the word for who dealt it. Fable says "dealer"; Sol says "source". "Dealer" fits "deals Damage"; "source" is also the word the skill-tags spec uses for where Modifiers come from (gear, talents), which would be confusing. **Recommendation:** `Hit`, with "the Character that dealt it" in prose and `dealer` in code. Decide before HP2.

---

## Work packages

In order. "HP" numbers are this area's; the other analysts' numbers are given as theirs.

### HP1. A Skill knows its Character

- **Branch:** the Character analyst's `character` branch (their WP1), or its own branch right on top of it. It can't land before it.
- **Files:**
  - `skills/skill.gd`: `character` replaces `faction` (`:53-55`); `hostile_mask()` reads it, with an assert; the Cooldown on internal physics through `_notification` (removes `:83-85`); `try_activate` refuses an aim with no direction; `_activate`'s doc says "the effect happens now" (brief A).
  - The two `skill.faction = faction` lines in their `Character` become `skill.character = self`.
- **Tests that move:** the Skill is given to a Character with `add_skill()` (from the Character analyst's base scene) in every test that activates a Skill calling `hostile_mask()`:
  - `test_attack.gd:35-70`;
  - all five Fireball tests in `test_projectile.gd` (`:24-37`, `:112-120`, `:133-188`);
  - `test_enemy_death.gd:11-17`;
  - `test_health_bar.gd:9-11`.

  `test_aim_modes.gd:32` (`add_skill`) is already in their WP1.
- **Tests added** (`test_skill.gd`):
  - A Skill added to an Enemy after it is ready hits a player-Faction Hurtbox and not an Enemy's. Fails with today's default Faction.
  - A Skill whose script has its own `_physics_process` still cools down. Fails today.
  - An aim with no direction activates nothing and starts no Cooldown.
- **Docs it reopens:** `.scratch/factions-health/spec.md` requirement 2 ("gives each of its Skills the Faction"); `.scratch/skill-tags/spec.md` "Where the code lives" (the Skill still runs its own Cooldown; say how); `docs/agents/godot-conventions.md`, one line: a Skill script may define `_physics_process` freely.
- **Depends on:**
  - The Character analyst's WP1: `class_name Character` with `faction`; `add_skill()`; a `Skills` `Node3D` above `SkillBar`; a base scene tests can instance.
  - The rules analyst's WP-1 also edits `skill.gd:111` (the Cooldown floor): merge order only.
  - No decision.
- **Implementer:** Sonnet, the same one as the Character branch.
- **Done when:** `Skill.faction` is gone; a Skill given to a zombie after it is ready hits only player-Faction Hurtboxes; a Skill script's own `_physics_process` can't stop its Cooldown; an aim with no direction is refused.

### HP2. The Hit

- **Branch:** its own.
- **Files:**
  - New: `skills/hit.gd`.
  - `characters/hurtbox/hurtbox.gd`: `take_hit(hit, direction)`, `hit_taken(hit, direction)`, and the `around()` cap of section 4.
  - `skills/skill.gd`: `_hit()` replaces `_land_hits()` (`:146-157`).
  - `skills/attack/attack.gd:48`.
  - `skills/fireball/fireball.gd:37`: `_hit(snapshot, FREEZES).land(...)` inside the lambda, until HP3 removes it.
  - The receiver, `Character._on_hit_taken` (their H1).
- **Tests that move:**
  - `test_skill.gd:11-40`: the landing tests become `tests/test_hit.gd`, with Hits made as `Hit.new(snapshot, null, true)`. `dealer` may be null.
  - `test_enemy_death.gd:63-74` (`take_hit`, `_land_hits`).
- **Tests added:**
  - The Attack's Hit names its Character (`test_attack.gd`).
  - `Hurtbox.around` finds 33 Hurtboxes (`test_hurtbox.gd`). Fails today.
  - A Hit that lands on nothing plays no impact. Moved from `test_skill.gd:38-40`.
- **Docs it reopens:**
  - `.scratch/factions-health/spec.md` rule 3 ("A hit reports where it pushes and the activation's Snapshot, nothing else") and requirements 3 and 4.
  - `.scratch/deepen-skills/spec.md` item 3 (one impact per `_land_hits` call becomes one per `Hit.land` call).
  - `.scratch/combat/spec.md` decision "Skill lands its own hits".
  - `GLOSSARY.md`: Hit (brief E).
  - `docs/agents/godot-conventions.md`: the HitFeedback and `delta` line (section 5).
  - Optionally a short ADR, "A Hit carries its Snapshot and dealer and outlives its Skill", recording the options considered: two arguments, Sol's `Effects` node, `add_sibling`.
- **Depends on:**
  - HP1.
  - The Character analyst's WP1 (the one receiver).
  - Brief E. Brief C optional: if answered, HP4 folds in here.
- **Implementer:** Sonnet, from a spec section Opus writes from section 2. It reopens a recorded rule and adds a glossary term.
- **Done when:** `take_hit(hit, direction)` and `hit_taken(hit, direction)` are the only forms; every Hit names its dealer; `_land_hits` is gone; `Hurtbox.around` finds more than 32 and warns at its cap.

### HP3. Fireball's ball lives in the world

- **Branch:** its own.
- **Files:**
  - `skills/skill.gd`: `_add_to_world()`.
  - `skills/fireball/fireball.gd`: `_activate`, five lines.
  - `skills/fireball/projectile.gd`:
    - `launch()`;
    - lands its own Hit, and spends Pierce only on Hits that landed;
    - Range from the Character, with the end looked at (brief D);
    - a ball with Speed 0 ends;
    - no `hit` signal and no `top_level`;
    - the `ponytail:` comment.
- **Tests that move:** all of `test_projectile.gd`.
  - `_fire()` uses `launch()`.
  - Hits are recorded from the zombies' `hit_taken`.
  - The ball is found among the test's children, not as `fireball.get_child(0)` (`:34`, `:117`, `:138`).
  - `:133-145` samples the time scale a tick after the hit: inside `hit_taken` it would be read before the impact plays, so the test couldn't fail.
  - Every test frees the balls it fires (section 10, item 5).
- **Tests added:**
  - A ball whose Character is freed mid-flight still lands its Hit.
  - A Hurtbox whose hit missed (killed earlier in the step) doesn't use up Pierce.
  - A Range-10 ball hits a zombie whose near side is 9.9 from the Character, and not one at 10.1. Fails today.
  - A Speed-0 ball ends.
- **Docs it reopens:**
  - `.scratch/combat/spec.md`, the decision that the ball is "a child of the Fireball Skill … Nothing else has to own it".
  - The Comments line of `.scratch/factions-health/issues/03-enemy-death.md` (resolved).
  - `GLOSSARY.md` Range (brief D).
- **Depends on:**
  - HP2. Brief D.
  - The rules analyst's WP-2: `SkillTag.PIERCE` at `projectile.gd:48` and the Speed rename. Merge order only.
  - The UI analyst's brief 1: where things in flight go after a game and level split. Not blocking: `_add_to_world` is the one line that changes.
- **Implementer:** Sonnet.
- **Done when:** a ball whose Character is freed mid-flight lands its Hit; a missed Hit spends no Pierce; a Range-10 ball touches nothing wholly beyond 10 from the Character; `projectile.gd` sends nothing back to Fireball.

### HP4. Hits on the player don't freeze the world (brief C)

- **Branch:** folds into HP2 if brief C is answered before it; otherwise a small branch before the first Enemy Skill ships.
- **Files:** `skills/hit.gd` (one condition: the impact plays when a landed Hurtbox is on the Enemies' layer); `GLOSSARY.md` Hit feedback.
- **Tests added:** a Hit landed on a player-Faction Hurtbox leaves the time scale at 1; one on an Enemy's freezes as today.
- **Depends on:** HP2; brief C; the player's Hurtbox (the Character analyst's WP3) for an end-to-end check.
- **Implementer:** Haiku, if brief C is B.
- **Done when:** a hit on the player never freezes or shakes the world, and a hit on an Enemy plays as today.

### At their triggers, not now

| What | Trigger | Implementer |
|---|---|---|
| The wind-up in the base Skill (brief A, option B): the number, the warning method, the cancel, "winding up" in `can_activate()` | The first Skill with a warning, likely the first Enemy Skill | Opus |
| The Aim object (brief B, option B only) | Before the third Skill script, if B | Opus |
| Swept ball movement, contacts in travel order | Any projectile able to pass about 24 units/s, or a Speed Modifier that could | Sonnet |
| `skills/projectile/`, the Speed constant on `Projectile` | The second projectile Skill (data unchanged) | Haiku |
| A Hurtbox found but not hit | The first immunity (a Blink, a shielded boss) | Haiku |
| Hit feedback's runtime in a scene-owned piece; restore the previous time scale | Slow motion, or a second camera effect | Sonnet |
| A ready Skill stops ticking | A profile with packs of Enemies with Skills | Sonnet |

**Order with the other analysts:**

1. The Character analyst's WP1, with HP1.
2. HP2.
3. HP3.
4. Brief C and HP4 before an Enemy Skill lands a hit.
5. The first Enemy Skill step, where brief A is answered (the Character analyst's WP3 and WP4).
6. Brief B before the third Skill script.

---

## Seams

**With the Character analyst** (their labels H1 to H8):

- **H1, what a hit carries:** their `_on_hit_taken(direction, snapshot)` becomes `(hit: Hit, direction: Vector3)` in HP2. R7's defender step and R6's hand-off of `hit.dealer` to the Behaviour's `notice()` live in that method (section 8).
- **H2, Skill to Character:** their two `skill.faction = faction` lines become `skill.character = self` (HP1). `add_skill()` working before the Character enters the tree is fine. Only `_add_to_world` needs the tree, at activation.
- **H3, "can be hit":** no new state now. Death keeps clearing the Hurtbox's layer, which takes it out of `take_hit` and out of every query at once. If death ever changes (their `process_mode` route, or B4's "can't be hit at 0"), `take_hit` must still answer false afterwards (`test_enemy_death.gd:59-66`).
- **H4, Hit feedback on the Character hit:** flash and squash on every Character, in their handler. Brief C decides only the freeze and the shake.
- **H5, process order:** agreed. The `Skills` `Node3D` above `SkillBar`; no priorities.
- **H6, things in flight:** HP3's `_add_to_world`. The dead Enemy's ball no longer goes with it.
- **H7, a staggered Character's activations:** a second reason for `can_activate()`. So is brief A's "winding up".
- **H8, an Enemy's Aim and timed activations:** an Enemy passes the offset to its target (brief B, A); brief A is answered with their WP4.
- **Assumed of them:** a base scene that tests can instance to hold a Skill; Facing staying on Player (nothing in this area needs it on Character now).

**With the rules analyst:**

- `projectile.gd:48` takes `SkillTag.PIERCE`.
- The Speed number's new name, if any. Its constant stays on Fireball until the second projectile.
- A ball with Speed 0 ends (HP3).
- A Range of 0 turns every aim the Player makes except the mouse's into a zero vector (section 7). HP1's guard refuses those activations; a floor on Range, like their Cooldown floor, would keep them from happening.
- `skill.gd:111` gets the Cooldown floor (their WP-1), next to HP1's edits.
- `can_activate()` is theirs, at its trigger; brief A's option B is one such trigger.
- Hit's read-only fields follow Snapshot's pattern.

**With the UI analyst:**

- Where `_add_to_world` puts things once the game and level split (their brief 1 and seam H3). Today: beside the Character.
- The camera's owner takes the shake if brief C picks C or slow motion arrives.
- `skill_bar_hud.gd:98-100` reads `is_ready()` and `aim`; brief B's optional rename of `AUTO`/`AIMED` touches `:100`.

---

## Needs a run

1. **A `Node3D` under a plain `Node` ignores the transform above it.** Inferred from the 4.7 reference (`get_parent_node_3d()` "Returns null if … the parent is not a Node3D"), and the Character analyst reads it the same way. Run: a GUT test with an Attack under a plain `Node` under a moved `CharacterBody3D`, checking its `global_position`. Moot if the `Skills` node is a `Node3D`.
2. **The zero aim's symptom.** Run `activate 1 0 0` in the Console with a zombie behind the player; watch for the `Basis.looking_at` error and whether the zombie is hit.
3. **Today's Range.** A Range-10 Fireball thrown along a line with a zombie centred 10.6 away: hit today, missed after HP3. This becomes HP3's test.
4. **Internal against regular physics callbacks.** The 4.7 reference doesn't say whether a node's internal and regular physics notifications run node by node or all internal ones first. Nothing here relies on it: either way, a Skill above the Skill bar runs its Cooldown before the bar asks.
5. **Tunnelling** (optional). A Speed-60 ball, a 1.0 step, against a head-on zombie misses on some starting offsets.

## Engine facts relied on

Godot 4.7 class reference and manual, read 2026-11-22 (each page shows "Godot Engine 4.7 documentation"):

- `Node3D.top_level`: "the node does not inherit its transformations from its parent". Nothing about lifetime. `get_parent_node_3d()`: "Returns null if no parent exists, the parent is not a Node3D, or top_level is true."
- `Node.queue_free()`: "When deleted, all of its children are deleted as well"; "Queues this node to be deleted at the end of the current frame."
- `Node._physics_process`: `delta` is `Engine.time_scale / Engine.physics_ticks_per_second`; "Nodes with the same priority are processed in tree order". `process_physics_priority`: lower values first, "regardless of tree order".
- `Engine.max_physics_steps_per_frame` (default 8): beyond it "the project will appear to slow down". `physics_ticks_per_second` default 60. `time_scale` scales the `delta` of `_process` and `_physics_process` and does not change the tick rate.
- `Node.set_physics_process_internal()`: "happens in isolation from the normal _physics_process() calls … even if … physics processing is disabled for scripting".
- `Object._notification`: "Unlike other virtual methods, this method is called automatically for every script that overrides it." GDScript reference: "functions in extending classes replace functions with the same name in their super classes. If you still want to call them, you can use super".
- `PhysicsDirectSpaceState3D.intersect_shape(parameters, max_results = 32)`: limits the count; says nothing of order. `cast_motion()`: returns "the safe and unsafe proportions … of the motion"; "Any Shape3Ds that the shape is already colliding with e.g. inside of, will be ignored." (for the later swept ball)
- `Area3D`: says nothing about fast movement. `Engine`: "High tick rates give more accurate physics simulation, particularly for fast moving objects."
- `Node.create_tween()`: "Creates a new Tween and binds it to this node"; `Tween.bind_node()`: "automatically killed when the bound object is freed"; default pause mode `TWEEN_PAUSE_BOUND`.
- `SceneTree.create_timer(…, ignore_time_scale)`: "the timer will ignore Engine.time_scale and update with the real, elapsed time."
