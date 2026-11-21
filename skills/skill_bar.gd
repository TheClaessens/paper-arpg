class_name SkillBar
extends Node
## The Skill bar (see GLOSSARY.md): the player's five Skill slots. Slot 0 is the main slot, 1 to 4
## the small ones in fan order. A slot holds a Skill or nothing, and the same Skill may sit in
## several. Only a Skill's own Cooldown limits how often it is used: using one slot never blocks
## another. A press on a ready Skill joins a queue, worked through in press order on the next
## physics frame; a press on a Skill still on Cooldown is ignored, not kept.
## A press may carry its own aim (a drag on touch); otherwise the Character aims the Skill.
## While a slot is held, a Skill that repeats while held is used again the moment its Cooldown
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

var _slots: Array[Skill] = []
var _pressed: Array[int] = [] # slots pressed since the last advance(), in press order
var _pressed_aims: Array[Vector3] = [] # each press's aim, matching _pressed
var _held: Dictionary[int, Vector3] = {} # held slots, each with its steered aim (or NO_AIM)
var _cooling: Array[Skill] = [] # Skills used and not yet ready again, on the bar or off it


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
		_pressed.append(slot)
		_pressed_aims.append(aim)


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


## Moves the Cooldowns on by `delta` seconds, then uses the pressed slots in press order, then
## the held ones whose Skill repeats. Presses are handled here, in the physics step, so a Skill
## can query the physics world.
func advance(delta: float) -> void:
	_cool_down(delta)
	for i in _pressed.size():
		_use(_pressed[i], _pressed_aims[i])
	_pressed.clear()
	_pressed_aims.clear()
	for slot: int in _held:
		var skill := _slots[slot]
		if skill and skill.repeats_while_held:
			_use(slot, _held[slot])


## Uses the Skill in `slot`, aimed at `aim`, unless the slot was emptied or the Skill went on
## Cooldown since the press (used from another slot, or pressed twice).
func _use(slot: int, aim: Vector3) -> void:
	var skill := _slots[slot]
	if not skill or not skill.is_ready():
		return
	skill.start_cooldown()
	if not skill.is_ready() and skill not in _cooling:
		_cooling.append(skill)
	used.emit(skill, aim)
	slot_used.emit(slot)


## Runs the cooldown of each Skill the bar has used, whether or not it still sits in a slot.
func _cool_down(delta: float) -> void:
	for skill: Skill in _cooling.duplicate(): # a copy, since ready ones leave the list
		if skill.cool_down(delta):
			_cooling.erase(skill)
			ready_again.emit(skill)

