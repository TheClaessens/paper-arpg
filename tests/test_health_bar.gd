extends GutTest
## The Health bar shows only while Health is below its maximum, filled by current over maximum,
## and hides when its Enemy dies.

var attack: Attack
var zombie: Enemy


func before_each() -> void:
	attack = preload("res://skills/attack/attack.tscn").instantiate()
	add_child_autofree(attack)
	zombie = preload("res://characters/enemy/zombie.tscn").instantiate()
	add_child_autoqfree(zombie)
	zombie.global_position = Vector3(1.0, 0.0, 0.0)
	await wait_physics_frames(2) # the physics world learns where it stands


func after_each() -> void:
	Engine.time_scale = 1.0 # the hitstops the hits started


## Swings the Attack (10 Damage) at the zombie `times` times, its Cooldown skipped.
func _swing(times: int) -> void:
	for i in times:
		attack.cooldown_left = 0.0
		attack.try_activate(Vector3.RIGHT, [])


func test_no_bar_at_full_health() -> void:
	assert_false(zombie.health_bar.visible, "the zombie's")
	var player: Player = add_child_autofree(preload("res://characters/player/player.tscn").instantiate())
	assert_false(player.health_bar.visible, "the player's")


func test_a_hit_shows_the_bar_dropped_by_its_share() -> void:
	_swing(1)
	assert_true(zombie.health_bar.visible)
	assert_almost_eq(zombie.health_bar.fraction, 0.8, 0.001, "40 of 50")


func test_a_dying_zombie_hides_its_bar() -> void:
	_swing(5)
	assert_false(zombie.health_bar.visible)


func test_the_players_bar_shows_while_hurt_and_hides_when_healed_to_full() -> void:
	var player: Player = add_child_autofree(preload("res://characters/player/player.tscn").instantiate())
	player.health.damage(10.0)
	assert_true(player.health_bar.visible, "hurt")
	assert_almost_eq(player.health_bar.fraction, 0.9, 0.001, "90 of 100")
	player.health.heal(10.0)
	assert_false(player.health_bar.visible, "back to full")
