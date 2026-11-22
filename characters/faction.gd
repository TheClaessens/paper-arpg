class_name Faction
## The Factions (see GLOSSARY.md). Not a node: a Character holds its Faction's Id, puts its
## Hurtbox on that Faction's layer, and its Skills look on hostile_mask(). The Hurtbox layers are
## their own, apart from the body layers, so a body is never hit.

## Which Faction a Character is of.
enum Id { PLAYER, ENEMIES }

const _LAYERS: Dictionary[Id, int] = {
	Id.PLAYER: 1 << 3, # layer 4, `player_hurtbox`
	Id.ENEMIES: 1 << 4, # layer 5, `enemy_hurtbox`
}


## The collision layer bit of the Hurtboxes of `faction`.
static func layer(faction: Id) -> int:
	return _LAYERS[faction]


## The layers of every Faction hostile to `faction`: every other Faction's.
static func hostile_mask(faction: Id) -> int:
	var mask := 0
	for other in _LAYERS:
		if other != faction:
			mask |= _LAYERS[other]
	return mask
