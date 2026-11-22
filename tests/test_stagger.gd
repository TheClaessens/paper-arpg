extends GutTest
## A Stagger slides its Character exactly its knockback, fastest at first; a frozen frame moves
## nothing; another hit restarts it; a Stagger of 0 does nothing.

var stagger: Stagger


func before_each() -> void:
	stagger = autofree(Stagger.new())


## Steps the Stagger by `delta` until it is over and returns how far it slid in all.
func _slide_it_out(delta: float) -> Vector3:
	var slid := Vector3.ZERO
	while stagger.is_active():
		slid += stagger.next_velocity(delta) * delta
	return slid


# Knockback: the slide's speed falls linearly to zero over the Stagger, so the distance still
# to go shrinks with the square of the time left.

func test_knockback_left_over_the_stagger() -> void:
	assert_almost_eq(Stagger.knockback_left(0.8, 0.2, 0.2), 0.8, 0.001, "all of it at the start")
	assert_almost_eq(Stagger.knockback_left(0.8, 0.2, 0.1), 0.2, 0.001, "a quarter halfway")
	assert_almost_eq(Stagger.knockback_left(0.8, 0.2, 0.0), 0.0, 0.001, "none at the end")


func test_a_whole_stagger_slides_exactly_its_knockback() -> void:
	assert_false(stagger.is_active(), "not before a hit")
	for delta: float in [1.0 / 60.0, 1.0 / 45.0]:
		stagger.start(Vector3(0.35, 0.0, 0.0), 0.05)
		assert_true(stagger.is_active())
		assert_almost_eq(_slide_it_out(delta), Vector3(0.35, 0.0, 0.0), Vector3.ONE * 0.0001, "at 1/%d s" % roundi(1.0 / delta))


func test_a_frozen_frame_moves_nothing() -> void:
	stagger.start(Vector3(0.35, 0.0, 0.0), 0.05)
	assert_eq(stagger.next_velocity(0.0), Vector3.ZERO)
	assert_true(stagger.is_active(), "its clock is held")
	assert_almost_eq(_slide_it_out(1.0 / 60.0), Vector3(0.35, 0.0, 0.0), Vector3.ONE * 0.0001, "the rest still totals the knockback")


func test_another_hit_restarts_it() -> void:
	stagger.start(Vector3(1.0, 0.0, 0.0), 0.5)
	stagger.next_velocity(1.0 / 60.0)
	stagger.next_velocity(1.0 / 60.0)
	stagger.start(Vector3(0.0, 0.0, 0.35), 0.05)
	var elapsed := 0.0
	var slid := Vector3.ZERO
	while stagger.is_active():
		slid += stagger.next_velocity(1.0 / 60.0) / 60.0
		elapsed += 1.0 / 60.0
	assert_almost_eq(slid, Vector3(0.0, 0.0, 0.35), Vector3.ONE * 0.0001, "the first knockback's rest is dropped")
	assert_lte(elapsed, 0.05 + 1.0 / 60.0, "over within the new Stagger")


func test_a_stagger_of_0_does_nothing() -> void:
	stagger.start(Vector3(0.35, 0.0, 0.0), 0.0)
	assert_false(stagger.is_active())
	assert_eq(stagger.next_velocity(1.0 / 60.0), Vector3.ZERO)
	stagger.start(Vector3(0.0, 0.0, 0.35), 0.05)
	stagger.start(Vector3(0.35, 0.0, 0.0), 0.0)
	assert_almost_eq(_slide_it_out(1.0 / 60.0), Vector3(0.0, 0.0, 0.35), Vector3.ONE * 0.0001, "a running Stagger goes on along its own knockback")
