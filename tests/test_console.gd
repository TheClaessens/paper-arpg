extends GutTest

# Assertions compare dynamic values (settings, shader parameters), which are Variant by design.
@warning_ignore_start("unsafe_call_argument")

const ConsoleScene := preload("res://autoloads/console/console.tscn")

var console: DevConsole
var settings: GameSettings


## A node that owns a console command, as Player owns `tp`.
class CommandOwner:
	extends Node

	func ping(_args: PackedStringArray) -> String:
		return "pong"


func before_each() -> void:
	settings = autofree(GameSettings.new())
	console = autofree(DevConsole.new())
	console.settings = settings


func test_blank_line_does_nothing() -> void:
	assert_eq(console.execute("   "), "")


func test_unknown_command() -> void:
	assert_string_contains(console.execute("dance"), "Unknown command 'dance'")


func test_registered_command_receives_args() -> void:
	console.register(&"echo", func(args: PackedStringArray) -> String: return "|".join(args), "Echo.")
	assert_eq(console.execute("  echo a  b "), "a|b")


func test_command_leaves_with_its_node() -> void:
	var owner_node: CommandOwner = add_child_autofree(CommandOwner.new())
	console.register(&"ping", owner_node.ping, "Ping.")
	assert_eq(console.execute("ping"), "pong")
	remove_child(owner_node)
	assert_string_contains(console.execute("ping"), "Unknown command")


func test_a_node_leaving_keeps_other_nodes_commands() -> void:
	var leaving: CommandOwner = add_child_autofree(CommandOwner.new())
	var staying: CommandOwner = add_child_autofree(CommandOwner.new())
	console.register(&"ping", leaving.ping, "Ping.")
	console.register(&"pong", staying.ping, "Pong.")
	remove_child(leaving)
	assert_eq(console.execute("pong"), "pong")


func test_registering_the_same_callback_again_does_nothing() -> void:
	# Every Aggro registers the same static callback for `aggro`.
	var owner_node: CommandOwner = add_child_autofree(CommandOwner.new())
	console.register(&"ping", owner_node.ping, "Ping.")
	console.register(&"ping", owner_node.ping, "Ping.")
	assert_eq(console.execute("ping"), "pong")
	assert_eq(console.execute("help").count("ping  Ping."), 1)


func test_help_lists_commands_with_descriptions() -> void:
	var help: String = console.execute("help")
	assert_string_contains(help, "set  set <setting> <value>")
	assert_string_contains(help, "settings  List every setting")


func test_set_changes_setting() -> void:
	assert_eq(console.execute("set pixelated 0"), "pixelated = false")
	assert_eq(settings.get_value(&"pixelated"), false)


func test_set_reports_bad_input() -> void:
	assert_string_contains(console.execute("set pixelated"), "Usage")
	assert_string_contains(console.execute("set wobble 1"), "Unknown setting 'wobble'")
	assert_string_contains(console.execute("set pixelated maybe"), "not a valid value")
	assert_eq(settings.get_value(&"pixelated"), true)


func test_get_and_settings_show_values() -> void:
	assert_eq(console.execute("get pixelated"), "pixelated = true")
	assert_string_contains(console.execute("settings"), "pixelated = true")


func test_open_console_pauses_game_and_closing_restores_it() -> void:
	var open_console: DevConsole = add_child_autofree(ConsoleScene.instantiate())
	var toggle := InputEventKey.new()
	toggle.pressed = true
	toggle.physical_keycode = KEY_QUOTELEFT
	open_console._input(toggle)
	assert_true(get_tree().paused, "open console pauses the game")
	open_console._input(toggle)
	assert_false(get_tree().paused, "closing unpauses a game that was running")


func test_closing_console_keeps_game_paused_if_it_was() -> void:
	var open_console: DevConsole = add_child_autofree(ConsoleScene.instantiate())
	var toggle := InputEventKey.new()
	toggle.pressed = true
	toggle.physical_keycode = KEY_QUOTELEFT
	get_tree().paused = true
	open_console._input(toggle)
	open_console._input(toggle)
	assert_true(get_tree().paused, "a game paused before opening stays paused")
	get_tree().paused = false


func test_button_toggles_console_like_the_key() -> void:
	var open_console: DevConsole = add_child_autofree(ConsoleScene.instantiate())
	var button: Button = open_console.get_node("%Button")
	button.pressed.emit()
	assert_true(get_tree().paused, "button opens the console")
	button.pressed.emit()
	assert_false(get_tree().paused, "button closes it again")


func test_command_word_ignores_case() -> void:
	# iOS capitalises the first letter typed.
	assert_string_contains(console.execute("Help"), "settings  List every setting")
