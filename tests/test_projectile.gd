extends GutTest
## A ball (Projectile) flies straight from beside the Character that threw it and ends where its
## front reaches its Range from that Character's centre. It carries its throw's Hit and lands it
## itself, so it flies on when its Skill and its Character are gone. It stops at the first hostile
## Hurtbox its Hit lands on, or with Pierce at the second, lands on each once, flies on past one its
## Hit misses, and stops at any wall. Its front reaches exactly its Range, never farther. A ball that
## can't fly ends where it starts. A ball frozen by a hitstop flies on after it. A ball outlives its
## Character, and an Enemy's goes into its Level and goes with it.
## after_each frees every ball a test threw: a ball lives beside its Character, not under it.

const ProjectileScene := preload("res://skills/fireball/projectile.tscn")
const ZombieScene := preload("res://characters/enemy/zombie.tscn")
const PlayerScene := preload("res://characters/player/player.tscn")
const FireballScene := preload("res://skills/fireball/fireball.tscn")

var hits: Array[Hurtbox] = [] # every Hurtbox a Hit landed on, in order, read from the zombies


func before_each() -> void:
	hits.clear()


func after_each() -> void:
	Engine.time_scale = 1.0 # in case a test froze it
	for ball in _balls():
		ball.free() # a ball lives beside its Character, not under it: free it, or it flies on into the next test


func test_flies_along_its_direction_then_disappears_after_its_range() -> void:
	var projectile: Projectile = add_child_autoqfree(ProjectileScene.instantiate())
	var snapshot := Snapshot.new([], {Fireball.PROJECTILE_SPEED: 60.0, Skill.RANGE: 5.0}, []) # 1 unit per frame at 60 Hz
	projectile.launch(Hit.new(snapshot, null, false), Vector3.ZERO, Vector3.LEFT, 0)
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
	var ball: Projectile = _balls()[0]
	modifiers.clear() # the Character loses the Modifier while the ball flies
	assert_eq(ball.hit.snapshot.number(Skill.RANGE), 15.0, "still 10 + 5")
	assert_eq(fireball.snapshot(modifiers).number(Skill.RANGE), 10.0, "the next throw goes 10")


## The player's own Fireball, the player standing at the origin with its physics off (no camera
## here to read input against, as in test_player.gd).
func _players_fireball() -> Fireball:
	var player: Player = add_child_autofree(PlayerScene.instantiate())
	player.set_physics_process(false)
	return player.get_node("Skills/Fireball")


## The balls in the test's node: those a test made itself and those the player's Fireball threw
## beside the player.
func _balls() -> Array[Node]:
	return find_children("*", "Projectile", false, false)


## A zombie at `x`, by its Hurtbox. A Hit landing on it is recorded in `hits`.
func _zombie_at(x: float) -> Hurtbox:
	var zombie: Enemy = ZombieScene.instantiate()
	add_child_autofree(zombie)
	zombie.global_position = Vector3(x, 0.0, 0.0)
	var hurtbox := zombie.hurtbox
	hurtbox.hit_taken.connect(func(_hit: Hit, _direction: Vector3) -> void: hits.append(hurtbox))
	return hurtbox


## A ball thrown from the origin along `Vector3.RIGHT`, looking on the layers hostile to the
## player's Faction (so its Hit lands on Enemies), carrying a Hit with `tags` and `projectile_speed`
## (0.25 units a frame at 15) that does `damage` and no knockback or stagger: a Range of 12.
func _fire(tags: Array[StringName], projectile_speed := 15.0, damage := 0.0) -> Projectile:
	var numbers: Dictionary[StringName, float] = {
		Fireball.PROJECTILE_SPEED: projectile_speed, Skill.RANGE: 12.0, Skill.DAMAGE: damage, Skill.KNOCKBACK: 0.0, Skill.STAGGER: 0.0,
	}
	var hit := Hit.new(Snapshot.new(tags, numbers, []), null, false)
	var ball: Projectile = add_child_autoqfree(ProjectileScene.instantiate())
	ball.launch(hit, Vector3.ZERO, Vector3.RIGHT, Faction.hostile_mask(Faction.Id.PLAYER))
	return ball


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
	first.hit_taken.connect(func(_hit: Hit, _direction: Vector3) -> void:
		first.set_deferred(&"global_position", Vector3(4.0, 0.0, 0.0))) # knocked ahead of the ball
	await wait_physics_frames(40)
	assert_eq(hits, [first, second], "touching the first again neither hits it nor stops the ball")
	assert_freed(ball)


func test_a_ball_in_flight_keeps_pierce_when_the_modifier_goes() -> void:
	var fireball := _players_fireball()
	var modifiers: Array[Modifier] = [load("res://skills/modifiers/pierce.tres")]
	fireball.try_activate(Vector3.RIGHT, modifiers)
	var ball: Projectile = _balls()[0]
	modifiers.clear() # Pierce switched off while the ball flies
	assert_has(ball.hit.snapshot.tags, &"Pierce")
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
	var lowest := 1.0 # sampled each frame, not in hit_taken: land() emits that before it plays the impact
	for i in 20:
		await wait_physics_frames(1)
		lowest = minf(lowest, Engine.time_scale)
	assert_eq(hits, [zombie], "hit once")
	assert_eq(lowest, 1.0, "the world never froze")
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
	assert_signal_emit_count(second, "hit_taken", 1, "the kill was its pierced Hit")
	assert_signal_not_emitted(third, "hit_taken", "it stopped at the second")


