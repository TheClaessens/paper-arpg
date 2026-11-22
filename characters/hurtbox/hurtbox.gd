class_name Hurtbox
extends Area3D
## A Character's Hurtbox (see GLOSSARY.md): the part of it that Skills hit. Skills find it on the
## layers hostile to the Faction of the Character that has them (see around()), and the Character puts it on its own Faction's
## layer. A Hurtbox doesn't look for anything; a Hit that lands on it is reported up to the Character through
## `hit_taken`. Its statics are how Skills and the player find Hurtboxes in the world.

## A Hit landed on it, pushing along `direction` (a unit vector on the ground). The Character
## reads what the Hit does to it from `hit`.
signal hit_taken(hit: Hit, direction: Vector3)


## Takes `hit`, pushing along `direction`, and says whether it landed: off every layer (its
## Character has died) it misses, so a second Hit in the frame that killed the Character reports
## nothing. Hit.land() calls it on each Hurtbox, then plays the impact.
func take_hit(hit: Hit, direction: Vector3) -> bool:
	if collision_layer == 0:
		return false
	hit_taken.emit(hit, direction)
	return true


## The Hurtbox on the layers in `mask` nearest `spot` on the ground within `reach` of it, or
## null (see nearest_to()).
static func nearest(world: World3D, spot: Vector3, reach: float, mask: int) -> Hurtbox:
	var hurtboxes := around(world, spot, reach, mask)
	var positions: Array[Vector3] = []
	for hurtbox in hurtboxes:
		positions.append(hurtbox.global_position)
	var i := nearest_to(spot, positions, reach)
	return hurtboxes[i] if i >= 0 else null


## Which of `positions` is nearest `spot` on the ground and within `reach` of it, or -1.
static func nearest_to(spot: Vector3, positions: Array[Vector3], reach: float) -> int:
	var best := -1
	var best_distance := reach
	for i in positions.size():
		var distance := Vector2(positions[i].x - spot.x, positions[i].z - spot.z).length()
		if distance <= best_distance:
			best = i
			best_distance = distance
	return best


## Every Hurtbox in `world` on the layers in `mask` with any part of it within `reach` of
## `centre`. The physics engine finds them: the sphere looks for areas only, on `mask` only.
static func around(world: World3D, centre: Vector3, reach: float, mask: int) -> Array[Hurtbox]:
	var sphere := SphereShape3D.new()
	sphere.radius = reach
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = sphere
	query.transform = Transform3D(Basis.IDENTITY, centre + Vector3.UP * 0.5) # body height
	query.collision_mask = mask
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var hurtboxes: Array[Hurtbox] = []
	for result in world.direct_space_state.intersect_shape(query, 32):
		var hurtbox := result.collider as Hurtbox
		if hurtbox:
			hurtboxes.append(hurtbox)
	return hurtboxes
