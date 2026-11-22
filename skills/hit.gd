class_name Hit
extends RefCounted
## A Hit (see GLOSSARY.md): what one activation of a Skill does to each Hurtbox it reaches. The
## Skill makes it with Skill._hit() and lands it with land(), the same Hit on every Hurtbox the
## activation reaches. Each Character hit works out from it what it does to them and writes
## nothing back.

## The activation's Snapshot: the Character hit reads Damage, Knockback and Stagger from it.
var snapshot: Snapshot
## The Character that dealt it, or null in a Hit made without one.
var dealer: Character
## Whether its impact freezes the world. A projectile's doesn't.
var freezes: bool


## A Hit made as `hit_snapshot`, dealt by `hit_dealer` (or null for none), whose impact freezes
## the world if `hit_freezes`. Skills make theirs with Skill._hit().
func _init(hit_snapshot: Snapshot, hit_dealer: Character, hit_freezes: bool) -> void:
	snapshot = hit_snapshot
	dealer = hit_dealer
	freezes = hit_freezes


## Lands it on each Hurtbox in `pushes`, pushing each along its direction (a unit vector on the
## ground), and says whether it landed on any: a Hurtbox off every layer (its Character has died)
## misses. The impact plays once, however many it landed on: the screen shakes, and the world
## freezes if `freezes`.
func land(pushes: Dictionary[Hurtbox, Vector3]) -> bool:
	var landed := false
	var impact_viewport: Viewport = null # the viewport of a Hurtbox it landed on
	for hurtbox in pushes:
		if hurtbox.take_hit(self, pushes[hurtbox]):
			landed = true
			impact_viewport = hurtbox.get_viewport()
	if impact_viewport:
		HitFeedback.shared().play_impact(impact_viewport, freezes)
	return landed
