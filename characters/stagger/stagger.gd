class_name Stagger
extends Node
## A Character's Stagger (see GLOSSARY.md): the short time after a hit when it slides with the
## knockback and doesn't walk. Another hit restarts it; a hit with a Stagger of 0 doesn't stagger.
## The Character starts it when hit and asks it each physics frame whether it is staggered and how
## fast to slide, then moves itself, as it asks Movement how fast to walk. It has no process of
## its own, so it stops when its Character stops. A Character without one is never staggered.

var _left := 0.0 # seconds still to go
var _length := 0.0 # the whole Stagger, in seconds
var _knockback := Vector3.ZERO # direction on the ground times distance


## Staggers it for `seconds`, sliding `knockback` (a direction on the ground times a distance in
## world units) over that time, fastest at first. A Stagger already running restarts with these.
## A Stagger of 0 or less does nothing, and leaves one already running as it is.
func start(knockback: Vector3, seconds: float) -> void:
	if seconds <= 0.0:
		return
	_length = seconds
	_left = seconds
	_knockback = knockback


## Whether it is staggered now.
func is_active() -> bool:
	return _left > 0.0


## This frame's share of the slide, as a velocity, with the Stagger's clock run on by `delta`:
## over the whole Stagger it covers exactly the knockback, at any frame rate and however few
## frames it lasts. Zero, and the clock held, in a frame the world is frozen in (delta 0).
func next_velocity(delta: float) -> Vector3:
	if delta == 0.0 or not is_active(): # frozen by a hitstop, or not staggered
		return Vector3.ZERO
	var left_after := maxf(_left - delta, 0.0)
	var distance := _knockback.length()
	var step := knockback_left(distance, _length, _left) - knockback_left(distance, _length, left_after)
	_left = left_after
	return _knockback.normalized() * step / delta


## How much of a `distance`-long knockback slide is still to go with `left` seconds of a
## `stagger`-long Stagger remaining. The slide's speed falls linearly to zero, so the distance
## still to go shrinks with the square of the time left.
static func knockback_left(distance: float, stagger: float, left: float) -> float:
	return distance * (left / stagger) ** 2
