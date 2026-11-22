extends GutTest
## Content: every Skill in every scene and every Modifier file is well made: it names only Skill
## tags and numbers that exist, has a Cooldown above 0 and no empty effect, and TagPass.IMPLIED_TAGS
## is sound (see .scratch/content-checks/spec.md). The walk is the check's: the same function,
## LoadAll.find_files, with its own extensions, so a new folder is covered the day it exists. The
## problem functions are checked on hand-made broken Skills, Modifiers and a table, so they can't
## quietly stop reporting.

const LoadAll := preload("res://tools/load_all.gd")


func test_every_skill_and_modifier_file_is_well_made() -> void:
	var problems: Array[String] = []
	var numbers: Array[StringName] = [] # every number some Skill in some scene has
	var modifiers: Dictionary[String, Modifier] = {} # by path
	var skills_found := 0
	for path in LoadAll.find_files("res://", ["tscn", "tres"]):
		var resource := load(path)
		if resource == null:
			problems.append("%s: doesn't load" % path)
		elif resource is PackedScene:
			var root := (resource as PackedScene).instantiate()
			if root == null:
				problems.append("%s: doesn't instantiate" % path)
				continue
			for skill in _skills_in(root):
				skills_found += 1
				for number: StringName in skill.numbers().keys():
					if number not in numbers:
						numbers.append(number)
				for problem in _skill_problems(skill):
					var place := "" if skill == root else " › %s" % root.get_path_to(skill)
					problems.append("%s%s: %s" % [path, place, problem])
			root.free()
		elif resource is Modifier:
			modifiers[path] = resource as Modifier
	for path in modifiers:
		for problem in _modifier_problems(modifiers[path], numbers):
			problems.append("%s: %s" % [path, problem])
	for problem in _implied_problems(TagPass.IMPLIED_TAGS):
		problems.append("TagPass.IMPLIED_TAGS: %s" % problem)
	assert_gt(skills_found, 0, "found no Skill in any scene")
	assert_gt(modifiers.size(), 0, "found no Modifier file")
	assert_true(problems.is_empty(), "; ".join(problems))


func test_a_skill_in_a_scene_is_found_below_the_root() -> void:
	var root := Node.new()
	var middle := Node.new()
	var skill := Skill.new()
	root.add_child(middle)
	middle.add_child(skill)
	assert_eq(_skills_in(root), [skill] as Array[Skill])
	root.free()


func test_a_broken_skill_gives_a_problem_for_each_fault() -> void:
	var broken := Skill.new()
	broken.tags = [&"Projectiles", SkillTag.ELEMENTAL]
	broken.cooldown = 0.0
	var problems := _skill_problems(broken)
	assert_eq(problems.size(), 3, str(problems))
	_assert_says(problems, "tag 'Projectiles' is not a Skill tag")
	_assert_says(problems, "tag 'Elemental' is implied by another tag")
	_assert_says(problems, "Cooldown is 0")
	broken.free()
	var fine := Skill.new()
	fine.tags = [SkillTag.SPELL]
	fine.cooldown = 1.0
	assert_eq(_skill_problems(fine), [] as Array[String])
	fine.free()


func test_a_broken_modifier_gives_a_problem_for_each_fault() -> void:
	var broken := Modifier.new()
	broken.filter = [&"Projectiles"]
	broken.number_changes = [_number_change(&"Cooldwon"), null]
	broken.tag_changes = [
		_tag_change(TagChange.Kind.ADD, &"Peirce"),
		_tag_change(TagChange.Kind.ADD, SkillTag.ELEMENTAL),
		_tag_change(TagChange.Kind.REPLACE, SkillTag.FIRE),
		_tag_change(TagChange.Kind.REPLACE, SkillTag.FIRE, SkillTag.ELEMENTAL),
		_tag_change(TagChange.Kind.ADD, SkillTag.PIERCE, SkillTag.FIRE),
		null,
	]
	var problems := _modifier_problems(broken, [Skill.COOLDOWN])
	assert_eq(problems.size(), 9, str(problems))
	_assert_says(problems, "filter tag 'Projectiles' is not a Skill tag")
	_assert_says(problems, "changes number 'Cooldwon', which no Skill has")
	_assert_says(problems, "has an empty effect")
	_assert_says(problems, "tag change on 'Peirce' is not a Skill tag")
	_assert_says(problems, "tag change on 'Elemental' is implied by another tag")
	_assert_says(problems, "replaces Fire with nothing")
	_assert_says(problems, "the into 'Elemental' is implied by another tag")
	_assert_says(problems, "has an into (Fire) without replacing")
	# A Spell filter halving Cooldown, adding Melee and replacing Fire with Pierce.
	var fine := Modifier.new()
	fine.filter = [SkillTag.SPELL]
	var halve := _number_change(Skill.COOLDOWN)
	halve.kind = NumberChange.Kind.MORE
	halve.amount = -50.0
	fine.number_changes = [halve]
	fine.tag_changes = [
		_tag_change(TagChange.Kind.ADD, SkillTag.MELEE),
		_tag_change(TagChange.Kind.REPLACE, SkillTag.FIRE, SkillTag.PIERCE),
	]
	assert_eq(_modifier_problems(fine, [Skill.COOLDOWN]), [] as Array[String])


