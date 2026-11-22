extends GutTest
## The Player: the `tp` console command it registers while in the tree, and Auto-aim.

const PlayerScene := preload("res://characters/player/player.tscn")
const ZombieScene := preload("res://characters/enemy/zombie.tscn")

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
	assert_eq(titles, ["Attack", "Fireball"] as Array[String])



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


func test_after_an_activation_the_player_faces_the_aim_for_a_moment() -> void:
	_tilted_camera()
	player.set_physics_process(true)
	Input.action_press(&"move_up")
	player.skill_bar.press(0, Vector3(3.0, 0.0, 0.0)) # the Attack, aimed to the right
	await wait_physics_frames(4)
	assert_almost_eq(player.facing, Vector3(1.0, 0.0, 0.0), Vector3.ONE * 0.05, "faces the aim while walking up")
	await wait_seconds(0.5)
	Input.action_release(&"move_up")
	assert_almost_eq(player.facing, Vector3(0.0, 0.0, -1.0), Vector3.ONE * 0.05, "then the walk takes Facing back")


# The `bar` and `activate` console commands, for driving Skills from tools/screenshot.gd and simulate.gd.

func test_bar_puts_a_skill_in_a_slot_and_empties_it() -> void:
	assert_eq(Console.execute("bar 2 fireball"), "bar 2 Fireball")
	assert_eq(player.skill_bar.skill_in(1), player.get_node("Fireball"))
	assert_eq(Console.execute("bar 2 empty"), "bar 2 empty")
	assert_null(player.skill_bar.skill_in(1))


func test_bar_rejects_bad_slots_and_unknown_skills() -> void:
	assert_eq(Console.execute("bar 6 attack"), "Usage: bar <1-5> <skill|empty>")
	assert_string_starts_with(Console.execute("bar 2 hammer"), "Unknown Skill 'hammer'")


## `seconds` pass: the player's Skills cool down (as each does in its own physics step), then
## its Skill bar works through its presses and holds.
func _elapse(seconds: float) -> void:
	for skill in player.skills:
		skill.cool_down(seconds)
	player.skill_bar.advance()


func test_activate_presses_a_slot_with_or_without_an_aim() -> void:
	var aims: Array[Vector3] = []
	player.skill_bar.activation_requested.connect(func(_slot: int, aim: Vector3) -> void: aims.append(aim))
	assert_eq(Console.execute("activate 1 3 -1"), "activate 1 at 3 -1")
	_elapse(0.016)
	_elapse(1.0)
	assert_eq(Console.execute("activate 1"), "activate 1")
	_elapse(0.016)
	assert_eq(aims, [Vector3(3.0, 0.0, -1.0), SkillBar.NO_AIM] as Array[Vector3])
	assert_eq(Console.execute("activate x"), "Usage: activate <1-5> [<x> <z>]")


# The Controls' signals reach the Skill bar: a press activates the slot's Skill and holds the
# slot, and letting go stops the repeats.

func test_the_controls_press_hold_and_let_go_of_a_slot() -> void:
	var activated: Array[int] = []
	player.skill_activated.connect(func(slot: int) -> void: activated.append(slot))
	var controls: Controls = player.get_node("Controls")
	controls.slot_pressed.emit(0) # the Attack: repeats while held
	_elapse(0.016)
	_elapse(0.4) # its Cooldown ends
	assert_eq(activated, [0, 0] as Array[int], "pressed, then repeated while held")
	controls.slot_released.emit(0)
	_elapse(1.0)
	assert_eq(activated.size(), 2, "let go")


func test_a_requested_skill_is_activated_with_the_players_modifiers() -> void:
	var fireball := _fireball()
	player.skill_bar.set_skill(1, fireball)
	Console.execute("modifier spell-cooldown on")
	player.skill_bar.press(1, Vector3.RIGHT)
	_elapse(0.016)
	assert_eq(fireball.cooldown_left, 2.0, "Spells have 50% reduced cooldown")


# The `modifier` command switches the proof Modifiers on the player, for trying them in game.

func _fireball() -> Skill:
	for skill in player.skills:
		if skill.title == "Fireball":
			return skill
	return null


