extends GutTest
## Landing a Skill's hits: each Enemy is pushed along its own direction with the Skill's
## knockback and Stagger, and the impact plays once per use, not per Enemy.

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
	skill._land_hits({left: Vector3.LEFT, right: Vector3.RIGHT})
	await wait_physics_frames(30) # past the hitstop and the Stagger
	assert_almost_eq(left.global_position.x, -5.35, 0.05)
	assert_almost_eq(right.global_position.x, 5.35, 0.05)


func test_no_hits_no_impact() -> void:
	skill._land_hits({})
	assert_eq(Engine.time_scale, 1.0)


# Auto-aim: the nearest Enemy within Range and within 60° of Facing; with none, along Facing.

func test_auto_aim_picks_the_nearest_enemy_near_facing() -> void:
	var near := Vector3(2.0, 0.0, 0.5)
	var far := Vector3(4.0, 0.0, 0.0)
	assert_eq(Skill.auto_aim(Vector3.RIGHT, 5.0, [far, near]), near)


func test_auto_aim_ignores_enemies_behind_or_out_of_range() -> void:
	var behind := Vector3(-1.0, 0.0, 0.0)
	var wide := Vector3(1.0, 0.0, 2.0) # 63° off Facing
	var too_far := Vector3(6.0, 0.0, 0.0)
	assert_eq(Skill.auto_aim(Vector3.RIGHT, 5.0, [behind, wide, too_far]), Vector3.RIGHT * 5.0, "along Facing, as far as the Range")


func test_auto_aim_ignores_height() -> void:
	assert_eq(Skill.auto_aim(Vector3.RIGHT, 5.0, [Vector3(2.0, 0.5, 0.0)]), Vector3(2.0, 0.0, 0.0))
