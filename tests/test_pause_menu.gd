extends GutTest
## The pause screen: it pauses the game, and its Skill menu changes what the Skill slot holds.

const MenuScene := preload("res://ui/pause_menu.tscn")

var menu: PauseMenu
var slot: SkillSlot
var attack: Skill
var fireball: Skill


func before_each() -> void:
	attack = autofree(Skill.new())
	attack.title = "Attack"
	fireball = autofree(Skill.new())
	fireball.title = "Fireball"
	slot = autofree(SkillSlot.new())
	slot.skill = attack
	menu = MenuScene.instantiate()
	menu.skill_slot = slot
	menu.skills = [attack, fireball]
	add_child_autofree(menu)


func after_each() -> void:
	get_tree().paused = false


func _button(text: String) -> Button:
	for button: Button in menu.find_children("*", "Button", true, false):
		if button.text == text and button.is_visible_in_tree():
			return button
	return null


func test_opening_pauses_the_game() -> void:
	menu.open()
	assert_true(get_tree().paused)
	_button("Resume").pressed.emit()
	assert_false(get_tree().paused)


func test_choosing_a_skill_puts_it_in_the_slot() -> void:
	menu.open()
	_button("Attack").pressed.emit() # the slot, showing what it holds
	_button("Fireball").pressed.emit() # in the Skill menu
	assert_eq(slot.skill, fireball)
	assert_not_null(_button("Resume"), "back on the pause screen")
	assert_true(get_tree().paused, "still paused")


func test_back_leaves_the_slot_alone() -> void:
	menu.open()
	_button("Attack").pressed.emit()
	_button("Back").pressed.emit()
	assert_eq(slot.skill, attack)
	assert_not_null(_button("Resume"))
