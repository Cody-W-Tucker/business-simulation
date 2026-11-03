extends Node
## Fixed-scene runtime sampler.
## --target=res://scene.tscn --report=C:/out/performance.json
## Optional: --warmup=120 --frames=300 --camera=0,3,8 --look-at=0,1,0

var target_path := ""
var report_path := ""
var warmup_frames := 120
var sample_frames := 300
var camera_position := Vector3.ZERO
var camera_target := Vector3.ZERO
var camera_set := false
var target_set := false


func _ready() -> void:
	AudioServer.set_bus_mute(0, true)
	_parse_arguments()
	if target_path.is_empty() or not ResourceLoader.exists(target_path):
		_fail("Pass an existing --target=res://... scene")
		return
	var packed := load(target_path) as PackedScene
	var target := packed.instantiate() as Node3D if packed != null else null
	if target == null:
		_fail("Target is not an instantiable Node3D")
		return
	add_child(target)
	await get_tree().process_frame
	_ensure_camera(target)
	for index in warmup_frames:
		await get_tree().process_frame
	var frame_ms: Array[float] = []
	var process_ms: Array[float] = []
	var physics_ms: Array[float] = []
	var draw_calls: Array[float] = []
	var objects: Array[float] = []
	var primitives: Array[float] = []
	var video_memory: Array[float] = []
	for index in sample_frames:
		var started := Time.get_ticks_usec()
		await get_tree().process_frame
		frame_ms.append((Time.get_ticks_usec() - started) / 1000.0)
		process_ms.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
		physics_ms.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
		draw_calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		objects.append(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
		primitives.append(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
		video_memory.append(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED))
	var report := {
		"target": target_path,
		"captured_unix_time": Time.get_unix_time_from_system(),
		"scene_modified_unix_time": FileAccess.get_modified_time(target_path),
		"warmup_frames": warmup_frames,
		"sample_frames": sample_frames,
		"frame_ms": _summary(frame_ms),
		"process_ms": _summary(process_ms),
		"physics_ms": _summary(physics_ms),
		"draw_calls": _summary(draw_calls),
		"rendered_objects": _summary(objects),
		"rendered_primitives": _summary(primitives),
		"video_memory_bytes": _summary(video_memory),
	}
	if not _write_report(report):
		_fail("Could not write performance report")
		return
	print("PERFORMANCE PROBE PASSED: %s" % JSON.stringify(report))
	get_tree().quit(0)


func _parse_arguments() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--target="):
			target_path = argument.trim_prefix("--target=")
		elif argument.begins_with("--report="):
			report_path = argument.trim_prefix("--report=")
		elif argument.begins_with("--warmup="):
			warmup_frames = maxi(1, argument.trim_prefix("--warmup=").to_int())
		elif argument.begins_with("--frames="):
			sample_frames = maxi(30, argument.trim_prefix("--frames=").to_int())
		elif argument.begins_with("--camera="):
			camera_position = _parse_vector(argument.trim_prefix("--camera="))
			camera_set = true
		elif argument.begins_with("--look-at="):
			camera_target = _parse_vector(argument.trim_prefix("--look-at="))
			target_set = true


func _ensure_camera(target: Node3D) -> void:
	for existing in get_tree().get_nodes_in_group("performance_probe_camera"):
		if existing is Camera3D:
			(existing as Camera3D).current = true
			return
	var camera := Camera3D.new()
	camera.name = "PerformanceProbeCamera"
	camera.add_to_group("performance_probe_camera")
	var bounds := _merged_bounds(target)
	if not target_set:
		camera_target = bounds.get_center()
	if not camera_set:
		var radius := maxf(3.0, maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z)) * 1.4)
		camera_position = camera_target + Vector3(radius * 0.65, radius * 0.35, radius)
	camera.position = camera_position
	add_child(camera)
	camera.look_at(camera_target, Vector3.UP)
	camera.current = true


func _merged_bounds(root: Node3D) -> AABB:
	var bounds := AABB(Vector3.ZERO, Vector3.ONE)
	var has_bounds := false
	for node in root.find_children("*", "VisualInstance3D", true, false):
		if node is MeshInstance3D and (node as MeshInstance3D).mesh == null:
			continue
		if node is MultiMeshInstance3D and ((node as MultiMeshInstance3D).multimesh == null \
				or (node as MultiMeshInstance3D).multimesh.mesh == null):
			continue
		if node is GeometryInstance3D:
			var visual := node as GeometryInstance3D
			var relative := root.global_transform.affine_inverse() * visual.global_transform
			var transformed := relative * visual.get_aabb()
			bounds = transformed if not has_bounds else bounds.merge(transformed)
			has_bounds = true
	return bounds


func _summary(values: Array[float]) -> Dictionary:
	values.sort()
	var total := 0.0
	for value in values:
		total += value
	var p95_index := clampi(ceili(values.size() * 0.95) - 1, 0, values.size() - 1)
	return {"mean": total / values.size(), "p95": values[p95_index],
		"min": values.front(), "max": values.back()}


func _write_report(report: Dictionary) -> bool:
	if report_path.is_empty():
		return true
	DirAccess.make_dir_recursive_absolute(report_path.get_base_dir())
	var file := FileAccess.open(report_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(report, "  "))
	return true


func _parse_vector(text: String) -> Vector3:
	var values := text.split_floats(",")
	return Vector3(values[0], values[1], values[2]) if values.size() == 3 else Vector3.ZERO


func _fail(message: String) -> void:
	push_error(message)
	print("PERFORMANCE PROBE FAILED")
	get_tree().quit(1)
