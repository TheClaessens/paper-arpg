extends GutTest
## A Hit lands itself: each Hurtbox it lands on tells its Character, which is pushed along its own
## direction. The impact plays once per landing, and only when the Hit landed on an Enemy.
## A Hit never changes, and a dealer that is freed reads as none.

const ZombieScene := preload("res://characters/enemy/zombie.tscn")
const PlayerScene := preload("res://characters/player/player.tscn")
const HurtboxScene := preload("res://characters/hurtbox/hurtbox.tscn")


func after_each() -> void:
	Engine.time_scale = 1.0


## A Snapshot with the numbers a Character hit reads: Character._on_hit_taken() asks for all three.
func _snapshot(damage: float, knockback: float, stagger: float) -> Snapshot:
	return Snapshot.new([], {Skill.DAMAGE: damage, Skill.KNOCKBACK: knockback, Skill.STAGGER: stagger}, [])


func _zombie_at(x: float) -> Enemy:
	var zombie: Enemy = ZombieScene.instantiate()
	add_child_autofree(zombie)
	zombie.global_position = Vector3(x, 0.0, 0.0)
	return zombie


func test_each_enemy_is_pushed_its_own_way() -> void:
	var left := _zombie_at(-5.0)
	var right := _zombie_at(5.0)
	Hit.new(_snapshot(0.0, 0.35, 0.05), null, true).land({left.hurtbox: Vector3.LEFT, right.hurtbox: Vector3.RIGHT})
	await wait_physics_frames(30) # past the hitstop and the Stagger
	assert_almost_eq(left.global_position.x, -5.35, 0.05)
	assert_almost_eq(right.global_position.x, 5.35, 0.05)


func test_landing_on_nothing_plays_no_impact() -> void:
	assert_false(Hit.new(_snapshot(0.0, 0.0, 0.0), null, true).land({}))
	assert_eq(Engine.time_scale, 1.0)


# Only a Hit that landed on an Enemy plays the impact.

func test_a_hit_on_the_player_neither_freezes_nor_shakes_the_world() -> void:
	var camera := Camera3D.new()
	add_child_autofree(camera)
	camera.make_current()
	assert_eq(get_viewport().get_camera_3d(), camera, "the camera a shake would move")
	var player: Player = PlayerScene.instantiate()
	player.add_child(HurtboxScene.instantiate()) # player.tscn has none yet: the first Enemy Skill will bring one
	add_child_autofree(player)
	player.set_physics_process(false) # no camera here to read input against, as in test_player.gd
	var landed := Hit.new(_snapshot(10.0, 0.0, 0.0), null, true).land({player.hurtbox: Vector3.RIGHT})
	assert_true(landed)
	assert_eq(player.health.current, 90.0, "it took the Damage")
	assert_eq(Engine.time_scale, 1.0, "nothing froze")
	await wait_process_frames(3)
	assert_eq(camera.h_offset, 0.0, "and nothing shook")
	assert_eq(camera.v_offset, 0.0)


func test_the_killing_hit_on_an_enemy_still_freezes_the_world() -> void:
	var zombie: Enemy = ZombieScene.instantiate()
	add_child_autoqfree(zombie)
	zombie.health.damage(zombie.health.max_health - 10.0)
	watch_signals(zombie.health)
	Hit.new(_snapshot(10.0, 0.0, 0.0), null, true).land({zombie.hurtbox: Vector3.RIGHT})
	assert_signal_emit_count(zombie.health, "died", 1, "it died")
	assert_eq(Engine.time_scale, 0.0, "and the killing Hit froze the world")


# A Hit never changes, and its dealer is never a freed Character.

func test_a_hits_fields_cannot_be_replaced() -> void:
	var snapshot := _snapshot(10.0, 0.0, 0.0)
	var hit := Hit.new(snapshot, null, true)
	hit.snapshot = _snapshot(99.0, 0.0, 0.0)
	assert_engine_error("A Hit never changes")
	hit.dealer = autofree(Character.new())
	assert_engine_error("A Hit never changes")
	hit.freezes = false
	assert_engine_error("A Hit never changes")
	assert_same(hit.snapshot, snapshot)
	assert_null(hit.dealer)
	assert_true(hit.freezes)


func test_a_dealer_that_is_freed_reads_as_none() -> void:
	var dealer := Character.new()
	var hit := Hit.new(_snapshot(10.0, 0.0, 0.0), dealer, true)
	assert_same(hit.dealer, dealer)
	dealer.free()
	assert_same(hit.dealer, null, "none, not the freed Character")
