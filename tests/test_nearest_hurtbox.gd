extends GutTest
## The Hurtbox nearest a spot on the ground, if one is close enough: what a Skill landing on a
## spot picks out, and which one the mouse cursor highlights.


func test_the_hurtbox_nearest_the_spot() -> void:
	var positions: Array[Vector3] = [Vector3(4.0, 0.0, 0.0), Vector3(2.0, 0.0, 1.0), Vector3(2.5, 0.0, -0.5)]
	assert_eq(Skill.nearest_to(Vector3(2.4, 0.0, -0.2), positions, 1.5), 2)


func test_none_when_no_hurtbox_is_close_enough() -> void:
	var positions: Array[Vector3] = [Vector3(4.0, 0.0, 0.0)]
	assert_eq(Skill.nearest_to(Vector3(1.0, 0.0, 0.0), positions, 1.5), -1)


func test_height_is_ignored() -> void:
	var positions: Array[Vector3] = [Vector3(1.0, 0.8, 0.0)]
	assert_eq(Skill.nearest_to(Vector3(1.0, 0.0, 0.0), positions, 0.5), 0)
