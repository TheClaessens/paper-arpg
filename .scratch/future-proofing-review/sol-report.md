# Future-proofing architecture review

Reviewed `master` at `8797660`. `tools/check.sh` passes: 0 load failures and 201 passing tests. The repository remained clean during the review.

## Verdict

The foundation is strong, but it should not scale unchanged.

The best parts are the pure Snapshot/tag resolver, data-driven Modifiers, Skill-owned cooldowns, Hurtbox/Faction targeting, scene-local gameplay state, and small reusable components. Preserve those.

The main architectural risks sit at shared contracts:

1. `Character` exists in the domain model but has no shared code boundary.
2. Skills know a Faction, not their owning Character.
3. Hits cannot identify their source, and persistent effects belong to their caster.
4. Modifier arithmetic and identity have unresolved semantics.
5. Shared target queries and projectile movement have hard scaling/correctness ceilings.
6. Content files are stringly typed without repository validation.
7. The sandbox is both level and game root.

This needs focused contract work, not an ECS, event bus, universal effect graph, or broad rewrite.

## What should remain

- `Snapshot.of()` and `TagPass` are the right pure seam for Skill resolution.
- `SkillBar` correctly owns slots, queues, and holds—not Skills or Cooldowns.
- One shallow `Skill` base class is justified.
- Faction-to-Hurtbox-layer mapping lets physics perform hostility filtering.
- `Movement`, `Health`, `Hurtbox`, `Aggro`, `HealthBar`, `Standee`, and `Controls` are appropriately small components.
- Player and Enemy are currently acceptable composition roots.
- Static scenes are editor-built; runtime construction is reserved for dynamic projectiles and UI tiles.
- Gameplay state has not leaked into autoloads.
- Tests cover meaningful physics and UI behavior, not only pure functions.

# Standards and Godot architecture

## S1 — High: `Character` has no shared code home

The glossary defines Player and Enemies as Characters, but the implementation splits Character responsibilities asymmetrically.

`characters/player/player.gd:31-50`:

```gdscript
var skill_bar: SkillBar:
	get:
		return $SkillBar

var skills: Array[Skill]:
	get:
		var found: Array[Skill] = []
		for child in get_children():
			if child is Skill:
				found.append(child as Skill)
		return found

@export var faction := Faction.Id.PLAYER
@export var modifiers: Array[Modifier] = []
```

`characters/enemy/enemy.gd:8-43`:

```gdscript
@export var faction := Faction.Id.ENEMIES

var _target: Node3D
var _stagger_left := 0.0
var _stagger_time := 0.0
var _knockback := Vector3.ZERO

@onready var hurtbox: Hurtbox = $Hurtbox
@onready var health: Health = $Health
@onready var health_bar: HealthBar = $HealthBar

func _ready() -> void:
	hurtbox.collision_layer = Faction.layer(faction)
	hurtbox.hit_taken.connect(_on_hit_taken)
	health.changed.connect(health_bar.show_health)
	health.died.connect(_die)
```

Today:

- Only Player owns Skills and Modifiers.
- Only Enemy can receive a hit and Stagger.
- Both duplicate Faction, Movement, Standee, Health, HealthBar, body shape, motion mode, and wiring.
- The next Enemy Skill and Player Hurtbox would copy the missing half into each root.

Recommendation: before the first Enemy Skill, specify a thin `Character` root type and shared scene. It should contain identity and wiring, not behavior:

- Faction and Modifiers.
- A dedicated `Skills` child.
- Hurtbox/Health/HealthBar wiring.
- Skill-owner initialization.
- A Stagger or hit-reaction component.
- Facing shared only if Enemy Skills need it.

Player keeps Controls and player aiming. Enemy keeps AI/navigation/death presentation. This is one semantic base type matching the glossary, not an inheritance hierarchy of Enemy kinds.

A likely shape:

```gdscript
class_name Character
extends CharacterBody3D

@export var faction: Faction.Id
@export var modifiers: Array[Modifier] = []

func add_skill(skill: Skill) -> void:
	$Skills.add_child(skill)
	skill.character = self
```

Do not introduce `enemy.tscn` inheritance until a second Enemy kind demonstrates what Enemy scenes share.

