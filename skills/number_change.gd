class_name NumberChange
extends Resource
## One effect of a Modifier: a change to one of a Skill's numbers (see Skill.numbers()). A
## Skill that doesn't have the number ignores it.

## FLAT adds `amount` to the number. INCREASED adds `amount` percent, summed with every other
## Increased percentage on it. MORE changes it by `amount` percent on its own (Less is negative).
enum Kind { FLAT, INCREASED, MORE }

## Which number, as Skill.numbers() names it, such as Cooldown or Range.
@export var number: StringName
@export var kind := Kind.FLAT
## Flat: in the number's own unit. Increased and More: a percentage, so -50 halves.
@export var amount := 0.0
