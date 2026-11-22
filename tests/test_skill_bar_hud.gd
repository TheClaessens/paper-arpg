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
	player.skill_bar.set_skill(1, player.get_node("Skills/Fireball") as Skill)
	hud = HudScene.instantiate()
	hud.player = player
	add_child_autofree(hud)
	button = hud.get_node("Slot1")
	aims = []
	player.skill_bar.activation_requested.connect(func(_slot: int, aim: Vector3) -> void: aims.append(aim))


## The balls a Fireball threw live beside the player, not under it: free them, or they fly on into
## the next test.
func after_each() -> void:
	for ball in find_children("*", "Projectile", false, false):
		ball.free()


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


func _push_touch(at: Vector2, pressed: bool, canceled := false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = at
	event.pressed = pressed
	event.canceled = canceled
	get_viewport().push_input(event, true)


func _push_drag(to: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = 0
	event.position = to
	get_viewport().push_input(event, true)


func _aim_marker_shows() -> bool:
	return (player.get_node("AimMarker") as Node3D).visible


func test_a_touch_the_system_cancels_mid_aim_activates_nothing() -> void:
	_push_touch(button.centre(), true)
	_push_drag(button.centre() + Vector2(-120.0, 0.0))
	assert_true(_aim_marker_shows(), "control: the drag is being aimed")
	_push_touch(Vector2(-1, -1), false) # how iOS reports a touch the system cancels
	_elapse(0.016)
	assert_eq(aims, [] as Array[Vector3])
	assert_false(_aim_marker_shows())


func test_losing_focus_lets_go_of_a_held_thumb() -> void:
	var main: SkillSlotButton = hud.get_node("Slot0") # the Attack: repeats while held
	_push_touch(main.centre(), true)
	_elapse(0.016)
	assert_eq(aims.size(), 1, "control: the press activated it")
	hud.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT) # to the HUD alone, not the Skill bar
	_elapse(0.5)
	assert_eq(aims.size(), 1)


func test_a_lift_during_a_pause_activates_nothing() -> void:
	button.touch_started.emit(button.centre())
	button.touch_moved.emit(button.centre() + Vector2(-120.0, 0.0))
	assert_true(_aim_marker_shows(), "control: the drag is being aimed")
	get_tree().paused = true
	button.touch_ended.emit(button.centre() + Vector2(-120.0, 0.0))
	get_tree().paused = false
	_elapse(0.016)
	assert_eq(aims, [] as Array[Vector3])


func test_a_skill_changed_under_an_aim_activates_nothing() -> void:
	button.touch_started.emit(button.centre())
	button.touch_moved.emit(button.centre() + Vector2(-120.0, 0.0))
	player.skill_bar.set_skill(1, player.skill_bar.skill_in(0)) # the Attack, as the Skill drawer would
	assert_false(_aim_marker_shows(), "hidden as the Skill changes, before the thumb lifts")
	button.touch_ended.emit(button.centre() + Vector2(-120.0, 0.0))
	_elapse(0.016)
	assert_eq(aims, [] as Array[Vector3])
	assert_false(_aim_marker_shows())


func test_a_slot_emptied_under_an_aim_activates_nothing() -> void:
	button.touch_started.emit(button.centre())
	button.touch_moved.emit(button.centre() + Vector2(-120.0, 0.0))
	player.skill_bar.set_skill(1, null)
	button.touch_moved.emit(button.centre() + Vector2(-130.0, 0.0))
	button.touch_ended.emit(button.centre() + Vector2(-130.0, 0.0))
	_elapse(0.016)
	assert_eq(aims, [] as Array[Vector3])


func test_a_skill_changed_under_a_held_thumb_ends_the_hold() -> void:
	var main: SkillSlotButton = hud.get_node("Slot0") # the Attack: repeats while held
	main.touch_started.emit(main.centre())
	_elapse(0.016)
	assert_eq(aims.size(), 1, "control: the press activated it")
	player.skill_bar.set_skill(0, player.skill_bar.skill_in(0)) # chosen again in the Skill drawer: still a change
	_elapse(0.5) # the Attack's Cooldown ends: a hold would repeat it
	assert_eq(aims.size(), 1, "the hold ended")


# One thumb per slot: each slot's hold and aim belong to the thumb that landed on it.

func test_each_lift_ends_its_own_hold() -> void:
	player.skill_bar.set_skill(2, player.skill_bar.skill_in(0)) # the Attack also in slot 2
	var slots: Array[int] = []
	player.skill_bar.activation_requested.connect(func(slot: int, _aim: Vector3) -> void: slots.append(slot))
	var main: SkillSlotButton = hud.get_node("Slot0")
	var also: SkillSlotButton = hud.get_node("Slot2")
	main.touch_started.emit(main.centre())
	also.touch_started.emit(also.centre()) # a second thumb holds the Attack's other slot
	_elapse(0.016)
	main.touch_ended.emit(main.centre())
	also.touch_ended.emit(also.centre())
	var before := slots.size()
	_elapse(0.5)
	_elapse(0.5)
	assert_eq(slots.slice(before), [] as Array[int], "no activation after both lifts, from any slot")


func test_a_second_aiming_thumb_is_ignored() -> void:
	player.skill_bar.set_skill(2, player.get_node("Skills/Fireball") as Skill) # Fireball also in slot 2
	var slots: Array[int] = []
	player.skill_bar.activation_requested.connect(func(slot: int, _aim: Vector3) -> void: slots.append(slot))
	var also: SkillSlotButton = hud.get_node("Slot2")
	var aimed_to := button.centre() + Vector2(60.0, 0.0)
	button.touch_started.emit(button.centre())
	button.touch_moved.emit(aimed_to)
	also.touch_started.emit(also.centre()) # a second thumb taps the other slot
	also.touch_ended.emit(also.centre())
	_elapse(0.016)
	assert_true(_aim_marker_shows(), "the first thumb keeps the aim")
	assert_eq(slots, [] as Array[int], "nothing activated yet")
	button.touch_ended.emit(aimed_to)
	_elapse(0.016)
	assert_eq(slots, [1] as Array[int], "the first thumb's lift activates its own slot")
	assert_almost_eq(aims[0], Vector3(10.0, 0.0, 0.0), Vector3.ONE * 0.001, "10 units to screen right: Fireball's Range along the drag")


func test_a_drag_back_to_where_it_began_is_a_tap() -> void:
	_touch(Vector2.ZERO, [Vector2(30.0, 0.0), Vector2.ZERO] as Array[Vector2])
	assert_eq(aims, [SkillBar.NO_AIM] as Array[Vector3], "auto-aimed, as a tap is")


func test_a_drag_off_the_slot_and_back_to_where_it_began_cancels() -> void:
	_touch(Vector2.ZERO, [Vector2(120.0, 0.0), Vector2.ZERO] as Array[Vector2])
	assert_eq(aims, [] as Array[Vector3], "back on the slot after leaving it: cancelled")
