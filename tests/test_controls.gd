extends GutTest
## Which Skill slot each binding presses and lets go of (Controls.slot_for()).


func _key(code: Key) -> InputEventKey:
	var key := InputEventKey.new()
	key.physical_keycode = code
	key.pressed = true
	return key


func _click(button: MouseButton, device: int) -> InputEventMouseButton:
	var click := InputEventMouseButton.new()
	click.button_index = button
	click.device = device
	click.pressed = true
	return click


func test_each_binding_presses_its_slot() -> void:
	assert_eq(Controls.slot_for(_click(MOUSE_BUTTON_LEFT, 0), true), 0, "left click: main slot")
	assert_eq(Controls.slot_for(_click(MOUSE_BUTTON_RIGHT, 0), true), 1, "right click")
	assert_eq(Controls.slot_for(_key(KEY_Q), true), 2)
	assert_eq(Controls.slot_for(_key(KEY_E), true), 3)
	assert_eq(Controls.slot_for(_key(KEY_R), true), 4)
	assert_eq(Controls.slot_for(_key(KEY_W), true), -1, "walking presses no slot")


func test_letting_go_of_a_binding_releases_its_slot() -> void:
	var key := _key(KEY_Q)
	key.pressed = false
	assert_eq(Controls.slot_for(key, false), 2)
	assert_eq(Controls.slot_for(_key(KEY_Q), false), -1, "a press releases nothing")


func test_a_touch_does_not_use_a_slot() -> void:
	# The mouse click Godot makes from every touch.
	assert_eq(Controls.slot_for(_click(MOUSE_BUTTON_LEFT, InputEvent.DEVICE_ID_EMULATION), true), -1)
