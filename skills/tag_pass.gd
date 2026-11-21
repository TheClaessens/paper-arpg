class_name TagPass
extends RefCounted
## The tag pass (see GLOSSARY.md): works out a Skill's final tags from its own tags and the
## Character's Modifiers, and so which Modifiers apply.
##
## Modifiers with tag changes go first, in rounds: each round is every one whose filter matches the
## tags as they stand, applied together. Each applies at most once, and once applied it stays
## applied, with all its effects, even if a later round removes a tag its filter needs. Removal
## wins: a tag removed in the pass can't be added back, whichever Modifier comes first. Every
## other Modifier is judged on the final tags. Why it works this way: docs/adr/0003.

## The Skill's tags after the pass, implied ones included.
var tags: Array[StringName]

var _applied: Array[Modifier] = [] # the Modifiers with tag changes that applied
var _changes_made: Dictionary[Modifier, Array] = {} # the TagChanges each of _applied made
var _removed: Array[StringName] = [] # every tag removed in the pass


## Runs the pass on a Skill whose own tags are `own_tags`, with the Character's `modifiers`:
## round after round until no Modifier with tag changes is left whose filter matches.
func _init(own_tags: Array[StringName], modifiers: Array[Modifier]) -> void:
	var changers := modifiers.filter(func(m: Modifier) -> bool: return not m.tag_changes.is_empty())
	var working: Array[StringName] = own_tags.duplicate() # the tags so far, without implied ones
	while true:
		tags = Skill.with_implied(working)
		var matching := changers.filter(func(m: Modifier) -> bool:
			return m not in _applied and m.missing(tags).is_empty())
		if matching.is_empty():
			return
		var added: Array[StringName] = []
		for modifier: Modifier in matching:
			_applied.append(modifier)
			_changes_made[modifier] = []
			for change in modifier.tag_changes:
				if change.kind == TagChange.Kind.REPLACE and change.tag not in working:
					continue
				_changes_made[modifier].append(change)
				if change.removed():
					_removed.append(change.removed())
				if change.gained():
					added.append(change.gained())
		for tag in added:
			if tag not in working:
				working.append(tag)
		for tag in _removed:
			working.erase(tag)


## Whether `modifier` applies: it changed tags in the pass, or its filter matches the final tags.
func applies(modifier: Modifier) -> bool:
	return modifier in _applied or modifier.missing(tags).is_empty()


## One line saying whether `modifier` applied, what it did to the tags, and why not when it
## missed: "Projectiles pierce 2 Enemies: applied, adds Pierce", "…: missed, Pierce was
## removed", "…: missed, not Spell".
func explain(modifier: Modifier) -> String:
	if applies(modifier):
		var parts: Array[String] = ["applied"]
		for change: TagChange in _changes_made.get(modifier, []):
			parts.append(_describe(change))
		return "%s: %s" % [modifier.title, ", ".join(parts)]
	var lacking := modifier.missing(tags)
	var lost := lacking.filter(func(tag: StringName) -> bool: return tag in _removed)
	if not lost.is_empty():
		return "%s: missed, %s was removed" % [modifier.title, ", ".join(lost)]
	return "%s: missed, not %s" % [modifier.title, ", ".join(lacking)]


## What `change` did, as the end of the pass has it: "adds Pierce", "Pierce stays removed".
func _describe(change: TagChange) -> String:
	if change.gained() and change.gained() in _removed:
		return "%s stays removed" % change.gained()
	match change.kind:
		TagChange.Kind.ADD:
			return "adds %s" % change.tag
		TagChange.Kind.REPLACE:
			return "replaces %s with %s" % [change.tag, change.into]
	return "removes %s" % change.tag
