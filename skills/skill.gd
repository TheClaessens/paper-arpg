@tool
class_name Skill
extends Node3D
## A Skill (see GLOSSARY.md): something the player activates from a Skill slot. Each Skill is
## a node on the Character that has it, so it can reach the world from where the Character
## stands. try_activate() is the one way to set it off, and the Skill runs its own Cooldown.
## Subclasses do their work in _activate(). Each Skill script is a @tool, as this one is, so the
## editor shows its configuration warnings.

## Its Cooldown has run out: it can be activated again.
signal ready_again

## How a Skill aims. AROUND: activated where the Character stands. AUTO: toward the nearest Enemy
## near Facing. AIMED: auto-aimed too, and on touch it can also be aimed by hand.
enum Aim { AROUND, AUTO, AIMED }

## Auto-aim takes an Enemy at most this far either side of Facing.
const AUTO_AIM_ANGLE := 60.0

## The one table of implied Skill tags: a Skill with the key tag also has each tag it lists.
const IMPLIED_TAGS: Dictionary[StringName, Array] = {
	&"Fire": [&"Elemental"],
}

## The names of the Skill's numbers (see numbers()), as Modifiers and Snapshots know them.
const COOLDOWN := &"Cooldown"
const RANGE := &"Range"
const KNOCKBACK := &"Knockback"
const STAGGER := &"Stagger"

## The Skill's Skill tags, as set in its scene: what kind of Skill it is. Implied tags are
## left out here; with_implied() works them out.
@export var tags: Array[StringName] = []
## The Skill's name, as the player sees it.
@export var title := ""
## The Skill's picture on its Skill slot's button and in the Skill drawer.
@export var icon: Texture2D
## How the Skill aims.
@export var aim := Aim.AUTO
## Whether it lands on a spot (aimed by how far, too) rather than going a direction.
@export var aims_at_spot := false
## Whether holding its slot activates it again each time its Cooldown ends.
@export var repeats_while_held := false
## The Skill's Cooldown: how long after an activation starts before it can be activated again,
## from any slot. The only thing that limits how often it is activated, so every Skill needs one
## above 0. Modifiers can change it: the Cooldown that runs is the activation's Snapshot's.
@export var cooldown := 0.0:
	set(value):
		cooldown = value
		update_configuration_warnings()
## The Skill's Range: how far it reaches from the Character's centre, in world units.
@export var range := 1.0
## How far a hit pushes an Enemy, in world units.
@export var knockback := 0.0
## How long a hit Enemy slides without chasing (its Stagger), in seconds.
@export var stagger := 0.0

## Seconds until the Skill can be activated again. The Skill runs this clock itself.
var cooldown_left := 0.0

var _cooldown_length := 0.0 # how long the running cooldown is in all


## Whether its cooldown has run out.
func is_ready() -> bool:
	return cooldown_left <= 0.0


## Starts a cooldown `seconds` long: an activation's Snapshot's Cooldown.
func start_cooldown(seconds: float) -> void:
	cooldown_left = seconds
	_cooldown_length = seconds


## Runs the cooldown on by `delta` seconds, emitting ready_again the moment it runs out.
func cool_down(delta: float) -> void:
	if is_ready():
		return
	cooldown_left = maxf(0.0, cooldown_left - delta)
	if is_ready():
		ready_again.emit()


func _physics_process(delta: float) -> void:
	if not Engine.is_editor_hint():
		cool_down(delta)


## How much of the cooldown is left: 1 just activated, 0 ready.
func cooldown_fraction() -> float:
	return cooldown_left / _cooldown_length if _cooldown_length > 0.0 else 0.0


## Warns in the editor about a Skill without a Cooldown: nothing would limit its activations.
func _get_configuration_warnings() -> PackedStringArray:
	return ["Every Skill needs a Cooldown above 0."] if cooldown <= 0.0 else []


## `given` plus every tag IMPLIED_TAGS says they imply. Worked out from the tags given, so a
## set without Fire has no Elemental. One level deep: an implied tag implies nothing further.
static func with_implied(given: Array[StringName]) -> Array[StringName]:
	var all := given.duplicate()
	for tag in given:
		for implied: StringName in IMPLIED_TAGS.get(tag, []):
			if implied not in all:
				all.append(implied)
	return all


## The Skill's numbers by name, for Modifiers to change. A Skill with numbers of its own adds
## them to these.
func numbers() -> Dictionary[StringName, float]:
	return {COOLDOWN: cooldown, RANGE: range, KNOCKBACK: knockback, STAGGER: stagger}


## Activates the Skill aimed at `aim` with the Character's `modifiers`, unless it is cooling
## down: makes the activation's Snapshot, starts the Snapshot's Cooldown, then does what the
## Skill does. Whether it activated.
func try_activate(aim: Vector3, modifiers: Array[Modifier]) -> bool:
	if not is_ready():
		return false
	var made := snapshot(modifiers)
	start_cooldown(made.number(COOLDOWN))
	_activate(made, aim)
	return true


## The Skill as one activation sees it: a Snapshot with every one of `modifiers` whose filter
## matches its tags, implied ones included.
func snapshot(modifiers: Array[Modifier]) -> Snapshot:
	var all_tags := with_implied(tags)
	var why: Array[String] = []
	for modifier in modifiers:
		why.append(modifier.explain(all_tags))
	return Snapshot.new(all_tags, _numbers_with(all_tags, modifiers), why)


## The number called `name` as it stands now with `modifiers`, outside any activation: for
## aiming, which follows the Modifiers as they come and go.
func number(name: StringName, modifiers: Array[Modifier]) -> float:
	return _numbers_with(with_implied(tags), modifiers)[name]


