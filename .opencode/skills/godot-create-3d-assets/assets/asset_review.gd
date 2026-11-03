extends Node
## Standalone multi-angle review with automatic framing and capture diagnostics.
## Arguments: --target=res://path/asset.tscn --shots=C:/out
## Optional: --center=0,1,0 --radius=8 --camera-height=1 --three-quarter=true

var target_path := ""
var shots_dir := "user://asset_review"
var center := Vector3.ZERO
var radius := 0.0
var camera_height := 0.0
var center_set := false
var radius_set := false
var camera_height_set := false
var include_three_quarter := false
var capture_failed := false


func _ready() -> void:
	AudioServer.set_bus_mute(0, true)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	parse_arguments()
	if target_path.is_empty() or not ResourceLoader.exists(target_path):
		push_error("Pass an existing --target=res://... scene")
		get_tree().quit(1)
		return
	var output_dir := ProjectSettings.globalize_path(shots_dir) \
		if shots_dir.begins_with("res://") or shots_dir.begins_with("user://") else shots_dir
	DirAccess.make_dir_recursive_absolute(output_dir)
	var target := (load(target_path) as PackedScene).instantiate() as Node3D
	if target == null:
		push_error("Target is not a Node3D scene")
		get_tree().quit(1)
		return
	add_child(target)
	await wait_frames(2)
	var bounds := merged_bounds(target)
	if not center_set:
		center = bounds.get_center()
	if not radius_set:
		radius = maxf(2.0, maxf(maxf(bounds.size.x, bounds.size.z), bounds.size.y) * 1.65)
	if not camera_height_set:
		camera_height = maxf(0.65, bounds.size.y * 0.16)

	build_lighting()
	var camera := Camera3D.new()
	camera.fov = 52.0
	camera.current = true
	add_child(camera)
	var camera_fill := OmniLight3D.new()
	camera_fill.omni_range = radius * 2.5
	camera_fill.light_energy = 1.4
	camera_fill.shadow_enabled = false
	camera.add_child(camera_fill)
	await wait_frames(20)

	var views := [
		["01_front.png", Vector3(0.0, camera_height, -radius)],
		["02_back.png", Vector3(0.0, camera_height, radius)],
		["03_left.png", Vector3(-radius, camera_height, 0.0)],
		["04_right.png", Vector3(radius, camera_height, 0.0)],
	]
	if include_three_quarter:
		var diagonal := radius / sqrt(2.0)
		views.append(["05_front_left.png", Vector3(-diagonal, camera_height, -diagonal)])
		views.append(["06_back_right.png", Vector3(diagonal, camera_height, diagonal)])

	var results: Array[Dictionary] = []
	for view in views:
		var filename: String = view[0]
		var offset: Vector3 = view[1]
		results.append(await capture(camera, filename, center + offset))
	var report := {
		"target": target_path,
		"captured_unix_time": Time.get_unix_time_from_system(),
		"scene_modified_unix_time": FileAccess.get_modified_time(target_path),
		"passed": not capture_failed,
		"framing": {
			"center": [center.x, center.y, center.z],
			"radius": radius,
			"camera_height": camera_height,
			"bounds_position": [bounds.position.x, bounds.position.y, bounds.position.z],
			"bounds_size": [bounds.size.x, bounds.size.y, bounds.size.z],
		},
		"views": results,
		"note": "Pixel statistics diagnose capture failures; visually inspect every image.",
	}
	var report_file := FileAccess.open(output_dir.path_join("review_report.json"), FileAccess.WRITE)
	if report_file == null:
		capture_failed = true
		push_error("Could not save review_report.json")
	else:
		report["passed"] = not capture_failed
		report_file.store_string(JSON.stringify(report, "  "))
	target.queue_free()
	await get_tree().process_frame
	print("ASSET REVIEW COMPLETE: %s" % output_dir)
	get_tree().quit(1 if capture_failed else 0)


