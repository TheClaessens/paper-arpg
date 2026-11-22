extends GutTest
## Factions: each has its own layer, and a Skill whose Character is of one Faction looks on every other's.


func test_the_players_skills_look_on_the_enemies_layer_only() -> void:
	var mask := Faction.hostile_mask(Faction.Id.PLAYER)
	assert_true(mask & Faction.layer(Faction.Id.ENEMIES) != 0, "the Enemies are hostile")
	assert_eq(mask & Faction.layer(Faction.Id.PLAYER), 0, "the player's own Faction is not")


func test_the_enemies_skills_look_on_the_players_layer_only() -> void:
	var mask := Faction.hostile_mask(Faction.Id.ENEMIES)
	assert_true(mask & Faction.layer(Faction.Id.PLAYER) != 0)
	assert_eq(mask & Faction.layer(Faction.Id.ENEMIES), 0)


func test_a_factions_layer_is_no_bodys_layer() -> void:
	for faction: Faction.Id in Faction.Id.values():
		assert_eq(Faction.layer(faction) & 0b111, 0, "not world, player or enemy: a body there would be hit")
