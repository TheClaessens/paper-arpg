extends GutTest
## The `tp` console command, which the Player registers while it is in the tree.

const PlayerScene := preload("res://characters/player/player.tscn")

var player: Player


func before_each() -> void:
	player = PlayerScene.instantiate()
	player.set_physics_process(false) # no camera here to read input against
	add_child_autofree(player)


func test_tp_moves_the_player() -> void:
	Console.execute("tp 3 -4.5")
	assert_eq(player.global_position, Vector3(3.0, 0.0, -4.5))


func test_tp_needs_two_numbers() -> void:
	assert_eq(Console.execute("tp 3"), "Usage: tp <x> <z>")
	assert_eq(Console.execute("tp a b"), "Usage: tp <x> <z>")
	assert_eq(player.global_position, Vector3.ZERO)


func test_tp_leaves_and_returns_with_the_player() -> void:
	remove_child(player)
	assert_string_starts_with(Console.execute("tp 1 1"), "Unknown command")
	add_child(player)
	assert_eq(Console.execute("tp 1 1"), "tp 1 1", "re-entering registers it again")
