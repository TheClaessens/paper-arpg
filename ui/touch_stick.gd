class_name TouchStick
extends Control
## The Touch stick (see GLOSSARY.md): a thumb that lands on the left half of the screen
## drags a stick from that spot. It presses the move_* actions like the controller's left
## stick, so the Player can't tell them apart.

const NO_FINGER := -1

## How far the thumb travels from the origin to push the stick fully.
@export var radius := 80.0

## When on, the origin is dragged along behind a thumb past the rim instead of staying put.
## Temporary: switched with the `touchstick` console command until the device test settles it.
@export var follow := false

var _finger := NO_FINGER # touch index that owns the stick
var _origin := Vector2.ZERO
var _thumb := Vector2.ZERO
var _stick := Vector2.ZERO # what the stick last pressed, so it releases only that

@onready var _pad: Sprite2D = $Pad
@onready var _nub: Sprite2D = $Nub


## Thumb offset from the origin as a stick vector, length 1 at the rim and clamped past it.
static func stick_vector(origin: Vector2, thumb: Vector2, stick_radius: float) -> Vector2:
	return ((thumb - origin) / stick_radius).limit_length(1.0)


## Where the origin goes when it follows: unchanged while the thumb is inside the rim,
## otherwise pulled along so the thumb sits exactly on the rim.
static func followed_origin(origin: Vector2, thumb: Vector2, stick_radius: float) -> Vector2:
	return thumb - (thumb - origin).limit_length(stick_radius)


func _enter_tree() -> void:
	Console.register(&"touchstick", _cmd_touchstick, "touchstick follow on|off: let the stick's origin follow the thumb.")


func _cmd_touchstick(args: PackedStringArray) -> String:
	if args.size() != 2 or args[0] != "follow" or args[1] not in ["on", "off"]:
		return "Usage: touchstick follow on|off"
	follow = args[1] == "on"
	return "touchstick follow %s" % args[1]


# Unhandled, so GUI on top (the console button) handles its own touches first.
func _unhandled_input(event: InputEvent) -> void:
	var touch := event as InputEventScreenTouch
	if touch:
		if touch.pressed and _finger == NO_FINGER and touch.position.x < get_viewport_rect().size.x / 2.0:
			_finger = touch.index
			_origin = touch.position
			_move_thumb(touch.position)
		elif not touch.pressed and touch.index == _finger:
			_release()
		return
	var drag := event as InputEventScreenDrag
	if drag and drag.index == _finger:
		_move_thumb(drag.position)


func _notification(what: int) -> void:
	# A thumb lost without a clean lift (the Console pausing the game, the app losing focus)
	# must not leave the player walking.
	if what == NOTIFICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_release()


func _move_thumb(at: Vector2) -> void:
	_thumb = at
	if follow:
		_origin = followed_origin(_origin, _thumb, radius)
	_press(stick_vector(_origin, _thumb, radius))
	_place_sprites()


func _release() -> void:
	if _finger == NO_FINGER:
		return
	_finger = NO_FINGER
	_press(Vector2.ZERO)
	_place_sprites()


## Presses each move_* action by its share of the stick; the Input Map deadzone applies on read.
## An action the stick stops pushing is released only if the stick was the one pressing it,
## so a key held on the keyboard stays held.
func _press(stick: Vector2) -> void:
	_press_action(&"move_left", -stick.x, -_stick.x)
	_press_action(&"move_right", stick.x, _stick.x)
	_press_action(&"move_up", -stick.y, -_stick.y)
	_press_action(&"move_down", stick.y, _stick.y)
	_stick = stick


func _press_action(action: StringName, strength: float, was: float) -> void:
	if strength > 0.0:
		Input.action_press(action, strength)
	elif was > 0.0:
		Input.action_release(action)


func _place_sprites() -> void:
	_pad.visible = _finger != NO_FINGER
	_nub.visible = _pad.visible
	# Sized so the pad's ring sits on the radius the thumb has to reach.
	_pad.scale = Vector2.ONE * radius * 2.0 / _pad.texture.get_width()
	_nub.scale = _pad.scale
	_pad.position = _origin
	_nub.position = _origin + stick_vector(_origin, _thumb, radius) * radius
