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

## The one table of implied Skill tags: a Skill with the key tag also has each tag it lists.
const IMPLIED_TAGS: Dictionary[StringName, Array] = {
	SkillTag.FIRE: [SkillTag.ELEMENTAL],
}

## The Skill's tags after the pass, implied ones included.
var tags: Array[StringName]

var _applied: Array[Modifier] = [] # the Modifiers with tag changes that applied
var _changes_made: Dictionary[Modifier, Array] = {} # the TagChanges each of _applied made
var _skipped: Dictionary[Modifier, Array] = {} # why each of _applied left a TagChange out
var _removed: Array[StringName] = [] # every tag removed in the pass


## Runs the pass on a Skill whose own tags are `own_tags`, with the Character's `modifiers`:
## round after round until no Modifier with tag changes is left whose filter matches.
func _init(own_tags: Array[StringName], modifiers: Array[Modifier]) -> void:
	var changers := modifiers.filter(func(m: Modifier) -> bool: return not m.tag_changes.is_empty())
	var working: Array[StringName] = own_tags.duplicate() # the tags so far, without implied ones
	while true:
		tags = with_implied(working)
		# ponytail: `in` scans over the Modifiers, here and in applies(), grow with the square of
		# their number; use a Dictionary as a set if a profile on the phone points here.
		var matching := changers.filter(func(m: Modifier) -> bool:
			return m not in _applied and m.missing(tags).is_empty())
		if matching.is_empty():
			return
		var added: Array[StringName] = []
		for modifier: Modifier in matching:
			_applied.append(modifier)
			_changes_made[modifier] = []
			_skipped[modifier] = []
			for change in modifier.tag_changes:
				var skip := _why_skip(change, working)
				if skip:
					_skipped[modifier].append(skip)
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


## `given` plus every tag IMPLIED_TAGS says they imply. Worked out from the tags given, so a
## set without Fire has no Elemental. One level deep: an implied tag implies nothing further.
static func with_implied(given: Array[StringName]) -> Array[StringName]:
	var all := given.duplicate()
	for tag in given:
		for implied: StringName in IMPLIED_TAGS.get(tag, []):
			if implied not in all:
				all.append(implied)
	return all


## Whether `modifier` applies: it changed tags in the pass, or its filter matches the final tags.
func applies(modifier: Modifier) -> bool:
	return modifier in _applied or modifier.missing(tags).is_empty()


## One line saying whether `modifier` applied, what it did to the tags, and why not when it
## missed: "Projectiles pierce an Enemy: applied, adds Pierce", "…: missed, Pierce was
## removed", "…: missed, not Spell".
func explain(modifier: Modifier) -> String:
	if applies(modifier):
		var parts: Array[String] = ["applied"]
		for change: TagChange in _changes_made.get(modifier, []):
			parts.append(_describe(change))
		for note: String in _skipped.get(modifier, []):
			parts.append(note)
		return "%s: %s" % [modifier.title, ", ".join(parts)]
	var lacking := modifier.missing(tags)
	var lost := lacking.filter(func(tag: StringName) -> bool: return tag in _removed)
	if not lost.is_empty():
		return "%s: missed, %s was removed" % [modifier.title, ", ".join(lost)]
	return "%s: missed, not %s" % [modifier.title, ", ".join(lacking)]


## Why `change` does nothing to a Skill whose tags so far are `working`, or empty when it acts.
## A Modifier can't change an implied tag directly, and a replace needs the tag it replaces.
static func _why_skip(change: TagChange, working: Array[StringName]) -> String:
	for implied: Array in IMPLIED_TAGS.values():
		for tag: StringName in [change.removed(), change.gained()]:
			if tag in implied:
				return "can't change %s, it comes from another tag" % tag
	if change.kind == TagChange.Kind.REPLACE and change.tag not in working:
		return "no %s to replace" % change.tag
	return ""


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
