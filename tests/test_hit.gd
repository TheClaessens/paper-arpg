extends GutTest
## A Hit lands itself: each Hurtbox it lands on tells its Character, which is pushed along its own
## direction. The impact plays once per landing.

const ZombieScene := preload("res://characters/enemy/zombie.tscn")


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
