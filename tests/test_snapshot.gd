extends GutTest
## Snapshots: each activation of a Skill is built from the Skill and its Character's Modifiers. A
## Modifier applies when its filter matches the Skill's tags (implied ones included), or always
## with no filter. Numbers stack flat, then Increased summed, then each More on its own.

const FireballScene := preload("res://skills/fireball/fireball.tscn")
const AttackScene := preload("res://skills/attack/attack.tscn")


## The Snapshot an activation of the Skill in `scene` would make with `modifiers`.
func _snapshot(scene: PackedScene, modifiers: Array[Modifier]) -> Snapshot:
	var skill: Skill = scene.instantiate()
	autofree(skill)
	return skill.snapshot(modifiers)


func _modifier(filter: Array[StringName], number: StringName, kind: NumberChange.Kind, amount: float) -> Modifier:
	var change := NumberChange.new()
	change.number = number
	change.kind = kind
	change.amount = amount
	var modifier := Modifier.new()
	modifier.title = "test"
	modifier.filter = filter
	modifier.number_changes = [change]
	return modifier


func test_a_spell_filter_applies_to_fireball_and_not_to_attack() -> void:
	var halved := _modifier([&"Spell"], Skill.COOLDOWN, NumberChange.Kind.INCREASED, -50.0)
	assert_eq(_snapshot(FireballScene, [halved]).number(Skill.COOLDOWN), 2.0)
	assert_eq(_snapshot(AttackScene, [halved]).number(Skill.COOLDOWN), 0.4)


func test_no_filter_applies_to_every_skill() -> void:
	var halved := _modifier([], Skill.COOLDOWN, NumberChange.Kind.INCREASED, -50.0)
	assert_eq(_snapshot(FireballScene, [halved]).number(Skill.COOLDOWN), 2.0)
	assert_almost_eq(_snapshot(AttackScene, [halved]).number(Skill.COOLDOWN), 0.2, 0.0001)


func test_flat_then_increased_summed_then_each_more() -> void:
	var snapshot := _snapshot(FireballScene, [
		_modifier([], Skill.RANGE, NumberChange.Kind.FLAT, 2.0),
		_modifier([], Skill.RANGE, NumberChange.Kind.INCREASED, 20.0),
		_modifier([], Skill.RANGE, NumberChange.Kind.INCREASED, 10.0),
		_modifier([], Skill.RANGE, NumberChange.Kind.MORE, 50.0),
	])
	assert_almost_eq(snapshot.number(Skill.RANGE), 23.4, 0.0001, "(10 + 2) × 1.3 × 1.5")


func test_no_modifier_takes_a_number_below_zero() -> void:
	var snapshot := _snapshot(FireballScene, [
		_modifier([], Skill.COOLDOWN, NumberChange.Kind.INCREASED, -150.0),
		_modifier([], Skill.RANGE, NumberChange.Kind.MORE, -150.0),
	])
	assert_eq(snapshot.number(Skill.COOLDOWN), 0.0, "Increased stops at -100%")
	assert_eq(snapshot.number(Skill.RANGE), 0.0, "so does each More")


func test_a_number_as_it_stands_now_follows_the_modifiers() -> void:
	var fireball: Skill = FireballScene.instantiate()
	autofree(fireball)
	var halved := _modifier([&"Spell"], Skill.COOLDOWN, NumberChange.Kind.INCREASED, -50.0)
	assert_eq(fireball.number(Skill.COOLDOWN, []), 4.0)
	assert_eq(fireball.number(Skill.COOLDOWN, [halved]), 2.0)


func test_a_number_the_skill_does_not_have_is_ignored() -> void:
	var snapshot := _snapshot(FireballScene, [_modifier([], Attack.SWEEP, NumberChange.Kind.FLAT, 30.0)])
	assert_false(snapshot.numbers.has(Attack.SWEEP))
	assert_eq(snapshot.number(Skill.RANGE), 10.0)


func test_the_snapshot_says_why_each_modifier_applied_or_missed() -> void:
	var spells := _modifier([&"Spell"], Skill.COOLDOWN, NumberChange.Kind.INCREASED, -50.0)
	spells.title = "Spells have 50% reduced cooldown"
	var elemental := _modifier([&"Elemental"], Skill.RANGE, NumberChange.Kind.FLAT, 1.0)
	elemental.title = "Elemental Skills have +1 Range"
	assert_eq(_snapshot(AttackScene, [spells, elemental]).why, [
		"Spells have 50% reduced cooldown: missed, not Spell",
		"Elemental Skills have +1 Range: missed, not Elemental",
	] as Array[String])
	assert_eq(_snapshot(FireballScene, [spells, elemental]).why, [
		"Spells have 50% reduced cooldown: applied",
		"Elemental Skills have +1 Range: applied",
	] as Array[String], "Elemental is implied by Fire")


func test_a_snapshot_never_changes() -> void:
	var snapshot := _snapshot(FireballScene, [])
	assert_true(snapshot.numbers.is_read_only(), "writing to it is an engine error")
	assert_true(snapshot.tags.is_read_only())
	assert_true(snapshot.why.is_read_only())


## A test Modifier with `filter` and one tag change of `kind` on `tag` (into `into` when it replaces).
func _tagger(title: String, filter: Array[StringName], kind: TagChange.Kind, tag: StringName, into: StringName = &"") -> Modifier:
	var change := TagChange.new()
	change.kind = kind
	change.tag = tag
	change.into = into
	var modifier := Modifier.new()
	modifier.title = title
	modifier.filter = filter
	modifier.tag_changes = [change]
	return modifier


