extends GutTest
## The pause screen: it pauses the game, and its Skill menu changes what the Skill slot holds.

const MenuScene := preload("res://ui/pause_menu.tscn")
const PlayerScene := preload("res://characters/player/player.tscn")

var menu: PauseMenu
var player: Player


func before_each() -> void:
	player = PlayerScene.instantiate()
	player.set_physics_process(false) # no camera here to read input against
	add_child_autofree(player)
	menu = MenuScene.instantiate()
	menu.player = player
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
	assert_eq(player.skill_slot.skill, player.get_node("Fireball"))
	assert_not_null(_button("Resume"), "back on the pause screen")
	assert_true(get_tree().paused, "still paused")


func test_back_leaves_the_slot_alone() -> void:
	menu.open()
	_button("Attack").pressed.emit()
	_button("Back").pressed.emit()
	assert_eq(player.skill_slot.skill, player.get_node("Attack"))
	assert_not_null(_button("Resume"))
