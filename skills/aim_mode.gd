class_name AimMode
extends Resource
## An Aim mode (see GLOSSARY.md): how a Skill is aimed. A saved file in skills/aim_modes/ that a
## Skill names; Skills aimed the same way name the same one. It says what the Skill's Aim holds,
## whether on touch the Skill waits for the thumb to lift, and whether holding its slot repeats it.
## Auto-aim is not one: it is the Aim any Skill gets when the player gives none (see Player).

## What an Aim holds. NOTHING: the Skill is activated around the Character. DIRECTION: where it
## goes. SPOT: where it goes and how far.
enum Holds { NOTHING, DIRECTION, SPOT }

## What an Aim of this mode holds.
@export var holds := Holds.DIRECTION
## Whether on touch the Skill waits for the thumb to lift: a drag off its slot aims it by hand and
## the lift activates it. Otherwise it is activated as the thumb lands. Keys, mouse and controller
## activate on the press either way.
@export var waits_for_lift := false
## Whether holding the Skill's slot activates it again each time its Cooldown ends.
@export var repeats_while_held := false


## The Aim for a thumb `drag` on screen, as an offset on the ground from the Character. `right` and
## `back` are screen right and screen down on the ground. An Aim that holds a spot goes as far as
## the drag, reaching `skill_range` at `full_drag`; any other goes the whole `skill_range`.
func aim_from_drag(drag: Vector2, right: Vector3, back: Vector3, skill_range: float, full_drag: float) -> Vector3:
	var direction := (right * drag.x + back * drag.y).normalized()
	var reach := minf(drag.length() / full_drag, 1.0) if holds == Holds.SPOT else 1.0
	return direction * skill_range * reach
