class_name Player
extends CharacterBody3D
## The player's Character (see GLOSSARY.md), of the player's Faction. Its Controls tell it
## where to walk, relative to the camera (pushing up walks up the screen), and which Skill
## slots of its Skill bar the player presses. It has its Skills (child nodes) and its Modifiers, and activates a Skill when its
## Skill bar asks: aimed at the mouse cursor, along the right stick while it is pushed, or else
## auto-aimed (see Skill.Aim).

## A Skill in `slot` was activated (the HUD presses its button in).
signal skill_activated(slot: int)

## How far the card stretches when the player activates a Skill.
const ACTIVATE_STRETCH := -0.15
## How near the mouse cursor's spot a hostile Hurtbox must be to be highlighted.
const HOVER_REACH := 1.0
## How long the player keeps facing what a Skill was aimed at before the walk takes Facing back.
const FACE_AIM_TIME := 0.35
## Auto-aim takes a Hurtbox at most this far either side of Facing.
const AUTO_AIM_ANGLE := 60.0
## The proof Modifiers the `modifier` console command switches, by the name it takes.
const PROOF_MODIFIERS: Dictionary[String, Modifier] = {
	"spell-cooldown": preload("res://skills/modifiers/spell_cooldown.tres"),
	"pierce": preload("res://skills/modifiers/pierce.tres"),
}

## The player's Facing (see GLOSSARY.md): a unit direction on the ground. It follows the right
## stick while that is pushed, the mouse cursor once the mouse moves, otherwise the movement.
var facing := Vector3.RIGHT

## The player's Skill bar.
var skill_bar: SkillBar:
	get:
		return $SkillBar

## The Skills the player has: every Skill under its Skills node.
var skills: Array[Skill]:
	get:
		var found: Array[Skill] = []
		for child in $Skills.get_children():
			if child is Skill:
				found.append(child as Skill)
		return found

## The player's Faction: the player's, unless its scene says otherwise. Its Skills hit only
## Hurtboxes hostile to it.
@export var faction := Faction.Id.PLAYER

## The player's Modifiers: every activation of its Skills is made with them, and aiming reads
## its Skills' numbers through them.
@export var modifiers: Array[Modifier] = []

var _face_aim_left := 0.0 # time left facing the last activation's aim

## How much more Damage the player can take.
@onready var health: Health = $Health
## Shows the player's Health while it is below the maximum.
@onready var health_bar: HealthBar = $HealthBar

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
	Console.register(&"activate", _cmd_activate, "activate <1-5> [<x> <z>]: press a Skill slot, auto-aimed or aimed at an offset on the ground.")
	Console.register(&"damage", _cmd_damage, "damage <amount>: take Damage off the player's Health.")
	Console.register(&"heal", _cmd_heal, "heal <amount>: heal the player's Health.")
	Console.register(&"modifier", _cmd_modifier, "modifier [<name> on|off]: switch a proof Modifier on the player, or list them and why each applies to each Skill.")


func _ready() -> void:
	health.changed.connect(health_bar.show_health)
	for skill in skills:
		skill.faction = faction
	facing = _controls.ground_axes()[0] # screen right
	skill_bar.activation_requested.connect(_on_activation_requested)
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
		pass # still facing the last activation's aim
	elif _controls.leads_with_mouse():
		facing = _facing_toward_cursor()
	elif not direction.is_zero_approx():
		facing = direction
	_highlight_hovered()
	_facing_arrow.basis = Basis.looking_at(facing)
	_standee.face(facing)
	_standee.play(&"idle" if velocity.is_zero_approx() else &"walk")


## Activates the Skill in `slot`, aimed at `given_aim` or, with NO_AIM, by the player.
func _on_activation_requested(slot: int, given_aim: Vector3) -> void:
	var skill := skill_bar.skill_in(slot)
	var aim := given_aim if given_aim.is_finite() else _aim_for(skill)
	if not skill.try_activate(aim, modifiers):
		return
	if not aim.is_zero_approx():
		facing = aim.normalized() # turn to what it was aimed at, for a moment
		_face_aim_left = FACE_AIM_TIME
	_standee.squash(ACTIVATE_STRETCH)
	skill_activated.emit(slot)


## The aim on the ground for a thumb `drag` on screen (see ground_aim()).
func aim_from_drag(skill: Skill, drag: Vector2, full_drag: float) -> Vector3:
	var axes := _controls.ground_axes()
	return ground_aim(drag, axes[0], axes[1], _range_of(skill), full_drag, skill.aims_at_spot)


## The aim on the ground, as an offset from the Character, for a thumb `drag` on screen.
## `right` and `back` are screen right and screen down on the ground. A Skill that goes a
## direction goes its whole Range; one that lands on a spot goes as far as the drag, reaching
## its Range at `full_drag`.
static func ground_aim(drag: Vector2, right: Vector3, back: Vector3, skill_range: float, full_drag: float, to_spot: bool) -> Vector3:
	var direction := (right * drag.x + back * drag.y).normalized()
	var reach := minf(drag.length() / full_drag, 1.0) if to_spot else 1.0
	return direction * skill_range * reach


## Shows where `skill` would go if activated now with `aim`, greyed out while `cancelling`.
func show_aim(skill: Skill, aim: Vector3, cancelling: bool) -> void:
	_aim_marker.show_aim(skill, aim, _range_of(skill), cancelling)


func hide_aim() -> void:
	_aim_marker.hide()


