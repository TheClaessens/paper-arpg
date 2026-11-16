class_name Fireball
extends Skill
## Fireball: throws a ball of fire straight along Facing. It flies at `speed` until it has flown
## the Skill's Range, or touches a wall or an Enemy. An Enemy it touches is knocked back, with
## the same Hit feedback as any other Skill.

const ProjectileScene := preload("res://skills/fireball/projectile.tscn")

## How far in front of the Character the ball starts, and how high it flies.
const LAUNCH_OFFSET := 0.45
const FLIGHT_HEIGHT := 0.5

## How fast the ball flies, in world units per second.
@export var speed := 12.0
## How the game shows the hit (game-wide, shared by every Skill).
@export var hit_feedback: HitFeedback


func use(facing: Vector3) -> void:
	var ball: Projectile = ProjectileScene.instantiate()
	ball.direction = facing
	ball.speed = speed
	ball.range = range
	ball.top_level = true # flies on its own instead of following the Character
	ball.hit_enemy.connect(func(enemy: Enemy) -> void: _hit(enemy, facing))
	add_child(ball)
	ball.global_position = global_position + facing * LAUNCH_OFFSET + Vector3.UP * FLIGHT_HEIGHT


func _hit(enemy: Enemy, direction: Vector3) -> void:
	enemy.take_hit(direction, knockback, stagger)
	hit_feedback.play_impact(get_viewport())
