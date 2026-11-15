extends GutTest
## Aggro is driven by real physics here: bodies enter its sphere and the engine reports them.

# Signal assertions compare Variant arguments.
@warning_ignore_start("unsafe_call_argument")

const AggroScene := preload("res://characters/aggro/aggro.tscn")
# Physics layer bits, as named in project.godot.
const PLAYER_LAYER := 2
const ENEMY_LAYER := 4

var aggro: Aggro


func before_each() -> void:
	aggro = AggroScene.instantiate()
	aggro.radius = 5.0
	add_child_autofree(aggro)
	watch_signals(aggro)


func test_aggroes_once_on_the_player() -> void:
	var player := _body(PLAYER_LAYER, Vector3(3.0, 0.0, 0.0))
	await wait_physics_frames(3)
	player.position = Vector3(20.0, 0.0, 0.0) # walks away...
	await wait_physics_frames(3)
	player.position = Vector3(3.0, 0.0, 0.0) # ...and comes back
	await wait_physics_frames(3)
	assert_signal_emit_count(aggro, "aggroed", 1)
	assert_signal_emitted_with_parameters(aggro, "aggroed", [player])


func test_ignores_the_player_outside_the_radius() -> void:
	_body(PLAYER_LAYER, Vector3(6.0, 0.0, 0.0))
	await wait_physics_frames(3)
	assert_signal_not_emitted(aggro, "aggroed")


func test_ignores_enemies() -> void:
	_body(ENEMY_LAYER, Vector3(3.0, 0.0, 0.0))
	await wait_physics_frames(3)
	assert_signal_not_emitted(aggro, "aggroed")


## A small body on one physics layer, standing at `position`.
func _body(layer: int, position: Vector3) -> CharacterBody3D:
	var body := CharacterBody3D.new()
	body.collision_layer = layer
	var shape := CollisionShape3D.new()
	shape.shape = SphereShape3D.new()
	body.add_child(shape)
	body.position = position
	add_child_autofree(body)
	return body
