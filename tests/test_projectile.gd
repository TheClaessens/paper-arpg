extends GutTest
## A Projectile flies straight along its direction and disappears once it has flown its
## Snapshot's Range. It keeps the Snapshot of the throw that fired it. It stops at the first
## hostile Hurtbox it hits, or with Pierce at the second, hits each once, and stops at any wall.

const ProjectileScene := preload("res://skills/fireball/projectile.tscn")
const ZombieScene := preload("res://characters/enemy/zombie.tscn")
const PlayerScene := preload("res://characters/player/player.tscn")

var hits: Array[Hurtbox] = [] # every Hurtbox the ball fired by _fire() reported hitting


func test_flies_along_its_direction_then_disappears_after_its_range() -> void:
	var projectile: Projectile = ProjectileScene.instantiate()
	projectile.direction = Vector3.LEFT
	projectile.snapshot = Snapshot.new([], {Fireball.PROJECTILE_SPEED: 60.0, Skill.RANGE: 5.0}, []) # 1 unit per frame at 60 Hz
	add_child_autoqfree(projectile)
	await wait_physics_frames(2)
	assert_lt(projectile.global_position.x, -0.5, "moving left")
	assert_almost_eq(projectile.global_position.z, 0.0, 0.001, "straight")
	await wait_physics_frames(8)
	assert_freed(projectile, "gone after 5 units")


func test_a_ball_in_flight_keeps_its_throws_snapshot() -> void:
	var fireball := _players_fireball()
	var farther := Modifier.new()
	var change := NumberChange.new()
	change.number = Skill.RANGE
	change.amount = 5.0
	farther.number_changes = [change]
	var modifiers: Array[Modifier] = [farther]
	fireball.try_activate(Vector3.RIGHT, modifiers)
	var ball: Projectile = fireball.get_child(0)
	modifiers.clear() # the Character loses the Modifier while the ball flies
	assert_eq(ball.snapshot.number(Skill.RANGE), 15.0, "still 10 + 5")
	assert_eq(fireball.snapshot(modifiers).number(Skill.RANGE), 10.0, "the next throw goes 10")



## The player's own Fireball, the player standing at the origin with its physics off (no camera
## here to read input against, as in test_player.gd).
func _players_fireball() -> Fireball:
	var player: Player = add_child_autofree(PlayerScene.instantiate())
	player.set_physics_process(false)
	return player.get_node("Skills/Fireball")


## A zombie at `x`, by its Hurtbox.
func _zombie_at(x: float) -> Hurtbox:
	var zombie: Enemy = ZombieScene.instantiate()
	add_child_autofree(zombie)
	zombie.global_position = Vector3(x, 0.0, 0.0)
	return zombie.hurtbox


## A ball the player's Fireball fired, flying right from the origin at body height, 0.25 units
## a frame, as far as 12.
func _fire(tags: Array[StringName]) -> Projectile:
	hits.clear()
	var projectile: Projectile = ProjectileScene.instantiate()
	projectile.direction = Vector3.RIGHT
	projectile.snapshot = Snapshot.new(tags, {Fireball.PROJECTILE_SPEED: 15.0, Skill.RANGE: 12.0}, [])
	projectile.collision_mask |= Faction.hostile_mask(Faction.Id.PLAYER)
	projectile.hit.connect(hits.append)
	add_child_autoqfree(projectile)
	projectile.global_position = Vector3.UP * 0.5
	return projectile


func test_without_pierce_it_stops_at_the_first_enemy() -> void:
	var first := _zombie_at(2.0)
	_zombie_at(4.0)
	await wait_physics_frames(2) # the physics world learns where they stand
	var ball := _fire([])
	await wait_physics_frames(30)
	assert_eq(hits, [first])
	assert_freed(ball)


func test_a_piercing_ball_passes_through_the_first_enemy_and_stops_at_the_second() -> void:
	var first := _zombie_at(2.0)
	var second := _zombie_at(4.0)
	_zombie_at(6.0)
	await wait_physics_frames(2)
	var ball := _fire([&"Pierce"])
	await wait_physics_frames(40)
	assert_eq(hits, [first, second], "the third is never reached")
	assert_freed(ball)


func test_a_piercing_ball_never_passes_through_a_wall() -> void:
	var wall := StaticBody3D.new() # on the `world` layer, as walls are
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	wall.add_child(shape)
	add_child_autofree(wall)
	wall.global_position = Vector3(2.0, 0.5, 0.0)
	_zombie_at(4.0)
	await wait_physics_frames(2)
	var ball := _fire([&"Pierce"])
	await wait_physics_frames(30)
	assert_eq(hits, [], "the zombie behind the wall is never reached")
	assert_freed(ball)


