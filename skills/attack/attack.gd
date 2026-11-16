class_name Attack
extends Skill
## The Attack (see GLOSSARY.md) with a sword: a swing in an arc along Facing that hits every
## Enemy inside it once. A white arc flashes flat on the ground over the area it covers.

## Closer than this, an Enemy is hit from any side: its body is pressed against the player's.
const POINT_BLANK := 0.6
## How long the arc on the ground takes to fade.
const SWING_FADE := 0.16

## How wide the swing is, centred on Facing.
@export_range(10.0, 360.0, 5.0, "suffix:°") var arc := 120.0
## How far the swing reaches from the player's centre, in world units.
@export var reach := 1.6
## How big an Enemy's body is around its centre; the swing hits any part of it.
@export var body_radius := 0.25
@export var hit_feedback: HitFeedback

@onready var _swing: MeshInstance3D = $Swing
@onready var _swing_material: ShaderMaterial = _swing.material_override


## Whether an Enemy at `offset` from the player is inside a swing along `facing`.
static func in_arc(offset: Vector3, facing: Vector3, arc_degrees: float, swing_reach: float, radius: float) -> bool:
	var flat := Vector3(offset.x, 0.0, offset.z)
	if flat.length() < POINT_BLANK:
		return true
	if flat.length() - radius > swing_reach:
		return false
	return rad_to_deg(flat.angle_to(facing)) <= arc_degrees / 2.0


func use(facing: Vector3) -> void:
	_show_swing(facing)
	var hit := false
	for enemy in _enemies_in_reach():
		var offset := enemy.global_position - global_position
		if in_arc(offset, facing, arc, reach, body_radius):
			enemy.take_hit(Vector3(offset.x, 0.0, offset.z).normalized() if offset.length() > 0.01 else facing)
			hit = true
	if hit:
		hit_feedback.play_impact(get_viewport()) # once per swing, however many it hits


## Every Enemy whose body is within reach, in any direction. The physics engine finds them:
## the sphere masks only the `enemy` layer.
func _enemies_in_reach() -> Array[Enemy]:
	var sphere := SphereShape3D.new()
	sphere.radius = reach + body_radius
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = sphere
	query.transform = Transform3D(Basis.IDENTITY, global_position + Vector3.UP * 0.5) # body height
	query.collision_mask = 1 << 2 # layer 3, `enemy`
	var enemies: Array[Enemy] = []
	for result in get_world_3d().direct_space_state.intersect_shape(query, 32):
		var enemy := result.collider as Enemy
		if enemy:
			enemies.append(enemy)
	return enemies


func _show_swing(facing: Vector3) -> void:
	_swing.basis = Basis.looking_at(facing).scaled(Vector3.ONE * reach)
	_swing_material.set_shader_parameter("half_arc", deg_to_rad(arc) / 2.0)
	var fade := _swing.create_tween()
	fade.tween_method(func(alpha: float) -> void: _swing_material.set_shader_parameter("alpha", alpha), 0.55, 0.0, SWING_FADE)
