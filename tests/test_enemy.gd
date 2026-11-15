extends GutTest
## The reach rule: an Enemy stops within `reach` of its target and chases again only past
## `resume`, so a small step by the player doesn't flick it between walking and standing.

var enemy: Enemy


func before_each() -> void:
	enemy = autofree(Enemy.new())
	enemy.reach = 1.0
	enemy.resume = 1.3


func test_keeps_chasing_outside_reach() -> void:
	assert_true(enemy.should_chase(true, 1.1))


func test_stops_within_reach() -> void:
	assert_false(enemy.should_chase(true, 0.9))


func test_stays_stopped_until_past_resume() -> void:
	assert_false(enemy.should_chase(false, 1.2))


func test_chases_again_past_resume() -> void:
	assert_true(enemy.should_chase(false, 1.4))
