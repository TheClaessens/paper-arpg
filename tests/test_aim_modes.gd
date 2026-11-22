extends GutTest
## The Aim modes, through a test-only Skill: a Skill whose Aim mode holds nothing goes along Facing
## whatever the aim, and the aim marker shows a spot Skill's spot and rings what it picks out.
## A drag aims a direction its full Range and a spot as far as it goes. The four files in
## skills/aim_modes/ say what the glossary's Aim modes say.

const PlayerScene := preload("res://characters/player/player.tscn")
const ZombieScene := preload("res://characters/enemy/zombie.tscn")


## A Skill that only records the aims it was activated with, and picks out `target`.
class TestSkill extends Skill:
	var aims: Array[Vector3] = []
	var target: Node3D

	func _activate(_snapshot: Snapshot, aim: Vector3) -> void:
		aims.append(aim)

	func target_for(_aim: Vector3) -> Node3D:
		return target


var player: Player
var skill: TestSkill


func before_each() -> void:
	player = PlayerScene.instantiate()
	add_child_autofree(player)
	player.set_physics_process(false) # no camera here to read input against; after add_child, or _ready turns it back on
	skill = TestSkill.new()
	skill.cooldown = 1.0
	skill.range = 2.0
	skill.aim_mode = AimMode.new()
	player.add_skill(skill)
	player.skill_bar.set_skill(1, skill)


func test_a_skill_activated_around_the_player_ignores_the_aim() -> void:
	skill.aim_mode = preload("res://skills/aim_modes/around.tres")
	var zombie: Node3D = ZombieScene.instantiate() # where auto-aim would point instead
	add_child_autofree(zombie)
	zombie.global_position = player.facing.rotated(Vector3.UP, deg_to_rad(30.0))
	await wait_physics_frames(2) # the zombie's body joins the physics world
	player.skill_bar.press(1)
	player.skill_bar.advance()
	assert_eq(skill.aims, [player.facing * 2.0] as Array[Vector3], "along Facing, as far as the Range")


func test_aiming_reads_the_range_as_it_stands_now() -> void:
	skill.aim_mode = preload("res://skills/aim_modes/around.tres")
	var farther := Modifier.new()
	var change := NumberChange.new()
	change.number = Skill.RANGE
	change.amount = 1.0
	farther.number_changes = [change]
	player.modifiers.append(farther) # a Range buff, gained before the press
	player.skill_bar.press(1)
	player.skill_bar.advance()
	assert_eq(skill.aims, [player.facing * 3.0] as Array[Vector3], "the Range with the buff")


func test_the_marker_shows_a_spot_and_rings_the_target() -> void:
	skill.aim_mode = preload("res://skills/aim_modes/spot.tres")
	skill.target = autofree(Node3D.new())
	add_child(skill.target)
	skill.target.global_position = Vector3(3.0, 0.0, 1.0)
	player.show_aim(skill, Vector3(1.5, 0.0, 0.0), false)
	var marker := player.get_node("AimMarker")
	assert_true((marker.get_node("Spot") as Node3D).visible, "a spot, not a line")
	assert_false((marker.get_node("Line") as Node3D).visible)
	var ring: Node3D = marker.get_node("Target")
	assert_true(ring.visible)
	assert_almost_eq(Vector2(ring.global_position.x, ring.global_position.z), Vector2(3.0, 1.0), Vector2.ONE * 0.001)


# The drag is measured on the ground by the camera's right and back axes.

func test_a_drag_aims_a_direction_its_full_range() -> void:
	var line: AimMode = preload("res://skills/aim_modes/line.tres")
	var aim := line.aim_from_drag(Vector2(30.0, 0.0), Vector3.RIGHT, Vector3.BACK, 10.0, 100.0)
	assert_almost_eq(aim, Vector3(10.0, 0.0, 0.0), Vector3.ONE * 0.001)


func test_a_drag_aims_a_spot_as_far_as_it_goes() -> void:
	var spot: AimMode = preload("res://skills/aim_modes/spot.tres")
	var half := spot.aim_from_drag(Vector2(0.0, 50.0), Vector3.RIGHT, Vector3.BACK, 8.0, 100.0)
	assert_almost_eq(half, Vector3(0.0, 0.0, 4.0), Vector3.ONE * 0.001, "half the drag, half the Range")
	var past := spot.aim_from_drag(Vector2(0.0, 300.0), Vector3.RIGHT, Vector3.BACK, 8.0, 100.0)
	assert_almost_eq(past, Vector3(0.0, 0.0, 8.0), Vector3.ONE * 0.001, "never past the Range")


func test_each_aim_mode_file_says_what_the_spec_says() -> void:
	# file: [holds, waits for the lift, repeats while held]
	var expected := {
		"steer": [AimMode.Holds.DIRECTION, false, true],
		"line": [AimMode.Holds.DIRECTION, true, false],
		"spot": [AimMode.Holds.SPOT, true, false],
		"around": [AimMode.Holds.NOTHING, false, false],
	}
	for file: String in expected:
		var mode: AimMode = load("res://skills/aim_modes/%s.tres" % file)
		var wanted: Array = expected[file]
		assert_eq([mode.holds, mode.waits_for_lift, mode.repeats_while_held], wanted, file)
