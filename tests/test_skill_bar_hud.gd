extends GutTest
## Touch on the Skill bar HUD: a tap activates a Skill auto-aimed, a drag from where the thumb landed
## aims it by hand, and dragging back onto the slot cancels it. Wherever on the button the thumb
## lands, a small wobble is still a tap.

const HudScene := preload("res://ui/skill_bar_hud.tscn")
const PlayerScene := preload("res://characters/player/player.tscn")

var hud: SkillBarHud
var player: Player
var button: SkillSlotButton
var aims: Array[Vector3] = []


func before_each() -> void:
	var camera := Camera3D.new() # aim_from_drag reads screen axes from it
	camera.position = Vector3(0.0, 10.0, 6.0)
	camera.rotation_degrees.x = -60.0
	add_child_autofree(camera)
	camera.make_current()
	player = PlayerScene.instantiate()
	add_child_autofree(player)
	player.set_physics_process(false) # after add_child, or _ready turns it back on
	player.skill_bar.set_skill(1, player.get_node("Fireball") as Skill)
	hud = HudScene.instantiate()
	hud.player = player
	add_child_autofree(hud)
	button = hud.get_node("Slot1")
	aims = []
	player.skill_bar.activation_requested.connect(func(_slot: int, aim: Vector3) -> void: aims.append(aim))


## `seconds` pass: the player's Skills cool down (as each does in its own physics step), then
## its Skill bar works through its presses and holds.
func _elapse(seconds: float) -> void:
	for skill in player.skills:
		skill.cool_down(seconds)
	player.skill_bar.advance()


## A touch that lands at `from` (relative to the button's centre), moves through `path`, lifts at
## the last point; then one physics step.
func _touch(from: Vector2, path: Array[Vector2]) -> void:
	var centre := button.centre()
	button.touch_started.emit(centre + from)
	for at in path:
		button.touch_moved.emit(centre + at)
	button.touch_ended.emit(centre + (path[-1] if path else from))
	_elapse(0.016)


func test_an_off_centre_tap_with_a_wobble_is_still_a_tap() -> void:
	_touch(Vector2(20.0, 0.0), [Vector2(23.0, 2.0)] as Array[Vector2])
	assert_eq(aims, [SkillBar.NO_AIM] as Array[Vector3], "auto-aimed")


func test_a_drag_aims_by_hand() -> void:
	_touch(Vector2(20.0, 0.0), [Vector2(-40.0, 0.0)] as Array[Vector2])
	assert_eq(aims.size(), 1)
	assert_true(aims[0].is_finite(), "aimed by hand")


func test_dragging_back_onto_the_slot_cancels() -> void:
	_touch(Vector2.ZERO, [Vector2(-120.0, 0.0), Vector2(2.0, 0.0)] as Array[Vector2])
	assert_eq(aims, [] as Array[Vector3])


func test_the_touch_command_taps_or_drags_a_slot() -> void:
	assert_eq(Console.execute("touch 2"), "touch 2")
	_elapse(0.016)
	_elapse(5.0) # past Fireball's cooldown
	assert_eq(Console.execute("touch 2 -40 0"), "touch 2 by -40 0")
	_elapse(0.016)
	assert_eq(aims.size(), 2)
	assert_false(aims[0].is_finite(), "a tap: auto-aimed")
	assert_true(aims[1].is_finite(), "a drag: aimed by hand")


func test_a_second_finger_on_another_slot_leaves_a_hold_alone() -> void:
	var main: SkillSlotButton = hud.get_node("Slot0") # the Attack: repeats while held
	main.touch_started.emit(main.centre())
	button.touch_started.emit(button.centre()) # a second finger lands on the Fireball
	main.touch_moved.emit(main.centre() + Vector2(2.0, 0.0)) # the first only wobbles
	_elapse(0.016)
	_elapse(0.4) # the Attack's Cooldown ends: the hold repeats it
	assert_eq(aims, [SkillBar.NO_AIM, SkillBar.NO_AIM] as Array[Vector3], "still auto-aimed, not steered")