## S2 — High: Skill ownership is under-specified and initialized only once

`skills/skill.gd:53-56`:

```gdscript
## The Faction of the Character that has the Skill, given by that Character.
var faction: Faction.Id
```

`characters/player/player.gd:77-85`:

```gdscript
func _ready() -> void:
	health.changed.connect(health_bar.show_health)
	for skill in skills:
		skill.faction = faction
	# ...
	skill_bar.activation_requested.connect(_on_activation_requested)
```

Consequences:

- A bare Skill defaults to `Faction.Id.PLAYER`.
- An Enemy Skill silently attacks Enemies unless manually initialized.
- A dynamically gained Skill added after `_ready()` misses initialization.
- Blink, Leap, costs, source-sensitive effects, and owner state cannot access the Character without forbidden parent traversal.
- Dynamic Skills can process after `SkillBar`, changing held-repeat timing because sibling order currently determines whether cooldown advances first.

Direction:

- Replace `Skill.faction` with a required typed owning Character.
- Add Skills through one owner method that initializes them.
- Fail loudly when an activation has no owner.
- Make cooldown-versus-SkillBar physics ordering explicit with process priorities or one owner-controlled advance order.
- Continue passing Modifiers explicitly until the first real Modifier source settles gathering.

## S3 — Medium: Enemy behavior and Character responsibilities are welded together

`enemy.gd` currently handles:

- Incoming Damage and feedback.
- Stagger and knockback.
- Death.
- Navigation and avoidance.
- Aggro target storage.
- Chase/stop behavior.

That is acceptable for one Enemy, but different Enemy kinds will either fork this script or add conditionals.

At the first Enemy Skill or second Enemy behavior:

- Move common Character hit handling out first.
- Keep locomotion/navigation local to the Enemy body.
- Move “stand, chase, stop, activate” into one concrete behavior component.
- Derive attack distance from the chosen Skill’s Range rather than maintaining unrelated `reach_distance` tuning.
- Do not build a state-machine framework or behavior tree yet.

## S4 — Medium: HUD reaches laterally into Player internals

`ui/skill_bar_hud.gd:95-123`:

```gdscript
func _on_touch_started(at: Vector2, slot: int) -> void:
	_landed[slot] = at
	var skill := player.skill_bar.skill_in(slot)
	# ...
	player.skill_bar.press(slot)
	# ...

func _on_touch_moved(at: Vector2, slot: int) -> void:
	# ...
	var skill := player.skill_bar.skill_in(slot)
	player.show_aim(skill, player.aim_from_drag(skill, drag, drag_full_range), cancelling)
```

The sandbox injects deep cross-branch NodePaths in `scenes/sandbox.tscn:146-155`:

```text
Sandbox
├─ PixelatedView/SubViewport/World/Player
└─ HUD
   ├─ PauseMenu ────────> Player, SkillBarHud
   └─ SkillBarHud ──────> Player
```

This is typed and explicit, but it departs from the repository’s parent-call-down/child-signal-up rule. It also couples UI to Player’s Skill storage and aiming implementation.

Do not add an event bus. Before the second level or replaceable Player:

- Let HUD controls emit activation/editing intent.
- Let the game root wire those signals to the active Player.
- Continue consuming `SkillBar.changed` and `Player.skill_activated` as output signals.
- Keep aiming presentation local unless a second consumer demonstrates a better seam.

## S5 — High, current defect: Skill touches survive focus loss

`TouchStick` deliberately drops a missing finger on pause or application focus loss:

```gdscript
# ui/touch_stick.gd:63-68
func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_release()
```

Skill buttons have no corresponding cancellation. Their `_finger`, the HUD’s `_held_slot`/`_aiming_slot`, and aim marker can survive an iOS interruption or suspend.

`ui/skill_slot_button.gd:99-117`:

```gdscript
func _input(event: InputEvent) -> void:
	var touch := event as InputEventScreenTouch
	if touch:
		if touch.pressed and _finger == NO_FINGER:
			_finger = touch.index
			# ...
		elif not touch.pressed and touch.index == _finger:
			_finger = NO_FINGER
			# ...
```

