class_name Player
extends CharacterBody3D
## The player's Character (see GLOSSARY.md). Walks where the left stick or the keys point,
## relative to the camera: pushing up walks up the screen.

## The player's Facing (see GLOSSARY.md): a unit direction on the ground. It follows the stick
## or keys, or the mouse cursor while the mouse was the last thing used.
var facing := Vector3.RIGHT

var _cursor := Vector2.ZERO # mouse position in this viewport
var _aim_with_mouse := false

@onready var _movement: Movement = $Movement
@onready var _standee: Standee = $Standee
@onready var _facing_arrow: Node3D = $FacingArrow


func _ready() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera:
		facing = Vector3(camera.global_basis.x.x, 0.0, camera.global_basis.x.z).normalized() # screen right


# Registered while in the tree, so a reloaded scene's new Player takes the command over.
func _enter_tree() -> void:
	Console.register(&"tp", _cmd_tp, "tp <x> <z>: move the player to a spot on the ground.")


func _cmd_tp(args: PackedStringArray) -> String:
	if args.size() != 2 or not args[0].is_valid_float() or not args[1].is_valid_float():
		return "Usage: tp <x> <z>"
	global_position = Vector3(args[0].to_float(), 0.0, args[1].to_float())
	velocity = Vector3.ZERO
	return "tp %s %s" % [args[0], args[1]]


## The Facing from `from` toward `to`, flattened onto the ground. A point right under `from`
## gives no direction, so `current` is kept.
static func facing_toward(from: Vector3, to: Vector3, current: Vector3) -> Vector3:
	var flat := Vector3(to.x - from.x, 0.0, to.z - from.z)
	return current if flat.length() < 0.05 else flat.normalized()


# _input, not _unhandled_input: the full-screen PixelatedView would claim mouse motion as GUI
# input first. A touch also moves the emulated mouse, which mustn't steal Facing from the stick.
func _input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion and motion.device != InputEvent.DEVICE_ID_EMULATION:
		_cursor = motion.position
		_aim_with_mouse = true


func _physics_process(delta: float) -> void:
	var direction := _input_direction()
	velocity = _movement.next_velocity(velocity, direction, delta)
	move_and_slide()
	if not direction.is_zero_approx():
		_aim_with_mouse = false # the stick or keys take Facing back
		facing = direction
	elif _aim_with_mouse:
		facing = _facing_toward_cursor()
	_facing_arrow.basis = Basis.looking_at(facing)
	_standee.face(facing)
	_standee.play(&"idle" if velocity.is_zero_approx() else &"walk")


## Facing toward the ground under the mouse cursor, at the player's feet height.
func _facing_toward_cursor() -> Vector3:
	var camera := get_viewport().get_camera_3d()
	var ground := Plane(Vector3.UP, global_position.y)
	var hit: Variant = ground.intersects_ray(camera.project_ray_origin(_cursor), camera.project_ray_normal(_cursor))
	return facing if hit == null else facing_toward(global_position, hit as Vector3, facing)


## The pushed direction as a unit vector on the ground, or zero inside the deadzone.
## Direction only: any push past the deadzone means full speed, so the vector is normalised.
func _input_direction() -> Vector3:
	# Deadzone comes from the move_* actions in the Input Map (0.2).
	var input := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	# Screen right and screen down on the ground: the camera's right and back axes, flattened.
	# Flattening each axis before mixing them keeps diagonals at 45° on the ground.
	var camera := get_viewport().get_camera_3d().global_basis
	var right := Vector3(camera.x.x, 0.0, camera.x.z).normalized()
	var back := Vector3(camera.z.x, 0.0, camera.z.z).normalized()
	return (right * input.x + back * input.y).normalized()
