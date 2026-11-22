class_name AimMarker
extends Node3D
## Shows on the ground where a Skill would go while it is aimed by hand: a ring at its Range,
## then a line for a Skill that goes a direction or a ring for one that lands on a spot, and a
## ring on whatever it would pick out. Grey while the aim is about to be cancelled.

const AIM_COLOR := Color(1.0, 0.82, 0.48, 0.9)
const CANCEL_COLOR := Color(0.6, 0.63, 0.7, 0.7)
## How wide the Range ring's line is.
const RING_WIDTH := 0.07

@onready var _material: StandardMaterial3D = ($RangeRing as MeshInstance3D).material_override
@onready var _ring: TorusMesh = ($RangeRing as MeshInstance3D).mesh
@onready var _line: Node3D = $Line
@onready var _spot: Node3D = $Spot
@onready var _target: Node3D = $Target


func _ready() -> void:
	hide()


## Shows `skill` aimed at `aim`, an offset on the ground from the Character, with its Range
## ring at `reach`: its Range as it stands now.
func show_aim(skill: Skill, aim: Vector3, reach: float, cancelling: bool) -> void:
	show()
	_material.albedo_color = CANCEL_COLOR if cancelling else AIM_COLOR
	_ring.outer_radius = reach
	_ring.inner_radius = reach - RING_WIDTH
	var flat := Vector3(aim.x, 0.0, aim.z)
	_spot.visible = skill.aims_at_spot
	_line.visible = not skill.aims_at_spot and flat.length() > 0.01
	if _spot.visible:
		_spot.position = flat
	elif _line.visible:
		# Stretched along its own length (scaled() would stretch along the world's axes).
		_line.basis = Basis.looking_at(flat.normalized()) * Basis.from_scale(Vector3(1.0, 1.0, flat.length()))
	var target := null if cancelling else skill.target_for(aim)
	_target.visible = target != null
	if target:
		_target.global_position = target.global_position + Vector3.UP * position.y
