extends GutTest
## The part of the screen clear of a phone's notch and rounded corners, in viewport units.
## In landscape the notch changes sides when the phone turns, so the larger side inset is
## kept clear on both sides.


func test_the_larger_side_inset_is_kept_clear_on_both_sides() -> void:
	# A 2000×1000 px screen shown as a 1000×500 viewport, notch 120 px on the left,
	# 40 px clear at the bottom.
	var safe := Rect2(120.0, 0.0, 1880.0, 960.0)
	var inner := SafeArea.inner(Vector2(1000.0, 500.0), Vector2(2000.0, 1000.0), safe)
	assert_eq(inner, Rect2(60.0, 0.0, 880.0, 480.0))


func test_no_insets_leave_the_whole_viewport() -> void:
	var inner := SafeArea.inner(Vector2(1152.0, 648.0), Vector2(1152.0, 648.0), Rect2(0.0, 0.0, 1152.0, 648.0))
	assert_eq(inner, Rect2(0.0, 0.0, 1152.0, 648.0))
