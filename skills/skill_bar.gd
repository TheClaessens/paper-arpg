class_name SkillBar
extends Node
## The Skill bar (see GLOSSARY.md): the player's five Skill slots. Slot 0 is the main slot, 1 to 4
## the small ones in fan order. A slot holds a Skill or nothing, and the same Skill may sit in
## several. The slots share one clock: a use makes the player busy for that Skill's Use time, and
## no slot is used until it has passed. A press in its final `buffer` seconds, from any slot, is
## kept and used the moment it ends (the latest such press wins); an earlier one is dropped.
## The Character connects `used` and calls the Skill with its own Facing.

signal used(skill: Skill)
## The Skill in `slot` changed; `skill` is null when the slot was emptied.
signal changed(slot: int, skill: Skill)

const SLOTS := 5
const NONE := -1

## The Skill in the main slot at the start. The small slots start empty.
@export var main_skill: Skill
## How early before the Use time ends a press is still kept, in seconds.
@export var buffer := 0.15

var _slots: Array[Skill] = []
var _pressed := NONE # a slot pressed since the last advance()
var _buffered := NONE # a slot kept for when the Use time ends
var _busy := 0.0 # Use time left


func _init() -> void:
	_slots.resize(SLOTS)


func _ready() -> void:
	if main_skill:
		set_skill(0, main_skill)


## The Skill in `slot`, or null when it is empty.
func skill_in(slot: int) -> Skill:
	return _slots[slot]


## Puts `skill` in `slot`, or empties it with null.
func set_skill(slot: int, skill: Skill) -> void:
	_slots[slot] = skill
	changed.emit(slot, skill)


## Asks to use `slot`. Takes effect on the next physics frame; an empty slot does nothing.
func press(slot: int) -> void:
	if _slots[slot]:
		_pressed = slot


func _physics_process(delta: float) -> void:
	advance(delta)


## Moves the clock on by `delta` seconds and uses a Skill if a press is due. Presses are
## handled here, in the physics step, so a Skill can query the physics world.
func advance(delta: float) -> void:
	_busy = maxf(0.0, _busy - delta)
	if _pressed != NONE and _busy <= buffer:
		_buffered = _pressed
	_pressed = NONE
	if _buffered != NONE and _busy == 0.0:
		var skill := _slots[_buffered]
		_buffered = NONE
		if skill: # it may have been emptied since the press
			_busy = skill.use_time
			used.emit(skill)
