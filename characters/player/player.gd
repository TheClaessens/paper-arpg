class_name Player
extends CharacterBody3D
## The player's Character (see GLOSSARY.md). Walks where the left stick or the keys point,
## relative to the camera: pushing up walks up the screen. The `use_skill_slot_1` to `_5`
## actions use the Skills on its Skill bar: at the mouse cursor, along the right stick while it
## is pushed, or else auto-aimed (see Skill.Aim).

## How far the card stretches when the player uses a Skill.
const USE_STRETCH := -0.15
## How near the mouse cursor's spot an Enemy must be to be highlighted.
const HOVER_REACH := 1.0
## How long the player keeps facing what a Skill was aimed at before the walk takes Facing back.
const FACE_AIM_TIME := 0.35

## The player's Facing (see GLOSSARY.md): a unit direction on the ground. It follows the right
## stick while that is pushed, the mouse cursor once the mouse moves, otherwise the movement.
var facing := Vector3.RIGHT

## The player's Skill bar.
var skill_bar: SkillBar:
	get:
		return $SkillBar

## The Skills the player has: every Skill node it holds.
var skills: Array[Skill]:
	get:
		var found: Array[Skill] = []
		for child in get_children():
			if child is Skill:
				found.append(child as Skill)
		return found

var _cursor := Vector2.ZERO # mouse position in this viewport
var _aim_with_mouse := false
var _aim_with_stick := false # the right stick is pushed
var _face_aim_left := 0.0 # time left facing the last use's aim

@onready var _movement: Movement = $Movement
@onready var _standee: Standee = $Standee
@onready var _facing_arrow: Node3D = $FacingArrow
@onready var _aim_marker: AimMarker = $AimMarker
@onready var _hover_ring: Node3D = $HoverRing


func _ready() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera:
		facing = Vector3(camera.global_basis.x.x, 0.0, camera.global_basis.x.z).normalized() # screen right
	skill_bar.used.connect(_on_skill_used)


func _unhandled_input(event: InputEvent) -> void:
	var slot := pressed_slot(event)
	if slot != SkillBar.NONE:
		skill_bar.press(slot)
		skill_bar.set_held(slot, true)
	slot = released_slot(event)
	if slot != SkillBar.NONE:
		skill_bar.set_held(slot, false)


## Which Skill slot `event` presses: 0 for the main slot, 1 to 4 for the small ones, or
## SkillBar.NONE. Godot also turns every touch into a left click, which would use the main slot
## wherever a thumb lands, so those emulated clicks don't count.
static func pressed_slot(event: InputEvent) -> int:
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		return SkillBar.NONE
	for slot in SkillBar.SLOTS:
		if event.is_action_pressed(slot_action(slot)):
			return slot
	return SkillBar.NONE


## Which Skill slot letting go of `event` releases, or SkillBar.NONE (see pressed_slot()).
static func released_slot(event: InputEvent) -> int:
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		return SkillBar.NONE
	for slot in SkillBar.SLOTS:
		if event.is_action_released(slot_action(slot)):
			return slot
	return SkillBar.NONE


## The input action that uses `slot`: `use_skill_slot_1` for the main slot, up to `_5`.
static func slot_action(slot: int) -> StringName:
	return StringName("use_skill_slot_%d" % (slot + 1))


func _on_skill_used(skill: Skill, given_aim: Vector3) -> void:
	var aim := given_aim if given_aim.is_finite() else _aim_for(skill)
	if not aim.is_zero_approx():
		facing = aim.normalized() # turn to what it was aimed at, for a moment
		_face_aim_left = FACE_AIM_TIME
	skill.use(aim)
	_standee.squash(USE_STRETCH)


## The aim on the ground for a thumb `drag` on screen (see ground_aim()).
func aim_from_drag(skill: Skill, drag: Vector2, full_drag: float) -> Vector3:
	var camera := get_viewport().get_camera_3d().global_basis
	var right := Vector3(camera.x.x, 0.0, camera.x.z).normalized()
	var back := Vector3(camera.z.x, 0.0, camera.z.z).normalized()
	return ground_aim(drag, right, back, skill.range, full_drag, skill.aims_at_spot)


