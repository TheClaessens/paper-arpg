class_name Player
extends CharacterBody3D
## The player's Character (see GLOSSARY.md). Walks where the left stick or the keys point,
## relative to the camera: pushing up walks up the screen.

@onready var _movement: Movement = $Movement
@onready var _standee: Standee = $Standee


# Registered while in the tree, so a reloaded scene's new Player takes the command over.
func _enter_tree() -> void:
	Console.register(&"tp", _cmd_tp, "tp <x> <z>: move the player to a spot on the ground.")


func _exit_tree() -> void:
	Console.unregister(&"tp")


func _cmd_tp(args: PackedStringArray) -> String:
	if args.size() != 2 or not args[0].is_valid_float() or not args[1].is_valid_float():
		return "Usage: tp <x> <z>"
	global_position = Vector3(args[0].to_float(), 0.0, args[1].to_float())
	velocity = Vector3.ZERO
	return "tp %s %s" % [args[0], args[1]]


func _physics_process(delta: float) -> void:
	velocity = _movement.next_velocity(velocity, _input_direction(), delta)
	move_and_slide()
	if velocity.is_zero_approx():
		_standee.play(&"idle")
	else:
		_standee.play(&"walk")
		_standee.face(velocity)


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
