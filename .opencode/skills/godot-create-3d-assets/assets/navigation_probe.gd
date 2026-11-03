extends Node
## NavigationServer reachability check.
## --target=res://scene.tscn --start=x,y,z --end=x,y,z --report=C:/out/nav.json

var target_path := ""
var report_path := ""
var start_local := Vector3.ZERO
var end_local := Vector3.ZERO
var points_set := 0


func _ready() -> void:
	_parse_arguments()
	if target_path.is_empty() or not ResourceLoader.exists(target_path) or points_set != 2:
		_fail("Pass --target, --start, and --end")
		return
	var target := (load(target_path) as PackedScene).instantiate() as Node3D
	if target == null:
		_fail("Target is not an instantiable Node3D")
		return
	add_child(target)
	for index in 4:
		await get_tree().physics_frame
	var map := get_viewport().world_3d.navigation_map
	NavigationServer3D.map_force_update(map)
	await get_tree().physics_frame
	var start_global := target.to_global(start_local)
	var end_global := target.to_global(end_local)
	var path := NavigationServer3D.map_get_path(map, start_global, end_global, true)
	var reached := path.size() >= 2 and path[path.size() - 1].distance_to(end_global) <= 0.75
	var report := {"target": target_path, "passed": reached,
		"start_global": _vector(start_global), "end_global": _vector(end_global),
		"path_points": path.size(), "path": Array(path).map(_vector)}
	if not report_path.is_empty():
		DirAccess.make_dir_recursive_absolute(report_path.get_base_dir())
		var file := FileAccess.open(report_path, FileAccess.WRITE)
		if file != null:
			file.store_string(JSON.stringify(report, "  "))
	print("NAVIGATION PROBE %s: %s" % ["PASSED" if reached else "FAILED", JSON.stringify(report)])
	get_tree().quit(0 if reached else 1)


func _parse_arguments() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--target="):
			target_path = argument.trim_prefix("--target=")
		elif argument.begins_with("--report="):
			report_path = argument.trim_prefix("--report=")
		elif argument.begins_with("--start="):
			start_local = _parse_vector(argument.trim_prefix("--start="))
			points_set |= 1
		elif argument.begins_with("--end="):
			end_local = _parse_vector(argument.trim_prefix("--end="))
			points_set |= 2


func _parse_vector(text: String) -> Vector3:
	var values := text.split_floats(",")
	return Vector3(values[0], values[1], values[2]) if values.size() == 3 else Vector3.ZERO


func _vector(value: Vector3) -> Array[float]:
	return [value.x, value.y, value.z]


func _fail(message: String) -> void:
	push_error(message)
	print("NAVIGATION PROBE FAILED")
	get_tree().quit(1)