## Where `skill` goes, as an offset on the ground: exactly at the mouse cursor, along a pushed
## right stick, or else auto-aimed. A Skill activated around the player ignores it.
func _aim_for(skill: Skill) -> Vector3:
	var reach := _range_of(skill)
	if skill.aim == Skill.Aim.AROUND:
		return facing * reach
	if _controls.leads_with_mouse():
		var point: Variant = _controls.cursor_on_ground(global_position.y)
		if point != null:
			var offset := (point as Vector3) - global_position
			offset.y = 0.0
			if offset.length() > 0.05:
				return offset
	if not _controls.aim_direction().is_zero_approx():
		return facing * reach
	return _auto_aim(reach)


## Where Auto-aim points, as an offset on the ground from the Character: the nearest of
## `target_offsets` within AUTO_AIM_ANGLE of `facing`, or else along `facing`. Never farther
## than `skill_range`. Which Hurtboxes are within Range is the caller's to ask (see _auto_aim()).
static func auto_aim(facing: Vector3, skill_range: float, target_offsets: Array[Vector3]) -> Vector3:
	var best := facing * skill_range
	var best_distance := INF
	for offset in target_offsets:
		var flat := Vector3(offset.x, 0.0, offset.z)
		var distance := flat.length()
		if distance < best_distance and rad_to_deg(flat.angle_to(facing)) <= AUTO_AIM_ANGLE:
			best = flat.limit_length(skill_range)
			best_distance = distance
	return best


## Auto-aim from where the player stands along its Facing (see auto_aim()), as far as `reach`:
## a Skill's Range as it stands now. A hostile Hurtbox within reach whose centre is past it is
## aimed at as far as the reach.
func _auto_aim(reach: float) -> Vector3:
	var offsets: Array[Vector3] = []
	for hurtbox in Hurtbox.around(get_world_3d(), global_position, reach, Faction.hostile_mask(faction)):
		offsets.append(hurtbox.global_position - global_position)
	return auto_aim(facing, reach, offsets)


## `skill`'s Range as it stands now, with the player's Modifiers: aiming isn't an activation,
## so it follows Modifiers that come and go.
func _range_of(skill: Skill) -> float:
	return skill.number(Skill.RANGE, modifiers)


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
		if String(skill.name).to_lower() == args[1].to_lower():
			skill_bar.set_skill(slot, skill)
			return "bar %d %s" % [slot + 1, skill.title]
	return "Unknown Skill '%s'. The player has: %s" % [args[1], ", ".join(skills.map(func(skill: Skill) -> String: return skill.name))]


func _cmd_activate(args: PackedStringArray) -> String:
	var aimed := args.size() == 3 and args[1].is_valid_float() and args[2].is_valid_float()
	if not (args.size() == 1 or aimed) or not args[0].is_valid_int() or args[0].to_int() not in range(1, SkillBar.SLOTS + 1):
		return "Usage: activate <1-5> [<x> <z>]"
	var slot := args[0].to_int() - 1
	if aimed:
		skill_bar.press(slot, Vector3(args[1].to_float(), 0.0, args[2].to_float()))
		return "activate %d at %s %s" % [slot + 1, args[1], args[2]]
	skill_bar.press(slot)
	return "activate %d" % (slot + 1)


func _cmd_damage(args: PackedStringArray) -> String:
	return _change_health(args, "damage", health.damage)


func _cmd_heal(args: PackedStringArray) -> String:
	return _change_health(args, "heal", health.heal)


## Runs the `command` console command: `change` the player's Health by the amount in `args`, then
## says what it is now, rounded.
func _change_health(args: PackedStringArray, command: String, change: Callable) -> String:
	if args.size() != 1 or not args[0].is_valid_float() or args[0].to_float() < 0.0:
		return "Usage: %s <amount>" % command
	change.call(args[0].to_float())
	return "Health %d" % roundi(health.current)


func _cmd_modifier(args: PackedStringArray) -> String:
	if args.is_empty():
		var lines: Array[String] = []
		for name in PROOF_MODIFIERS:
			var modifier := PROOF_MODIFIERS[name]
			lines.append("%s: %s (%s)" % [name, "on" if modifier in modifiers else "off", modifier.title])
		for skill in skills: # why each Modifier the player has applies to each Skill or not
			for line in skill.snapshot(modifiers).why:
				lines.append("%s › %s" % [skill.title, line])
		return "\n".join(lines)
	if args.size() != 2 or args[0] not in PROOF_MODIFIERS or args[1] not in ["on", "off"]:
		return "Usage: modifier [<%s> on|off]" % "|".join(PROOF_MODIFIERS.keys())
	var modifier := PROOF_MODIFIERS[args[0]]
	modifiers.erase(modifier)
	if args[1] == "on":
		modifiers.append(modifier)
	return "modifier %s %s" % [args[0], args[1]]


## The Facing from `from` toward `to`, flattened onto the ground. A point right under `from`
## gives no direction, so `current` is kept.
static func facing_toward(from: Vector3, to: Vector3, current: Vector3) -> Vector3:
	var flat := Vector3(to.x - from.x, 0.0, to.z - from.z)
	return current if flat.length() < 0.05 else flat.normalized()


## Facing toward the ground under the mouse cursor, at the player's feet height.
func _facing_toward_cursor() -> Vector3:
	var point: Variant = _controls.cursor_on_ground(global_position.y)
	return facing if point == null else facing_toward(global_position, point as Vector3, facing)


## Rings the hostile Hurtbox nearest the spot under the mouse cursor, while the mouse aims: on
## PC, the one a Skill that lands on a spot would pick.
func _highlight_hovered() -> void:
	var point: Variant = _controls.cursor_on_ground(global_position.y) if _controls.leads_with_mouse() else null
	var hovered: Hurtbox = null
	if point != null:
		hovered = Hurtbox.nearest(get_world_3d(), point as Vector3, HOVER_REACH, Faction.hostile_mask(faction))
	_hover_ring.visible = hovered != null
	if hovered:
		_hover_ring.global_position = hovered.global_position + Vector3.UP * 0.05
