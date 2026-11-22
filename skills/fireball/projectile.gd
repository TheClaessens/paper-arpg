class_name Projectile
extends Area3D
## Fireball's ball. Thrown with launch(), it flies straight at its Hit's Projectile speed and lands
## its Hit on each hostile Hurtbox it touches, until it has flown its Hit's Range, or it touches a
## wall or a prop. With Pierce among its Hit's Snapshot's tags it passes through the first Hurtbox
## its Hit lands on and stops at the next; a Hurtbox its Hit misses doesn't count. It looks for
## walls and props on the `world` layer and for Hurtboxes on the layers launch() adds. It lives in
## the world beside that Character (see Skill._add_to_world()) and needs neither the Skill nor the
## Character once thrown, so it flies on and lands its Hit after they are gone.

## How far in front of its Character's centre it starts, and how high it flies.
const LAUNCH_OFFSET := 0.45
const FLIGHT_HEIGHT := 0.5

## The Hit it carries and lands: its throw's Snapshot and the Character that threw it.
var hit: Hit

var _direction := Vector3.FORWARD # a unit vector on the ground
var _flight := 0.0 # how far its centre flies before it ends
var _flown := 0.0
var _hurtboxes_hit: Array[Hurtbox] = [] # those its Hit landed on


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


## Throws it, once it is in the world (see Skill._add_to_world()), from `centre`, the centre of the
## Character that throws it, along `direction` (a unit vector on the ground). It carries `ball_hit`,
## which it lands on each Hurtbox it touches on the layers of `mask`. It starts LAUNCH_OFFSET along
## `direction` and FLIGHT_HEIGHT up, and flies until its centre has flown its Hit's Range.
func launch(ball_hit: Hit, centre: Vector3, direction: Vector3, mask: int) -> void:
	hit = ball_hit
	_direction = direction
	collision_mask |= mask
	global_position = centre + direction * LAUNCH_OFFSET + Vector3.UP * FLIGHT_HEIGHT
	_flight = hit.snapshot.number(Skill.RANGE)


# ponytail: moves by setting its position and trusts the physics step's overlaps, so it can skip
# whatever is thinner than one step (Projectile speed / 60). At Fireball's 12 a step is 0.2, and
# only a graze within 0.011 of a Hurtbox's edge can slip by. Above 24 a Hurtbox passed more than
# 0.40 from its centre can slip by, above 46 the thinnest prop head-on (a table), above 54 a
# Hurtbox head-on, above 84 a wall. With the first Modifier on Projectile speed, sweep it instead:
# cast_motion along each step for the wall or prop that stops it, and the Hurtboxes the swept ball
# touches before that point, taken in travel order.
func _physics_process(delta: float) -> void:
	var step := hit.snapshot.number(Fireball.PROJECTILE_SPEED) * delta
	global_position += _direction * step
	_flown += step
	if _flown >= _flight:
		queue_free()


## A wall or a prop: it stops the ball.
func _on_body_entered(_body: Node3D) -> void:
	queue_free()


func _on_area_entered(area: Area3D) -> void:
	if is_queued_for_deletion(): # it ended earlier in this physics step: nothing else counts
		return
	var hurtbox := area as Hurtbox
	if not hurtbox or hurtbox in _hurtboxes_hit: # touching it again after knocking it ahead
		return
	if not hit.land({hurtbox: _direction}): # its Character died earlier in this physics step
		return
	_hurtboxes_hit.append(hurtbox)
	var passes_through := 1 if SkillTag.PIERCE in hit.snapshot.tags else 0
	if _hurtboxes_hit.size() > passes_through:
		queue_free()
