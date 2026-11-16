class_name SkillTile
extends Button
## One tile in the Skill drawer (see GLOSSARY.md): a Skill's icon on a hexagon, or a bare
## hexagon for emptying the slot. The Skill in the slot being changed is tinted amber.

const CURRENT_TINT := Color(1.3, 1.12, 0.8)

@onready var _background: TextureRect = $Background
@onready var _icon: TextureRect = $Icon


## Shows `icon` (none for the Empty tile), tinted when `current`.
func show_skill(icon: Texture2D, current: bool) -> void:
	_icon.texture = icon
	_background.modulate = CURRENT_TINT if current else Color.WHITE
