class_name Health
extends Node
## A Character's Health (see GLOSSARY.md): how much more Damage it can take before it dies.
## It lies between 0 and its maximum. Damage or healing of 0 or less changes nothing, so only
## Damage brings it to 0. At 0 the Character is dead, and Health ignores Damage and
## healing from then on, so it dies once.

## Health went up or down: it is now `current` of `max_health`.
signal changed(current: float, max_health: float)
## Health reached 0. Emitted once.
signal died

## The most Health the Character can have. It starts with this much.
@export var max_health := 100.0

## How much Health the Character has now. Read only: damage() and heal() change it.
@onready var current := max_health


## Whether Health has reached 0.
func is_dead() -> bool:
	return current <= 0.0


## Takes `amount` of Damage, no lower than 0, and dies on reaching it. An amount of 0 or less
## does nothing: Damage never raises Health.
func damage(amount: float) -> void:
	if amount <= 0.0 or is_dead():
		return
	_set_current(current - amount)
	if is_dead():
		died.emit()


## Heals `amount`, no higher than the maximum. An amount of 0 or less does nothing: healing
## never lowers Health, so it can't bring Health to 0 without dying.
func heal(amount: float) -> void:
	if amount <= 0.0:
		return
	_set_current(current + amount)


## Moves Health to `value` within 0 and the maximum, unless it is dead or nothing would change.
func _set_current(value: float) -> void:
	value = clampf(value, 0.0, max_health)
	if is_dead() or value == current:
		return
	current = value
	changed.emit(current, max_health)
