class_name Attack
extends Skill
## The Attack (see GLOSSARY.md) with a sword: a swing along Facing that hits every Enemy
## inside its Sweep and Range once. A white wedge flashes flat on the ground over that area.

## Closer than this, an Enemy is hit from any side: its body is pressed against the player's.
const POINT_BLANK := 0.6
## How long the wedge on the ground takes to fade.
const SWING_FADE := 0.16

## The Sweep: how wide the swing is, centred on Facing.
@export_range(10.0, 360.0, 5.0, "suffix:°") var sweep := 120.0
## How big an Enemy's body is around its centre; the swing hits any part of it.
@export var body_radius := 0.25
## How the game shows the hit (game-wide, shared by every Skill).
@export var hit_feedback: HitFeedback

@onready var _swing: MeshInstance3D = $Swing
@onready var _swing_material: ShaderMaterial = _swing.material_override


## Whether an Enemy at `offset` from the player is inside a swing along `facing`.
static func in_sweep(offset: Vector3, facing: Vector3, sweep_degrees: float, swing_range: float, radius: float) -> bool:
	var flat := Vector3(offset.x, 0.0, offset.z)
	if flat.length() < POINT_BLANK:
		return true
	if flat.length() - radius > swing_range:
		return false
	return rad_to_deg(flat.angle_to(facing)) <= sweep_degrees / 2.0


func use(facing: Vector3) -> void:
	_show_swing(facing)
	var hit := false
	for enemy in _enemies_in_range():
		var offset := enemy.global_position - global_position
		if in_sweep(offset, facing, sweep, range, body_radius):
			var direction := Vector3(offset.x, 0.0, offset.z).normalized() if offset.length() > 0.01 else facing
			enemy.take_hit(direction, knockback, stagger)
			hit = true
	if hit:
		hit_feedback.play_impact(get_viewport()) # once per swing, however many it hits


## Every Enemy whose body is within Range, in any direction. The physics engine finds them:
## the sphere masks only the `enemy` layer.
func _enemies_in_range() -> Array[Enemy]:
	var sphere := SphereShape3D.new()
	sphere.radius = range + body_radius
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
	_swing.basis = Basis.looking_at(facing).scaled(Vector3.ONE * range)
	_swing_material.set_shader_parameter("half_sweep", deg_to_rad(sweep) / 2.0)
	var fade := _swing.create_tween()
	fade.tween_method(func(alpha: float) -> void: _swing_material.set_shader_parameter("alpha", alpha), 0.55, 0.0, SWING_FADE)