Add one HUD-owned cancellation path that:

- Clears held and aiming slots.
- Releases `SkillBar` holds.
- Hides the Aim marker.
- Makes each button forget its finger.
- Runs on pause, focus loss, and tree exit.

This needs a mobile regression test analogous to `TouchStick`.

## S6 — Medium/watch: HitFeedback is hidden global runtime state

`skills/hit_feedback.gd:32-52`:

```gdscript
static var _hitstops := 0

func play_impact(viewport: Viewport, freezes := true) -> void:
	if freezes and hitstop > 0.0:
		_hitstops += 1
		Engine.time_scale = 0.0
		# ...

static func _end_hitstop() -> void:
	_hitstops -= 1
	if _hitstops == 0:
		Engine.time_scale = 1.0
```

The shared `.tres` is appropriate tuning data. The static counter and engine/camera mutation make it a global gameplay service outside scene ownership.

It is safe while Hit feedback is the only time-scale and camera-offset owner. Before slow motion, another camera effect, or Enemy hit feedback:

- Move runtime coordination into a scene-owned component.
- Preserve the Resource as tuning data.
- Restore the previous time scale rather than assuming `1.0`.
- Settle whether Enemy attacks and periodic Damage freeze or shake the world.

## S7 — High before content growth: resources are loaded but not semantically validated

`tools/load_all.gd:28-35`:

```gdscript
func _find(dir: String) -> PackedStringArray:
	# ...
	for file in DirAccess.get_files_at(dir):
		if file.get_extension() in ["gd", "tscn"]:
			found.append(dir.path_join(file))
```

Tags and number names remain free-form `StringName`s. This is appropriate for data-driven and potentially moddable content, but `Cooldwon` or `Projectiles` silently does nothing.

Before many Skills and Modifiers:

- Include `.tres` in loading checks.
- Add one content-validation test over shipped Skill and Modifier resources.
- Validate nonempty titles/tags/numbers, valid TagChange shapes, null entries, positive base Cooldowns, and unique stable IDs once IDs exist.
- Keep StringNames; do not replace the system with enums.
- Document that exported enums stored by scenes/resources are append-only. Inserting enum members in the middle silently changes saved integer meanings.

# Spec and domain-model findings

## D1 — Blocker: Modifier pool arithmetic conflicts with the glossary

Snapshot applies number changes from tag-changing Modifiers as a complete arithmetic pool before all other number changes.

`skills/snapshot.gd:25-43`:

```gdscript
## ...number changes apply in two pools, those of Modifiers that change tags first,
## then every other's...
static func of(...):
	var tag_pool: Array[NumberChange] = []
	var number_pool: Array[NumberChange] = []
	# ...
	(number_pool if modifier.tag_changes.is_empty() else tag_pool).append_array(modifier.number_changes)
	# ...
	result[name] = _stack(_stack(own_numbers[name], name, tag_pool), name, number_pool)
```

The test intentionally locks that behavior:

```gdscript
# tests/test_snapshot.gd:186-194
func test_a_tag_changers_number_changes_are_a_pool_of_their_own() -> void:
	# 50% Increased on the tag-changing Modifier, then +2 elsewhere
	var snapshot := _snapshot(SPELL, [_modifier([], Skill.RANGE, NumberChange.Kind.FLAT, 2.0), pierces])
	assert_eq(snapshot.number(Skill.RANGE), 17.0, "10 × 1.5, then + 2")
```

But the glossary promises:

```text
Increased:
A Modifier's percentage that is added to every other increased or reduced percentage
on the same number, before they change it together.

More:
A Modifier's percentage that changes a number on its own, after every Increased percentage.
```

The implementation matches the Skill-tags specification’s “tag changes with all their effects” wording, but conflicts with the player-facing definition.

Concrete consequence: 20% Increased on a tag-changing Modifier and 10% Increased on another produce `×1.2 ×1.1 = ×1.32`, not the glossary’s `×1.30`.

This must be settled before authoring more Modifiers:

- If all Increased values on a number sum globally, TagPass should decide applicability and number changes should then stack together.
- If pool-local Increased is intended, the glossary and player-facing explanation must expose those pools.

