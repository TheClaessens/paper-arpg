class_name DevConsole
extends CanvasLayer
## Developer console, available in debug builds only.
## Open with the backtick key (`), by clicking both sticks in at once, or with the button in
## the top-left corner (for touch screens).
## Systems add their own commands with register(); the console itself only knows
## `help`, the commands for reading and changing Settings, and engine debug toggles.
##
## In release builds the Console is an empty shell: no panel, no input, and register()
## does nothing. Game code can call it freely without checking the build type.

## A command callback takes the words typed after the command name and returns text to show.
## Example: Console.register(&"hello", func(args: PackedStringArray) -> String: return "hi", "Say hi.")

## The Settings autoload, swapped for a fresh instance in tests.
var settings: GameSettings

var _enabled := OS.is_debug_build()
var _commands: Dictionary[StringName, Dictionary] = {}
var _game_was_paused := false

@onready var _panel: Control = $Panel
@onready var _output: RichTextLabel = %Output
@onready var _field: LineEdit = %Input
@onready var _toggle: Button = %Toggle


func _init() -> void:
	register(&"help", _cmd_help, "List all commands.")
	register(&"settings", _cmd_settings, "List every setting with its value.")
	register(&"get", _cmd_get, "get <setting>: show a setting's value.")
	register(&"set", _cmd_set, "set <setting> <value>: change a setting.")
	register(&"collisions", _cmd_collisions, "Toggle drawing collision shapes.")
	register(&"nav", _cmd_nav, "Toggle drawing every Enemy's path. Navmesh: Debug > Visible Navigation.")


func _ready() -> void:
	if not _enabled:
		_panel.queue_free()
		_toggle.queue_free()
		set_process_input(false)
		return
	if settings == null:
		settings = Settings
	_panel.hide()
	_field.text_submitted.connect(_on_input_submitted)
	_toggle.pressed.connect(_toggle_panel)
	get_viewport().size_changed.connect(_avoid_notch)
	_avoid_notch()


func register(command: StringName, callback: Callable, help: String) -> void:
	if not _enabled:
		return
	assert(not _commands.has(command), "Console command registered twice: %s" % command)
	_commands[command] = {callback = callback, help = help}


func unregister(command: StringName) -> void:
	_commands.erase(command)


## Runs one line of input and returns the text to show.
func execute(line: String) -> String:
	var words := line.strip_edges().split(" ", false)
	if words.is_empty():
		return ""
	var command := StringName(words[0])
	if not _commands.has(command):
		return "Unknown command '%s'. Type 'help' for a list." % command
	var callback: Callable = _commands[command].callback
	return callback.call(words.slice(1))


func _input(event: InputEvent) -> void:
	if _is_toggle(event):
		get_viewport().set_input_as_handled() # keeps the ` out of the text field
		_toggle_panel()


func _toggle_panel() -> void:
	_panel.visible = not _panel.visible
	# Typing must not drive the game: the Player reads the keyboard directly, so pause the
	# whole tree while open (the Console runs with process_mode ALWAYS). Closing restores
	# whatever pause state the game had before.
	if _panel.visible:
		_game_was_paused = get_tree().paused
		get_tree().paused = true
		_field.clear()
		_field.grab_focus() # on iOS this brings up the on-screen keyboard
	else:
		get_tree().paused = _game_was_paused
		_field.release_focus()


## Insets the button past an iPhone's notch. The safe area is in screen pixels, so it's scaled
## to the stretched viewport. In landscape the notch can flip sides when the phone turns, so
## the larger side inset is used either way.
func _avoid_notch() -> void:
	if not OS.has_feature("mobile"):
		return # on desktop the safe area is the display's, not the window's
	var safe := Rect2(DisplayServer.get_display_safe_area())
	var screen := Vector2(DisplayServer.window_get_size())
	var left := safe.position.x
	var right := screen.x - safe.end.x
	var to_viewport := get_viewport().get_visible_rect().size / screen
	_toggle.position = Vector2(maxf(left, right), safe.position.y) * to_viewport


func _is_toggle(event: InputEvent) -> bool:
	var key := event as InputEventKey
	if key:
		return key.pressed and not key.echo and key.physical_keycode == KEY_QUOTELEFT
	var button := event as InputEventJoypadButton
	if button and button.pressed:
		# Fires when the second stick goes down while the first is still held.
		match button.button_index:
			JOY_BUTTON_LEFT_STICK:
				return Input.is_joy_button_pressed(button.device, JOY_BUTTON_RIGHT_STICK)
			JOY_BUTTON_RIGHT_STICK:
				return Input.is_joy_button_pressed(button.device, JOY_BUTTON_LEFT_STICK)
	return false


func _on_input_submitted(text: String) -> void:
	_field.clear()
	if text.strip_edges().is_empty():
		return
	_output.add_text("> %s\n" % text)
	var result := execute(text)
	if not result.is_empty():
		_output.add_text(result + "\n")


func _cmd_help(_args: PackedStringArray) -> String:
	var names: Array[StringName] = _commands.keys()
	names.sort()
	var lines := PackedStringArray()
	for command: StringName in names:
		lines.append("%s  %s" % [command, _commands[command].help])
	return "\n".join(lines)


func _cmd_settings(_args: PackedStringArray) -> String:
	var lines := PackedStringArray()
	for key: StringName in settings.DEFINITIONS:
		lines.append("%s = %s  %s" % [key, settings.get_value(key), settings.DEFINITIONS[key].description])
	return "\n".join(lines)


func _cmd_get(args: PackedStringArray) -> String:
	if args.size() != 1:
		return "Usage: get <setting>"
	if not settings.has_setting(args[0]):
		return _unknown_setting(args[0])
	return _show_setting(args[0])


func _cmd_set(args: PackedStringArray) -> String:
	if args.size() != 2:
		return "Usage: set <setting> <value>"
	match settings.set_from_text(args[0], args[1]):
		OK:
			return _show_setting(args[0])
		ERR_DOES_NOT_EXIST:
			return _unknown_setting(args[0])
		_:
			return "'%s' is not a valid value for %s." % [args[1], args[0]]


func _cmd_collisions(_args: PackedStringArray) -> String:
	var tree := get_tree()
	tree.debug_collisions_hint = not tree.debug_collisions_hint
	# Shapes build their debug mesh when they enter the tree, so the scene re-enters to redraw.
	# Unlike reloading it, this keeps its state: everything stays where it is.
	var scene := tree.current_scene
	tree.root.remove_child(scene)
	tree.root.add_child(scene)
	tree.current_scene = scene
	# A GridMap builds its debug shapes with its tile chunks, which only a rebuild recreates.
	for grid_map: GridMap in scene.find_children("*", "GridMap", true, false):
		grid_map.cell_size = grid_map.cell_size
	return "collisions %s" % ("on" if tree.debug_collisions_hint else "off")


## Only the paths: the navmesh itself draws only when navigation debugging is on from launch
## (editor: Debug > Visible Navigation, or --debug-navigation), and scripts can't switch it.
func _cmd_nav(_args: PackedStringArray) -> String:
	var on := not NavigationServer3D.get_debug_enabled()
	NavigationServer3D.set_debug_enabled(on)
	for agent: NavigationAgent3D in get_tree().root.find_children("*", "NavigationAgent3D", true, false):
		agent.debug_enabled = on
	return "nav %s" % ("on" if on else "off")


func _show_setting(key: StringName) -> String:
	return "%s = %s" % [key, settings.get_value(key)]


func _unknown_setting(key: StringName) -> String:
	return "Unknown setting '%s'. Type 'settings' for a list." % key
