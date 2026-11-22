extends GutTest
## A Skill: it warns without a Cooldown, try_activate() is the one way to set it off, and its
## numbers are what Modifiers change. Landing its Hit is test_hit.gd's.

var skill: Skill


func before_each() -> void:
	skill = Skill.new()
	add_child_autofree(skill)


# Every Skill needs a Cooldown: it is the only thing that limits how often a Skill is activated.

func test_a_skill_without_a_cooldown_warns() -> void:
	skill.cooldown = 0.0
	assert_eq(skill._get_configuration_warnings().size(), 1)
	skill.cooldown = 0.4
	assert_eq(skill._get_configuration_warnings().size(), 0)


# Activating: try_activate() is the one way to set a Skill off. It makes the activation's
# Snapshot, starts the Snapshot's Cooldown, never shorter than Skill.SHORTEST_COOLDOWN, and then
# does what the Skill does.

## A Skill that only records the Snapshot of each activation.
class RecordingSkill extends Skill:
	var snapshots: Array[Snapshot] = []

	func _activate(snapshot: Snapshot, _aim: Vector3) -> void:
		snapshots.append(snapshot)


## A Skill script with a _physics_process of its own, that doesn't call super().
class OwnPhysicsSkill extends Skill:
	var frames := 0

	func _physics_process(_delta: float) -> void:
		frames += 1


func _recording(seconds: float, skill_tags: Array[StringName]) -> RecordingSkill:
	var recording := RecordingSkill.new()
	recording.cooldown = seconds
	recording.tags = skill_tags
	recording.character = autofree(Character.new()) # a stand-in: this Skill never reaches its Character
	add_child_autofree(recording)
	return recording


func test_activating_starts_the_cooldown_and_a_cooling_skill_does_not_activate() -> void:
	var recording := _recording(1.0, [])
	assert_true(recording.try_activate(Vector3.RIGHT, []))
	assert_false(recording.try_activate(Vector3.RIGHT, []), "cooling down")
	assert_eq(recording.snapshots.size(), 1)
	assert_eq(recording.cooldown_left, 1.0)


func test_the_cooldown_is_the_snapshots() -> void:
	var recording := _recording(4.0, [&"Spell"])
	recording.try_activate(Vector3.RIGHT, [preload("res://skills/modifiers/spell_cooldown.tres")])
	assert_eq(recording.cooldown_left, 2.0, "Spells have 50% reduced cooldown")
	assert_eq(recording.snapshots[0].number(Skill.COOLDOWN), 2.0, "the Skill got the same Snapshot")


func test_no_cooldown_runs_shorter_than_the_shortest() -> void:
	var recording := _recording(0.4, [])
	var change := NumberChange.new()
	change.number = Skill.COOLDOWN
	change.kind = NumberChange.Kind.INCREASED
	change.amount = -100.0
	var no_cooldown := Modifier.new()
	no_cooldown.number_changes = [change]
	assert_true(recording.try_activate(Vector3.RIGHT, [no_cooldown]))
	assert_eq(recording.snapshots[0].number(Skill.COOLDOWN), 0.0, "the Snapshot keeps what the Modifiers made")
	assert_eq(recording.cooldown_left, Skill.SHORTEST_COOLDOWN)
	assert_false(recording.try_activate(Vector3.RIGHT, [no_cooldown]), "still cooling down")


func test_it_says_when_it_is_ready_again() -> void:
	var recording := _recording(1.0, [])
	watch_signals(recording)
	recording.try_activate(Vector3.RIGHT, [])
	recording.cool_down(0.5)
	assert_signal_not_emitted(recording, "ready_again")
	recording.cool_down(0.6)
	assert_signal_emit_count(recording, "ready_again", 1)
	recording.cool_down(1.0)
	assert_signal_emit_count(recording, "ready_again", 1, "once, not every frame after")


func test_it_runs_its_own_cooldown() -> void:
	var recording := _recording(0.2, [])
	recording.try_activate(Vector3.RIGHT, [])
	await wait_physics_frames(15) # 0.25 s at 60 Hz
	assert_true(recording.is_ready())


# Damage is one of the Skill's numbers, so the Snapshot holds it after Modifiers.

func test_attack_and_fireball_deal_their_damage() -> void:
	var attack: Skill = autofree(preload("res://skills/attack/attack.tscn").instantiate())
	var fireball: Skill = autofree(preload("res://skills/fireball/fireball.tscn").instantiate())
	assert_eq(attack.snapshot([]).number(Skill.DAMAGE), 10.0)
	assert_eq(fireball.snapshot([]).number(Skill.DAMAGE), 20.0)


func test_a_modifier_on_damage_changes_it() -> void:
	var attack: Skill = autofree(preload("res://skills/attack/attack.tscn").instantiate())
	var harder := Modifier.new()
	var change := NumberChange.new()
	change.number = Skill.DAMAGE
	change.kind = NumberChange.Kind.INCREASED
	change.amount = 50.0
	harder.number_changes = [change]
	assert_eq(attack.snapshot([harder]).number(Skill.DAMAGE), 15.0, "10, 50% increased")


func test_a_skill_without_a_character_fails_loudly() -> void:
	var recording := RecordingSkill.new()
	recording.cooldown = 1.0
	add_child_autofree(recording)
	assert_false(recording.try_activate(Vector3.RIGHT, []))
	assert_engine_error("has no Character")
	assert_eq(recording.snapshots.size(), 0, "nothing happened")
	assert_eq(recording.cooldown_left, 0.0, "and no Cooldown started")


func test_a_skill_with_its_own_physics_process_still_cools_down() -> void:
	var own := OwnPhysicsSkill.new()
	own.cooldown = Skill.SHORTEST_COOLDOWN
	own.character = autofree(Character.new()) # a stand-in: this Skill never reaches its Character
	add_child_autofree(own)
	own.try_activate(Vector3.RIGHT, [])
	await wait_physics_frames(8) # 0.1 s less six sixtieths leaves a crumb above 0: ready on the 7th tick
	assert_gt(own.frames, 0, "its own _physics_process ran")
	assert_true(own.is_ready())


func test_a_cooldown_waits_while_the_game_is_paused() -> void:
	var recording := _recording(1.0, [])
	recording.try_activate(Vector3.RIGHT, [])
	get_tree().paused = true
	await wait_physics_frames(6) # counts the tree's frames, paused or not
	get_tree().paused = false
	assert_eq(recording.cooldown_left, 1.0)
	await wait_physics_frames(6)
	assert_lt(recording.cooldown_left, 1.0, "and it runs again once unpaused")


func test_an_aim_with_no_direction_on_the_ground_is_refused() -> void:
	var recording := _recording(1.0, [])
	assert_false(recording.try_activate(Vector3.ZERO, []))
	assert_push_error("direction on the ground")
	assert_false(recording.try_activate(Vector3(0.0, 0.3, 0.0), []), "straight up has none either")
	assert_push_error("direction on the ground")
	assert_eq(recording.snapshots.size(), 0, "nothing happened")
	assert_eq(recording.cooldown_left, 0.0, "and no Cooldown started")
