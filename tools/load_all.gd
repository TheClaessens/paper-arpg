extends SceneTree
## Loads every project script and scene (outside addons/) and exits non-zero if any fails.
## A script with a parse error, including GDScript warnings the project treats as errors,
## fails to load; a scene with a broken reference fails to instantiate.
## Run: godot --headless --script res://tools/load_all.gd   (or tools/check.sh)
## Keep project class names (GameSettings, Standee, ...) out of this file: a --script entry
## point compiles before autoloads exist, so naming them breaks compilation.


func _initialize() -> void:
	var failures := PackedStringArray()
	for path in _find("res://"):
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


func _find(dir: String) -> PackedStringArray:
	var found := PackedStringArray()
	for sub in DirAccess.get_directories_at(dir):
		if not sub.begins_with(".") and sub != "addons":
			found.append_array(_find(dir.path_join(sub)))
	for file in DirAccess.get_files_at(dir):
		if file.get_extension() in ["gd", "tscn"]:
			found.append(dir.path_join(file))
	return found
