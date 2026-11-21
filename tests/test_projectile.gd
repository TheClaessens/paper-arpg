extends GutTest
## A Projectile flies straight along its direction and disappears once it has flown its
## Snapshot's Range. It keeps the Snapshot of the throw that fired it.

const ProjectileScene := preload("res://skills/fireball/projectile.tscn")


func test_flies_along_its_direction_then_disappears_after_its_range() -> void:
	var projectile: Projectile = ProjectileScene.instantiate()
	projectile.direction = Vector3.LEFT
	projectile.snapshot = Snapshot.new([], {Fireball.SPEED: 60.0, Skill.RANGE: 5.0}, []) # 1 unit per frame at 60 Hz
	add_child_autoqfree(projectile)
	await wait_physics_frames(2)
	assert_lt(projectile.global_position.x, -0.5, "moving left")
	assert_almost_eq(projectile.global_position.z, 0.0, 0.001, "straight")
	await wait_physics_frames(8)
	assert_freed(projectile, "gone after 5 units")


func test_a_ball_in_flight_keeps_its_throws_snapshot() -> void:
	var fireball: Fireball = preload("res://skills/fireball/fireball.tscn").instantiate()
	add_child_autoqfree(fireball)
	var farther := Modifier.new()
	var change := NumberChange.new()
	change.number = Skill.RANGE
	change.amount = 5.0
	farther.number_changes = [change]
	var modifiers: Array[Modifier] = [farther]
	fireball.try_activate(Vector3.RIGHT, modifiers)
	var ball: Projectile = fireball.get_child(0)
	modifiers.clear() # the Character loses the Modifier while the ball flies
	assert_eq(ball.snapshot.number(Skill.RANGE), 15.0, "still 10 + 5")
	assert_eq(fireball.snapshot(modifiers).number(Skill.RANGE), 10.0, "the next throw goes 10")
