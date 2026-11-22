class_name Hit
extends RefCounted
## A Hit (see GLOSSARY.md): what one activation of a Skill does to each Hurtbox it reaches. The
## Skill makes it with Skill._hit() and lands it with land(), the same Hit on every Hurtbox the
## activation reaches. So it never changes: its fields can't be replaced, and each Character hit
## works out from it what it does to them and writes nothing back.

## The activation's Snapshot: the Character hit reads Damage, Knockback and Stagger from it.
var snapshot: Snapshot:
	get:
		return _snapshot
	set(_value):
		assert(false, "A Hit never changes")
## The Character that dealt it, or null: none was given, or that Character has been freed since
## (an Enemy is, once it has sunk). Never a freed Character.
var dealer: Character:
	get:
		return _dealer.get_ref() as Character
	set(_value):
		assert(false, "A Hit never changes")
## Whether its impact freezes the world. A projectile's doesn't.
var freezes: bool:
	get:
		return _freezes
	set(_value):
		assert(false, "A Hit never changes")

var _snapshot: Snapshot
var _dealer: WeakRef # a freed dealer reads as null: a typed getter can't return a freed one
var _freezes: bool


## A Hit made as `hit_snapshot`, dealt by `hit_dealer` (or null for none), whose impact freezes
## the world if `hit_freezes`. Skills make theirs with Skill._hit().
func _init(hit_snapshot: Snapshot, hit_dealer: Character, hit_freezes: bool) -> void:
	_snapshot = hit_snapshot
	_dealer = weakref(hit_dealer) # an empty WeakRef for null
	_freezes = hit_freezes


## Lands it on each Hurtbox in `pushes`, pushing each along its direction (a unit vector on the
## ground), and says whether it landed on any: a Hurtbox off every layer (its Character has died)
## misses. If it landed on an Enemy, the impact plays once, however many it landed on: the screen
## shakes, and the world freezes if `freezes`. On any other Character it shows only on that
## Character (see Character._on_hit_taken()), and the game keeps running.
func land(pushes: Dictionary[Hurtbox, Vector3]) -> bool:
	var landed := false
	var impact_viewport: Viewport = null # the viewport of an Enemy's Hurtbox it landed on
	for hurtbox in pushes:
		# Asked before it lands: the killing Hit takes its Enemy's Hurtbox off every layer.
		var on_enemy := hurtbox.collision_layer & Faction.layer(Faction.Id.ENEMIES) != 0
		if hurtbox.take_hit(self, pushes[hurtbox]):
			landed = true
			if on_enemy:
				impact_viewport = hurtbox.get_viewport()
	if impact_viewport:
		HitFeedback.shared().play_impact(impact_viewport, freezes)
	return landed
