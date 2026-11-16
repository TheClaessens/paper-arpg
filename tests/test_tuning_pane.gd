extends GutTest
## The `hitfeel` console command, which the TuningPane registers while it is in the tree.

const PaneScene := preload("res://ui/tuning_pane.tscn")

var pane: TuningPane
var feedback: HitFeedback
var attack: Attack
var slot: SkillSlot


func before_each() -> void:
	feedback = HitFeedback.new()
	attack = autofree(Attack.new())
	slot = autofree(SkillSlot.new())
	pane = PaneScene.instantiate()
	pane.hit_feedback = feedback
	pane.attack = attack
	pane.skill_slot = slot
	add_child_autofree(pane)


func test_sets_a_hit_feedback_value() -> void:
	assert_eq(Console.execute("hitfeel knockback 0.5"), "hitfeel knockback 0.5")
	assert_eq(feedback.knockback, 0.5)


func test_sets_attack_and_slot_values() -> void:
	Console.execute("hitfeel attack_arc 90")
	Console.execute("hitfeel buffer 0.1")
	assert_eq(attack.arc, 90.0)
	assert_eq(slot.buffer, 0.1)


func test_rejects_unknown_names_and_non_numbers() -> void:
	assert_string_starts_with(Console.execute("hitfeel wobble 1"), "Unknown value 'wobble'")
	assert_eq(Console.execute("hitfeel knockback lots"), "Usage: hitfeel [<name> <value>]")
	assert_eq(feedback.knockback, 0.8, "unchanged")


func test_alone_it_toggles_the_pane_and_lists_every_value() -> void:
	assert_false(pane.visible)
	var listing := Console.execute("hitfeel")
	assert_true(pane.visible)
	assert_string_contains(listing, "hitfeel hitstop 0.06")
	assert_string_contains(listing, "hitfeel attack_reach 1.6")
	Console.execute("hitfeel")
	assert_false(pane.visible)
