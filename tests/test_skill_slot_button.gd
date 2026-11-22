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