func test_an_added_tag_lets_another_modifier_match() -> void:
	var chains := _modifier([&"Chain"], Skill.RANGE, NumberChange.Kind.FLAT, 1.0)
	var snapshot := _snapshot(FireballScene, [chains, _tagger("chain", [&"Projectile"], TagChange.Kind.ADD, &"Chain")])
	assert_has(snapshot.tags, &"Chain")
	assert_eq(snapshot.number(Skill.RANGE), 11.0, "the Chain filter is judged after the tag is added")


func test_replacing_fire_with_a_non_elemental_tag_drops_elemental() -> void:
	var elemental := _modifier([&"Elemental"], Skill.RANGE, NumberChange.Kind.FLAT, 1.0)
	elemental.title = "Elemental Skills have +1 Range"
	var snapshot := _snapshot(FireballScene, [_tagger("Fire spells are now Holy", [&"Fire"], TagChange.Kind.REPLACE, &"Fire", &"Holy"), elemental])
	assert_eq(snapshot.tags, [&"Spell", &"Projectile", &"Holy"] as Array[StringName])
	assert_eq(snapshot.number(Skill.RANGE), 10.0)
	assert_eq(snapshot.why, [
		"Fire spells are now Holy: applied, replaces Fire with Holy",
		"Elemental Skills have +1 Range: missed, not Elemental",
	] as Array[String], "Elemental went with Fire")


func test_a_removed_tag_cannot_be_added_back_whichever_comes_first() -> void:
	var adds := _tagger("Projectiles pierce 2 Enemies", [&"Projectile"], TagChange.Kind.ADD, &"Pierce")
	var removes := _tagger("Spells can no longer pierce", [&"Spell"], TagChange.Kind.REMOVE, &"Pierce")
	assert_does_not_have(_snapshot(FireballScene, [adds, removes]).tags, &"Pierce")
	assert_does_not_have(_snapshot(FireballScene, [removes, adds]).tags, &"Pierce")
	assert_eq(_snapshot(FireballScene, [adds, removes]).why, [
		"Projectiles pierce 2 Enemies: applied, Pierce stays removed",
		"Spells can no longer pierce: applied, removes Pierce",
	] as Array[String])


func test_skills_that_chain_can_no_longer_pierce() -> void:
	var chains := _tagger("Projectiles chain", [&"Projectile"], TagChange.Kind.ADD, &"Chain")
	var pierces := _tagger("Projectiles pierce 2 Enemies", [&"Projectile"], TagChange.Kind.ADD, &"Pierce")
	var no_pierce := _tagger("Skills that chain can no longer pierce", [&"Chain"], TagChange.Kind.REMOVE, &"Pierce")
	var piercing := _modifier([&"Pierce"], Skill.RANGE, NumberChange.Kind.FLAT, 1.0)
	piercing.title = "Piercing Skills have +1 Range"
	var snapshot := _snapshot(FireballScene, [piercing, no_pierce, pierces, chains])
	assert_does_not_have(snapshot.tags, &"Pierce", "a chaining Fireball doesn't pierce")
	assert_eq(snapshot.number(Skill.RANGE), 10.0, "anything needing Pierce misses")
	assert_eq(snapshot.why[0], "Piercing Skills have +1 Range: dropped out, Pierce was removed")


func test_two_modifiers_that_switch_each_other_off_and_on_still_end() -> void:
	var to_holy := _tagger("Fire Skills are Holy", [&"Fire"], TagChange.Kind.ADD, &"Holy")
	var unfire := _tagger("Holy Skills are not Fire", [&"Holy"], TagChange.Kind.REMOVE, &"Fire")
	var snapshot := _snapshot(FireballScene, [to_holy, unfire])
	assert_eq(snapshot.tags, [&"Spell", &"Projectile", &"Fire", &"Elemental"] as Array[StringName], "neither applies in the end")
	assert_eq(snapshot.why, [
		"Fire Skills are Holy: dropped out, Fire was removed",
		"Holy Skills are not Fire: missed, not Holy",
	] as Array[String])


func test_tag_changes_come_before_number_changes() -> void:
	var piercing := _modifier([&"Pierce"], Skill.COOLDOWN, NumberChange.Kind.INCREASED, -50.0)
	var snapshot := _snapshot(FireballScene, [piercing, _tagger("pierce", [&"Projectile"], TagChange.Kind.ADD, &"Pierce")])
	assert_eq(snapshot.number(Skill.COOLDOWN), 2.0, "the granted Pierce is there when numbers are worked out")


func test_a_tag_changer_applies_its_number_changes_too() -> void:
	var pierces := _tagger("pierce", [&"Projectile"], TagChange.Kind.ADD, &"Pierce")
	var change := NumberChange.new()
	change.number = Skill.RANGE
	change.amount = 2.0
	pierces.number_changes = [change]
	assert_eq(_snapshot(FireballScene, [pierces]).number(Skill.RANGE), 12.0)


func test_a_tag_changers_number_changes_are_a_pool_of_their_own() -> void:
	var pierces := _tagger("pierce", [&"Projectile"], TagChange.Kind.ADD, &"Pierce")
	var change := NumberChange.new()
	change.number = Skill.RANGE
	change.kind = NumberChange.Kind.INCREASED
	change.amount = 50.0
	pierces.number_changes = [change]
	var snapshot := _snapshot(FireballScene, [_modifier([], Skill.RANGE, NumberChange.Kind.FLAT, 2.0), pierces])
	assert_eq(snapshot.number(Skill.RANGE), 17.0, "10 × 1.5, then + 2")
