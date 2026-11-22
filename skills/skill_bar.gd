class_name SkillBar
extends Node
## The Skill bar (see GLOSSARY.md): the player's five Skill slots, each bound to one of the
## Character's Skills or to nothing. Slot 0 is the main slot, 1 to 4 the small ones in fan order.
## The same Skill may sit in several slots. The bar only says which slot asks to activate its
## Skill, and when; the Character activates it, and the Skill runs its own Cooldown.
## A press on a ready Skill joins a queue, worked through in press order on the next physics
## frame; a press on a Skill still on Cooldown is ignored, not kept. A press may carry its own
## aim (a drag on touch); otherwise the Character aims the Skill. While a slot is held, a Skill
## whose Aim mode repeats while held is asked for again whenever it is ready, aimed where the hold
## steers it. Pausing, or the app losing focus, lets go of every slot. The Character connects
## `activation_requested`.

## `slot` asks to activate its Skill, which is ready. `aim` is the press's own aim, or NO_AIM to
## let the Character aim it.
signal activation_requested(slot: int, aim: Vector3)
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


func _init() -> void:
	_slots.resize(SLOTS)


func _ready() -> void:
	if main_skill:
		set_skill(0, main_skill)


## The Skill in `slot`, or null when it is empty.
func skill_in(slot: int) -> Skill:
	return _slots[slot]


## Puts `skill` in `slot`, or empties it with null. A Skill without an Aim mode fails an assertion.
func set_skill(slot: int, skill: Skill) -> void:
	if skill:
		assert(skill.aim_mode != null, "%s has no Aim mode: a Skill in a Skill slot needs one." % skill.name)
	_slots[slot] = skill
	changed.emit(slot, skill)


## Presses `slot`: asks to activate its Skill, aimed at `aim` (an offset on the ground) or, by
## default, by the Character. Takes effect on the next physics frame. An empty slot, or one whose Skill is
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
	# A binding held through a pause or a focus loss may be let go of unheard: Controls is
	# paused, or the engine releases keys without an event when the app loses focus.
	if what == NOTIFICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_held.clear()


func _physics_process(_delta: float) -> void:
	advance()


## Asks for the pressed slots in press order, then the held ones whose Skill repeats. Presses are
## handled here, in the physics step, so the Skill can query the physics world. The Character
## answers each request at once, so a Skill activated by an earlier one is no longer ready for a
## later one in the same frame.
func advance() -> void:
	for i in _pressed.size():
		_request(_pressed[i], _pressed_aims[i])
	_pressed.clear()
	_pressed_aims.clear()
	for slot: int in _held:
		var skill := _slots[slot]
		if skill and skill.aim_mode.repeats_while_held:
			_request(slot, _held[slot])


## Asks to activate the Skill in `slot`, aimed at `aim`, unless the slot was emptied or the
## Skill went on Cooldown since the press (activated from another slot, or pressed twice).
func _request(slot: int, aim: Vector3) -> void:
	var skill := _slots[slot]
	if skill and skill.is_ready():
		activation_requested.emit(slot, aim)
