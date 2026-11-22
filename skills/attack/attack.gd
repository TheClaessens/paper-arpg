@tool
class_name Attack
extends Skill
## The Attack (see GLOSSARY.md) with a sword: a swing along Facing that hits every hostile
## Hurtbox inside its Sweep and Range once. A white wedge flashes flat on the ground over that area.

## Closer than this, a Hurtbox is hit from any side: its body is pressed against its Character's.
const POINT_BLANK := 0.6
## How long the wedge on the ground takes to fade.
const SWING_FADE := 0.16

## The name of the Sweep among the Skill's numbers.
const SWEEP := &"Sweep"

## The Sweep: how wide the swing is, centred on where it is aimed.
@export_range(10.0, 360.0, 5.0, "suffix:°") var sweep := 120.0

@onready var _swing: MeshInstance3D = $Swing
@onready var _swing_material: ShaderMaterial = _swing.material_override


## Whether a Hurtbox at `offset` from its Character is inside the Sweep of a swing along `facing`.
## Only the angle: _activate() asks for the hostile Hurtboxes within Range first.
static func in_sweep(offset: Vector3, facing: Vector3, sweep_degrees: float) -> bool:
	var flat := Vector3(offset.x, 0.0, offset.z)
	if flat.length() < POINT_BLANK:
		return true
	return rad_to_deg(flat.angle_to(facing)) <= sweep_degrees / 2.0


func numbers() -> Dictionary[StringName, float]:
	var all := super()
	all[SWEEP] = sweep
	return all


func _activate(snapshot: Snapshot, aim: Vector3) -> void:
	var facing := aim.normalized()
	var swing_range := snapshot.number(RANGE)
	var swing_sweep := snapshot.number(SWEEP)
	_show_swing(facing, swing_range, swing_sweep)
	var pushes: Dictionary[Hurtbox, Vector3] = {}
	for hurtbox in Hurtbox.around(get_world_3d(), global_position, swing_range, hostile_mask()):
		var offset := hurtbox.global_position - global_position
		if in_sweep(offset, facing, swing_sweep):
			# Pushed straight away from its Character; one right on top goes along Facing.
			pushes[hurtbox] = Vector3(offset.x, 0.0, offset.z).normalized() if offset.length() > 0.01 else facing
	_hit(snapshot).land(pushes)


func _show_swing(facing: Vector3, swing_range: float, swing_sweep: float) -> void:
	_swing.basis = Basis.looking_at(facing).scaled(Vector3.ONE * swing_range)
	_swing_material.set_shader_parameter("half_sweep", deg_to_rad(swing_sweep) / 2.0)
	var fade := _swing.create_tween()
	fade.tween_method(func(alpha: float) -> void: _swing_material.set_shader_parameter("alpha", alpha), 0.55, 0.0, SWING_FADE)
