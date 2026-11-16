class_name Skill
extends Node3D
## A Skill (see GLOSSARY.md): something the player uses from a Skill slot. Each Skill is a
## node on the Character, so it can reach the world from where the Character stands.
## Subclasses do the work in use().

## How long one use takes. The slot accepts no new use until it has passed.
@export var use_time := 0.4


## Uses the Skill along `facing`, a unit direction on the ground.
func use(_facing: Vector3) -> void:
	pass
