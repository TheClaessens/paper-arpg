class_name SkillSlotButton
extends Control
## One Skill slot's button on the Skill bar HUD (see GLOSSARY.md). It shows the slot's Skill, or
## a faded empty button. In play its TouchScreenButton presses the slot's input action, the
## same one the mouse and the controller press, so the Player can't tell them apart; a
## TouchScreenButton also takes a second finger while the thumb holds the Touch stick. While the
## Skill bar is being changed it shows a focusable Button instead, which emits `chosen`.

signal chosen

## How faded an empty slot is.
const EMPTY_OPACITY := 0.5

@onready var _face: Control = $Face
@onready var _icon: TextureRect = $Face/Icon
@onready var _ring: TextureRect = $Ring
@onready var _touch: TouchScreenButton = $Touch
@onready var _choose: Button = $Choose


func _ready() -> void:
	_choose.pressed.connect(chosen.emit)
	set_editing(false)
	set_ringed(false)


## Puts the button for `slot` with its centre at `centre`, `diameter` across.
func place(slot: int, centre: Vector2, diameter: float) -> void:
	size = Vector2.ONE * diameter
	position = centre - size / 2.0
	_touch.action = Player.slot_action(slot)
	_touch.position = size / 2.0
	(_touch.shape as CircleShape2D).radius = diameter / 2.0


## Shows `skill`, or an empty slot when it is null.
func show_skill(skill: Skill) -> void:
	_icon.texture = skill.icon if skill else null
	_face.modulate.a = 1.0 if skill else EMPTY_OPACITY


## In play the slot is used by touch; while editing it is chosen with a tap, click or controller.
func set_editing(on: bool) -> void:
	_touch.visible = not on # a hidden TouchScreenButton takes no touches
	_choose.visible = on


## Rings the slot, marking it as the one being changed.
func set_ringed(on: bool) -> void:
	_ring.visible = on


func focus() -> void:
	_choose.grab_focus()
