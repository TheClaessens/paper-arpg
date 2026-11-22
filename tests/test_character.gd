extends GutTest
## A Character: its Faction reaches its Hurtbox and its Skills, a Skill given later joins its Skills,
## and only a Character with a Stagger is staggered.

const PlayerScene := preload("res://characters/player/player.tscn")
const ZombieScene := preload("res://characters/enemy/zombie.tscn")


func test_an_enemys_hurtbox_is_on_the_enemies_layer() -> void:
	var zombie: Enemy = add_child_autofree(ZombieScene.instantiate())
	assert_eq(zombie.hurtbox.collision_layer, Faction.layer(Faction.Id.ENEMIES))


func test_the_player_and_its_skills_are_of_the_players_faction() -> void:
	var player: Player = add_child_autofree(PlayerScene.instantiate())
	assert_eq(player.faction, Faction.Id.PLAYER)
	for skill in player.skills:
		assert_eq(skill.faction, Faction.Id.PLAYER, "%s is the player's" % skill.name)


func test_a_skill_given_later_takes_its_characters_faction() -> void:
	var zombie: Enemy = add_child_autofree(ZombieScene.instantiate())
	var skill := Skill.new()
	zombie.add_skill(skill)
	assert_eq(skill.get_parent(), zombie.get_node("Skills"))
	assert_eq(skill.faction, Faction.Id.ENEMIES)


func test_without_a_stagger_a_hit_doesnt_push() -> void:
	var zombie: Enemy = ZombieScene.instantiate()
	zombie.get_node("Stagger").free()
	add_child_autofree(zombie)
	await wait_physics_frames(2) # the physics world learns where it stands
	var snapshot := Snapshot.new([], {Skill.DAMAGE: 10.0, Skill.KNOCKBACK: 0.35, Skill.STAGGER: 0.05}, [])
	zombie.hurtbox.take_hit(Vector3.RIGHT, snapshot)
	Engine.time_scale = 1.0 # the hitstop the hit started
	assert_eq(zombie.health.current, zombie.health.max_health - 10.0, "it took the Damage")
	var stood := zombie.global_position
	await wait_physics_frames(10)
	assert_eq(zombie.global_position, stood, "and wasn't pushed")
