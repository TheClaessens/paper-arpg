class_name Modifier
extends Resource
## A Modifier (see GLOSSARY.md): an optional filter on Skill tags plus its effects. It applies to
## a Skill that has every tag in its filter, or to every Skill when the filter is empty.

## What it says, as the player would read it: "Spells have 50% reduced cooldown".
@export var title := ""
## The Skill tags a Skill needs, all of them, for this to apply. Empty: every Skill.
@export var filter: Array[StringName] = []
## Its effects on the Skill's numbers.
@export var number_changes: Array[NumberChange] = []


## The tags of its filter that `tags` (implied ones already worked out) lack. It applies to a
## Skill with `tags` when there are none.
func missing(tags: Array[StringName]) -> Array[StringName]:
	var lacking: Array[StringName] = []
	for tag in filter:
		if tag not in tags:
			lacking.append(tag)
	return lacking


## One line saying whether it applies to a Skill with `tags`, and why not when it misses:
## "Spells have 50% reduced cooldown: missed, not Spell".
func explain(tags: Array[StringName]) -> String:
	var lacking := missing(tags)
	return "%s: applied" % title if lacking.is_empty() else "%s: missed, not %s" % [title, ", ".join(lacking)]
