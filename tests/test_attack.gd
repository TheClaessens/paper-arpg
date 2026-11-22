extends GutTest
## The Attack's Sweep along Facing: a Hurtbox counts when its centre lies inside it. Whether it
## is within Range is asked of the physics engine first (see test_skill.gd).


func _at(degrees: float, distance: float) -> Vector3:
	return Vector3.FORWARD.rotated(Vector3.UP, deg_to_rad(degrees)) * distance


func test_straight_ahead_within_range() -> void:
	assert_true(Attack.in_sweep(_at(0.0, 1.5), Vector3.FORWARD, 120.0))


func test_inside_and_outside_the_sweep() -> void:
	assert_true(Attack.in_sweep(_at(55.0, 1.0), Vector3.FORWARD, 120.0))
	assert_false(Attack.in_sweep(_at(65.0, 1.0), Vector3.FORWARD, 120.0))


func test_height_is_ignored() -> void:
	assert_true(Attack.in_sweep(_at(0.0, 1.0) + Vector3.UP * 0.5, Vector3.FORWARD, 120.0))


func test_an_enemy_pressed_against_the_player_is_hit_from_any_side() -> void:
	assert_true(Attack.in_sweep(_at(180.0, 0.4), Vector3.FORWARD, 120.0))


# A swing hits the hostile Hurtboxes inside its Sweep and Range, and never one of its own Faction.

func test_a_swing_hits_a_zombie_and_not_the_players_faction_in_the_same_spot() -> void:
	var attack: Attack = preload("res://skills/attack/attack.tscn").instantiate()
	add_child_autofree(attack)
	var zombie: Enemy = preload("res://characters/enemy/zombie.tscn").instantiate()
	add_child_autofree(zombie)
	zombie.global_position = Vector3(1.0, 0.0, 0.3)
	var friend: Hurtbox = preload("res://characters/hurtbox/hurtbox.tscn").instantiate()
	friend.collision_layer = Faction.layer(Faction.Id.PLAYER)
	add_child_autofree(friend)
	friend.global_position = zombie.global_position # in the same spot
	await wait_physics_frames(2) # the physics world learns where they stand
	watch_signals(zombie.hurtbox)
	watch_signals(friend)
	attack.try_activate(Vector3.RIGHT, [])
	assert_signal_emit_count(zombie.hurtbox, "hit_taken", 1)
	assert_signal_not_emitted(friend, "hit_taken")
	Engine.time_scale = 1.0 # the hitstop the hit started
