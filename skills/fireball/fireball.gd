@tool
class_name Fireball
extends Skill
## Fireball: throws a ball of fire (see Projectile) straight where it is aimed, carrying the
## activation's Hit. The ball lands the Hit itself on each hostile Hurtbox it touches, with the
## same Hit feedback as any other Skill except the hitstop: a projectile's Hit doesn't freeze the
## world. It lives in the world beside the Character, so it flies on after the Skill and the
## Character are gone.

const ProjectileScene := preload("res://skills/fireball/projectile.tscn")
## Whether the throw's Hit freezes the world: a projectile's doesn't.
const FREEZES := false

## The name of how fast the ball flies among the Skill's numbers (see GLOSSARY.md, Projectile speed).
const PROJECTILE_SPEED := &"Projectile speed"

## How fast the ball flies, in world units per second.
@export var projectile_speed := 12.0


func numbers() -> Dictionary[StringName, float]:
	var all := super()
	all[PROJECTILE_SPEED] = projectile_speed
	return all


func _activate(snapshot: Snapshot, aim: Vector3) -> void:
	var ball: Projectile = ProjectileScene.instantiate()
	_add_to_world(ball)
	ball.launch(_hit(snapshot, FREEZES), global_position, aim.normalized(), hostile_mask())
