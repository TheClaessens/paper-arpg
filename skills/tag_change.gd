class_name TagChange
extends Resource
## One effect of a Modifier: a change to a Skill's tags, made in the tag pass (see TagPass). A
## Modifier changes an implied tag by changing the tag that implies it, not directly.

## ADD gives the Skill `tag`. REMOVE takes it away, and it can't come back in that activation.
## REPLACE does both when the Skill has `tag`: removes it and adds `into`.
enum Kind { ADD, REPLACE, REMOVE }

@export var kind := Kind.ADD
## The tag it adds, removes or replaces.
@export var tag: StringName
## What REPLACE puts in `tag`'s place; the others leave it empty.
@export var into: StringName


## The tag it takes away: REMOVE's and REPLACE's `tag`. Empty for ADD.
func removed() -> StringName:
	return &"" if kind == Kind.ADD else tag


## The tag it gives: ADD's `tag`, REPLACE's `into`. Empty for REMOVE.
func gained() -> StringName:
	match kind:
		Kind.ADD:
			return tag
		Kind.REPLACE:
			return into
	return &""