The current hidden distinction—whether the same Modifier also edits a tag—is not predictable from “Increased.”

## D2 — High before gear: Modifier identity is Resource pointer identity

`skills/snapshot.gd:33-39`:

```gdscript
var counted: Array[Modifier] = []
# ...
if modifier not in counted and tag_pass.applies(modifier):
	counted.append(modifier)
```

`tests/test_snapshot.gd:230-232`:

```gdscript
func test_a_modifier_listed_twice_applies_once() -> void:
	var farther := _modifier([], Skill.RANGE, NumberChange.Kind.FLAT, 2.0)
	assert_eq(_snapshot(SPELL, [farther, farther]).number(Skill.RANGE), 12.0)
```

Two gear items referencing the same `.tres` apply once; two equivalent duplicated Resources apply twice. Storage aliasing therefore determines game rules.

Before the first real Modifier source, distinguish:

- Modifier definition: immutable reusable data.
- Modifier occurrence: one grant from one item, talent, buff, or support.

The tag pass must apply each occurrence once. Deduplication should prevent accidentally gathering the same occurrence twice, not prevent two legitimate sources from sharing a definition.

Do not build a source manager before that feature; settle the identity rule first.

## D3 — High, current invariant defect: negative flat changes bypass all bounds

`skills/snapshot.gd:49-62`:

```gdscript
static func _stack(value: float, name: StringName, changes: Array[NumberChange]) -> float:
	var increased := 0.0
	var more := 1.0
	for change in changes:
		match change.kind:
			NumberChange.Kind.FLAT:
				value += change.amount
			# ...
	return value * maxf(0.0, 1.0 + increased / 100.0) * more
```

The “never below zero” test covers only Increased and More. A negative flat change can produce:

- Negative Damage, which heals through `Health.damage()`.
- Negative Speed, which moves a projectile backwards while `_flown` decreases forever.
- Negative Range passed into a physics shape.
- Negative Knockback reversing direction.
- Negative healing that reaches zero without `died`, because only `damage()` emits it.

All current Skill numbers have a minimum of zero. Enforce that at the resolved-number boundary and reject negative `Health.damage()`/`heal()` inputs. Cooldown’s positive minimum remains a separate explicitly deferred rule.

## D4 — High: a hit lacks source identity and persistent lifetime

`characters/hurtbox/hurtbox.gd:10-20`:

```gdscript
signal hit_taken(direction: Vector3, snapshot: Snapshot)

func take_hit(direction: Vector3, snapshot: Snapshot) -> bool:
	if collision_layer == 0:
		return false
	hit_taken.emit(direction, snapshot)
	return true
```

`skills/fireball/fireball.gd:30-39`:

```gdscript
func _activate(snapshot: Snapshot, aim: Vector3) -> void:
	var ball: Projectile = ProjectileScene.instantiate()
	ball.snapshot = snapshot
	ball.top_level = true
	# ...
	add_child(ball)
```

Future mechanics blocked by the current payload include:

- Aggroing the actual attacker.
- Kill credit and experience.
- Leech and reflect.
- Source-side “on hit/on kill” effects.
- Effects surviving the caster’s death.

`top_level` changes transform inheritance, not scene-tree lifetime. An Enemy projectile parented beneath its Skill disappears when that Enemy is freed.

Before the first Enemy Skill, reopen the Factions/Health rule that a hit carries “direction and Snapshot, nothing else.” Introduce one small immutable hit/activation context containing only demonstrated facts—at minimum Snapshot and source Character. Do not add speculative critical-hit/status fields.

Persistent projectiles and areas should live under a world-owned `Effects` node or equivalent scene-owned host. Contact resolution should return whether the hit landed so invulnerability or stale Hurtboxes do not consume Pierce accidentally.

## D5 — High: Hurtbox discovery silently truncates at 32

`characters/hurtbox/hurtbox.gd:46-61`:

```gdscript
static func around(world: World3D, centre: Vector3, reach: float, mask: int) -> Array[Hurtbox]:
	# ...
	var hurtboxes: Array[Hurtbox] = []
	for result in world.direct_space_state.intersect_shape(query, 32):
		var hurtbox := result.collider as Hurtbox
		if hurtbox:
			hurtboxes.append(hurtbox)
	return hurtboxes
```

