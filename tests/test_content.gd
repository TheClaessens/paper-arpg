extends GutTest
## Content: every Skill in every scene and every Modifier file names only Skill tags and numbers
## that exist (see .scratch/content-checks/spec.md). The walk uses the check's own files, so a new
## folder is covered the day it exists. The problem functions are checked on hand-made broken
## Skills, Modifiers and a table, so they can't quietly stop reporting.

const LoadAll := preload("res://tools/load_all.gd")


func test_skills_and_modifier_files_name_only_what_exists() -> void:
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
					problems.append("%s › %s: %s" % [path, root.get_path_to(skill), problem])
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


func test_a_broken_skill_gives_a_problem_for_each_fault() -> void:
	var broken := Skill.new()
	broken.tags = [&"Projectiles", SkillTag.ELEMENTAL]
	broken.cooldown = 0.0
	assert_eq(_skill_problems(broken).size(), 3, str(_skill_problems(broken)))
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
	var fine := Modifier.new()
	fine.filter = [SkillTag.SPELL]
	fine.number_changes = [_number_change(Skill.COOLDOWN)]
	assert_eq(_modifier_problems(fine, [Skill.COOLDOWN]), [] as Array[String])


func test_an_implied_tag_that_implies_more_gives_a_problem() -> void:
	var table: Dictionary[StringName, Array] = {
		SkillTag.FIRE: [SkillTag.ELEMENTAL],
		SkillTag.ELEMENTAL: [SkillTag.SPELL],
	}
	assert_eq(_implied_problems(table).size(), 1, str(_implied_problems(table)))
	assert_eq(_implied_problems(TagPass.IMPLIED_TAGS), [] as Array[String])


## Each problem with `skill` as its scene sets it (rules 1–3), one line each.
func _skill_problems(skill: Skill) -> Array[String]:
	var problems: Array[String] = []
	for tag in skill.tags:
		if tag not in SkillTag.ALL:
			problems.append("tag '%s' is not a Skill tag" % tag)
		elif _is_implied(tag):
			problems.append("lists %s, which another tag implies" % tag)
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
			problems.append("has an empty effect slot")
		elif change.number not in numbers:
			problems.append("changes number '%s', which no Skill has" % change.number)
	for change in modifier.tag_changes:
		if change == null:
			problems.append("has an empty effect slot")
			continue
		var tag_problem := _tag_problem(change.tag)
		if tag_problem:
			problems.append("tag change on %s" % tag_problem)
		if change.kind == TagChange.Kind.REPLACE:
			if change.into.is_empty():
				problems.append("replaces %s with nothing" % change.tag)
			elif _tag_problem(change.into):
				problems.append("replaces %s into %s" % [change.tag, _tag_problem(change.into)])
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


## What is wrong with `tag` as a tag a tag change names, or empty: not declared, or implied.
func _tag_problem(tag: StringName) -> String:
	if tag not in SkillTag.ALL:
		return "'%s', which is not a Skill tag" % tag
	if _is_implied(tag):
		return "'%s', which another tag implies" % tag
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