func parse_arguments() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--target="):
			target_path = argument.trim_prefix("--target=")
		elif argument.begins_with("--shots="):
			shots_dir = argument.trim_prefix("--shots=")
		elif argument.begins_with("--center="):
			var values := argument.trim_prefix("--center=").split_floats(",")
			if values.size() == 3:
				center = Vector3(values[0], values[1], values[2])
				center_set = true
		elif argument.begins_with("--radius="):
			radius = argument.trim_prefix("--radius=").to_float()
			radius_set = radius > 0.0
		elif argument.begins_with("--camera-height="):
			camera_height = argument.trim_prefix("--camera-height=").to_float()
			camera_height_set = true
		elif argument == "--three-quarter=true":
			include_three_quarter = true


func build_lighting() -> void:
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.46, 0.55, 0.63)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.62, 0.67, 0.72)
	environment.ambient_light_energy = 1.0
	environment_node.environment = environment
	add_child(environment_node)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-32.0, 145.0, 0.0)
	fill.light_energy = 0.65
	fill.shadow_enabled = false
	add_child(fill)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(radius * 6.0, radius * 6.0)
	ground.mesh = plane
	ground.position.y = -0.015
	var ground_material := StandardMaterial3D.new()
	ground_material.albedo_color = Color(0.24, 0.29, 0.31)
	ground_material.roughness = 1.0
	ground.material_override = ground_material
	add_child(ground)


func capture(camera: Camera3D, filename: String, position: Vector3) -> Dictionary:
	camera.global_position = position
	camera.look_at(center, Vector3.UP)
	await wait_frames(8)
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var output_dir := ProjectSettings.globalize_path(shots_dir) \
		if shots_dir.begins_with("res://") or shots_dir.begins_with("user://") else shots_dir
	var error := image.save_png(output_dir.path_join(filename))
	if error != OK:
		capture_failed = true
		push_error("Could not save %s: %s" % [filename, error_string(error)])
	else:
		print("captured %s" % filename)
	return image_statistics(image, filename, error)


func image_statistics(image: Image, filename: String, error: Error) -> Dictionary:
	var samples := 0
	var dark := 0
	var clipped := 0
	var luminance_total := 0.0
	var minimum := 1.0
	var maximum := 0.0
	for y in range(0, image.get_height(), 4):
		for x in range(0, image.get_width(), 4):
			var color := image.get_pixel(x, y)
			var luminance := color.get_luminance()
			luminance_total += luminance
			minimum = minf(minimum, luminance)
			maximum = maxf(maximum, luminance)
			dark += 1 if luminance < 0.02 else 0
			clipped += 1 if maxf(color.r, maxf(color.g, color.b)) > 0.985 else 0
			samples += 1
	return {
		"file": filename,
		"saved": error == OK,
		"width": image.get_width(),
		"height": image.get_height(),
		"sample_count": samples,
		"mean_luminance": luminance_total / maxf(samples, 1),
		"minimum_luminance": minimum,
		"maximum_luminance": maximum,
		"dark_percent": 100.0 * dark / maxf(samples, 1),
		"clipped_percent": 100.0 * clipped / maxf(samples, 1),
	}


func merged_bounds(root: Node3D) -> AABB:
	var bounds := AABB()
	var has_bounds := false
	for found in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := found as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		var relative := root.global_transform.affine_inverse() * mesh_instance.global_transform
		var transformed := relative * mesh_instance.get_aabb()
		bounds = transformed if not has_bounds else bounds.merge(transformed)
		has_bounds = true
	for found in root.find_children("*", "MultiMeshInstance3D", true, false):
		var multimesh_instance := found as MultiMeshInstance3D
		if multimesh_instance.multimesh == null or multimesh_instance.multimesh.mesh == null:
			continue
		var relative := root.global_transform.affine_inverse() * multimesh_instance.global_transform
		var transformed := relative * multimesh_instance.get_aabb()
		bounds = transformed if not has_bounds else bounds.merge(transformed)
		has_bounds = true
	return bounds


func wait_frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame
