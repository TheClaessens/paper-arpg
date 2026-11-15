extends GutTest

var console: DevConsole
var settings: GameSettings


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


func test_unregister_removes_command() -> void:
	console.register(&"echo", func(_args: PackedStringArray) -> String: return "", "Echo.")
	console.unregister(&"echo")
	assert_string_contains(console.execute("echo"), "Unknown command")


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
