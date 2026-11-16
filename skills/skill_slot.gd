class_name SkillSlot
extends Node
## A Skill slot (see GLOSSARY.md): holds one Skill and says when it is used. A press uses it
## at once, unless the last use is still going: then a press in the final `buffer` seconds is
## kept and used the moment the time ends, and an earlier one is dropped.
## The Character connects `used` and calls the Skill with its own Facing.

signal used(skill: Skill)

@export var skill: Skill
## How early before the use time ends a press is still kept, in seconds.
@export var buffer := 0.15

var _pressed := false # a press waiting for the next advance()
var _buffered := false # a press kept for when the use time ends
var _busy := 0.0 # use time left


## Asks to use the Skill. Takes effect on the next physics frame.
func press() -> void:
	_pressed = true


func _physics_process(delta: float) -> void:
	advance(delta)


## Moves the slot's clock on by `delta` seconds and uses the Skill if a press is due.
## Presses are handled here, in the physics step, so a Skill can query the physics world.
func advance(delta: float) -> void:
	_busy = maxf(0.0, _busy - delta)
	if _pressed and _busy <= buffer:
		_buffered = true
	_pressed = false
	if _buffered and _busy == 0.0:
		_buffered = false
		_busy = skill.use_time
		used.emit(skill)