func test_modifier_lists_the_proof_modifiers_and_why_each_applies() -> void:
	assert_eq(Console.execute("modifier"), "\n".join([
		"spell-cooldown: off (Spells have 50% reduced cooldown)",
		"pierce: off (Projectiles pierce an Enemy)",
	]))
	Console.execute("modifier spell-cooldown on")
	Console.execute("modifier pierce on")
	assert_eq(Console.execute("modifier"), "\n".join([
		"spell-cooldown: on (Spells have 50% reduced cooldown)",
		"pierce: on (Projectiles pierce an Enemy)",
		"Attack › Spells have 50% reduced cooldown: missed, not Spell",
		"Attack › Projectiles pierce an Enemy: missed, not Projectile",
		"Fireball › Spells have 50% reduced cooldown: applied",
		"Fireball › Projectiles pierce an Enemy: applied, adds Pierce",
	]))


func test_modifier_switches_a_proof_modifier_on_and_off() -> void:
	assert_eq(Console.execute("modifier spell-cooldown on"), "modifier spell-cooldown on")
	assert_eq(_fireball().snapshot(player.modifiers).number(Skill.COOLDOWN), 2.0)
	Console.execute("modifier spell-cooldown on")
	assert_eq(player.modifiers.size(), 1, "switching on twice adds it once")
	assert_eq(Console.execute("modifier spell-cooldown off"), "modifier spell-cooldown off")
	assert_eq(_fireball().snapshot(player.modifiers).number(Skill.COOLDOWN), 4.0)
	assert_eq(Console.execute("modifier pierce on"), "modifier pierce on")
	assert_has(_fireball().snapshot(player.modifiers).tags, &"Pierce")
	Console.execute("modifier pierce off")
	assert_does_not_have(_fireball().snapshot(player.modifiers).tags, &"Pierce")


func test_modifier_needs_a_known_name_and_on_or_off() -> void:
	assert_eq(Console.execute("modifier chain on"), "Usage: modifier [<spell-cooldown|pierce> on|off]")
	assert_eq(Console.execute("modifier spell-cooldown maybe"), "Usage: modifier [<spell-cooldown|pierce> on|off]")
	assert_eq(player.modifiers.size(), 0)


# Auto-aim: the nearest Enemy within 60° of Facing, no farther than the Range; with none, along
# Facing. Its caller hands it the Enemies within Range.

func test_auto_aim_picks_the_nearest_enemy_near_facing() -> void:
	var near := Vector3(2.0, 0.0, 0.5)
	var far := Vector3(4.0, 0.0, 0.0)
	assert_eq(Player.auto_aim(Vector3.RIGHT, 5.0, [far, near]), near)


func test_auto_aim_ignores_enemies_behind_or_wide_of_facing() -> void:
	var behind := Vector3(-1.0, 0.0, 0.0)
	var wide := Vector3(1.0, 0.0, 2.0) # 63° off Facing
	assert_eq(Player.auto_aim(Vector3.RIGHT, 5.0, [behind, wide]), Vector3.RIGHT * 5.0, "along Facing, as far as the Range")


func test_auto_aim_ignores_height() -> void:
	assert_eq(Player.auto_aim(Vector3.RIGHT, 5.0, [Vector3(2.0, 0.5, 0.0)]), Vector3(2.0, 0.0, 0.0))


func test_auto_aim_at_a_body_in_range_goes_as_far_as_the_range() -> void:
	var attack: Skill = player.get_node("Attack") # Range 1.6, which a 32-bit length can't hold exactly
	player.set_physics_process(false) # off once in the tree, or _ready turns it back on: the player stays put
	player.facing = Vector3.RIGHT
	var zombie: Enemy = ZombieScene.instantiate()
	add_child_autofree(zombie)
	zombie.global_position = Vector3(1.5, 0.0, 0.7) # 25° off Facing, centre 1.66 away, body inside the Range
	await wait_physics_frames(2)
	var aim := player._aim_for(attack)
	assert_almost_eq(aim, Vector3(1.5, 0.0, 0.7).normalized() * 1.6, Vector3.ONE * 0.001, "at the Enemy, not along Facing")
