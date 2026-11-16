class_name Skill
extends Node3D
## A Skill (see GLOSSARY.md): something the player uses from a Skill slot. Each Skill is a
## node on the Character, so it can reach the world from where the Character stands.
## Subclasses do the work in use().

## The Skill's name, as the player sees it.
@export var title := ""
## The Skill's picture on its Skill slot's button and in the Skill menu.
@export var icon: Texture2D
## The Skill's Use time: how long one use takes. The slot accepts no new use until it has passed.
@export var use_time := 0.4
## The Skill's Range: how far it reaches from the Character's centre, in world units.
@export var range := 1.0
## How far a hit pushes an Enemy, in world units.
@export var knockback := 0.0
## How long a hit Enemy slides without chasing (its Stagger), in seconds.
@export var stagger := 0.0


## Uses the Skill along `facing`, a unit direction on the ground.
func use(_facing: Vector3) -> void:
	pass


## Lands one use's hits: each Enemy in `hits` is pushed along its direction (a unit vector on
## the ground) with this Skill's knockback and Stagger. The impact (hitstop, screen shake)
## plays once for the whole use, however many Enemies it hit. For the Skills themselves.
func _land_hits(hits: Dictionary[Enemy, Vector3]) -> void:
	if hits.is_empty():
		return
	for enemy in hits:
		enemy.take_hit(hits[enemy], knockback, stagger)
	HitFeedback.shared().play_impact(get_viewport())
