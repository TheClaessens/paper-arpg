extends GutTest
## The Attack's hit shape: an arc along Facing. An Enemy counts when any part of its body,
## `body_radius` around its centre, is within reach, and its centre lies inside the arc.

const BODY := 0.25


func _at(degrees: float, distance: float) -> Vector3:
	return Vector3.FORWARD.rotated(Vector3.UP, deg_to_rad(degrees)) * distance


func test_straight_ahead_within_reach() -> void:
	assert_true(Attack.in_arc(_at(0.0, 1.5), Vector3.FORWARD, 120.0, 1.6, BODY))


func test_its_body_reaches_into_range() -> void:
	assert_true(Attack.in_arc(_at(0.0, 1.8), Vector3.FORWARD, 120.0, 1.6, BODY), "edge at 1.55")
	assert_false(Attack.in_arc(_at(0.0, 1.9), Vector3.FORWARD, 120.0, 1.6, BODY), "edge at 1.65")


func test_inside_and_outside_the_arc() -> void:
	assert_true(Attack.in_arc(_at(55.0, 1.0), Vector3.FORWARD, 120.0, 1.6, BODY))
	assert_false(Attack.in_arc(_at(65.0, 1.0), Vector3.FORWARD, 120.0, 1.6, BODY))


func test_height_is_ignored() -> void:
	assert_true(Attack.in_arc(_at(0.0, 1.0) + Vector3.UP * 0.5, Vector3.FORWARD, 120.0, 1.6, BODY))


func test_an_enemy_pressed_against_the_player_is_hit_from_any_side() -> void:
	assert_true(Attack.in_arc(_at(180.0, 0.4), Vector3.FORWARD, 120.0, 1.6, BODY))
