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


func test_after_a_use_the_player_faces_the_aim_for_a_moment() -> void:
	_tilted_camera()
	player.set_physics_process(true)
	Input.action_press(&"move_up")
	player.skill_bar.press(0, Vector3(3.0, 0.0, 0.0)) # the Attack, aimed to the right
	await wait_physics_frames(4)
	assert_almost_eq(player.facing, Vector3(1.0, 0.0, 0.0), Vector3.ONE * 0.05, "faces the aim while walking up")
	await wait_seconds(0.5)
	Input.action_release(&"move_up")
	assert_almost_eq(player.facing, Vector3(0.0, 0.0, -1.0), Vector3.ONE * 0.05, "then the walk takes Facing back")


# The `bar` and `use` console commands, for driving Skills from tools/screenshot.gd and simulate.gd.

func test_bar_puts_a_skill_in_a_slot_and_empties_it() -> void:
	assert_eq(Console.execute("bar 2 fireball"), "bar 2 Fireball")
	assert_eq(player.skill_bar.skill_in(1), player.get_node("Fireball"))
	assert_eq(Console.execute("bar 2 empty"), "bar 2 empty")
	assert_null(player.skill_bar.skill_in(1))


func test_bar_rejects_bad_slots_and_unknown_skills() -> void:
	assert_eq(Console.execute("bar 6 attack"), "Usage: bar <1-5> <skill|empty>")
	assert_string_starts_with(Console.execute("bar 2 hammer"), "Unknown Skill 'hammer'")


func test_use_presses_a_slot_with_or_without_an_aim() -> void:
	var aims: Array[Vector3] = []
	player.skill_bar.used.connect(func(_skill: Skill, aim: Vector3) -> void: aims.append(aim))
	assert_eq(Console.execute("use 1 3 -1"), "use 1 at 3 -1")
	player.skill_bar.advance(0.016)
	player.skill_bar.advance(1.0)
	assert_eq(Console.execute("use 1"), "use 1")
	player.skill_bar.advance(0.016)
	assert_eq(aims, [Vector3(3.0, 0.0, -1.0), SkillBar.NO_AIM] as Array[Vector3])
	assert_eq(Console.execute("use x"), "Usage: use <1-5> [<x> <z>]")


# The Controls' signals reach the Skill bar: a press uses the slot and holds it, and letting go
# stops the repeats.

func test_the_controls_press_hold_and_let_go_of_a_slot() -> void:
	var used: Array[Skill] = []
	player.skill_bar.used.connect(func(skill: Skill, _aim: Vector3) -> void: used.append(skill))
	var controls: Controls = player.get_node("Controls")
	controls.slot_pressed.emit(0) # the Attack: repeats while held
	player.skill_bar.advance(0.016)
	player.skill_bar.advance(1.0) # past its Use time
	assert_eq(used.size(), 2, "pressed, then repeated while held")
	controls.slot_released.emit(0)
	player.skill_bar.advance(1.0)
	assert_eq(used.size(), 2, "let go")
