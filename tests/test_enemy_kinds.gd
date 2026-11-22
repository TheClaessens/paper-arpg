extends GutTest
## Enemy kinds (see GLOSSARY.md): every scene whose root is an Enemy, but the base
## characters/enemy/enemy.tscn, is a kind that inherits the base itself, so a change for every
## Enemy is one edit there; and it gives its Standee frames, which the base leaves to its kinds.
## A Level that places Enemies isn't a kind: its root isn't an Enemy.

const LoadAll := preload("res://tools/load_all.gd")
const BASE := "res://characters/enemy/enemy.tscn"


func test_every_enemy_kind_inherits_the_base_and_has_frames() -> void:
	var kinds := 0
	var problems: Array[String] = []
	for path in LoadAll.find_files("res://", ["tscn"]):
		var scene: PackedScene = load(path)
		var root := scene.instantiate()
		if root is Enemy and path != BASE:
			kinds += 1
			problems.append_array(_kind_problems(path, scene, root))
		root.free()
	assert_gt(kinds, 0, "found no Enemy kind")
	assert_true(problems.is_empty(), "; ".join(problems))


func test_a_copy_is_no_kind() -> void:
	var enemy := Enemy.new()
	var copy := PackedScene.new()
	copy.pack(enemy)
	enemy.free()
	var root := copy.instantiate()
	var problems := _kind_problems("a copy", copy, root)
	root.free()
	assert_eq(problems.size(), 2, str(problems))
	assert_string_contains(problems[0], "inherits no scene")
	assert_string_contains(problems[1], "no frames")


## What is wrong with the Enemy kind `scene` at `path`, built as `root`, one line each.
func _kind_problems(path: String, scene: PackedScene, root: Node) -> Array[String]:
	var problems: Array[String] = []
	var base := scene.get_state().get_base_scene_state()
	if base == null:
		problems.append("%s inherits no scene: make a kind with Scene › New Inherited Scene from %s" % [path, BASE])
	elif base.get_path() != BASE:
		problems.append("%s inherits %s: a kind inherits %s itself" % [path, base.get_path(), BASE])
	var standee := root.get_node_or_null(^"Standee") as Standee
	if standee == null or standee.frames == null:
		problems.append("%s gives its Standee no frames" % path)
	return problems
