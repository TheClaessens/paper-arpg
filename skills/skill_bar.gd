class_name SkillBar
extends Node
## The Skill bar (see GLOSSARY.md): the player's five Skill slots. Slot 0 is the main slot, 1 to 4
## the small ones in fan order. A slot holds a Skill or nothing, and the same Skill may sit in
## several. The slots share one clock: a use makes the player busy for that Skill's Use time, and
## no slot is used until it has passed. A press in its final `buffer` seconds, from any slot, is
## kept and used the moment it ends (the latest such press wins); an earlier one is dropped.
## A Skill on cooldown can't be used from any slot; a press on it is ignored, not kept.
## A press may carry its own aim (a drag on touch); otherwise the Character aims the Skill.
## While a slot is held, a Skill that repeats while held is used again each time the Use time
## ends, aimed where the hold steers it. Pausing lets go of every slot.
## The Character connects `used`.

## `skill` is used. `aim` is the press's own aim, or NO_AIM to let the Character aim it.
signal used(skill: Skill, aim: Vector3)
## `slot` was used (the HUD presses its button in).
signal slot_used(slot: int)
## `skill`'s cooldown has run out.
signal ready_again(skill: Skill)
## The Skill in `slot` changed; `skill` is null when the slot was emptied.
signal changed(slot: int, skill: Skill)

const SLOTS := 5
const NONE := -1
## A press without its own aim.
const NO_AIM := Vector3.INF

## The Skill in the main slot at the start. The small slots start empty.
@export var main_skill: Skill
## How early before the Use time ends a press is still kept, in seconds.
@export var buffer := 0.15

var _slots: Array[Skill] = []
var _pressed := NONE # a slot pressed since the last advance()
var _pressed_aim := NO_AIM
var _buffered := NONE # a slot kept for when the Use time ends
var _buffered_aim := NO_AIM
var _busy := 0.0 # Use time left
var _held: Dictionary[int, Vector3] = {} # held slots, each with its steered aim (or NO_AIM)


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


## Asks to use `slot`, aimed at `aim` (an offset on the ground) or, by default, by the
## Character. Takes effect on the next physics frame. An empty slot, or one whose Skill is
## cooling down, does nothing.
func press(slot: int, aim := NO_AIM) -> void:
	var skill := _slots[slot]
	if skill and skill.is_ready():
		_pressed = slot
		_pressed_aim = aim


## Holds `slot` down (or lets go), steering its repeats toward `aim` (an offset on the ground),
## or letting the Character aim them with NO_AIM.
func set_held(slot: int, held: bool, aim := NO_AIM) -> void:
	if held:
		_held[slot] = aim
	else:
		_held.erase(slot)


func _notification(what: int) -> void:
	# A press held through a pause may lift unheard, so a pause lets go.
	if what == NOTIFICATION_PAUSED:
		_held.clear()


func _physics_process(delta: float) -> void:
	advance(delta)


## Moves the clock on by `delta` seconds and uses a Skill if a press is due. Presses are
## handled here, in the physics step, so a Skill can query the physics world.
func advance(delta: float) -> void:
	_cool_down(delta)
	_busy = maxf(0.0, _busy - delta)
	if _pressed != NONE and _busy <= buffer:
		_buffered = _pressed
		_buffered_aim = _pressed_aim
	_pressed = NONE
	if _buffered == NONE and _busy == 0.0:
		_repeat_held()
	if _buffered != NONE and _busy == 0.0:
		var skill := _slots[_buffered]
		var slot := _buffered
		_buffered = NONE
		if skill and skill.is_ready(): # emptied, or used from another slot, since the press
			_busy = skill.use_time
			skill.start_cooldown()
			used.emit(skill, _buffered_aim)
			slot_used.emit(slot)


## Runs the cooldown of each Skill on the bar once, however many slots it sits in.
func _cool_down(delta: float) -> void:
	var seen: Array[Skill] = []
	for skill in _slots:
		if skill == null or skill in seen:
			continue
		seen.append(skill)
		if skill.cool_down(delta):
			ready_again.emit(skill)


## Queues a held slot whose Skill repeats while held, aimed where its hold steers it.
func _repeat_held() -> void:
	for slot: int in _held:
		var skill := _slots[slot]
		if skill and skill.repeats_while_held and skill.is_ready():
			_buffered = slot
			_buffered_aim = _held[slot]
			return
