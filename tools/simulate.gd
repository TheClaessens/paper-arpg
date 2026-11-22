extends SceneTree
## Runs a scene headless for some seconds after console commands, and prints where every
## Character is (and how far from the player) once per second. For checking how Enemies
## behave without playing: put the player somewhere with `tp`, then watch the numbers.
##
##   godot --headless --path . --script res://tools/simulate.gd -- \
##       res://scenes/game.tscn 6 "tp 16 7.5"
##
## To compare two runs, add `--fixed-fps 60` to the command (before `--path`): it steps the game
## without the wall clock, and without it the number of physics steps before the first command
## varies with how long the first frames take. Even with it, positions differ by up to 0.01,
## because the navigation server's avoidance runs on several threads. For output that is the
## same run after run, also put a file `override.cfg` next to `project.godot` with
## `[navigation]` and `avoidance/thread_model/avoidance_use_multiple_threads=false` on the next
## line, and delete it afterwards (git doesn't ignore it: don't commit it).
##
## The player stands still: nothing presses a key in a headless run.
## Keep project class names out of this file: a --script entry point compiles before
## autoloads exist, so naming them (DevConsole, Enemy, ...) breaks compilation.

const SETTLE_FRAMES := 2 # time for every _ready to run before the commands


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2 or not args[1].is_valid_float():
		printerr("Usage: --script res://tools/simulate.gd -- <scene> <seconds> [console command]...")
		quit(1)
		return
	change_scene_to_file(args[0])
	for i in SETTLE_FRAMES:
		await process_frame
	var console: Node = root.get_node("Console")
	for i in range(2, args.size()):
		print("> %s\n%s" % [args[i], console.call("execute", args[i])])
	var ticks := Engine.physics_ticks_per_second
	for second in ceili(args[1].to_float()):
		for i in ticks:
			await physics_frame
		_report(second + 1)
	quit()


func _report(second: int) -> void:
	var player := current_scene.find_child("Player", true, false) as Node3D
	print("t=%ds" % second)
	for body: Node in current_scene.find_children("*", "CharacterBody3D", true, false):
		var at := (body as Node3D).global_position
		var line := "  %-16s (%6.2f, %6.2f)" % [body.name, at.x, at.z]
		if player and body != player:
			line += "  %.2f from player" % Vector2(at.x - player.global_position.x, at.z - player.global_position.z).length()
		print(line)
