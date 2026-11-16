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


# Knockback: the slide's speed falls linearly to zero over the Stagger and covers the knockback distance.

func test_knockback_starts_fast_and_runs_down() -> void:
	assert_almost_eq(Enemy.knockback_speed(0.8, 0.2, 0.2), 8.0, 0.001, "start")
	assert_almost_eq(Enemy.knockback_speed(0.8, 0.2, 0.1), 4.0, 0.001, "halfway")
	assert_almost_eq(Enemy.knockback_speed(0.8, 0.2, 0.0), 0.0, 0.001, "end")


func test_knockback_covers_its_distance_over_the_stagger() -> void:
	var travelled := 0.0
	var step := 0.2 / 1000.0
	for i in 1000:
		travelled += Enemy.knockback_speed(0.8, 0.2, 0.2 - (i + 0.5) * step) * step
	assert_almost_eq(travelled, 0.8, 0.001)
