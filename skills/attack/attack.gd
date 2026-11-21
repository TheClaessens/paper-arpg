@tool
class_name Attack
extends Skill
## The Attack (see GLOSSARY.md) with a sword: a swing along Facing that hits every Enemy
## inside its Sweep and Range once. A white wedge flashes flat on the ground over that area.

## Closer than this, an Enemy is hit from any side: its body is pressed against the player's.
const POINT_BLANK := 0.6
## How long the wedge on the ground takes to fade.
const SWING_FADE := 0.16

## The Sweep: how wide the swing is, centred on where it is aimed.
@export_range(10.0, 360.0, 5.0, "suffix:°") var sweep := 120.0

@onready var _swing: MeshInstance3D = $Swing
@onready var _swing_material: ShaderMaterial = _swing.material_override


## Whether an Enemy at `offset` from the player is inside the Sweep of a swing along `facing`.
## Only the angle: use() asks for the Enemies within Range first.
static func in_sweep(offset: Vector3, facing: Vector3, sweep_degrees: float) -> bool:
	var flat := Vector3(offset.x, 0.0, offset.z)
	if flat.length() < POINT_BLANK:
		return true
	return rad_to_deg(flat.angle_to(facing)) <= sweep_degrees / 2.0


func use(aim: Vector3) -> void:
	var facing := aim.normalized()
	_show_swing(facing)
	var hits: Dictionary[Enemy, Vector3] = {}
	for enemy in _enemies_within(range):
		var offset := enemy.global_position - global_position
		if in_sweep(offset, facing, sweep):
			# Pushed straight away from the player; one right on top goes along Facing.
			hits[enemy] = Vector3(offset.x, 0.0, offset.z).normalized() if offset.length() > 0.01 else facing
	_land_hits(hits)


func _show_swing(facing: Vector3) -> void:
	_swing.basis = Basis.looking_at(facing).scaled(Vector3.ONE * range)
	_swing_material.set_shader_parameter("half_sweep", deg_to_rad(sweep) / 2.0)
	var fade := _swing.create_tween()
	fade.tween_method(func(alpha: float) -> void: _swing_material.set_shader_parameter("alpha", alpha), 0.55, 0.0, SWING_FADE)
