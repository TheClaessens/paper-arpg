class_name Nova
extends Skill
## Nova, a throwaway test Skill (see .scratch/aiming/spec.md): used around the player, it knocks
## back every Enemy within its Range. A white disc flashes flat on the ground over that area.

## How long the disc takes to fade.
const FLASH_FADE := 0.25

@onready var _disc: MeshInstance3D = $Disc
@onready var _disc_material: ShaderMaterial = _disc.material_override


func use(_aim: Vector3) -> void:
	_disc.scale = Vector3.ONE * range
	var fade := _disc.create_tween()
	fade.tween_method(func(alpha: float) -> void: _disc_material.set_shader_parameter("alpha", alpha), 0.5, 0.0, FLASH_FADE)
	var hits: Dictionary[Enemy, Vector3] = {}
	for enemy in _enemies_within(range):
		var offset := enemy.global_position - global_position
		offset.y = 0.0
		hits[enemy] = offset.normalized() if offset.length() > 0.01 else Vector3.FORWARD
	_land_hits(hits)
