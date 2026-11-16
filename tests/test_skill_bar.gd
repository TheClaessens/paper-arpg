extends GutTest
## The Skill bar: five Skill slots sharing one Use time. A press uses the slot's Skill, the
## player is then busy for its Use time, and a press near the end of it (from any slot) is kept
## for when it ends. Earlier presses are dropped, and an empty slot does nothing.

var bar: SkillBar
var sword: Skill
var fire: Skill
var used: Array[Skill] = []


func before_each() -> void:
	sword = autofree(Skill.new())
	sword.use_time = 0.4
	fire = autofree(Skill.new())
	fire.use_time = 0.6
	bar = autofree(SkillBar.new())
	bar.buffer = 0.15
	bar.set_skill(0, sword)
	bar.set_skill(1, fire)
	used = []
	bar.used.connect(func(skill: Skill) -> void: used.append(skill))


func test_a_press_uses_the_slots_skill() -> void:
	bar.press(1)
	bar.advance(0.016)
	assert_eq(used, [fire] as Array[Skill])


func test_the_use_time_blocks_every_slot() -> void:
	bar.press(0)
	bar.advance(0.016)
	bar.advance(0.1) # 0.28 s of the sword's use left, outside the buffer
	bar.press(1)
	bar.advance(0.016)
	bar.advance(0.5)
	assert_eq(used, [sword] as Array[Skill], "the Fireball press came too early")


func test_a_late_press_from_another_slot_is_used_when_the_time_ends() -> void:
	bar.press(0)
	bar.advance(0.016)
	bar.advance(0.3) # under 0.1 s left, inside the buffer
	bar.press(1)
	bar.advance(0.016)
	assert_eq(used, [sword] as Array[Skill], "not before the use time ends")
	bar.advance(0.1)
	assert_eq(used, [sword, fire] as Array[Skill])


func test_the_latest_late_press_wins() -> void:
	bar.press(0)
	bar.advance(0.016)
	bar.advance(0.3)
	bar.press(1)
	bar.advance(0.016)
	bar.press(0)
	bar.advance(0.016)
	bar.advance(0.1)
	assert_eq(used, [sword, sword] as Array[Skill])


func test_an_empty_slot_does_nothing() -> void:
	assert_null(bar.skill_in(4))
	bar.press(4)
	bar.advance(0.016)
	bar.advance(1.0)
	assert_eq(used, [] as Array[Skill])


func test_the_same_skill_can_sit_in_two_slots() -> void:
	bar.set_skill(3, fire)
	bar.press(3)
	bar.advance(0.016)
	assert_eq(used, [fire] as Array[Skill])
	assert_eq(bar.skill_in(1), fire, "still in its first slot too")


func test_changing_a_slot_says_so() -> void:
	var changes: Array[int] = []
	bar.changed.connect(func(slot: int, _skill: Skill) -> void: changes.append(slot))
	bar.set_skill(2, sword)
	bar.set_skill(0, null)
	assert_eq(changes, [2, 0] as Array[int])
	assert_null(bar.skill_in(0), "emptied")
