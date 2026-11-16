class_name SkillSlotButton
extends Control
## The Skill slot's button on a touch screen (see GLOSSARY.md). Its TouchScreenButton presses
## the `use_skill_slot` action, the same one the mouse and the controller press, so the Player
## can't tell them apart. It shows the icon of the Skill in the slot. Without a touch screen
## there is nothing to tap, so it hides.

@export var skill_slot: SkillSlot

@onready var _icon: Sprite2D = $Icon


func _ready() -> void:
	visible = DisplayServer.is_touchscreen_available()
	skill_slot.skill_changed.connect(_show_skill)
	_show_skill(skill_slot.skill)


func _show_skill(skill: Skill) -> void:
	_icon.texture = skill.icon
