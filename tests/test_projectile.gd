extends GutTest
## A Projectile flies straight along its direction and disappears once it has flown its Range.

const ProjectileScene := preload("res://skills/fireball/projectile.tscn")


func test_flies_along_its_direction_then_disappears_after_its_range() -> void:
	var projectile: Projectile = ProjectileScene.instantiate()
	projectile.direction = Vector3.LEFT
	projectile.speed = 60.0 # one unit per physics frame at 60 Hz
	projectile.range = 5.0
	add_child_autoqfree(projectile)
	await wait_physics_frames(2)
	assert_lt(projectile.global_position.x, -0.5, "moving left")
	assert_almost_eq(projectile.global_position.z, 0.0, 0.001, "straight")
	await wait_physics_frames(8)
	assert_freed(projectile, "gone after 5 units")