The Enemy spec explicitly allows 20–40 Enemies on screen. Future area Skills can therefore miss arbitrary targets. Auto-aim can miss the actual nearest target because physics does not promise nearest-first ordering.

Minimum direction:

- Define the supported active-Hurtbox/query ceiling.
- Query with enough headroom.
- Detect and fail loudly in debug when the result saturates.
- Add a 33+ Hurtbox regression.

Do not add a global spatial registry until profiling proves bounded physics queries inadequate.

## D6 — High, current defects: Fireball Range and collision do not match their contracts

Fireball starts ahead of the Character:

```gdscript
# skills/fireball/fireball.gd:30-39
func _activate(snapshot: Snapshot, aim: Vector3) -> void:
	# ...
	add_child(ball)
	ball.global_position = global_position + facing * LAUNCH_OFFSET + Vector3.UP * FLIGHT_HEIGHT
```

Then it travels the full Snapshot Range from that launch point:

```gdscript
# skills/fireball/projectile.gd:27-32
func _physics_process(delta: float) -> void:
	var step := snapshot.number(Fireball.SPEED) * delta
	global_position += direction * step
	_flown += step
	if _flown >= snapshot.number(Skill.RANGE):
		queue_free()
```

Two issues:

1. A Range-10 Fireball reaches 10.45 units from the Character, while aiming displays 10.
2. Direct position changes use sampled overlap signals, so a fast projectile or long mobile frame can cross a wall or Hurtbox without ever overlapping it.

Fix before adding Speed Modifiers:

- Count launch offset against Range.
- Sweep the collision shape over each movement segment.
- Process contacts in travel order, with walls always stopping it.
- Test a thin collider crossed in one tick and an endpoint measured from the Character.

Keep it Fireball-specific for now or rename it `FireballProjectile`. Extract generic projectile pieces only when a second projectile demonstrates the repeated shape.

## D7 — Medium: Snapshot immutability is shallow

`skills/snapshot.gd:9-22`:

```gdscript
var tags: Array[StringName]
var numbers: Dictionary[StringName, float]
var why: Array[String]

func _init(...):
	tags = snapshot_tags
	numbers = snapshot_numbers
	why = snapshot_why
	tags.make_read_only()
	numbers.make_read_only()
	why.make_read_only()
```

The containers reject mutation, but callers can replace `snapshot.tags`, `snapshot.numbers`, or `snapshot.why` wholesale.

Because Snapshot immutability is a core domain guarantee, use private backing fields and getter-only access. Prefer domain queries such as `number()`, `has_tag()`, and diagnostic access over exposing replaceable state.

## D8 — Medium: zero Stagger is silently changed to 0.02 seconds

`characters/enemy/enemy.gd:61-68`:

```gdscript
func _on_hit_taken(direction: Vector3, snapshot: Snapshot) -> void:
	health.damage(snapshot.number(Skill.DAMAGE))
	# ponytail: a Stagger of 0 would need an instant push; the shortest slide stands in for it.
	_stagger_time = maxf(snapshot.number(Skill.STAGGER), 0.02)
```

A zero-Stagger Skill still interrupts chasing. A Modifier cannot remove Stagger fully.

Settle the rule before a Skill reaches zero:

- Zero Stagger and zero Knockback should likely do nothing.
- Zero Stagger with Knockback needs an explicit instant-push or no-push rule.
- Do not retain an undocumented minimum as content multiplies.

## D9 — Design gates that must be settled, not guessed by agents

### Timed activations

`try_activate()` snapshots, starts Cooldown, and performs the effect synchronously. Enemy telegraphs, channels, Leap, and interruptible Skills need decisions about:

- When Snapshot and Aim become fixed.
- Whether Stagger cancels the activation.
- Whether Cooldown starts at wind-up or release.
- Whether the Character can move or activate another Skill.

Settle this before the first telegraphed Enemy Skill.

### Aim’s data shape

Aim is currently a `Vector3`, with `Vector3.INF` meaning “not supplied.” Around-the-player Skills receive a fabricated Facing vector. A targeted curse can preview a Hurtbox through `target_for()` but cannot receive that exact Hurtbox at activation; it must query again.

