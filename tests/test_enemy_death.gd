extends GutTest
## A zombie at 0 Health dies: it stops chasing, can't be hit, aimed at or ringed, blocks no one,
## and sinks where it stood before it is freed. A hit on it after that misses.

const ZombieScene := preload("res://characters/enemy/zombie.tscn")

var attack: Attack
var zombie: Enemy


func before_each() -> void:
	attack = preload("res://skills/attack/attack.tscn").instantiate()
	add_child_autofree(attack)
	zombie = ZombieScene.instantiate()
	add_child_autoqfree(zombie)
	zombie.global_position = Vector3(1.0, 0.0, 0.0)
	await wait_physics_frames(2) # the physics world learns where it stands


func after_each() -> void:
	Engine.time_scale = 1.0 # the hitstops the hits started


## Swings the Attack at the zombie `times` times, its Cooldown skipped.
func _swing(times: int) -> void:
	for i in times:
		attack.cooldown_left = 0.0
		attack.try_activate(Vector3.RIGHT, [])


func test_five_attacks_kill_a_zombie() -> void:
	watch_signals(zombie.health)
	_swing(4)
	assert_signal_not_emitted(zombie.health, "died", "40 Damage of its 50")
	_swing(1)
	assert_signal_emit_count(zombie.health, "died", 1)


func test_a_dead_zombie_cant_be_hit_aimed_at_or_ringed_and_blocks_no_one() -> void:
	_swing(5)
	var mask := Faction.hostile_mask(Faction.Id.PLAYER)
	assert_eq(Hurtbox.around(get_tree().root.world_3d, Vector3.ZERO, 3.0, mask), [] as Array[Hurtbox], "no Skill finds it")
	assert_null(Hurtbox.nearest(get_tree().root.world_3d, zombie.global_position, 1.0, mask), "no Auto-aim or ring")
	assert_eq(zombie.collision_layer, 0, "its body blocks no one")


func test_it_sinks_where_it_stood_and_is_freed_after_the_sink() -> void:
	_swing(5)
	Engine.time_scale = 1.0
	await wait_seconds(0.3)
	assert_not_freed(zombie, "still sinking")
	assert_almost_eq(zombie.global_position, Vector3(1.0, 0.0, 0.0), Vector3.ONE * 0.001, "the killing hit doesn't knock it back")
	await wait_seconds(0.25)
	assert_freed(zombie, "gone 0.45 s after the hit")


## Stands in for one Attack and one Fireball landing in the same frame, where the second finds
## the Hurtbox the first just killed.
func test_a_hit_after_the_killing_hit_misses() -> void:
	watch_signals(zombie.health)
	_swing(5)
	watch_signals(zombie.hurtbox)
	var snapshot := Snapshot.new([], {Skill.DAMAGE: 10.0}, [])
	assert_false(zombie.hurtbox.take_hit(Vector3.RIGHT, snapshot), "missed")
	assert_signal_not_emitted(zombie.hurtbox, "hit_taken", "no flash, squash or Damage")
	assert_signal_emit_count(zombie.health, "died", 1, "dies once")


func test_hit_feedback_plays_only_when_a_hit_landed() -> void:
	_swing(5)
	Engine.time_scale = 1.0
	var hits: Dictionary[Hurtbox, Vector3] = {zombie.hurtbox: Vector3.RIGHT}
	attack._land_hits(hits, Snapshot.new([], {Skill.DAMAGE: 10.0}, []))
	assert_eq(Engine.time_scale, 1.0, "no hitstop")
