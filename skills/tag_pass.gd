class_name TagPass
extends RefCounted
## The tag pass (see GLOSSARY.md): works out a Skill's final tags from its own tags and the
## Character's Modifiers, and so which Modifiers apply. Every filter is judged on the final tags.
##
## Modifiers with tag changes go first, in waves: each wave is every one whose filter matches the
## tags as they stand, applied together, each at most once. Removal wins: a tag removed in the pass
## can't be added back, whichever Modifier comes first. A Modifier that applied but whose filter
## misses the final tags (a tag it needs was removed) drops out and stays out, and the pass starts
## again without it. Each restart drops one more Modifier, so the pass always ends.

## The Skill's tags after the pass, implied ones included.
var tags: Array[StringName]

var _applied: Array[Modifier] = [] # the Modifiers with tag changes that applied
var _changes_made: Dictionary[Modifier, Array] = {} # the TagChanges each of _applied made
var _removed: Array[StringName] = [] # every tag removed in the pass
var _dropped: Dictionary[Modifier, Array] = {} # each Modifier that dropped out, and the tags it lost


func _init(given: Array[StringName], modifiers: Array[Modifier]) -> void:
	var changers := modifiers.filter(func(m: Modifier) -> bool: return not m.tag_changes.is_empty())
	while true:
		_run(given, changers)
		var dropped_any := false
		for modifier in _applied:
			var lost := _lost_by(modifier)
			if not lost.is_empty():
				_dropped[modifier] = lost
				dropped_any = true
		if not dropped_any:
			return


## Whether `modifier` applies: its filter matches the final tags, less the tags it removed
## itself, and it didn't drop out.
func applies(modifier: Modifier) -> bool:
	return modifier not in _dropped and (modifier in _applied or modifier.missing(tags).is_empty())


## One line saying whether `modifier` applied, what it did to the tags, and why not when it
## missed: "Projectiles pierce 2 Enemies: applied, adds Pierce", "…: dropped out, Pierce was
## removed", "…: missed, not Spell".
func explain(modifier: Modifier) -> String:
	if applies(modifier):
		var parts: Array[String] = ["applied"]
		for change: TagChange in _changes_made.get(modifier, []):
			parts.append(_describe(change))
		return "%s: %s" % [modifier.title, ", ".join(parts)]
	var lacking := modifier.missing(tags)
	var lost: Array = _dropped.get(modifier, lacking.filter(func(tag: StringName) -> bool: return tag in _removed))
	if not lost.is_empty():
		return "%s: dropped out, %s was removed" % [modifier.title, ", ".join(lost)]
	return "%s: missed, not %s" % [modifier.title, ", ".join(lacking)]


## The tags `modifier`'s filter needs that the final tags lack, other than those it removed
## itself: a Modifier that replaces Fire still filters on Fire.
func _lost_by(modifier: Modifier) -> Array[StringName]:
	var own_removals: Array[StringName] = []
	for change: TagChange in _changes_made[modifier]:
		own_removals.append(change.removed())
	var lost: Array[StringName] = []
	for tag in modifier.missing(tags):
		if tag not in own_removals:
			lost.append(tag)
	return lost


## One round of the pass from `given`, without the Modifiers that dropped out: wave after wave of
## `changers` until none is left whose filter matches.
func _run(given: Array[StringName], changers: Array) -> void:
	_applied.clear()
	_changes_made.clear()
	_removed.clear()
	var own: Array[StringName] = given.duplicate()
	while true:
		tags = Skill.with_implied(own)
		var wave := changers.filter(func(m: Modifier) -> bool:
			return m not in _applied and m not in _dropped and m.missing(tags).is_empty())
		if wave.is_empty():
			return
		var added: Array[StringName] = []
		for modifier: Modifier in wave:
			_applied.append(modifier)
			_changes_made[modifier] = []
			for change in modifier.tag_changes:
				if change.kind == TagChange.Kind.REPLACE and change.tag not in own:
					continue
				_changes_made[modifier].append(change)
				if change.removed():
					_removed.append(change.removed())
				if change.gained():
					added.append(change.gained())
		for tag in added:
			if tag not in own:
				own.append(tag)
		for tag in _removed:
			own.erase(tag)


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
