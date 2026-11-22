extends GutTest
## Health lies between 0 and its maximum: Damage lowers it, healing raises it, both clamped, and
## Damage or healing of 0 or less leaves it alone. At 0 it dies, once, and then ignores Damage
## and healing.

var health: Health


func before_each() -> void:
	health = Health.new()
	health.max_health = 50.0
	add_child_autofree(health)
	watch_signals(health)


func test_starts_at_its_maximum() -> void:
	assert_eq(health.current, 50.0)


func test_damage_lowers_it_and_reports_the_change() -> void:
	health.damage(10.0)
	assert_eq(health.current, 40.0)
	assert_signal_emitted_with_parameters(health, "changed", [40.0, 50.0])


func test_heal_raises_it_no_higher_than_its_maximum() -> void:
	health.damage(10.0)
	health.heal(25.0)
	assert_eq(health.current, 50.0)
	assert_signal_emitted_with_parameters(health, "changed", [50.0, 50.0])


func test_nothing_changes_nothing_is_reported() -> void:
	health.damage(0.0)
	health.heal(5.0) # already full
	assert_eq(health.current, 50.0)
	assert_signal_not_emitted(health, "changed")


func test_dies_once_at_the_hit_that_reaches_0() -> void:
	health.damage(30.0)
	assert_signal_not_emitted(health, "died")
	health.damage(30.0)
	assert_eq(health.current, 0.0, "no lower than 0")
	assert_signal_emit_count(health, "died", 1)
	assert_signal_emit_count(health, "changed", 2)


func test_once_dead_it_ignores_damage_and_healing() -> void:
	health.damage(50.0)
	health.heal(20.0)
	health.damage(5.0)
	assert_eq(health.current, 0.0)
	assert_signal_emit_count(health, "died", 1)
	assert_signal_emit_count(health, "changed", 1)


func test_negative_damage_does_not_heal() -> void:
	health.damage(10.0)
	health.damage(-5.0)
	assert_eq(health.current, 40.0)
	assert_signal_emit_count(health, "changed", 1)


func test_negative_healing_does_not_hurt() -> void:
	health.damage(10.0)
	health.heal(-50.0)
	assert_eq(health.current, 40.0)
	assert_false(health.is_dead())
