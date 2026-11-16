class_name Skill
extends Node3D
## A Skill (see GLOSSARY.md): something the player uses from a Skill slot. Each Skill is a
## node on the Character, so it can reach the world from where the Character stands.
## Subclasses do the work in use().

## How a Skill aims. AROUND: used where the Character stands. AUTO: toward the nearest Enemy
## near Facing. AIMED: auto-aimed too, and on touch it can also be aimed by hand.
enum Aim { AROUND, AUTO, AIMED }

## Auto-aim takes an Enemy at most this far either side of Facing.
const AUTO_AIM_ANGLE := 60.0

## The Skill's name, as the player sees it.
@export var title := ""
## The Skill's picture on its Skill slot's button and in the Skill drawer.
@export var icon: Texture2D
## How the Skill aims.
@export var aim := Aim.AUTO
## Whether it lands on a spot (aimed by how far, too) rather than going a direction.
@export var aims_at_spot := false
## Whether holding its slot uses it again each time its Use time ends.
@export var repeats_while_held := false
## The Skill's Use time: how long one use takes. The Skill bar takes no new use until it has passed.
@export var use_time := 0.4
## The Skill's cooldown: how long after a use starts before it can be used again, from any slot.
## 0 for none. Its Use time still blocks the whole Skill bar meanwhile.
@export var cooldown := 0.0
## The Skill's Range: how far it reaches from the Character's centre, in world units.
@export var range := 1.0
## How far a hit pushes an Enemy, in world units.
@export var knockback := 0.0
## How long a hit Enemy slides without chasing (its Stagger), in seconds.
@export var stagger := 0.0

## Seconds until the Skill can be used again. The Skill bar runs this clock.
var cooldown_left := 0.0


## Whether its cooldown has run out (or it has none).
func is_ready() -> bool:
	return cooldown_left <= 0.0


## Starts the cooldown, for a use.
func start_cooldown() -> void:
	cooldown_left = cooldown


## Runs the cooldown on by `delta` seconds. True the moment it runs out.
func cool_down(delta: float) -> bool:
	if is_ready():
		return false
	cooldown_left = maxf(0.0, cooldown_left - delta)
	return is_ready()


## How much of the cooldown is left: 1 just used, 0 ready.
func cooldown_fraction() -> float:
	return cooldown_left / cooldown if cooldown > 0.0 else 0.0


## Where auto-aim points, as an offset on the ground from the Character: the nearest of
## `enemy_offsets` within `skill_range` and AUTO_AIM_ANGLE of `facing`, or else along `facing`
## as far as `skill_range`.
static func auto_aim(facing: Vector3, skill_range: float, enemy_offsets: Array[Vector3]) -> Vector3:
	var best := facing * skill_range
	var best_distance := INF
	for offset in enemy_offsets:
		var flat := Vector3(offset.x, 0.0, offset.z)
		var distance := flat.length()
		if distance <= skill_range and distance < best_distance and rad_to_deg(flat.angle_to(facing)) <= AUTO_AIM_ANGLE:
			best = flat
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


## Auto-aim from where the Character stands (see auto_aim()). An Enemy whose body is in Range
## but whose centre is past it is aimed at as far as the Range.
func aim_toward(facing: Vector3) -> Vector3:
	var offsets: Array[Vector3] = []
	for enemy in _enemies_within(range):
		var offset := enemy.global_position - global_position
		offsets.append(Vector3(offset.x, 0.0, offset.z).limit_length(range))
	return auto_aim(facing, range, offsets)


## Uses the Skill, aimed at `aim`: an offset on the ground from the Character. Its direction is
## where the Skill goes; for a Skill that lands on a spot, its length is how far.
func use(_aim: Vector3) -> void:
	pass


## What a use aimed at `aim` would pick out, to ring it while aiming; null for most Skills.
func target_for(_aim: Vector3) -> Node3D:
	return null


## Every Enemy whose body is within `reach` of the Character, in any direction.
func _enemies_within(reach: float) -> Array[Enemy]:
	return enemies_around(get_world_3d(), global_position, reach)


## Lands one use's hits: each Enemy in `hits` is pushed along its direction (a unit vector on
## the ground) with this Skill's knockback and Stagger. The impact (hitstop, screen shake)
## plays once for the whole use, however many Enemies it hit. For the Skills themselves.
func _land_hits(hits: Dictionary[Enemy, Vector3]) -> void:
	if hits.is_empty():
		return
	for enemy in hits:
		enemy.take_hit(hits[enemy], knockback, stagger)
	HitFeedback.shared().play_impact(get_viewport())