func test_an_implied_tag_that_implies_more_gives_a_problem() -> void:
	var table: Dictionary[StringName, Array] = {
		SkillTag.FIRE: [SkillTag.ELEMENTAL],
		SkillTag.ELEMENTAL: [SkillTag.SPELL],
	}
	var problems := _implied_problems(table)
	assert_eq(problems.size(), 1, str(problems))
	_assert_says(problems, "Elemental is implied by another tag and implies more")
	assert_eq(_implied_problems(TagPass.IMPLIED_TAGS), [] as Array[String])


func _assert_says(problems: Array[String], wording: String) -> void:
	var said := problems.any(func(line: String) -> bool: return line.contains(wording))
	assert_true(said, "no problem says '%s' in %s" % [wording, problems])


## Each problem with `skill` as its scene sets it (rules 1–3), one line each.
func _skill_problems(skill: Skill) -> Array[String]:
	var problems: Array[String] = []
	for tag in skill.tags:
		var tag_problem := _tag_problem(tag)
		if tag_problem:
			problems.append("tag '%s' %s" % [tag, tag_problem])
	if skill.cooldown <= 0.0:
		problems.append("Cooldown is %s, it needs one above 0" % skill.cooldown)
	return problems


## Each problem with `modifier`, where `numbers` holds every number some Skill has (rules 1, 4).
func _modifier_problems(modifier: Modifier, numbers: Array[StringName]) -> Array[String]:
	var problems: Array[String] = []
	for tag in modifier.filter:
		if tag not in SkillTag.ALL:
			problems.append("filter tag '%s' is not a Skill tag" % tag)
	for change in modifier.number_changes:
		if change == null:
			problems.append("has an empty effect")
		elif change.number not in numbers:
			problems.append("changes number '%s', which no Skill has" % change.number)
	for change in modifier.tag_changes:
		if change == null:
			problems.append("has an empty effect")
			continue
		var tag_problem := _tag_problem(change.tag)
		if tag_problem:
			problems.append("tag change on '%s' %s" % [change.tag, tag_problem])
		if change.kind == TagChange.Kind.REPLACE:
			var into_problem := _tag_problem(change.into)
			if change.into.is_empty():
				problems.append("replaces %s with nothing" % change.tag)
			elif into_problem:
				problems.append("replaces %s; the into '%s' %s" % [change.tag, change.into, into_problem])
		elif not change.into.is_empty():
			problems.append("has an into (%s) without replacing" % change.into)
	return problems


## Each tag in `table` that is implied and implies more (rule 5).
func _implied_problems(table: Dictionary[StringName, Array]) -> Array[String]:
	var problems: Array[String] = []
	for tag: StringName in table:
		if _is_implied(tag, table):
			problems.append("%s is implied by another tag and implies more, which would be dropped" % tag)
	return problems


## Every node of `node`'s tree, `node` included, that is a Skill.
func _skills_in(node: Node) -> Array[Skill]:
	var found: Array[Skill] = []
	if node is Skill:
		found.append(node as Skill)
	for child in node.get_children():
		found.append_array(_skills_in(child))
	return found


## Whether any tag in `table` implies `tag`, as TagPass reads it.
func _is_implied(tag: StringName, table: Dictionary[StringName, Array] = TagPass.IMPLIED_TAGS) -> bool:
	for implied: Array in table.values():
		if tag in implied:
			return true
	return false


## What is wrong with `tag` as a tag a Skill lists or a tag change names, or empty: not declared,
## or implied.
func _tag_problem(tag: StringName) -> String:
	if tag not in SkillTag.ALL:
		return "is not a Skill tag"
	if _is_implied(tag):
		return "is implied by another tag"
	return ""


func _number_change(number: StringName) -> NumberChange:
	var change := NumberChange.new()
	change.number = number
	return change


func _tag_change(kind: TagChange.Kind, tag: StringName, into: StringName = &"") -> TagChange:
	var change := TagChange.new()
	change.kind = kind
	change.tag = tag
	change.into = into
	return change
