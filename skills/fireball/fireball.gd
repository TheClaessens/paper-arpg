class_name Fireball
extends Skill
## Fireball: throws a ball of fire straight where it is aimed. It flies at `speed` until it has flown
## the Skill's Range, or touches a wall or an Enemy. An Enemy it touches is knocked back, with
## the same Hit feedback as any other Skill.

const ProjectileScene := preload("res://skills/fireball/projectile.tscn")

## How far in front of the Character the ball starts, and how high it flies.
const LAUNCH_OFFSET := 0.45
const FLIGHT_HEIGHT := 0.5

## How fast the ball flies, in world units per second.
@export var speed := 12.0


func use(aim: Vector3) -> void:
	var facing := aim.normalized()
	var ball: Projectile = ProjectileScene.instantiate()
	ball.direction = facing
	ball.speed = speed
	ball.range = range
	ball.top_level = true # flies on its own instead of following the Character
	ball.hit_enemy.connect(func(enemy: Enemy) -> void: _land_hits({enemy: facing})) # pushed along the throw
	add_child(ball)
	ball.global_position = global_position + facing * LAUNCH_OFFSET + Vector3.UP * FLIGHT_HEIGHT