## The aim on the ground, as an offset from the Character, for a thumb `drag` on screen.
## `right` and `back` are screen right and screen down on the ground. A Skill that goes a
## direction goes its whole Range; one that lands on a spot goes as far as the drag, reaching
## its Range at `full_drag`.
static func ground_aim(drag: Vector2, right: Vector3, back: Vector3, skill_range: float, full_drag: float, to_spot: bool) -> Vector3:
	var direction := (right * drag.x + back * drag.y).normalized()
	var reach := minf(drag.length() / full_drag, 1.0) if to_spot else 1.0
	return direction * skill_range * reach


## Shows where `skill` would go if used now with `aim`, greyed out while `cancelling`.
func show_aim(skill: Skill, aim: Vector3, cancelling: bool) -> void:
	_aim_marker.show_aim(skill, aim, cancelling)


func hide_aim() -> void:
	_aim_marker.hide()


## Where `skill` goes, as an offset on the ground: exactly at the mouse cursor, along a pushed
## right stick, or else auto-aimed. A Skill used around the player ignores it.
func _aim_for(skill: Skill) -> Vector3:
	if skill.aim == Skill.Aim.AROUND:
		return facing * skill.range
	if _aim_with_mouse:
		var point: Variant = _cursor_on_ground()
		if point != null:
			var offset := (point as Vector3) - global_position
			offset.y = 0.0
			if offset.length() > 0.05:
				return offset
	if _aim_with_stick:
		return facing * skill.range
	return skill.aim_toward(facing)


# Registered while in the tree, so a reloaded scene's new Player takes the command over.
func _enter_tree() -> void:
	Console.register(&"tp", _cmd_tp, "tp <x> <z>: move the player to a spot on the ground.")
	Console.register(&"bar", _cmd_bar, "bar <1-5> <skill|empty>: put a Skill in a Skill slot (1 is the main slot), or empty it.")
	Console.register(&"use", _cmd_use, "use <1-5> [<x> <z>]: use a Skill slot, auto-aimed or aimed at an offset on the ground.")


func _cmd_tp(args: PackedStringArray) -> String:
	if args.size() != 2 or not args[0].is_valid_float() or not args[1].is_valid_float():
		return "Usage: tp <x> <z>"
	global_position = Vector3(args[0].to_float(), 0.0, args[1].to_float())
	velocity = Vector3.ZERO
	return "tp %s %s" % [args[0], args[1]]


func _cmd_bar(args: PackedStringArray) -> String:
	if args.size() != 2 or not args[0].is_valid_int() or args[0].to_int() not in range(1, SkillBar.SLOTS + 1):
		return "Usage: bar <1-5> <skill|empty>"
	var slot := args[0].to_int() - 1
	if args[1].to_lower() == "empty":
		skill_bar.set_skill(slot, null)
		return "bar %d empty" % (slot + 1)
	for skill in skills:
		if skill.title.to_lower() == args[1].to_lower():
			skill_bar.set_skill(slot, skill)
			return "bar %d %s" % [slot + 1, skill.title]
	return "Unknown Skill '%s'. The player has: %s" % [args[1], ", ".join(skills.map(func(skill: Skill) -> String: return skill.title))]


func _cmd_use(args: PackedStringArray) -> String:
	var aimed := args.size() == 3 and args[1].is_valid_float() and args[2].is_valid_float()
	if not (args.size() == 1 or aimed) or not args[0].is_valid_int() or args[0].to_int() not in range(1, SkillBar.SLOTS + 1):
		return "Usage: use <1-5> [<x> <z>]"
	var slot := args[0].to_int() - 1
	if aimed:
		skill_bar.press(slot, Vector3(args[1].to_float(), 0.0, args[2].to_float()))
		return "use %d at %s %s" % [slot + 1, args[1], args[2]]
	skill_bar.press(slot)
	return "use %d" % (slot + 1)