Before the first targeted or Enemy Skill, decide whether Aim can carry:

- Direction only.
- A ground spot.
- A specific Hurtbox.
- No Aim.

Do not introduce a strategy framework before those cases are specified.

### Defender-side resolution

Snapshot contains attacker-side activation state. Resistances, armour, “more Damage against staggered Enemies,” and immunity depend on the target at hit time. Design this with Damage types rather than forcing it into Snapshot now.

### Character numbers

Modifiers currently change Skills only. Gear will also want maximum Health and Movement speed. Decide with the first gear system whether these use the same stacking vocabulary or a separate Character-number model.

# Growth gates

| Trigger | Required work first |
|---|---|
| First Enemy Skill | Character owner boundary, Player Hurtbox, hit source context, persistent-effect lifetime, timed activation and feedback rules |
| First real Modifier source | Definition-versus-occurrence identity and stacking semantics |
| Third/fourth Skill | Extract only demonstrated projectile/swing/area execution pieces |
| First gained Skill or save file | Stable Skill IDs, one runtime Skill instance per Character, serializable slot/Cooldown state |
| Second Enemy kind | Extract the demonstrated common Enemy scene and behavior component |
| Second level/session | Split persistent game root from replaceable level content |
| Slow motion/second camera effect | Scene-owned Hit feedback runtime coordinator |
| Horde-scale target | Profile navigation, avoidance, Standee shader/process, Snapshot diagnostics, and idle Skill callbacks |

A suitable scene boundary before the second level:

```text
Game
├─ PixelatedView/SubViewport/World
│  ├─ Level
│  ├─ Player
│  └─ Effects
└─ HUD
```

The Level owns geometry, navigation, props, Enemy placement/spawning, and a Player start marker. Game owns the active Player, camera, HUD wiring, and state that survives level replacement.

# Performance watch list

These are not reasons for premature systems:

- Every ready Skill still receives `_physics_process()`. Disable processing while ready once Characters own many Skills.
- Dormant Enemies still run physics and avoidance. Measure with the intended 20–40 Enemy pack before changing behavior.
- Chasing Enemies update navigation targets every physics frame.
- Standee’s outline shader samples the texture 32 times per fragment and updates shader parameters every frame.
- `Skill.number()` constructs a complete Snapshot, including `why` strings; touch aiming can do this repeatedly per drag event.
- Modifier membership scans become quadratic at large active Modifier counts.

Profile on target hardware before adding pooling, schedulers, spatial indexes, or shader rewrites. The only immediate performance-related fix is explicit Skill/SkillBar processing order because it affects correctness.

# Recommended sequence

1. Settle and record:
   - Modifier pool arithmetic.
   - Modifier occurrence identity.
   - Character boundary.
   - Hit/source context.
   - Aim and timed-activation rules.
2. Fix current invariants:
   - Negative flat results and Health input validation.
   - Hurtbox query ceiling.
   - Projectile Range and swept collision.
   - Snapshot property immutability.
   - Skill-touch focus cancellation.
   - `.tres` loading and content validation.
3. Before the first Enemy Skill:
   - Add the thin Character foundation.
   - Give Skills an owning Character and one initialization path.
   - Extract Stagger/hit reaction.
   - Add source-aware hit context and world-owned persistent effects.
4. Extract Enemy behavior only with the first concrete attacking Enemy.
5. Add IDs/catalogs only with unlocking, saving, or a second Modifier source.
6. Split Game and Level before creating the second level.

# Explicitly not recommended

- ECS.
- Gameplay autoloads or an event bus.
- Dependency injection/service locators.
- A universal Character-stat or effect framework.
- A behavior tree or generic state machine.
- Splitting Skill definitions from Skill scenes now.
- A generic projectile framework before a second projectile.
- Object pooling or a custom spatial index without profiling.
- Treating five Skill slots or two current Factions as accidental magic numbers.

Summary: 7 Standards/Godot findings, worst being the missing Character/Skill ownership boundary; 9 Spec/domain findings, worst being the unresolved Modifier arithmetic contract.
