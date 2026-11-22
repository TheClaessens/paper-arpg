extends SceneTree
## Loads every project script, scene and .tres resource (outside dot folders, addons/ and assets/)
## and exits non-zero if any fails. A script with a parse error, including GDScript warnings the
## project treats as errors, fails to load; a scene with a broken reference fails to instantiate;
## a resource fails on a parse error or a broken reference.
## Run: godot --headless --script res://tools/load_all.gd   (or tools/check.sh)
## Keep project class names (GameSettings, Standee, ...) out of this file: a --script entry
## point compiles before autoloads exist, so naming them breaks compilation.


func _initialize() -> void:
	var failures := PackedStringArray()
	for path in find_files("res://", ["gd", "tscn", "tres"]):
		var resource := load(path)
		if resource == null or (resource is Script and not (resource as Script).can_instantiate()):
			failures.append(path)
		elif resource is PackedScene:
			var node := (resource as PackedScene).instantiate()
			if node == null:
				failures.append(path)
			else:
				node.free()
	for path in failures:
		printerr("FAILED TO LOAD: ", path)
	print("load_all: %d failed" % failures.size())
	quit(1 if failures.size() > 0 else 0)


## Every file under `dir` whose extension is in `extensions`, leaving out dot folders and the
## vendored res://addons and res://assets. tests/test_content.gd makes the same walk, with its own extensions.
static func find_files(dir: String, extensions: PackedStringArray) -> PackedStringArray:
	var found := PackedStringArray()
	for sub in DirAccess.get_directories_at(dir):
		var path := dir.path_join(sub)
		if not sub.begins_with(".") and path not in ["res://addons", "res://assets"]:
			found.append_array(find_files(path, extensions))
	for file in DirAccess.get_files_at(dir):
		if file.get_extension() in extensions:
			found.append(dir.path_join(file))
	return found
