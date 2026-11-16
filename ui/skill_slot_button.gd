class_name SkillSlotButton
extends Control
## The Skill slot's button on a touch screen (see GLOSSARY.md). Its TouchScreenButton presses
## the `use_skill_slot` action, the same one the mouse and the controller press, so the Player
## can't tell them apart. Without a touch screen there is nothing to tap, so it hides.


func _ready() -> void:
	visible = DisplayServer.is_touchscreen_available()
