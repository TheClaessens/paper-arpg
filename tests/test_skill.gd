extends GutTest
## Landing a Skill's hits: each Hurtbox hit tells its Enemy, which is pushed along its own
## direction with the Snapshot's Knockback and Stagger. The impact plays once per activation.

const ZombieScene := preload("res://characters/enemy/zombie.tscn")
const HurtboxScene := preload("res://characters/hurtbox/hurtbox.tscn")
const ENEMIES := 1 << 4 # Faction.layer(ENEMIES), written out so the test doesn't recompute it

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


# Auto-aim: the nearest Enemy within 60° of Facing, no farther than the Range; with none, along
# Facing. Its caller hands it the Enemies within Range.

func test_auto_aim_picks_the_nearest_enemy_near_facing() -> void:
	var near := Vector3(2.0, 0.0, 0.5)
	var far := Vector3(4.0, 0.0, 0.0)
	assert_eq(Skill.auto_aim(Vector3.RIGHT, 5.0, [far, near]), near)


func test_auto_aim_ignores_enemies_behind_or_wide_of_facing() -> void:
	var behind := Vector3(-1.0, 0.0, 0.0)
	var wide := Vector3(1.0, 0.0, 2.0) # 63° off Facing
	assert_eq(Skill.auto_aim(Vector3.RIGHT, 5.0, [behind, wide]), Vector3.RIGHT * 5.0, "along Facing, as far as the Range")


func test_auto_aim_ignores_height() -> void:
	assert_eq(Skill.auto_aim(Vector3.RIGHT, 5.0, [Vector3(2.0, 0.5, 0.0)]), Vector3(2.0, 0.0, 0.0))


# Reach: a Hurtbox is within reach when any part of it is. A zombie's Hurtbox is its body's
# capsule, 0.25 around its centre. Only Hurtboxes on the layers asked for are found.

func _player_hurtbox_at(x: float) -> Hurtbox:
	var hurtbox: Hurtbox = HurtboxScene.instantiate()
	hurtbox.collision_layer = Faction.layer(Faction.Id.PLAYER)
	add_child_autofree(hurtbox)
	hurtbox.global_position = Vector3(x, 0.0, 0.0)
	return hurtbox


func test_a_hurtbox_is_within_reach_when_any_part_of_it_is() -> void:
	var zombie := _zombie_at(1.2) # its near edge at 0.95
	await wait_physics_frames(2) # the physics world learns where it stands
	var world := skill.get_world_3d()
	assert_eq(Skill.hurtboxes_around(world, Vector3.ZERO, 1.0, ENEMIES), [zombie.hurtbox] as Array[Hurtbox])
	assert_eq(Skill.hurtboxes_around(world, Vector3.ZERO, 0.9, ENEMIES), [] as Array[Hurtbox], "0.05 short of it")


func test_only_hurtboxes_on_the_layers_asked_for_are_found() -> void:
	var zombie := _zombie_at(0.5)
	_player_hurtbox_at(0.5)
	await wait_physics_frames(2)
	var world := skill.get_world_3d()
	assert_eq(Skill.hurtboxes_around(world, Vector3.ZERO, 1.0, ENEMIES), [zombie.hurtbox] as Array[Hurtbox])
	assert_eq(Skill.hurtbox_nearest(world, Vector3(0.5, 0.0, 0.0), 1.0, ENEMIES), zombie.hurtbox)


func test_the_players_skills_never_aim_at_the_players_faction() -> void:
	_player_hurtbox_at(1.0)
	await wait_physics_frames(2)
	assert_eq(skill.aim_toward(Vector3.RIGHT, 2.0), Vector3.RIGHT * 2.0, "along Facing")
	assert_null(Skill.hurtbox_nearest(skill.get_world_3d(), Vector3(1.0, 0.0, 0.0), 1.0, skill.hostile_mask()), "nothing to ring")


func test_auto_aim_at_a_body_in_range_goes_as_far_as_the_range() -> void:
	skill.range = 1.6 # the Attack's, which a 32-bit length can't hold exactly
	var zombie := _zombie_at(1.5)
	zombie.global_position.z = 0.7 # 25° off Facing, centre 1.66 away, body inside the Range
	await wait_physics_frames(2)
	var aim := skill.aim_toward(Vector3.RIGHT, skill.range)
	assert_almost_eq(aim, Vector3(1.5, 0.0, 0.7).normalized() * 1.6, Vector3.ONE * 0.001, "at the Enemy, not along Facing")


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
