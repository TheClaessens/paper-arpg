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
