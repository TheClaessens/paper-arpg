class_name Hurtbox
extends Area3D
## A Character's Hurtbox (see GLOSSARY.md): the part of it that Skills hit. Skills find it on the
## layers hostile to their Faction, and the Character puts it on its own Faction's layer. It
## doesn't look for anything itself; a hit is reported up to the Character through `hit_taken`.

## A Skill hit it: pushing along `direction` (a unit vector on the ground), with the Damage,
## Knockback and Stagger of the activation's `snapshot` for the Character to read.
signal hit_taken(direction: Vector3, snapshot: Snapshot)


## Hit by a Skill's activation made as `snapshot`, pushing along `direction`.
func take_hit(direction: Vector3, snapshot: Snapshot) -> void:
	hit_taken.emit(direction, snapshot)
