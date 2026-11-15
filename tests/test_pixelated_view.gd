extends GutTest

var view: PixelatedView


func before_each() -> void:
	Settings.set_value(&"pixelated", true)
	view = PixelatedView.new()
	add_child_autofree(view)


func after_each() -> void:
	Settings.set_value(&"pixelated", true) # leave the global setting at its default


func _shrink_at(height: float, pixel_height: int = 240) -> int:
	view.pixel_height = pixel_height
	view.size = Vector2(1280.0, height)
	return view.stretch_shrink


func test_picks_the_nearest_whole_shrink() -> void:
	assert_eq(_shrink_at(720.0), 3) # 720 / 240 = 3, renders 240 tall
	assert_eq(_shrink_at(1080.0), 5) # 4.5 rounds up, renders 216 tall
	assert_eq(_shrink_at(1440.0), 6)


func test_never_shrinks_below_one() -> void:
	assert_eq(_shrink_at(100.0), 1)


func test_follows_the_pixelated_setting() -> void:
	_shrink_at(1080.0)
	Settings.set_value(&"pixelated", false)
	assert_eq(view.stretch_shrink, 1)
	Settings.set_value(&"pixelated", true)
	assert_eq(view.stretch_shrink, 5)
