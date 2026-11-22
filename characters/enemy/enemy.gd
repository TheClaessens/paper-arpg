class_name Enemy
extends Character
## A Character of the Enemies' Faction (see GLOSSARY.md). Stands still until its Aggro notices
## the player, then chases them along the navmesh for good, stopping within reach.
## Staggered, it slides with the knockback and doesn't chase until the Stagger ends. At 0
## Health it dies: it sinks through the floor where it stood and is gone.

## Stops chasing this close to the target, in world units.
@export var reach_distance := 1.0
## Chases again once the target is this far away. Larger than `reach_distance`, so a small
## step by the player doesn't flick the Enemy between walking and standing.
@export var resume_distance := 1.3

var _target: Node3D
var _chasing := false

@onready var _movement: Movement = $Movement
@onready var _agent: NavigationAgent3D = $NavigationAgent3D


func _ready() -> void:
	super()
	assert(hurtbox, "An Enemy needs a Hurtbox")
	health.died.connect(_die)
	($Aggro as Aggro).aggroed.connect(func(target: Node3D) -> void: _target = target)
	_agent.velocity_computed.connect(_on_velocity_computed)
	_agent.max_speed = _movement.speed # avoidance never speeds an Enemy past its own top speed


## Whether to chase a target `distance` away, given whether the Enemy is chasing now.
func should_chase(chasing: bool, distance: float) -> bool:
	return distance > (reach_distance if chasing else resume_distance)


func _physics_process(delta: float) -> void:
	if _slide(delta):
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


## Staggered, it slides with the knockback and doesn't chase: it skips the navigation agent.
## Says whether it is staggered. A frame the world is frozen in moves nothing, and the slide
## ends at rest.
func _slide(delta: float) -> bool:
	if _stagger == null or not _stagger.is_active():
		return false
	velocity = _stagger.next_velocity(delta)
	if delta > 0.0: # not in a frozen frame, where move_and_slide() would only push it out of what presses on it
		move_and_slide()
	if not _stagger.is_active():
		velocity = Vector3.ZERO
	return true


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


## At 0 Health: stops chasing and sliding (so the killing hit doesn't knock it back), leaves
## every collision layer so nothing can hit, aim at, ring or bump into it, hides its Health bar,
## and sinks through the floor where it stood. Gone once the sink ends.
func _die() -> void:
	set_physics_process(false)
	_standee.play(&"idle") # no walk wobble on top of the sink's
	_agent.avoidance_enabled = false # other Enemies no longer steer around it
	collision_layer = 0
	hurtbox.collision_layer = 0
	health_bar.hide()
	_standee.sunk.connect(queue_free)
	_standee.sink()


## The part of `vector` along the ground. Path points sit a little above the floor.
func _flat(vector: Vector3) -> Vector3:
	return Vector3(vector.x, 0.0, vector.z)
