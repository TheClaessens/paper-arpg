extends GutTest

var movement: Movement


func before_each() -> void:
	movement = autofree(Movement.new())
	movement.speed = 4.0
	movement.acceleration = 40.0
	movement.deceleration = 80.0


func test_accelerates_toward_direction() -> void:
	var velocity := movement.next_velocity(Vector3.ZERO, Vector3.RIGHT, 0.05)
	assert_almost_eq(velocity, Vector3(2.0, 0.0, 0.0), Vector3.ONE * 0.001)


func test_caps_at_speed() -> void:
	var velocity := movement.next_velocity(Vector3.ZERO, Vector3.RIGHT, 1.0)
	assert_almost_eq(velocity, Vector3(4.0, 0.0, 0.0), Vector3.ONE * 0.001)


func test_decelerates_when_no_direction() -> void:
	var velocity := movement.next_velocity(Vector3(4.0, 0.0, 0.0), Vector3.ZERO, 0.025)
	assert_almost_eq(velocity, Vector3(2.0, 0.0, 0.0), Vector3.ONE * 0.001)


func test_comes_to_rest() -> void:
	var velocity := movement.next_velocity(Vector3(4.0, 0.0, 0.0), Vector3.ZERO, 1.0)
	assert_eq(velocity, Vector3.ZERO)


func test_turns_using_acceleration() -> void:
	# Reversing heads for the new target at the acceleration rate, through zero.
	var velocity := movement.next_velocity(Vector3(4.0, 0.0, 0.0), Vector3.LEFT, 0.05)
	assert_almost_eq(velocity, Vector3(2.0, 0.0, 0.0), Vector3.ONE * 0.001)
