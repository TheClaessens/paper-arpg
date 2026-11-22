extends SceneTree
## Opens a scene, takes a screenshot, then runs each console command and screenshots again.
## Used to check a change visually without clicking through the game.
##
##   godot --path . --resolution 1280x720 --script res://tools/screenshot.gd -- \
##       res://scenes/game.tscn "tp 16 7.5" "set pixelated 0"
##
## Writes 0_start.png, 1_tp-16-7.5.png, ... to user://screenshots/ and prints each path.
## Needs a window (no --headless): headless runs render nothing.
## Keep project class names out of this file: a --script entry point compiles before
## autoloads exist, so naming them (DevConsole, Standee, ...) breaks compilation.

const SETTLE_FRAMES := 30 # time for the scene to load and animations to start
const COMMAND_FRAMES := 10


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		printerr("Usage: --script res://tools/screenshot.gd -- <scene> [console command]...")
		quit(1)
		return
	change_scene_to_file(args[0])
	await _frames(SETTLE_FRAMES)
	DirAccess.make_dir_recursive_absolute("user://screenshots")
	_shot("0_start")
	var console: Node = root.get_node("Console")
	for i in range(1, args.size()):
		print("> %s\n%s" % [args[i], console.call("execute", args[i])])
		await _frames(COMMAND_FRAMES)
		_shot("%d_%s" % [i, args[i].to_lower().replace(" ", "-")])
	quit()


func _frames(count: int) -> void:
	for i in count:
		await process_frame


func _shot(name: String) -> void:
	var path := "user://screenshots/%s.png" % name
	root.get_texture().get_image().save_png(path)
	print("screenshot: ", ProjectSettings.globalize_path(path))
