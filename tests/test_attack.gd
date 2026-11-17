extends GutTest
## The Attack's Sweep along Facing: an Enemy counts when its centre lies inside it. Whether the
## Enemy is within Range is asked of the physics engine first (see test_skill.gd).


func _at(degrees: float, distance: float) -> Vector3:
	return Vector3.FORWARD.rotated(Vector3.UP, deg_to_rad(degrees)) * distance


func test_straight_ahead_within_range() -> void:
	assert_true(Attack.in_sweep(_at(0.0, 1.5), Vector3.FORWARD, 120.0))


func test_inside_and_outside_the_sweep() -> void:
	assert_true(Attack.in_sweep(_at(55.0, 1.0), Vector3.FORWARD, 120.0))
	assert_false(Attack.in_sweep(_at(65.0, 1.0), Vector3.FORWARD, 120.0))


func test_height_is_ignored() -> void:
	assert_true(Attack.in_sweep(_at(0.0, 1.0) + Vector3.UP * 0.5, Vector3.FORWARD, 120.0))


func test_an_enemy_pressed_against_the_player_is_hit_from_any_side() -> void:
	assert_true(Attack.in_sweep(_at(180.0, 0.4), Vector3.FORWARD, 120.0))
