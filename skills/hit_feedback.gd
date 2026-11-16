class_name HitFeedback
extends Resource
## Hit feedback (see GLOSSARY.md): how the game shows the moment a Skill hits. Game-wide, not
## per Skill: no game system changes it, and melee and ranged hits felt the same in the tuning
## study the values started from (see .scratch/combat/spec.md). One shared set,
## `hit_feedback.tres`, serves everything: shared() returns it. Tune it in the editor. How hard a hit pushes (knockback, Stagger) belongs
## to the Skill. The hit Enemy shows flash and squash; the Skill that hit plays the impact
## (hitstop and screen shake) once per use.

## The whole game freezes this long.
@export var hitstop := 0.06
## The hit Enemy turns white this long.
@export var flash := 0.1
## How far the hit Standee squashes at the peak: 0.3 is 30% wider and 30% shorter.
@export var squash := 0.3
## How far the screen shakes, in world units.
@export var shake := 0.12
## How long the screen shakes.
@export var shake_time := 0.15

static var _shared: HitFeedback

## The game's one set of Hit feedback. Kept once loaded: load() alone forgets a resource
## nothing holds, and would read the file again on every hit.
static func shared() -> HitFeedback:
	if _shared == null:
		_shared = load("res://skills/hit_feedback.tres")
	return _shared


# Hitstops started and not yet over. Overlapping ones keep the game frozen until the last ends.
static var _hitstops := 0


## The impact of a hit: freezes the game for `hitstop` and shakes the viewport's camera.
func play_impact(viewport: Viewport) -> void:
	if hitstop > 0.0:
		_hitstops += 1
		Engine.time_scale = 0.0
		# The timer ignores the time scale, or it would never run out.
		viewport.get_tree().create_timer(hitstop, true, false, true).timeout.connect(_end_hitstop)
	var camera := viewport.get_camera_3d()
	if camera and shake > 0.0 and shake_time > 0.0:
		var tween := camera.create_tween().set_ignore_time_scale() # shakes through the hitstop
		tween.tween_method(_shake_camera.bind(camera), shake, 0.0, shake_time)
		tween.tween_callback(_shake_camera.bind(0.0, camera))


static func _end_hitstop() -> void:
	_hitstops -= 1
	if _hitstops == 0:
		Engine.time_scale = 1.0


# Bound arguments come after the tweened value, hence `strength` first.
static func _shake_camera(strength: float, camera: Camera3D) -> void:
	camera.h_offset = randf_range(-strength, strength)
	camera.v_offset = randf_range(-strength, strength)
