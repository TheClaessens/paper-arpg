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


func _key(code: Key) -> InputEventKey:
	var key := InputEventKey.new()
	key.physical_keycode = code
	key.pressed = true
	return key


func _click(button: MouseButton, device: int) -> InputEventMouseButton:
	var click := InputEventMouseButton.new()
	click.button_index = button
	click.device = device
	click.pressed = true
	return click


func test_each_binding_presses_its_slot() -> void:
	assert_eq(Player.pressed_slot(_click(MOUSE_BUTTON_LEFT, 0)), 0, "left click: main slot")
	assert_eq(Player.pressed_slot(_click(MOUSE_BUTTON_RIGHT, 0)), 1, "right click")
	assert_eq(Player.pressed_slot(_key(KEY_Q)), 2)
	assert_eq(Player.pressed_slot(_key(KEY_E)), 3)
	assert_eq(Player.pressed_slot(_key(KEY_R)), 4)
	assert_eq(Player.pressed_slot(_key(KEY_W)), -1, "walking presses no slot")


func test_letting_go_of_a_binding_releases_its_slot() -> void:
	var key := _key(KEY_Q)
	key.pressed = false
	assert_eq(Player.released_slot(key), 2)
	assert_eq(Player.released_slot(_key(KEY_Q)), -1, "a press releases nothing")


func test_a_touch_does_not_use_a_slot() -> void:
	# The mouse click Godot makes from every touch.
	assert_eq(Player.pressed_slot(_click(MOUSE_BUTTON_LEFT, InputEvent.DEVICE_ID_EMULATION)), -1)


func test_the_right_stick_aims_apart_from_walking() -> void:
	_tilted_camera()
	player.set_physics_process(true)
	Input.action_press(&"move_up")
	Input.action_press(&"aim_right")
	await wait_physics_frames(2)
	Input.action_release(&"move_up")
	Input.action_release(&"aim_right")
	assert_almost_eq(player.facing, Vector3(1.0, 0.0, 0.0), Vector3.ONE * 0.05, "aims right while walking up")

func test_its_skills_are_the_skill_nodes_it_holds() -> void:
	var titles: Array[String] = []
	for skill in player.skills:
		titles.append(skill.title)
	assert_eq(titles, ["Attack", "Fireball", "Nova", "Mark"] as Array[String])



# A thumb drag on screen becomes an aim on the ground: screen right and screen down are the
# camera's right and back axes on the ground.

func test_a_drag_aims_a_direction_skill_its_full_range() -> void:
	var aim := Player.ground_aim(Vector2(30.0, 0.0), Vector3.RIGHT, Vector3.BACK, 10.0, 100.0, false)
	assert_almost_eq(aim, Vector3(10.0, 0.0, 0.0), Vector3.ONE * 0.001)


func test_a_drag_aims_a_spot_skill_as_far_as_it_goes() -> void:
	var half := Player.ground_aim(Vector2(0.0, 50.0), Vector3.RIGHT, Vector3.BACK, 8.0, 100.0, true)
	assert_almost_eq(half, Vector3(0.0, 0.0, 4.0), Vector3.ONE * 0.001, "half the drag, half the Range")
	var past := Player.ground_aim(Vector2(0.0, 300.0), Vector3.RIGHT, Vector3.BACK, 8.0, 100.0, true)
	assert_almost_eq(past, Vector3(0.0, 0.0, 8.0), Vector3.ONE * 0.001, "never past the Range")