## The Facing from `from` toward `to`, flattened onto the ground. A point right under `from`
## gives no direction, so `current` is kept.
static func facing_toward(from: Vector3, to: Vector3, current: Vector3) -> Vector3:
	var flat := Vector3(to.x - from.x, 0.0, to.z - from.z)
	return current if flat.length() < 0.05 else flat.normalized()


# _input, not _unhandled_input: the full-screen PixelatedView would claim mouse motion as GUI
# input first. The mouse leads Facing once it moves; the keys only walk. A gamepad stick or a
# touch takes Facing back from the mouse. A touch also moves the emulated mouse, which mustn't
# count as the mouse.
func _input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion and motion.device != InputEvent.DEVICE_ID_EMULATION:
		_cursor = motion.position
		_aim_with_mouse = true
	elif event is InputEventScreenTouch:
		_aim_with_mouse = false
	elif event is InputEventJoypadMotion:
		var stick := event as InputEventJoypadMotion
		if stick.axis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y, JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y] and absf(stick.axis_value) > 0.2:
			_aim_with_mouse = false


func _physics_process(delta: float) -> void:
	var direction := _stick_direction(&"move_left", &"move_right", &"move_up", &"move_down")
	velocity = _movement.next_velocity(velocity, direction, delta)
	move_and_slide()
	var aim := _stick_direction(&"aim_left", &"aim_right", &"aim_up", &"aim_down")
	_aim_with_stick = not aim.is_zero_approx()
	_face_aim_left = maxf(0.0, _face_aim_left - delta)
	if _aim_with_stick:
		facing = aim
	elif _face_aim_left > 0.0:
		pass # still facing the last use's aim
	elif _aim_with_mouse:
		facing = _facing_toward_cursor()
	elif not direction.is_zero_approx():
		facing = direction
	_highlight_hovered()
	_facing_arrow.basis = Basis.looking_at(facing)
	_standee.face(facing)
	_standee.play(&"idle" if velocity.is_zero_approx() else &"walk")


## Facing toward the ground under the mouse cursor, at the player's feet height.
func _facing_toward_cursor() -> Vector3:
	var point: Variant = _cursor_on_ground()
	return facing if point == null else facing_toward(global_position, point as Vector3, facing)


## Rings the Enemy nearest the spot under the mouse cursor, while the mouse aims: on PC, the
## Enemy a precision Skill such as Mark would pick.
func _highlight_hovered() -> void:
	var point: Variant = _cursor_on_ground() if _aim_with_mouse else null
	var hovered := Skill.enemy_nearest(get_world_3d(), point as Vector3, HOVER_REACH) if point != null else null
	_hover_ring.visible = hovered != null
	if hovered:
		_hover_ring.global_position = hovered.global_position + Vector3.UP * 0.05


## The spot on the ground under the mouse cursor, at the player's feet height, or null.
func _cursor_on_ground() -> Variant:
	var camera := get_viewport().get_camera_3d()
	var ground := Plane(Vector3.UP, global_position.y)
	return ground.intersects_ray(camera.project_ray_origin(_cursor), camera.project_ray_normal(_cursor))


## A stick's pushed direction as a unit vector on the ground, or zero inside the deadzone.
## Direction only: any push past the deadzone counts in full, so the vector is normalised.
func _stick_direction(to_left: StringName, to_right: StringName, to_up: StringName, to_down: StringName) -> Vector3:
	# Deadzone comes from the actions in the Input Map (0.2).
	var input := Input.get_vector(to_left, to_right, to_up, to_down)
	# Screen right and screen down on the ground: the camera's right and back axes, flattened.
	# Flattening each axis before mixing them keeps diagonals at 45° on the ground.
	var camera := get_viewport().get_camera_3d().global_basis
	var right := Vector3(camera.x.x, 0.0, camera.x.z).normalized()
	var back := Vector3(camera.z.x, 0.0, camera.z.z).normalized()
	return (right * input.x + back * input.y).normalized()
