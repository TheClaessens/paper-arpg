extends GutTest
## Landing a Skill's hits: each Enemy is pushed along its own direction with the Skill's
## Knockback and Stagger, and the impact plays once per call, not per Enemy.

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
	skill._land_hits({left: Vector3.LEFT, right: Vector3.RIGHT}, skill.snapshot([]))
	await wait_physics_frames(30) # past the hitstop and the Stagger
	assert_almost_eq(left.global_position.x, -5.35, 0.05)
	assert_almost_eq(right.global_position.x, 5.35, 0.05)


func test_no_hits_no_impact() -> void:
	skill._land_hits({}, skill.snapshot([]))
	assert_eq(Engine.time_scale, 1.0)


# Reach: an Enemy is within reach when any part of its body is. A zombie's body is 0.25 around
# its centre.

func test_an_enemy_is_within_reach_when_its_body_is() -> void:
	var zombie := _zombie_at(1.2) # its near edge at 0.95
	await wait_physics_frames(2) # the physics world learns where it stands
	assert_eq(Enemy.enemies_around(skill.get_world_3d(), Vector3.ZERO, 1.0), [zombie] as Array[Enemy])
	assert_eq(Enemy.enemies_around(skill.get_world_3d(), Vector3.ZERO, 0.9), [] as Array[Enemy], "0.05 short of it")


# Every Skill needs a Cooldown: it is the only thing that limits how often a Skill is activated.

func test_a_skill_without_a_cooldown_warns() -> void:
	skill.cooldown = 0.0
	assert_eq(skill._get_configuration_warnings().size(), 1)
	skill.cooldown = 0.4
	assert_eq(skill._get_configuration_warnings().size(), 0)


# Activating: try_activate() is the one way to set a Skill off. It makes the activation's
# Snapshot, starts the Snapshot's Cooldown and then does what the Skill does.

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
	var recording := _recording(0.05, [])
	recording.try_activate(Vector3.RIGHT, [])
	await wait_physics_frames(6) # 0.1 s at 60 Hz
	assert_true(recording.is_ready())
