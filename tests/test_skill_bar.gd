extends GutTest
## The Skill bar: five Skill slots, each Skill limited only by its own Cooldown. Presses on
## ready Skills ask for them in press order on the next physics frame, and an empty slot does
## nothing. Here a stand-in for the Character owns the Skills, and the test answers each request by
## activating the Skill.

var bar: SkillBar
var sword: Skill
var fire: Skill
var activated: Array[Skill] = []
var aims: Array[Vector3] = []


func before_each() -> void:
	var character: Character = autofree(Character.new()) # a stand-in, kept out of the tree
	sword = autofree(Skill.new())
	sword.character = character
	sword.cooldown = 0.4
	sword.aim_mode = AimMode.new()
	fire = autofree(Skill.new())
	fire.character = character
	fire.cooldown = 0.6
	fire.aim_mode = AimMode.new()
	bar = autofree(SkillBar.new())
	bar.set_skill(0, sword)
	bar.set_skill(1, fire)
	activated = []
	aims = []
	bar.activation_requested.connect(func(slot: int, aim: Vector3) -> void:
		var skill := bar.skill_in(slot)
		if skill.try_activate(aim, []):
			activated.append(skill)
			aims.append(aim))


## `seconds` pass: the Skills cool down (as each does in its own physics step), then the bar
## works through its presses and holds.
func _elapse(seconds: float) -> void:
	sword.cool_down(seconds)
	fire.cool_down(seconds)
	bar.advance()


func test_a_press_activates_the_slots_skill() -> void:
	bar.press(1)
	_elapse(0.016)
	assert_eq(activated, [fire] as Array[Skill])


func test_two_skills_pressed_in_one_frame_both_activate_in_press_order() -> void:
	bar.press(1)
	bar.press(0)
	_elapse(0.016)
	assert_eq(activated, [fire, sword] as Array[Skill])


func test_a_skill_pressed_twice_in_one_frame_activates_once() -> void:
	bar.set_skill(3, sword)
	bar.press(0)
	bar.press(3)
	_elapse(0.016)
	assert_eq(activated, [sword] as Array[Skill], "the second press finds it on Cooldown")


func test_an_empty_slot_does_nothing() -> void:
	assert_null(bar.skill_in(4))
	bar.press(4)
	_elapse(0.016)
	_elapse(1.0)
	assert_eq(activated, [] as Array[Skill])


func test_the_same_skill_can_sit_in_two_slots() -> void:
	bar.set_skill(3, fire)
	bar.press(3)
	_elapse(0.016)
	assert_eq(activated, [fire] as Array[Skill])
	assert_eq(bar.skill_in(1), fire, "still in its first slot too")


func test_changing_a_slot_says_so() -> void:
	var changes: Array[int] = []
	bar.changed.connect(func(slot: int, _skill: Skill) -> void: changes.append(slot))
	bar.set_skill(2, sword)
	bar.set_skill(0, null)
	assert_eq(changes, [2, 0] as Array[int])
	assert_null(bar.skill_in(0), "emptied")


func test_a_skill_without_an_aim_mode_is_refused() -> void:
	var bare: Skill = autofree(Skill.new())
	bar.set_skill(2, bare)
	assert_engine_error("has no Aim mode")


# Cooldowns: a Skill's own clock, started by an activation. While it runs, the Skill can't be
# activated from any slot it sits in; a press is ignored, not kept.

func test_a_cooling_skill_ignores_presses_in_every_slot() -> void:
	fire.cooldown = 4.0
	bar.set_skill(3, fire)
	bar.press(1)
	_elapse(0.016)
	_elapse(fire.cooldown - 0.05) # just before it is ready
	bar.press(3)
	_elapse(0.016)
	_elapse(1.0) # cooled down now, but the press was not kept
	assert_eq(activated, [fire] as Array[Skill])
	bar.press(3)
	_elapse(0.016)
	assert_eq(activated, [fire, fire] as Array[Skill])


func test_another_skill_works_while_one_cools() -> void:
	fire.cooldown = 4.0
	bar.press(1)
	_elapse(0.016)
	bar.press(0)
	_elapse(0.016)
	assert_eq(activated, [fire, sword] as Array[Skill])


# Drag to aim: a press can carry its own aim, which reaches the request as it was given.

func test_a_press_carries_its_aim_through() -> void:
	bar.press(1, Vector3(2.0, 0.0, 1.0))
	_elapse(0.016)
	assert_eq(aims, [Vector3(2.0, 0.0, 1.0)] as Array[Vector3])


func test_a_plain_press_leaves_the_aim_to_the_character() -> void:
	bar.press(1)
	_elapse(0.016)
	assert_eq(aims, [SkillBar.NO_AIM] as Array[Vector3])


# Holding: while a slot is held, a Skill that repeats while held is activated again the moment
# its Cooldown ends, aimed where the hold steers it.

func test_holding_repeats_a_repeating_skill() -> void:
	sword.aim_mode = preload("res://skills/aim_modes/steer.tres")
	bar.press(0)
	bar.set_held(0, true)
	_elapse(0.016)
	_elapse(0.4)
	_elapse(0.4)
	assert_eq(activated.size(), 3, "each time its Cooldown ends")
	bar.set_held(0, false)
	_elapse(1.0)
	assert_eq(activated.size(), 3, "letting go stops it")


func test_holding_does_not_repeat_other_skills() -> void:
	bar.press(1)
	bar.set_held(1, true)
	_elapse(0.016)
	_elapse(2.0)
	assert_eq(activated, [fire] as Array[Skill])


func test_a_hold_steers_the_next_activations() -> void:
	sword.aim_mode = preload("res://skills/aim_modes/steer.tres")
	bar.press(0)
	bar.set_held(0, true)
	_elapse(0.016)
	bar.set_held(0, true, Vector3(0.0, 0.0, 2.0))
	_elapse(0.4)
	assert_eq(aims, [SkillBar.NO_AIM, Vector3(0.0, 0.0, 2.0)] as Array[Vector3])


func test_pausing_lets_go() -> void:
	sword.aim_mode = preload("res://skills/aim_modes/steer.tres")
	bar.press(0)
	bar.set_held(0, true)
	_elapse(0.016)
	bar.propagate_notification(Node.NOTIFICATION_PAUSED) # the release may never arrive while paused
	_elapse(1.0)
	assert_eq(activated.size(), 1)


func test_losing_focus_lets_go() -> void:
	sword.aim_mode = preload("res://skills/aim_modes/steer.tres")
	bar.press(0)
	bar.set_held(0, true)
	_elapse(0.016)
	bar.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT) # the engine releases keys unheard
	_elapse(1.0)
	assert_eq(activated.size(), 1)
