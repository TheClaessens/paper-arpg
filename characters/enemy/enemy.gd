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
## How hard hits land. Shared with the Skills that hit (skills/hit_feedback.tres).
@export var hit_feedback: HitFeedback

var _target: Node3D
var _chasing := false
var _stagger_left := 0.0
var _stagger_time := 0.0 # the full length of the current Stagger
var _knockback_direction := Vector3.ZERO

@onready var _movement: Movement = $Movement
@onready var _standee: Standee = $Standee
@onready var _agent: NavigationAgent3D = $NavigationAgent3D


func _ready() -> void:
	($Aggro as Aggro).aggroed.connect(func(target: Node3D) -> void: _target = target)
	_agent.velocity_computed.connect(_on_velocity_computed)
	_agent.max_speed = _movement.speed # avoidance never speeds an Enemy past its own top speed


## Whether to chase a target `distance` away, given whether the Enemy is chasing now.
func should_chase(chasing: bool, distance: float) -> bool:
	return distance > (reach_distance if chasing else resume_distance)


## The knockback slide's speed with `left` seconds of a `stagger`-long Stagger to go. It falls
## linearly to zero, so over the whole Stagger the Enemy slides exactly `distance`.
static func knockback_speed(distance: float, stagger: float, left: float) -> float:
	return 2.0 * distance * left / (stagger * stagger)


## Hit by a Skill, pushed along `direction` (a unit vector on the ground).
func take_hit(direction: Vector3) -> void:
	# ponytail: a Stagger of 0 would need an instant push; the shortest slide stands in for it.
	_stagger_time = maxf(hit_feedback.stagger, 0.02)
	_stagger_left = _stagger_time
	_knockback_direction = direction
	_standee.flash(hit_feedback.flash)
	_standee.squash(hit_feedback.squash)


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
	velocity = _knockback_direction * knockback_speed(hit_feedback.knockback, _stagger_time, _stagger_left)
	_stagger_left -= delta
	move_and_slide()
	if _stagger_left <= 0.0:
		velocity = Vector3.ZERO


## The part of `vector` along the ground. Path points sit a little above the floor.
func _flat(vector: Vector3) -> Vector3:
	return Vector3(vector.x, 0.0, vector.z)
