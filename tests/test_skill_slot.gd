extends GutTest
## A Skill slot's timing: a press uses the Skill, the Skill then takes its use time, and a press
## near the end of that time is kept for when it ends. Earlier presses are dropped.

var slot: SkillSlot
var uses := 0


func before_each() -> void:
	var skill: Skill = autofree(Skill.new())
	skill.use_time = 0.4
	slot = autofree(SkillSlot.new())
	slot.skill = skill
	slot.buffer = 0.15
	uses = 0
	slot.used.connect(func(_skill: Skill) -> void: uses += 1)


func test_a_press_uses_the_skill() -> void:
	slot.press()
	slot.advance(0.016)
	assert_eq(uses, 1)


func test_an_early_press_is_dropped() -> void:
	slot.press()
	slot.advance(0.016)
	slot.advance(0.1) # 0.28 s of use time left, outside the buffer
	slot.press()
	slot.advance(0.016)
	slot.advance(0.5)
	assert_eq(uses, 1)


func test_a_late_press_is_used_when_the_time_ends() -> void:
	slot.press()
	slot.advance(0.016)
	slot.advance(0.3) # under 0.1 s left, inside the buffer
	slot.press()
	slot.advance(0.016)
	assert_eq(uses, 1, "not before the use time ends")
	slot.advance(0.1)
	assert_eq(uses, 2)


func test_holding_does_nothing_more() -> void:
	slot.press()
	slot.advance(0.016)
	slot.advance(1.0)
	assert_eq(uses, 1, "no press, no use")
