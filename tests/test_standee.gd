extends GutTest

const StandeeScene := preload("res://characters/standee/standee.tscn")

var standee: Standee
var frames: SpriteFrames


func before_each() -> void:
	frames = SpriteFrames.new() # starts with a 'default' animation; we add our own
	var texture := ImageTexture.create_from_image(Image.create(4, 4, false, Image.FORMAT_RGBA8))
	frames.add_animation(&"idle")
	frames.add_frame(&"idle", texture)
	frames.add_animation(&"walk")
	frames.set_animation_speed(&"walk", 10.0) # 0.1 s per frame
	for i in 4:
		frames.add_frame(&"walk", texture)
	standee = StandeeScene.instantiate()
	standee.frames = frames
	add_child_autofree(standee)
	standee.play(&"walk")


func test_steps_frames_at_animation_fps() -> void:
	standee._process(0.25)
	assert_eq(standee._frame, 2)


func test_looping_animation_wraps() -> void:
	standee._process(0.45)
	assert_eq(standee._frame, 0)


func test_non_looping_animation_holds_last_frame() -> void:
	frames.set_animation_loop(&"walk", false)
	standee._process(1.0)
	assert_eq(standee._frame, 3)


func test_respects_per_frame_duration() -> void:
	frames.set_frame(&"walk", 0, frames.get_frame_texture(&"walk", 0), 3.0) # first frame lasts 0.3 s
	standee._process(0.25)
	assert_eq(standee._frame, 0)
	standee._process(0.1)
	assert_eq(standee._frame, 1)


func test_play_restarts_from_first_frame() -> void:
	standee._process(0.25)
	standee.play(&"idle")
	standee.play(&"walk")
	assert_eq(standee._frame, 0)


func test_face_without_camera_does_nothing() -> void:
	standee.face(Vector3.LEFT) # the test scene has no Camera3D
	assert_eq(standee._material.get_shader_parameter("flip"), null)
