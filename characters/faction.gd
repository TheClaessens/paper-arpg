class_name Faction
## The Factions (see GLOSSARY.md). Not a node: a Character holds its Faction, puts its Hurtbox
## on that Faction's layer, and its Skills look on hostile_mask(). The Hurtbox layers are their
## own, apart from the body layers, so a body is never hit.

## Written `Faction.Side` even in here: a bare `Side` is the engine's own enum (SIDE_LEFT, ...).
enum Side { PLAYER, ENEMIES }

const _LAYERS: Dictionary[Faction.Side, int] = {
	Side.PLAYER: 1 << 3, # layer 4, `player_hurtbox`
	Side.ENEMIES: 1 << 4, # layer 5, `enemy_hurtbox`
}


## The collision layer bit of the Hurtboxes of Faction `side`.
static func layer(side: Faction.Side) -> int:
	return _LAYERS[side]


## The layers of every Faction hostile to `side`: every other Faction's.
static func hostile_mask(side: Faction.Side) -> int:
	var mask := 0
	for other in _LAYERS:
		if other != side:
			mask |= _LAYERS[other]
	return mask
