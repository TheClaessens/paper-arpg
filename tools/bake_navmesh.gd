extends SceneTree
## Bakes every NavigationRegion3D in a scene and saves each navmesh to its resource file:
## the editor's Bake NavigationMesh button, from the command line. Run after editing a Level.
##
##   godot --path . --script res://tools/bake_navmesh.gd -- res://scenes/sandbox.tscn
##
## Needs a window, never --headless: baking reads the visual floor meshes from the GPU, and
## a headless run bakes no floor at all. Prints the walkable area at each height as a check:
## the floor shows up at y 0.2 (heights round up to the cell height), the rest are wall and
## prop tops nothing can reach.


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		printerr("Usage: --script res://tools/bake_navmesh.gd -- <scene>")
		quit(1)
		return
	if DisplayServer.get_name() == "headless":
		printerr("bake_navmesh needs a window: run it without --headless.")
		quit(1)
		return
	var scene := (load(args[0]) as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	var failed := false
	for region: NavigationRegion3D in scene.find_children("*", "NavigationRegion3D", true, false):
		region.bake_navigation_mesh(false)
		var mesh := region.navigation_mesh
		# Saving drops the file's uid, so put it back: scenes may refer to the navmesh by it.
		var uid := ResourceLoader.get_resource_uid(mesh.resource_path)
		var error := ResourceSaver.save(mesh, mesh.resource_path)
		if error == OK and uid != ResourceUID.INVALID_ID:
			error = ResourceSaver.set_uid(mesh.resource_path, uid)
		failed = failed or error != OK
		print("%s -> %s: %s" % [region.name, mesh.resource_path, error_string(error)])
		print("  walkable area by height: ", _area_by_height(mesh))
	quit(1 if failed else 0)


func _area_by_height(mesh: NavigationMesh) -> Dictionary[float, float]:
	var vertices := mesh.get_vertices()
	var area: Dictionary[float, float] = {}
	for i in mesh.get_polygon_count():
		var polygon := mesh.get_polygon(i)
		var sum := 0.0
		for k in range(1, polygon.size() - 1):
			var a := vertices[polygon[k]] - vertices[polygon[0]]
			var b := vertices[polygon[k + 1]] - vertices[polygon[0]]
			sum += a.cross(b).length() / 2.0
		var height := snappedf(vertices[polygon[0]].y, 0.1)
		area[height] = snappedf((area.get(height, 0.0) as float) + sum, 0.1)
	return area
