class_name Player
extends CharacterBody3D
## The player's Character (see GLOSSARY.md). Its Controls tell it where to walk, relative to the
## camera (pushing up walks up the screen), and which Skill slots of its Skill bar the player
## uses. It aims each use at the mouse cursor, along the right stick while it is pushed, or else
## auto-aimed (see Skill.Aim).

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

var _face_aim_left := 0.0 # time left facing the last use's aim

@onready var _controls: Controls = $Controls
@onready var _movement: Movement = $Movement
@onready var _standee: Standee = $Standee
@onready var _facing_arrow: Node3D = $FacingArrow
@onready var _aim_marker: AimMarker = $AimMarker
@onready var _hover_ring: Node3D = $HoverRing


# Registered while in the tree, so a reloaded scene's new Player takes the command over.
func _enter_tree() -> void:
	Console.register(&"tp", _cmd_tp, "tp <x> <z>: move the player to a spot on the ground.")
	Console.register(&"bar", _cmd_bar, "bar <1-5> <skill|empty>: put a Skill in a Skill slot (1 is the main slot), or empty it.")
	Console.register(&"use", _cmd_use, "use <1-5> [<x> <z>]: use a Skill slot, auto-aimed or aimed at an offset on the ground.")


func _ready() -> void:
	facing = _controls.ground_axes()[0] # screen right
	skill_bar.used.connect(_on_skill_used)
	_controls.slot_pressed.connect(skill_bar.press)
	_controls.slot_pressed.connect(skill_bar.set_held.bind(true))
	_controls.slot_released.connect(skill_bar.set_held.bind(false))


func _physics_process(delta: float) -> void:
	var direction := _controls.move_direction()
	velocity = _movement.next_velocity(velocity, direction, delta)
	move_and_slide()
	var aim := _controls.aim_direction()
	_face_aim_left = maxf(0.0, _face_aim_left - delta)
	if not aim.is_zero_approx():
		facing = aim
	elif _face_aim_left > 0.0:
		pass # still facing the last use's aim
	elif _controls.leads_with_mouse():
		facing = _facing_toward_cursor()
	elif not direction.is_zero_approx():
		facing = direction
	_highlight_hovered()
	_facing_arrow.basis = Basis.looking_at(facing)
	_standee.face(facing)
	_standee.play(&"idle" if velocity.is_zero_approx() else &"walk")


func _on_skill_used(skill: Skill, given_aim: Vector3) -> void:
	var aim := given_aim if given_aim.is_finite() else _aim_for(skill)
	if not aim.is_zero_approx():
		facing = aim.normalized() # turn to what it was aimed at, for a moment
		_face_aim_left = FACE_AIM_TIME
	skill.use(aim)
	_standee.squash(USE_STRETCH)


## The aim on the ground for a thumb `drag` on screen (see ground_aim()).
func aim_from_drag(skill: Skill, drag: Vector2, full_drag: float) -> Vector3:
	var axes := _controls.ground_axes()
	return ground_aim(drag, axes[0], axes[1], skill.range, full_drag, skill.aims_at_spot)


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
	if _controls.leads_with_mouse():
		var point: Variant = _controls.cursor_on_ground(global_position.y)
		if point != null:
			var offset := (point as Vector3) - global_position
			offset.y = 0.0
			if offset.length() > 0.05:
				return offset
	if not _controls.aim_direction().is_zero_approx():
		return facing * skill.range
	return skill.aim_toward(facing)


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


## Facing toward the ground under the mouse cursor, at the player's feet height.
func _facing_toward_cursor() -> Vector3:
	var point: Variant = _controls.cursor_on_ground(global_position.y)
	return facing if point == null else facing_toward(global_position, point as Vector3, facing)


## Rings the Enemy nearest the spot under the mouse cursor, while the mouse aims: on PC, the
## Enemy a precision Skill such as Mark would pick.
func _highlight_hovered() -> void:
	var point: Variant = _controls.cursor_on_ground(global_position.y) if _controls.leads_with_mouse() else null
	var hovered := Skill.enemy_nearest(get_world_3d(), point as Vector3, HOVER_REACH) if point != null else null
	_hover_ring.visible = hovered != null
	if hovered:
		_hover_ring.global_position = hovered.global_position + Vector3.UP * 0.05
