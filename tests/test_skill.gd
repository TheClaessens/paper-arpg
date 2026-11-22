extends GutTest
## Landing a Skill's hits: each Hurtbox hit tells its Enemy, which is pushed along its own
## direction with the Snapshot's Knockback and Stagger. The impact plays once per call, not per
## Hurtbox.

const ZombieScene := preload("res://characters/enemy/zombie.tscn")

var skill: Skill


func before_each() -> void:
	skill = Skill.new()
	skill.knockback = 0.35
	skill.stagger = 0.05
	add_child_autofree(skill)


func after_each() -> void:
	Engine.time_scale = 1.0


func _zombie_at(x: float) -> Enemy:
	var zombie: Enemy = ZombieScene.instantiate()
	add_child_autofree(zombie)
	zombie.global_position = Vector3(x, 0.0, 0.0)
	return zombie


func test_each_enemy_is_pushed_its_own_way() -> void:
	var left := _zombie_at(-5.0)
	var right := _zombie_at(5.0)
	skill._land_hits({left.hurtbox: Vector3.LEFT, right.hurtbox: Vector3.RIGHT}, skill.snapshot([]))
	await wait_physics_frames(30) # past the hitstop and the Stagger
	assert_almost_eq(left.global_position.x, -5.35, 0.05)
	assert_almost_eq(right.global_position.x, 5.35, 0.05)


func test_no_hits_no_impact() -> void:
	skill._land_hits({}, skill.snapshot([]))
	assert_eq(Engine.time_scale, 1.0)


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


func _recording(seconds: float, skill_tags: Array[StringName]) -> RecordingSkill:
	var recording := RecordingSkill.new()
	recording.cooldown = seconds
	recording.tags = skill_tags
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
