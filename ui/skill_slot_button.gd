class_name SkillSlotButton
extends Control
## One Skill slot's button on the Skill bar HUD (see GLOSSARY.md). It shows the slot's Skill, or
## a faded empty button. In play it follows the finger that lands on it, like the Touch stick
## does, and reports where it goes and where it lifts, or that the finger was lost without lifting;
## it takes a second finger while the thumb holds the stick. While the Skill bar is being changed it
## shows a focusable Button instead, which emits `chosen`.
## It also shows the Skill's cooldown, presses in when activated and flashes when ready again.

signal chosen
## A finger landed on the button at `at`, moved to `at`, or lifted at `at` (viewport coordinates).
signal touch_started(at: Vector2)
signal touch_moved(at: Vector2)
signal touch_ended(at: Vector2)
## The finger was taken away without lifting: the system cancelled its touch, or the app lost focus.
signal touch_lost

const NO_FINGER := -1

## How faded an empty slot is.
const EMPTY_OPACITY := 0.5
## How far a button presses in on an activation, and how long it takes to spring back.
const PRESS_SCALE := 0.86
const PRESS_TIME := 0.15
## How bright the ready flash starts, and how long it fades.
const FLASH := Color(2.2, 2.2, 2.2)
const FLASH_TIME := 0.3

var _skill: Skill
var _finger := NO_FINGER # touch index that landed on the button

@onready var _face: Control = $Face
@onready var _icon: TextureRect = $Face/Icon
@onready var _ring: TextureRect = $Ring
@onready var _choose: Button = $Choose
@onready var _sweep: CooldownSweep = $Face/Sweep


func _ready() -> void:
	_choose.pressed.connect(chosen.emit)
	set_editing(false)
	set_ringed(false)


## Puts the button with its centre at `at`, `diameter` across.
func place(at: Vector2, diameter: float) -> void:
	size = Vector2.ONE * diameter
	position = at - size / 2.0
	_face.pivot_offset = size / 2.0


## The button's centre, in viewport coordinates.
func centre() -> Vector2:
	return global_position + size / 2.0


## Whether `at` lies on the round button.
func covers(at: Vector2) -> bool:
	return at.distance_to(centre()) <= size.x / 2.0


## Shows `skill`, or an empty slot when it is null, and flashes whenever that Skill is ready again.
func show_skill(skill: Skill) -> void:
	if _skill:
		_skill.ready_again.disconnect(_flash)
	_skill = skill
	if skill:
		skill.ready_again.connect(_flash)
	_icon.texture = skill.icon if skill else null
	_face.modulate.a = 1.0 if skill else EMPTY_OPACITY


## In play the slot is pressed by touch; while editing it is chosen with a tap, click or controller.
func set_editing(on: bool) -> void:
	_choose.visible = on


## Rings the slot, marking it as the one being changed.
func set_ringed(on: bool) -> void:
	_ring.visible = on


func focus() -> void:
	_choose.grab_focus()


## Presses the button in and lets it spring back, for an activation.
func press_in() -> void:
	_face.scale = Vector2.ONE * PRESS_SCALE
	create_tween().set_ignore_time_scale().tween_property(_face, ^"scale", Vector2.ONE, PRESS_TIME)


# A short flash for a Skill that is ready again.
func _flash() -> void:
	_face.modulate = Color(FLASH, _face.modulate.a)
	create_tween().set_ignore_time_scale().tween_property(_face, ^"modulate", Color(Color.WHITE, _face.modulate.a), FLASH_TIME)


# _input, so the button claims its finger before the Touch stick or the world sees it.
# A new finger only counts in play; one already held is followed to the end.
func _input(event: InputEvent) -> void:
	var touch := event as InputEventScreenTouch
	if touch:
		if touch.pressed and _finger == NO_FINGER and not _choose.visible and not get_tree().paused and covers(touch.position):
			_finger = touch.index
			get_viewport().set_input_as_handled()
			touch_started.emit(touch.position)
		elif not touch.pressed and touch.index == _finger:
			get_viewport().set_input_as_handled()
			if _is_lift(touch):
				_finger = NO_FINGER
				touch_ended.emit(touch.position)
			else:
				_lose_finger()
		return
	var drag := event as InputEventScreenDrag
	if drag and drag.index == _finger:
		get_viewport().set_input_as_handled()
		touch_moved.emit(drag.position)


func _notification(what: int) -> void:
	# The app losing focus can take the finger with no lift this button hears. A pause can't: the
	# button runs while paused (it inherits the HUD's process_mode ALWAYS, so it never gets
	# NOTIFICATION_PAUSED) and follows its finger to the end.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_lose_finger()


func _lose_finger() -> void:
	if _finger == NO_FINGER:
		return
	_finger = NO_FINGER
	touch_lost.emit()


## Whether `touch`, a release, is a lift and not the system taking the touch away. Android marks a
## taken touch `canceled`; Godot 4.7 on iOS doesn't, and puts it at (-1, -1).
# ponytail: a lift left of or above the window (the Mac's mouse emulating touch) counts as lost;
# drop the position check once Godot on iOS sets `canceled`.
static func _is_lift(touch: InputEventScreenTouch) -> bool:
	return not touch.canceled and touch.position.x >= 0.0 and touch.position.y >= 0.0


func _process(_delta: float) -> void:
	_sweep.left = _skill.cooldown_fraction() if _skill else 0.0
