extends GutTest
## The aim modes, through a test-only Skill: a Skill used around the player goes along Facing
## whatever the aim, and the aim marker shows a spot Skill's spot and rings what it picks out.

const PlayerScene := preload("res://characters/player/player.tscn")
const ZombieScene := preload("res://characters/enemy/zombie.tscn")


## A Skill that only records the aims it was used with, and picks out `target`.
class TestSkill extends Skill:
	var aims: Array[Vector3] = []
	var target: Node3D

	func use(aim: Vector3) -> void:
		aims.append(aim)

	func target_for(_aim: Vector3) -> Node3D:
		return target


var player: Player
var skill: TestSkill


func before_each() -> void:
	player = PlayerScene.instantiate()
	player.set_physics_process(false) # no camera here to read input against
	add_child_autofree(player)
	skill = TestSkill.new()
	skill.cooldown = 1.0
	skill.range = 2.0
	player.add_child(skill)
	player.skill_bar.set_skill(1, skill)


func test_a_skill_used_around_the_player_ignores_the_aim() -> void:
	skill.aim = Skill.Aim.AROUND
	var zombie: Node3D = ZombieScene.instantiate() # where auto-aim would point instead
	add_child_autofree(zombie)
	zombie.global_position = player.facing.rotated(Vector3.UP, deg_to_rad(30.0))
	await wait_physics_frames(2) # the zombie's body joins the physics world
	player.skill_bar.press(1)
	player.skill_bar.advance(0.016)
	assert_eq(skill.aims, [player.facing * 2.0] as Array[Vector3], "along Facing, as far as the Range")


func test_the_marker_shows_a_spot_and_rings_the_target() -> void:
	skill.aims_at_spot = true
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
