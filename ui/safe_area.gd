class_name SafeArea
extends RefCounted
## The part of the screen clear of a phone's notch and rounded corners, in viewport units.
## In landscape the notch changes sides when the phone turns, so the larger side inset is kept
## clear on both sides. On desktop the safe area belongs to the display, not the window, so
## there the whole viewport is clear.


## The clear rect of `viewport`.
static func of(viewport: Viewport) -> Rect2:
	var size := viewport.get_visible_rect().size
	if not OS.has_feature("mobile"):
		return Rect2(Vector2.ZERO, size)
	return inner(size, Vector2(DisplayServer.window_get_size()), Rect2(DisplayServer.get_display_safe_area()))


## The clear rect of a `viewport_size` viewport shown on a `screen_size` screen whose safe area
## is `safe`, in screen pixels.
static func inner(viewport_size: Vector2, screen_size: Vector2, safe: Rect2) -> Rect2:
	var scale := viewport_size / screen_size
	var side := maxf(safe.position.x, screen_size.x - safe.end.x) * scale.x
	var top := safe.position.y * scale.y
	var bottom := (screen_size.y - safe.end.y) * scale.y
	return Rect2(side, top, viewport_size.x - 2.0 * side, viewport_size.y - top - bottom)
