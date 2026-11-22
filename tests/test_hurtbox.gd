extends GutTest
## Finding Hurtboxes: the ones within reach of a spot, on the layers asked for, and the one nearest
## a spot on the ground if it is close enough (what a Skill landing on a spot picks out, and which
## one the mouse cursor highlights). It finds up to Hurtbox.MOST_FOUND at once, with a warning
## when that many are found.

const ZombieScene := preload("res://characters/enemy/zombie.tscn")
const HurtboxScene := preload("res://characters/hurtbox/hurtbox.tscn")
const ENEMIES := 1 << 4 # Faction.layer(ENEMIES), written out so the test doesn't recompute it


func test_the_hurtbox_nearest_the_spot() -> void:
	var positions: Array[Vector3] = [Vector3(4.0, 0.0, 0.0), Vector3(2.0, 0.0, 1.0), Vector3(2.5, 0.0, -0.5)]
	assert_eq(Hurtbox.nearest_to(Vector3(2.4, 0.0, -0.2), positions, 1.5), 2)


func test_none_when_no_hurtbox_is_close_enough() -> void:
	var positions: Array[Vector3] = [Vector3(4.0, 0.0, 0.0)]
	assert_eq(Hurtbox.nearest_to(Vector3(1.0, 0.0, 0.0), positions, 1.5), -1)


func test_height_is_ignored() -> void:
	var positions: Array[Vector3] = [Vector3(1.0, 0.8, 0.0)]
	assert_eq(Hurtbox.nearest_to(Vector3(1.0, 0.0, 0.0), positions, 0.5), 0)


# Reach: a Hurtbox is within reach when any part of it is. A zombie's Hurtbox is its body's
# capsule, 0.25 around its centre. Only Hurtboxes on the layers asked for are found.

func _zombie_at(x: float) -> Enemy:
	var zombie: Enemy = ZombieScene.instantiate()
	add_child_autofree(zombie)
	zombie.global_position = Vector3(x, 0.0, 0.0)
	return zombie


func _player_hurtbox_at(x: float) -> Hurtbox:
	var hurtbox: Hurtbox = HurtboxScene.instantiate()
	hurtbox.collision_layer = Faction.layer(Faction.Id.PLAYER)
	add_child_autofree(hurtbox)
	hurtbox.global_position = Vector3(x, 0.0, 0.0)
	return hurtbox


## `count` Hurtboxes on the Enemies' layer, all at `x`.
func _enemy_hurtboxes_at(count: int, x: float) -> void:
	for i in count:
		var hurtbox: Hurtbox = HurtboxScene.instantiate()
		hurtbox.collision_layer = ENEMIES
		add_child_autofree(hurtbox)
		hurtbox.global_position = Vector3(x, 0.0, 0.0)


func test_a_hurtbox_is_within_reach_when_any_part_of_it_is() -> void:
	var zombie := _zombie_at(1.2) # its near edge at 0.95
	await wait_physics_frames(2) # the physics world learns where it stands
	var world := get_tree().root.world_3d
	assert_eq(Hurtbox.around(world, Vector3.ZERO, 1.0, ENEMIES), [zombie.hurtbox] as Array[Hurtbox])
	assert_eq(Hurtbox.around(world, Vector3.ZERO, 0.9, ENEMIES), [] as Array[Hurtbox], "0.05 short of it")


func test_only_hurtboxes_on_the_layers_asked_for_are_found() -> void:
	var zombie := _zombie_at(0.5)
	_player_hurtbox_at(0.5)
	await wait_physics_frames(2)
	var world := get_tree().root.world_3d
	assert_eq(Hurtbox.around(world, Vector3.ZERO, 1.0, ENEMIES), [zombie.hurtbox] as Array[Hurtbox])
	assert_eq(Hurtbox.nearest(world, Vector3(0.5, 0.0, 0.0), 1.0, ENEMIES), zombie.hurtbox)


func test_around_finds_more_than_32() -> void:
	_enemy_hurtboxes_at(33, 0.5)
	await wait_physics_frames(2)
	assert_eq(Hurtbox.around(get_tree().root.world_3d, Vector3.ZERO, 1.0, ENEMIES).size(), 33)


func test_around_warns_when_it_finds_its_most() -> void:
	_enemy_hurtboxes_at(Hurtbox.MOST_FOUND + 1, 0.5)
	await wait_physics_frames(2)
	assert_eq(Hurtbox.around(get_tree().root.world_3d, Vector3.ZERO, 1.0, ENEMIES).size(), Hurtbox.MOST_FOUND, "the rest are left out")
	assert_push_warning("found its most")
