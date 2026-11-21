class_name Enemy
extends CharacterBody3D
## A Character hostile to the player (see GLOSSARY.md). Stands still until its Aggro notices
## the player, then chases them along the navmesh for good, stopping within reach.
## A hit staggers it: it slides away with the knockback and doesn't chase until the Stagger ends.

## Stops chasing this close to the target, in world units.
@export var reach_distance := 1.0
## Chases again once the target is this far away. Larger than `reach_distance`, so a small
## step by the player doesn't flick the Enemy between walking and standing.
@export var resume_distance := 1.3

var _target: Node3D
var _chasing := false
var _stagger_left := 0.0
var _stagger_time := 0.0 # the full length of the current Stagger
var _knockback := Vector3.ZERO # direction times distance

@onready var _movement: Movement = $Movement
@onready var _standee: Standee = $Standee
@onready var _agent: NavigationAgent3D = $NavigationAgent3D


func _ready() -> void:
	($Aggro as Aggro).aggroed.connect(func(target: Node3D) -> void: _target = target)
	_agent.velocity_computed.connect(_on_velocity_computed)
	_agent.max_speed = _movement.speed # avoidance never speeds an Enemy past its own top speed


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


## Whether to chase a target `distance` away, given whether the Enemy is chasing now.
func should_chase(chasing: bool, distance: float) -> bool:
	return distance > (reach_distance if chasing else resume_distance)


## How much of a `distance`-long knockback slide is still to go with `left` seconds of a
## `stagger`-long Stagger remaining. The slide's speed falls linearly to zero, so the distance
## still to go shrinks with the square of the time left.
static func knockback_left(distance: float, stagger: float, left: float) -> float:
	return distance * (left / stagger) ** 2


## Hit by a Skill: pushed `knockback` world units along `direction` (a unit vector on the
## ground), sliding without chasing for `stagger` seconds. The Skill decides both.
func take_hit(direction: Vector3, knockback: float, stagger: float) -> void:
	# ponytail: a Stagger of 0 would need an instant push; the shortest slide stands in for it.
	_stagger_time = maxf(stagger, 0.02)
	_stagger_left = _stagger_time
	_knockback = direction * knockback
	var feedback := HitFeedback.shared()
	_standee.flash(feedback.flash)
	_standee.squash(feedback.squash)


func _physics_process(delta: float) -> void:
	if _stagger_left > 0.0:
		_slide(delta)
		return
	var direction := Vector3.ZERO
	if _target:
		_chasing = should_chase(_chasing, _flat(_target.global_position - global_position).length())
		if _chasing:
			_agent.target_position = _target.global_position
			direction = _flat(_agent.get_next_path_position() - global_position).normalized()
	# An agent ignores agents of lower priority. Within reach the Enemy holds its ground, and
	# the ones still chasing walk around it instead of shoving it onto the player.
	_agent.avoidance_priority = 0.5 if _chasing else 1.0
	var next_velocity := _movement.next_velocity(velocity, direction, delta)
	# Avoidance may bend the velocity around other Enemies and hands the result back through
	# velocity_computed later this frame. With avoidance off the agent never answers.
	if _agent.avoidance_enabled:
		_agent.velocity = next_velocity
	else:
		_on_velocity_computed(next_velocity)


func _on_velocity_computed(safe_velocity: Vector3) -> void:
	velocity = safe_velocity
	# Standing still skips move_and_slide: it would push the Enemy out of every Enemy pressing
	# into it, and a pack arriving behind would shove the first ones onto the player.
	if not velocity.is_zero_approx():
		move_and_slide()
	if velocity.is_zero_approx():
		_standee.play(&"idle")
		if _target:
			_standee.face(_target.global_position - global_position)
	else:
		_standee.play(&"walk")
		_standee.face(velocity)


## Staggered: slides with the knockback and doesn't steer. Skips the navigation agent, which
## would bend the slide around other Enemies a frame late.
func _slide(delta: float) -> void:
	if delta == 0.0: # frozen by a hitstop
		return
	# Exactly this frame's share of the slide, so the whole slide covers the knockback distance
	# at any frame rate, even when the Stagger lasts only a few frames.
	var left_after := maxf(_stagger_left - delta, 0.0)
	var distance := _knockback.length()
	var step := knockback_left(distance, _stagger_time, _stagger_left) - knockback_left(distance, _stagger_time, left_after)
	velocity = _knockback.normalized() * step / delta
	_stagger_left = left_after
	move_and_slide()
	if _stagger_left <= 0.0:
		velocity = Vector3.ZERO


## The part of `vector` along the ground. Path points sit a little above the floor.
func _flat(vector: Vector3) -> Vector3:
	return Vector3(vector.x, 0.0, vector.z)
