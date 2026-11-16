extends GutTest

const TouchStickScene := preload("res://ui/touch_stick.tscn")

var stick: TouchStick


func before_each() -> void:
	stick = add_child_autofree(TouchStickScene.instantiate())
	stick.radius = 80.0


func after_each() -> void:
	for action: StringName in [&"move_left", &"move_right", &"move_up", &"move_down"]:
		Input.action_release(action)


func _touch(index: int, at: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = at
	event.pressed = pressed
	stick._unhandled_input(event)


func _drag(index: int, to: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = to
	stick._unhandled_input(event)


# Raw strengths: get_vector() would rescale them past the deadzone.
func _pushed() -> Vector2:
	return Vector2(
		Input.get_action_raw_strength(&"move_right") - Input.get_action_raw_strength(&"move_left"),
		Input.get_action_raw_strength(&"move_down") - Input.get_action_raw_strength(&"move_up"))


func test_vector_is_offset_over_radius() -> void:
	assert_eq(TouchStick.stick_vector(Vector2(100, 100), Vector2(140, 100), 80.0), Vector2(0.5, 0))


func test_vector_clamps_at_the_rim() -> void:
	assert_eq(TouchStick.stick_vector(Vector2(100, 100), Vector2(100, 400), 80.0), Vector2(0, 1))


func test_origin_follows_a_thumb_past_the_rim() -> void:
	assert_eq(TouchStick.followed_origin(Vector2(100, 100), Vector2(300, 100), 80.0), Vector2(220, 100))


func test_origin_stays_while_thumb_is_inside() -> void:
	assert_eq(TouchStick.followed_origin(Vector2(100, 100), Vector2(150, 100), 80.0), Vector2(100, 100))


func test_drag_on_left_half_pushes_move_actions() -> void:
	_touch(0, Vector2(100, 400), true)
	_drag(0, Vector2(100, 300))
	assert_almost_eq(_pushed().y, -1.0, 0.01, "dragging up past the rim pushes fully up")


func test_touch_on_right_half_is_ignored() -> void:
	var right := get_viewport().get_visible_rect().size.x * 0.75
	_touch(0, Vector2(right, 400), true)
	_drag(0, Vector2(right, 300))
	assert_eq(_pushed(), Vector2.ZERO)


func test_second_finger_is_ignored() -> void:
	_touch(0, Vector2(100, 400), true)
	_touch(1, Vector2(200, 400), true)
	_drag(1, Vector2(300, 400))
	assert_eq(_pushed(), Vector2.ZERO, "only the first finger drives the stick")


func test_lifting_the_finger_releases_the_actions() -> void:
	_touch(0, Vector2(100, 400), true)
	_drag(0, Vector2(200, 400))
	_touch(0, Vector2(200, 400), false)
	assert_eq(_pushed(), Vector2.ZERO)


func test_losing_focus_releases_the_actions() -> void:
	_touch(0, Vector2(100, 400), true)
	_drag(0, Vector2(200, 400))
	stick.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_eq(_pushed(), Vector2.ZERO)


func test_follow_mode_drags_the_origin() -> void:
	stick.follow = true
	_touch(0, Vector2(100, 400), true)
	_drag(0, Vector2(400, 400)) # origin follows to 320
	_drag(0, Vector2(300, 400)) # 20 px left of the new origin
	assert_almost_eq(_pushed().x, -0.25, 0.01, "a short flick back reverses direction")


func test_touch_on_console_button_does_not_start_the_stick() -> void:
	var button: Button = Console.get_node("%Button")
	var on_button := InputEventScreenTouch.new()
	on_button.position = button.get_global_rect().get_center()
	on_button.pressed = true
	get_viewport().push_input(on_button, true)
	_drag(0, on_button.position + Vector2(100, 0))
	assert_eq(_pushed(), Vector2.ZERO, "the GUI claims touches on the button")
	# Control step: the same route off the button does reach the stick.
	var beside := InputEventScreenTouch.new()
	beside.position = on_button.position + Vector2(0, 100)
	beside.pressed = true
	get_viewport().push_input(beside, true)
	_drag(0, beside.position + Vector2(100, 0))
	assert_gt(_pushed().x, 0.0, "a touch beside the button starts the stick")


func test_stick_leaves_a_held_key_alone() -> void:
	Input.action_press(&"move_up") # W held on the keyboard
	_touch(0, Vector2(100, 400), true)
	_drag(0, Vector2(200, 400))
	_touch(0, Vector2(200, 400), false)
	assert_true(Input.is_action_pressed(&"move_up"), "the stick only releases what it pressed")


func test_pausing_without_a_thumb_leaves_a_held_key_alone() -> void:
	Input.action_press(&"move_up")
	stick.notification(Node.NOTIFICATION_PAUSED)
	assert_true(Input.is_action_pressed(&"move_up"))
