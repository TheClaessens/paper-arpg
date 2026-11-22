extends GutTest
## Skill tags: each Skill's scene sets what kind of Skill it is, and implied tags (Fire is also
## Elemental) are worked out from whatever tags are given.

const FireballScene := preload("res://skills/fireball/fireball.tscn")
const AttackScene := preload("res://skills/attack/attack.tscn")


func _tags_of(scene: PackedScene) -> Array[StringName]:
	var skill: Skill = scene.instantiate()
	var tags := skill.tags
	skill.free()
	return tags


func test_fireball_is_a_fire_projectile_spell() -> void:
	assert_eq(_tags_of(FireballScene), [&"Spell", &"Projectile", &"Fire"] as Array[StringName])


func test_attack_is_a_melee_attack() -> void:
	assert_eq(_tags_of(AttackScene), [&"Attack", &"Melee"] as Array[StringName])


func test_fireball_is_also_elemental() -> void:
	assert_has(Skill.with_implied(_tags_of(FireballScene)), &"Elemental")


func test_attack_is_not_elemental() -> void:
	assert_does_not_have(Skill.with_implied(_tags_of(AttackScene)), &"Elemental")


func test_replacing_fire_drops_elemental() -> void:
	var tags := _tags_of(FireballScene)
	tags[tags.find(&"Fire")] = &"Cold"
	assert_eq(Skill.with_implied(tags), [&"Spell", &"Projectile", &"Cold"] as Array[StringName])
