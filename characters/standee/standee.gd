class_name Standee
extends Node3D
## A character drawn as a paper cut-out (see GLOSSARY.md). Owns everything visual about a
## character: the card and its outline, animation, facing, walk wobble and Blob shadow.
## The character tells it what to show with play() and face().

## sink() has ended: the card is below the ground.
signal sunk

## Room around each frame for the white outline, in texture pixels.
const PADDING_PX := 8.0
## How long a squash takes, out and back.
const SQUASH_TIME := 0.18
## How long sink() takes.
const SINK_TIME := 0.45
## How far the card rocks side to side at the start of sink(), in degrees.
const SINK_WOBBLE := 3.0

## Animations by name. Needs at least `idle`: the starting pose, which also sets the card size.
## Every frame must be the same size.
@export var frames: SpriteFrames
## World units per texture pixel: sets how tall the Standee stands.
@export var pixel_size := 0.008
## While this animation plays, the card rocks side to side like a cut-out being walked along.
@export var wobble_animation: StringName = &"walk"
@export_range(0.0, 20.0, 0.5, "suffix:°") var wobble_angle := 4.5
@export var wobble_speed := 14.0

var _animation: StringName = &"idle"
var _frame := 0
var _frame_elapsed := 0.0
var _wobble_phase := 0.0
var _flash_left := 0.0
var _squash_amount := 0.0
var _squash_elapsed := SQUASH_TIME # done
var _sink := 0.0 # how far through sink(): 0 standing, 1 below the ground
var _card_height := 0.0

@onready var _card: Node3D = $Card
@onready var _sprite: MeshInstance3D = $Card/Sprite
@onready var _material: ShaderMaterial = _sprite.material_override
@onready var _blob_shadow: MeshInstance3D = $BlobShadow


func _ready() -> void:
	assert(frames != null, "Standee needs a SpriteFrames resource in `frames`.")
	assert(frames.has_animation(&"idle"), "Standee frames need an 'idle' animation.")
	var frame_size := frames.get_frame_texture(_animation, 0).get_size()
	var quad := QuadMesh.new()
	quad.size = (frame_size + Vector2.ONE * PADDING_PX * 2.0) * pixel_size
	quad.center_offset.y = quad.size.y / 2.0 - PADDING_PX * pixel_size # feet on the Standee's origin
	_sprite.mesh = quad
	_card_height = quad.size.y
	_material.set_shader_parameter("pad_px", PADDING_PX)
	_show_frame()


func play(animation: StringName) -> void:
	assert(frames.has_animation(animation), "Standee has no animation '%s'" % animation)
	if animation == _animation:
		return
	_animation = animation
	_frame = 0
	_frame_elapsed = 0.0
	_wobble_phase = 0.0
	_show_frame()


## Faces a direction in the world. Paper has two sides, so the card flips to whichever side
## the direction points on screen. Straight towards or away from the camera keeps the current side.
func face(direction: Vector3) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var side := camera.global_basis.x.dot(direction)
	if absf(side) > 0.01:
		_material.set_shader_parameter("flip", side < 0.0)


## Turns the card white for `duration` seconds.
func flash(duration: float) -> void:
	_flash_left = duration


## Squashes the card and lets it spring back over SQUASH_TIME. At the peak it is `amount`
## wider and shorter (0.3 is 30%). A negative amount stretches it instead.
func squash(amount: float) -> void:
	_squash_amount = amount
	_squash_elapsed = 0.0


## Drops the card through the ground line over SINK_TIME, speeding up as it goes, rocking a
## little side to side, while the Blob shadow shrinks and fades. Emits `sunk` at the end. A tween
## on the game's time, so a hitstop holds it still and the Hit's flash and squash show first.
func sink() -> void:
	var tween := create_tween().set_parallel()
	tween.tween_property(self, ^"_sink", 1.0, SINK_TIME)
	tween.tween_property(_blob_shadow, ^"scale", Vector3.ONE * 0.6, SINK_TIME)
	tween.tween_property(_blob_shadow, ^"transparency", 1.0, SINK_TIME)
	tween.finished.connect(sunk.emit)


func _process(delta: float) -> void:
	_advance(delta)
	_show_frame()
	_wobble_phase = fmod(_wobble_phase + delta * wobble_speed, TAU)
	# The camera never rotates (ADR 0001), but following its yaw keeps the card square to the
	# screen however the character itself is turned.
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var wobble := 0.0
	if _animation == wobble_animation:
		wobble = deg_to_rad(wobble_angle) * sin(_wobble_phase)
	# Sinking: ease-in down past the card's own height (the floor hides what is below it),
	# rocking one and a half times, less as it goes, and ending upright.
	_card.position.y = -_card_height * ease(_sink, 2.0)
	wobble -= deg_to_rad(SINK_WOBBLE) * (1.0 - _sink / 2.0) * sin(_sink * 3.0 * PI)
	_card.global_rotation = Vector3(0.0, camera.global_rotation.y, wobble)
	_show_hit(delta)


## The flash and squash. The card's feet stay on the ground: it scales around its origin.
## Runs after the rotation is set, which resets the card's scale.
func _show_hit(delta: float) -> void:
	_flash_left = maxf(0.0, _flash_left - delta)
	_material.set_shader_parameter("flash", _flash_left > 0.0)
	_squash_elapsed = minf(SQUASH_TIME, _squash_elapsed + delta)
	var s := _squash_amount * sin(PI * _squash_elapsed / SQUASH_TIME)
	_card.scale = Vector3(1.0 + s, 1.0 - s, 1.0)


## Moves through the frames like AnimatedSprite3D does: a frame lasts its relative
## duration divided by the animation's FPS. Looping animations wrap; others hold the last frame.
func _advance(delta: float) -> void:
	var fps := frames.get_animation_speed(_animation)
	if fps <= 0.0:
		return
	var count := frames.get_frame_count(_animation)
	_frame_elapsed += delta
	while true:
		var frame_seconds := frames.get_frame_duration(_animation, _frame) / fps
		if _frame_elapsed < frame_seconds:
			return
		if _frame + 1 < count:
			_frame += 1
		elif frames.get_animation_loop(_animation):
			_frame = 0
		else:
			_frame_elapsed = 0.0
			return
		_frame_elapsed -= frame_seconds


func _show_frame() -> void:
	_material.set_shader_parameter("tex", frames.get_frame_texture(_animation, _frame))
