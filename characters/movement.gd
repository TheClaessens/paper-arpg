class_name Movement
extends Node
## Turns where a Character wants to go into how fast it moves (see GLOSSARY.md).
## The Character asks for its next velocity each physics frame and moves itself with it.
## The player feeds it input; enemies will feed it their AI.

## Top speed, in world units per second.
@export var speed := 4.0
## How fast speed builds up, in units per second². 60 reaches 4.0 in about 0.07 s.
@export var acceleration := 60.0
## How fast speed drops when the Character stops, in units per second².
@export var deceleration := 80.0


## Steps `velocity` toward `direction * speed`. A zero direction brings the Character to rest.
## Takes the current velocity rather than remembering its own, so speed lost against
## a wall (after move_and_slide) stays lost.
func next_velocity(velocity: Vector3, direction: Vector3, delta: float) -> Vector3:
	var target := direction * speed
	var rate := deceleration if target.is_zero_approx() else acceleration
	return velocity.move_toward(target, rate * delta)
