extends Node
## Generic capsule traversal fallback.
## --target=res://scene.tscn --route=x,y,z;x,y,z --report=C:/out/route.json
## Optional: --radius=0.45 --height=1.8 --speed=3.5 --timeout=30

var target_path := ""
var report_path := ""
var route: Array[Vector3] = []
var radius := 0.45
var body_height := 1.8
var speed := 3.5
var timeout_seconds := 30.0
var max_vertical_error := 1.25


func _ready() -> void:
	_parse_arguments()
	if target_path.is_empty() or not ResourceLoader.exists(target_path) or route.size() < 2:
		_fail("Pass --target and at least two semicolon-separated --route points")
		return
	var packed := load(target_path) as PackedScene
	var target := packed.instantiate() as Node3D if packed != null else null
	if target == null:
		_fail("Target is not an instantiable Node3D")
		return
	add_child(target)
	var body := CharacterBody3D.new()
	body.name = "RouteProbeBody"
	body.floor_snap_length = 0.3
	body.floor_max_angle = deg_to_rad(48.0)
	body.max_slides = 8
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = radius
	shape.height = maxf(body_height, radius * 2.0)
	collision.shape = shape
	collision.position.y = body_height * 0.5
	body.add_child(collision)
	add_child(body)
	body.global_position = target.to_global(route[0])
	await get_tree().physics_frame
	var started := Time.get_ticks_msec()
	var reached: Array[Dictionary] = []
	var stalled_seconds := 0.0
	var previous := body.global_position
	for point_index in range(1, route.size()):
		var destination := target.to_global(route[point_index])
		while Vector2(body.global_position.x - destination.x,
				body.global_position.z - destination.z).length() > maxf(0.25, radius * 0.65):
			if body.global_position.y < destination.y - max_vertical_error:
				_write_and_quit(false, reached, body, "fell below route before point %d" % point_index)
				return
			if (Time.get_ticks_msec() - started) / 1000.0 > timeout_seconds:
				_write_and_quit(false, reached, body, "timeout before point %d" % point_index)
				return
			var horizontal := Vector3(destination.x - body.global_position.x, 0.0,
				destination.z - body.global_position.z).normalized()
			body.velocity.x = horizontal.x * speed
			body.velocity.z = horizontal.z * speed
			body.velocity.y = -0.5 if body.is_on_floor() else body.velocity.y - 18.0 * get_physics_process_delta_time()
			body.move_and_slide()
			await get_tree().physics_frame
			var moved := body.global_position.distance_to(previous)
			stalled_seconds = stalled_seconds + get_physics_process_delta_time() if moved < 0.002 else 0.0
			previous = body.global_position
			if stalled_seconds > 2.0:
				_write_and_quit(false, reached, body, "stalled before point %d" % point_index)
				return
		if absf(body.global_position.y - destination.y) > max_vertical_error:
			_write_and_quit(false, reached, body, "vertical mismatch at point %d" % point_index)
			return
		reached.append({"index": point_index, "position": _vector(body.global_position)})
	_write_and_quit(true, reached, body, "complete")


func _parse_arguments() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--target="):
			target_path = argument.trim_prefix("--target=")
		elif argument.begins_with("--report="):
			report_path = argument.trim_prefix("--report=")
		elif argument.begins_with("--route="):
			for point in argument.trim_prefix("--route=").split(";"):
				var values := point.split_floats(",")
				if values.size() == 3:
					route.append(Vector3(values[0], values[1], values[2]))
		elif argument.begins_with("--radius="):
			radius = maxf(0.05, argument.trim_prefix("--radius=").to_float())
		elif argument.begins_with("--height="):
			body_height = maxf(radius * 2.0, argument.trim_prefix("--height=").to_float())
		elif argument.begins_with("--speed="):
			speed = maxf(0.1, argument.trim_prefix("--speed=").to_float())
		elif argument.begins_with("--timeout="):
			timeout_seconds = maxf(1.0, argument.trim_prefix("--timeout=").to_float())
		elif argument.begins_with("--max-vertical-error="):
			max_vertical_error = maxf(0.05, argument.trim_prefix("--max-vertical-error=").to_float())


func _write_and_quit(passed: bool, reached: Array[Dictionary], body: CharacterBody3D,
		reason: String) -> void:
	var collisions: Array[Dictionary] = []
	for index in body.get_slide_collision_count():
		var hit := body.get_slide_collision(index)
		collisions.append({"normal": _vector(hit.get_normal()),
			"collider": str(hit.get_collider())})
	var report := {"target": target_path, "passed": passed, "reason": reason,
		"route_local": route.map(_vector), "reached": reached,
		"final_global_position": _vector(body.global_position), "last_collisions": collisions,
		"controller": {"radius_m": radius, "height_m": body_height,
			"max_vertical_error_m": max_vertical_error}}
	if not report_path.is_empty():
		DirAccess.make_dir_recursive_absolute(report_path.get_base_dir())
		var file := FileAccess.open(report_path, FileAccess.WRITE)
		if file != null:
			file.store_string(JSON.stringify(report, "  "))
	print("ROUTE PROBE %s: %s" % ["PASSED" if passed else "FAILED", JSON.stringify(report)])
	get_tree().quit(0 if passed else 1)


func _vector(value: Vector3) -> Array[float]:
	return [value.x, value.y, value.z]


func _fail(message: String) -> void:
	push_error(message)
	print("ROUTE PROBE FAILED")
	get_tree().quit(1)
