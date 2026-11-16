class_name Mark
extends Skill
## Mark, a throwaway test Skill (see .scratch/aiming/spec.md): aimed at a spot, it marks the Enemy
## nearest where it lands, tinting it for a while. No damage, no cooldown.

## How close to the spot an Enemy must be to be marked.
const REACH := 1.5
## How long a mark lasts.
const MARK_TIME := 3.0


## Which of `enemies` (positions) is nearest `spot` on the ground and within `reach` of it, or -1.
static func nearest(spot: Vector3, enemies: Array[Vector3], reach: float) -> int:
	var best := -1
	var best_distance := reach
	for i in enemies.size():
		var distance := Vector2(enemies[i].x - spot.x, enemies[i].z - spot.z).length()
		if distance <= best_distance:
			best = i
			best_distance = distance
	return best


func use(aim: Vector3) -> void:
	var enemy := target_for(aim) as Enemy
	if enemy:
		enemy.mark(MARK_TIME)


## The Enemy a use aimed at `aim` would mark, or null.
func target_for(aim: Vector3) -> Node3D:
	var spot := global_position + Vector3(aim.x, 0.0, aim.z).limit_length(range)
	var enemies := _enemies_within(range + REACH)
	var positions: Array[Vector3] = []
	for enemy in enemies:
		positions.append(enemy.global_position)
	var i := nearest(spot, positions, REACH)
	return enemies[i] if i >= 0 else null
