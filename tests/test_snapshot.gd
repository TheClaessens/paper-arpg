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
