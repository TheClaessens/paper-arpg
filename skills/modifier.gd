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
## Its effects on the Skill's tags. Its tag changes apply in the tag pass (see TagPass); its number changes stack with every other Modifier's.
@export var tag_changes: Array[TagChange] = []


## The tags of its filter that `tags` (implied ones already worked out) lack. Whether it
## applies is the tag pass's to say (see TagPass.applies()).
func missing(tags: Array[StringName]) -> Array[StringName]:
	var lacking: Array[StringName] = []
	for tag in filter:
		if tag not in tags:
			lacking.append(tag)
	return lacking

