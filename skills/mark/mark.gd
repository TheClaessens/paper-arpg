class_name Mark
extends Skill
## Mark, a throwaway test Skill (see .scratch/aiming/spec.md): aimed at a spot, it marks the Enemy
## nearest where it lands, tinting it for a while. No damage, no cooldown.

## How close to the spot an Enemy must be to be marked.
const REACH := 1.5
## How long a mark lasts.
const MARK_TIME := 3.0


func use(aim: Vector3) -> void:
	var enemy := target_for(aim) as Enemy
	if enemy:
		enemy.mark(MARK_TIME)


## The Enemy a use aimed at `aim` would mark, or null.
func target_for(aim: Vector3) -> Node3D:
	var spot := global_position + Vector3(aim.x, 0.0, aim.z).limit_length(range)
	return enemy_nearest(get_world_3d(), spot, REACH)
