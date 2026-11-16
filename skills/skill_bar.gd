class_name SkillBar
extends Node
## The Skill bar (see GLOSSARY.md): the player's five Skill slots. Slot 0 is the main slot, 1 to 4
## the small ones in fan order. A slot holds a Skill or nothing, and the same Skill may sit in
## several. The slots share one clock: a use makes the player busy for that Skill's Use time, and
## no slot is used until it has passed. A press in its final `buffer` seconds, from any slot, is
## kept and used the moment it ends (the latest such press wins); an earlier one is dropped.
## A Skill on cooldown can't be used from any slot; a press on it is ignored, not kept.
## The Character connects `used` and aims the Skill.

signal used(skill: Skill)
## `slot` was used (the HUD presses its button in).
signal slot_used(slot: int)
## `skill`'s cooldown has run out.
signal ready_again(skill: Skill)
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


## Asks to use `slot`. Takes effect on the next physics frame. An empty slot, or one whose Skill
## is cooling down, does nothing.
func press(slot: int) -> void:
	var skill := _slots[slot]
	if skill and skill.cooldown_left <= 0.0:
		_pressed = slot


func _physics_process(delta: float) -> void:
	advance(delta)


## Moves the clock on by `delta` seconds and uses a Skill if a press is due. Presses are
## handled here, in the physics step, so a Skill can query the physics world.
func advance(delta: float) -> void:
	_cool_down(delta)
	_busy = maxf(0.0, _busy - delta)
	if _pressed != NONE and _busy <= buffer:
		_buffered = _pressed
	_pressed = NONE
	if _buffered != NONE and _busy == 0.0:
		var skill := _slots[_buffered]
		var slot := _buffered
		_buffered = NONE
		if skill and skill.cooldown_left <= 0.0: # emptied, or used from another slot, since the press
			_busy = skill.use_time
			skill.cooldown_left = skill.cooldown
			used.emit(skill)
			slot_used.emit(slot)


## Runs the cooldown of each Skill on the bar once, however many slots it sits in.
func _cool_down(delta: float) -> void:
	var seen: Array[Skill] = []
	for skill in _slots:
		if skill == null or skill in seen or skill.cooldown_left <= 0.0:
			continue
		seen.append(skill)
		skill.cooldown_left = maxf(0.0, skill.cooldown_left - delta)
		if skill.cooldown_left == 0.0:
			ready_again.emit(skill)
