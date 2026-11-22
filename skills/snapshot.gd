class_name Snapshot
extends RefCounted
## A Snapshot (see GLOSSARY.md): a Skill with every Modifier that applied when it was
## activated. of() makes one; Skill.try_activate() asks for one per activation, and everything
## the activation causes reads its numbers from it.
## Its lists are read-only, so it never changes after it is made.

## The Skill's tags, implied ones included.
var tags: Array[StringName]
## Each of the Skill's numbers (see Skill.numbers()), with the Modifiers applied.
var numbers: Dictionary[StringName, float]
## One line per Modifier the Character has: whether it applied, and why not when it missed.
var why: Array[String]


func _init(snapshot_tags: Array[StringName], snapshot_numbers: Dictionary[StringName, float], snapshot_why: Array[String]) -> void:
	tags = snapshot_tags
	numbers = snapshot_numbers
	why = snapshot_why
	tags.make_read_only()
	numbers.make_read_only()
	why.make_read_only()


## The Snapshot of a Skill whose own tags are `own_tags` and own numbers `own_numbers`, with the
## Character's `modifiers`. The tag pass (see TagPass) settles the tags and which Modifiers
## apply; then the number changes apply in two pools, those of Modifiers that change tags first,
## then every other's (see docs/adr/0002). Each Modifier applies at most once, even if listed twice.
static func of(own_tags: Array[StringName], own_numbers: Dictionary[StringName, float], modifiers: Array[Modifier]) -> Snapshot:
	var tag_pass := TagPass.new(own_tags, modifiers)
	var tag_pool: Array[NumberChange] = []
	var number_pool: Array[NumberChange] = []
	var counted: Array[Modifier] = []
	var why: Array[String] = []
	for modifier in modifiers:
		why.append(tag_pass.explain(modifier))
		if modifier not in counted and tag_pass.applies(modifier):
			counted.append(modifier)
			(number_pool if modifier.tag_changes.is_empty() else tag_pool).append_array(modifier.number_changes)
	var result: Dictionary[StringName, float] = {}
	for name in own_numbers:
		result[name] = _stack(_stack(own_numbers[name], name, tag_pool), name, number_pool)
	return Snapshot.new(tag_pass.tags, result, why)


## The number called `name`, `value` at first, with each of `changes` to it: flat additions
## first, then the sum of every Increased percentage, then each More percentage on its own.
## Neither takes a number below 0: Increased stops at -100%, and so does each More.
static func _stack(value: float, name: StringName, changes: Array[NumberChange]) -> float:
	var increased := 0.0
	var more := 1.0
	for change in changes:
		if change.number != name:
			continue
		match change.kind:
			NumberChange.Kind.FLAT:
				value += change.amount
			NumberChange.Kind.INCREASED:
				increased += change.amount
			NumberChange.Kind.MORE:
				more *= maxf(0.0, 1.0 + change.amount / 100.0)
	return value * maxf(0.0, 1.0 + increased / 100.0) * more


## The number called `name`, such as Cooldown or Range. Asking for one the Skill doesn't have
## is a bug in that Skill.
func number(name: StringName) -> float:
	assert(numbers.has(name), "The Snapshot has no number '%s'. It has: %s" % [name, numbers.keys()])
	return numbers[name]