## Each of the Skill's numbers with every one of `modifiers` whose filter matches `all_tags`.
func _numbers_with(all_tags: Array[StringName], modifiers: Array[Modifier]) -> Dictionary[StringName, float]:
	var applied: Array[NumberChange] = []
	for modifier in modifiers:
		if modifier.missing(all_tags).is_empty():
			applied.append_array(modifier.number_changes)
	var result := numbers()
	for name in result:
		result[name] = stack(result[name], name, applied)
	return result


## The number called `name`, `value` at first, with each of `changes` to it: flat additions
## first, then the sum of every Increased percentage, then each More percentage on its own.
## Neither takes a number below 0: Increased stops at -100%, and so does each More.
static func stack(value: float, name: StringName, changes: Array[NumberChange]) -> float:
	var increased := 0.0
	var more := 1.0
	for change in changes:
		if change.number != name:
			continue
		match change.kind:
			NumberChange.Kind.FLAT:
				value += change.amount
			NumberChange.Kind.INCREASED:
				increased += change.amount
			NumberChange.Kind.MORE:
				more *= maxf(0.0, 1.0 + change.amount / 100.0)
	return value * maxf(0.0, 1.0 + increased / 100.0) * more


## Where auto-aim points, as an offset on the ground from the Character: the nearest of
## `enemy_offsets` within AUTO_AIM_ANGLE of `facing`, or else along `facing`. Never farther
## than `skill_range`. Which Enemies are within Range is the caller's to ask (see aim_toward()).
static func auto_aim(facing: Vector3, skill_range: float, enemy_offsets: Array[Vector3]) -> Vector3:
	var best := facing * skill_range
	var best_distance := INF
	for offset in enemy_offsets:
		var flat := Vector3(offset.x, 0.0, offset.z)
		var distance := flat.length()
		if distance < best_distance and rad_to_deg(flat.angle_to(facing)) <= AUTO_AIM_ANGLE:
			best = flat.limit_length(skill_range)
			best_distance = distance
	return best


## The Enemy nearest `spot` on the ground within `reach` of it, or null (see nearest_to()).
static func enemy_nearest(world: World3D, spot: Vector3, reach: float) -> Enemy:
	var enemies := enemies_around(world, spot, reach)
	var positions: Array[Vector3] = []
	for enemy in enemies:
		positions.append(enemy.global_position)
	var i := nearest_to(spot, positions, reach)
	return enemies[i] if i >= 0 else null


## Which of `enemies` (positions) is nearest `spot` on the ground and within `reach` of it, or -1.
static func nearest_to(spot: Vector3, enemies: Array[Vector3], reach: float) -> int:
	var best := -1
	var best_distance := reach
	for i in enemies.size():
		var distance := Vector2(enemies[i].x - spot.x, enemies[i].z - spot.z).length()
		if distance <= best_distance:
			best = i
			best_distance = distance
	return best


## Every Enemy in `world` with any part of its body within `reach` of `centre`.
## The physics engine finds them: the sphere masks only the `enemy` layer, and an Enemy's body
## is its collision shape.
static func enemies_around(world: World3D, centre: Vector3, reach: float) -> Array[Enemy]:
	var sphere := SphereShape3D.new()
	sphere.radius = reach
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = sphere
	query.transform = Transform3D(Basis.IDENTITY, centre + Vector3.UP * 0.5) # body height
	query.collision_mask = 1 << 2 # layer 3, `enemy`
	var enemies: Array[Enemy] = []
	for result in world.direct_space_state.intersect_shape(query, 32):
		var enemy := result.collider as Enemy
		if enemy:
			enemies.append(enemy)
	return enemies


## Auto-aim from where the Character stands (see auto_aim()), as far as `reach`: the Skill's
## Range as it stands now. An Enemy whose body is within reach but whose centre is past it is
## aimed at as far as the reach.
func aim_toward(facing: Vector3, reach: float) -> Vector3:
	var offsets: Array[Vector3] = []
	for enemy in _enemies_within(reach):
		offsets.append(enemy.global_position - global_position)
	return auto_aim(facing, reach, offsets)


## What the Skill does when activated, as `snapshot` says, aimed at `aim`: an offset on the
## ground from the Character. Its direction is where the Skill goes; for a Skill that lands on a
## spot, its length is how far. A Skill reads its numbers from `snapshot`, not from itself.
## Each Skill overrides it; try_activate() calls it.
func _activate(_snapshot: Snapshot, _aim: Vector3) -> void:
	pass


## What an activation aimed at `aim` would pick out, to ring it while aiming; null for most Skills.
func target_for(_aim: Vector3) -> Node3D:
	return null


## Every Enemy whose body is within `reach` of the Character, in any direction.
func _enemies_within(reach: float) -> Array[Enemy]:
	return enemies_around(get_world_3d(), global_position, reach)


## Lands one activation's hits: each Enemy in `hits` is pushed along its direction (a unit
## vector on the ground) with the Knockback and Stagger of the activation's `snapshot`. The
## impact (hitstop, screen shake) plays once for the whole activation, however many Enemies it hit. For the Skills themselves.
func _land_hits(hits: Dictionary[Enemy, Vector3], snapshot: Snapshot) -> void:
	if hits.is_empty():
		return
	for enemy in hits:
		enemy.take_hit(hits[enemy], snapshot.number(KNOCKBACK), snapshot.number(STAGGER))
	HitFeedback.shared().play_impact(get_viewport())