func test_a_piercing_ball_lands_its_throws_one_hit_on_both() -> void:
	var fireball := _players_fireball()
	var landed: Array[Hit] = []
	for x: float in [2.0, 4.0]:
		_zombie_at(x).hit_taken.connect(func(hit: Hit, _direction: Vector3) -> void: landed.append(hit))
	await wait_physics_frames(2)
	fireball.try_activate(Vector3.RIGHT, [load("res://skills/modifiers/pierce.tres")])
	await wait_physics_frames(40)
	assert_eq(landed.size(), 2, "both zombies took a Hit")
	assert_same(landed[0], landed[1], "the throw's one Hit, not one per contact")
	assert_same(landed[0].dealer, fireball.character, "dealt by the player")


func test_a_ball_whose_character_is_freed_mid_flight_still_lands_its_hit() -> void:
	var fireball := _players_fireball()
	var zombie: Enemy = _zombie_at(3.0).get_parent()
	await wait_physics_frames(2)
	fireball.try_activate(Vector3.RIGHT, [])
	fireball.character.free() # the player and its Fireball, with the ball in flight
	await wait_physics_frames(30)
	assert_eq(zombie.health.current, 30.0, "the ball flew on and landed its Hit")


func test_an_enemys_ball_goes_into_its_level_and_goes_with_it() -> void:
	var level: Node3D = add_child_autofree(Node3D.new()) # stands in for a Level
	var zombie: Enemy = ZombieScene.instantiate()
	level.add_child(zombie)
	var fireball: Fireball = FireballScene.instantiate()
	zombie.add_skill(fireball)
	fireball.try_activate(Vector3.RIGHT, [])
	var balls := level.find_children("*", "Projectile", true, false)
	assert_eq(balls.size(), 1, "the zombie threw a ball")
	var ball: Node = balls[0]
	assert_eq(ball.get_parent(), level, "it is beside its Character, in the Level")
	level.free()
	assert_freed(ball, "it goes with its Level")


func test_a_ball_flies_on_past_a_zombie_its_hit_missed() -> void:
	var first := _zombie_at(2.0)
	(first.get_parent() as Enemy).health.damage(40.0) # 10 left: one ball's Hit kills it
	var second := _zombie_at(4.0)
	await wait_physics_frames(2)
	_fire([], 15.0, 10.0)
	_fire([], 15.0, 10.0) # side by side: both touch the first zombie in the same physics step
	await wait_physics_frames(20) # about 14 frames at 0.25 a frame to cross the 3.1 to the second zombie; the rest is slack
	assert_eq(hits, [first, second], "the ball whose Hit missed the dead zombie flew on to the second")


func test_a_fireballs_front_reaches_its_range() -> void:
	var fireball := _players_fireball()
	var zombie: Enemy = _zombie_at(10.15).get_parent() # its near side is 9.9 from the player's centre
	await wait_physics_frames(2)
	fireball.try_activate(Vector3.RIGHT, [])
	await wait_physics_frames(55) # its flight takes 47 frames at Projectile speed 12, and one more to end; the rest is slack
	assert_eq(zombie.health.current, 30.0, "the ball's front reaches the Range of 10")


func test_a_fireball_never_touches_a_zombie_wholly_beyond_its_range() -> void:
	var fireball := _players_fireball()
	var zombie: Enemy = _zombie_at(10.35).get_parent() # its near side is 10.1 from the player's centre
	await wait_physics_frames(2)
	fireball.try_activate(Vector3.RIGHT, [])
	await wait_physics_frames(55) # its flight takes 47 frames at Projectile speed 12, and one more to end; the rest is slack
	assert_eq(zombie.health.current, 50.0, "untouched")
	assert_eq(_balls(), [] as Array[Node], "the ball has ended")


func test_a_fireballs_last_step_is_cut_short_at_its_range() -> void:
	var fireball := _players_fireball()
	# Its near side is 10.02 from the player's centre. A step is 0.2, so an unclipped last step would
	# put the front at 10.05 and touch it; the clipped one stops the front at 10.0. The ball and the
	# Hurtbox's straight part are both at height 0.5, so the horizontal gap is the whole distance.
	var zombie: Enemy = _zombie_at(10.27).get_parent()
	await wait_physics_frames(2)
	fireball.try_activate(Vector3.RIGHT, [])
	await wait_physics_frames(55) # 47 frames of flight and one to end; the rest is slack
	assert_eq(zombie.health.current, 50.0, "the front stopped at the Range of 10, short of its near side")


func test_a_ball_with_no_projectile_speed_ends() -> void:
	var ball := _fire([], 0.0)
	await wait_physics_frames(3)
	assert_freed(ball, "it can't fly, so it ends where it starts")


func test_a_ball_frozen_by_a_hitstop_flies_on_after_it() -> void:
	var zombie := _zombie_at(4.0)
	await wait_physics_frames(2)
	var ball := _fire([])
	Engine.time_scale = 0.0 # as a hitstop does
	await wait_physics_frames(10)
	assert_not_freed(ball, "a frozen ball waits")
	Engine.time_scale = 1.0
	await wait_physics_frames(30)
	assert_eq(hits, [zombie], "it flew on and hit the zombie")
