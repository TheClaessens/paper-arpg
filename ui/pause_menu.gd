class_name PauseMenu
extends Control
## The pause button and the pause screen. The button, the `pause` action (Esc, controller
## Start) or open() pauses the game and shows the Skill slot. Choosing the slot opens the Skill
## menu; choosing a Skill there puts it in the slot. Works with touch, mouse and controller:
## the D-pad or stick moves between buttons and the bottom button chooses.

## Whose Skill slot this is; the Skill menu offers the player's Skills.
@export var player: Player

@onready var _pause_button: Button = %PauseButton
@onready var _screen: Control = %Screen
@onready var _main: Control = %Main
@onready var _slot_button: Button = %Slot
@onready var _skill_menu: Control = %SkillMenu
@onready var _options: VBoxContainer = %Options


func _ready() -> void:
	_screen.hide()
	_pause_button.pressed.connect(open)
	_slot_button.pressed.connect(_show_skill_menu)
	(%Resume as Button).pressed.connect(close)
	(%Back as Button).pressed.connect(_show_main)


## Pauses the game and shows the pause screen.
func open() -> void:
	get_tree().paused = true
	_screen.show()
	_pause_button.hide()
	_show_main()


## Hides the pause screen and lets the game run again.
func close() -> void:
	_screen.hide()
	_pause_button.show()
	get_tree().paused = false


# Runs while paused (process_mode ALWAYS). Esc and Start pause; on the pause screen they, and
# the controller's B button (ui_cancel), step back: from the Skill menu to the pause screen,
# from there to the game.
func _unhandled_input(event: InputEvent) -> void:
	if not _screen.visible:
		if event.is_action_pressed(&"pause"):
			get_viewport().set_input_as_handled()
			open()
	elif event.is_action_pressed(&"pause") or event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		if _skill_menu.visible:
			_show_main()
		else:
			close()


func _show_main() -> void:
	_skill_menu.hide()
	_main.show()
	_slot_button.text = player.skill_slot.skill.title
	_slot_button.icon = player.skill_slot.skill.icon
	_slot_button.grab_focus.call_deferred() # for the controller; touch and mouse ignore focus


## One button per Skill the player has, the one in the slot shown pressed. Rebuilt each time,
## so it always matches the slot.
func _show_skill_menu() -> void:
	_main.hide()
	_skill_menu.show()
	for old in _options.get_children():
		old.queue_free()
	for skill in player.skills:
		var option := Button.new()
		option.text = skill.title
		option.icon = skill.icon
		option.toggle_mode = true
		option.button_pressed = skill == player.skill_slot.skill
		option.custom_minimum_size = Vector2(220.0, 56.0)
		option.pressed.connect(_choose.bind(skill))
		_options.add_child(option)
		if option.button_pressed:
			option.grab_focus.call_deferred()


func _choose(skill: Skill) -> void:
	player.skill_slot.skill = skill
	_show_main()
