extends GutTest
## Hitstop: a hit freezes the game, and hits that overlap keep it frozen until the last one ends.


func after_each() -> void:
	Engine.time_scale = 1.0


# A wait that the freeze itself doesn't stop.
func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout


func test_overlapping_hitstops_freeze_until_the_last_ends() -> void:
	var feedback := HitFeedback.new()
	feedback.hitstop = 0.1
	feedback.shake = 0.0
	feedback.play_impact(get_viewport())
	assert_eq(Engine.time_scale, 0.0, "frozen")
	await _wait(0.06)
	feedback.play_impact(get_viewport()) # a second hit while frozen
	await _wait(0.06) # the first hitstop is over, the second isn't
	assert_eq(Engine.time_scale, 0.0, "still frozen")
	await _wait(0.08)
	assert_eq(Engine.time_scale, 1.0, "running again")


func test_an_impact_that_does_not_freeze_leaves_the_game_running() -> void:
	var feedback := HitFeedback.new()
	feedback.hitstop = 0.1
	feedback.shake = 0.0
	feedback.play_impact(get_viewport(), false)
	assert_eq(Engine.time_scale, 1.0)
