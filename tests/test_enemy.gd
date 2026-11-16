extends GutTest
## The reach rule: an Enemy stops within `reach_distance` of its target and chases again only
## past `resume_distance`, so a small step by the player doesn't flick it between walking and
## standing.

var enemy: Enemy


func before_each() -> void:
	enemy = autofree(Enemy.new())
	enemy.reach_distance = 1.0
	enemy.resume_distance = 1.3


func test_keeps_chasing_outside_reach() -> void:
	assert_true(enemy.should_chase(true, 1.1))


func test_stops_within_reach() -> void:
	assert_false(enemy.should_chase(true, 0.9))


func test_stays_stopped_until_past_resume() -> void:
	assert_false(enemy.should_chase(false, 1.2))


func test_chases_again_past_resume() -> void:
	assert_true(enemy.should_chase(false, 1.4))


# Knockback: the slide's speed falls linearly to zero over the Stagger, so the distance still
# to go shrinks with the square of the time left.

func test_knockback_left_over_the_stagger() -> void:
	assert_almost_eq(Enemy.knockback_left(0.8, 0.2, 0.2), 0.8, 0.001, "all of it at the start")
	assert_almost_eq(Enemy.knockback_left(0.8, 0.2, 0.1), 0.2, 0.001, "a quarter halfway")
	assert_almost_eq(Enemy.knockback_left(0.8, 0.2, 0.0), 0.0, 0.001, "none at the end")
