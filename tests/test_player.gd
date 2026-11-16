extends GutTest
## The `tp` console command, which the Player registers while it is in the tree.

const PlayerScene := preload("res://characters/player/player.tscn")

var player: Player


func before_each() -> void:
	player = PlayerScene.instantiate()
	player.set_physics_process(false) # no camera here to read input against
	add_child_autofree(player)


func test_tp_moves_the_player() -> void:
	Console.execute("tp 3 -4.5")
	assert_eq(player.global_position, Vector3(3.0, 0.0, -4.5))


func test_tp_needs_two_numbers() -> void:
	assert_eq(Console.execute("tp 3"), "Usage: tp <x> <z>")
	assert_eq(Console.execute("tp a b"), "Usage: tp <x> <z>")
	assert_eq(player.global_position, Vector3.ZERO)


func test_tp_leaves_and_returns_with_the_player() -> void:
	remove_child(player)
	assert_string_starts_with(Console.execute("tp 1 1"), "Unknown command")
	add_child(player)
	assert_eq(Console.execute("tp 1 1"), "tp 1 1", "re-entering registers it again")


func test_facing_toward_a_point_lies_on_the_ground() -> void:
	var facing := Player.facing_toward(Vector3(1.0, 0.0, 1.0), Vector3(1.0, 0.5, 4.0), Vector3.RIGHT)
	assert_almost_eq(facing, Vector3(0.0, 0.0, 1.0), Vector3.ONE * 0.001)


func test_facing_toward_the_spot_underfoot_keeps_the_facing() -> void:
	var facing := Player.facing_toward(Vector3(1.0, 0.0, 1.0), Vector3(1.0, 0.3, 1.0), Vector3.LEFT)
	assert_eq(facing, Vector3.LEFT)


func test_facing_follows_the_stick_and_stays_when_let_go() -> void:
	var camera := Camera3D.new() # unrotated: screen right is +X, screen up is -Z
	add_child_autofree(camera)
	camera.make_current()
	player.set_physics_process(true)
	Input.action_press(&"move_up")
	await wait_physics_frames(2)
	assert_almost_eq(player.facing, Vector3(0.0, 0.0, -1.0), Vector3.ONE * 0.001)
	Input.action_release(&"move_up")
	await wait_physics_frames(2)
	assert_almost_eq(player.facing, Vector3(0.0, 0.0, -1.0), Vector3.ONE * 0.001, "let go: Facing stays")


func test_the_cursor_leads_facing_while_the_keys_walk() -> void:
	var camera := Camera3D.new() # tilted down like the game's: up the screen is -Z on the ground
	camera.position = Vector3(0.0, 10.0, 6.0)
	camera.rotation_degrees.x = -60.0
	add_child_autofree(camera)
	camera.make_current()
	player.set_physics_process(true)
	var motion := InputEventMouseMotion.new()
	motion.position = camera.unproject_position(Vector3(3.0, 0.0, 0.0)) # cursor right of the player
	get_viewport().push_input(motion, true)
	Input.action_press(&"move_up")
	await wait_physics_frames(2)
	Input.action_release(&"move_up")
	assert_almost_eq(player.facing, Vector3(1.0, 0.0, 0.0), Vector3.ONE * 0.05)


func _tilted_camera() -> Camera3D:
	var camera := Camera3D.new() # tilted down like the game's: up the screen is -Z on the ground
	camera.position = Vector3(0.0, 10.0, 6.0)
	camera.rotation_degrees.x = -60.0
	add_child_autofree(camera)
	camera.make_current()
	return camera


func test_a_touch_does_not_use_the_skill_slot() -> void:
	var tap := InputEventMouseButton.new() # the mouse click Godot makes from every touch
	tap.device = InputEvent.DEVICE_ID_EMULATION
	tap.button_index = MOUSE_BUTTON_LEFT
	tap.pressed = true
	assert_false(Player.uses_skill_slot(tap), "a touch is not a click")
	var click := tap.duplicate() as InputEventMouseButton
	click.device = 0
	assert_true(Player.uses_skill_slot(click), "a real click is")


func test_the_right_stick_leaves_the_cursor_in_charge() -> void:
	var camera := _tilted_camera()
	player.set_physics_process(true)
	var motion := InputEventMouseMotion.new()
	motion.position = camera.unproject_position(Vector3(3.0, 0.0, 0.0)) # cursor right of the player
	get_viewport().push_input(motion, true)
	var right_stick := InputEventJoypadMotion.new()
	right_stick.axis = JOY_AXIS_RIGHT_X
	right_stick.axis_value = 1.0
	get_viewport().push_input(right_stick, true)
	Input.action_press(&"move_up")
	await wait_physics_frames(2)
	Input.action_release(&"move_up")
	assert_almost_eq(player.facing, Vector3(1.0, 0.0, 0.0), Vector3.ONE * 0.05)
