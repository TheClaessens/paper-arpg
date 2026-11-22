extends GutTest
## A Skill slot's button flashes when the Skill it shows is ready again: any Skill, even one the
## player gained after the HUD was made, and only the one it shows now.

const ButtonScene := preload("res://ui/skill_slot_button.tscn")


func _button() -> SkillSlotButton:
	var button: SkillSlotButton = ButtonScene.instantiate()
	add_child_autofree(button)
	return button


## A Skill that has just been activated: on a 1 second Cooldown.
func _cooling_skill() -> Skill:
	var skill: Skill = autofree(Skill.new())
	skill.start_cooldown(1.0)
	return skill


func _flashing(button: SkillSlotButton) -> bool:
	return (button.get_node("Face") as Control).modulate.r > 1.0


func test_it_flashes_when_its_skill_is_ready_again() -> void:
	var button := _button()
	var skill := _cooling_skill() # made after the button, as a Skill gained later is
	button.show_skill(skill)
	skill.cool_down(0.5)
	assert_false(_flashing(button), "still cooling down")
	skill.cool_down(0.5)
	assert_true(_flashing(button))


func test_a_skill_swapped_out_no_longer_flashes_it() -> void:
	var button := _button()
	var old := _cooling_skill()
	button.show_skill(old)
	button.show_skill(null)
	old.cool_down(1.0)
	assert_false(_flashing(button))


func test_a_skill_in_two_slots_flashes_both() -> void:
	var first := _button()
	var second := _button()
	var skill := _cooling_skill()
	first.show_skill(skill)
	second.show_skill(skill)
	skill.cool_down(1.0)
	assert_true(_flashing(first))
	assert_true(_flashing(second))


func _push_touch(at: Vector2, pressed: bool, canceled := false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = at
	event.pressed = pressed
	event.canceled = canceled
	get_viewport().push_input(event, true)


func _push_drag(to: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = 0
	event.position = to
	get_viewport().push_input(event, true)


## A button clear of the Console's corner button, so a pushed touch can't land on both.
func _placed_button() -> SkillSlotButton:
	var button := _button()
	button.place(Vector2(300, 300), 88.0)
	watch_signals(button)
	return button


func test_a_touch_the_system_cancels_is_not_a_lift() -> void:
	var button := _placed_button()
	_push_touch(button.centre(), true)
	_push_touch(button.centre(), false)
	assert_signal_emit_count(button, "touch_ended", 1, "a tap lifts")
	assert_signal_emit_count(button, "touch_lost", 0)
	_push_touch(button.centre(), true)
	_push_touch(Vector2(-1, -1), false) # how iOS reports a touch the system cancels
	assert_signal_emit_count(button, "touch_ended", 1, "the cancel is not a lift")
	assert_signal_emit_count(button, "touch_lost", 1)
	button.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT) # the focus loss after it
	assert_signal_emit_count(button, "touch_lost", 1, "one finger is lost once")


func test_a_release_marked_canceled_is_not_a_lift() -> void:
	var button := _placed_button()
	_push_touch(button.centre(), true)
	_push_touch(button.centre(), false, true)
	assert_signal_emit_count(button, "touch_lost", 1)
	assert_signal_emit_count(button, "touch_ended", 0)


func test_losing_focus_lets_go_of_the_finger() -> void:
	var button := _placed_button()
	button.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_signal_emit_count(button, "touch_lost", 0, "no finger, nothing lost")
	_push_touch(button.centre(), true)
	button.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_signal_emit_count(button, "touch_lost", 1)
	_push_drag(button.centre() + Vector2(10, 0))
	_push_touch(button.centre(), false)
	assert_signal_emit_count(button, "touch_moved", 0, "the lost finger is forgotten")
	assert_signal_emit_count(button, "touch_ended", 0)
