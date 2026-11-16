class_name SkillSlotButton
extends Control
## The Skill slot's button on a touch screen (see GLOSSARY.md). Its TouchScreenButton presses
## the `use_skill_slot` action, the same one the mouse and the controller press, so the Player
## can't tell them apart. It shows the icon of the Skill in the slot. Without a touch screen
## there is nothing to tap, so it hides.

## Whose Skill slot this button uses.
@export var player: Player

@onready var _icon: Sprite2D = $Icon


func _ready() -> void:
	visible = DisplayServer.is_touchscreen_available()
	player.skill_slot.skill_changed.connect(_show_skill)
	_show_skill(player.skill_slot.skill)


func _show_skill(skill: Skill) -> void:
	_icon.texture = skill.icon
