class_name Controls
extends Node
## The player's Controls (see GLOSSARY.md): reads the keys and mouse, a controller and touch.
## The Player asks it each physics frame where the player walks and aims, and connects its
## signals to the Skill bar. The `use_skill_slot_1` to `_5` actions press and let go of the
## Skill slots; it knows the slots only by number.

## The player pressed the binding of `slot`.
signal slot_pressed(slot: int)
## The player let go of the binding of `slot`.
signal slot_released(slot: int)

## The input action that uses each Skill slot, the main slot first.
const SLOT_ACTIONS: Array[StringName] = [
	&"use_skill_slot_1", &"use_skill_slot_2", &"use_skill_slot_3", &"use_skill_slot_4", &"use_skill_slot_5",
]

var _cursor := Vector2.ZERO # mouse position in this viewport
var _mouse_leads := false


# _input, not _unhandled_input: the full-screen PixelatedView would claim mouse motion as GUI
# input first. The mouse leads Facing once it moves; the keys only walk. A gamepad stick or a
# touch takes Facing back from the mouse. A touch also moves the emulated mouse, which mustn't
# count as the mouse.
func _input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion and motion.device != InputEvent.DEVICE_ID_EMULATION:
		_cursor = motion.position
		_mouse_leads = true
	elif event is InputEventScreenTouch:
		_mouse_leads = false
	elif event is InputEventJoypadMotion:
		var stick := event as InputEventJoypadMotion
		if stick.axis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y, JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y] and absf(stick.axis_value) > 0.2:
			_mouse_leads = false


func _unhandled_input(event: InputEvent) -> void:
	var slot := slot_for(event, true)
	if slot != SkillBar.NONE:
		slot_pressed.emit(slot)
	slot = slot_for(event, false)
	if slot != SkillBar.NONE:
		slot_released.emit(slot)


## Which Skill slot `event` presses (or, with `pressed` false, lets go of): 0 for the main slot,
## 1 to 4 for the small ones, or SkillBar.NONE. Godot also turns every touch into a left click,
## which would use the main slot wherever a thumb lands, so those emulated clicks don't count.
static func slot_for(event: InputEvent, pressed: bool) -> int:
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		return SkillBar.NONE
	for slot in SLOT_ACTIONS.size():
		var action := SLOT_ACTIONS[slot]
		if event.is_action_pressed(action) if pressed else event.is_action_released(action):
			return slot
	return SkillBar.NONE


## Where the left stick or the keys walk, as a unit direction on the ground, or zero.
func move_direction() -> Vector3:
	return _stick_direction(&"move_left", &"move_right", &"move_up", &"move_down")


## Where the right stick aims, as a unit direction on the ground, or zero while it rests.
func aim_direction() -> Vector3:
	return _stick_direction(&"aim_left", &"aim_right", &"aim_up", &"aim_down")


## Whether the mouse leads Facing: it has moved since the last stick push or touch.
func leads_with_mouse() -> bool:
	return _mouse_leads


## The spot on the ground under the mouse cursor, at `height`, or null.
func cursor_on_ground(height: float) -> Variant:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return null
	var ground := Plane(Vector3.UP, height)
	return ground.intersects_ray(camera.project_ray_origin(_cursor), camera.project_ray_normal(_cursor))


## Screen right and screen down on the ground, in that order: the camera's right and back axes,
## flattened. Flattening each axis before mixing them keeps diagonals at 45° on the ground.
## With no camera (a test without one), the world's own right and back.
func ground_axes() -> Array[Vector3]:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return [Vector3.RIGHT, Vector3.BACK]
	var view := camera.global_basis
	return [Vector3(view.x.x, 0.0, view.x.z).normalized(), Vector3(view.z.x, 0.0, view.z.z).normalized()]


## A stick's pushed direction as a unit vector on the ground, or zero inside the deadzone.
## Direction only: any push past the deadzone counts in full, so the vector is normalised.
func _stick_direction(to_left: StringName, to_right: StringName, to_up: StringName, to_down: StringName) -> Vector3:
	# Deadzone comes from the actions in the Input Map (0.2).
	var input := Input.get_vector(to_left, to_right, to_up, to_down)
	var axes := ground_axes()
	return (axes[0] * input.x + axes[1] * input.y).normalized()
