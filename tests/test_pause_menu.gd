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
	add_child_autofree(player)
	player.set_physics_process(false) # no camera here to read input against; after add_child, or _ready turns it back on
	hud = HudScene.instantiate()
	hud.player = player
	menu = MenuScene.instantiate()
	menu.player = player
	menu.hud = hud
	add_child_autofree(menu)
	add_child_autofree(hud)


func after_each() -> void:
	if Console.is_open(): # a failed test may have left it open
		Console._toggle_panel()
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


# A controller moves through the screens by focus alone, so each step must leave focus somewhere.

func _focused() -> Control:
	return get_viewport().gui_get_focus_owner()


func test_controller_focus_follows_each_step() -> void:
	menu.open()
	assert_eq(_focused(), _button("SkillBarItem"), "the menu's first item")
	_button("SkillBarItem").pressed.emit()
	assert_eq(_focused(), hud.find_child("Slot0", true, false).find_child("Choose", true, false), "the main slot")
	_choose_slot(1)
	assert_eq(_focused(), _button("Empty"), "the slot's current tile in the drawer")
	_button("Fireball").pressed.emit()
	assert_eq(_focused(), hud.find_child("Slot1", true, false).find_child("Choose", true, false), "back on the slot")


func _pad(button: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = true
	return event


func test_the_controller_chooses_with_a_and_steps_back_with_b() -> void:
	assert_true(InputMap.event_is_action(_pad(JOY_BUTTON_A), &"ui_accept"), "A chooses")
	assert_true(InputMap.event_is_action(_pad(JOY_BUTTON_B), &"ui_cancel"), "B steps back")


# The Console pauses the game while open and restores the pause it found, so the pause menu
# stays out of the way meanwhile.

func test_the_corner_button_waits_for_the_console_to_close() -> void:
	Console._toggle_panel() # open
	_button("Corner").pressed.emit()
	assert_null(_button("SkillBarItem"), "no pause menu")
	Console._toggle_panel() # close
	assert_false(get_tree().paused, "the game runs again")
	_button("Corner").pressed.emit()
	assert_not_null(_button("SkillBarItem"), "now it pauses")


func test_resume_waits_for_the_console_to_close() -> void:
	menu.open()
	Console._toggle_panel() # open, over the pause menu
	_button("Resume").pressed.emit()
	assert_not_null(_button("Resume"), "still in the pause menu")
	Console._toggle_panel() # close
	assert_true(get_tree().paused, "and still paused")
