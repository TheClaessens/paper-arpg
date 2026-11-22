extends SceneTree
## Gives a hand-written resource or scene a `uid` in its header, as the editor would on its first
## save, so that save doesn't show up as churn. `ResourceSaver.save()` run headless writes none.
##
##   godot --headless --path . --script res://tools/give_uid.gd -- res://a.tres res://b.tscn
##
## A file that already has a `uid` is left alone and reported. Prints each path and its `uid`.
## A file has one when its first line holds `uid="`: ResourceLoader.get_resource_uid() only knows
## files the editor has scanned, so it says INVALID_ID for a file written a moment ago.
## A scene's nodes still get their `unique_id` from the editor.
## Keep project class names out of this file: a --script entry point compiles before
## autoloads exist, so naming them breaks compilation.


func _initialize() -> void:
	var paths := OS.get_cmdline_user_args()
	if paths.is_empty():
		printerr("Usage: --script res://tools/give_uid.gd -- <res:// path>...")
		quit(1)
		return
	var failed := false
	for path in paths:
		if _has_uid(path):
			print("%s already has a uid" % path)
			continue
		var id := ResourceUID.create_id()
		var error := ResourceSaver.set_uid(path, id)
		if error != OK:
			printerr("%s: set_uid failed (%s)" % [path, error_string(error)])
			failed = true
			continue
		print("%s %s" % [path, ResourceUID.id_to_text(id)])
	quit(1 if failed else 0)


func _has_uid(path: String) -> bool:
	var file := FileAccess.open(path, FileAccess.READ)
	return file != null and file.get_line().contains('uid="')
