extends GutTest
## The pause menu and the Skill bar view: pausing shows the menu, "Skill bar" lets the player
## choose a slot, and the Skill drawer puts a Skill in it or empties it. Back steps out one
## level at a time.

const MenuScene := preload("res://ui/pause_menu.tscn")
const HudScene := preload("res://ui/skill_bar_hud.tscn")
const PlayerScene := preload("res://characters/player/player.tscn")

var menu: PauseMenu
var hud: SkillBarHud
var player: Player


func before_each() -> void:
	player = PlayerScene.instantiate()
	player.set_physics_process(false) # no camera here to read input against
	add_child_autofree(player)
	hud = HudScene.instantiate()
	hud.player = player
	menu = MenuScene.instantiate()
	menu.player = player
	menu.hud = hud
	add_child_autofree(menu)
	add_child_autofree(hud)


func after_each() -> void:
	get_tree().paused = false


## A visible button, found by its node name.
func _button(name: String) -> Button:
	for root: Node in [menu, hud]:
		var found := root.find_child(name, true, false) as Button
		if found and found.is_visible_in_tree():
			return found
	return null


func _choose_slot(slot: int) -> void:
	(hud.find_child("Slot%d" % slot, true, false).find_child("Choose", true, false) as Button).pressed.emit()


func test_pausing_shows_the_menu_and_resume_ends_it() -> void:
	menu.open()
	assert_true(get_tree().paused)
	assert_not_null(_button("SkillBarItem"))
	_button("Resume").pressed.emit()
	assert_false(get_tree().paused)


func test_a_slot_takes_a_skill_from_the_drawer() -> void:
	menu.open()
	_button("SkillBarItem").pressed.emit()
	_choose_slot(1)
	_button("Fireball").pressed.emit()
	assert_eq(player.skill_bar.skill_in(1), player.get_node("Fireball"))
	assert_null(_button("Fireball"), "the drawer closed")


func test_the_empty_tile_clears_a_slot() -> void:
	menu.open()
	_button("SkillBarItem").pressed.emit()
	_choose_slot(0)
	_button("Empty").pressed.emit()
	assert_null(player.skill_bar.skill_in(0))


func test_back_steps_out_one_level_at_a_time() -> void:
	menu.open()
	_button("SkillBarItem").pressed.emit()
	_choose_slot(2)
	menu.back()
	assert_null(_button("Fireball"), "first the drawer closes")
	assert_null(_button("SkillBarItem"), "still in the Skill bar view")
	menu.back()
	assert_not_null(_button("SkillBarItem"), "then the pause menu")
	menu.back()
	assert_false(get_tree().paused, "then the game")
