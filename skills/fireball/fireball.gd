@tool
class_name Fireball
extends Skill
## Fireball: throws a ball of fire straight where it is aimed. It flies at its Projectile speed
## until it has flown the Skill's Range, or touches a wall or a hostile Hurtbox (with Pierce, a
## second one). Each Hurtbox it touches takes the throw's one Hit, with the same Hit feedback as any
## other Skill except the hitstop: a projectile's Hit doesn't freeze the world.

const ProjectileScene := preload("res://skills/fireball/projectile.tscn")
## Whether the throw's Hit freezes the world: a projectile's doesn't.
const FREEZES := false

## How far in front of the Character the ball starts, and how high it flies.
const LAUNCH_OFFSET := 0.45
const FLIGHT_HEIGHT := 0.5

## The name of how fast the ball flies among the Skill's numbers (see GLOSSARY.md, Projectile speed).
const PROJECTILE_SPEED := &"Projectile speed"

## How fast the ball flies, in world units per second.
@export var projectile_speed := 12.0


func numbers() -> Dictionary[StringName, float]:
	var all := super()
	all[PROJECTILE_SPEED] = projectile_speed
	return all


func _activate(snapshot: Snapshot, aim: Vector3) -> void:
	var facing := aim.normalized()
	var ball: Projectile = ProjectileScene.instantiate()
	ball.direction = facing
	ball.snapshot = snapshot # the ball flies as this throw was made, whatever changes after
	ball.top_level = true # flies on its own instead of following the Character
	ball.collision_mask |= hostile_mask()
	var ball_hit := _hit(snapshot, FREEZES) # one Hit for the throw: a Pierce ball lands it twice
	ball.hit.connect(func(hurtbox: Hurtbox) -> void: ball_hit.land({hurtbox: facing})) # pushed along the throw
	add_child(ball)
	ball.global_position = global_position + facing * LAUNCH_OFFSET + Vector3.UP * FLIGHT_HEIGHT
