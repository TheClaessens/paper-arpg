class_name Snapshot
extends RefCounted
## A Snapshot (see GLOSSARY.md): a Skill with every Modifier that applied when it was
## activated. Skill.try_activate() makes one per activation, and everything the activation
## causes reads its numbers from it.
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


## The number called `name`, such as Cooldown or Range. Asking for one the Skill doesn't have
## is a bug in that Skill.
func number(name: StringName) -> float:
	assert(numbers.has(name), "The Snapshot has no number '%s'. It has: %s" % [name, numbers.keys()])
	return numbers[name]
