extends GutTest
## The Enemy nearest a spot on the ground, if one is close enough: what a Skill landing on a
## spot picks out, and which Enemy the mouse cursor highlights.


func test_the_enemy_nearest_the_spot() -> void:
	var enemies: Array[Vector3] = [Vector3(4.0, 0.0, 0.0), Vector3(2.0, 0.0, 1.0), Vector3(2.5, 0.0, -0.5)]
	assert_eq(Enemy.nearest_to(Vector3(2.4, 0.0, -0.2), enemies, 1.5), 2)


func test_none_when_no_enemy_is_close_enough() -> void:
	var enemies: Array[Vector3] = [Vector3(4.0, 0.0, 0.0)]
	assert_eq(Enemy.nearest_to(Vector3(1.0, 0.0, 0.0), enemies, 1.5), -1)


func test_height_is_ignored() -> void:
	var enemies: Array[Vector3] = [Vector3(1.0, 0.8, 0.0)]
	assert_eq(Enemy.nearest_to(Vector3(1.0, 0.0, 0.0), enemies, 0.5), 0)