func test_it_hits_an_enemy_only_once_even_when_it_touches_it_again() -> void:
	var first := _zombie_at(2.0)
	var second := _zombie_at(6.0)
	await wait_physics_frames(2)
	var ball := _fire([&"Pierce"])
	ball.hit.connect(func(hurtbox: Hurtbox) -> void:
		if hurtbox == first:
			first.set_deferred(&"global_position", Vector3(4.0, 0.0, 0.0))) # knocked ahead of the ball
	await wait_physics_frames(40)
	assert_eq(hits, [first, second], "touching the first again neither hits it nor stops the ball")
	assert_freed(ball)


func test_a_ball_in_flight_keeps_pierce_when_the_modifier_goes() -> void:
	var fireball := _players_fireball()
	var modifiers: Array[Modifier] = [load("res://skills/modifiers/pierce.tres")]
	fireball.try_activate(Vector3.RIGHT, modifiers)
	var ball: Projectile = fireball.get_child(0)
	modifiers.clear() # Pierce switched off while the ball flies
	assert_has(ball.snapshot.tags, &"Pierce")
	assert_does_not_have(fireball.snapshot(modifiers).tags, &"Pierce", "the next throw doesn't pierce")


func test_a_piercing_ball_still_ends_at_its_range() -> void:
	var first := _zombie_at(2.0)
	_zombie_at(14.0) # past the Range of 12
	await wait_physics_frames(2)
	var ball := _fire([&"Pierce"])
	await wait_physics_frames(60)
	assert_eq(hits, [first])
	assert_freed(ball)


func test_a_fireball_hit_knocks_back_without_freezing_the_world() -> void:
	var fireball := _players_fireball()
	var zombie := _zombie_at(2.0)
	fireball.try_activate(Vector3.RIGHT, [])
	var ball: Projectile = fireball.get_child(0)
	var time_scales: Array[float] = []
	ball.hit.connect(func(_hurtbox: Hurtbox) -> void: time_scales.append(Engine.time_scale)) # after Fireball lands the hit
	await wait_physics_frames(20)
	Engine.time_scale = 1.0 # in case it froze, for the tests after this one
	assert_eq(time_scales, [1.0] as Array[float], "hit once, and the world kept running")
	assert_gt(zombie.global_position.x, 2.0, "knocked back")


func test_it_flies_through_a_hurtbox_of_its_throwers_faction() -> void:
	var friend: Hurtbox = preload("res://characters/hurtbox/hurtbox.tscn").instantiate()
	friend.collision_layer = Faction.layer(Faction.Id.PLAYER)
	add_child_autofree(friend)
	friend.global_position = Vector3(2.0, 0.0, 0.0)
	var zombie := _zombie_at(4.0)
	await wait_physics_frames(2)
	var ball := _fire([])
	await wait_physics_frames(30)
	assert_eq(hits, [zombie], "never hits the player's Faction, and isn't stopped by it")
	assert_freed(ball)


func test_a_fireball_lowers_a_zombies_health_by_its_damage() -> void:
	var fireball := _players_fireball()
	var zombie: Enemy = ZombieScene.instantiate()
	add_child_autofree(zombie)
	zombie.global_position = Vector3(2.0, 0.0, 0.0)
	await wait_physics_frames(2)
	fireball.try_activate(Vector3.RIGHT, [])
	await wait_physics_frames(30)
	assert_eq(zombie.health.current, 30.0, "50 less the Fireball's Damage of 20")


func test_a_piercing_ball_passes_through_the_zombie_it_kills_and_stops_at_the_next() -> void:
	var fireball := _players_fireball()
	var dying: Enemy = _zombie_at(2.0).get_parent()
	dying.health.damage(40.0) # the Fireball's 20 kills it
	var deaths: Array[bool] = []
	dying.health.died.connect(func() -> void: deaths.append(true))
	var second := _zombie_at(4.0)
	var third := _zombie_at(6.0)
	await wait_physics_frames(2)
	watch_signals(second)
	watch_signals(third)
	fireball.try_activate(Vector3.RIGHT, [load("res://skills/modifiers/pierce.tres")])
	await wait_physics_frames(40)
	assert_eq(deaths.size(), 1, "the first is killed")
	assert_signal_emit_count(second, "hit_taken", 1, "the kill was its pierced hit")
	assert_signal_not_emitted(third, "hit_taken", "it stopped at the second")
